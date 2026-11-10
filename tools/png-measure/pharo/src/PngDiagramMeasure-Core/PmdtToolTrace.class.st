"
I wrap one measurement route, emit one Beacon signal, and never mask the real result or error.
"
Class {
	#name : 'PmdtToolTrace',
	#superclass : 'Object',
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'tracing' }
PmdtToolTrace class >> tool: aString request: request do: aBlock [
	| signal started result error duration |
	started := Time millisecondClockValue.
	signal := PmdtToolCallSignal new
		tool: aString;
		requestId: (request at: 'request_id' ifAbsent: [ UUID new asString ]);
		clientId: (request at: 'client_id' ifAbsent: [ 'unknown' ]);
		clientRole: (request at: 'client_role' ifAbsent: [ 'unknown' ]);
		imagePath: (request at: 'image_path' ifAbsent: [ nil ]);
		phase: 'server';
		yourself.
	[ result := aBlock value ]
		on: Error
		do: [ :exception | error := exception ].
	duration := Time millisecondClockValue - started.
	signal durationMs: duration.
	error
		ifNil: [ self fillSuccess: signal result: result request: request ]
		ifNotNil: [ self fillError: signal error: error ].
	[ Beacon instance announce: signal ] on: Error do: [ :traceError |
		Transcript showln: 'PDMT trace emit failed: ' , traceError messageText ].
	error ifNotNil: [ error signal ].
	^ result
]

{ #category : 'private' }
PmdtToolTrace class >> fillSuccess: signal result: result request: request [
	| warnings |
	warnings := (result isKindOf: Dictionary) ifTrue: [ result at: 'warnings' ifAbsent: [ #() ] ] ifFalse: [ #() ].
	signal
		outcome: (warnings isEmpty ifTrue: [ 'ok' ] ifFalse: [ 'ok_with_warnings' ]);
		warningCodes: (warnings collect: [ :each | each at: 'code' ifAbsent: [ each asString ] ]) asArray;
		resultBytes: ((result isNil) ifTrue: [ 0 ] ifFalse: [ (PmdtCanonicalJson toString: result) asByteArray size ]);
		outputWritten: (self outputWrittenIn: result);
		regionCount: (self regionCountIn: result);
		emptyRegionCount: (self emptyRegionCountIn: result);
		imageSha256: (self imageShaIn: result request: request)
]

{ #category : 'private' }
PmdtToolTrace class >> fillError: signal error: error [
	signal
		outcome: 'error';
		errorCode: ((error respondsTo: #code) ifTrue: [ error code ] ifFalse: [ 'internal_error' ]);
		warningCodes: #();
		resultBytes: 0
]

{ #category : 'private' }
PmdtToolTrace class >> outputWrittenIn: result [
	(result isKindOf: Dictionary) ifFalse: [ ^ false ].
	^ (result includesKey: 'mask_path') or: [ result includesKey: 'baseline_sha256' ]
]

{ #category : 'private' }
PmdtToolTrace class >> regionCountIn: result [
	| regions |
	(result isKindOf: Dictionary) ifFalse: [ ^ 0 ].
	regions := result at: 'regions' ifAbsent: [ nil ].
	^ (regions isKindOf: Dictionary) ifTrue: [ regions size ] ifFalse: [ 0 ]
]

{ #category : 'private' }
PmdtToolTrace class >> emptyRegionCountIn: result [
	| regions |
	(result isKindOf: Dictionary) ifFalse: [ ^ 0 ].
	regions := result at: 'regions' ifAbsent: [ nil ].
	(regions isKindOf: Dictionary) ifFalse: [ ^ 0 ].
	^ regions values count: [ :each | (each at: 'status' ifAbsent: [ '' ]) = 'empty' ]
]

{ #category : 'private' }
PmdtToolTrace class >> imageShaIn: result request: request [
	| image |
	(result isKindOf: Dictionary) ifTrue: [
		image := result at: 'image' ifAbsent: [ nil ].
		(image isKindOf: Dictionary) ifTrue: [
			image at: 'sha256' ifPresent: [ :value | ^ value ] ] ].
	^ request at: 'image_sha256' ifAbsent: [ nil ]
]
