"
I filter and aggregate the in-image trace ring for /png/trace and the png_trace MCP tool.
"
Class {
	#name : 'PmdtTraceReport',
	#superclass : 'Object',
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'reporting' }
PmdtTraceReport class >> from: aPmdtTraceLogger limit: limit sinceSequence: since tool: tool clientId: clientId [
	| selected byTool byOutcome byWarning byClient entries truncated |
	selected := aPmdtTraceLogger entries select: [ :signal |
		(since isNil or: [ signal sequence > since ]) and: [
			(tool isNil or: [ signal tool = tool ]) and: [
				(clientId isNil or: [ signal clientId = clientId ]) ] ] ].
	truncated := limit notNil and: [ selected size > limit ].
	entries := limit
		ifNil: [ selected asOrderedCollection ]
		ifNotNil: [ selected asOrderedCollection last: (limit min: selected size) ].
	entries := entries asSortedCollection: [ :a :b | a sequence > b sequence ].
	byTool := Dictionary new.
	byOutcome := Dictionary new.
	byWarning := Dictionary new.
	byClient := Dictionary new.
	selected do: [ :signal |
		byTool at: signal tool put: ((byTool at: signal tool ifAbsent: [ 0 ]) + 1).
		byOutcome at: signal outcome put: ((byOutcome at: signal outcome ifAbsent: [ 0 ]) + 1).
		byClient at: (signal clientId ifNil: [ 'unknown' ]) put: ((byClient at: (signal clientId ifNil: [ 'unknown' ]) ifAbsent: [ 0 ]) + 1).
		signal warningCodes do: [ :code |
			byWarning at: code put: ((byWarning at: code ifAbsent: [ 0 ]) + 1) ] ].
	^ Dictionary new
		at: 'entries' put: (entries collect: [ :signal | signal asDictionary ]) asArray;
		at: 'counts' put: (Dictionary new
			at: 'total' put: selected size;
			at: 'by_tool' put: byTool;
			at: 'by_outcome' put: byOutcome;
			at: 'by_warning' put: byWarning;
			at: 'by_client' put: byClient;
			yourself);
		at: 'log' put: (Dictionary new
			at: 'path' put: aPmdtTraceLogger file pathString;
			at: 'entries' put: aPmdtTraceLogger entries size;
			at: 'bytes' put: (aPmdtTraceLogger file exists ifTrue: [ aPmdtTraceLogger file size ] ifFalse: [ 0 ]);
			yourself);
		at: 'truncated' put: truncated;
		yourself
]
