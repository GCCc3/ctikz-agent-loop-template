"
I measure the canvas, the ink box, margins, aspect ratios, tight-crop status, and physical size.
"
Class {
	#name : 'PmdtBoundsMeasurer',
	#superclass : 'Object',
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'measuring' }
PmdtBoundsMeasurer class >> measure: aPmdtRgbaImage mask: aPmdtInkMask dpiX: dpiX dpiY: dpiY source: aString [
	| width height imageBox inkBox margins warnings reasons coverage marginLimitX marginLimitY sensitivityLimit maxSensitivity tight physical background |
	width := aPmdtRgbaImage width.
	height := aPmdtRgbaImage height.
	imageBox := PmdtBBox fullWidth: width height: height.
	inkBox := aPmdtInkMask primaryBoundingBox.
	warnings := OrderedCollection new.
	reasons := OrderedCollection new.
	marginLimitX := 3 max: 0.02 * width.
	marginLimitY := 3 max: 0.02 * height.
	sensitivityLimit := 2 max: 0.005 * (width max: height).
	background := aPmdtInkMask parameters backgroundRgb.
	((0.2126 * (background at: 1)) + (0.7152 * (background at: 2)) + (0.0722 * (background at: 3))) / 255 > 0.5
		ifFalse: [ warnings add: (self warning: 'background_not_light' message: 'The background is not predominantly light') ].
	aPmdtInkMask inkFraction > 0.9
		ifTrue: [ warnings add: (self warning: 'mostly_ink' message: 'Most of the image is classified as ink') ].
	inkBox ifNil: [
		warnings add: (self warning: 'no_ink' message: 'No ink was found in the image').
		reasons add: 'no-ink'.
		^ Dictionary new
			at: 'image_bbox_px' put: imageBox asArray;
			at: 'ink_bbox_px' put: nil;
			at: 'image_size_px' put: (self sizeDictionary: width height: height);
			at: 'ink_size_px' put: nil;
			at: 'margins_px' put: nil;
			at: 'aspect_ratio' put: (Dictionary new at: 'image' put: (self ratio: width height: height); at: 'ink' put: nil; yourself);
			at: 'tight_crop' put: (self tightDictionary: false marginLimitX: marginLimitX marginLimitY: marginLimitY coverage: 0.0 sensitivityLimit: sensitivityLimit maximumSensitivity: 0 reasons: reasons asArray);
			at: 'physical_size_cm' put: (self physicalDictionary: width height: height inkBox: nil dpiX: dpiX dpiY: dpiY source: aString warnings: warnings);
			at: 'basis' put: (Dictionary new at: 'mask_method' put: aPmdtInkMask parameters method; at: 'threshold' put: aPmdtInkMask parameters threshold; yourself);
			at: 'warnings' put: warnings asArray;
			yourself ].
	margins := Dictionary new
		at: 'left' put: inkBox x0;
		at: 'top' put: inkBox y0;
		at: 'right' put: width - inkBox x1;
		at: 'bottom' put: height - inkBox y1;
		yourself.
	(margins at: 'left') > marginLimitX ifTrue: [ reasons add: 'left margin exceeds the horizontal margin limit' ].
	(margins at: 'right') > marginLimitX ifTrue: [ reasons add: 'right margin exceeds the horizontal margin limit' ].
	(margins at: 'top') > marginLimitY ifTrue: [ reasons add: 'top margin exceeds the vertical margin limit' ].
	(margins at: 'bottom') > marginLimitY ifTrue: [ reasons add: 'bottom margin exceeds the vertical margin limit' ].
	coverage := (inkBox width * inkBox height) / (width * height) asFloat.
	coverage < 0.90 ifTrue: [ reasons add: 'ink bounding-box coverage is below 0.90' ].
	maxSensitivity := self maximumSensitivity: aPmdtInkMask primaryBoundingBox boxes: aPmdtInkMask boundingBoxes.
	maxSensitivity > sensitivityLimit
		ifTrue: [
			reasons add: 'ink bounding box is unstable across sensitivity thresholds'.
			warnings add: (self warning: 'bbox_unstable' message: 'The ink bounding box changes materially across sensitivity thresholds') ].
	tight := reasons isEmpty.
	^ Dictionary new
		at: 'image_bbox_px' put: imageBox asArray;
		at: 'ink_bbox_px' put: inkBox asArray;
		at: 'image_size_px' put: (self sizeDictionary: width height: height);
		at: 'ink_size_px' put: (self sizeDictionary: inkBox width height: inkBox height);
		at: 'margins_px' put: margins;
		at: 'aspect_ratio' put: (Dictionary new
			at: 'image' put: (self ratio: width height: height);
			at: 'ink' put: (self ratio: inkBox width height: inkBox height);
			yourself);
		at: 'tight_crop' put: (self tightDictionary: tight marginLimitX: marginLimitX marginLimitY: marginLimitY coverage: coverage sensitivityLimit: sensitivityLimit maximumSensitivity: maxSensitivity reasons: reasons asArray);
		at: 'physical_size_cm' put: (self physicalDictionary: width height: height inkBox: inkBox dpiX: dpiX dpiY: dpiY source: aString warnings: warnings);
		at: 'basis' put: (Dictionary new at: 'mask_method' put: aPmdtInkMask parameters method; at: 'threshold' put: aPmdtInkMask parameters threshold; yourself);
		at: 'warnings' put: warnings asArray;
		yourself
]

