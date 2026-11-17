"
I resolve schemabloc macro names to human-readable descriptions.
"
Class {
	#name : 'SchemablocComponentLookup',
	#superclass : 'Object',
	#instVars : [ 'knownComponents' ],
	#classVars : [ 'Current' ],
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocComponentLookup class >> default [
	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
SchemablocComponentLookup class >> reset [ Current := nil ]

{ #category : 'initialization' }
SchemablocComponentLookup >> initialize [
	super initialize.
	knownComponents := Dictionary new.
	self registerDefaults
]

{ #category : 'private' }
SchemablocComponentLookup >> registerDefaults [
	#(
		'sbEntree' 'Entry point'
		'sbSortie' 'Exit point'
		'sbBloc' 'Process block'
		'sbBlocL' 'Process block with label'
		'sbBlocr' 'Process block, right aligned'
		'sbBlocrL' 'Process block with label, right aligned'
		'sbBlocSeul' 'Standalone block'
		'sbComp' 'Comparator'
		'sbComph' 'Horizontal comparator'
		'sbSumb' 'Summing comparator'
		'sbSumh' 'Horizontal summing comparator'
		'sbCompSum' 'Comparator and summing junction'
		'sbRelier' 'Link between nodes'
		'sbRenvoi' 'Return link to a comparator'
		'sbRelierxy' 'Diagonal link'
		'sbRelieryx' 'Diagonal link'
		'sbDecaleNoeudx' 'Horizontal node offset'
		'sbDecaleNoeudy' 'Vertical node offset'
		'sbNomLien' 'Visible link label'
		'sbStyleBloc' 'Block style'
		'sbStyleLien' 'Link style'
		'sbStyleSum' 'Sum style'
	) pairsDo: [ :name :description |
		knownComponents at: name put: description ]
]

{ #category : 'accessing' }
SchemablocComponentLookup >> knownComponents [ ^ knownComponents ]

{ #category : 'operations' }
SchemablocComponentLookup >> lookup: aName [
	| description |
	description := knownComponents at: aName ifAbsent: [ nil ].
	description ifNil: [ ^ nil ].
	^ SchemablocComponentInfo name: aName description: description
]
