"
I scan CircuitTikZ source and produce a CtikzSourceModel.

I am comment-aware and TeX-light: I strip comments, track brace depth and
environments, and extract document class, packages, libraries, coordinates,
components, labels, and forbidden tokens. I am not a full TeX engine and I do not
expand macros.
"
Class {
	#name : 'CtikzSourceScanner',
	#superclass : 'Object',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'scanning' }
CtikzSourceScanner >> scan: aSource [
	| model normalized stripped unsupported |
	model := CtikzSourceModel new.
	model source: aSource.
	model sourceSha256: ((SHA256 hashMessage: aSource utf8Encoded) hex).
	normalized := self normalizeLineEndings: aSource.
	model lineMap: (self buildLineMap: normalized).
	unsupported := OrderedCollection new.
	stripped := self stripComments: (self maskVerbatim: normalized into: unsupported).
	model documentClass: (self documentClassIn: stripped).
	model documentClassOptions: (self optionsFor: 'documentclass' in: stripped).
	model packages: (self packagesIn: stripped).
	model libraries: (self librariesIn: stripped).
	model environments: (self environmentsIn: stripped).
	model braceBalance: (self braceBalanceIn: stripped).
	model braceErrors: (self braceErrorsIn: stripped).
	model definedCoordinates: (self coordinatesIn: stripped).
	model coordinateReferences: (self coordinateReferencesIn: stripped).
	model components: (self componentsIn: stripped).
	model labels: (self labelsIn: stripped).
	model forbiddenMatches: (self forbiddenMatchesIn: stripped).
	model unsupported: unsupported asArray.
	model activeSource: stripped.
	^ model
]

{ #category : 'private' }
CtikzSourceScanner >> normalizeLineEndings: aSource [
	| crlf cr |
	crlf := String with: Character cr with: Character lf.
	cr := String with: Character cr.
	^ (aSource copyReplaceAll: crlf with: (String with: Character lf))
		copyReplaceAll: cr with: (String with: Character lf)
]

{ #category : 'private' }
CtikzSourceScanner >> stripComments: aSource [
	| output index inComment |
	output := String new: aSource size withAll: $ .
	index := 1.
	inComment := false.
	[ index <= aSource size ] whileTrue: [
		| char |
		char := aSource at: index.
		inComment
			ifTrue: [
				char = Character lf
					ifTrue: [ inComment := false. output at: index put: char ] ]
			ifFalse: [
				char = $\
					ifTrue: [
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
CtikzSourceScanner >> maskVerbatim: aSource into: aCollection [
	| output index |
	output := aSource copy.
	index := 1.
	[ index <= aSource size ] whileTrue: [
		| begin kind marker endStart endMarker candidate |
		begin := aSource indexOfSubCollection: '\begin{verbatim}' startingAt: index.
		kind := 'verbatim'.
		marker := '\begin{verbatim}'.
		candidate := aSource indexOfSubCollection: '\begin{lstlisting}' startingAt: index.
		(candidate > 0 and: [ begin = 0 or: [ candidate < begin ] ]) ifTrue: [
			begin := candidate.
			kind := 'lstlisting'.
			marker := '\begin{lstlisting}' ].
		begin = 0 ifTrue: [ ^ self maskInlineVerbs: output into: aCollection ].
		endMarker := '\end{' , kind , '}'.
		endStart := aSource indexOfSubCollection: endMarker startingAt: begin + marker size.
		endStart = 0 ifTrue: [
			aCollection add: (Dictionary new
				at: 'kind' put: kind;
				at: 'line' put: (self lineFor: begin in: aSource);
				yourself).
			^ self maskInlineVerbs: output into: aCollection ].
		self maskRange: begin + marker size to: endStart - 1 in: output.
		aCollection add: (Dictionary new
			at: 'kind' put: kind;
			at: 'line' put: (self lineFor: begin in: aSource);
			yourself).
		index := endStart + endMarker size ].
	^ self maskInlineVerbs: output into: aCollection
]

{ #category : 'private' }
CtikzSourceScanner >> maskInlineVerbs: aSource into: aCollection [
	| index |
	index := 1.
	[ (index := aSource indexOfSubCollection: '\verb' startingAt: index) = 0 ] whileFalse: [
		| start delimiter end |
		start := index + 5.
		(start <= aSource size and: [ (aSource at: start) = $* ])
			ifTrue: [ start := start + 1 ].
		start > aSource size ifTrue: [ ^ aSource ].
		delimiter := aSource at: start.
		(delimiter isLetter or: [ delimiter isDigit ])
			ifTrue: [ index := start + 1 ]
			ifFalse: [
				end := aSource indexOf: delimiter startingAt: start + 1.
				end = 0 ifTrue: [ ^ aSource ].
				self maskRange: start + 1 to: end - 1 in: aSource.
				aCollection add: (Dictionary new
					at: 'kind' put: 'verb';
					at: 'line' put: (self lineFor: index in: aSource);
					yourself).
				index := end + 1 ] ].
	^ aSource
]

{ #category : 'private' }
CtikzSourceScanner >> maskRange: start to: end in: aString [
	start to: end do: [ :index |
		(aString at: index) = Character lf ifFalse: [ aString at: index put: $  ] ]
]

{ #category : 'private' }
CtikzSourceScanner >> buildLineMap: aSource [
	| map |
	map := OrderedCollection new.
	map add: 1.
	aSource withIndexDo: [ :char :index |
		char = Character lf ifTrue: [ map add: index + 1 ] ].
	^ map asArray
]

{ #category : 'private' }
CtikzSourceScanner >> documentClassIn: aSource [
	| index open close |
	index := aSource indexOfSubCollection: '\documentclass' startingAt: 1.
	index = 0 ifTrue: [ ^ nil ].
	open := self openBraceAfterCommandAt: index size: 14 in: aSource.
	open = 0 ifTrue: [ ^ nil ].
	close := aSource indexOf: $} startingAt: open.
	close = 0 ifTrue: [ ^ nil ].
	^ aSource copyFrom: open + 1 to: close - 1
]

{ #category : 'private' }
CtikzSourceScanner >> openBraceAfterCommandAt: anIndex size: aSize in: aSource [
	| cursor |
	cursor := self skipOptionsFrom: anIndex + aSize in: aSource.
	[ cursor <= aSource size and: [ (aSource at: cursor) ~= ${ ] ] whileTrue: [
		cursor := cursor + 1 ].
	^ cursor <= aSource size ifTrue: [ cursor ] ifFalse: [ 0 ]
]

{ #category : 'private' }
CtikzSourceScanner >> skipWhitespaceFrom: anIndex in: aSource [
	| cursor |
	cursor := anIndex.
	[ cursor <= aSource size and: [ (aSource at: cursor) isSeparator ] ] whileTrue: [
		cursor := cursor + 1 ].
	^ cursor
]

{ #category : 'private' }
CtikzSourceScanner >> skipOptionsFrom: anIndex in: aSource [
	| cursor close |
	cursor := self skipWhitespaceFrom: anIndex in: aSource.
	(cursor <= aSource size and: [ (aSource at: cursor) = $[ ])
		ifFalse: [ ^ cursor ].
	close := aSource indexOf: $] startingAt: cursor.
	^ close = 0
		ifTrue: [ aSource size + 1 ]
		ifFalse: [ close + 1 ]
]

{ #category : 'private' }
CtikzSourceScanner >> optionsFor: aCommand in: aSource [
	| index after close |
	index := aSource indexOfSubCollection: '\' , aCommand startingAt: 1.
	index = 0 ifTrue: [ ^ OrderedCollection new ].
	after := self skipWhitespaceFrom: index + 1 + aCommand size in: aSource.
	(after <= aSource size and: [ (aSource at: after) = $[ ])
		ifFalse: [ ^ OrderedCollection new ].
	close := aSource indexOf: $] startingAt: after.
	close = 0 ifTrue: [ ^ OrderedCollection new ].
	^ (aSource copyFrom: after + 1 to: close - 1) substrings: ','
]

{ #category : 'private' }
CtikzSourceScanner >> packagesIn: aSource [
	| packages index |
	packages := OrderedCollection new.
	index := 1.
	[ (index := aSource indexOfSubCollection: '\usepackage' startingAt: index) = 0 ] whileFalse: [
		| open close names |
		open := self openBraceAfterCommandAt: index size: 11 in: aSource.
		open = 0 ifTrue: [ ^ packages ].
		close := aSource indexOf: $} startingAt: open.
		close = 0 ifTrue: [ ^ packages ].
		names := (aSource copyFrom: open + 1 to: close - 1) substrings: ','.
		names do: [ :each |
			| trimmed |
			trimmed := each trimBoth.
			trimmed isEmpty ifFalse: [ packages add: trimmed ] ].
		index := close + 1 ].
	^ packages
]

{ #category : 'private' }
CtikzSourceScanner >> librariesIn: aSource [
	| libraries index |
	libraries := OrderedCollection new.
	index := 1.
	[ (index := aSource indexOfSubCollection: '\usetikzlibrary' startingAt: index) = 0 ] whileFalse: [
		| open close |
		open := self openBraceAfterCommandAt: index size: 15 in: aSource.
		open = 0 ifTrue: [ ^ libraries ].
		close := aSource indexOf: $} startingAt: open.
		close = 0 ifTrue: [ ^ libraries ].
		libraries add: (aSource copyFrom: open + 1 to: close - 1) trimBoth.
		index := close + 1 ].
	^ libraries
]

{ #category : 'private' }
CtikzSourceScanner >> environmentsIn: aSource [
	| environments index beginIndex endIndex |
	environments := OrderedCollection new.
	index := 1.
	[ index <= aSource size ] whileTrue: [
		| next kind open close |
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
CtikzSourceScanner >> braceBalanceIn: aSource [
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
CtikzSourceScanner >> braceErrorsIn: aSource [
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
					balance < 0 ifTrue: [
						errors add: (Dictionary new
							at: 'line' put: (self lineFor: index in: aSource);
							at: 'message' put: 'Unbalanced closing brace';
							yourself) ] ].
				index := index + 1 ] ].
	^ errors asArray
]

{ #category : 'private' }
CtikzSourceScanner >> coordinatesIn: aSource [
	| coordinates index |
	coordinates := OrderedCollection new.
	index := 1.
	[ (index := aSource indexOfSubCollection: '\coordinate' startingAt: index) = 0 ] whileFalse: [
		| cursor open close |
		cursor := self skipOptionsFrom: index + 11 in: aSource.
		[ cursor <= aSource size and: [ (aSource at: cursor) ~= $( ] ] whileTrue: [
			cursor := cursor + 1 ].
		cursor > aSource size ifTrue: [ ^ coordinates ].
		open := cursor.
		close := aSource indexOf: $) startingAt: open.
		close = 0 ifTrue: [ ^ coordinates ].
		coordinates add: (Dictionary new
			at: 'name' put: (aSource copyFrom: open + 1 to: close - 1) trimBoth;
			at: 'line' put: (self lineFor: index in: aSource);
			yourself).
		index := close + 1 ].
	^ coordinates asArray
]

{ #category : 'private' }
CtikzSourceScanner >> coordinateReferencesIn: aSource [
	| references index |
	references := OrderedCollection new.
	index := 1.
	[ (index := aSource indexOf: $( startingAt: index) = 0 ] whileFalse: [
		| close |
		close := aSource indexOf: $) startingAt: index.
		close = 0 ifTrue: [ ^ references ].
		references add: (Dictionary new
			at: 'name' put: (aSource copyFrom: index + 1 to: close - 1) trimBoth;
			at: 'line' put: (self lineFor: index in: aSource);
			yourself).
		index := close + 1 ].
	index := 1.
	[ (index := aSource indexOfSubCollection: '++' startingAt: index) = 0 ] whileFalse: [
		references add: (Dictionary new
			at: 'name' put: '++';
			at: 'line' put: (self lineFor: index in: aSource);
			yourself).
		index := index + 2 ].
	index := 1.
	[ (index := aSource indexOf: $+ startingAt: index) = 0 ] whileFalse: [
		| previous next cursor |
		previous := index > 1 ifTrue: [ aSource at: index - 1 ] ifFalse: [ nil ].
		next := index < aSource size ifTrue: [ aSource at: index + 1 ] ifFalse: [ nil ].
		(previous = $+ or: [ next = $+ ])
			ifFalse: [
				cursor := index + 1.
				[ cursor <= aSource size and: [ (aSource at: cursor) isSeparator ] ] whileTrue: [
					cursor := cursor + 1 ].
				(cursor <= aSource size and: [ (aSource at: cursor) = $( ])
					ifTrue: [
						references add: (Dictionary new
							at: 'name' put: '+';
							at: 'line' put: (self lineFor: index in: aSource);
							yourself) ] ].
		index := index + 1 ].
	^ references asArray
]

{ #category : 'private' }
CtikzSourceScanner >> componentsIn: aSource [
	| components index |
	components := OrderedCollection new.
	index := 1.
	[ (index := aSource indexOfSubCollection: 'to[' startingAt: index) = 0 ] whileFalse: [
		| end |
		end := aSource indexOf: $] startingAt: index.
		end = 0 ifTrue: [ ^ components ].
		components add: (Dictionary new
			at: 'options' put: (aSource copyFrom: index + 3 to: end - 1) trimBoth;
			at: 'line' put: (self lineFor: index in: aSource);
			yourself).
		index := end + 1 ].
	^ components asArray
]

{ #category : 'private' }
CtikzSourceScanner >> firstTextBraceAfter: anIndex in: aSource [
	| index |
	index := anIndex.
	[ index <= aSource size ] whileTrue: [
		| char |
		char := aSource at: index.
		char = ${ ifTrue: [ ^ index ].
		(char = $[ or: [ char = $( ])
			ifTrue: [
				index := self matchingCloseFor: char at: index in: aSource.
				index = 0 ifTrue: [ ^ 0 ].
				index := index + 1 ]
			ifFalse: [ index := index + 1 ] ].
	^ 0
]

{ #category : 'private' }
CtikzSourceScanner >> matchingBraceCloseFrom: anIndex in: aSource [
	| depth |
	depth := 0.
	anIndex to: aSource size do: [ :index |
		| char |
		char := aSource at: index.
		char = ${ ifTrue: [ depth := depth + 1 ].
		char = $} ifTrue: [
			depth := depth - 1.
			depth = 0 ifTrue: [ ^ index ] ] ].
	^ 0
]

{ #category : 'private' }
CtikzSourceScanner >> matchingCloseFor: anOpenChar at: anIndex in: aSource [
	| depth closeChar |
	depth := 0.
	closeChar := anOpenChar = $[ ifTrue: [ $] ] ifFalse: [ $) ].
	anIndex to: aSource size do: [ :index |
		| char |
		char := aSource at: index.
		char = anOpenChar ifTrue: [ depth := depth + 1 ].
		char = closeChar ifTrue: [
			depth := depth - 1.
			depth = 0 ifTrue: [ ^ index ] ] ].
	^ 0
]

{ #category : 'private' }
CtikzSourceScanner >> labelsIn: aSource [
	| labels index |
	labels := OrderedCollection new.
	index := 1.
	[ (index := aSource indexOfSubCollection: '\node' startingAt: index) = 0 ] whileFalse: [
		| open close |
		open := self firstTextBraceAfter: index + 5 in: aSource.
		open = 0 ifTrue: [ ^ labels ].
		close := self matchingBraceCloseFrom: open in: aSource.
		close = 0 ifTrue: [ ^ labels ].
		labels add: (Dictionary new
			at: 'text' put: (aSource copyFrom: open + 1 to: close - 1) trimBoth;
			at: 'line' put: (self lineFor: index in: aSource);
			yourself).
		index := close + 1 ].
	^ labels asArray
]

{ #category : 'private' }
CtikzSourceScanner >> forbiddenMatchesIn: aSource [
	| matches |
	matches := OrderedCollection new.
	#( '\includegraphics' 'reference/target.png' ) do: [ :pattern |
		| index |
		index := 1.
		[ (index := aSource indexOfSubCollection: pattern startingAt: index) = 0 ] whileFalse: [
			matches add: (Dictionary new
				at: 'pattern' put: pattern;
				at: 'line' put: (self lineFor: index in: aSource);
				yourself).
			index := index + pattern size ] ].
	^ matches asArray
]

{ #category : 'private' }
CtikzSourceScanner >> lineFor: anIndex in: aSource [
	| line |
	line := 1.
	1 to: (anIndex min: aSource size) do: [ :index |
		(aSource at: index) = Character lf ifTrue: [ line := line + 1 ] ].
	^ line
]
