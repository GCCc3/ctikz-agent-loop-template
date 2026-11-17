"
I validate schemabloc snippets and render parameters.
"
Class {
	#name : 'SchemablocSnippetValidator',
	#superclass : 'Object',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'private' }
SchemablocSnippetValidator >> fail: aCode message: aMessage [
	DsktError code: aCode message: aMessage
]

{ #category : 'validation' }
SchemablocSnippetValidator >> validate: aSnippet in: aCatalog [
	| id |
	id := aSnippet id.
	(id isNil or: [ id isEmpty ])
		ifTrue: [ self fail: 'snippet_validation_failed' message: 'Snippet id is empty' ].
	(aSnippet title isNil or: [ aSnippet title isEmpty ])
		ifTrue: [ self fail: 'snippet_validation_failed' message: 'Snippet title is empty: ' , id ].
	(aSnippet kind isNil or: [ aSnippet kind isEmpty ])
		ifTrue: [ self fail: 'snippet_validation_failed' message: 'Snippet kind is empty: ' , id ].
	(aSnippet mustacheSource isNil or: [ aSnippet mustacheSource isEmpty ])
		ifTrue: [ self fail: 'snippet_validation_failed' message: 'Snippet source is empty: ' , id ].
	self validateSchema: aSnippet.
	self validatePlaceholders: aSnippet.
	^ aSnippet
]

{ #category : 'private' }
SchemablocSnippetValidator >> validateSchema: aSnippet [
	| names |
	names := Set new.
	aSnippet parameterSchema do: [ :parameter |
		| name type |
		name := parameter name.
		(name isNil or: [ name isEmpty ])
			ifTrue: [ self fail: 'snippet_validation_failed' message: 'Parameter name is empty in ' , aSnippet id ].
		(names includes: name)
			ifTrue: [ self fail: 'snippet_validation_failed' message: 'Duplicate parameter ' , name , ' in ' , aSnippet id ].
		names add: name.
		type := parameter type.
		(#( 'string' 'number' 'boolean' 'array' ) includes: type)
			ifFalse: [ self fail: 'snippet_validation_failed' message: 'Unsupported parameter type ' , type printString , ' in ' , aSnippet id ] ]
]

{ #category : 'validation' }
SchemablocSnippetValidator >> validatePlaceholders: aSnippet [
	| knownNames placeholders |
	knownNames := self knownNamesFor: aSnippet.
	placeholders := self placeholderNamesIn: aSnippet mustacheSource.
	placeholders do: [ :each |
		| name |
		name := each.
		(name notEmpty and: [ (#($# $/ $^ $! $>) includes: name first) ])
			ifTrue: [ name := name allButFirst ].
		(name isEmpty or: [ name = '.' ])
			ifFalse: [
				(knownNames includes: name)
					ifFalse: [ self fail: 'snippet_validation_failed' message: 'Unknown Mustache placeholder ' , name , ' in ' , aSnippet id ] ] ].
	^ aSnippet
]

{ #category : 'validation' }
SchemablocSnippetValidator >> validateParameters: aSnippet parameters: aDictionary [
	| schemaNames provided |
	schemaNames := Set new.
	aSnippet parameterSchema do: [ :each | schemaNames add: each name ].
	provided := aDictionary keys asSet.
	provided do: [ :key |
		(schemaNames includes: key asString)
			ifFalse: [ DsktError code: 'unknown_parameter' message: 'Unknown parameter ' , key asString , ' for snippet ' , aSnippet id ] ].
	aSnippet parameterSchema do: [ :parameter |
		| value |
		value := aDictionary at: parameter name ifAbsent: [ parameter default ].
		(value isNil and: [ parameter required ])
			ifTrue: [ DsktError code: 'missing_parameter' message: 'Missing required parameter ' , parameter name , ' for snippet ' , aSnippet id ].
		self validateValue: value type: parameter type name: parameter name.
		parameter enum ifNotNil: [ :enum |
			(value isNil or: [ enum includes: value ])
				ifFalse: [ DsktError code: 'invalid_parameter' message: 'Parameter ' , parameter name , ' is not in its enum' ] ] ].
	^ aSnippet
]

{ #category : 'private' }
SchemablocSnippetValidator >> validateValue: value type: type name: name [
	value ifNil: [ ^ self ].
	type = 'string' ifTrue: [ (value isString) ifFalse: [ DsktError code: 'invalid_parameter' message: 'Parameter ' , name , ' must be a string' ] ].
	type = 'number' ifTrue: [ (value isNumber) ifFalse: [ DsktError code: 'invalid_parameter' message: 'Parameter ' , name , ' must be a number' ] ].
	type = 'boolean' ifTrue: [ ((value = true) or: [ value = false ]) ifFalse: [ DsktError code: 'invalid_parameter' message: 'Parameter ' , name , ' must be a boolean' ] ].
	type = 'array' ifTrue: [ (value isCollection) ifFalse: [ DsktError code: 'invalid_parameter' message: 'Parameter ' , name , ' must be an array' ] ]
]

{ #category : 'private' }
SchemablocSnippetValidator >> knownNamesFor: aSnippet [
	| names |
	names := Set new.
	aSnippet parameterSchema do: [ :each | names add: each name ].
	aSnippet presetParameters keysDo: [ :each | names add: each ].
	^ names
]

{ #category : 'private' }
SchemablocSnippetValidator >> placeholderNamesIn: aSource [
	| names index start end |
	names := OrderedCollection new.
	index := 1.
	[ index <= aSource size ] whileTrue: [
		start := aSource indexOf: ${ startingAt: index.
		start = 0 ifTrue: [ ^ names ].
		((start + 1) <= aSource size and: [ (aSource at: start + 1) = ${ ])
			ifFalse: [ index := start + 1 ]
			ifTrue: [
				end := aSource indexOf: $} startingAt: start + 2.
				end = 0 ifTrue: [ ^ names ].
				((end + 1) <= aSource size and: [ (aSource at: end + 1) = $} ])
					ifFalse: [ index := end + 1 ]
					ifTrue: [
						names add: (aSource copyFrom: start + 2 to: end - 1) trimBoth.
						index := end + 2 ] ] ].
	^ names
]
