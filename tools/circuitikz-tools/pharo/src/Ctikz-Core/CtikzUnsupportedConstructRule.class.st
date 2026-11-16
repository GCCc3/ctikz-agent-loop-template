"
I warn when the scanner found a construct it cannot analyze statically.

Verbatim and inline-verb content is masked before the structural checks, so this
rule reports the unsupported construct instead of silently passing it.
"
Class {
	#name : 'CtikzUnsupportedConstructRule',
	#superclass : 'CtikzLintRule',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzUnsupportedConstructRule >> id [ ^ 'unsupported_construct' ]

{ #category : 'accessing' }
CtikzUnsupportedConstructRule >> defaultSeverity [ ^ 'warning' ]

{ #category : 'evaluating' }
CtikzUnsupportedConstructRule >> evaluate: model context: context [
	model unsupported ifEmpty: [ ^ self passed ].
	^ self warning: 'Unsupported construct: ' , (model unsupported first at: 'kind')
		line: (model unsupported first at: 'line')
]
