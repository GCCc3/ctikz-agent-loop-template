"
I reject duplicate node names.
"
Class {
	#name : 'SchemablocDuplicateNodesRule',
	#superclass : 'SchemablocLintRule',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocDuplicateNodesRule >> id [ ^ 'duplicate_nodes' ]
{ #category : 'evaluating' }
SchemablocDuplicateNodesRule >> evaluate: aModel context: aDictionary [
	| seen |
	seen := Dictionary new.
	aModel definitions do: [ :each |
		| name |
		name := each at: 'name'.
		(seen includesKey: name)
			ifTrue: [ ^ self failed: ('Duplicate node name: ', name) line: (each at: 'line') ]
			ifFalse: [ seen at: name put: true ] ].
	^ self passed
]
