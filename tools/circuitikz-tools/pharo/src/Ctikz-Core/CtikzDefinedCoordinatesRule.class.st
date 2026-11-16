"
I am the rule that checks direct coordinate references.

I fail when a direct coordinate reference has no matching definition.
"
Class {
	#name : 'CtikzDefinedCoordinatesRule',
	#superclass : 'CtikzLintRule',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzDefinedCoordinatesRule >> id [ ^ 'defined_coordinates' ]

{ #category : 'evaluating' }
CtikzDefinedCoordinatesRule >> evaluate: model context: context [
	| defined |
	defined := (model definedCoordinates collect: [ :each | each at: 'name' ]) asSet.
	model coordinateReferences do: [ :reference |
		| name |
		name := reference at: 'name'.
		(self isDirectName: name) ifTrue: [
			(defined includes: name) ifFalse: [
				^ self failed: 'Undefined coordinate: ' , name
					line: (reference at: 'line') ] ] ].
	^ self passed
]

{ #category : 'private' }
CtikzDefinedCoordinatesRule >> isDirectName: aString [
	| trimmed |
	trimmed := aString trimBoth.
	trimmed isEmpty ifTrue: [ ^ false ].
	(trimmed includesSubstring: ',') ifTrue: [ ^ false ].
	(trimmed includesSubstring: '+') ifTrue: [ ^ false ].
	(trimmed includesSubstring: '-') ifTrue: [ ^ false ].
	(trimmed includesSubstring: '$') ifTrue: [ ^ false ].
	(trimmed includesSubstring: 'calc') ifTrue: [ ^ false ].
	^ trimmed allSatisfy: [ :each |
		each isLetter or: [ each isDigit or: [
			(each = (Character value: 95)) or: [ each = (Character value: 58) ] ] ] ]
]
