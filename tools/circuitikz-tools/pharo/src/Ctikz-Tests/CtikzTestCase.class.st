"
I add shared assertions for Ctikz tests.
"
Class {
	#name : 'CtikzTestCase',
	#superclass : 'TestCase',
	#category : 'Ctikz-Tests',
	#package : 'Ctikz-Tests'
}

{ #category : 'helpers' }
CtikzTestCase >> assertCode: aBlock equals: aString [
	| code |
	self should: aBlock raise: DsktError.
	code := nil.
	[ aBlock value ] on: DsktError do: [ :error | code := error code ].
	self assert: code equals: aString
]
