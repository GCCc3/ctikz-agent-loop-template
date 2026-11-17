"
I am one schemabloc snippet.
"
Class {
	#name : 'SchemablocSnippet',
	#superclass : 'Object',
	#instVars : [ 'id', 'title', 'kind', 'tags', 'description', 'mustacheSource', 'parameterSchema', 'presetParameters', 'requires', 'provides', 'version', 'checksum' ],
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'instance creation' }
SchemablocSnippet class >> id: anId title: aTitle kind: aKind source: aSource schema: aSchema [
	^ self new
		id: anId;
		title: aTitle;
		kind: aKind;
		mustacheSource: aSource;
		parameterSchema: aSchema;
		yourself
]
{ #category : 'accessing' }
SchemablocSnippet >> id [ ^ id ]
{ #category : 'accessing' }
SchemablocSnippet >> id: anObject [ id := anObject ]
{ #category : 'accessing' }
SchemablocSnippet >> title [ ^ title ]
{ #category : 'accessing' }
SchemablocSnippet >> title: anObject [ title := anObject ]
{ #category : 'accessing' }
SchemablocSnippet >> kind [ ^ kind ]
{ #category : 'accessing' }
SchemablocSnippet >> kind: anObject [ kind := anObject ]
{ #category : 'accessing' }
SchemablocSnippet >> tags [ ^ tags ifNil: [ tags := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocSnippet >> tags: anObject [ tags := anObject ]
{ #category : 'accessing' }
SchemablocSnippet >> description [ ^ description ]
{ #category : 'accessing' }
SchemablocSnippet >> description: anObject [ description := anObject ]
{ #category : 'accessing' }
SchemablocSnippet >> mustacheSource [ ^ mustacheSource ]
{ #category : 'accessing' }
SchemablocSnippet >> mustacheSource: anObject [ mustacheSource := anObject. checksum := nil ]
{ #category : 'accessing' }
SchemablocSnippet >> parameterSchema [ ^ parameterSchema ifNil: [ parameterSchema := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocSnippet >> parameterSchema: anObject [ parameterSchema := anObject ]
{ #category : 'accessing' }
SchemablocSnippet >> presetParameters [ ^ presetParameters ifNil: [ presetParameters := Dictionary new ] ]
{ #category : 'accessing' }
SchemablocSnippet >> presetParameters: anObject [ presetParameters := anObject ]
{ #category : 'accessing' }
SchemablocSnippet >> requires [ ^ requires ifNil: [ requires := Dictionary new ] ]
{ #category : 'accessing' }
SchemablocSnippet >> requires: anObject [ requires := anObject ]
{ #category : 'accessing' }
SchemablocSnippet >> provides [ ^ provides ifNil: [ provides := Dictionary new ] ]
{ #category : 'accessing' }
SchemablocSnippet >> provides: anObject [ provides := anObject ]
{ #category : 'accessing' }
SchemablocSnippet >> version [ ^ version ifNil: [ version := 1 ] ]
{ #category : 'accessing' }
SchemablocSnippet >> version: anObject [ version := anObject ]
{ #category : 'accessing' }
SchemablocSnippet >> checksum [
	^ checksum ifNil: [ checksum := (SHA256 hashMessage: (mustacheSource ifNil: [ '' ]) asByteArray) hex ]
]
{ #category : 'converting' }
SchemablocSnippet >> asDictionary [
	^ Dictionary new
		at: 'id' put: id;
		at: 'title' put: title;
		at: 'kind' put: kind;
		at: 'tags' put: self tags asArray;
		at: 'description' put: description;
		at: 'source' put: mustacheSource;
		at: 'parameters' put: (self parameterSchema collect: [ :each | each asDictionary ]);
		at: 'presets' put: self presetParameters;
		at: 'requires' put: self requires;
		at: 'provides' put: self provides;
		at: 'version' put: self version;
		at: 'checksum' put: self checksum;
		yourself
]
