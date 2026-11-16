"
I describe one installed CircuitTikZ component or style key.

I carry the component name, a human-readable description, the declaration
location when known, aliases, default length and height, and style defaults.
I also carry the ids of catalog snippets that use this component.
"
Class {
	#name : 'CtikzComponentInfo',
	#superclass : 'Object',
	#instVars : [
		'name',
		'description',
		'declaration',
		'aliases',
		'defaultLength',
		'defaultHeight',
		'styleDefaults',
		'snippetIds',
		'circuitikzVersion'
	],
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'instance creation' }
CtikzComponentInfo class >> name: aName description: aDescription [
	^ self new
		name: aName;
		description: aDescription;
		yourself
]

{ #category : 'accessing' }
CtikzComponentInfo >> name [ ^ name ]

{ #category : 'accessing' }
CtikzComponentInfo >> name: anObject [ name := anObject ]

{ #category : 'accessing' }
CtikzComponentInfo >> description [ ^ description ]

{ #category : 'accessing' }
CtikzComponentInfo >> description: anObject [ description := anObject ]

{ #category : 'accessing' }
CtikzComponentInfo >> declaration [ ^ declaration ]

{ #category : 'accessing' }
CtikzComponentInfo >> declaration: anObject [ declaration := anObject ]

{ #category : 'accessing' }
CtikzComponentInfo >> aliases [ ^ aliases ifNil: [ aliases := OrderedCollection new ] ]

{ #category : 'accessing' }
CtikzComponentInfo >> aliases: anObject [ aliases := anObject ]

{ #category : 'accessing' }
CtikzComponentInfo >> defaultLength [ ^ defaultLength ]

{ #category : 'accessing' }
CtikzComponentInfo >> defaultLength: anObject [ defaultLength := anObject ]

{ #category : 'accessing' }
CtikzComponentInfo >> defaultHeight [ ^ defaultHeight ]

{ #category : 'accessing' }
CtikzComponentInfo >> defaultHeight: anObject [ defaultHeight := anObject ]

{ #category : 'accessing' }
CtikzComponentInfo >> styleDefaults [ ^ styleDefaults ifNil: [ styleDefaults := Dictionary new ] ]

{ #category : 'accessing' }
CtikzComponentInfo >> styleDefaults: anObject [ styleDefaults := anObject ]

{ #category : 'accessing' }
CtikzComponentInfo >> snippetIds [ ^ snippetIds ifNil: [ snippetIds := OrderedCollection new ] ]

{ #category : 'accessing' }
CtikzComponentInfo >> snippetIds: anObject [ snippetIds := anObject ]

{ #category : 'accessing' }
CtikzComponentInfo >> circuitikzVersion [ ^ circuitikzVersion ]

{ #category : 'accessing' }
CtikzComponentInfo >> circuitikzVersion: anObject [ circuitikzVersion := anObject ]

{ #category : 'converting' }
CtikzComponentInfo >> asDictionary [
	^ Dictionary new
		at: 'name' put: name;
		at: 'description' put: description;
		at: 'declaration' put: declaration;
		at: 'aliases' put: self aliases asArray;
		at: 'default_length' put: defaultLength;
		at: 'default_height' put: defaultHeight;
		at: 'style_defaults' put: self styleDefaults;
		at: 'snippet_ids' put: self snippetIds asArray;
		at: 'circuitikz_version' put: circuitikzVersion;
		yourself
]
