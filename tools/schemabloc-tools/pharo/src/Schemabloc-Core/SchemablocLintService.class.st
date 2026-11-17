"
I am the facade for the schemabloc source linter.

I read source from a repository-relative path or source_text, scan it, run rules
in fixed order, and return a deterministic report. I contain no tracing.
"
Class {
	#name : 'SchemablocLintService',
	#superclass : 'Object',
	#instVars : [ 'rules' ],
	#classVars : [ 'Current' ],
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocLintService class >> default [
	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
SchemablocLintService class >> reset [ Current := nil ]

{ #category : 'initialization' }
SchemablocLintService >> initialize [
	super initialize.
	rules := self class rules
]

{ #category : 'accessing' }
SchemablocLintService >> rules [ ^ rules ]

{ #category : 'accessing' }
SchemablocLintService >> rulesVersion [
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
SchemablocLintService >> lintSource: aDictionary [
	| path sourceText source bytes pathInfo model checks summary counts report strict required forbid |
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
	model := SchemablocSourceScanner new scan: source.
	checks := OrderedCollection new.
	required := aDictionary at: 'required_labels' ifAbsent: [ #() ].
	forbid := aDictionary at: 'forbid_patterns' ifAbsent: [ #( 'includegraphics' 'reference/target.png' ) ].
	rules do: [ :rule |
		| result |
		result := rule evaluate: model context: (aDictionary at: 'required_labels' put: required; yourself).
		result isCollection
			ifTrue: [ checks addAll: result ]
			ifFalse: [ checks add: result ] ].
	forbid do: [ :pattern |
		(source includesSubstring: pattern) ifTrue: [
			checks add: (SchemablocLintCheck id: 'forbidden_patterns' status: 'failed' message: ('Forbidden pattern found: ', pattern) line: nil details: nil) ] ].
	strict := (aDictionary at: 'strict' ifAbsent: [ false ]) = true.
	strict ifTrue: [
		checks := checks collect: [ :each |
			each isWarning
				ifTrue: [ SchemablocLintCheck id: each id status: 'failed' message: each message line: each line details: each details ]
				ifFalse: [ each ] ] ].
	summary := Dictionary new
		at: 'passed' put: (checks count: [ :each | each status = 'passed' ]);
		at: 'warning' put: (checks count: [ :each | each status = 'warning' ]);
		at: 'failed' put: (checks count: [ :each | each status = 'failed' ]);
		yourself.
	counts := model counts copy.
	report := SchemablocLintReport
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
SchemablocLintService >> validateRequest: aDictionary [
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
SchemablocLintService >> sourceMaxBytes [
	^ (DsktSettings env: 'DSKT_SOURCE_MAX_BYTES' default: '1000000') asInteger
]

{ #category : 'private' }
SchemablocLintService >> resolvePath: aPath [
	| resolved |
	resolved := DsktPathResolver resolveExisting: aPath under: DsktSettings repoRoot.
	resolved isFile
		ifFalse: [ DsktError code: 'source_not_found' message: 'Source is not a regular file: ' , aPath printString ].
	^ resolved
]

{ #category : 'rules' }
SchemablocLintService class >> rules [
	^ {
		SchemablocSingleTikzPictureRule new.
		SchemablocPackageRule new.
		SchemablocNoCircuitikzRule new.
		SchemablocNoImageRule new.
		SchemablocBalancedBracesRule new.
		SchemablocBalancedEnvironmentsRule new.
		SchemablocDefinedNodesRule new.
		SchemablocDefinedLinksRule new.
		SchemablocDuplicateNodesRule new.
		SchemablocRequiredLabelsRule new.
		SchemablocInventoryRule new.
		SchemablocManualBlockRule new.
		SchemablocUnknownMacroRule new.
		SchemablocComparatorSignsRule new }
]
