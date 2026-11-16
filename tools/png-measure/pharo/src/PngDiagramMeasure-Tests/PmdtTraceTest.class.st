"
I test Beacon signal serialization and trace aggregation without requiring a live HTTP server.
"
Class {
	#name : 'PmdtTraceTest',
	#superclass : 'TestCase',
	#category : 'PngDiagramMeasure-Tests',
	#package : 'PngDiagramMeasure-Tests'
}

{ #category : 'tests' }
PmdtTraceTest >> testSignalDictionary [
	| signal dictionary |
	signal := DsktToolCallSignal new
		tool: 'png_measure_bounds';
		outcome: 'ok_with_warnings';
		warningCodes: #('bbox_unstable');
		durationMs: 12;
		details: (Dictionary new
			at: 'image_path' put: 'reference/target.png';
			at: 'image_sha256' put: 'abc';
			yourself);
		requestId: 'r1';
		clientId: 'c1';
		clientRole: 'reviewer';
		resultBytes: 42;
		yourself.
	dictionary := signal asDictionary.
	self assert: (dictionary at: 'tool') equals: 'png_measure_bounds'.
	self assert: (dictionary at: 'outcome') equals: 'ok_with_warnings'.
	self assert: (dictionary at: 'warning_codes') equals: #('bbox_unstable').
	self assert: (dictionary at: 'schema_version') equals: 1.
	self assert: (dictionary at: 'result_bytes') equals: 42.
	self assert: ((dictionary at: 'details') at: 'image_path') equals: 'reference/target.png'.
	self assert: (dictionary at: 'timestamp') isString
]

{ #category : 'tests' }
PmdtTraceTest >> testReportCounts [
	| logger report signals |
	logger := DsktTraceLogger new.
	signals := {
		DsktToolCallSignal new tool: 'png_inspect_image'; outcome: 'ok'; warningCodes: #(); sequence: 1; clientId: 'c1'; yourself.
		DsktToolCallSignal new tool: 'png_measure_bounds'; outcome: 'ok_with_warnings'; warningCodes: #('bbox_unstable'); sequence: 2; clientId: 'c1'; yourself.
		DsktToolCallSignal new tool: 'png_measure_bounds'; outcome: 'error'; errorCode: 'invalid_request'; warningCodes: #(); sequence: 3; clientId: 'c2'; yourself }.
	signals do: [ :signal | logger entries add: signal ].
	report := DsktTraceReport from: logger limit: 2 sinceSequence: nil tool: nil clientId: nil.
	self assert: ((report at: 'counts') at: 'total') equals: 3.
	self assert: (((report at: 'counts') at: 'by_tool') at: 'png_measure_bounds') equals: 2.
	self assert: (((report at: 'counts') at: 'by_outcome') at: 'ok') equals: 1.
	self assert: (((report at: 'counts') at: 'by_warning') at: 'bbox_unstable') equals: 1.
	self assert: (report at: 'entries') size equals: 2.
	self assert: (report at: 'truncated') equals: true
]
