"
I test component lookup through the installed component index.
"
Class {
	#name : 'CtikzComponentLookupTest',
	#superclass : 'CtikzTestCase',
	#category : 'Ctikz-Tests',
	#package : 'Ctikz-Tests'
}

{ #category : 'running' }
CtikzComponentLookupTest >> setUp [
	super setUp.
	CtikzComponentIndex reset.
	CtikzComponentLookup reset
]

{ #category : 'tests' }
CtikzComponentLookupTest >> testDescriptions [
	| lookup |
	lookup := CtikzComponentLookup default.
	self assert: (lookup lookup: 'L') description equals: 'inductor'.
	self assert: (lookup lookup: 'R') description equals: 'resistor'.
	self assert: (lookup lookup: 'generic') description equals: 'generic bipole'.
	self assert: (lookup lookup: 'sV') description equals: 'independent voltage source'
]

{ #category : 'tests' }
CtikzComponentLookupTest >> testUnknownComponent [
	self assert: (CtikzComponentLookup default lookup: 'not-a-component') isNil
]

{ #category : 'tests' }
CtikzComponentLookupTest >> testCatalogUsesKnownComponents [
	self assert: CtikzSnippetCatalog default validationWarnings isEmpty
]

{ #category : 'tests' }
CtikzComponentLookupTest >> testInstalledStyleIndex [
	| file lookup |
	file := FileSystem workingDirectory / 'tmp' / ('ctikz-style-' , UUID new asString , '.sty').
	file writeStreamDo: [ :stream |
		stream nextPutAll: '\def\pgfcircversion{1.2.3}
\pgfcircdeclarebipole{L}
\pgfcircdeclarebipole{R}
\pgfcircdeclarebipole{generic}
\pgfcircdeclarebipole{sV}' ].
	[ OSEnvironment current setEnv: 'DSKT_CIRCUITIKZ_STY' value: file pathString during: [
		CtikzComponentIndex reset.
		CtikzComponentLookup reset.
		lookup := CtikzComponentLookup default.
		self assert: lookup index status equals: 'ok'.
		self assert: lookup index circuitikzVersion equals: '1.2.3'.
		self assert: (lookup lookup: 'L') declaration notNil ] ]
		ensure: [ file delete ]
]
