"
I convert points and axis-aligned boxes among image, ink, normalized, and centimetre bases.
"
Class {
	#name : 'PmdtGeometryConverter',
	#superclass : 'Object',
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'converting' }
PmdtGeometryConverter class >> convert: aDictionary from: fromString to: toString image: aPmdtRgbaImage mask: aPmdtInkMask dpiX: dpiX dpiY: dpiY [
	| type coordinates imageBox inkBox warnings imageCoords targetCoords exact |
	type := aDictionary at: 'type'.
	coordinates := aDictionary at: 'coordinates'.
	(type = 'point' and: [ coordinates size ~= 2 ])
		ifTrue: [ PmdtError code: 'invalid_request' message: 'A point must have two coordinates' ].
	(type = 'box' and: [ coordinates size ~= 4 ])
		ifTrue: [ PmdtError code: 'invalid_request' message: 'A box must have four coordinates' ].
	(type = 'point' or: [ type = 'box' ])
		ifFalse: [ PmdtError code: 'invalid_request' message: 'Only point and box geometry are supported' ].
	imageBox := PmdtBBox fullWidth: aPmdtRgbaImage width height: aPmdtRgbaImage height.
	inkBox := aPmdtInkMask primaryBoundingBox.
	warnings := OrderedCollection new.
	(type = 'point' and: [ (#('normalized_ink' 'ink_pixels' 'centimetres') includes: fromString) and: [ inkBox isNil ] ])
		ifTrue: [ PmdtError code: 'invalid_request' message: 'The selected source basis requires a non-empty ink mask' ].
	imageCoords := self toImagePixels: coordinates type: type from: fromString image: aPmdtRgbaImage inkBox: inkBox dpiX: dpiX dpiY: dpiY warnings: warnings.
	targetCoords := self fromImagePixels: imageCoords type: type to: toString image: aPmdtRgbaImage inkBox: inkBox dpiX: dpiX dpiY: dpiY warnings: warnings.
	exact := (targetCoords allSatisfy: [ :each | each notNil ]).
	^ Dictionary new
		at: 'geometry' put: (Dictionary new at: 'type' put: type; at: 'coordinates' put: targetCoords; yourself);
		at: 'from' put: (self descriptor: fromString);
		at: 'to' put: (self descriptor: toString);
		at: 'transformation' put: (Dictionary new
			at: 'ink_bbox_px' put: (inkBox ifNil: [ nil ] ifNotNil: [ :each | each asArray ]);
			at: 'mask_threshold' put: aPmdtInkMask parameters threshold;
			yourself);
		at: 'exact' put: exact;
		at: 'warnings' put: warnings asArray;
		yourself
]

{ #category : 'private' }
PmdtGeometryConverter class >> toImagePixels: coordinates type: type from: fromString image: aPmdtRgbaImage inkBox: inkBox dpiX: dpiX dpiY: dpiY warnings: warnings [
	fromString = 'image_pixels' ifTrue: [ ^ coordinates collect: [ :each | each asFloat ] ].
	fromString = 'normalized_image' ifTrue: [
		^ self mapPairs: coordinates type: type do: [ :x :y |
			{ x * aPmdtRgbaImage width . y * aPmdtRgbaImage height } ] ].
	fromString = 'ink_pixels' ifTrue: [
		^ self mapPairs: coordinates type: type do: [ :x :y |
			{ inkBox x0 + x . inkBox y0 + y } ] ].
	fromString = 'normalized_ink' ifTrue: [
		^ self mapPairs: coordinates type: type do: [ :x :y |
			{ inkBox x0 + (x * inkBox width) . inkBox y0 + (y * inkBox height) } ] ].
	fromString = 'centimetres' ifTrue: [
		(dpiX isNil or: [ dpiY isNil ])
			ifTrue: [ PmdtError code: 'dpi_unknown' message: 'Centimetre conversion requires DPI' ].
		^ self mapPairs: coordinates type: type do: [ :x :y |
			{ x * dpiX / 2.54 . y * dpiY / 2.54 } ] ].
	PmdtError code: 'unknown_basis' message: 'Unsupported source basis: ' , fromString printString
]

{ #category : 'private' }
PmdtGeometryConverter class >> fromImagePixels: coordinates type: type to: toString image: aPmdtRgbaImage inkBox: inkBox dpiX: dpiX dpiY: dpiY warnings: warnings [
	| result |
	toString = 'image_pixels' ifTrue: [ result := coordinates collect: [ :each | each asFloat ] ].
	toString = 'normalized_image' ifTrue: [
		result := self mapPairs: coordinates type: type do: [ :x :y |
			{ x / aPmdtRgbaImage width . y / aPmdtRgbaImage height } ] ].
	toString = 'ink_pixels' ifTrue: [
		result := self mapPairs: coordinates type: type do: [ :x :y |
			{ x - inkBox x0 . y - inkBox y0 } ] ].
	toString = 'normalized_ink' ifTrue: [
		result := self mapPairs: coordinates type: type do: [ :x :y |
			{ (x - inkBox x0) / inkBox width asFloat . (y - inkBox y0) / inkBox height asFloat } ] ].
	toString = 'centimetres' ifTrue: [
		(dpiX isNil or: [ dpiY isNil ])
			ifTrue: [
				warnings add: (Dictionary new at: 'code' put: 'dpi_unknown'; at: 'message' put: 'Centimetre conversion requires DPI'; at: 'details' put: Dictionary new; yourself).
				^ coordinates collect: [ :each | nil ] ].
		result := self mapPairs: coordinates type: type do: [ :x :y |
			{ x * 2.54 / dpiX . y * 2.54 / dpiY } ] ].
	result ifNil: [ PmdtError code: 'unknown_basis' message: 'Unsupported destination basis: ' , toString printString ].
	self checkOutside: result type: type basis: toString image: aPmdtRgbaImage inkBox: inkBox dpiX: dpiX dpiY: dpiY warnings: warnings.
	^ result
]

{ #category : 'private' }
PmdtGeometryConverter class >> mapPairs: coordinates type: type do: aBlock [
	| output |
	output := OrderedCollection new.
	type = 'point' ifTrue: [
		| pair |
		pair := aBlock value: (coordinates at: 1) value: (coordinates at: 2).
		output add: (pair at: 1); add: (pair at: 2).
		^ output asArray ].
	1 to: 4 by: 2 do: [ :i |
		| pair |
		pair := aBlock value: (coordinates at: i) value: (coordinates at: i + 1).
		output add: (pair at: 1); add: (pair at: 2) ].
	^ output asArray
]

{ #category : 'private' }
PmdtGeometryConverter class >> checkOutside: coordinates type: type basis: aString image: aPmdtRgbaImage inkBox: inkBox dpiX: dpiX dpiY: dpiY warnings: warnings [
	| maxX maxY outside |
	aString = 'normalized_image' ifTrue: [ maxX := 1.0. maxY := 1.0 ].
	aString = 'normalized_ink' ifTrue: [ maxX := 1.0. maxY := 1.0 ].
	aString = 'image_pixels' ifTrue: [ maxX := aPmdtRgbaImage width. maxY := aPmdtRgbaImage height ].
	aString = 'ink_pixels' ifTrue: [ maxX := inkBox width. maxY := inkBox height ].
	aString = 'centimetres' ifTrue: [
		maxX := aPmdtRgbaImage width * 2.54 / dpiX.
		maxY := aPmdtRgbaImage height * 2.54 / dpiY ].
	outside := false.
	coordinates do: [ :each | each isNil ifTrue: [ outside := true ] ].
	(outside not and: [ maxX notNil ]) ifTrue: [
		type = 'point'
			ifTrue: [
				outside := (coordinates at: 1) < 0 or: [ (coordinates at: 1) > maxX or: [ (coordinates at: 2) < 0 or: [ (coordinates at: 2) > maxY ] ] ] ]
			ifFalse: [
				outside := (coordinates at: 1) < 0 or: [ (coordinates at: 3) > maxX or: [ (coordinates at: 2) < 0 or: [ (coordinates at: 4) > maxY ] ] ] ] ].
	outside ifTrue: [
		warnings add: (Dictionary new
			at: 'code' put: 'outside_basis';
			at: 'message' put: 'Geometry lies outside the destination basis';
			at: 'details' put: (Dictionary new at: 'basis' put: aString; yourself);
			yourself) ]
]

{ #category : 'private' }
PmdtGeometryConverter class >> descriptor: aString [
	^ Dictionary new
		at: 'system' put: aString;
		at: 'origin' put: (self originFor: aString);
		at: 'x_direction' put: 'right';
		at: 'y_direction' put: 'down';
		yourself
]

{ #category : 'private' }
PmdtGeometryConverter class >> originFor: aString [
	aString = 'normalized_ink' ifTrue: [ ^ 'ink_bbox_top_left' ].
	aString = 'ink_pixels' ifTrue: [ ^ 'ink_bbox_top_left' ].
	^ 'top_left'
]
