"
I test the catalog/lint facades together with the golden reconstruction.
"
Class {
	#name : 'CtikzToolsIntegrationTest',
	#superclass : 'CtikzTestCase',
	#category : 'Ctikz-Tests',
	#package : 'Ctikz-Tests'
}

{ #category : 'tests' }
CtikzToolsIntegrationTest >> testReconstructionPassesLint [
	| result |
	result := CtikzLintService default lintSource: (Dictionary new
		at: 'path' put: 'current/reconstruction.tex';
		yourself).
	self assert: ((result at: 'summary') at: 'failed') equals: 0.
	self assert: ((result at: 'counts') at: 'coordinates') equals: 12.
	self assert: ((result at: 'counts') at: 'components') equals: 4
]

{ #category : 'tests' }
CtikzToolsIntegrationTest >> testCatalogServiceOperations [
	| service listed snippet rendered lookup |
	service := CtikzCatalogService default.
	listed := service listSnippets: (Dictionary new at: 'component' put: 'L'; yourself).
	self assert: ((listed at: 'snippets') anySatisfy: [ :each | (each at: 'id') = 'component/L' ]).
	snippet := service getSnippetRequest: (Dictionary new at: 'id' put: 'component/L'; yourself).
	self assert: ((snippet at: 'snippet') at: 'id') equals: 'component/L'.
	rendered := service renderSnippet: (Dictionary new
		at: 'snippet_id' put: 'component/L';
		at: 'parameters' put: (Dictionary new at: 'start' put: 'c1'; at: 'end' put: 'c2'; yourself);
		yourself).
	self assert: (rendered at: 'source') equals: '\draw (c1) to[L] (c2);'.
	lookup := service lookupComponent: (Dictionary new at: 'component' put: 'sV'; yourself).
	self assert: (lookup at: 'found')
]

{ #category : 'tests' }
CtikzToolsIntegrationTest >> testLintIsDeterministic [
	| request first second |
	request := Dictionary new
		at: 'source_text' put: CtikzTestFixtures validSource;
		at: 'required_labels' put: #();
		yourself.
	first := DsktCanonicalJson toString: (CtikzLintService default lintSource: request).
	second := DsktCanonicalJson toString: (CtikzLintService default lintSource: request).
	self assert: first equals: second
]

{ #category : 'tests' }
CtikzToolsIntegrationTest >> testOversizedSourceRejected [
	| source |
	source := String new: 1000001 withAll: $x.
	self assertCode: [
		CtikzLintService default lintSource: (Dictionary new
			at: 'source_text' put: source;
			yourself) ] equals: 'source_too_large'
]

{ #category : 'tests' }
CtikzToolsIntegrationTest >> testPathEscapeRejected [
	self assertCode: [
		CtikzLintService default lintSource: (Dictionary new
			at: 'path' put: '../outside.tex';
			yourself) ] equals: 'path_outside_repo'
]

{ #category : 'tests' }
CtikzToolsIntegrationTest >> testMalformedUtf8Rejected [
	| path |
	path := 'tmp/c tikz-invalid-utf8.tex' asFileReference.
	path parent ensureCreateDirectory.
	path binaryWriteStreamDo: [ :stream | stream nextPutAll: #[255 254 65] ].
	[ self assertCode: [
		CtikzLintService default lintSource: (Dictionary new
			at: 'path' put: 'tmp/c tikz-invalid-utf8.tex';
			yourself) ] equals: 'unsupported_encoding' ]
		ensure: [ path exists ifTrue: [ path delete ] ]
]

{ #category : 'tests' }
CtikzToolsIntegrationTest >> testMissingSourceRejected [
	self assertCode: [
		CtikzLintService default lintSource: (Dictionary new
			at: 'path' put: 'current/does-not-exist.tex';
			yourself) ] equals: 'source_not_found'
]

{ #category : 'tests' }
CtikzToolsIntegrationTest >> testBothSourceInputsRejected [
	self assertCode: [
		CtikzLintService default lintSource: (Dictionary new
			at: 'path' put: 'current/reconstruction.tex';
			at: 'source_text' put: 'x';
			yourself) ] equals: 'invalid_request'
]
