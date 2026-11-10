"
I measure aggregate ink inside caller-named windows and report the tightened geometry.
"
Class {
	#name : 'PmdtRegionMeasurer',
	#superclass : 'Object',
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'measuring' }
PmdtRegionMeasurer class >> measure: aPmdtRgbaImage mask: aPmdtInkMask regions: aDictionary units: aString [
	| result |
	result := Dictionary new.
	(aDictionary keys asSortedCollection: [ :a :b | a asString <= b asString ]) do: [ :name |
		result at: name asString put: (self measureRegion: (aDictionary at: name) image: aPmdtRgbaImage mask: aPmdtInkMask units: aString) ].
	^ Dictionary new
		at: 'regions' put: result;
		at: 'basis' put: (Dictionary new
			at: 'mask_method' put: aPmdtInkMask parameters method;
			at: 'threshold' put: aPmdtInkMask parameters threshold;
			at: 'region_units' put: aString;
			yourself);
		at: 'warnings' put: #();
		yourself
]

{ #category : 'private' }
PmdtRegionMeasurer class >> measureRegion: anArray image: aPmdtRgbaImage mask: aPmdtInkMask units: aString [
	| imageBox inkBox rawBox clippedBox clipped warnings tightBox sensitivity status |
	(anArray isNil or: [ anArray size ~= 4 ])
		ifTrue: [ ^ self invalid: anArray units: aString message: 'A region must contain four coordinates' ].
	imageBox := PmdtBBox fullWidth: aPmdtRgbaImage width height: aPmdtRgbaImage height.
	inkBox := aPmdtInkMask primaryBoundingBox.
	(inkBox isNil and: [ aString = 'normalized_ink' ])
		ifTrue: [ ^ self invalid: anArray units: aString message: 'normalized_ink requires a non-empty ink mask' ].
	rawBox := self convert: anArray units: aString image: aPmdtRgbaImage inkBox: inkBox.
	(rawBox isNil or: [ rawBox isEmpty ])
		ifTrue: [ ^ self invalid: anArray units: aString message: 'The region has no area' ].
	clippedBox := rawBox clippedTo: imageBox.
	clipped := clippedBox asArray ~= rawBox asArray.
	(clippedBox isEmpty)
		ifTrue: [ ^ self invalid: anArray units: aString message: 'The region lies outside the image' ].
	warnings := OrderedCollection new.
	clipped ifTrue: [ warnings add: (self warning: 'region_clipped' message: 'The requested region was clipped to the image' details: (Dictionary new at: 'requested' put: rawBox asArray; at: 'clipped' put: clippedBox asArray; yourself)) ].
	self addEdgeWarnings: warnings region: clippedBox mask: aPmdtInkMask image: aPmdtRgbaImage.
	tightBox := self tightBoxIn: clippedBox mask: aPmdtInkMask.
	sensitivity := self sensitivityBoxesIn: clippedBox image: aPmdtRgbaImage parameters: aPmdtInkMask parameters.
	tightBox ifNil: [
		warnings add: (self warning: 'region_empty' message: 'No ink was found inside the requested region' details: Dictionary new).
		^ Dictionary new
			at: 'status' put: 'empty';
			at: 'requested_bbox' put: anArray;
			at: 'requested_basis' put: aString;
			at: 'requested_bbox_px' put: clippedBox asArray;
			at: 'clipped' put: clipped;
			at: 'tight_bbox_px' put: nil;
			at: 'tight_bbox_normalized_ink' put: nil;
			at: 'center_px' put: nil;
			at: 'center_normalized_ink' put: nil;
			at: 'size_px' put: nil;
			at: 'aspect_ratio' put: nil;
			at: 'bbox_sensitivity' put: sensitivity;
			at: 'warnings' put: warnings asArray;
			yourself ].
	status := 'measured'.
	^ Dictionary new
		at: 'status' put: status;
		at: 'requested_bbox' put: anArray;
		at: 'requested_basis' put: aString;
		at: 'requested_bbox_px' put: clippedBox asArray;
		at: 'clipped' put: clipped;
		at: 'tight_bbox_px' put: tightBox asArray;
		at: 'tight_bbox_normalized_ink' put: (self normalizedInkBox: tightBox inkBox: inkBox);
		at: 'center_px' put: (self arrayForPoint: tightBox center);
		at: 'center_normalized_ink' put: (self normalizedInkPoint: tightBox center inkBox: inkBox);
		at: 'size_px' put: (Dictionary new at: 'width' put: tightBox width; at: 'height' put: tightBox height; yourself);
		at: 'aspect_ratio' put: (tightBox height = 0 ifTrue: [ nil ] ifFalse: [ tightBox width / tightBox height asFloat ]);
		at: 'bbox_sensitivity' put: sensitivity;
		at: 'warnings' put: warnings asArray;
		yourself
]

{ #category : 'private' }
PmdtRegionMeasurer class >> convert: anArray units: aString image: aPmdtRgbaImage inkBox: inkBox [
	| x0 y0 x1 y1 |
	aString = 'image_pixels' ifTrue: [
		x0 := (anArray at: 1) asFloat.
		y0 := (anArray at: 2) asFloat.
		x1 := (anArray at: 3) asFloat.
		y1 := (anArray at: 4) asFloat ].
	aString = 'normalized_image' ifTrue: [
		x0 := (anArray at: 1) * aPmdtRgbaImage width.
		y0 := (anArray at: 2) * aPmdtRgbaImage height.
		x1 := (anArray at: 3) * aPmdtRgbaImage width.
		y1 := (anArray at: 4) * aPmdtRgbaImage height ].
	aString = 'normalized_ink' ifTrue: [
		x0 := inkBox x0 + ((anArray at: 1) * inkBox width).
		y0 := inkBox y0 + ((anArray at: 2) * inkBox height).
		x1 := inkBox x0 + ((anArray at: 3) * inkBox width).
		y1 := inkBox y0 + ((anArray at: 4) * inkBox height) ].
	(x0 isNil or: [ y0 isNil or: [ x1 isNil or: [ y1 isNil ] ] ])
		ifTrue: [ PmdtError code: 'unknown_basis' message: 'Unsupported region units: ' , aString printString ].
	^ PmdtBBox
		x0: x0 floor
		y0: y0 floor
		x1: x1 ceiling
		y1: y1 ceiling
]

{ #category : 'private' }
PmdtRegionMeasurer class >> tightBoxIn: aPmdtBBox mask: aPmdtInkMask [
	| minX minY maxX maxY |
	minX := aPmdtBBox x1.
	minY := aPmdtBBox y1.
	maxX := -1.
	maxY := -1.
	aPmdtBBox y0 to: aPmdtBBox y1 - 1 do: [ :y |
		aPmdtBBox x0 to: aPmdtBBox x1 - 1 do: [ :x |
			(aPmdtInkMask inkAtX: x y: y) ifTrue: [
				x < minX ifTrue: [ minX := x ].
				y < minY ifTrue: [ minY := y ].
				x > maxX ifTrue: [ maxX := x ].
				y > maxY ifTrue: [ maxY := y ] ] ] ].
	^ maxX < 0
		ifTrue: [ nil ]
		ifFalse: [ PmdtBBox x0: minX y0: minY x1: maxX + 1 y1: maxY + 1 ]
]

{ #category : 'private' }
PmdtRegionMeasurer class >> sensitivityBoxesIn: aPmdtBBox image: aPmdtRgbaImage parameters: aPmdtMaskParameters [
	| result |
	result := Dictionary new.
	aPmdtMaskParameters thresholds do: [ :threshold |
		| box |
		box := PmdtLuminanceClassifier
			boundingBoxIn: aPmdtRgbaImage
			x0: aPmdtBBox x0
			y0: aPmdtBBox y0
			x1: aPmdtBBox x1
			y1: aPmdtBBox y1
			threshold: threshold
			backgroundRgb: aPmdtMaskParameters backgroundRgb.
		result at: (PmdtCanonicalJson toString: threshold) put: (box ifNil: [ nil ] ifNotNil: [ :each | each asArray ]) ].
	^ result
]

{ #category : 'private' }
PmdtRegionMeasurer class >> addEdgeWarnings: warnings region: aPmdtBBox mask: aPmdtInkMask image: aPmdtRgbaImage [
	| left right top bottom |
	left := aPmdtBBox x0 - 1.
	right := aPmdtBBox x1.
	top := aPmdtBBox y0 - 1.
	bottom := aPmdtBBox y1.
	(left >= 0 and: [ self hasInkInColumn: left from: aPmdtBBox y0 to: aPmdtBBox y1 - 1 mask: aPmdtInkMask ])
		ifTrue: [ warnings add: (self sideWarning: 'left' region: aPmdtBBox) ].
	(right < aPmdtRgbaImage width and: [ self hasInkInColumn: right from: aPmdtBBox y0 to: aPmdtBBox y1 - 1 mask: aPmdtInkMask ])
		ifTrue: [ warnings add: (self sideWarning: 'right' region: aPmdtBBox) ].
	(top >= 0 and: [ self hasInkInRow: top from: aPmdtBBox x0 to: aPmdtBBox x1 - 1 mask: aPmdtInkMask ])
		ifTrue: [ warnings add: (self sideWarning: 'top' region: aPmdtBBox) ].
	(bottom < aPmdtRgbaImage height and: [ self hasInkInRow: bottom from: aPmdtBBox x0 to: aPmdtBBox x1 - 1 mask: aPmdtInkMask ])
		ifTrue: [ warnings add: (self sideWarning: 'bottom' region: aPmdtBBox) ]
]

{ #category : 'private' }
PmdtRegionMeasurer class >> hasInkInColumn: x from: y0 to: y1 mask: aPmdtInkMask [
	y0 to: y1 do: [ :y | (aPmdtInkMask inkAtX: x y: y) ifTrue: [ ^ true ] ].
	^ false
]

{ #category : 'private' }
PmdtRegionMeasurer class >> hasInkInRow: y from: x0 to: x1 mask: aPmdtInkMask [
	x0 to: x1 do: [ :x | (aPmdtInkMask inkAtX: x y: y) ifTrue: [ ^ true ] ].
	^ false
]

{ #category : 'private' }
PmdtRegionMeasurer class >> normalizedInkBox: aPmdtBBox inkBox: inkBox [
	^ { (aPmdtBBox x0 - inkBox x0) / inkBox width asFloat .
		(aPmdtBBox y0 - inkBox y0) / inkBox height asFloat .
		(aPmdtBBox x1 - inkBox x0) / inkBox width asFloat .
		(aPmdtBBox y1 - inkBox y0) / inkBox height asFloat }
]

{ #category : 'private' }
PmdtRegionMeasurer class >> normalizedInkPoint: aPoint inkBox: inkBox [
	^ { (aPoint x - inkBox x0) / inkBox width asFloat .
		(aPoint y - inkBox y0) / inkBox height asFloat }
]

{ #category : 'private' }
PmdtRegionMeasurer class >> arrayForPoint: aPoint [
	^ { aPoint x . aPoint y }
]

{ #category : 'private' }
PmdtRegionMeasurer class >> invalid: anArray units: aString message: aString2 [
	| warnings |
	warnings := OrderedCollection new.
	warnings add: (self warning: 'region_empty' message: aString2 details: Dictionary new).
	^ Dictionary new
		at: 'status' put: 'invalid';
		at: 'requested_bbox' put: anArray;
		at: 'requested_basis' put: aString;
		at: 'requested_bbox_px' put: nil;
		at: 'clipped' put: false;
		at: 'tight_bbox_px' put: nil;
		at: 'tight_bbox_normalized_ink' put: nil;
		at: 'center_px' put: nil;
		at: 'center_normalized_ink' put: nil;
		at: 'size_px' put: nil;
		at: 'aspect_ratio' put: nil;
		at: 'bbox_sensitivity' put: Dictionary new;
		at: 'warnings' put: warnings asArray;
		yourself
]

{ #category : 'private' }
PmdtRegionMeasurer class >> warning: code message: message details: details [
	^ Dictionary new at: 'code' put: code; at: 'message' put: message; at: 'details' put: details; yourself
]

{ #category : 'private' }
PmdtRegionMeasurer class >> sideWarning: side region: aPmdtBBox [
	^ self warning: 'region_ink_extends_beyond_window'
		message: 'Ink continues immediately ' , side , ' of the requested window'
		details: (Dictionary new at: 'side' put: side; at: 'region' put: aPmdtBBox asArray; yourself)
]
