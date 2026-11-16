"
I am the facade for the CircuitTikZ snippet catalog.

I expose list, get, render, and lookup operations. I convert domain errors to
DsktError and I contain no tracing. The route provider wraps me with DsktServer.
"
Class {
	#name : 'CtikzCatalogService',
	#superclass : 'Object',
	#instVars : [
		'catalog',
		'renderer',
		'lookup'
	],
	#classVars : [
		'Current'
	],
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzCatalogService class >> default [
	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
CtikzCatalogService class >> reset [
	Current := nil
]

{ #category : 'initialization' }
CtikzCatalogService >> initialize [
	super initialize.
	catalog := CtikzSnippetCatalog default.
	renderer := CtikzSnippetRenderer new.
	lookup := CtikzComponentLookup default
]

{ #category : 'accessing' }
CtikzCatalogService >> catalog [ ^ catalog ]

{ #category : 'accessing' }
CtikzCatalogService >> renderer [ ^ renderer ]

{ #category : 'accessing' }
CtikzCatalogService >> lookup [ ^ lookup ]

{ #category : 'private' }
CtikzCatalogService >> ensureCatalogAvailable [
	(catalog isNil or: [ catalog validationWarnings notEmpty ])
		ifTrue: [ DsktError code: 'catalog_unavailable' message: 'The snippet catalog failed to load' ]
]

{ #category : 'operations' }
CtikzCatalogService >> listSnippets: aDictionary [
	| result |
	self ensureCatalogAvailable.
	result := catalog search: aDictionary.
	^ Dictionary new
		at: 'snippets' put: (result collect: [ :each | each asDictionary ]);
		at: 'catalog_version' put: catalog catalogVersion;
		yourself
]

{ #category : 'operations' }
CtikzCatalogService >> getSnippetRequest: request [
	| id |
	id := request at: 'id' ifAbsent: [ DsktError code: 'invalid_request' message: 'id is required' ].
	^ self getSnippet: id
]

{ #category : 'operations' }
CtikzCatalogService >> getSnippet: anId [
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
CtikzCatalogService >> renderSnippet: request [
	| snippet id parameters |
	self ensureCatalogAvailable.
	id := request at: 'snippet_id' ifAbsent: [ DsktError code: 'invalid_request' message: 'snippet_id is required' ].
	snippet := catalog snippetNamed: id.
	snippet ifNil: [ DsktError code: 'snippet_not_found' message: 'Unknown snippet: ' , id printString ].
	parameters := request at: 'parameters' ifAbsent: [ Dictionary new ].
	(parameters isKindOf: Dictionary)
		ifFalse: [ DsktError code: 'invalid_request' message: 'parameters must be an object' ].
	^ renderer render: snippet parameters: parameters
]

{ #category : 'operations' }
CtikzCatalogService >> lookupComponent: request [
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
		(each tags includes: name) or: [ each id = ('component/' , name) ] ].
	info snippetIds: (snippetIds collect: [ :each | each id ]).
	^ Dictionary new
		at: 'found' put: true;
		at: 'component' put: name;
		at: 'description' put: info description;
		at: 'info' put: info asDictionary;
		yourself
]
