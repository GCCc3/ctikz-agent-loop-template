"
I am one CircuitTikZ snippet.

I hold a Mustache source for a leaf construct, a parameter schema, optional preset
parameters, and metadata. I do not represent a document and I do not assume target
geometry or labels.
"
Class {
	#name : 'CtikzSnippet',
	#superclass : 'Object',
	#instVars : [
		'id',
		'title',
		'kind',
		'tags',
		'description',
		'mustacheSource',
		'parameterSchema',
		'presetParameters',
		'requires',
		'provides',
		'version',
		'checksum'
	],
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'instance creation' }
CtikzSnippet class >> id: anId title: aTitle kind: aKind source: aSource schema: aSchema [
	^ self new
		id: anId;
		title: aTitle;
		kind: aKind;
		mustacheSource: aSource;
		parameterSchema: aSchema;
		yourself
]

{ #category : 'accessing' }
CtikzSnippet >> id [ ^ id ]

{ #category : 'accessing' }
CtikzSnippet >> id: anObject [ id := anObject ]

{ #category : 'accessing' }
CtikzSnippet >> title [ ^ title ]

{ #category : 'accessing' }
CtikzSnippet >> title: anObject [ title := anObject ]

{ #category : 'accessing' }
CtikzSnippet >> kind [ ^ kind ]

{ #category : 'accessing' }
CtikzSnippet >> kind: anObject [ kind := anObject ]

{ #category : 'accessing' }
CtikzSnippet >> tags [ ^ tags ifNil: [ tags := OrderedCollection new ] ]

{ #category : 'accessing' }
CtikzSnippet >> tags: anObject [ tags := anObject ]

{ #category : 'accessing' }
CtikzSnippet >> description [ ^ description ]

{ #category : 'accessing' }
CtikzSnippet >> description: anObject [ description := anObject ]

{ #category : 'accessing' }
CtikzSnippet >> mustacheSource [ ^ mustacheSource ]

{ #category : 'accessing' }
CtikzSnippet >> mustacheSource: anObject [
	mustacheSource := anObject.
	checksum := nil
]

{ #category : 'accessing' }
CtikzSnippet >> parameterSchema [ ^ parameterSchema ifNil: [ parameterSchema := OrderedCollection new ] ]

{ #category : 'accessing' }
CtikzSnippet >> parameterSchema: anObject [ parameterSchema := anObject ]

{ #category : 'accessing' }
CtikzSnippet >> presetParameters [ ^ presetParameters ifNil: [ presetParameters := Dictionary new ] ]

{ #category : 'accessing' }
CtikzSnippet >> presetParameters: anObject [ presetParameters := anObject ]

{ #category : 'accessing' }
CtikzSnippet >> requires [ ^ requires ifNil: [ requires := Dictionary new ] ]

{ #category : 'accessing' }
CtikzSnippet >> requires: anObject [ requires := anObject ]

{ #category : 'accessing' }
CtikzSnippet >> provides [ ^ provides ifNil: [ provides := Dictionary new ] ]

{ #category : 'accessing' }
CtikzSnippet >> provides: anObject [ provides := anObject ]

{ #category : 'accessing' }
CtikzSnippet >> version [ ^ version ifNil: [ version := 1 ] ]

{ #category : 'accessing' }
CtikzSnippet >> version: anObject [ version := anObject ]

{ #category : 'accessing' }
CtikzSnippet >> checksum [
	^ checksum ifNil: [ checksum := self computeChecksum ]
]

{ #category : 'private' }
CtikzSnippet >> computeChecksum [
	| document |
	document := Dictionary new
		at: 'source' put: mustacheSource;
		at: 'schema' put: (self parameterSchema collect: [ :each | each asDictionary ]);
		at: 'presets' put: self presetParameters;
		yourself.
	^ (SHA256 hashMessage: (DsktCanonicalJson toString: document) asByteArray) hex
]

{ #category : 'converting' }
CtikzSnippet >> asDictionary [
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
