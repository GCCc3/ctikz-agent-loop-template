"
I am an immutable exclusive bounding box [x0, y0, x1, y1].

x1 and y1 are exclusive. Width is x1 - x0 and height is y1 - y0.
"
Class {
	#name : 'PmdtBBox',
	#superclass : 'Object',
	#instVars : [
		'x0',
		'y0',
		'x1',
		'y1'
	],
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'instance creation' }
PmdtBBox class >> fromArray: anArray [
	(anArray isNil or: [ anArray size ~= 4 ])
		ifTrue: [ PmdtError code: 'invalid_region' message: 'A bounding box must have four coordinates' ].
	^ self
		x0: (anArray at: 1)
		y0: (anArray at: 2)
		x1: (anArray at: 3)
		y1: (anArray at: 4)
]

{ #category : 'instance creation' }
PmdtBBox class >> x0: aNumber y0: aNumber2 x1: aNumber3 y1: aNumber4 [
	^ self new
		x0: aNumber;
		y0: aNumber2;
		x1: aNumber3;
		y1: aNumber4;
		yourself
]

{ #category : 'instance creation' }
PmdtBBox class >> fullWidth: aNumber height: aNumber2 [
	^ self x0: 0 y0: 0 x1: aNumber y1: aNumber2
]

{ #category : 'accessing' }
PmdtBBox >> x0 [ ^ x0 ]

{ #category : 'accessing' }
PmdtBBox >> x0: anObject [ x0 := anObject ]

{ #category : 'accessing' }
PmdtBBox >> y0 [ ^ y0 ]

{ #category : 'accessing' }
PmdtBBox >> y0: anObject [ y0 := anObject ]

{ #category : 'accessing' }
PmdtBBox >> x1 [ ^ x1 ]

{ #category : 'accessing' }
PmdtBBox >> x1: anObject [ x1 := anObject ]

{ #category : 'accessing' }
PmdtBBox >> y1 [ ^ y1 ]

{ #category : 'accessing' }
PmdtBBox >> y1: anObject [ y1 := anObject ]

{ #category : 'accessing' }
PmdtBBox >> width [
	^ self x1 - self x0
]

{ #category : 'accessing' }
PmdtBBox >> height [
	^ self y1 - self y0
]

{ #category : 'accessing' }
PmdtBBox >> center [
	^ Point
		x: (self x0 + self x1) / 2.0
		y: (self y0 + self y1) / 2.0
]

{ #category : 'testing' }
PmdtBBox >> isEmpty [
	^ self width <= 0 or: [ self height <= 0 ]
]

{ #category : 'testing' }
PmdtBBox >> isValid [
	^ self x1 >= self x0 and: [ self y1 >= self y0 ]
]

{ #category : 'operations' }
PmdtBBox >> union: aBBox [
	^ self class
		x0: (self x0 min: aBBox x0)
		y0: (self y0 min: aBBox y0)
		x1: (self x1 max: aBBox x1)
		y1: (self y1 max: aBBox y1)
]

{ #category : 'operations' }
PmdtBBox >> intersect: aBBox [
	^ self class
		x0: (self x0 max: aBBox x0)
		y0: (self y0 max: aBBox y0)
		x1: (self x1 min: aBBox x1)
		y1: (self y1 min: aBBox y1)
]

{ #category : 'operations' }
PmdtBBox >> clippedTo: aBBox [
	^ self intersect: aBBox
]

{ #category : 'testing' }
PmdtBBox >> containsPoint: aPoint [
	^ aPoint x >= self x0 and: [
		aPoint x < self x1 and: [
			aPoint y >= self y0 and: [ aPoint y < self y1 ] ] ]
]

{ #category : 'converting' }
PmdtBBox >> asArray [
	^ { self x0 . self y0 . self x1 . self y1 }
]

{ #category : 'converting' }
PmdtBBox >> asPointArray [
	^ { self x0 . self y0 . self x1 . self y1 } collect: [ :each | each asFloat ]
]

{ #category : 'printing' }
PmdtBBox >> printOn: aStream [
	super printOn: aStream.
	aStream nextPut: $(.
	self asArray
		do: [ :each | each printOn: aStream ]
		separatedBy: [ aStream nextPut: $,; space ].
	aStream nextPut: $)
]
