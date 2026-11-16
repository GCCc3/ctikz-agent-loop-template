"
I test the final snippet set and the catalog policy.
"
Class {
	#name : 'CtikzCatalogTest',
	#superclass : 'CtikzTestCase',
	#category : 'Ctikz-Tests',
	#package : 'Ctikz-Tests'
}

{ #category : 'tests' }
CtikzCatalogTest >> testCatalogIsValid [
	self assert: CtikzSnippetCatalog default validationWarnings isEmpty
]

{ #category : 'tests' }
CtikzCatalogTest >> testFinalSnippetSet [
	| ids expected |
	ids := (CtikzSnippetCatalog default snippets collect: [ :each | each id ]) asSortedCollection.
	expected := #(
		'annotation/arrow'
		'component/L'
		'component/R'
		'component/ac-dc-converter'
		'component/bipole'
		'component/generic'
		'component/line'
		'component/sV'
		'coordinate/point'
		'group/dashed-rectangle'
		'label/generic'
		'preamble/standalone-circuitikz'
	) asSortedCollection.
	self assert: ids asArray equals: expected asArray
]

{ #category : 'tests' }
CtikzCatalogTest >> testNoRectangleOrDiagonalEntries [
	| ids |
	ids := CtikzSnippetCatalog default snippets collect: [ :each | each id ].
	self deny: (ids includes: 'component/rectangle').
	self deny: (ids includes: 'component/diagonal')
]

{ #category : 'tests' }
CtikzCatalogTest >> testLabelHasNoDefaultText [
	| label text |
	label := CtikzSnippetCatalog default snippetNamed: 'label/generic'.
	text := label parameterSchema detect: [ :each | each name = 'text' ].
	self assert: text required.
	self assert: text default isNil
]

{ #category : 'tests' }
CtikzCatalogTest >> testLookupDescriptionsAndSnippetIds [
	| service |
	service := CtikzCatalogService default.
	#(('L' 'inductor' 'component/L')
	  ('R' 'resistor' 'component/R')
	  ('generic' 'generic bipole' 'component/generic')
	  ('sV' 'independent voltage source' 'component/sV')) do: [ :row |
		| result info |
		result := service lookupComponent: (Dictionary new at: 'component' put: row first; yourself).
		info := result at: 'info'.
		self assert: (result at: 'description') equals: row second.
		self assert: ((info at: 'snippet_ids') includes: row third) ]
]

{ #category : 'tests' }
CtikzCatalogTest >> testReloadIsIdempotent [
	| catalog version |
	catalog := CtikzSnippetCatalog default.
	version := catalog catalogVersion.
	catalog reload.
	self assert: catalog catalogVersion equals: version.
	self assert: catalog snippets size equals: 12.
	self assert: catalog validationWarnings isEmpty
]

{ #category : 'tests' }
CtikzCatalogTest >> testUnknownSnippet [
	self assertCode: [ CtikzCatalogService default getSnippet: 'missing/snippet' ] equals: 'snippet_not_found'
]

{ #category : 'tests' }
CtikzCatalogTest >> testDuplicateIdFailsCatalog [
	| catalog first second |
	first := CtikzSnippet new
		id: 'duplicate/test';
		title: 'First';
		kind: 'test';
		mustacheSource: '\draw (a) -- (b);';
		parameterSchema: #();
		yourself.
	second := CtikzSnippet new
		id: 'duplicate/test';
		title: 'Second';
		kind: 'test';
		mustacheSource: '\draw (a) -- (b);';
		parameterSchema: #();
		yourself.
	catalog := CtikzSnippetCatalog new.
	catalog reloadFrom: { first. second }.
	self deny: catalog validationWarnings isEmpty
]

{ #category : 'tests' }
CtikzCatalogTest >> testTargetSpecificTokenAccepted [
	| snippet |
	snippet := CtikzSnippet new
		id: 'gfm/test';
		title: 'Test';
		kind: 'test';
		mustacheSource: '\draw (a) -- (b);';
		parameterSchema: #();
		yourself.
	self assert: (CtikzSnippetValidator new validate: snippet in: CtikzSnippetCatalog default) == snippet
]
