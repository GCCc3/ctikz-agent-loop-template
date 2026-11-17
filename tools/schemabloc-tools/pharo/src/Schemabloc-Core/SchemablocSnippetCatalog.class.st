"
I hold the schemabloc snippet catalog.
"
Class {
	#name : 'SchemablocSnippetCatalog',
	#superclass : 'Object',
	#instVars : [ 'snippets', 'catalogVersion' ],
	#classVars : [ 'Current' ],
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocSnippetCatalog class >> default [
	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
SchemablocSnippetCatalog class >> reset [ Current := nil ]

{ #category : 'initialization' }
SchemablocSnippetCatalog >> initialize [
	super initialize.
	catalogVersion := 'schemabloc-1'.
	snippets := self buildSnippets
]

{ #category : 'building' }
SchemablocSnippetCatalog >> parameter: aName required: aBoolean description: aDescription [
	| parameter |
	parameter := (SchemablocSnippetParameter name: aName type: 'string' required: aBoolean) description: aDescription.
	aName = 'offset' ifTrue: [ parameter default: '0' ].
	aName = 'label' ifTrue: [ parameter default: '' ].
	^ parameter
]

{ #category : 'building' }
SchemablocSnippetCatalog >> addSnippet: anId title: aTitle kind: aKind tags: someTags source: aSource parameters: someParameters to: aCollection [
	| snippet |
	snippet := SchemablocSnippet id: anId title: aTitle kind: aKind source: aSource schema: someParameters.
	snippet tags: someTags.
	aCollection add: snippet.
	^ snippet
]

{ #category : 'building' }
SchemablocSnippetCatalog >> buildSnippets [
	| result |
	result := OrderedCollection new.
	self addSnippet: 'preamble/schemabloc-standalone' title: 'Standalone schemabloc preamble' kind: 'preamble'
		tags: #('preamble' 'schemabloc')
		source: '\documentclass[border=5mm]{standalone}
\usepackage{amsmath}
\usepackage{schemabloc}
\usetikzlibrary{arrows.meta,calc,positioning}'
		parameters: { }
		to: result.
	self addSnippet: 'entry' title: 'Entree' kind: 'entry' tags: #('entry' 'sbEntree')
		source: '\sbEntree{ {{name}} }'
		parameters: { self parameter: 'name' required: true description: 'Entry name' }
		to: result.
	self addSnippet: 'block' title: 'Bloc' kind: 'block' tags: #('block' 'sbBloc')
		source: '\sbBloc[{{offset}}]{ {{name}} }{ {{content}} }{ {{previous}} }'
		parameters: {
			self parameter: 'name' required: true description: 'Node name'.
			self parameter: 'content' required: true description: 'Block label'.
			self parameter: 'previous' required: true description: 'Previous node'.
			self parameter: 'offset' required: false description: 'Optional horizontal offset' }
		to: result.
	self addSnippet: 'block-linked' title: 'Bloc lie' kind: 'block' tags: #('block' 'sbBlocL')
		source: '\sbBlocL[{{offset}}]{ {{name}} }{ {{content}} }{ {{previous}} }'
		parameters: {
			self parameter: 'name' required: true description: 'Node name'.
			self parameter: 'content' required: true description: 'Block label'.
			self parameter: 'previous' required: true description: 'Previous node'.
			self parameter: 'offset' required: false description: 'Optional horizontal offset' }
		to: result.
	self addSnippet: 'block-right' title: 'Bloc droit' kind: 'block' tags: #('block' 'sbBlocr')
		source: '\sbBlocr[{{offset}}]{ {{name}} }{ {{content}} }{ {{previous}} }'
		parameters: {
			self parameter: 'name' required: true description: 'Node name'.
			self parameter: 'content' required: true description: 'Block label'.
			self parameter: 'previous' required: true description: 'Previous node'.
			self parameter: 'offset' required: false description: 'Optional horizontal offset' }
		to: result.
	self addSnippet: 'block-right-linked' title: 'Bloc droit lie' kind: 'block' tags: #('block' 'sbBlocrL')
		source: '\sbBlocrL[{{offset}}]{ {{name}} }{ {{content}} }{ {{previous}} }'
		parameters: {
			self parameter: 'name' required: true description: 'Node name'.
			self parameter: 'content' required: true description: 'Block label'.
			self parameter: 'previous' required: true description: 'Previous node'.
			self parameter: 'offset' required: false description: 'Optional horizontal offset' }
		to: result.
	self addSnippet: 'block-alone' title: 'Bloc seul' kind: 'block' tags: #('block' 'sbBlocSeul')
		source: '\sbBlocSeul[{{offset}}]{ {{input}} }{ {{content}} }{ {{output}} }'
		parameters: {
			self parameter: 'input' required: true description: 'Input anchor'.
			self parameter: 'content' required: true description: 'Block label'.
			self parameter: 'output' required: true description: 'Output anchor'.
			self parameter: 'offset' required: false description: 'Optional horizontal offset' }
		to: result.
	self addSnippet: 'comparator' title: 'Comparateur' kind: 'comparator' tags: #('comparator' 'sbComp')
		source: '\sbComp[{{offset}}]{ {{name}} }{ {{previous}} }'
		parameters: {
			self parameter: 'name' required: true description: 'Comparator name'.
			self parameter: 'previous' required: true description: 'Previous node'.
			self parameter: 'offset' required: false description: 'Optional horizontal offset' }
		to: result.
	self addSnippet: 'comparator-star' title: 'Comparateur etoile' kind: 'comparator' tags: #('comparator' 'sbComp*')
		source: '\sbComp*[{{offset}}]{ {{name}} }{ {{previous}} }'
		parameters: {
			self parameter: 'name' required: true description: 'Comparator name'.
			self parameter: 'previous' required: true description: 'Previous node'.
			self parameter: 'offset' required: false description: 'Optional horizontal offset' }
		to: result.
	self addSnippet: 'comparator-horizontal' title: 'Comparateur horizontal' kind: 'comparator' tags: #('comparator' 'sbComph')
		source: '\sbComph[{{offset}}]{ {{name}} }{ {{previous}} }'
		parameters: {
			self parameter: 'name' required: true description: 'Comparator name'.
			self parameter: 'previous' required: true description: 'Previous node'.
			self parameter: 'offset' required: false description: 'Optional horizontal offset' }
		to: result.
	self addSnippet: 'sum-b' title: 'Sommateur vertical' kind: 'comparator' tags: #('comparator' 'sbSumb')
		source: '\sbSumb[{{offset}}]{ {{name}} }{ {{previous}} }'
		parameters: {
			self parameter: 'name' required: true description: 'Sum name'.
			self parameter: 'previous' required: true description: 'Previous node'.
			self parameter: 'offset' required: false description: 'Optional horizontal offset' }
		to: result.
	self addSnippet: 'sum-h' title: 'Sommateur horizontal' kind: 'comparator' tags: #('comparator' 'sbSumh')
		source: '\sbSumh[{{offset}}]{ {{name}} }{ {{previous}} }'
		parameters: {
			self parameter: 'name' required: true description: 'Sum name'.
			self parameter: 'previous' required: true description: 'Previous node'.
			self parameter: 'offset' required: false description: 'Optional horizontal offset' }
		to: result.
	self addSnippet: 'combined-sum' title: 'Comparateur-sommateur' kind: 'comparator' tags: #('comparator' 'sbCompSum')
		source: '\sbCompSum[{{offset}}]{ {{name}} }{ {{previous}} }{ {{a}} }{ {{b}} }{ {{c}} }{ {{d}} }'
		parameters: {
			self parameter: 'name' required: true description: 'Node name'.
			self parameter: 'previous' required: true description: 'Previous node'.
			self parameter: 'a' required: true description: 'First sign'.
			self parameter: 'b' required: true description: 'Second sign'.
			self parameter: 'c' required: true description: 'Third sign'.
			self parameter: 'd' required: true description: 'Fourth sign'.
			self parameter: 'offset' required: false description: 'Optional offset' }
		to: result.
	self addSnippet: 'link' title: 'Lien' kind: 'link' tags: #('link' 'sbRelier')
		source: '\sbRelier[{{label}}]{ {{from}} }{ {{to}} }'
		parameters: {
			self parameter: 'from' required: true description: 'Source node'.
			self parameter: 'to' required: true description: 'Target node'.
			self parameter: 'label' required: false description: 'Optional link label' }
		to: result.
	self addSnippet: 'return-link' title: 'Renvoi' kind: 'link' tags: #('link' 'sbRenvoi')
		source: '\sbRenvoi[{{offset}}]{ {{link}} }{ {{comparator}} }{ {{label}} }'
		parameters: {
			self parameter: 'link' required: true description: 'Link name'.
			self parameter: 'comparator' required: true description: 'Comparator name'.
			self parameter: 'label' required: true description: 'Visible label'.
			self parameter: 'offset' required: false description: 'Optional offset' }
		to: result.
	self addSnippet: 'link-xy' title: 'Lien diagonal' kind: 'link' tags: #('link' 'sbRelierxy')
		source: '\sbRelierxy[{{label}}]{ {{block}} }{ {{comparator}} }'
		parameters: {
			self parameter: 'block' required: true description: 'Block name'.
			self parameter: 'comparator' required: true description: 'Comparator name'.
			self parameter: 'label' required: false description: 'Optional link label' }
		to: result.
	self addSnippet: 'link-yx' title: 'Lien diagonal inverse' kind: 'link' tags: #('link' 'sbRelieryx')
		source: '\sbRelieryx{ {{link}} }{ {{block}} }'
		parameters: {
			self parameter: 'link' required: true description: 'Link name'.
			self parameter: 'block' required: true description: 'Block name' }
		to: result.
	self addSnippet: 'shift-x' title: 'Decalage horizontal' kind: 'coordinate' tags: #('coordinate' 'sbDecaleNoeudx')
		source: '\sbDecaleNoeudx{ {{from}} }{ {{name}} }'
		parameters: {
			self parameter: 'from' required: true description: 'Source coordinate'.
			self parameter: 'name' required: true description: 'New coordinate name' }
		to: result.
	self addSnippet: 'shift-y' title: 'Decalage vertical' kind: 'coordinate' tags: #('coordinate' 'sbDecaleNoeudy')
		source: '\sbDecaleNoeudy{ {{from}} }{ {{name}} }'
		parameters: {
			self parameter: 'from' required: true description: 'Source coordinate'.
			self parameter: 'name' required: true description: 'New coordinate name' }
		to: result.
	self addSnippet: 'name-link' title: 'Nom de lien' kind: 'label' tags: #('label' 'sbNomLien')
		source: '\sbNomLien[{{offset}}]{ {{link}} }{ {{label}} }'
		parameters: {
			self parameter: 'link' required: true description: 'Link name'.
			self parameter: 'label' required: true description: 'Visible label'.
			self parameter: 'offset' required: false description: 'Optional offset' }
		to: result.
	self addSnippet: 'exit' title: 'Sortie' kind: 'exit' tags: #('exit' 'sbSortie')
		source: '\sbSortie[{{offset}}]{ {{name}} }{ {{previous}} }'
		parameters: {
			self parameter: 'name' required: true description: 'Exit name'.
			self parameter: 'previous' required: true description: 'Previous node'.
			self parameter: 'offset' required: false description: 'Optional horizontal offset' }
		to: result.
	self addSnippet: 'style-block' title: 'Style de bloc' kind: 'style' tags: #('style' 'sbStyleBloc')
		source: '\sbStyleBloc{ {{options}} }'
		parameters: { self parameter: 'options' required: true description: 'TikZ style options' }
		to: result.
	self addSnippet: 'style-link' title: 'Style de lien' kind: 'style' tags: #('style' 'sbStyleLien')
		source: '\sbStyleLien{ {{options}} }'
		parameters: { self parameter: 'options' required: true description: 'TikZ style options' }
		to: result.
	self addSnippet: 'style-sum' title: 'Style de sommateur' kind: 'style' tags: #('style' 'sbStyleSum')
		source: '\sbStyleSum{ {{options}} }'
		parameters: { self parameter: 'options' required: true description: 'TikZ style options' }
		to: result.
	self addSnippet: 'annotation' title: 'Annotation TikZ' kind: 'annotation' tags: #('annotation' 'node')
		source: '\node[{{style}}] at ({{position}}) { {{text}} };'
		parameters: {
			self parameter: 'style' required: true description: 'Node style'.
			self parameter: 'position' required: true description: 'Coordinate or anchor'.
			self parameter: 'text' required: true description: 'Annotation text' }
		to: result.
	^ result
]

{ #category : 'accessing' }
SchemablocSnippetCatalog >> snippets [ ^ snippets ifNil: [ snippets := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocSnippetCatalog >> catalogVersion [ ^ catalogVersion ]
{ #category : 'accessing' }
SchemablocSnippetCatalog >> validationWarnings [
	| warnings |
	warnings := OrderedCollection new.
	self snippets isEmpty ifTrue: [ warnings add: 'catalog is empty' ].
	self snippets do: [ :each |
		(each id isNil or: [ each id isEmpty ]) ifTrue: [ warnings add: 'snippet without id' ].
		(each mustacheSource isNil or: [ each mustacheSource isEmpty ]) ifTrue: [ warnings add: 'snippet without source: ' , each id printString ] ].
	^ warnings asArray
]
{ #category : 'accessing' }
SchemablocSnippetCatalog >> snippetNamed: anId [
	^ self snippets detect: [ :each | each id = anId ] ifNone: [ nil ]
]
{ #category : 'operations' }
SchemablocSnippetCatalog >> search: aDictionary [
	| q tag component kind |
	q := (aDictionary at: 'q' ifAbsent: [ nil ]) ifNotNil: [ :value | value asLowercase ].
	tag := aDictionary at: 'tag' ifAbsent: [ nil ].
	component := aDictionary at: 'component' ifAbsent: [ nil ].
	kind := aDictionary at: 'kind' ifAbsent: [ nil ].
	^ (self snippets select: [ :each |
		(q isNil or: [
			(each id asLowercase includesSubstring: q)
				or: [ (each title asLowercase includesSubstring: q)
					or: [ each description notNil and: [ each description asLowercase includesSubstring: q ] ] ] ])
			and: [ (tag isNil or: [ each tags includes: tag ])
				and: [ (component isNil or: [ each tags includes: component ])
					and: [ kind isNil or: [ each kind = kind ] ] ] ] ]) asSortedCollection: [ :a :b | a id <= b id ]
]

{ #category : 'converting' }
SchemablocSnippetCatalog >> asDictionary [
	^ Dictionary new
		at: 'catalog_version' put: self catalogVersion;
		at: 'snippets' put: (self snippets collect: [ :each | each asDictionary ]);
		yourself
]
