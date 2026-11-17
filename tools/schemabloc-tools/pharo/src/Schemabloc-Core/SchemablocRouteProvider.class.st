"
I am the schemabloc domain route provider for the shared DsktServer.
"
Class {
	#name : 'SchemablocRouteProvider',
	#superclass : 'DsktRouteProvider',
	#instVars : [ 'catalogService', 'lintService' ],
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'instance creation' }
SchemablocRouteProvider class >> default [ ^ self new ]

{ #category : 'initialization' }
SchemablocRouteProvider class >> initialize [
	DsktRouteRegistry register: self new
]

{ #category : 'accessing' }
SchemablocRouteProvider >> name [ ^ 'schemabloc' ]

{ #category : 'accessing' }
SchemablocRouteProvider >> catalogService [
	^ catalogService ifNil: [ catalogService := SchemablocCatalogService default ]
]

{ #category : 'accessing' }
SchemablocRouteProvider >> lintService [
	^ lintService ifNil: [ lintService := SchemablocLintService default ]
]

{ #category : 'routes' }
SchemablocRouteProvider >> installRoutesOn: server [
	server teapot
		GET: '/schemabloc/health' -> [ :request | server handleHealth: 'schemabloc' request: request ];
		GET: '/schemabloc/snippets' -> [ :request | server handleOperation: 'schemabloc_list_snippets' selector: #listSnippets: request: request params: (self queryParamsFor: request keys: #(q tag component kind)) service: self catalogService details: [ :result | self catalogDetailsFor: result ] ];
		GET: '/schemabloc/snippets/<category>/<name>' -> [ :request |
			server handleOperation: 'schemabloc_get_snippet'
				selector: #getSnippetRequest:
				request: request
				params: (Dictionary new
					at: 'id' put: ((request at: #category ifAbsent: [ '' ]) , '/' , (request at: #name ifAbsent: [ '' ]));
					yourself)
				service: self catalogService
				details: [ :result | self catalogDetailsFor: result ] ];
		GET: '/schemabloc/snippets/<id>' -> [ :request | server handleOperation: 'schemabloc_get_snippet' selector: #getSnippetRequest: request: request params: (self queryParamsFor: request keys: #(id)) service: self catalogService details: [ :result | self catalogDetailsFor: result ] ];
		POST: '/schemabloc/render_snippet' -> [ :request | server handleOperation: 'schemabloc_render_snippet' selector: #renderSnippet: request: request service: self catalogService details: [ :result | self catalogDetailsFor: result ] ];
		POST: '/schemabloc/components' -> [ :request | server handleOperation: 'schemabloc_lookup_component' selector: #lookupComponent: request: request service: self catalogService details: [ :result | self catalogDetailsFor: result ] ];
		POST: '/schemabloc/lint' -> [ :request | server handleOperation: 'schemabloc_lint_source' selector: #lintSource: request: request service: self lintService details: [ :result | self lintDetailsFor: result ] ]
]

{ #category : 'health' }
SchemablocRouteProvider >> health [
	^ Dictionary new
		at: 'status' put: 'ok';
		at: 'catalog_status' put: (self catalogService catalog validationWarnings isEmpty ifTrue: [ 'valid' ] ifFalse: [ 'invalid' ]);
		at: 'catalog_version' put: self catalogService catalog catalogVersion;
		at: 'snippet_count' put: self catalogService catalog snippets size;
		at: 'lint_rules_version' put: self lintService rulesVersion;
		at: 'schemabloc_sty_path' put: (DsktSettings env: 'DSKT_SCHEMABLOC_STY' default: '');
		at: 'schemabloc_version' put: (DsktSettings env: 'DSKT_SCHEMABLOC_VERSION' default: 'unknown');
		yourself
]

{ #category : 'private' }
SchemablocRouteProvider >> catalogDetailsFor: result [
	^ Dictionary new
		at: 'tool_family' put: 'catalog';
		at: 'catalog_version' put: ((result isKindOf: Dictionary)
			ifTrue: [ result at: 'catalog_version' ifAbsent: [ self catalogService catalog catalogVersion ] ]
			ifFalse: [ self catalogService catalog catalogVersion ]);
		at: 'snippet_id' put: ((result isKindOf: Dictionary)
			ifTrue: [ result at: 'snippet_id' ifAbsent: [ (result at: 'snippet' ifAbsent: [ nil ]) ifNotNil: [ :each | each at: 'id' ifAbsent: [ nil ] ] ] ]
			ifFalse: [ nil ]);
		yourself
]

{ #category : 'private' }
SchemablocRouteProvider >> lintDetailsFor: result [
	^ Dictionary new
		at: 'tool_family' put: 'lint';
		at: 'source_path' put: ((result isKindOf: Dictionary)
			ifTrue: [ result at: 'source_path' ifAbsent: [ nil ] ]
			ifFalse: [ nil ]);
		at: 'check_counts' put: ((result isKindOf: Dictionary)
			ifTrue: [ result at: 'summary' ifAbsent: [ nil ] ]
			ifFalse: [ nil ]);
		at: 'lint_rules_version' put: self lintService rulesVersion;
		yourself
]

{ #category : 'status' }
SchemablocRouteProvider >> statusFor: code [
	(#( 'invalid_request' 'path_outside_repo' 'source_too_large' 'unsupported_encoding' ) includes: code)
		ifTrue: [ ^ 400 ].
	(#( 'snippet_not_found' 'source_not_found' ) includes: code)
		ifTrue: [ ^ 404 ].
	(#( 'unknown_parameter' 'missing_parameter' 'invalid_parameter' 'snippet_validation_failed' 'template_render_failed' ) includes: code)
		ifTrue: [ ^ 422 ].
	(#( 'catalog_unavailable' 'internal_error' 'unknown_domain' ) includes: code)
		ifTrue: [ ^ 500 ].
	^ 500
]

{ #category : 'private' }
SchemablocRouteProvider >> queryParamsFor: request keys: keys [
	| params |
	params := Dictionary new.
	keys do: [ :key |
		| value |
		value := request at: key ifAbsent: [ nil ].
		value ifNotNil: [ params at: key put: value ] ].
	^ params
]
