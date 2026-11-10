"
I am a Beacon signal describing one measurement tool call.
"
Class {
	#name : 'PmdtToolCallSignal',
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
		'imagePath',
		'imageSha256',
		'regionCount',
		'emptyRegionCount',
		'outputWritten',
		'resultBytes'
	],
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'initialization' }
PmdtToolCallSignal >> initialize [
	super initialize.
	phase := 'server'.
	warningCodes := #().
	regionCount := 0.
	emptyRegionCount := 0.
	outputWritten := false.
	resultBytes := 0
]

{ #category : 'accessing' }
PmdtToolCallSignal >> runId [ ^ runId ]
{ #category : 'accessing' }
PmdtToolCallSignal >> runId: anObject [ runId := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> sequence [ ^ sequence ]
{ #category : 'accessing' }
PmdtToolCallSignal >> sequence: anObject [ sequence := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> phase [ ^ phase ]
{ #category : 'accessing' }
PmdtToolCallSignal >> phase: anObject [ phase := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> requestId [ ^ requestId ]
{ #category : 'accessing' }
PmdtToolCallSignal >> requestId: anObject [ requestId := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> clientId [ ^ clientId ]
{ #category : 'accessing' }
PmdtToolCallSignal >> clientId: anObject [ clientId := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> clientRole [ ^ clientRole ]
{ #category : 'accessing' }
PmdtToolCallSignal >> clientRole: anObject [ clientRole := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> tool [ ^ tool ]
{ #category : 'accessing' }
PmdtToolCallSignal >> tool: anObject [ tool := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> outcome [ ^ outcome ]
{ #category : 'accessing' }
PmdtToolCallSignal >> outcome: anObject [ outcome := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> errorCode [ ^ errorCode ]
{ #category : 'accessing' }
PmdtToolCallSignal >> errorCode: anObject [ errorCode := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> warningCodes [ ^ warningCodes ifNil: [ #() ] ]
{ #category : 'accessing' }
PmdtToolCallSignal >> warningCodes: anObject [ warningCodes := anObject ifNil: [ #() ] ]
{ #category : 'accessing' }
PmdtToolCallSignal >> durationMs [ ^ durationMs ]
{ #category : 'accessing' }
PmdtToolCallSignal >> durationMs: anObject [ durationMs := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> imagePath [ ^ imagePath ]
{ #category : 'accessing' }
PmdtToolCallSignal >> imagePath: anObject [ imagePath := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> imageSha256 [ ^ imageSha256 ]
{ #category : 'accessing' }
PmdtToolCallSignal >> imageSha256: anObject [ imageSha256 := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> regionCount [ ^ regionCount ]
{ #category : 'accessing' }
PmdtToolCallSignal >> regionCount: anObject [ regionCount := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> emptyRegionCount [ ^ emptyRegionCount ]
{ #category : 'accessing' }
PmdtToolCallSignal >> emptyRegionCount: anObject [ emptyRegionCount := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> outputWritten [ ^ outputWritten ]
{ #category : 'accessing' }
PmdtToolCallSignal >> outputWritten: anObject [ outputWritten := anObject ]
{ #category : 'accessing' }
PmdtToolCallSignal >> resultBytes [ ^ resultBytes ]
{ #category : 'accessing' }
PmdtToolCallSignal >> resultBytes: anObject [ resultBytes := anObject ]

{ #category : 'converting' }
PmdtToolCallSignal >> asDictionary [
	^ Dictionary new
		at: 'schema_version' put: PmdtVersion schemaVersion;
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
		at: 'image_path' put: self imagePath;
		at: 'image_sha256' put: self imageSha256;
		at: 'region_count' put: self regionCount;
		at: 'empty_region_count' put: self emptyRegionCount;
		at: 'output_written' put: self outputWritten;
		at: 'result_bytes' put: self resultBytes;
		yourself
]
