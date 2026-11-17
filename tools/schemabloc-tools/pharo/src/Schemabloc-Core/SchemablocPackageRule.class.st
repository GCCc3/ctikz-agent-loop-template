"
I require the schemabloc package.
"
Class {
	#name : 'SchemablocPackageRule',
	#superclass : 'SchemablocLintRule',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocPackageRule >> id [ ^ 'schemabloc_package' ]
{ #category : 'evaluating' }
SchemablocPackageRule >> evaluate: aModel context: aDictionary [
	(aModel hasPackage: 'schemabloc')
		ifTrue: [ ^ self passed ].
	^ self failed: 'The source does not load the schemabloc package' line: nil
]
