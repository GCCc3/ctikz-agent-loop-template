"
I hold the scanner result for one schemabloc source.
"
Class {
	#name : 'SchemablocSourceModel',
	#superclass : 'Object',
	#instVars : [
		'source',
		'sourceSha256',
		'packages',
		'tikzPictures',
		'environments',
		'braceBalance',
		'braceErrors',
		'definitions',
		'references',
		'links',
		'labels',
		'definedLinks',
		'linkReferences',
		'unknownMacros',
		'manualRectangles'
	],
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocSourceModel >> source [ ^ source ifNil: [ '' ] ]
{ #category : 'accessing' }
SchemablocSourceModel >> source: anObject [ source := anObject ]
{ #category : 'accessing' }
SchemablocSourceModel >> sourceSha256 [ ^ sourceSha256 ]
{ #category : 'accessing' }
SchemablocSourceModel >> sourceSha256: anObject [ sourceSha256 := anObject ]
{ #category : 'accessing' }
SchemablocSourceModel >> packages [ ^ packages ifNil: [ packages := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocSourceModel >> packages: anObject [ packages := anObject ]
{ #category : 'accessing' }
SchemablocSourceModel >> tikzPictures [ ^ tikzPictures ifNil: [ 0 ] ]
{ #category : 'accessing' }
SchemablocSourceModel >> tikzPictures: anObject [ tikzPictures := anObject ]
{ #category : 'accessing' }
SchemablocSourceModel >> environments [ ^ environments ifNil: [ environments := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocSourceModel >> environments: anObject [ environments := anObject ]
{ #category : 'accessing' }
SchemablocSourceModel >> braceBalance [ ^ braceBalance ifNil: [ 0 ] ]
{ #category : 'accessing' }
SchemablocSourceModel >> braceBalance: anObject [ braceBalance := anObject ]
{ #category : 'accessing' }
SchemablocSourceModel >> braceErrors [ ^ braceErrors ifNil: [ OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocSourceModel >> braceErrors: anObject [ braceErrors := anObject ]
{ #category : 'accessing' }
SchemablocSourceModel >> definitions [ ^ definitions ifNil: [ definitions := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocSourceModel >> definitions: anObject [ definitions := anObject ]
{ #category : 'accessing' }
SchemablocSourceModel >> references [ ^ references ifNil: [ references := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocSourceModel >> references: anObject [ references := anObject ]
{ #category : 'accessing' }
SchemablocSourceModel >> links [ ^ links ifNil: [ links := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocSourceModel >> links: anObject [ links := anObject ]
{ #category : 'accessing' }
SchemablocSourceModel >> labels [ ^ labels ifNil: [ labels := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocSourceModel >> labels: anObject [ labels := anObject ]
{ #category : 'accessing' }
SchemablocSourceModel >> definedLinks [ ^ definedLinks ifNil: [ definedLinks := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocSourceModel >> definedLinks: anObject [ definedLinks := anObject ]
{ #category : 'accessing' }
SchemablocSourceModel >> linkReferences [ ^ linkReferences ifNil: [ linkReferences := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocSourceModel >> linkReferences: anObject [ linkReferences := anObject ]
{ #category : 'accessing' }
SchemablocSourceModel >> unknownMacros [ ^ unknownMacros ifNil: [ unknownMacros := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocSourceModel >> unknownMacros: anObject [ unknownMacros := anObject ]
{ #category : 'accessing' }
SchemablocSourceModel >> manualRectangles [ ^ manualRectangles ifNil: [ manualRectangles := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocSourceModel >> manualRectangles: anObject [ manualRectangles := anObject ]

{ #category : 'accessing' }
SchemablocSourceModel >> definitionNames [
	^ (self definitions collect: [ :each | each at: 'name' ]) asSet
]

{ #category : 'testing' }
SchemablocSourceModel >> hasPackage: aString [
	^ self packages anySatisfy: [ :each | each = aString ]
]

{ #category : 'accessing' }
SchemablocSourceModel >> counts [
	^ Dictionary new
		at: 'blocks' put: (self definitions count: [ :each | (#('sbBloc' 'sbBlocL' 'sbBlocr' 'sbBlocrL' 'sbBlocSeul') includes: (each at: 'macro')) ]);
		at: 'comparators' put: (self definitions count: [ :each | (#('sbComp' 'sbComp*' 'sbComph' 'sbSumb' 'sbSumh' 'sbCompSum') includes: (each at: 'macro')) ]);
		at: 'links' put: self links size;
		at: 'entries' put: (self definitions count: [ :each | (each at: 'macro') = 'sbEntree' ]);
		at: 'exits' put: (self definitions count: [ :each | (each at: 'macro') = 'sbSortie' ]);
		yourself
]

{ #category : 'converting' }
SchemablocSourceModel >> asDictionary [
	^ Dictionary new
		at: 'source_sha256' put: sourceSha256;
		at: 'packages' put: self packages asArray;
		at: 'tikz_pictures' put: self tikzPictures;
		at: 'environments' put: self environments asArray;
		at: 'brace_balance' put: self braceBalance;
		at: 'brace_errors' put: self braceErrors asArray;
		at: 'definitions' put: self definitions asArray;
		at: 'references' put: self references asArray;
		at: 'links' put: self links asArray;
		at: 'labels' put: self labels asArray;
		at: 'defined_links' put: self definedLinks asArray;
		at: 'link_references' put: self linkReferences asArray;
		at: 'unknown_macros' put: self unknownMacros asArray;
		at: 'manual_rectangles' put: self manualRectangles;
		at: 'counts' put: self counts;
		yourself
]
