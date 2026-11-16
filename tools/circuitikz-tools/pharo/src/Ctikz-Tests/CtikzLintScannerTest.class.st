"
I test the comment-aware structural scanner.
"
Class {
	#name : 'CtikzLintScannerTest',
	#superclass : 'CtikzTestCase',
	#category : 'Ctikz-Tests',
	#package : 'Ctikz-Tests'
}

{ #category : 'helpers' }
CtikzLintScannerTest >> scan: aSource [
	^ CtikzSourceScanner new scan: aSource
]

{ #category : 'tests' }
CtikzLintScannerTest >> testDocumentClassOptionsPackagesAndLibraries [
	| model |
	model := self scan: CtikzTestFixtures validSource.
	self assert: model documentClass equals: 'standalone'.
	self assert: (model documentClassOptions includes: 'border=6pt').
	self assert: (model packages includes: 'circuitikz').
	self assert: (model libraries includes: 'arrows.meta')
]

{ #category : 'tests' }
CtikzLintScannerTest >> testEnvironmentOrder [
	| model kinds |
	model := self scan: CtikzTestFixtures validSource.
	kinds := model environments collect: [ :each | each at: 'kind' ].
	self assert: kinds asArray equals: #('begin' 'begin' 'end' 'end').
	self assert: model circuitikzEnvironments size equals: 1
]

{ #category : 'tests' }
CtikzLintScannerTest >> testForbiddenTokenInCommentIsIgnored [
	| model |
	model := self scan: CtikzTestFixtures commentWithForbiddenToken.
	self assert: model forbiddenMatches isEmpty
]

{ #category : 'tests' }
CtikzLintScannerTest >> testEscapedPercentIsNotAComment [
	| model |
	model := self scan: CtikzTestFixtures escapedPercent.
	self assert: (model labels anySatisfy: [ :each | (each at: 'text') = '\%' ])
]

{ #category : 'tests' }
CtikzLintScannerTest >> testNestedLabelBraces [
	| model |
	model := self scan: CtikzTestFixtures nestedLabel.
	self assert: (model labels first at: 'text') equals: '$R_{load}$'
]

{ #category : 'tests' }
CtikzLintScannerTest >> testRelativeReferenceIsCollected [
	| model |
	model := self scan: CtikzTestFixtures relativeCoordinate.
	self assert: (model coordinateReferences anySatisfy: [ :each | (each at: 'name') = '++' ])
]

{ #category : 'tests' }
CtikzLintScannerTest >> testForbiddenMatchLineNumber [
	| model match |
	model := self scan: CtikzTestFixtures imageInclusion.
	match := model forbiddenMatches detect: [ :each | (each at: 'pattern') = '\includegraphics' ].
	self assert: (match at: 'line') equals: 5
]
