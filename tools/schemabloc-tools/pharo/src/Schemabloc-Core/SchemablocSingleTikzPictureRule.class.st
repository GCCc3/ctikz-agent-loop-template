"
I require exactly one tikzpicture.
"
Class {
	#name : 'SchemablocSingleTikzPictureRule',
	#superclass : 'SchemablocLintRule',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocSingleTikzPictureRule >> id [ ^ 'single_tikzpicture' ]
{ #category : 'evaluating' }
SchemablocSingleTikzPictureRule >> evaluate: aModel context: aDictionary [
	aModel tikzPictures = 1 ifTrue: [ ^ self passed ].
	^ self failed: ('Expected exactly one tikzpicture, found ', aModel tikzPictures printString) line: nil
]
