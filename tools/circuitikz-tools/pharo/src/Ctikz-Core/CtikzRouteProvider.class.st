"
I am the CircuitTikZ domain route provider for the shared DsktServer.

I install /ctikz/* routes on the common server and report catalog and lint health.
I hold the catalog and lint services but no HTTP, envelope, trace, or lifecycle
logic.
"
Class {
	#name : 'CtikzRouteProvider',
	#superclass : 'DsktRouteProvider',
	#instVars : [
		'catalogService',
		'lintService'
	],
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'instance creation' }
CtikzRouteProvider class >> default [
	^ self new
]

{ #category : 'initialization' }
CtikzRouteProvider class >> initialize [
	DsktRouteRegistry register: self new
]

{ #category : 'initialization' }
CtikzRouteProvider >> initialize [
	super initialize
]

{ #category : 'accessing' }
CtikzRouteProvider >> name [ ^ 'ctikz' ]

{ #category : 'accessing' }
CtikzRouteProvider >> catalogService [
	^ catalogService ifNil: [ catalogService := CtikzCatalogService default ]
]

{ #category : 'accessing' }
CtikzRouteProvider >> lintService [
	^ lintService ifNil: [ lintService := CtikzLintService default ]
]

{ #category : 'routes' }
CtikzRouteProvider >> installRoutesOn: server [
	server teapot
		GET: '/ctikz/health' -> [ :request | server handleHealth: 'ctikz' request: request ];
		GET: '/ctikz/snippets' -> [ :request | server handleOperation: 'ctikz_list_snippets' selector: #listSnippets: request: request params: (self queryParamsFor: request keys: #(q tag component kind)) service: self catalogService details: [ :result | self catalogDetailsFor: result ] ];
		GET: '/ctikz/snippets/<category>/<name>' -> [ :request |
			server handleOperation: 'ctikz_get_snippet'
				selector: #getSnippetRequest:
				request: request
				params: (Dictionary new
					at: 'id' put: ((request at: #category ifAbsent: [ '' ]) , '/' , (request at: #name ifAbsent: [ '' ]));
					yourself)
				service: self catalogService
				details: [ :result | self catalogDetailsFor: result ] ];
		GET: '/ctikz/snippets/<id>' -> [ :request | server handleOperation: 'ctikz_get_snippet' selector: #getSnippetRequest: request: request params: (self queryParamsFor: request keys: #(id)) service: self catalogService details: [ :result | self catalogDetailsFor: result ] ];
		POST: '/ctikz/render_snippet' -> [ :request | server handleOperation: 'ctikz_render_snippet' selector: #renderSnippet: request: request service: self catalogService details: [ :result | self catalogDetailsFor: result ] ];
		POST: '/ctikz/components' -> [ :request | server handleOperation: 'ctikz_lookup_component' selector: #lookupComponent: request: request service: self catalogService details: [ :result | self catalogDetailsFor: result ] ];
		POST: '/ctikz/lint' -> [ :request | server handleOperation: 'ctikz_lint_source' selector: #lintSource: request: request service: self lintService details: [ :result | self lintDetailsFor: result ] ]
]

{ #category : 'health' }
CtikzRouteProvider >> health [
	^ Dictionary new
		at: 'status' put: 'ok';
		at: 'catalog_status' put: (self catalogService catalog validationWarnings isEmpty ifTrue: [ 'valid' ] ifFalse: [ 'invalid' ]);
		at: 'catalog_version' put: self catalogService catalog catalogVersion;
		at: 'snippet_count' put: self catalogService catalog snippets size;
		at: 'lint_rules_version' put: self lintService rulesVersion;
		yourself
]

{ #category : 'private' }
CtikzRouteProvider >> catalogDetailsFor: result [
	| snippet |
	snippet := (result isKindOf: Dictionary)
		ifTrue: [ result at: 'snippet' ifAbsent: [ nil ] ]
		ifFalse: [ nil ].
	^ Dictionary new
		at: 'tool_family' put: 'catalog';
		at: 'catalog_version' put: ((result isKindOf: Dictionary)
			ifTrue: [ result at: 'catalog_version' ifAbsent: [ self catalogService catalog catalogVersion ] ]
			ifFalse: [ self catalogService catalog catalogVersion ]);
		at: 'snippet_id' put: ((result isKindOf: Dictionary)
			ifTrue: [ result at: 'snippet_id' ifAbsent: [ snippet ifNotNil: [ :each | each at: 'id' ifAbsent: [ nil ] ] ] ]
			ifFalse: [ nil ]);
		yourself
]

{ #category : 'private' }
CtikzRouteProvider >> lintDetailsFor: result [
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
CtikzRouteProvider >> statusFor: code [
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
CtikzRouteProvider >> queryParamsFor: request keys: keys [
	| params |
	params := Dictionary new.
	keys do: [ :key |
		| value |
		value := request at: key ifAbsent: [ nil ].
		value ifNotNil: [ params at: key put: value ] ].
	^ params
]
