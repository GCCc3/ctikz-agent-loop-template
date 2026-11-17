"
I reject circuitikz in a schemabloc source.
"
Class {
	#name : 'SchemablocNoCircuitikzRule',
	#superclass : 'SchemablocLintRule',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocNoCircuitikzRule >> id [ ^ 'no_circuitikz' ]
{ #category : 'evaluating' }
SchemablocNoCircuitikzRule >> evaluate: aModel context: aDictionary [
	((aModel hasPackage: 'circuitikz') or: [ aModel source includesSubstring: '\begin{circuitikz}' ])
		ifFalse: [ ^ self passed ].
	^ self failed: 'circuitikz is not allowed in a schemabloc source' line: nil
]
