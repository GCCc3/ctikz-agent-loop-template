"
I require every link endpoint to be a defined node.
"
Class {
	#name : 'SchemablocDefinedNodesRule',
	#superclass : 'SchemablocLintRule',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocDefinedNodesRule >> id [ ^ 'defined_nodes' ]
{ #category : 'evaluating' }
SchemablocDefinedNodesRule >> evaluate: aModel context: aDictionary [
	| names |
	names := aModel definitionNames.
	aModel references do: [ :each |
		(names includes: (each at: 'name')) ifFalse: [
			^ self failed: ('Undefined node: ', (each at: 'name')) line: (each at: 'line') ] ].
	^ self passed
]
