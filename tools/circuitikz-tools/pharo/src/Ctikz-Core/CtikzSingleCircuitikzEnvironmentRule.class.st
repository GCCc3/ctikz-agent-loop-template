"
I am the rule that requires exactly one CircuitTikZ environment.

I fail when the source contains zero or more than one circuitikz environment.
"
Class {
	#name : 'CtikzSingleCircuitikzEnvironmentRule',
	#superclass : 'CtikzLintRule',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzSingleCircuitikzEnvironmentRule >> id [ ^ 'single_circuitikz_environment' ]

{ #category : 'evaluating' }
CtikzSingleCircuitikzEnvironmentRule >> evaluate: model context: context [
	| count |
	count := model circuitikzEnvironments size.
	count = 1 ifTrue: [ ^ self passed ].
	^ self failed: 'Expected exactly one circuitikz environment, found ' , count printString line: nil
]
