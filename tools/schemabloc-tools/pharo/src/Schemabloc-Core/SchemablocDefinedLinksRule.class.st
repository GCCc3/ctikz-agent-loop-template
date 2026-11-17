"
I require return links to refer to a named link.
"
Class {
	#name : 'SchemablocDefinedLinksRule',
	#superclass : 'SchemablocLintRule',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocDefinedLinksRule >> id [ ^ 'defined_links' ]
{ #category : 'evaluating' }
SchemablocDefinedLinksRule >> evaluate: aModel context: aDictionary [
	| names |
	names := aModel definedLinks asSet.
	aModel linkReferences do: [ :each |
		(names includes: (each at: 'name')) ifFalse: [
			^ self failed: ('Undefined link: ', (each at: 'name')) line: (each at: 'line') ] ].
	^ self passed
]
