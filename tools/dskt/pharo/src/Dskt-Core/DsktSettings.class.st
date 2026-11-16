"
I read DSKT_* settings from the process environment.

I hold only toolkit-wide settings. Domain-specific settings live in each domain's
settings class (for example PngMeasureSettings or CtikzSettings).
"
Class {
	#name : 'DsktSettings',
	#superclass : 'Object',
	#category : 'Dskt-Core',
	#package : 'Dskt-Core'
}

{ #category : 'accessing' }
DsktSettings class >> env: aString default: anObject [
	^ (Smalltalk at: #OSEnvironment) current at: aString ifAbsent: [ anObject ]
]

{ #category : 'accessing' }
DsktSettings class >> port [
	^ (self env: 'DSKT_PORT' default: '8087') asInteger
]

{ #category : 'accessing' }
DsktSettings class >> host [
	^ self env: 'DSKT_HOST' default: '127.0.0.1'
]

{ #category : 'accessing' }
DsktSettings class >> bindAddress [
	| parts |
	parts := self host substrings: '.'.
	(parts size = 4 and: [ parts allSatisfy: [ :each |
		each notEmpty and: [
			(each allSatisfy: [ :character | character isDigit ]) and: [
				each asInteger between: 0 and: 255 ] ] ] ])
		ifFalse: [ DsktError code: 'invalid_host' message: 'DSKT_HOST must be a dotted IPv4 address: ' , self host printString ].
	^ (parts collect: [ :each | each asInteger ]) asByteArray
]

{ #category : 'accessing' }
DsktSettings class >> repoRoot [
	^ (self env: 'DSKT_REPO_ROOT' default: (FileSystem workingDirectory pathString)) asFileReference absolutePath pathString
]

{ #category : 'accessing' }
DsktSettings class >> traceLog [
	| value path |
	value := self env: 'DSKT_TRACE_LOG' default: 'tmp/dskt/tool-trace.jsonl'.
	path := [ DsktPathResolver resolveWritable: value under: self repoRoot ]
		on: DsktError
		do: [ :error | DsktError code: 'trace_unavailable' message: 'DSKT_TRACE_LOG must resolve under DSKT_REPO_ROOT' ].
	^ path pathString
]

{ #category : 'accessing' }
DsktSettings class >> clientRole [
	^ self env: 'DSKT_CLIENT_ROLE' default: 'unknown'
]

{ #category : 'accessing' }
DsktSettings class >> traceEntries [
	^ (self env: 'DSKT_TRACE_ENTRIES' default: '1000') asInteger
]

{ #category : 'accessing' }
DsktSettings class >> traceMaxBytes [
	^ (self env: 'DSKT_TRACE_MAX_BYTES' default: '5000000') asInteger
]

{ #category : 'accessing' }
DsktSettings class >> debug [
	^ (self env: 'DSKT_DEBUG' default: '0') ~= '0'
]

{ #category : 'accessing' }
DsktSettings class >> autostart [
	^ (self env: 'DSKT_AUTOSTART' default: '1') ~= '0'
]
