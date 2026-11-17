"
I require balanced begin/end environments.
"
Class {
	#name : 'SchemablocBalancedEnvironmentsRule',
	#superclass : 'SchemablocLintRule',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocBalancedEnvironmentsRule >> id [ ^ 'balanced_environments' ]
{ #category : 'evaluating' }
SchemablocBalancedEnvironmentsRule >> evaluate: aModel context: aDictionary [
	| stack |
	stack := OrderedCollection new.
	aModel environments do: [ :each |
		(each at: 'kind') = 'begin'
			ifTrue: [ stack add: each ]
			ifFalse: [
				stack isEmpty ifTrue: [ ^ self failed: ('Unexpected end of environment ', (each at: 'name')) line: (each at: 'line') ].
				(stack removeLast at: 'name') = (each at: 'name') ifFalse: [ ^ self failed: 'Mismatched environment boundary' line: (each at: 'line') ] ] ].
	stack isEmpty ifTrue: [ ^ self passed ].
	^ self failed: ('Unclosed environment ', (stack first at: 'name')) line: (stack first at: 'line')
]
