"
I check caller-supplied labels.
"
Class {
	#name : 'SchemablocRequiredLabelsRule',
	#superclass : 'SchemablocLintRule',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocRequiredLabelsRule >> id [ ^ 'required_labels' ]
{ #category : 'private' }
SchemablocRequiredLabelsRule >> normalize: aString [
	^ ((aString asString copyReplaceAll: '$' with: '') trimBoth) asLowercase
]
{ #category : 'evaluating' }
SchemablocRequiredLabelsRule >> evaluate: aModel context: aDictionary [
	| labels required |
	labels := aModel labels collect: [ :each | self normalize: each ].
	required := aDictionary at: 'required_labels' ifAbsent: [ #() ].
	required do: [ :each |
		(labels includes: (self normalize: each)) ifFalse: [
			^ self failed: ('Missing required label: ', each) line: nil ] ].
	^ self passed
]
