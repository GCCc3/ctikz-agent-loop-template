"
I read PDMT_* settings from the process environment.
"
Class {
	#name : 'PmdtSettings',
	#superclass : 'Object',
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'accessing' }
PmdtSettings class >> env: aString default: anObject [
	^ (Smalltalk at: #OSEnvironment) current at: aString ifAbsent: [ anObject ]
]

{ #category : 'accessing' }
PmdtSettings class >> port [
	^ (self env: 'PDMT_PORT' default: '8087') asInteger
]

{ #category : 'accessing' }
PmdtSettings class >> host [
	^ self env: 'PDMT_HOST' default: '127.0.0.1'
]

{ #category : 'accessing' }
PmdtSettings class >> repoRoot [
	^ (self env: 'PDMT_REPO_ROOT' default: (FileSystem workingDirectory pathString)) asFileReference absolutePath pathString
]

{ #category : 'accessing' }
PmdtSettings class >> outputRoot [
	| value |
	value := self env: 'PDMT_OUTPUT_ROOT' default: 'tmp/png-measure'.
	^ value asFileReference absolutePath pathString
]

{ #category : 'accessing' }
PmdtSettings class >> traceLog [
	| value root path |
	value := self env: 'PDMT_TRACE_LOG' default: (self outputRoot asFileReference / 'tool-trace.jsonl') pathString.
	path := value asFileReference.
	path isAbsolute ifFalse: [ path := self repoRoot asFileReference / value ].
	path := path absolutePath.
	root := self outputRoot asFileReference absolutePath.
	(path pathString beginsWith: root pathString)
		ifFalse: [ PmdtError code: 'trace_unavailable' message: 'PDMT_TRACE_LOG must resolve under PDMT_OUTPUT_ROOT' ].
	^ path pathString
]

{ #category : 'accessing' }
PmdtSettings class >> maxPixels [
	^ (self env: 'PDMT_MAX_PIXELS' default: '50000000') asInteger
]

{ #category : 'accessing' }
PmdtSettings class >> autostart [
	^ (self env: 'PDMT_AUTOSTART' default: '1') ~= '0'
]

{ #category : 'accessing' }
PmdtSettings class >> traceEntries [
	^ (self env: 'PDMT_TRACE_ENTRIES' default: '1000') asInteger
]

{ #category : 'accessing' }
PmdtSettings class >> traceMaxBytes [
	^ (self env: 'PDMT_TRACE_MAX_BYTES' default: '5000000') asInteger
]

{ #category : 'accessing' }
PmdtSettings class >> debug [
	^ (self env: 'PDMT_DEBUG' default: '0') ~= '0'
]

{ #category : 'accessing' }
PmdtSettings class >> ensureOutputRoot [
	| directory |
	directory := self outputRoot asFileReference.
	directory ensureCreateDirectory.
	^ directory
]
