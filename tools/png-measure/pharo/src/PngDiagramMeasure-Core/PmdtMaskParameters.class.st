"
I validate and hold the background colour, mask method, primary threshold, and sensitivity thresholds.
"
Class {
	#name : 'PmdtMaskParameters',
	#superclass : 'Object',
	#instVars : [
		'background',
		'method',
		'threshold',
		'sensitivityThresholds',
		'backgroundRgb'
	],
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'instance creation' }
PmdtMaskParameters class >> default [
	^ self new
		background: '#ffffff';
		method: 'luminance';
		threshold: 0.5;
		sensitivityThresholds: #(0.25 0.5 0.75);
		yourself
]

{ #category : 'instance creation' }
PmdtMaskParameters class >> fromDictionary: aDictionary [
	| params |
	params := self default.
	aDictionary ifNil: [ ^ params ].
	(aDictionary at: 'background' ifAbsent: [ nil ])
		ifNotNil: [ :value | params background: value ].
	(aDictionary at: 'method' ifAbsent: [ nil ])
		ifNotNil: [ :value | params method: value ].
	(aDictionary at: 'threshold' ifAbsent: [ nil ])
		ifNotNil: [ :value | params threshold: value asFloat ].
	(aDictionary at: 'sensitivity_thresholds' ifAbsent: [ nil ])
		ifNotNil: [ :value | params sensitivityThresholds: value ].
	^ params
]

{ #category : 'accessing' }
PmdtMaskParameters >> background [ ^ background ]

{ #category : 'accessing' }
PmdtMaskParameters >> background: aString [
	| parsed |
	parsed := self parseBackground: aString.
	background := aString.
	backgroundRgb := parsed
]

{ #category : 'accessing' }
PmdtMaskParameters >> backgroundRgb [
	^ backgroundRgb ifNil: [ backgroundRgb := self parseBackground: self background ]
]

{ #category : 'accessing' }
PmdtMaskParameters >> method [ ^ method ]

{ #category : 'accessing' }
PmdtMaskParameters >> method: aString [
	(aString asLowercase = 'luminance')
		ifFalse: [ PmdtError code: 'invalid_request' message: 'Only the luminance mask method is supported' ].
	method := 'luminance'
]

{ #category : 'accessing' }
PmdtMaskParameters >> threshold [ ^ threshold ]

{ #category : 'accessing' }
PmdtMaskParameters >> threshold: aNumber [
	(aNumber isNumber and: [ aNumber > 0 and: [ aNumber < 1 ] ])
		ifFalse: [ PmdtError code: 'invalid_request' message: 'The threshold must be between 0 and 1' ].
	threshold := aNumber asFloat
]

{ #category : 'accessing' }
PmdtMaskParameters >> sensitivityThresholds [ ^ sensitivityThresholds ifNil: [ #() ] ]

{ #category : 'accessing' }
PmdtMaskParameters >> sensitivityThresholds: aCollection [
	| values |
	values := aCollection collect: [ :each | each asFloat ].
	values := values select: [ :each | each > 0 and: [ each < 1 ] ].
	values := values asSortedCollection: [ :a :b | a <= b ].
	values := values asOrderedCollection.
	values add: self threshold.
	values := values asSet asSortedCollection: [ :a :b | a <= b ].
	values := values asOrderedCollection.
	values size > 9
		ifTrue: [ PmdtError code: 'invalid_request' message: 'At most nine sensitivity thresholds are supported' ].
	sensitivityThresholds := values
]

{ #category : 'accessing' }
PmdtMaskParameters >> thresholds [
	| values |
	values := self sensitivityThresholds asOrderedCollection.
	values add: self threshold.
	^ values asSet asSortedCollection: [ :a :b | a <= b ]
]

{ #category : 'accessing' }
PmdtMaskParameters >> cacheKey [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: self background; nextPut: $|;
			nextPutAll: self method; nextPut: $|;
			print: self threshold; nextPut: $|;
			print: self thresholds asArray ]
]

{ #category : 'converting' }
PmdtMaskParameters >> asDictionary [
	^ Dictionary new
		at: 'background' put: self background;
		at: 'mask_method' put: self method;
		at: 'threshold' put: self threshold;
		at: 'sensitivity_thresholds' put: self thresholds asArray;
		yourself
]

{ #category : 'private' }
PmdtMaskParameters >> parseBackground: aString [
	| text red green blue |
	text := aString asString trimBoth.
	(text size = 7 and: [ text first = $# ])
		ifFalse: [ PmdtError code: 'invalid_request' message: 'The background must be #rrggbb' ].
	red := Integer readFrom: (text copyFrom: 2 to: 3) base: 16.
	green := Integer readFrom: (text copyFrom: 4 to: 5) base: 16.
	blue := Integer readFrom: (text copyFrom: 6 to: 7) base: 16.
	^ { red . green . blue }
]
