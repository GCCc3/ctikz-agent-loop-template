"
I read PNG-specific settings from the process environment.

Common toolkit settings (port, host, repository root, trace log, trace size,
autostart, debug) live in DsktSettings. I hold only PNG-specific values.
"
Class {
	#name : 'PngMeasureSettings',
	#superclass : 'Object',
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'accessing' }
PngMeasureSettings class >> env: aString default: anObject [
	^ DsktSettings env: aString default: anObject
]

{ #category : 'accessing' }
PngMeasureSettings class >> repoRoot [
	^ DsktSettings repoRoot
]

{ #category : 'accessing' }
PngMeasureSettings class >> outputRoot [
	| value path |
	value := self env: 'PNG_OUTPUT_ROOT' default: 'tmp/png-measure'.
	path := value asFileReference.
	path isAbsolute ifFalse: [ path := DsktSettings repoRoot asFileReference / value ].
	^ path absolutePath pathString
]

{ #category : 'accessing' }
PngMeasureSettings class >> maxPixels [
	^ (self env: 'PNG_MAX_PIXELS' default: '50000000') asInteger
]

{ #category : 'accessing' }
PngMeasureSettings class >> ensureOutputRoot [
	| directory |
	directory := self outputRoot asFileReference.
	directory ensureCreateDirectory.
	^ directory
]
