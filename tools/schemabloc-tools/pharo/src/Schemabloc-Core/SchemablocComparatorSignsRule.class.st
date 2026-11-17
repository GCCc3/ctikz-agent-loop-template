"
I warn about comparators without visible plus/minus signs.
"
Class {
	#name : 'SchemablocComparatorSignsRule',
	#superclass : 'SchemablocLintRule',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocComparatorSignsRule >> id [ ^ 'comparator_signs' ]
{ #category : 'evaluating' }
SchemablocComparatorSignsRule >> evaluate: aModel context: aDictionary [
	| comparators |
	comparators := aModel definitions select: [ :each | (each at: 'kind') = 'comparator' ].
	comparators isEmpty ifTrue: [ ^ self passed ].
	((aModel source includesSubstring: '+') or: [ aModel source includesSubstring: '-' ])
		ifTrue: [ ^ self passed ].
	^ self warning: 'Comparators are present but no plus/minus signs were found' line: nil
]
