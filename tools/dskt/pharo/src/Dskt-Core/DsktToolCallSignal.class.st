"
I am a Beacon signal describing one tool call across every domain.

I carry only generic fields. Domain-specific facts (image path, image hash, region
counts, snippet id, check counts) travel in the `details` dictionary, so adding a
domain never requires changing this class.
"
Class {
	#name : 'DsktToolCallSignal',
	#superclass : 'BeaconSignal',
	#instVars : [
		'runId',
		'sequence',
		'phase',
		'requestId',
		'clientId',
		'clientRole',
		'tool',
		'outcome',
		'errorCode',
		'warningCodes',
		'durationMs',
		'resultBytes',
		'toolFamily',
		'snippetId',
		'sourcePath',
		'checkCounts',
		'catalogVersion',
		'lintRulesVersion',
		'details'
	],
	#category : 'Dskt-Core',
	#package : 'Dskt-Core'
}

{ #category : 'initialization' }
DsktToolCallSignal >> initialize [
	super initialize.
	phase := 'server'.
	warningCodes := #().
	resultBytes := 0.
	details := Dictionary new
]

{ #category : 'accessing' }
DsktToolCallSignal >> runId [ ^ runId ]
{ #category : 'accessing' }
DsktToolCallSignal >> runId: anObject [ runId := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> sequence [ ^ sequence ]
{ #category : 'accessing' }
DsktToolCallSignal >> sequence: anObject [ sequence := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> phase [ ^ phase ]
{ #category : 'accessing' }
DsktToolCallSignal >> phase: anObject [ phase := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> requestId [ ^ requestId ]
{ #category : 'accessing' }
DsktToolCallSignal >> requestId: anObject [ requestId := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> clientId [ ^ clientId ]
{ #category : 'accessing' }
DsktToolCallSignal >> clientId: anObject [ clientId := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> clientRole [ ^ clientRole ]
{ #category : 'accessing' }
DsktToolCallSignal >> clientRole: anObject [ clientRole := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> tool [ ^ tool ]
{ #category : 'accessing' }
DsktToolCallSignal >> tool: anObject [ tool := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> outcome [ ^ outcome ]
{ #category : 'accessing' }
DsktToolCallSignal >> outcome: anObject [ outcome := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> errorCode [ ^ errorCode ]
{ #category : 'accessing' }
DsktToolCallSignal >> errorCode: anObject [ errorCode := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> warningCodes [ ^ warningCodes ifNil: [ #() ] ]
{ #category : 'accessing' }
DsktToolCallSignal >> warningCodes: anObject [ warningCodes := anObject ifNil: [ #() ] ]
{ #category : 'accessing' }
DsktToolCallSignal >> durationMs [ ^ durationMs ]
{ #category : 'accessing' }
DsktToolCallSignal >> durationMs: anObject [ durationMs := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> resultBytes [ ^ resultBytes ]
{ #category : 'accessing' }
DsktToolCallSignal >> resultBytes: anObject [ resultBytes := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> toolFamily [ ^ toolFamily ]
{ #category : 'accessing' }
DsktToolCallSignal >> toolFamily: anObject [ toolFamily := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> snippetId [ ^ snippetId ]
{ #category : 'accessing' }
DsktToolCallSignal >> snippetId: anObject [ snippetId := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> sourcePath [ ^ sourcePath ]
{ #category : 'accessing' }
DsktToolCallSignal >> sourcePath: anObject [ sourcePath := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> checkCounts [ ^ checkCounts ]
{ #category : 'accessing' }
DsktToolCallSignal >> checkCounts: anObject [ checkCounts := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> catalogVersion [ ^ catalogVersion ]
{ #category : 'accessing' }
DsktToolCallSignal >> catalogVersion: anObject [ catalogVersion := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> lintRulesVersion [ ^ lintRulesVersion ]
{ #category : 'accessing' }
DsktToolCallSignal >> lintRulesVersion: anObject [ lintRulesVersion := anObject ]
{ #category : 'accessing' }
DsktToolCallSignal >> details [ ^ details ifNil: [ Dictionary new ] ]
{ #category : 'accessing' }
DsktToolCallSignal >> details: anObject [ details := anObject ifNil: [ Dictionary new ] ]

{ #category : 'converting' }
DsktToolCallSignal >> asDictionary [
	^ Dictionary new
		at: 'schema_version' put: DsktVersion schemaVersion;
		at: 'run_id' put: self runId;
		at: 'sequence' put: self sequence;
		at: 'timestamp' put: self timestamp asUTC printString;
		at: 'phase' put: self phase;
		at: 'request_id' put: self requestId;
		at: 'client_id' put: self clientId;
		at: 'client_role' put: self clientRole;
		at: 'tool' put: self tool;
		at: 'outcome' put: self outcome;
		at: 'error_code' put: self errorCode;
		at: 'warning_codes' put: self warningCodes;
		at: 'duration_ms' put: self durationMs;
		at: 'result_bytes' put: self resultBytes;
		at: 'tool_family' put: self toolFamily;
		at: 'snippet_id' put: self snippetId;
		at: 'source_path' put: self sourcePath;
		at: 'check_counts' put: self checkCounts;
		at: 'catalog_version' put: self catalogVersion;
		at: 'lint_rules_version' put: self lintRulesVersion;
		at: 'details' put: self details;
		yourself
]
