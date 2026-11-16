"
I wrap one route dispatch, emit one Beacon signal, and never mask the real result or error.

I am domain-agnostic: callers pass an optional `details` block that builds a dictionary
of domain facts (image path, snippet id, check counts) stored in the signal's `details`.
"
Class {
	#name : 'DsktToolTrace',
	#superclass : 'Object',
	#category : 'Dskt-Core',
	#package : 'Dskt-Core'
}

{ #category : 'tracing' }
DsktToolTrace class >> tool: aString request: request do: aBlock [
	^ self tool: aString request: request do: aBlock details: nil
]

{ #category : 'tracing' }
DsktToolTrace class >> tool: aString request: request do: aBlock details: aDetailsBlock [
	| signal started result error duration |
	started := Time millisecondClockValue.
	signal := DsktToolCallSignal new
		tool: aString;
		requestId: (request at: 'request_id' ifAbsent: [ UUID new asString ]);
		clientId: (request at: 'client_id' ifAbsent: [ 'unknown' ]);
		clientRole: (request at: 'client_role' ifAbsent: [ 'unknown' ]);
		phase: 'server';
		yourself.
	[ result := aBlock value ]
		on: Error
		do: [ :exception | error := exception ].
	duration := Time millisecondClockValue - started.
	signal durationMs: duration.
	error
		ifNil: [ self fillSuccess: signal result: result request: request details: aDetailsBlock ]
		ifNotNil: [ self fillError: signal error: error ].
	[ Beacon instance announce: signal ] on: Error do: [ :traceError |
		Transcript show: 'DSKT trace emit failed: '; show: traceError messageText; cr ].
	error ifNotNil: [ error signal ].
	^ result
]

{ #category : 'private' }
DsktToolTrace class >> fillSuccess: signal result: result request: request details: aDetailsBlock [
	| warnings details |
	warnings := (result isKindOf: Dictionary) ifTrue: [ result at: 'warnings' ifAbsent: [ #() ] ] ifFalse: [ #() ].
	details := aDetailsBlock ifNil: [ Dictionary new ] ifNotNil: [ aDetailsBlock value: result ].
	details := details ifNil: [ Dictionary new ].
	signal
		outcome: (warnings isEmpty ifTrue: [ 'ok' ] ifFalse: [ 'ok_with_warnings' ]);
		warningCodes: (warnings collect: [ :each | each at: 'code' ifAbsent: [ each asString ] ]) asArray;
		resultBytes: ((result isNil) ifTrue: [ 0 ] ifFalse: [ (DsktCanonicalJson toString: result) asByteArray size ]);
		toolFamily: (details at: 'tool_family' ifAbsent: [ nil ]);
		snippetId: (details at: 'snippet_id' ifAbsent: [ nil ]);
		sourcePath: (details at: 'source_path' ifAbsent: [ nil ]);
		checkCounts: (details at: 'check_counts' ifAbsent: [ nil ]);
		catalogVersion: (details at: 'catalog_version' ifAbsent: [ nil ]);
		lintRulesVersion: (details at: 'lint_rules_version' ifAbsent: [ nil ]);
		details: details
]

{ #category : 'private' }
DsktToolTrace class >> fillError: signal error: error [
	signal
		outcome: 'error';
		errorCode: ((error respondsTo: #code) ifTrue: [ error code ] ifFalse: [ 'internal_error' ]);
		warningCodes: #();
		resultBytes: 0;
		details: ((error respondsTo: #details) ifTrue: [ error details ] ifFalse: [ Dictionary new ])
]
