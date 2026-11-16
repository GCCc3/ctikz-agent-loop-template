"
I am the common Teapot server shared by every domain package.

I own the lifecycle, the route registry, the shared envelope, canonical JSON, and
the Beacon trace. I hold no domain classes: domains install their routes through a
DsktRouteProvider and expose their own service object.

Routes:
  GET  /health          common health plus a services map
  GET  /trace           shared trace ring and counts
  domain routes         installed by each provider
"
Class {
	#name : 'DsktServer',
	#superclass : 'Object',
	#instVars : [
		'teapot',
		'traceLogger',
		'registry'
	],
	#classVars : [
		'Current'
	],
	#category : 'Dskt-Core',
	#package : 'Dskt-Core'
}

{ #category : 'accessing' }
DsktServer class >> current [ ^ Current ]
{ #category : 'accessing' }
DsktServer class >> current: anObject [ Current := anObject ]

{ #category : 'lifecycle' }
DsktServer class >> installStartup [
	Smalltalk addToStartUpList: self.
	Smalltalk addToShutDownList: self.
	DsktSettings traceLog asFileReference parent ensureCreateDirectory.
	self traceLoggerClass
]

{ #category : 'lifecycle' }
DsktServer class >> startUp: resuming [
	| server |
	DsktSettings autostart ifFalse: [ ^ self ].
	Current ifNotNil: [ ^ Current ].
	server := self new.
	[
		server start.
		Current := server ]
		on: Error
		do: [ :error |
			Transcript show: 'DSKT server start failed: '; show: error messageText; cr ]
]

{ #category : 'lifecycle' }
DsktServer class >> shutDown: quitting [
	Current ifNotNil: [
		Current stop.
		Current := nil ]
]

{ #category : 'lifecycle' }
DsktServer class >> restart [
	self shutDown: false.
	^ self startUp: true
]

{ #category : 'accessing' }
DsktServer class >> traceLoggerClass [
	^ DsktTraceLogger
]

{ #category : 'initialization' }
DsktServer >> initialize [
	super initialize.
	traceLogger := DsktTraceLogger new.
	registry := DsktRouteRegistry current.
	teapot := Teapot configure: {
		#port -> DsktSettings port.
		#bindAddress -> DsktSettings bindAddress }.
	self installRoutes
]

{ #category : 'accessing' }
DsktServer >> teapot [ ^ teapot ]
{ #category : 'accessing' }
DsktServer >> traceLogger [ ^ traceLogger ]
{ #category : 'accessing' }
DsktServer >> registry [ ^ registry ]
{ #category : 'accessing' }
DsktServer >> providerNamed: name [ ^ registry providerNamed: name ]

{ #category : 'routes' }
DsktServer >> installRoutes [
	teapot
		GET: '/health' -> [ :request | self handleHealth: nil request: request ];
		GET: '/trace' -> [ :request | self handleTrace: request ].
	registry installRoutesOn: self
]

{ #category : 'controlling' }
DsktServer >> start [
	traceLogger start.
	[ teapot start ]
		on: Error
		do: [ :error |
			traceLogger stop.
			error signal ]
]

{ #category : 'controlling' }
DsktServer >> stop [
	teapot ifNotNil: [ teapot stop ].
	traceLogger ifNotNil: [ traceLogger stop ]
]

{ #category : 'handling' }
DsktServer >> handleOperation: toolName selector: selector request: teaRequest [
	^ self handleOperation: toolName selector: selector request: teaRequest service: nil details: nil
]

{ #category : 'handling' }
DsktServer >> handleOperation: toolName selector: selector request: teaRequest service: service details: detailsBlock [
	^ self handleOperation: toolName selector: selector request: teaRequest params: nil service: service details: detailsBlock
]

{ #category : 'handling' }
DsktServer >> handleOperation: toolName selector: selector request: teaRequest params: params service: service details: detailsBlock [
	| body request response |
	^ [
		[
			body := teaRequest entity isNil ifTrue: [ '' ] ifFalse: [ teaRequest entity string ].
			request := [ body isEmpty
				ifTrue: [ Dictionary new ]
				ifFalse: [ NeoJSONReader fromString: body ] ]
				on: Error
				do: [ :parseError | DsktError code: 'invalid_request' message: 'Malformed JSON request body' ].
			(request isKindOf: Dictionary)
				ifFalse: [ DsktError code: 'invalid_request' message: 'The request body must be a JSON object' ].
			params ifNotNil: [
				params keysAndValuesDo: [ :key :value |
					value ifNotNil: [ request at: key asString put: value ] ] ].
			self attachTraceHeaders: teaRequest to: request.
			response := DsktToolTrace
				tool: toolName
				request: request
				do: [ (service ifNil: [ self providerForTool: toolName ]) perform: selector with: request ]
				details: detailsBlock.
			self jsonResponse: (self successEnvelope: response) code: 200 ]
			on: DsktError
			do: [ :error | self jsonResponse: (self errorEnvelope: error) code: (self statusFor: error code) ] ]
		on: Error
		do: [ :error |
			DsktSettings debug ifTrue: [
				error messageText traceCr.
				error signalerContext stackTraceString traceCr ].
			self jsonResponse: (self internalErrorEnvelope: error) code: 500 ]
]

{ #category : 'handling' }
DsktServer >> handleHealth: domain request: teaRequest [
	^ [
		[ | trace result |
		trace := traceLogger health.
		result := domain
			ifNil: [
				Dictionary new
					at: 'status' put: 'ok';
					at: 'tool_version' put: DsktVersion toolVersion;
					at: 'port' put: DsktSettings port;
					at: 'trace' put: trace;
					at: 'services' put: registry health;
					yourself ]
			ifNotNil: [
				| provider |
				provider := registry providerNamed: domain.
				provider ifNil: [ DsktError code: 'unknown_domain' message: 'Unknown domain: ' , domain ].
				provider health ].
		self jsonResponse: (self successEnvelope: result) code: 200 ]
			on: DsktError
			do: [ :error | self jsonResponse: (self errorEnvelope: error) code: (self statusFor: error code) ] ]
		on: Error
		do: [ :error |
			DsktSettings debug ifTrue: [ error messageText traceCr ].
			self jsonResponse: (self internalErrorEnvelope: error) code: 500 ]
]

{ #category : 'handling' }
DsktServer >> handleTrace: teaRequest [
	| limit since tool client result |
	limit := [ (teaRequest at: 'limit' ifAbsent: [ '50' ]) asInteger ] on: Error do: [ :e | 50 ].
	limit := limit max: 1; min: 500.
	since := [ (teaRequest at: 'since_sequence' ifAbsent: [ nil ]) ifNotNil: [ :value | value asInteger ] ] on: Error do: [ :e | nil ].
	tool := teaRequest at: 'tool' ifAbsent: [ nil ].
	client := teaRequest at: 'client_id' ifAbsent: [ nil ].
	result := DsktTraceReport from: traceLogger limit: limit sinceSequence: since tool: tool clientId: client.
	^ self jsonResponse: (self successEnvelope: result) code: 200
]

{ #category : 'private' }
DsktServer >> providerForTool: toolName [
	^ registry providers detect: [ :provider | toolName beginsWith: provider name ] ifNone: [ nil ]
]

{ #category : 'private' }
DsktServer >> attachTraceHeaders: teaRequest to: request [
	| headers |
	headers := teaRequest headers.
	#('X-DSKT-Request-Id' 'X-DSKT-Client-Id' 'X-DSKT-Client-Role') do: [ :name |
		(headers at: name ifAbsent: [ nil ]) ifNotNil: [ :value |
			name = 'X-DSKT-Request-Id' ifTrue: [ request at: 'request_id' put: value ].
			name = 'X-DSKT-Client-Id' ifTrue: [ request at: 'client_id' put: value ].
			name = 'X-DSKT-Client-Role' ifTrue: [ request at: 'client_role' put: value ] ] ].
	request at: 'request_id' ifAbsent: [ request at: 'request_id' put: UUID new asString ].
	request at: 'client_id' ifAbsent: [ request at: 'client_id' put: 'unknown' ].
	request at: 'client_role' ifAbsent: [ request at: 'client_role' put: DsktSettings clientRole ]
]

{ #category : 'private' }
DsktServer >> successEnvelope: result [
	^ Dictionary new
		at: 'success' put: true;
		at: 'schema_version' put: DsktVersion schemaVersion;
		at: 'tool_version' put: DsktVersion toolVersion;
		at: 'result' put: result;
		yourself
]

{ #category : 'private' }
DsktServer >> errorEnvelope: error [
	^ Dictionary new
		at: 'success' put: false;
		at: 'schema_version' put: DsktVersion schemaVersion;
		at: 'tool_version' put: DsktVersion toolVersion;
		at: 'error' put: error asDictionary;
		yourself
]

{ #category : 'private' }
DsktServer >> internalErrorEnvelope: error [
	^ Dictionary new
		at: 'success' put: false;
		at: 'schema_version' put: DsktVersion schemaVersion;
		at: 'tool_version' put: DsktVersion toolVersion;
		at: 'error' put: (Dictionary new
			at: 'code' put: 'internal_error';
			at: 'message' put: 'Internal service error';
			at: 'details' put: Dictionary new;
			yourself);
		yourself
]

{ #category : 'private' }
DsktServer >> statusFor: code [
	registry providers do: [ :provider |
		| status |
		status := provider statusFor: code.
		status ~= 500 ifTrue: [ ^ status ] ].
	^ 500
]

{ #category : 'private' }
DsktServer >> jsonResponse: dictionary code: anInteger [
	| json response |
	json := DsktCanonicalJson toString: dictionary.
	response := ZnResponse new.
	response statusLine: (ZnStatusLine code: anInteger).
	response entity: (ZnEntity text: json).
	response headers at: 'Content-Type' put: 'application/json; charset=utf-8'.
	^ response
]
