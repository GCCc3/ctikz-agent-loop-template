"
I am the rule that fails when the source includes an image.

I check active source for includegraphics or reference/target.png.
"
Class {
	#name : 'CtikzNoImageInclusionRule',
	#superclass : 'CtikzLintRule',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzNoImageInclusionRule >> id [ ^ 'no_image_inclusion' ]

{ #category : 'evaluating' }
CtikzNoImageInclusionRule >> evaluate: model context: context [
	| matches |
	matches := model forbiddenMatches select: [ :each |
		(each at: 'pattern') = '\includegraphics' or: [ (each at: 'pattern') = 'reference/target.png' ] ].
	matches ifEmpty: [ ^ self passed ].
	^ self failed: 'The source includes an image' line: (matches first at: 'line')
]
