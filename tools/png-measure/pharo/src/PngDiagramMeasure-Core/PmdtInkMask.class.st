"
I hold a binary ink mask and the bounding boxes measured at each sensitivity threshold.
"
Class {
	#name : 'PmdtInkMask',
	#superclass : 'Object',
	#instVars : [
		'width',
		'height',
		'pixels',
		'parameters',
		'inkCount',
		'boundingBoxes'
	],
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'instance creation' }
PmdtInkMask class >> width: anInteger height: anInteger2 pixels: aByteArray parameters: aMaskParameters boundingBoxes: aDictionary [
	^ self new
		width: anInteger;
		height: anInteger2;
		pixels: aByteArray;
		parameters: aMaskParameters;
		boundingBoxes: aDictionary;
		yourself
]

{ #category : 'accessing' }
PmdtInkMask >> width [ ^ width ]

{ #category : 'accessing' }
PmdtInkMask >> width: anObject [ width := anObject ]

{ #category : 'accessing' }
PmdtInkMask >> height [ ^ height ]

{ #category : 'accessing' }
PmdtInkMask >> height: anObject [ height := anObject ]

{ #category : 'accessing' }
PmdtInkMask >> pixels [ ^ pixels ]

{ #category : 'accessing' }
PmdtInkMask >> pixels: anObject [ pixels := anObject ]

{ #category : 'accessing' }
PmdtInkMask >> parameters [ ^ parameters ]

{ #category : 'accessing' }
PmdtInkMask >> parameters: anObject [ parameters := anObject ]

{ #category : 'accessing' }
PmdtInkMask >> boundingBoxes [ ^ boundingBoxes ifNil: [ Dictionary new ] ]

{ #category : 'accessing' }
PmdtInkMask >> boundingBoxes: anObject [ boundingBoxes := anObject ]

{ #category : 'accessing' }
PmdtInkMask >> inkCount [
	^ inkCount ifNil: [
		inkCount := 0.
		pixels do: [ :each | each = 0 ifTrue: [ inkCount := inkCount + 1 ] ].
		inkCount ]
]

{ #category : 'accessing' }
PmdtInkMask >> inkFraction [
	^ self inkCount / (width * height) asFloat
]

{ #category : 'accessing' }
PmdtInkMask >> inkAtX: anInteger y: anInteger2 [
	^ (pixels at: (anInteger2 * width) + anInteger + 1) = 0
]

{ #category : 'accessing' }
PmdtInkMask >> primaryBoundingBox [
	^ self boundingBoxForThreshold: self parameters threshold
]

{ #category : 'accessing' }
PmdtInkMask >> boundingBoxForThreshold: aNumber [
	^ self boundingBoxes
		at: (PmdtCanonicalJson toString: aNumber) asString
		ifAbsent: [ nil ]
]

{ #category : 'testing' }
PmdtInkMask >> isEmpty [
	^ self inkCount = 0
]

{ #category : 'accessing' }
PmdtInkMask >> coverage [
	| box |
	box := self primaryBoundingBox.
	box ifNil: [ ^ 0.0 ].
	^ (box width * box height) / (width * height) asFloat
]

{ #category : 'converting' }
PmdtInkMask >> asDictionary [
	| box |
	box := self primaryBoundingBox.
	^ Dictionary new
		at: 'width_px' put: width;
		at: 'height_px' put: height;
		at: 'ink_pixel_count' put: self inkCount;
		at: 'ink_fraction' put: self inkFraction;
		at: 'ink_bbox_px' put: (box ifNil: [ nil ] ifNotNil: [ :each | each asArray ]);
		yourself
]
