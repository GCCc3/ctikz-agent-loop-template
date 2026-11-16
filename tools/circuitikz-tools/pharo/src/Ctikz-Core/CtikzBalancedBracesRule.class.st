"
I am the rule that checks brace balance.

I fail when the brace depth is not zero or when a closing brace appears before
its matching opening brace.
"
Class {
	#name : 'CtikzBalancedBracesRule',
	#superclass : 'CtikzLintRule',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzBalancedBracesRule >> id [ ^ 'balanced_braces' ]

{ #category : 'evaluating' }
CtikzBalancedBracesRule >> evaluate: model context: context [
	model braceBalance = 0 ifFalse: [
		^ self failed: 'Brace depth is ' , model braceBalance printString line: nil ].
	model braceErrors ifEmpty: [ ^ self passed ].
	^ self failed: 'Unbalanced braces' line: (model braceErrors first at: 'line')
]
