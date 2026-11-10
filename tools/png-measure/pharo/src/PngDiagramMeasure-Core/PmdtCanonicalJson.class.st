"
I serialize measurement dictionaries deterministically: sorted keys, fixed float precision, LF line endings, and UTF-8 output.

I intentionally do not add timestamps or run-varying identifiers.
"
Class {
	#name : 'PmdtCanonicalJson',
	#superclass : 'Object',
	#classVars : [
		'FloatDecimals'
	],
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'accessing' }
PmdtCanonicalJson class >> floatDecimals [
	^ FloatDecimals ifNil: [ 6 ]
]

{ #category : 'accessing' }
PmdtCanonicalJson class >> floatDecimals: anInteger [
	FloatDecimals := anInteger
]

{ #category : 'converting' }
PmdtCanonicalJson class >> toString: anObject [
	^ String streamContents: [ :stream | self write: anObject on: stream ]
]

{ #category : 'converting' }
PmdtCanonicalJson class >> bytesFor: anObject [
	^ self toString: anObject
]

{ #category : 'private' }
PmdtCanonicalJson class >> write: anObject on: aStream [
	anObject isNil
		ifTrue: [ ^ aStream nextPutAll: 'null' ].
	anObject == true
		ifTrue: [ ^ aStream nextPutAll: 'true' ].
	anObject == false
		ifTrue: [ ^ aStream nextPutAll: 'false' ].
	anObject isString
		ifTrue: [ ^ aStream nextPutAll: (NeoJSONWriter toString: anObject) ].
	anObject isSymbol
		ifTrue: [ ^ aStream nextPutAll: (NeoJSONWriter toString: anObject asString) ].
	anObject isNumber
		ifTrue: [ ^ self writeNumber: anObject on: aStream ].
	(anObject isKindOf: Dictionary)
		ifTrue: [ ^ self writeDictionary: anObject on: aStream ].
	(anObject isKindOf: Collection)
		ifTrue: [ ^ self writeCollection: anObject on: aStream ].
	(anObject respondsTo: #asCanonicalJsonObject)
		ifTrue: [ ^ self write: anObject asCanonicalJsonObject on: aStream ].
	^ aStream nextPutAll: (NeoJSONWriter toString: anObject printString)
]

{ #category : 'private' }
PmdtCanonicalJson class >> writeDictionary: aDictionary on: aStream [
	| keys |
	keys := aDictionary keys collect: [ :each | each asString ].
	keys := keys asSortedCollection: [ :a :b | a <= b ].
	aStream nextPut: ${.
	keys
		do: [ :key |
			| value |
			value := aDictionary
				at: key
				ifAbsent: [ aDictionary at: key asSymbol ifAbsent: [ nil ] ].
			aStream nextPutAll: (NeoJSONWriter toString: key).
			aStream nextPut: $:.
			self write: value on: aStream ]
		separatedBy: [ aStream nextPut: $, ].
	aStream nextPut: $}
]

{ #category : 'private' }
PmdtCanonicalJson class >> writeCollection: aCollection on: aStream [
	aStream nextPut: $[.
	aCollection
		do: [ :each | self write: each on: aStream ]
		separatedBy: [ aStream nextPut: $, ].
	aStream nextPut: $]
]

{ #category : 'private' }
PmdtCanonicalJson class >> writeNumber: aNumber on: aStream [
	aNumber isInteger
		ifTrue: [ ^ aNumber printOn: aStream ].
	aNumber isFloat
		ifTrue: [
			| rounded |
			rounded := (aNumber * (10 raisedTo: self floatDecimals)) rounded
				/ (10 raisedTo: self floatDecimals) asFloat.
			^ rounded printOn: aStream ].
	^ aNumber printOn: aStream
]
