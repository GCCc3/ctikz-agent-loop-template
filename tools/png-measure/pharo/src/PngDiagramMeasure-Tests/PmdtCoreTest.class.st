"
I test bounding boxes, canonical JSON, and mask parameters.
"
Class {
	#name : 'PmdtCoreTest',
	#superclass : 'TestCase',
	#category : 'PngDiagramMeasure-Tests',
	#package : 'PngDiagramMeasure-Tests'
}

{ #category : 'tests' }
PmdtCoreTest >> testBBoxGeometry [
	| box other |
	box := PmdtBBox x0: 2 y0: 3 x1: 8 y1: 9.
	self assert: box width equals: 6.
	self assert: box height equals: 6.
	self assert: box center equals: 5 @ 6.
	self assert: (box containsPoint: 2 @ 3).
	self deny: (box containsPoint: 8 @ 9).
	other := PmdtBBox x0: 7 y0: 8 x1: 12 y1: 13.
	self assert: (box union: other) asArray equals: #(2 3 12 13).
	self assert: (box intersect: other) asArray equals: #(7 8 8 9)
]

{ #category : 'tests' }
PmdtCoreTest >> testCanonicalJsonSortsAndFormats [
	| dictionary json |
	dictionary := Dictionary new
		at: 'b' put: 1.5;
		at: 'a' put: nil;
		at: 'c' put: #(true false);
		yourself.
	json := PmdtCanonicalJson toString: dictionary.
	self assert: json equals: '{"a":null,"b":1.5,"c":[true,false]}'
]

{ #category : 'tests' }
PmdtCoreTest >> testMaskParametersThresholds [
	| parameters |
	parameters := PmdtMaskParameters fromDictionary: (Dictionary new
		at: 'background' put: '#ffffff';
		at: 'threshold' put: 0.5;
		at: 'sensitivity_thresholds' put: #(0.75 0.25 0.5 0.25);
		yourself).
	self assert: parameters thresholds asArray equals: #(0.25 0.5 0.75).
	self assert: parameters backgroundRgb asArray equals: #(255 255 255).
	self should: [ PmdtMaskParameters fromDictionary: (Dictionary new at: 'threshold' put: 1.5; yourself) ] raise: PmdtError
]
