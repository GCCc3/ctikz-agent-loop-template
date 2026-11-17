"
I warn about manual rectangles that mimic blocks.
"
Class {
	#name : 'SchemablocManualBlockRule',
	#superclass : 'SchemablocLintRule',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocManualBlockRule >> id [ ^ 'manual_blocks' ]
{ #category : 'evaluating' }
SchemablocManualBlockRule >> evaluate: aModel context: aDictionary [
	aModel manualRectangles = 0 ifTrue: [ ^ self passed ].
	^ self warning: ('Manual rectangle blocks found: ', aModel manualRectangles printString) line: nil
]
