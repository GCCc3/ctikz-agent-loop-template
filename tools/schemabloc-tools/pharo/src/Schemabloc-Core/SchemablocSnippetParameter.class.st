"
I describe one schemabloc snippet parameter.
"
Class {
	#name : 'SchemablocSnippetParameter',
	#superclass : 'Object',
	#instVars : [ 'name', 'type', 'required', 'default', 'description', 'enum' ],
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'instance creation' }
SchemablocSnippetParameter class >> name: aName type: aType required: aBoolean [
	^ self new
		name: aName;
		type: aType;
		required: aBoolean;
		yourself
]
{ #category : 'accessing' }
SchemablocSnippetParameter >> name [ ^ name ]
{ #category : 'accessing' }
SchemablocSnippetParameter >> name: anObject [ name := anObject ]
{ #category : 'accessing' }
SchemablocSnippetParameter >> type [ ^ type ifNil: [ 'string' ] ]
{ #category : 'accessing' }
SchemablocSnippetParameter >> type: anObject [ type := anObject ]
{ #category : 'accessing' }
SchemablocSnippetParameter >> required [ ^ required ifNil: [ false ] ]
{ #category : 'accessing' }
SchemablocSnippetParameter >> required: anObject [ required := anObject ]
{ #category : 'accessing' }
SchemablocSnippetParameter >> default [ ^ default ]
{ #category : 'accessing' }
SchemablocSnippetParameter >> default: anObject [
	default := anObject.
	^ self
]
{ #category : 'accessing' }
SchemablocSnippetParameter >> description [ ^ description ]
{ #category : 'accessing' }
SchemablocSnippetParameter >> description: anObject [
	description := anObject.
	^ self
]
{ #category : 'accessing' }
SchemablocSnippetParameter >> enum [ ^ enum ]
{ #category : 'accessing' }
SchemablocSnippetParameter >> enum: anObject [
	enum := anObject.
	^ self
]
{ #category : 'converting' }
SchemablocSnippetParameter >> asDictionary [
	^ Dictionary new
		at: 'name' put: name;
		at: 'type' put: self type;
		at: 'required' put: self required;
		at: 'default' put: default;
		at: 'description' put: description;
		at: 'enum' put: self enum;
		yourself
]
