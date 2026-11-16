"
I am the rule that fails when active source matches a forbidden pattern.

I use the caller's forbid_patterns or the default includegraphics and
reference/target.png.
"
Class {
	#name : 'CtikzForbiddenPatternsRule',
	#superclass : 'CtikzLintRule',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzForbiddenPatternsRule >> id [ ^ 'forbidden_patterns' ]

{ #category : 'evaluating' }
CtikzForbiddenPatternsRule >> evaluate: model context: context [
	| patterns source |
	patterns := (context at: 'forbid_patterns' ifAbsent: [ nil ])
		ifNil: [ #('\includegraphics' 'reference/target.png') ].
	source := model activeSource.
	patterns do: [ :pattern |
		| index |
		index := source indexOfSubCollection: pattern asString startingAt: 1.
		index > 0 ifTrue: [
			^ self failed: 'Forbidden pattern: ' , pattern asString
				line: (model lineForOffset: index) ] ].
	^ self passed
]
