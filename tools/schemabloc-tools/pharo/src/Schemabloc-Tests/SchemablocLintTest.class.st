"
I test the schemabloc source lint.
"
Class {
	#name : 'SchemablocLintTest',
	#superclass : 'TestCase',
	#category : 'Schemabloc-Tests',
	#package : 'Schemabloc-Tests'
}

{ #category : 'private' }
SchemablocLintTest >> lint: aSource [
	^ SchemablocLintService new lintSource: (Dictionary new
		at: 'source_text' put: aSource;
		yourself)
]

{ #category : 'tests' }
SchemablocLintTest >> testValidSourceHasNoFailures [
	| report |
	report := self lint: SchemablocTestFixtures controlSource.
	self assert: ((report at: 'summary') at: 'failed') equals: 0.
	self assert: ((report at: 'counts') at: 'blocks') equals: 1
]

{ #category : 'tests' }
SchemablocLintTest >> testMissingPackageFails [
	| report source |
	source := SchemablocTestFixtures controlSource copyReplaceAll: '\usepackage{schemabloc}' with: ''.
	report := self lint: source.
	self assert: ((report at: 'checks') anySatisfy: [ :each | (each at: 'id') = 'schemabloc_package' and: [ (each at: 'status') = 'failed' ] ])
]

{ #category : 'tests' }
SchemablocLintTest >> testUndefinedNodeFails [
	| report source |
	source := SchemablocTestFixtures controlSource copyReplaceAll: '\sbRelier{Gva}{iout}' with: '\sbRelier{Gva}{missing}'.
	report := self lint: source.
	self assert: ((report at: 'checks') anySatisfy: [ :each | (each at: 'id') = 'defined_nodes' and: [ (each at: 'status') = 'failed' ] ])
]

{ #category : 'tests' }
SchemablocLintTest >> testUndefinedLinkFails [
	| report source |
	source := SchemablocTestFixtures controlSource copyReplaceAll: '\sbRelier{Gva}{iout}' with: '\sbRenvoi{missing}{sumv}{x}'.
	report := self lint: source.
	self assert: ((report at: 'checks') anySatisfy: [ :each | (each at: 'id') = 'defined_links' and: [ (each at: 'status') = 'failed' ] ])
]

{ #category : 'tests' }
SchemablocLintTest >> testDuplicateNodeFails [
	| report source |
	source := SchemablocTestFixtures controlSource copyReplaceAll: '\sbEntree{vref}' with: '\sbEntree{vref}\sbEntree{vref}'.
	report := self lint: source.
	self assert: ((report at: 'checks') anySatisfy: [ :each | (each at: 'id') = 'duplicate_nodes' and: [ (each at: 'status') = 'failed' ] ])
]

{ #category : 'tests' }
SchemablocLintTest >> testCircuitikzFails [
	| report |
	report := self lint: SchemablocTestFixtures sourceWithCircuitikz.
	self assert: ((report at: 'checks') anySatisfy: [ :each | (each at: 'id') = 'no_circuitikz' and: [ (each at: 'status') = 'failed' ] ])
]

{ #category : 'tests' }
SchemablocLintTest >> testManualRectangleWarns [
	| report |
	report := self lint: SchemablocTestFixtures sourceWithManualRectangle.
	self assert: ((report at: 'checks') anySatisfy: [ :each | (each at: 'id') = 'manual_blocks' and: [ (each at: 'status') = 'warning' ] ])
]

{ #category : 'tests' }
SchemablocLintTest >> testRequiredLabels [
	| report |
	report := SchemablocLintService new lintSource: (Dictionary new
		at: 'source_text' put: SchemablocTestFixtures controlSource;
		at: 'required_labels' put: #( 'G_va' 'missing_label' );
		yourself).
	self assert: ((report at: 'checks') anySatisfy: [ :each | (each at: 'id') = 'required_labels' and: [ (each at: 'status') = 'failed' ] ])
]
