"
I am the facade for the schemabloc snippet catalog.
"
Class {
	#name : 'SchemablocCatalogService',
	#superclass : 'Object',
	#instVars : [ 'catalog', 'renderer', 'lookup' ],
	#classVars : [ 'Current' ],
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocCatalogService class >> default [
	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
SchemablocCatalogService class >> reset [ Current := nil ]

{ #category : 'initialization' }
SchemablocCatalogService >> initialize [
	super initialize.
	catalog := SchemablocSnippetCatalog default.
	renderer := SchemablocSnippetRenderer new.
	lookup := SchemablocComponentLookup default
]

{ #category : 'accessing' }
SchemablocCatalogService >> catalog [ ^ catalog ]
{ #category : 'accessing' }
SchemablocCatalogService >> renderer [ ^ renderer ]
{ #category : 'accessing' }
SchemablocCatalogService >> lookup [ ^ lookup ]

{ #category : 'private' }
SchemablocCatalogService >> ensureCatalogAvailable [
	(catalog isNil or: [ catalog validationWarnings notEmpty ])
		ifTrue: [ DsktError code: 'catalog_unavailable' message: 'The snippet catalog failed to load' ]
]

{ #category : 'operations' }
SchemablocCatalogService >> listSnippets: aDictionary [
	| result |
	self ensureCatalogAvailable.
	result := catalog search: aDictionary.
	^ Dictionary new
		at: 'snippets' put: (result collect: [ :each | each asDictionary ]);
		at: 'catalog_version' put: catalog catalogVersion;
		yourself
]

{ #category : 'operations' }
SchemablocCatalogService >> getSnippetRequest: request [
	| id |
	id := request at: 'id' ifAbsent: [ DsktError code: 'invalid_request' message: 'id is required' ].
	^ self getSnippet: id
]

{ #category : 'operations' }
SchemablocCatalogService >> getSnippet: anId [
	| snippet |
	self ensureCatalogAvailable.
	snippet := catalog snippetNamed: anId.
	snippet ifNil: [ DsktError code: 'snippet_not_found' message: 'Unknown snippet: ' , anId printString ].
	^ Dictionary new
		at: 'snippet' put: snippet asDictionary;
		at: 'catalog_version' put: catalog catalogVersion;
		yourself
]

{ #category : 'operations' }
SchemablocCatalogService >> renderSnippet: request [
	| id snippet parameters |
	self ensureCatalogAvailable.
	id := request at: 'snippet_id' ifAbsent: [ DsktError code: 'invalid_request' message: 'snippet_id is required' ].
	snippet := catalog snippetNamed: id.
	snippet ifNil: [ DsktError code: 'snippet_not_found' message: 'Unknown snippet: ' , id printString ].
	parameters := request at: 'parameters' ifAbsent: [ Dictionary new ].
	^ renderer render: snippet parameters: parameters
]

{ #category : 'operations' }
SchemablocCatalogService >> lookupComponent: request [
	| name info snippetIds |
	self ensureCatalogAvailable.
	name := request at: 'component' ifAbsent: [ DsktError code: 'invalid_request' message: 'component is required' ].
	info := lookup lookup: name.
	info ifNil: [
		^ Dictionary new
			at: 'found' put: false;
			at: 'component' put: name;
			at: 'suggestions' put: (lookup knownComponents keys asSortedCollection: [ :a :b | a <= b ]) asArray;
			yourself ].
	snippetIds := catalog snippets select: [ :each |
		(each tags includes: name) or: [ each id = ('schemabloc/' , name) ] ].
	info snippetIds: (snippetIds collect: [ :each | each id ]).
	^ Dictionary new
		at: 'found' put: true;
		at: 'component' put: name;
		at: 'description' put: info description;
		at: 'info' put: info asDictionary;
		yourself
]
