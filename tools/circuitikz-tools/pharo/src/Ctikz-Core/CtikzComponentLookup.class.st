"
I resolve CircuitTikZ component and style keys through the installed component index.

I return a CtikzComponentInfo for a requested key. Matching snippet ids are added
by the catalog service, not by me, to avoid a load-time cycle with the catalog.
"
Class {
	#name : 'CtikzComponentLookup',
	#superclass : 'Object',
	#instVars : [
		'index'
	],
	#classVars : [
		'Current'
	],
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzComponentLookup class >> default [
	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
CtikzComponentLookup class >> reset [
	Current := nil
]

{ #category : 'initialization' }
CtikzComponentLookup >> initialize [
	super initialize.
	index := CtikzComponentIndex default
]

{ #category : 'accessing' }
CtikzComponentLookup >> index [ ^ index ]

{ #category : 'accessing' }
CtikzComponentLookup >> knownComponents [ ^ index components ]

{ #category : 'lookup' }
CtikzComponentLookup >> lookup: aName [
	^ index components at: aName asString ifAbsent: [ nil ]
]

{ #category : 'lookup' }
CtikzComponentLookup >> lookupOrNil: aName [
	^ self lookup: aName
]
