"
I am the rule that checks environment balance.

I fail when a begin or end environment does not match in order.
"
Class {
	#name : 'CtikzBalancedEnvironmentsRule',
	#superclass : 'CtikzLintRule',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzBalancedEnvironmentsRule >> id [ ^ 'balanced_environments' ]

{ #category : 'evaluating' }
CtikzBalancedEnvironmentsRule >> evaluate: model context: context [
	| stack |
	stack := OrderedCollection new.
	model environments do: [ :environment |
		| name |
		name := environment at: 'name'.
		(environment at: 'kind') = 'begin'
			ifTrue: [ stack add: name ]
			ifFalse: [
				stack ifEmpty: [
					^ self failed: 'Unexpected end environment: ' , name
						line: (environment at: 'line') ].
				stack removeLast = name ifFalse: [
					^ self failed: 'Mismatched end environment: ' , name
						line: (environment at: 'line') ] ] ].
	stack ifEmpty: [ ^ self passed ].
	^ self failed: 'Unclosed environments: ' , stack printString line: nil
]
