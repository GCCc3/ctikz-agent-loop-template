"
I render one CircuitTikZ snippet with Mustache.

I merge preset parameters with caller parameters, validate the merged parameter
map against the snippet schema, render the Mustache source, and return the
rendered text with warnings and the snippet checksum. I never accept a
caller-supplied template.
"
Class {
	#name : 'CtikzSnippetRenderer',
	#superclass : 'Object',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'rendering' }
CtikzSnippetRenderer >> render: aSnippet parameters: aDictionary [
	| merged validator viewModel source |
	validator := CtikzSnippetValidator new.
	validator validatePlaceholders: aSnippet.
	validator validateParameters: aSnippet parameters: aDictionary.
	merged := Dictionary new.
	aSnippet parameterSchema do: [ :parameter |
		parameter default ifNotNil: [ merged at: parameter name put: parameter default ] ].
	merged addAll: aSnippet presetParameters.
	aDictionary keysAndValuesDo: [ :key :value | merged at: key put: value ].
	viewModel := self viewModelFor: merged.
	source := [ (MustacheTemplate on: aSnippet mustacheSource) value: viewModel ]
		on: Error
		do: [ :error | DsktError code: 'template_render_failed' message: 'Mustache rendering failed: ' , error messageText ].
	source := String streamContents: [ :stream |
		source lines
			do: [ :line | stream nextPutAll: line ]
			separatedBy: [ stream nextPut: Character lf ] ].
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

{ #category : 'private' }
CtikzSnippetRenderer >> viewModelFor: aDictionary [
	| viewModel |
	viewModel := Dictionary new.
	aDictionary keysAndValuesDo: [ :key :value | viewModel at: key put: value ].
	^ viewModel
]
