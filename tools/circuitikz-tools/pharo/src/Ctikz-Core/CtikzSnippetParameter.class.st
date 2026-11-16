"
I describe one parameter accepted by a CircuitTikZ snippet.

I am schema metadata, not a value: name, type, required flag, default, enum, and
description. The renderer uses me to validate caller parameters; the catalog uses
me to expose the parameter schema to the agent.
"
Class {
	#name : 'CtikzSnippetParameter',
	#superclass : 'Object',
	#instVars : [
		'name',
		'type',
		'required',
		'default',
		'enum',
		'description'
	],
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'instance creation' }
CtikzSnippetParameter class >> fromDictionary: aDictionary [
	^ self new
		name: (aDictionary at: 'name' ifAbsent: [ nil ]);
		type: (aDictionary at: 'type' ifAbsent: [ 'string' ]);
		required: (aDictionary at: 'required' ifAbsent: [ false ]);
		default: (aDictionary at: 'default' ifAbsent: [ nil ]);
		enum: (aDictionary at: 'enum' ifAbsent: [ nil ]);
		description: (aDictionary at: 'description' ifAbsent: [ nil ]);
		yourself
]

{ #category : 'instance creation' }
CtikzSnippetParameter class >> named: aName type: aType [
	^ self new
		name: aName;
		type: aType;
		required: false;
		yourself
]

{ #category : 'accessing' }
CtikzSnippetParameter >> name [ ^ name ]

{ #category : 'accessing' }
CtikzSnippetParameter >> name: anObject [ name := anObject ]

{ #category : 'accessing' }
CtikzSnippetParameter >> type [ ^ type ]

{ #category : 'accessing' }
CtikzSnippetParameter >> type: anObject [ type := anObject ]

{ #category : 'accessing' }
CtikzSnippetParameter >> required [ ^ required ]

{ #category : 'accessing' }
CtikzSnippetParameter >> required: anObject [ required := anObject ]

{ #category : 'accessing' }
CtikzSnippetParameter >> default [ ^ default ]

{ #category : 'accessing' }
CtikzSnippetParameter >> default: anObject [ default := anObject ]

{ #category : 'accessing' }
CtikzSnippetParameter >> enum [ ^ enum ]

{ #category : 'accessing' }
CtikzSnippetParameter >> enum: anObject [ enum := anObject ]

{ #category : 'accessing' }
CtikzSnippetParameter >> description [ ^ description ]

{ #category : 'accessing' }
CtikzSnippetParameter >> description: anObject [ description := anObject ]

{ #category : 'converting' }
CtikzSnippetParameter >> asDictionary [
	^ Dictionary new
		at: 'name' put: name;
		at: 'type' put: type;
		at: 'required' put: required;
		at: 'default' put: default;
		at: 'enum' put: enum;
		at: 'description' put: description;
		yourself
]
