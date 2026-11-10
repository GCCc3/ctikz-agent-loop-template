"
I am the single Beacon logger for measurement tool calls.

I keep a bounded in-image ring and append one JSON object per line to PDMT_TRACE_LOG.
"
Class {
	#name : 'PmdtTraceLogger',
	#superclass : 'SignalLogger',
	#instVars : [
		'entries',
		'sequence',
		'mutex',
		'file',
		'runId',
		'status',
		'maxEntries',
		'maxBytes'
	],
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'initialization' }
PmdtTraceLogger >> initialize [
	super initialize.
	entries := OrderedCollection new.
	sequence := 0.
	mutex := Semaphore forMutualExclusion.
	file := PmdtSettings traceLog asFileReference.
	runId := UUID new asString.
	status := 'ok'.
	maxEntries := PmdtSettings traceEntries.
	maxBytes := PmdtSettings traceMaxBytes.
	self name: 'PmdtTraceLogger'
]

{ #category : 'accessing' }
PmdtTraceLogger >> entries [ ^ entries ]
{ #category : 'accessing' }
PmdtTraceLogger >> runId [ ^ runId ]
{ #category : 'accessing' }
PmdtTraceLogger >> status [ ^ status ]
{ #category : 'accessing' }
PmdtTraceLogger >> file [ ^ file ]

{ #category : 'controlling' }
PmdtTraceLogger >> start [
	file parent ensureCreateDirectory.
	self startFor: PmdtToolCallSignal
]

{ #category : 'controlling' }
PmdtTraceLogger >> stop [
	super stop.
	status := 'stopped'
]

{ #category : 'logging' }
PmdtTraceLogger >> nextPut: aSignal [
	mutex critical: [
		sequence := sequence + 1.
		aSignal sequence: sequence.
		aSignal runId: runId.
		entries addLast: aSignal.
		[ entries size > maxEntries ] whileTrue: [ entries removeFirst ].
		self append: aSignal ]
]

{ #category : 'private' }
PmdtTraceLogger >> append: aSignal [
	| line |
	line := PmdtCanonicalJson toString: aSignal asDictionary.
	[
		| stream |
		file parent ensureCreateDirectory.
		(file exists and: [ file size > maxBytes ]) ifTrue: [
			(file parent / (file basename , '.1')) exists
				ifTrue: [ (file parent / (file basename , '.1')) delete ].
			file renameTo: (file parent / (file basename , '.1')) pathString ].
		stream := file writeStream.
		stream setToEnd.
		stream nextPutAll: line.
		stream nextPut: Character lf.
		stream close ]
		on: Error
		do: [ :error |
			status := 'degraded'.
			Transcript showln: 'PDMT trace write failed: ' , error messageText ]
]
