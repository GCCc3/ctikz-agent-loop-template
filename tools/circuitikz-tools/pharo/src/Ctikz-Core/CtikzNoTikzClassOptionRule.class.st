"
I am the rule that warns when the standalone document class includes the tikz
option while circuitikz is loaded.
"
Class {
	#name : 'CtikzNoTikzClassOptionRule',
	#superclass : 'CtikzLintRule',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzNoTikzClassOptionRule >> id [ ^ 'no_tikz_class_option' ]

{ #category : 'accessing' }
CtikzNoTikzClassOptionRule >> defaultSeverity [ ^ 'warning' ]

{ #category : 'evaluating' }
CtikzNoTikzClassOptionRule >> evaluate: model context: context [
	| options |
	model documentClass ifNil: [ ^ self passed ].
	model documentClass = 'standalone' ifFalse: [ ^ self passed ].
	(model packages includes: 'circuitikz') ifFalse: [ ^ self passed ].
	options := model documentClassOptions.
	(options includes: 'tikz') ifFalse: [ ^ self passed ].
	^ self warning: 'The standalone class uses the tikz option while circuitikz is loaded' line: nil
]
