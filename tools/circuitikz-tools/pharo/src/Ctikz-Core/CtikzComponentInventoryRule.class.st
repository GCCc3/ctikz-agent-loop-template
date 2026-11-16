"
I am the rule that reports the component inventory.

I count to[L], to[R], to[generic], and to[sV] in the source.
"
Class {
	#name : 'CtikzComponentInventoryRule',
	#superclass : 'CtikzLintRule',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzComponentInventoryRule >> id [ ^ 'component_inventory' ]

{ #category : 'accessing' }
CtikzComponentInventoryRule >> defaultSeverity [ ^ 'passed' ]

{ #category : 'evaluating' }
CtikzComponentInventoryRule >> evaluate: model context: context [
	| counts |
	counts := Dictionary new.
	#('L' 'R' 'generic' 'sV') do: [ :name | counts at: name put: 0 ].
	model components do: [ :component |
		| options |
		options := component at: 'options'.
		counts keys do: [ :name |
			(options includesSubstring: name) ifTrue: [
				counts at: name put: (counts at: name) + 1 ] ] ].
	^ CtikzLintCheck id: self id status: 'passed' message: '' line: nil details: counts
]
