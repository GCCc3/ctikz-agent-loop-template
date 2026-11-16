"
I am the CircuitTikZ snippet catalog.

I load snippets from class-side methods in protocol `snippets`, validate their
uniqueness and component compatibility, compute a deterministic catalog version,
and support search and reset.
"
Class {
	#name : 'CtikzSnippetCatalog',
	#superclass : 'Object',
	#instVars : [
		'snippets',
		'catalogVersion',
		'validationWarnings'
	],
	#classVars : [
		'Current'
	],
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzSnippetCatalog class >> default [
	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
CtikzSnippetCatalog class >> reset [
	Current := nil
]

{ #category : 'initialization' }
CtikzSnippetCatalog >> initialize [
	super initialize.
	snippets := OrderedCollection new.
	validationWarnings := OrderedCollection new.
	self reload
]

{ #category : 'accessing' }
CtikzSnippetCatalog >> snippets [ ^ snippets ]

{ #category : 'accessing' }
CtikzSnippetCatalog >> validationWarnings [ ^ validationWarnings ]

{ #category : 'accessing' }
CtikzSnippetCatalog >> catalogVersion [
	^ catalogVersion ifNil: [ catalogVersion := self computeCatalogVersion ]
]

{ #category : 'accessing' }
CtikzSnippetCatalog >> snippetNamed: anId [
	^ snippets detect: [ :each | each id = anId ] ifNone: [ nil ]
]

{ #category : 'accessing' }
CtikzSnippetCatalog >> all [ ^ snippets ]

{ #category : 'initialization' }
CtikzSnippetCatalog >> reload [
	^ self reloadFrom: self class snippets
]

{ #category : 'initialization' }
CtikzSnippetCatalog >> reloadFrom: aCollection [
	| validator seen |
	snippets := aCollection.
	validator := CtikzSnippetValidator new.
	validationWarnings := OrderedCollection new.
	seen := Set new.
	snippets do: [ :each |
		(seen includes: each id)
			ifTrue: [
				validationWarnings add: (Dictionary new
					at: 'code' put: 'snippet_validation_failed';
					at: 'message' put: 'Duplicate snippet id: ' , each id printString;
					at: 'details' put: Dictionary new;
					yourself) ]
			ifFalse: [ seen add: each id ].
		[ validator validate: each in: self ]
			on: DsktError
			do: [ :error | validationWarnings add: error asDictionary ] ].
	catalogVersion := self computeCatalogVersion.
	^ snippets
]

{ #category : 'private' }
CtikzSnippetCatalog >> computeCatalogVersion [
	| document |
	document := (snippets collect: [ :each | each asDictionary ])
		asSortedCollection: [ :a :b | (a at: 'id') <= (b at: 'id') ].
	^ (SHA256 hashMessage: (DsktCanonicalJson toString: document) asByteArray) hex
]

{ #category : 'searching' }
CtikzSnippetCatalog >> search: aDictionary [
	| query tag component kind result |
	query := (aDictionary at: 'q' ifAbsent: [ nil ]) ifNotNil: [ :value | value asLowercase ].
	tag := aDictionary at: 'tag' ifAbsent: [ nil ].
	component := aDictionary at: 'component' ifAbsent: [ nil ].
	kind := aDictionary at: 'kind' ifAbsent: [ nil ].
	result := snippets select: [ :each |
		| matches |
		matches := true.
		query ifNotNil: [
			matches := matches and: [
				(each id asLowercase includesSubstring: query) or: [
					(each title asLowercase includesSubstring: query) or: [
						((each description ifNil: [ '' ]) asLowercase includesSubstring: query) ] ] ] ].
		tag ifNotNil: [ matches := matches and: [ each tags includes: tag ] ].
		component ifNotNil: [
			matches := matches and: [
				(each tags includes: component) or: [ each id = ('component/' , component) ] ] ].
		kind ifNotNil: [ matches := matches and: [ each kind = kind ] ].
		matches ].
	^ result asArray
]

{ #category : 'snippets' }
CtikzSnippetCatalog class >> snippets [
	^ OrderedCollection new
		add: (self snippetPreambleStandalone);
		add: (self snippetCoordinatePoint);
		add: (self snippetComponentBipole);
		add: (self snippetComponentL);
		add: (self snippetComponentR);
		add: (self snippetComponentGeneric);
		add: (self snippetComponentSV);
		add: (self snippetComponentAcDcConverter);
		add: (self snippetComponentLine);
		add: (self snippetAnnotationArrow);
		add: (self snippetGroupDashedRectangle);
		add: (self snippetLabelGeneric);
		yourself
]

{ #category : 'snippets' }
CtikzSnippetCatalog class >> snippetPreambleStandalone [
	^ CtikzSnippet new
		id: 'preamble/standalone-circuitikz';
		title: 'Standalone CircuitTikZ preamble';
		kind: 'preamble';
		tags: #( 'preamble' 'standalone' );
		description: 'Standalone document preamble for CircuitTikZ';
		mustacheSource: '\documentclass[{{class_options}}]{standalone}
\usepackage[{{package_options}}]{circuitikz}
{{#libraries}}
\usetikzlibrary{ {{.}} }
{{/libraries}}';
		parameterSchema: {
			(CtikzSnippetParameter named: 'class_options' type: 'string') default: ''.
			(CtikzSnippetParameter named: 'package_options' type: 'string') default: ''.
			(CtikzSnippetParameter named: 'libraries' type: 'array') default: #() };
		requires: Dictionary new;
		provides: Dictionary new;
		version: 1;
		yourself
]

{ #category : 'snippets' }
CtikzSnippetCatalog class >> snippetCoordinatePoint [
	^ CtikzSnippet new
		id: 'coordinate/point';
		title: 'Coordinate point';
		kind: 'coordinate';
		tags: #( 'coordinate' 'point' );
		description: 'A named coordinate definition';
		mustacheSource: '\coordinate ({{name}}) at ({{x}},{{y}});';
		parameterSchema: {
			(CtikzSnippetParameter named: 'name' type: 'string') required: true.
			(CtikzSnippetParameter named: 'x' type: 'number') required: true.
			(CtikzSnippetParameter named: 'y' type: 'number') required: true };
		requires: Dictionary new;
		provides: Dictionary new;
		version: 1;
		yourself
]

{ #category : 'snippets' }
CtikzSnippetCatalog class >> snippetComponentBipole [
	^ CtikzSnippet new
		id: 'component/bipole';
		title: 'Generic bipole';
		kind: 'component';
		tags: #( 'component' 'bipole' );
		description: 'A two-terminal component between two coordinates';
		mustacheSource: '\draw ({{start}}) to[{{component_options}}] ({{end}});';
		parameterSchema: {
			(CtikzSnippetParameter named: 'start' type: 'string') required: true.
			(CtikzSnippetParameter named: 'end' type: 'string') required: true.
			(CtikzSnippetParameter named: 'component_options' type: 'string') required: true };
		requires: Dictionary new;
		provides: Dictionary new;
		version: 1;
		yourself
]

{ #category : 'snippets' }
CtikzSnippetCatalog class >> snippetComponentL [
	^ CtikzSnippet new
		id: 'component/L';
		title: 'Inductor';
		kind: 'component';
		tags: #( 'component' 'L' );
		description: 'Inductor';
		mustacheSource: '\draw ({{start}}) to[{{component_options}}] ({{end}});';
		parameterSchema: {
			(CtikzSnippetParameter named: 'start' type: 'string') required: true.
			(CtikzSnippetParameter named: 'end' type: 'string') required: true };
		presetParameters: (Dictionary new at: 'component_options' put: 'L'; yourself);
		requires: (Dictionary new at: 'component/bipole' put: true; yourself);
		provides: (Dictionary new at: 'component/L' put: true; yourself);
		version: 1;
		yourself
]

{ #category : 'snippets' }
CtikzSnippetCatalog class >> snippetComponentR [
	^ CtikzSnippet new
		id: 'component/R';
		title: 'Resistor';
		kind: 'component';
		tags: #( 'component' 'R' );
		description: 'Resistor';
		mustacheSource: '\draw ({{start}}) to[{{component_options}}] ({{end}});';
		parameterSchema: {
			(CtikzSnippetParameter named: 'start' type: 'string') required: true.
			(CtikzSnippetParameter named: 'end' type: 'string') required: true };
		presetParameters: (Dictionary new at: 'component_options' put: 'R'; yourself);
		requires: (Dictionary new at: 'component/bipole' put: true; yourself);
		provides: (Dictionary new at: 'component/R' put: true; yourself);
		version: 1;
		yourself
]

{ #category : 'snippets' }
CtikzSnippetCatalog class >> snippetComponentGeneric [
	^ CtikzSnippet new
		id: 'component/generic';
		title: 'Generic bipole';
		kind: 'component';
		tags: #( 'component' 'generic' );
		description: 'Generic bipole';
		mustacheSource: '\draw ({{start}}) to[{{component_options}}] ({{end}});';
		parameterSchema: {
			(CtikzSnippetParameter named: 'start' type: 'string') required: true.
			(CtikzSnippetParameter named: 'end' type: 'string') required: true };
		presetParameters: (Dictionary new at: 'component_options' put: 'generic'; yourself);
		requires: (Dictionary new at: 'component/bipole' put: true; yourself);
		provides: (Dictionary new at: 'component/generic' put: true; yourself);
		version: 1;
		yourself
]

{ #category : 'snippets' }
CtikzSnippetCatalog class >> snippetComponentSV [
	^ CtikzSnippet new
		id: 'component/sV';
		title: 'Independent voltage source';
		kind: 'component';
		tags: #( 'component' 'sV' );
		description: 'Independent voltage source';
		mustacheSource: '\draw ({{start}}) to[{{component_options}}] ({{end}});';
		parameterSchema: {
			(CtikzSnippetParameter named: 'start' type: 'string') required: true.
			(CtikzSnippetParameter named: 'end' type: 'string') required: true };
		presetParameters: (Dictionary new at: 'component_options' put: 'sV'; yourself);
		requires: (Dictionary new at: 'component/bipole' put: true; yourself);
		provides: (Dictionary new at: 'component/sV' put: true; yourself);
		version: 1;
		yourself
]

{ #category : 'snippets' }
CtikzSnippetCatalog class >> snippetComponentAcDcConverter [
	^ CtikzSnippet new
		id: 'component/ac-dc-converter';
		title: 'AC/DC converter';
		kind: 'component';
		tags: #( 'component' 'converter' );
		description: 'AC/DC converter block with a rectangle and one diagonal';
		mustacheSource: '\draw{{block_style_options}} ({{block_start}}) rectangle ({{block_end}});
\draw{{diagonal_style_options}} ({{diagonal_start}}) -- ({{diagonal_end}});';
		parameterSchema: {
			(CtikzSnippetParameter named: 'block_start' type: 'string') required: true.
			(CtikzSnippetParameter named: 'block_end' type: 'string') required: true.
			(CtikzSnippetParameter named: 'diagonal_start' type: 'string') required: true.
			(CtikzSnippetParameter named: 'diagonal_end' type: 'string') required: true.
			(CtikzSnippetParameter named: 'block_style_options' type: 'string') default: ''.
			(CtikzSnippetParameter named: 'diagonal_style_options' type: 'string') default: '' };
		requires: Dictionary new;
		provides: Dictionary new;
		version: 1;
		yourself
]

{ #category : 'snippets' }
CtikzSnippetCatalog class >> snippetComponentLine [
	^ CtikzSnippet new
		id: 'component/line';
		title: 'Line';
		kind: 'component';
		tags: #( 'component' 'line' );
		description: 'A straight line between two coordinates';
		mustacheSource: '\draw{{style_options}} ({{start}}) -- ({{end}});';
		parameterSchema: {
			(CtikzSnippetParameter named: 'start' type: 'string') required: true.
			(CtikzSnippetParameter named: 'end' type: 'string') required: true.
			(CtikzSnippetParameter named: 'style_options' type: 'string') default: '' };
		requires: Dictionary new;
		provides: Dictionary new;
		version: 1;
		yourself
]

{ #category : 'snippets' }
CtikzSnippetCatalog class >> snippetAnnotationArrow [
	^ CtikzSnippet new
		id: 'annotation/arrow';
		title: 'Arrow';
		kind: 'annotation';
		tags: #( 'annotation' 'arrow' );
		description: 'An arrowed line';
		mustacheSource: '\draw[{{arrow_options}}] ({{start}}) -- ({{end}});';
		parameterSchema: {
			(CtikzSnippetParameter named: 'start' type: 'string') required: true.
			(CtikzSnippetParameter named: 'end' type: 'string') required: true.
			(CtikzSnippetParameter named: 'arrow_options' type: 'string') default: '-{Triangle[length=6pt,width=5pt]}' };
		requires: Dictionary new;
		provides: Dictionary new;
		version: 1;
		yourself
]

{ #category : 'snippets' }
CtikzSnippetCatalog class >> snippetGroupDashedRectangle [
	^ CtikzSnippet new
		id: 'group/dashed-rectangle';
		title: 'Dashed rectangle';
		kind: 'group';
		tags: #( 'group' 'dashed' );
		description: 'A dashed rectangle group boundary';
		mustacheSource: '\draw[dashed{{style_options}}] ({{x0}},{{y0}}) rectangle ({{x1}},{{y1}});';
		parameterSchema: {
			(CtikzSnippetParameter named: 'x0' type: 'number') required: true.
			(CtikzSnippetParameter named: 'y0' type: 'number') required: true.
			(CtikzSnippetParameter named: 'x1' type: 'number') required: true.
			(CtikzSnippetParameter named: 'y1' type: 'number') required: true.
			(CtikzSnippetParameter named: 'style_options' type: 'string') default: '' };
		requires: Dictionary new;
		provides: Dictionary new;
		version: 1;
		yourself
]

{ #category : 'snippets' }
CtikzSnippetCatalog class >> snippetLabelGeneric [
	^ CtikzSnippet new
		id: 'label/generic';
		title: 'Generic label';
		kind: 'label';
		tags: #( 'label' 'generic' );
		description: 'A generic label node';
		mustacheSource: '\node{{anchor_options}} at ({{x}},{{y}}) { {{text}} };';
		parameterSchema: {
			(CtikzSnippetParameter named: 'text' type: 'string') required: true.
			(CtikzSnippetParameter named: 'x' type: 'number') required: true.
			(CtikzSnippetParameter named: 'y' type: 'number') required: true.
			(CtikzSnippetParameter named: 'anchor_options' type: 'string') default: ''.
			(CtikzSnippetParameter named: 'style_options' type: 'string') default: '' };
		requires: Dictionary new;
		provides: Dictionary new;
		version: 1;
		yourself
]
