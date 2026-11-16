"
I hold the component and style keys known to the installed CircuitTikZ.

I use a curated manifest for descriptions and defaults, and when
`DSKT_CIRCUITIKZ_STY` points at an installed `circuitikz.sty` I verify each key
against that file and record its declaration line and version. If the style file
is absent I keep the manifest and report a fallback status.
"
Class {
	#name : 'CtikzComponentIndex',
	#superclass : 'Object',
	#instVars : [
		'components',
		'sourcePath',
		'status',
		'circuitikzVersion'
	],
	#classVars : [
		'Current'
	],
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzComponentIndex class >> default [
	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
CtikzComponentIndex class >> reset [
	Current := nil
]

{ #category : 'initialization' }
CtikzComponentIndex >> initialize [
	super initialize.
	components := Dictionary new.
	status := 'fallback'.
	self registerManifest.
	self loadInstalledStyle
]

{ #category : 'accessing' }
CtikzComponentIndex >> components [ ^ components ]

{ #category : 'accessing' }
CtikzComponentIndex >> sourcePath [ ^ sourcePath ]

{ #category : 'accessing' }
CtikzComponentIndex >> status [ ^ status ]

{ #category : 'accessing' }
CtikzComponentIndex >> circuitikzVersion [ ^ circuitikzVersion ]

{ #category : 'private' }
CtikzComponentIndex >> registerManifest [
	self
		add: 'component' description: 'component';
		add: 'bipole' description: 'bipole';
		add: 'converter' description: 'ac/dc converter';
		add: 'L' description: 'inductor';
		add: 'R' description: 'resistor';
		add: 'generic' description: 'generic bipole';
		add: 'sV' description: 'independent voltage source'
]

{ #category : 'private' }
CtikzComponentIndex >> add: aKey description: aDescription [
	components at: aKey put: (CtikzComponentInfo name: aKey description: aDescription)
]

{ #category : 'private' }
CtikzComponentIndex >> loadInstalledStyle [
	| configured file |
	configured := DsktSettings env: 'DSKT_CIRCUITIKZ_STY' default: nil.
	configured ifNil: [ ^ self ].
	file := configured asFileReference.
	(file exists and: [ file isFile ])
		ifFalse: [ status := 'missing'. ^ self ].
	sourcePath := file pathString.
	circuitikzVersion := self versionFrom: file.
	self applyDeclarationsFrom: file.
	status := 'ok'
]

{ #category : 'private' }
CtikzComponentIndex >> applyDeclarationsFrom: aFileReference [
	| lines |
	lines := aFileReference contents lines.
	components keysAndValuesDo: [ :key :info |
		| index |
		index := lines findFirst: [ :line | line includesSubstring: key ].
		index > 0 ifTrue: [
			info
				declaration: aFileReference pathString , ':' , index printString;
				circuitikzVersion: circuitikzVersion ] ]
]

{ #category : 'private' }
CtikzComponentIndex >> versionFrom: aFileReference [
	| line |
	line := aFileReference contents lines
		detect: [ :each | each includesSubstring: '\pgfcircversion' ]
		ifNone: [ nil ].
	line ifNil: [ ^ nil ].
	^ (line copyAfter: ${) copyUpTo: $}
]
