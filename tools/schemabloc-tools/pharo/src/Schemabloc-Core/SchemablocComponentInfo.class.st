"
I describe one schemabloc macro.
"
Class {
	#name : 'SchemablocComponentInfo',
	#superclass : 'Object',
	#instVars : [
		'name',
		'description',
		'argumentCount',
		'definesNode',
		'consumesPrevious',
		'drawsLink',
		'snippetIds'
	],
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'instance creation' }
SchemablocComponentInfo class >> name: aName description: aDescription [
	^ self new
		name: aName;
		description: aDescription;
		yourself
]

{ #category : 'accessing' }
SchemablocComponentInfo >> name [ ^ name ]
{ #category : 'accessing' }
SchemablocComponentInfo >> name: anObject [ name := anObject ]
{ #category : 'accessing' }
SchemablocComponentInfo >> description [ ^ description ]
{ #category : 'accessing' }
SchemablocComponentInfo >> description: anObject [ description := anObject ]
{ #category : 'accessing' }
SchemablocComponentInfo >> argumentCount [ ^ argumentCount ]
{ #category : 'accessing' }
SchemablocComponentInfo >> argumentCount: anObject [ argumentCount := anObject ]
{ #category : 'accessing' }
SchemablocComponentInfo >> definesNode [ ^ definesNode ifNil: [ false ] ]
{ #category : 'accessing' }
SchemablocComponentInfo >> definesNode: anObject [ definesNode := anObject ]
{ #category : 'accessing' }
SchemablocComponentInfo >> consumesPrevious [ ^ consumesPrevious ifNil: [ false ] ]
{ #category : 'accessing' }
SchemablocComponentInfo >> consumesPrevious: anObject [ consumesPrevious := anObject ]
{ #category : 'accessing' }
SchemablocComponentInfo >> drawsLink [ ^ drawsLink ifNil: [ false ] ]
{ #category : 'accessing' }
SchemablocComponentInfo >> drawsLink: anObject [ drawsLink := anObject ]
{ #category : 'accessing' }
SchemablocComponentInfo >> snippetIds [ ^ snippetIds ifNil: [ snippetIds := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocComponentInfo >> snippetIds: anObject [ snippetIds := anObject ]

{ #category : 'converting' }
SchemablocComponentInfo >> asDictionary [
	^ Dictionary new
		at: 'name' put: name;
		at: 'description' put: description;
		at: 'argument_count' put: argumentCount;
		at: 'defines_node' put: self definesNode;
		at: 'consumes_previous' put: self consumesPrevious;
		at: 'draws_link' put: self drawsLink;
		at: 'snippet_ids' put: self snippetIds asArray;
		yourself
]
