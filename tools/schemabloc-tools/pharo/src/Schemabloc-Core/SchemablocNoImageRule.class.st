"
I reject image inclusion in a schemabloc source.
"
Class {
	#name : 'SchemablocNoImageRule',
	#superclass : 'SchemablocLintRule',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocNoImageRule >> id [ ^ 'no_image_inclusion' ]
{ #category : 'evaluating' }
SchemablocNoImageRule >> evaluate: aModel context: aDictionary [
	| source |
	source := aModel source.
	((source includesSubstring: '\includegraphics')
		or: [ (source includesSubstring: 'control_diagram.png')
			or: [ source includesSubstring: 'target.png' ] ])
		ifFalse: [ ^ self passed ].
	^ self failed: 'The source includes an image' line: nil
]
