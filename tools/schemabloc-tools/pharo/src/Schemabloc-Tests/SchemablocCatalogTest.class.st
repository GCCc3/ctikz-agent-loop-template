"
I test the schemabloc snippet catalog.
"
Class {
	#name : 'SchemablocCatalogTest',
	#superclass : 'TestCase',
	#category : 'Schemabloc-Tests',
	#package : 'Schemabloc-Tests'
}

{ #category : 'tests' }
SchemablocCatalogTest >> testCatalogHasSnippets [
	| catalog |
	catalog := SchemablocSnippetCatalog default.
	self assert: catalog snippets notEmpty.
	self assert: catalog validationWarnings isEmpty.
	self assert: (catalog snippetNamed: 'block') notNil
]

{ #category : 'tests' }
SchemablocCatalogTest >> testSearchByKind [
	| catalog results |
	catalog := SchemablocSnippetCatalog default.
	results := catalog search: (Dictionary new at: 'kind' put: 'block'; yourself).
	self assert: results notEmpty.
	self assert: (results allSatisfy: [ :each | each kind = 'block' ])
]

{ #category : 'tests' }
SchemablocCatalogTest >> testRenderBlock [
	| snippet result |
	snippet := SchemablocSnippetCatalog default snippetNamed: 'block'.
	result := SchemablocSnippetRenderer new render: snippet parameters: (Dictionary new
		at: 'name' put: 'ctrl';
		at: 'content' put: 'Controller';
		at: 'previous' put: 'in';
		yourself).
	self assert: ((result at: 'source') includesSubstring: '\sbBloc').
	self assert: ((result at: 'source') includesSubstring: 'ctrl')
]

{ #category : 'tests' }
SchemablocCatalogTest >> testLookupComponent [
	| info |
	info := SchemablocComponentLookup default lookup: 'sbBloc'.
	self assert: info notNil.
	self assert: info description equals: 'Process block'
]
