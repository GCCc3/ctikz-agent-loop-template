"
I test the trace detail dictionaries built by the Ctikz route provider.
"
Class {
	#name : 'CtikzTraceTest',
	#superclass : 'CtikzTestCase',
	#category : 'Ctikz-Tests',
	#package : 'Ctikz-Tests'
}

{ #category : 'tests' }
CtikzTraceTest >> testCatalogDetails [
	| details |
	details := CtikzRouteProvider new catalogDetailsFor: (Dictionary new
		at: 'catalog_version' put: 'catalog-v1';
		at: 'snippet_id' put: 'component/L';
		yourself).
	self assert: (details at: 'tool_family') equals: 'catalog'.
	self assert: (details at: 'catalog_version') equals: 'catalog-v1'.
	self assert: (details at: 'snippet_id') equals: 'component/L'
]

{ #category : 'tests' }
CtikzTraceTest >> testLintDetails [
	| details |
	details := CtikzRouteProvider new
		lintDetailsFor: (Dictionary new
			at: 'source_path' put: 'current/reconstruction.tex';
			at: 'summary' put: (Dictionary new at: 'failed' put: 0; yourself);
			yourself).
	self assert: (details at: 'tool_family') equals: 'lint'.
	self assert: (details at: 'source_path') equals: 'current/reconstruction.tex'.
	self assert: ((details at: 'check_counts') at: 'failed') equals: 0.
	self assert: (details at: 'lint_rules_version') isString
]
