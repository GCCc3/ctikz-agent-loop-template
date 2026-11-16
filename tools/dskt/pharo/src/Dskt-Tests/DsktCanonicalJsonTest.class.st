"
I test the deterministic JSON contract used by every domain.
"
Class {
	#name : 'DsktCanonicalJsonTest',
	#superclass : 'TestCase',
	#category : 'Dskt-Tests',
	#package : 'Dskt-Tests'
}

{ #category : 'tests' }
DsktCanonicalJsonTest >> testSortsKeys [
	| json |
	json := DsktCanonicalJson toString: (Dictionary new
		at: 'b' put: 2;
		at: 'a' put: 1;
		yourself).
	self assert: json equals: '{"a":1,"b":2}'
]

{ #category : 'tests' }
DsktCanonicalJsonTest >> testIsDeterministicForDifferentInsertionOrder [
	| first second |
	first := DsktCanonicalJson toString: (Dictionary new
		at: 'b' put: #(2 3);
		at: 'a' put: 1;
		yourself).
	second := DsktCanonicalJson toString: (Dictionary new
		at: 'a' put: 1;
		at: 'b' put: #(2 3);
		yourself).
	self assert: first equals: second
]
