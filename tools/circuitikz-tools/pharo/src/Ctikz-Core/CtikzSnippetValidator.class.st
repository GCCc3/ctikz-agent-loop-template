"
I validate CircuitTikZ snippets at load time and at render time.

I reject missing metadata, unknown Mustache placeholders, target-specific
defaults, unknown components, preset overrides, enum violations, and unknown or
missing parameters. Duplicate ids are checked by CtikzSnippetCatalog.
"
Class {
	#name : 'CtikzSnippetValidator',
	#superclass : 'Object',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'private' }
CtikzSnippetValidator >> fail: aCode message: aMessage [
	DsktError code: aCode message: aMessage
]

{ #category : 'validation' }
CtikzSnippetValidator >> validate: aSnippet in: aCatalog [
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
	self validateDefaults: aSnippet.
	self validatePresets: aSnippet.
	self validateComponents: aSnippet.
	self validateRequires: aSnippet in: aCatalog.
	self validatePlaceholders: aSnippet.
	^ aSnippet
]

{ #category : 'private' }
CtikzSnippetValidator >> validateDefaults: aSnippet [
	| forbidden |
	forbidden := #( 'L_f' 'R_f' 'Z_g' 'GFM converter' 'grid' ).
	aSnippet parameterSchema do: [ :parameter |
		| default |
		default := parameter default.
		default ifNotNil: [
			(default isString and: [ forbidden includes: default ])
				ifTrue: [ self fail: 'snippet_validation_failed' message: 'Target-specific default ' , default printString , ' in ' , aSnippet id ].
			(default isNumber and: [ #( 'x' 'y' 'x0' 'y0' 'x1' 'y1' ) includes: parameter name ])
				ifTrue: [ self fail: 'snippet_validation_failed' message: 'Target-specific coordinate default for ' , parameter name , ' in ' , aSnippet id ].
			(parameter name = 'text' and: [ aSnippet id = 'label/generic' ])
				ifTrue: [ self fail: 'snippet_validation_failed' message: 'label/generic must not define a default text' ] ] ]
]

{ #category : 'private' }
CtikzSnippetValidator >> validatePresets: aSnippet [
	aSnippet presetParameters keysAndValuesDo: [ :key :value |
		| parameter |
		parameter := aSnippet parameterSchema
			detect: [ :each | each name = key ]
			ifNone: [ nil ].
		parameter ifNotNil: [
			(parameter default = value)
				ifFalse: [ self fail: 'snippet_validation_failed' message: 'Preset ' , key , ' overrides a caller parameter in ' , aSnippet id ] ] ]
]

{ #category : 'private' }
CtikzSnippetValidator >> validateComponents: aSnippet [
	aSnippet presetParameters at: 'component_options' ifPresent: [ :value |
		| key |
		key := (value substrings: ',') first trimBoth.
		key isEmpty ifFalse: [
			(CtikzComponentLookup default lookup: key) ifNil: [
				self fail: 'snippet_validation_failed' message: 'Unknown component key ' , key , ' in ' , aSnippet id ] ] ]
]

{ #category : 'validation' }
CtikzSnippetValidator >> validatePlaceholders: aSnippet [
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

{ #category : 'private' }
CtikzSnippetValidator >> validateSchema: aSnippet [
	| names |
	names := Set new.
	aSnippet parameterSchema do: [ :parameter |
		| name |
		name := parameter name.
		(name isNil or: [ name isEmpty ])
			ifTrue: [ self fail: 'snippet_validation_failed' message: 'Parameter name is empty in ' , aSnippet id ].
		(names includes: name)
			ifTrue: [ self fail: 'snippet_validation_failed' message: 'Duplicate parameter ' , name , ' in ' , aSnippet id ].
		names add: name.
		self validateParameter: parameter in: aSnippet ]
]

{ #category : 'private' }
CtikzSnippetValidator >> validateParameter: aParameter in: aSnippet [
	| type default |
	type := aParameter type.
	(#( 'string' 'number' 'boolean' 'array' ) includes: type)
		ifFalse: [ self fail: 'snippet_validation_failed' message: 'Unsupported parameter type ' , type printString , ' in ' , aSnippet id ].
	default := aParameter default.
	default ifNil: [ ^ self ].
	type = 'string' ifTrue: [ (default isString) ifFalse: [ self fail: 'snippet_validation_failed' message: 'Default for ' , aParameter name , ' must be a string' ] ].
	type = 'number' ifTrue: [ (default isNumber) ifFalse: [ self fail: 'snippet_validation_failed' message: 'Default for ' , aParameter name , ' must be a number' ] ].
	type = 'boolean' ifTrue: [ ((default = true) or: [ default = false ]) ifFalse: [ self fail: 'snippet_validation_failed' message: 'Default for ' , aParameter name , ' must be a boolean' ] ].
	type = 'array' ifTrue: [ (default isCollection) ifFalse: [ self fail: 'snippet_validation_failed' message: 'Default for ' , aParameter name , ' must be an array' ] ].
	aParameter enum ifNotNil: [ :enum |
		(enum includes: default)
			ifFalse: [ self fail: 'snippet_validation_failed' message: 'Default for ' , aParameter name , ' is not in its enum' ] ]
]

{ #category : 'private' }
CtikzSnippetValidator >> validateRequires: aSnippet in: aCatalog [
	aSnippet requires keysAndValuesDo: [ :key :value |
		(aCatalog snippetNamed: key) ifNil: [ self fail: 'snippet_validation_failed' message: 'Missing required snippet ' , key , ' in ' , aSnippet id ] ].
	aSnippet provides keysAndValuesDo: [ :key :value |
		key ifNil: [ self fail: 'snippet_validation_failed' message: 'Provided key is nil in ' , aSnippet id ] ]
]

{ #category : 'validation' }
CtikzSnippetValidator >> validateParameters: aSnippet parameters: aDictionary [
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
CtikzSnippetValidator >> validateValue: value type: type name: name [
	value ifNil: [ ^ self ].
	type = 'string' ifTrue: [ (value isString) ifFalse: [ DsktError code: 'invalid_parameter' message: 'Parameter ' , name , ' must be a string' ] ].
	type = 'number' ifTrue: [ (value isNumber) ifFalse: [ DsktError code: 'invalid_parameter' message: 'Parameter ' , name , ' must be a number' ] ].
	type = 'boolean' ifTrue: [ ((value = true) or: [ value = false ]) ifFalse: [ DsktError code: 'invalid_parameter' message: 'Parameter ' , name , ' must be a boolean' ] ].
	type = 'array' ifTrue: [ (value isCollection) ifFalse: [ DsktError code: 'invalid_parameter' message: 'Parameter ' , name , ' must be an array' ] ]
]

{ #category : 'private' }
CtikzSnippetValidator >> knownNamesFor: aSnippet [
	| names |
	names := Set new.
	aSnippet parameterSchema do: [ :each | names add: each name ].
	aSnippet presetParameters keysDo: [ :each | names add: each ].
	^ names
]

{ #category : 'private' }
CtikzSnippetValidator >> placeholderNamesIn: aSource [
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
