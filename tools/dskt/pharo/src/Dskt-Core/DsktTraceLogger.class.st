"
I am the single Beacon logger for all tool calls.

I keep a bounded in-image ring and append one JSON object per line to DSKT_TRACE_LOG.
"
Class {
	#name : 'DsktTraceLogger',
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
	#category : 'Dskt-Core',
	#package : 'Dskt-Core'
}

{ #category : 'initialization' }
DsktTraceLogger >> initialize [
	super initialize.
	entries := OrderedCollection new.
	sequence := 0.
	mutex := Semaphore forMutualExclusion.
	file := DsktSettings traceLog asFileReference.
	runId := UUID new asString.
	status := 'ok'.
	maxEntries := DsktSettings traceEntries.
	maxBytes := DsktSettings traceMaxBytes.
	self name: 'DsktTraceLogger'
]

{ #category : 'accessing' }
DsktTraceLogger >> entries [ ^ entries ]
{ #category : 'accessing' }
DsktTraceLogger >> runId [ ^ runId ]
{ #category : 'accessing' }
DsktTraceLogger >> status [ ^ status ]
{ #category : 'accessing' }
DsktTraceLogger >> file [ ^ file ]
{ #category : 'accessing' }
DsktTraceLogger >> maxEntries [ ^ maxEntries ]
{ #category : 'accessing' }
DsktTraceLogger >> maxEntries: anObject [ maxEntries := anObject ]
{ #category : 'accessing' }
DsktTraceLogger >> maxBytes [ ^ maxBytes ]
{ #category : 'accessing' }
DsktTraceLogger >> maxBytes: anObject [ maxBytes := anObject ]

{ #category : 'controlling' }
DsktTraceLogger >> start [
	file parent ensureCreateDirectory.
	self startFor: DsktToolCallSignal
]

{ #category : 'controlling' }
DsktTraceLogger >> stop [
	super stop.
	status := 'stopped'
]

{ #category : 'logging' }
DsktTraceLogger >> nextPut: aSignal [
	mutex critical: [
		sequence := sequence + 1.
		aSignal sequence: sequence.
		aSignal runId: runId.
		entries addLast: aSignal.
		[ entries size > maxEntries ] whileTrue: [ entries removeFirst ].
		self append: aSignal ]
]

{ #category : 'private' }
DsktTraceLogger >> append: aSignal [
	| line |
	line := DsktCanonicalJson toString: aSignal asDictionary.
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
			Transcript show: 'DSKT trace write failed: '; show: error messageText; cr ]
]

{ #category : 'accessing' }
DsktTraceLogger >> health [
	^ Dictionary new
		at: 'status' put: self status;
		at: 'log_path' put: self file pathString;
		at: 'entries' put: self entries size;
		at: 'bytes' put: (self file exists ifTrue: [ self file size ] ifFalse: [ 0 ]);
		yourself
]
