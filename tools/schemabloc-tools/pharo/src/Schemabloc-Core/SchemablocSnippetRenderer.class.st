"
I render one schemabloc snippet with Mustache.
"
Class {
	#name : 'SchemablocSnippetRenderer',
	#superclass : 'Object',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'rendering' }
SchemablocSnippetRenderer >> render: aSnippet parameters: aDictionary [
	| merged source |
	(aDictionary isKindOf: Dictionary)
		ifFalse: [ DsktError code: 'invalid_request' message: 'parameters must be an object' ].
	merged := Dictionary new.
	aSnippet parameterSchema do: [ :parameter |
		parameter default ifNotNil: [ merged at: parameter name put: parameter default ] ].
	merged addAll: aSnippet presetParameters.
	aDictionary keysAndValuesDo: [ :key :value | merged at: key put: value ].
	aSnippet parameterSchema do: [ :parameter |
		(parameter required and: [ (merged includesKey: parameter name) not ])
			ifTrue: [ DsktError code: 'missing_parameter' message: ('Missing required parameter: ', parameter name) ] ].
	source := [ (MustacheTemplate on: aSnippet mustacheSource) value: merged ]
		on: Error
		do: [ :error | DsktError code: 'template_render_failed' message: 'Mustache rendering failed: ' , error messageText ].
	source := String streamContents: [ :stream |
		source lines do: [ :line | stream nextPutAll: line ] separatedBy: [ stream nextPut: Character lf ] ].
	((source includesSubstring: '{{') or: [ source includesSubstring: '}}' ])
		ifTrue: [ DsktError code: 'template_render_failed' message: 'Unresolved Mustache placeholder in ' , aSnippet id ].
	^ Dictionary new
		at: 'snippet_id' put: aSnippet id;
		at: 'version' put: aSnippet version;
		at: 'parameters' put: merged;
		at: 'source' put: source;
		at: 'warnings' put: #();
		at: 'checksum' put: aSnippet checksum;
		yourself
]
