"
I report the node and link inventory.
"
Class {
	#name : 'SchemablocInventoryRule',
	#superclass : 'SchemablocLintRule',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocInventoryRule >> id [ ^ 'inventory' ]
{ #category : 'evaluating' }
SchemablocInventoryRule >> evaluate: aModel context: aDictionary [
	^ self passed
]
