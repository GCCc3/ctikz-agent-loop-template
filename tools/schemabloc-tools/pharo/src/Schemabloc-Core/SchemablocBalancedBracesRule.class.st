"
I require balanced braces.
"
Class {
	#name : 'SchemablocBalancedBracesRule',
	#superclass : 'SchemablocLintRule',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocBalancedBracesRule >> id [ ^ 'balanced_braces' ]
{ #category : 'evaluating' }
SchemablocBalancedBracesRule >> evaluate: aModel context: aDictionary [
	aModel braceBalance = 0 ifFalse: [ ^ self failed: 'Brace depth is not balanced' line: nil ].
	aModel braceErrors isEmpty ifTrue: [ ^ self passed ].
	^ self failed: (aModel braceErrors first at: 'message') line: (aModel braceErrors first at: 'line')
]
