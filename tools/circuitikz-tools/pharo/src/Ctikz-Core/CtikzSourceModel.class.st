"
I hold the facts extracted from one CircuitTikZ source by CtikzSourceScanner.

I carry the document class and options, packages, libraries, environments,
brace balance, defined and referenced coordinates, components, labels, forbidden
matches, and the line map needed to report 1-based source lines.
"
Class {
	#name : 'CtikzSourceModel',
	#superclass : 'Object',
	#instVars : [
		'source',
		'sourceSha256',
		'documentClass',
		'documentClassOptions',
		'packages',
		'libraries',
		'environments',
		'braceBalance',
		'braceErrors',
		'definedCoordinates',
		'coordinateReferences',
		'components',
		'labels',
		'forbiddenMatches',
		'activeSource',
		'unsupported',
		'lineMap'
	],
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzSourceModel >> source [ ^ source ]
{ #category : 'accessing' }
CtikzSourceModel >> source: anObject [ source := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> sourceSha256 [ ^ sourceSha256 ]
{ #category : 'accessing' }
CtikzSourceModel >> sourceSha256: anObject [ sourceSha256 := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> documentClass [ ^ documentClass ]
{ #category : 'accessing' }
CtikzSourceModel >> documentClass: anObject [ documentClass := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> documentClassOptions [ ^ documentClassOptions ifNil: [ documentClassOptions := OrderedCollection new ] ]
{ #category : 'accessing' }
CtikzSourceModel >> documentClassOptions: anObject [ documentClassOptions := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> packages [ ^ packages ifNil: [ packages := OrderedCollection new ] ]
{ #category : 'accessing' }
CtikzSourceModel >> packages: anObject [ packages := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> libraries [ ^ libraries ifNil: [ libraries := OrderedCollection new ] ]
{ #category : 'accessing' }
CtikzSourceModel >> libraries: anObject [ libraries := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> environments [ ^ environments ifNil: [ environments := OrderedCollection new ] ]
{ #category : 'accessing' }
CtikzSourceModel >> environments: anObject [ environments := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> braceBalance [ ^ braceBalance ifNil: [ braceBalance := 0 ] ]
{ #category : 'accessing' }
CtikzSourceModel >> braceBalance: anObject [ braceBalance := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> braceErrors [ ^ braceErrors ifNil: [ braceErrors := OrderedCollection new ] ]
{ #category : 'accessing' }
CtikzSourceModel >> braceErrors: anObject [ braceErrors := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> definedCoordinates [ ^ definedCoordinates ifNil: [ definedCoordinates := OrderedCollection new ] ]
{ #category : 'accessing' }
CtikzSourceModel >> definedCoordinates: anObject [ definedCoordinates := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> coordinateReferences [ ^ coordinateReferences ifNil: [ coordinateReferences := OrderedCollection new ] ]
{ #category : 'accessing' }
CtikzSourceModel >> coordinateReferences: anObject [ coordinateReferences := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> components [ ^ components ifNil: [ components := OrderedCollection new ] ]
{ #category : 'accessing' }
CtikzSourceModel >> components: anObject [ components := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> labels [ ^ labels ifNil: [ labels := OrderedCollection new ] ]
{ #category : 'accessing' }
CtikzSourceModel >> labels: anObject [ labels := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> forbiddenMatches [ ^ forbiddenMatches ifNil: [ forbiddenMatches := OrderedCollection new ] ]
{ #category : 'accessing' }
CtikzSourceModel >> forbiddenMatches: anObject [ forbiddenMatches := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> activeSource [ ^ activeSource ifNil: [ activeSource := '' ] ]
{ #category : 'accessing' }
CtikzSourceModel >> activeSource: anObject [ activeSource := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> lineForOffset: anIndex [
	| line |
	line := 1.
	1 to: (anIndex min: self activeSource size) do: [ :index |
		(self activeSource at: index) = Character lf ifTrue: [ line := line + 1 ] ].
	^ line
]
{ #category : 'accessing' }
CtikzSourceModel >> unsupported [ ^ unsupported ifNil: [ unsupported := OrderedCollection new ] ]
{ #category : 'accessing' }
CtikzSourceModel >> unsupported: anObject [ unsupported := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> lineMap [ ^ lineMap ifNil: [ lineMap := OrderedCollection new ] ]
{ #category : 'accessing' }
CtikzSourceModel >> lineMap: anObject [ lineMap := anObject ]
{ #category : 'accessing' }
CtikzSourceModel >> circuitikzEnvironments [
	^ self environments select: [ :each |
		(each isKindOf: Dictionary)
			ifTrue: [ (each at: 'name') = 'circuitikz' and: [ (each at: 'kind') = 'begin' ] ]
			ifFalse: [ each = 'circuitikz' ] ]
]
