"
I warn about unrecognized sb macros.
"
Class {
	#name : 'SchemablocUnknownMacroRule',
	#superclass : 'SchemablocLintRule',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocUnknownMacroRule >> id [ ^ 'unknown_macro' ]
{ #category : 'evaluating' }
SchemablocUnknownMacroRule >> evaluate: aModel context: aDictionary [
	aModel unknownMacros isEmpty ifTrue: [ ^ self passed ].
	^ self warning: ('Unrecognized macros: ', (aModel unknownMacros collect: [ :each | each at: 'macro' ]) asArray printString) line: (aModel unknownMacros first at: 'line')
]
