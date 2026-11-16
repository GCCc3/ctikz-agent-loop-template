"
I am the rule that warns about coordinates the scanner cannot resolve statically.

I warn for relative, calc, and plus references.
"
Class {
	#name : 'CtikzAmbiguousCoordinatesRule',
	#superclass : 'CtikzLintRule',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzAmbiguousCoordinatesRule >> id [ ^ 'ambiguous_coordinates' ]

{ #category : 'accessing' }
CtikzAmbiguousCoordinatesRule >> defaultSeverity [ ^ 'warning' ]

{ #category : 'evaluating' }
CtikzAmbiguousCoordinatesRule >> evaluate: model context: context [
	| ambiguous |
	ambiguous := model coordinateReferences select: [ :each |
		| name |
		name := each at: 'name'.
		(name includesSubstring: '++')
			or: [ (name beginsWith: '+')
			or: [ (name includesSubstring: 'calc')
			or: [ name includesSubstring: '$' ] ] ] ].
	ambiguous ifEmpty: [ ^ self passed ].
	^ self warning: 'Ambiguous coordinate references cannot be resolved statically'
		line: (ambiguous first at: 'line')
]
