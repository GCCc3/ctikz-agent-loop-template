"
I test each lint rule with a small fixture.
"
Class {
	#name : 'CtikzLintRuleTest',
	#superclass : 'CtikzTestCase',
	#category : 'Ctikz-Tests',
	#package : 'Ctikz-Tests'
}

{ #category : 'helpers' }
CtikzLintRuleTest >> check: anId in: aResult [
	^ (aResult at: 'checks') detect: [ :each | (each at: 'id') = anId ] ifNone: [ nil ]
]

{ #category : 'helpers' }
CtikzLintRuleTest >> lint: aSource [
	^ CtikzLintService default lintSource: (Dictionary new
		at: 'source_text' put: aSource;
		at: 'required_labels' put: #();
		yourself)
]

{ #category : 'helpers' }
CtikzLintRuleTest >> lint: aSource labels: labels [
	^ CtikzLintService default lintSource: (Dictionary new
		at: 'source_text' put: aSource;
		at: 'required_labels' put: labels;
		yourself)
]

{ #category : 'helpers' }
CtikzLintRuleTest >> lint: aSource labels: labels strict: aBoolean [
	^ CtikzLintService default lintSource: (Dictionary new
		at: 'source_text' put: aSource;
		at: 'required_labels' put: labels;
		at: 'strict' put: aBoolean;
		yourself)
]

{ #category : 'helpers' }
CtikzLintRuleTest >> statusOf: anId in: aResult [
	^ (self check: anId in: aResult) at: 'status'
]

{ #category : 'tests' }
CtikzLintRuleTest >> testValidSourceHasNoFailures [
	| result |
	result := self lint: CtikzTestFixtures validSource.
	self assert: ((result at: 'summary') at: 'failed') equals: 0
]

{ #category : 'tests' }
CtikzLintRuleTest >> testTwoCircuitikzEnvironmentsFail [
	| result |
	result := self lint: CtikzTestFixtures twoCircuitikzEnvironments.
	self assert: (self statusOf: 'single_circuitikz_environment' in: result) equals: 'failed'
]

{ #category : 'tests' }
CtikzLintRuleTest >> testTikzClassOptionWarnsAndStrictFails [
	| warning strict |
	warning := self lint: CtikzTestFixtures tikzClassOption.
	self assert: (self statusOf: 'no_tikz_class_option' in: warning) equals: 'warning'.
	strict := self lint: CtikzTestFixtures tikzClassOption labels: #() strict: true.
	self assert: (self statusOf: 'no_tikz_class_option' in: strict) equals: 'failed'
]

{ #category : 'tests' }
CtikzLintRuleTest >> testImageInclusionFails [
	| result |
	result := self lint: CtikzTestFixtures imageInclusion.
	self assert: (self statusOf: 'no_image_inclusion' in: result) equals: 'failed'
]

{ #category : 'tests' }
CtikzLintRuleTest >> testForbiddenTokenInCommentPasses [
	| result |
	result := self lint: CtikzTestFixtures commentWithForbiddenToken.
	self assert: (self statusOf: 'no_image_inclusion' in: result) equals: 'passed'
]

{ #category : 'tests' }
CtikzLintRuleTest >> testMismatchedEnvironmentFails [
	| result |
	result := self lint: CtikzTestFixtures mismatchedEnvironment.
	self assert: (self statusOf: 'balanced_environments' in: result) equals: 'failed'
]

{ #category : 'tests' }
CtikzLintRuleTest >> testUnbalancedBraceFails [
	| result |
	result := self lint: CtikzTestFixtures unbalancedBrace.
	self assert: (self statusOf: 'balanced_braces' in: result) equals: 'failed'
]

{ #category : 'tests' }
CtikzLintRuleTest >> testUndefinedCoordinateFails [
	| result |
	result := self lint: CtikzTestFixtures undefinedCoordinate.
	self assert: (self statusOf: 'defined_coordinates' in: result) equals: 'failed'
]

{ #category : 'tests' }
CtikzLintRuleTest >> testRelativeCoordinateWarns [
	| result |
	result := self lint: CtikzTestFixtures relativeCoordinate.
	self assert: (self statusOf: 'defined_coordinates' in: result) equals: 'passed'.
	self assert: (self statusOf: 'ambiguous_coordinates' in: result) equals: 'warning'
]

{ #category : 'tests' }
CtikzLintRuleTest >> testRequiredLabelMatchesWholeToken [
	| result |
	result := self lint: CtikzTestFixtures mathLabel labels: #('v').
	self assert: (self statusOf: 'required_labels' in: result) equals: 'failed'
]

{ #category : 'tests' }
CtikzLintRuleTest >> testComponentInventoryDetails [
	| result check |
	result := self lint: CtikzTestFixtures validSource.
	check := self check: 'component_inventory' in: result.
	self assert: ((check at: 'details') at: 'R') equals: 1
]

{ #category : 'tests' }
CtikzLintRuleTest >> testCustomForbiddenPatterns [
	| result |
	result := CtikzLintService default lintSource: (Dictionary new
		at: 'source_text' put: CtikzTestFixtures imageInclusion;
		at: 'required_labels' put: #();
		at: 'forbid_patterns' put: #('target.png');
		yourself).
	self assert: (self statusOf: 'forbidden_patterns' in: result) equals: 'failed'
]
