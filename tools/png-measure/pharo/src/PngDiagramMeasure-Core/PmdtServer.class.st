"
I expose the measurement service over typed Teapot JSON endpoints.
"
Class {
	#name : 'PmdtServer',
	#superclass : 'Object',
	#instVars : [
		'teapot',
		'traceLogger',
		'service'
	],
	#classVars : [
		'Current'
	],
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'accessing' }
PmdtServer class >> current [ ^ Current ]
{ #category : 'accessing' }
PmdtServer class >> current: anObject [ Current := anObject ]

{ #category : 'lifecycle' }
PmdtServer class >> installStartup [
	Smalltalk addToStartUpList: self.
	Smalltalk addToShutDownList: self.
	PmdtSettings ensureOutputRoot.
	self traceLoggerClass
]

{ #category : 'lifecycle' }
PmdtServer class >> startUp: resuming [
	| server |
	PmdtSettings autostart ifFalse: [ ^ self ].
	Current ifNotNil: [ ^ Current ].
	server := self new.
	[
		server start.
		Current := server ]
		on: Error
		do: [ :error |
			Transcript showln: 'PDMT server start failed: ' , error messageText ]
]

{ #category : 'lifecycle' }
PmdtServer class >> shutDown: quitting [
	Current ifNotNil: [
		Current stop.
		Current := nil ]
]

{ #category : 'lifecycle' }
PmdtServer class >> restart [
	self shutDown: false.
	^ self startUp: true
]

{ #category : 'accessing' }
PmdtServer class >> traceLoggerClass [
	^ PmdtTraceLogger
]

{ #category : 'initialization' }
PmdtServer >> initialize [
	super initialize.
	service := PmdtService default.
	traceLogger := PmdtTraceLogger new.
	teapot := Teapot configure: {
		#port -> PmdtSettings port.
		#bindAddress -> #[127 0 0 1] }.
	self installRoutes
]

{ #category : 'accessing' }
PmdtServer >> teapot [ ^ teapot ]
{ #category : 'accessing' }
PmdtServer >> traceLogger [ ^ traceLogger ]
{ #category : 'accessing' }
PmdtServer >> service [ ^ service ]

{ #category : 'routes' }
PmdtServer >> installRoutes [
	teapot
		GET: '/png/health' -> [ :request | self handleHealth: request ];
		GET: '/png/trace' -> [ :request | self handleTrace: request ];
		POST: '/png/inspect_image' -> [ :request | self handleOperation: 'png_inspect_image' selector: #inspectImage: request: request ];
		POST: '/png/make_ink_mask' -> [ :request | self handleOperation: 'png_make_ink_mask' selector: #makeInkMask: request: request ];
		POST: '/png/measure_bounds' -> [ :request | self handleOperation: 'png_measure_bounds' selector: #measureBounds: request: request ];
		POST: '/png/measure_regions' -> [ :request | self handleOperation: 'png_measure_regions' selector: #measureRegions: request: request ];
		POST: '/png/normalize_geometry' -> [ :request | self handleOperation: 'png_normalize_geometry' selector: #normalizeGeometry: request: request ];
		POST: '/png/create_baseline' -> [ :request | self handleOperation: 'png_create_baseline' selector: #createBaseline: request: request ]
]

{ #category : 'controlling' }
PmdtServer >> start [
	traceLogger start.
	[ teapot start ]
		on: Error
		do: [ :error |
			traceLogger stop.
			error signal ]
]

{ #category : 'controlling' }
PmdtServer >> stop [
	teapot ifNotNil: [ teapot stop ].
	traceLogger ifNotNil: [ traceLogger stop ]
]

{ #category : 'handling' }
PmdtServer >> handleOperation: toolName selector: selector request: teaRequest [
	| body request response |
	^ [
		[
			body := teaRequest entity isNil ifTrue: [ '' ] ifFalse: [ teaRequest entity string ].
			request := [ body isEmpty
				ifTrue: [ Dictionary new ]
				ifFalse: [ NeoJSONReader fromString: body ] ]
				on: Error
				do: [ :parseError | PmdtError code: 'invalid_request' message: 'Malformed JSON request body' ].
			(request isKindOf: Dictionary)
				ifFalse: [ PmdtError code: 'invalid_request' message: 'The request body must be a JSON object' ].
			self attachTraceHeaders: teaRequest to: request.
			response := PmdtToolTrace
				tool: toolName
				request: request
				do: [ service perform: selector with: request ].
			self jsonResponse: (self successEnvelope: response) code: 200 ]
			on: PmdtError
			do: [ :error | self jsonResponse: (self errorEnvelope: error) code: (self statusFor: error code) ] ]
		on: Error
		do: [ :error |
			PmdtSettings debug ifTrue: [ error signalerContext printString traceCr ].
			self jsonResponse: (self internalErrorEnvelope: error) code: 500 ]
]

{ #category : 'handling' }
PmdtServer >> handleHealth: teaRequest [
	| result trace |
	trace := Dictionary new
		at: 'status' put: (traceLogger ifNil: [ 'unavailable' ] ifNotNil: [ traceLogger status ]);
		at: 'log_path' put: (traceLogger ifNil: [ nil ] ifNotNil: [ traceLogger file pathString ]);
		at: 'entries' put: (traceLogger ifNil: [ 0 ] ifNotNil: [ traceLogger entries size ]);
		at: 'bytes' put: (traceLogger ifNil: [ 0 ] ifNotNil: [ traceLogger file exists ifTrue: [ traceLogger file size ] ifFalse: [ 0 ] ]);
		yourself.
	result := Dictionary new
		at: 'status' put: 'ok';
		at: 'tool_version' put: PmdtVersion toolVersion;
		at: 'port' put: PmdtSettings port;
		at: 'output_root' put: PmdtSettings outputRoot;
		at: 'cache' put: (Dictionary new
			at: 'images' put: service repository imageCount;
			at: 'masks' put: service repository maskCount;
			yourself);
		at: 'trace' put: trace;
		yourself.
	^ self jsonResponse: (self successEnvelope: result) code: 200
]

{ #category : 'handling' }
PmdtServer >> handleTrace: teaRequest [
	| limit since tool client result |
	limit := [ (teaRequest at: 'limit' ifAbsent: [ '50' ]) asInteger ] on: Error do: [ :e | 50 ].
	limit := limit max: 1; min: 500.
	since := [ (teaRequest at: 'since_sequence' ifAbsent: [ nil ]) ifNotNil: [ :value | value asInteger ] ] on: Error do: [ :e | nil ].
	tool := teaRequest at: 'tool' ifAbsent: [ nil ].
	client := teaRequest at: 'client_id' ifAbsent: [ nil ].
	result := PmdtTraceReport from: traceLogger limit: limit sinceSequence: since tool: tool clientId: client.
	^ self jsonResponse: (self successEnvelope: result) code: 200
]

{ #category : 'private' }
PmdtServer >> attachTraceHeaders: teaRequest to: request [
	| headers |
	headers := teaRequest headers.
	#('X-PDMT-Request-Id' 'X-PDMT-Client-Id' 'X-PDMT-Client-Role') do: [ :name |
		(headers at: name ifAbsent: [ nil ]) ifNotNil: [ :value |
			name = 'X-PDMT-Request-Id' ifTrue: [ request at: 'request_id' put: value ].
			name = 'X-PDMT-Client-Id' ifTrue: [ request at: 'client_id' put: value ].
			name = 'X-PDMT-Client-Role' ifTrue: [ request at: 'client_role' put: value ] ] ].
	request at: 'request_id' ifAbsent: [ request at: 'request_id' put: UUID new asString ].
	request at: 'client_id' ifAbsent: [ request at: 'client_id' put: 'unknown' ].
	request at: 'client_role' ifAbsent: [ request at: 'client_role' put: 'unknown' ]
]

{ #category : 'private' }
PmdtServer >> successEnvelope: result [
	^ Dictionary new
		at: 'success' put: true;
		at: 'schema_version' put: PmdtVersion schemaVersion;
		at: 'tool_version' put: PmdtVersion toolVersion;
		at: 'result' put: result;
		yourself
]

{ #category : 'private' }
PmdtServer >> errorEnvelope: error [
	^ Dictionary new
		at: 'success' put: false;
		at: 'schema_version' put: PmdtVersion schemaVersion;
		at: 'tool_version' put: PmdtVersion toolVersion;
		at: 'error' put: error asDictionary;
		yourself
]

{ #category : 'private' }
PmdtServer >> internalErrorEnvelope: error [
	^ Dictionary new
		at: 'success' put: false;
		at: 'schema_version' put: PmdtVersion schemaVersion;
		at: 'tool_version' put: PmdtVersion toolVersion;
		at: 'error' put: (Dictionary new
			at: 'code' put: 'internal_error';
			at: 'message' put: 'Internal measurement error';
			at: 'details' put: Dictionary new;
			yourself);
		yourself
]

{ #category : 'private' }
PmdtServer >> statusFor: code [
	^ (#('invalid_request' 'path_outside_repo' 'unknown_basis' 'invalid_region' 'sha_mismatch' 'output_path_rejected' 'image_too_large') includes: code)
		ifTrue: [ 400 ]
		ifFalse: [
			(#('image_not_found') includes: code)
				ifTrue: [ 404 ]
				ifFalse: [
					(#('not_a_png' 'truncated_png' 'invalid_chunk' 'crc_mismatch' 'unsupported_bit_depth' 'unsupported_interlace' 'unsupported_color_type' 'decompression_failed' 'trailing_idat_data') includes: code)
						ifTrue: [ 422 ]
						ifFalse: [ 500 ] ] ]
]

{ #category : 'private' }
PmdtServer >> jsonResponse: dictionary code: anInteger [
	| json response |
	json := PmdtCanonicalJson toString: dictionary.
	response := ZnResponse new.
	response statusLine: (ZnStatusLine code: anInteger).
	response entity: (ZnEntity text: json).
	response headers at: 'Content-Type' put: 'application/json; charset=utf-8'.
	^ response
]
