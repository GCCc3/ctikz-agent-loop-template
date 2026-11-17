"
I scan schemabloc source into a SchemablocSourceModel.
"
Class {
	#name : 'SchemablocSourceScanner',
	#superclass : 'Object',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'scanning' }
SchemablocSourceScanner >> scan: aSource [
	| model active |
	model := SchemablocSourceModel new.
	model source: aSource.
	model sourceSha256: ((SHA256 hashMessage: aSource utf8Encoded) hex).
	active := self maskVerbatim: (self stripComments: (self normalizeLineEndings: aSource)).
	model packages: (self packagesIn: active).
	model tikzPictures: (self count: '\begin{tikzpicture}' in: active).
	model environments: (self environmentsIn: active).
	model braceBalance: (self braceBalanceIn: active).
	model braceErrors: (self braceErrorsIn: active).
	model manualRectangles: (self manualRectanglesIn: active).
	self processMacros: (self macrosIn: active) into: model.
	^ model
]

{ #category : 'private' }
SchemablocSourceScanner >> normalizeLineEndings: aSource [
	^ (aSource copyReplaceAll: (String with: Character cr with: Character lf) with: (String with: Character lf))
		copyReplaceAll: (String with: Character cr) with: (String with: Character lf)
]

{ #category : 'private' }
SchemablocSourceScanner >> stripComments: aSource [
	| output index inComment |
	output := String new: aSource size withAll: $ .
	index := 1.
	inComment := false.
	[ index <= aSource size ] whileTrue: [
		| char |
		char := aSource at: index.
		inComment
			ifTrue: [ char = Character lf ifTrue: [ inComment := false. output at: index put: char ] ]
			ifFalse: [
				char = $\ ifTrue: [
					output at: index put: char.
					(index < aSource size and: [ (aSource at: index + 1) = $% ])
						ifTrue: [ output at: index + 1 put: $%. index := index + 1 ] ]
				ifFalse: [
					char = $%
						ifTrue: [ inComment := true ]
						ifFalse: [ output at: index put: char ] ] ].
		index := index + 1 ].
	^ output
]

{ #category : 'private' }
SchemablocSourceScanner >> maskVerbatim: aSource [
	| output index start end |
	output := aSource copy.
	index := 1.
	[ index <= aSource size ] whileTrue: [
		start := aSource indexOfSubCollection: '\begin{verbatim}' startingAt: index.
		start = 0 ifTrue: [
			start := aSource indexOfSubCollection: '\begin{lstlisting}' startingAt: index ].
		start = 0 ifTrue: [ ^ output ].
		end := aSource indexOfSubCollection: '\end{verbatim}' startingAt: start.
		end = 0 ifTrue: [ end := aSource indexOfSubCollection: '\end{lstlisting}' startingAt: start ].
		end = 0 ifTrue: [ end := aSource size ].
		start to: end do: [ :i |
			(output at: i) = Character lf ifFalse: [ output at: i put: $  ] ].
		index := end + 1 ].
	^ output
]

{ #category : 'private' }
SchemablocSourceScanner >> packagesIn: aSource [
	| packages index |
	packages := OrderedCollection new.
	index := 1.
	[ (index := aSource indexOfSubCollection: '\usepackage' startingAt: index) = 0 ] whileFalse: [
		| open close cursor |
		cursor := self skipWhitespace: index + '\usepackage' size in: aSource.
		(cursor <= aSource size and: [ (aSource at: cursor) = $[ ])
			ifTrue: [ cursor := (aSource indexOf: $] startingAt: cursor) + 1 ].
		cursor := self skipWhitespace: cursor in: aSource.
		open := cursor.
		(open <= aSource size and: [ (aSource at: open) = ${ ])
			ifFalse: [ index := index + '\usepackage' size ]
			ifTrue: [
				close := aSource indexOf: $} startingAt: open.
				close = 0 ifTrue: [ ^ packages ].
				((aSource copyFrom: open + 1 to: close - 1) substrings: ',') do: [ :each |
					| trimmed |
					trimmed := each trimBoth.
					trimmed isEmpty ifFalse: [ packages add: trimmed ] ].
				index := close + 1 ] ].
	^ packages
]

{ #category : 'private' }
SchemablocSourceScanner >> environmentsIn: aSource [
	| environments index |
	environments := OrderedCollection new.
	index := 1.
	[ index <= aSource size ] whileTrue: [
		| beginIndex endIndex next kind open close |
		beginIndex := aSource indexOfSubCollection: '\begin{' startingAt: index.
		endIndex := aSource indexOfSubCollection: '\end{' startingAt: index.
		beginIndex = 0 ifTrue: [ beginIndex := aSource size + 1 ].
		endIndex = 0 ifTrue: [ endIndex := aSource size + 1 ].
		next := beginIndex min: endIndex.
		next > aSource size ifTrue: [ ^ environments ].
		kind := next = beginIndex ifTrue: [ 'begin' ] ifFalse: [ 'end' ].
		open := next + (kind = 'begin' ifTrue: [ 7 ] ifFalse: [ 5 ]).
		close := aSource indexOf: $} startingAt: open.
		close = 0 ifTrue: [ ^ environments ].
		environments add: (Dictionary new
			at: 'name' put: (aSource copyFrom: open to: close - 1) trimBoth;
			at: 'kind' put: kind;
			at: 'line' put: (self lineFor: next in: aSource);
			yourself).
		index := close + 1 ].
	^ environments
]

{ #category : 'private' }
SchemablocSourceScanner >> braceBalanceIn: aSource [
	| balance index |
	balance := 0.
	index := 1.
	[ index <= aSource size ] whileTrue: [
		| char |
		char := aSource at: index.
		(char = $\ and: [ index < aSource size and: [ (aSource at: index + 1) = ${ or: [ (aSource at: index + 1) = $} ] ] ])
			ifTrue: [ index := index + 2 ]
			ifFalse: [
				char = ${ ifTrue: [ balance := balance + 1 ].
				char = $} ifTrue: [ balance := balance - 1 ].
				index := index + 1 ] ].
	^ balance
]

{ #category : 'private' }
SchemablocSourceScanner >> braceErrorsIn: aSource [
	| errors balance index |
	errors := OrderedCollection new.
	balance := 0.
	index := 1.
	[ index <= aSource size ] whileTrue: [
		| char |
		char := aSource at: index.
		(char = $\ and: [ index < aSource size and: [ (aSource at: index + 1) = ${ or: [ (aSource at: index + 1) = $} ] ] ])
			ifTrue: [ index := index + 2 ]
			ifFalse: [
				char = ${ ifTrue: [ balance := balance + 1 ].
				char = $} ifTrue: [
					balance := balance - 1.
					balance < 0 ifTrue: [ errors add: (Dictionary new at: 'line' put: (self lineFor: index in: aSource); at: 'message' put: 'Unbalanced closing brace'; yourself) ] ].
				index := index + 1 ] ].
	^ errors asArray
]

{ #category : 'private' }
SchemablocSourceScanner >> manualRectanglesIn: aSource [
	| count |
	count := 0.
	aSource lines do: [ :line |
		((line includesSubstring: '\draw') and: [ line includesSubstring: 'rectangle' ]) ifTrue: [ count := count + 1 ] ].
	^ count
]

{ #category : 'private' }
SchemablocSourceScanner >> count: aString in: aSource [
	| count index |
	count := 0.
	index := 1.
	[ (index := aSource indexOfSubCollection: aString startingAt: index) = 0 ] whileFalse: [
		count := count + 1.
		index := index + aString size ].
	^ count
]

{ #category : 'private' }
SchemablocSourceScanner >> macrosIn: aSource [
	| macros index |
	macros := OrderedCollection new.
	index := 1.
	[ index <= aSource size ] whileTrue: [
		| start cursor name optional args |
		start := aSource indexOf: $\ startingAt: index.
		start = 0 ifTrue: [ ^ macros ].
		((start + 2) <= aSource size and: [ (aSource at: start + 1) = $s and: [ (aSource at: start + 2) = $b ] ])
			ifFalse: [ index := start + 1 ]
			ifTrue: [
				cursor := start + 1.
				[ cursor <= aSource size and: [ (aSource at: cursor) isLetter ] ] whileTrue: [ cursor := cursor + 1 ].
				name := aSource copyFrom: start + 1 to: cursor - 1.
				(cursor <= aSource size and: [ (aSource at: cursor) = $* ])
					ifTrue: [ name := name , '*'. cursor := cursor + 1 ].
				cursor := self skipWhitespace: cursor in: aSource.
				optional := nil.
				(cursor <= aSource size and: [ (aSource at: cursor) = $[ ])
					ifTrue: [
						| read |
						read := self readOptionalFrom: cursor in: aSource.
						optional := read at: 1.
						cursor := read at: 2 ].
				args := OrderedCollection new.
				cursor := self skipWhitespace: cursor in: aSource.
				[ cursor <= aSource size and: [ (aSource at: cursor) = ${ ] ] whileTrue: [
					| read |
					read := self readBracedFrom: cursor in: aSource.
					args add: (read at: 1).
					cursor := self skipWhitespace: (read at: 2) in: aSource ].
				macros add: (Dictionary new
					at: 'name' put: name;
					at: 'optional' put: optional;
					at: 'args' put: args asArray;
					at: 'line' put: (self lineFor: start in: aSource);
					yourself).
				index := cursor max: start + 3 ] ].
	^ macros
]

{ #category : 'private' }
SchemablocSourceScanner >> readOptionalFrom: anIndex in: aSource [
	| cursor depth |
	cursor := anIndex + 1.
	depth := 1.
	[ cursor <= aSource size ] whileTrue: [
		| char |
		char := aSource at: cursor.
		char = $[ ifTrue: [ depth := depth + 1 ].
		char = $] ifTrue: [
			depth := depth - 1.
			depth = 0 ifTrue: [ ^ { (aSource copyFrom: anIndex + 1 to: cursor - 1) trimBoth . cursor + 1 } ] ].
		cursor := cursor + 1 ].
	^ { nil . aSource size + 1 }
]

{ #category : 'private' }
SchemablocSourceScanner >> readBracedFrom: anIndex in: aSource [
	| cursor depth |
	cursor := anIndex + 1.
	depth := 1.
	[ cursor <= aSource size ] whileTrue: [
		| char |
		char := aSource at: cursor.
		char = ${ ifTrue: [ depth := depth + 1 ].
		char = $} ifTrue: [
			depth := depth - 1.
			depth = 0 ifTrue: [ ^ { (aSource copyFrom: anIndex + 1 to: cursor - 1) . cursor + 1 } ] ].
		cursor := cursor + 1 ].
	^ { nil . aSource size + 1 }
]

{ #category : 'private' }
SchemablocSourceScanner >> skipWhitespace: anIndex in: aSource [
	| cursor |
	cursor := anIndex.
	[ cursor <= aSource size and: [ (aSource at: cursor) isSeparator ] ] whileTrue: [ cursor := cursor + 1 ].
	^ cursor
]

{ #category : 'private' }
SchemablocSourceScanner >> processMacros: macros into: model [
	macros do: [ :macro |
		| name args line optional base |
		name := macro at: 'name'.
		base := name.
		(base notEmpty and: [ base last = $* ]) ifTrue: [ base := base copyFrom: 1 to: base size - 1 ].
		args := macro at: 'args'.
		line := macro at: 'line'.
		optional := macro at: 'optional'.
		(self knownMacroNames includes: base)
			ifFalse: [ model unknownMacros add: (Dictionary new at: 'macro' put: name; at: 'line' put: line; yourself) ]
			ifTrue: [
				(base = 'sbEntree') ifTrue: [ self addDefinition: (args at: 1) macro: base kind: 'entry' content: nil line: line model: model ].
				(base = 'sbSortie') ifTrue: [
					self addDefinition: (args at: 1) macro: base kind: 'exit' content: nil line: line model: model.
					self addReference: (args at: 2) line: line model: model ].
				(#('sbBloc' 'sbBlocL' 'sbBlocr' 'sbBlocrL') includes: base) ifTrue: [
					self addDefinition: (args at: 1) macro: base kind: 'block' content: (args at: 2) line: line model: model.
					self addReference: (args at: 3) line: line model: model.
					model labels add: (args at: 2) ].
				(base = 'sbBlocSeul') ifTrue: [ model labels add: (args at: 2) ].
				(#('sbComp' 'sbComph' 'sbSumb' 'sbSumh' 'sbCompSum') includes: base) ifTrue: [
					self addDefinition: (args at: 1) macro: base kind: 'comparator' content: nil line: line model: model.
					self addReference: (args at: 2) line: line model: model ].
				(#('sbDecaleNoeudx' 'sbDecaleNoeudy') includes: base) ifTrue: [
					self addDefinition: (args at: 2) macro: base kind: 'coordinate' content: nil line: line model: model.
					self addReference: (args at: 1) line: line model: model ].
				(base = 'sbRelier') ifTrue: [
					self addLink: name from: (args at: 1) to: (args at: 2) label: (optional ifNil: [ '' ]) line: line model: model.
					self addReference: (args at: 1) line: line model: model.
					self addReference: (args at: 2) line: line model: model.
					optional ifNotNil: [ :value | value isEmpty ifFalse: [ model labels add: value ] ] ].
				(base = 'sbRenvoi') ifTrue: [
					self addLink: name from: (args at: 2) to: (args at: 2) label: (args at: 3 ifAbsent: [ '' ]) line: line model: model.
					self addReference: (args at: 2) line: line model: model.
					self addLinkReference: (args at: 1) line: line model: model.
					(args at: 3 ifAbsent: [ '' ]) isEmpty ifFalse: [ model labels add: (args at: 3) ] ].
				(base = 'sbRelierxy') ifTrue: [
					self addLink: name from: (args at: 1) to: (args at: 2) label: (optional ifNil: [ '' ]) line: line model: model.
					self addReference: (args at: 1) line: line model: model.
					self addReference: (args at: 2) line: line model: model.
					optional ifNotNil: [ :value | value isEmpty ifFalse: [ model labels add: value ] ] ].
				(base = 'sbRelieryx') ifTrue: [
					self addLink: name from: (args at: 1) to: (args at: 2) label: '' line: line model: model.
					self addReference: (args at: 2) line: line model: model.
					self addLinkReference: (args at: 1) line: line model: model ].
				(base = 'sbNomLien') ifTrue: [
					model definedLinks add: (args at: 1).
					model labels add: (args at: 2) ] ] ].
	^ model
]

{ #category : 'private' }
SchemablocSourceScanner >> addDefinition: aName macro: aMacro kind: aKind content: content line: line model: model [
	model definitions add: (Dictionary new
		at: 'name' put: aName;
		at: 'macro' put: aMacro;
		at: 'kind' put: aKind;
		at: 'content' put: content;
		at: 'line' put: line;
		yourself)
]

{ #category : 'private' }
SchemablocSourceScanner >> addReference: aName line: line model: model [
	(model definitions anySatisfy: [ :each | (each at: 'name') = aName ]) ifTrue: [ ^ self ].
	model references add: (Dictionary new at: 'name' put: aName; at: 'line' put: line; yourself)
]

{ #category : 'private' }
SchemablocSourceScanner >> addLinkReference: aName line: line model: model [
	(model linkReferences anySatisfy: [ :each | (each at: 'name') = aName ]) ifTrue: [ ^ self ].
	model linkReferences add: (Dictionary new at: 'name' put: aName; at: 'line' put: line; yourself)
]

{ #category : 'private' }
SchemablocSourceScanner >> addLink: aMacro from: from to: to label: label line: line model: model [
	model links add: (Dictionary new
		at: 'macro' put: aMacro;
		at: 'from' put: from;
		at: 'to' put: to;
		at: 'label' put: (label ifNil: [ '' ]);
		at: 'line' put: line;
		yourself)
]

{ #category : 'private' }
SchemablocSourceScanner >> knownMacroNames [
	^ #('sbEntree' 'sbSortie' 'sbBloc' 'sbBlocL' 'sbBlocr' 'sbBlocrL' 'sbBlocSeul' 'sbComp' 'sbComph' 'sbSumb' 'sbSumh' 'sbCompSum' 'sbRelier' 'sbRenvoi' 'sbRelierxy' 'sbRelieryx' 'sbDecaleNoeudx' 'sbDecaleNoeudy' 'sbNomLien' 'sbStyleBloc' 'sbStyleBlocDefaut' 'sbStyleLien' 'sbStyleLienDefaut' 'sbStyleSum')
]

{ #category : 'private' }
SchemablocSourceScanner >> lineFor: anIndex in: aSource [
	| line |
	line := 1.
	1 to: (anIndex min: aSource size) do: [ :index |
		(aSource at: index) = Character lf ifTrue: [ line := line + 1 ] ].
	^ line
]