{ #category : 'private' }
PmdtBoundsMeasurer class >> sizeDictionary: width height: height [
	^ Dictionary new at: 'width' put: width; at: 'height' put: height; yourself
]

{ #category : 'private' }
PmdtBoundsMeasurer class >> ratio: width height: height [
	^ height = 0 ifTrue: [ nil ] ifFalse: [ width / height asFloat ]
]

{ #category : 'private' }
PmdtBoundsMeasurer class >> tightDictionary: tight marginLimitX: marginLimitX marginLimitY: marginLimitY coverage: coverage sensitivityLimit: sensitivityLimit maximumSensitivity: maximumSensitivity reasons: reasons [
	^ Dictionary new
		at: 'tightly_cropped' put: tight;
		at: 'margin_limit_px' put: (Dictionary new at: 'horizontal' put: marginLimitX; at: 'vertical' put: marginLimitY; yourself);
		at: 'bbox_coverage' put: coverage;
		at: 'minimum_bbox_coverage' put: 0.90;
		at: 'sensitivity_limit_px' put: sensitivityLimit;
		at: 'maximum_edge_sensitivity_px' put: maximumSensitivity;
		at: 'tight_crop_reasons' put: reasons;
		yourself
]

{ #category : 'private' }
PmdtBoundsMeasurer class >> maximumSensitivity: primary boxes: boxes [
	| maximum |
	primary ifNil: [ ^ 0 ].
	maximum := 0.
	boxes valuesDo: [ :box |
		box ifNotNil: [
			maximum := maximum max: (primary x0 - box x0) abs.
			maximum := maximum max: (primary y0 - box y0) abs.
			maximum := maximum max: (primary x1 - box x1) abs.
			maximum := maximum max: (primary y1 - box y1) abs ] ].
	^ maximum
]

{ #category : 'private' }
PmdtBoundsMeasurer class >> physicalDictionary: width height: height inkBox: inkBox dpiX: dpiX dpiY: dpiY source: aString warnings: warnings [
	| result |
	result := Dictionary new.
	(dpiX isNil or: [ dpiY isNil or: [ dpiX <= 0 or: [ dpiY <= 0 ] ] ])
		ifTrue: [
			warnings add: (self warning: 'dpi_unknown' message: 'The PNG does not provide reliable physical resolution metadata').
			^ result
				at: 'image_width' put: nil;
				at: 'image_height' put: nil;
				at: 'ink_width' put: nil;
				at: 'ink_height' put: nil;
				at: 'source' put: 'unknown';
				yourself ].
	result
		at: 'image_width' put: width * 2.54 / dpiX;
		at: 'image_height' put: height * 2.54 / dpiY.
	inkBox ifNotNil: [
		result
			at: 'ink_width' put: inkBox width * 2.54 / dpiX;
			at: 'ink_height' put: inkBox height * 2.54 / dpiY ].
	result at: 'source' put: (aString ifNil: [ 'metadata' ]).
	^ result
]

{ #category : 'private' }
PmdtBoundsMeasurer class >> warning: code message: message [
	^ Dictionary new at: 'code' put: code; at: 'message' put: message; at: 'details' put: Dictionary new; yourself
]
