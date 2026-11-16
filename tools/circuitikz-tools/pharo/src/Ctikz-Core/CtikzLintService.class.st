"
I am the facade for the CircuitTikZ source linter.

I read the source from a repository-relative path or from source_text, scan it,
run every rule in fixed order, and return a deterministic report. I contain no
tracing.
"
Class {
	#name : 'CtikzLintService',
	#superclass : 'Object',
	#instVars : [
		'rules'
	],
	#classVars : [
		'Current'
	],
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzLintService class >> default [
	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
CtikzLintService class >> reset [
	Current := nil
]

{ #category : 'initialization' }
CtikzLintService >> initialize [
	super initialize.
	rules := self class rules
]

{ #category : 'accessing' }
CtikzLintService >> rules [ ^ rules ]

{ #category : 'accessing' }
CtikzLintService >> rulesVersion [
	| document |
	document := rules collect: [ :each |
		Dictionary new
			at: 'id' put: each id;
			at: 'version' put: each version;
			at: 'severity' put: each defaultSeverity;
			yourself ].
	^ (SHA256 hashMessage: (DsktCanonicalJson toString: document) asByteArray) hex
]

{ #category : 'operations' }
CtikzLintService >> lintSource: aDictionary [
	| path sourceText source bytes pathInfo model checks summary counts report strict |
	self validateRequest: aDictionary.
	path := aDictionary at: 'path' ifAbsent: [ nil ].
	sourceText := aDictionary at: 'source_text' ifAbsent: [ nil ].
	(path isNil and: [ sourceText isNil ])
		ifTrue: [ DsktError code: 'invalid_request' message: 'Exactly one of path or source_text is required' ].
	(path notNil and: [ sourceText notNil ])
		ifTrue: [ DsktError code: 'invalid_request' message: 'Exactly one of path or source_text is required' ].
	sourceText ifNotNil: [ source := sourceText ]
	ifNil: [
		pathInfo := self resolvePath: path.
		(pathInfo size > self sourceMaxBytes)
			ifTrue: [ DsktError code: 'source_too_large' message: 'The source exceeds the configured byte limit' ].
		bytes := [ pathInfo asFileReference binaryReadStream upToEnd ]
			on: Error
			do: [ :error | DsktError code: 'source_not_found' message: 'Cannot read source: ' , path printString ].
		source := [ bytes utf8Decoded ]
			on: Error
			do: [ :error | DsktError code: 'unsupported_encoding' message: 'The source is not valid UTF-8' ] ].
	(source utf8Encoded size > self sourceMaxBytes)
		ifTrue: [ DsktError code: 'source_too_large' message: 'The source exceeds the configured byte limit' ].
	model := CtikzSourceScanner new scan: source.
	checks := OrderedCollection new.
	rules do: [ :rule |
		| result |
		result := rule evaluate: model context: aDictionary.
		result isCollection
			ifTrue: [ checks addAll: result ]
			ifFalse: [ checks add: result ] ].
	strict := (aDictionary at: 'strict' ifAbsent: [ false ]) = true.
	strict ifTrue: [
		checks := checks collect: [ :each |
			each isWarning
				ifTrue: [ CtikzLintCheck id: each id status: 'failed' message: each message line: each line details: each details ]
				ifFalse: [ each ] ] ].
	summary := Dictionary new
		at: 'passed' put: (checks count: [ :each | each status = 'passed' ]);
		at: 'warning' put: (checks count: [ :each | each status = 'warning' ]);
		at: 'failed' put: (checks count: [ :each | each status = 'failed' ]);
		yourself.
	counts := Dictionary new
		at: 'circuitikz_environments' put: model circuitikzEnvironments size;
		at: 'coordinates' put: model definedCoordinates size;
		at: 'components' put: model components size;
		yourself.
	report := CtikzLintReport
		checks: checks
		counts: counts
		summary: summary
		sourceSha256: model sourceSha256.
	report
		sourceKind: (path ifNil: [ 'text' ] ifNotNil: [ 'path' ]);
		sourcePath: path.
	^ report asDictionary
]

{ #category : 'private' }
CtikzLintService >> validateRequest: aDictionary [
	| path sourceText required forbid strict |
	path := aDictionary at: 'path' ifAbsent: [ nil ].
	sourceText := aDictionary at: 'source_text' ifAbsent: [ nil ].
	(path notNil and: [ path isString not ])
		ifTrue: [ DsktError code: 'invalid_request' message: 'path must be a string' ].
	(sourceText notNil and: [ sourceText isString not ])
		ifTrue: [ DsktError code: 'invalid_request' message: 'source_text must be a string' ].
	required := aDictionary at: 'required_labels' ifAbsent: [ nil ].
	(required notNil and: [ (required isCollection and: [ required allSatisfy: [ :each | each isString ] ]) not ])
		ifTrue: [ DsktError code: 'invalid_request' message: 'required_labels must be an array of strings' ].
	forbid := aDictionary at: 'forbid_patterns' ifAbsent: [ nil ].
	(forbid notNil and: [ (forbid isCollection and: [ forbid allSatisfy: [ :each | each isString ] ]) not ])
		ifTrue: [ DsktError code: 'invalid_request' message: 'forbid_patterns must be an array of strings' ].
	strict := aDictionary at: 'strict' ifAbsent: [ nil ].
	(strict notNil and: [ (strict = true or: [ strict = false ]) not ])
		ifTrue: [ DsktError code: 'invalid_request' message: 'strict must be a boolean' ]
]

{ #category : 'private' }
CtikzLintService >> sourceMaxBytes [
	^ (DsktSettings env: 'DSKT_SOURCE_MAX_BYTES' default: '1000000') asInteger
]

{ #category : 'private' }
CtikzLintService >> resolvePath: aPath [
	| resolved |
	resolved := DsktPathResolver resolveExisting: aPath under: DsktSettings repoRoot.
	resolved isFile
		ifFalse: [ DsktError code: 'source_not_found' message: 'Source is not a regular file: ' , aPath printString ].
	^ resolved
]

{ #category : 'rules' }
CtikzLintService class >> rules [
	^ {
		CtikzSingleCircuitikzEnvironmentRule new.
		CtikzNoTikzClassOptionRule new.
		CtikzUnsupportedConstructRule new.
		CtikzNoImageInclusionRule new.
		CtikzRequiredLabelsRule new.
		CtikzBalancedBracesRule new.
		CtikzBalancedEnvironmentsRule new.
		CtikzDefinedCoordinatesRule new.
		CtikzAmbiguousCoordinatesRule new.
		CtikzForbiddenPatternsRule new.
		CtikzComponentInventoryRule new }
]
