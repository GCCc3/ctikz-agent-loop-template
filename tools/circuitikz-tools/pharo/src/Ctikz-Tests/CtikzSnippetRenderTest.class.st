"
I test deterministic snippet rendering, defaults, presets, and validation.
"
Class {
	#name : 'CtikzSnippetRenderTest',
	#superclass : 'CtikzTestCase',
	#category : 'Ctikz-Tests',
	#package : 'Ctikz-Tests'
}

{ #category : 'helpers' }
CtikzSnippetRenderTest >> minimalParametersFor: aSnippet [
	| parameters |
	parameters := Dictionary new.
	aSnippet parameterSchema do: [ :parameter |
		parameter required ifTrue: [
			parameters at: parameter name put: (parameter type = 'number' ifTrue: [ 1 ] ifFalse: [ 'x' ]) ] ].
	^ parameters
]

{ #category : 'tests' }
CtikzSnippetRenderTest >> testAllSnippetsRenderWithMinimalParameters [
	| renderer |
	renderer := CtikzSnippetRenderer new.
	CtikzSnippetCatalog default snippets do: [ :snippet |
		| result source |
		result := renderer render: snippet parameters: (self minimalParametersFor: snippet).
		source := result at: 'source'.
		self deny: (source includesSubstring: '{{').
		self assert: (source includes: Character cr) not ]
]

{ #category : 'tests' }
CtikzSnippetRenderTest >> testAcDcConverterHasTwoDrawCommands [
	| snippet result source drawCount |
	snippet := CtikzSnippetCatalog default snippetNamed: 'component/ac-dc-converter'.
	result := CtikzSnippetRenderer new render: snippet parameters: (Dictionary new
		at: 'block_start' put: 'a';
		at: 'block_end' put: 'b';
		at: 'diagonal_start' put: 'a';
		at: 'diagonal_end' put: 'b';
		yourself).
	source := result at: 'source'.
	drawCount := 0.
	source lines do: [ :line |
		(line includesSubstring: '\draw') ifTrue: [ drawCount := drawCount + 1 ] ].
	self assert: drawCount equals: 2.
	self assert: (source includesSubstring: 'rectangle').
	self assert: (source includesSubstring: '--')
]

{ #category : 'tests' }
CtikzSnippetRenderTest >> testPresetL [
	| snippet result |
	snippet := CtikzSnippetCatalog default snippetNamed: 'component/L'.
	result := CtikzSnippetRenderer new render: snippet parameters: (Dictionary new
		at: 'start' put: 'c1';
		at: 'end' put: 'c2';
		yourself).
	self assert: (result at: 'source') equals: '\draw (c1) to[L] (c2);'
]

{ #category : 'tests' }
CtikzSnippetRenderTest >> testMissingParameter [
	| snippet |
	snippet := CtikzSnippetCatalog default snippetNamed: 'label/generic'.
	self assertCode: [
		CtikzSnippetRenderer new render: snippet parameters: (Dictionary new
			at: 'x' put: 1;
			at: 'y' put: 2;
			yourself) ] equals: 'missing_parameter'
]

{ #category : 'tests' }
CtikzSnippetRenderTest >> testUnknownParameter [
	| snippet |
	snippet := CtikzSnippetCatalog default snippetNamed: 'component/L'.
	self assertCode: [
		CtikzSnippetRenderer new render: snippet parameters: (Dictionary new
			at: 'start' put: 'c1';
			at: 'end' put: 'c2';
			at: 'component_options' put: 'R';
			yourself) ] equals: 'unknown_parameter'
]

{ #category : 'tests' }
CtikzSnippetRenderTest >> testDeterministicRender [
	| snippet parameters first second |
	snippet := CtikzSnippetCatalog default snippetNamed: 'component/L'.
	parameters := Dictionary new at: 'start' put: 'c1'; at: 'end' put: 'c2'; yourself.
	first := CtikzSnippetRenderer new render: snippet parameters: parameters.
	second := CtikzSnippetRenderer new render: snippet parameters: parameters.
	self assert: (first at: 'source') equals: (second at: 'source').
	self assert: (first at: 'checksum') equals: (second at: 'checksum')
]

{ #category : 'tests' }
CtikzSnippetRenderTest >> testPresetOverrideRejected [
	| snippet |
	snippet := CtikzSnippet new
		id: 'test/preset-override';
		title: 'Test';
		kind: 'test';
		mustacheSource: '\draw (a) to[{{component_options}}] (b);';
		parameterSchema: { (CtikzSnippetParameter named: 'component_options' type: 'string') default: 'L'; yourself };
		presetParameters: (Dictionary new at: 'component_options' put: 'R'; yourself);
		yourself.
	self assertCode: [
		CtikzSnippetValidator new validate: snippet in: CtikzSnippetCatalog default ]
		equals: 'snippet_validation_failed'
]

{ #category : 'tests' }
CtikzSnippetRenderTest >> testUnknownComponentRejected [
	| snippet |
	snippet := CtikzSnippet new
		id: 'test/unknown-component';
		title: 'Test';
		kind: 'test';
		mustacheSource: '\draw (a) to[{{component_options}}] (b);';
		parameterSchema: #();
		presetParameters: (Dictionary new at: 'component_options' put: 'not-a-component'; yourself);
		yourself.
	self assertCode: [
		CtikzSnippetValidator new validate: snippet in: CtikzSnippetCatalog default ]
		equals: 'snippet_validation_failed'
]

{ #category : 'tests' }
CtikzSnippetRenderTest >> testEnumRejected [
	| snippet |
	snippet := CtikzSnippet new
		id: 'test/enum';
		title: 'Test';
		kind: 'test';
		mustacheSource: '\draw (a) -- (b);';
		parameterSchema: { (CtikzSnippetParameter named: 'mode' type: 'string') default: 'c'; enum: #('a' 'b'); yourself };
		yourself.
	self assertCode: [
		CtikzSnippetValidator new validate: snippet in: CtikzSnippetCatalog default ]
		equals: 'snippet_validation_failed'
]

{ #category : 'tests' }
CtikzSnippetRenderTest >> testLabelAnchorSpacing [
	| snippet result |
	snippet := CtikzSnippetCatalog default snippetNamed: 'label/generic'.
	result := CtikzSnippetRenderer new render: snippet parameters: (Dictionary new
		at: 'text' put: '$v_g$';
		at: 'x' put: 1;
		at: 'y' put: 2;
		at: 'anchor_options' put: ' [anchor=east]';
		at: 'style_options' put: '';
		yourself).
	self assert: (result at: 'source') equals: '\node [anchor=east] at (1,2) { $v_g$ };'
]

{ #category : 'tests' }
CtikzSnippetRenderTest >> testUnknownPlaceholderFailsValidation [
	| snippet |
	snippet := CtikzSnippet new
		id: 'test/unknown-placeholder';
		title: 'Test';
		kind: 'test';
		mustacheSource: '\draw {{bogus}} (a) -- (b);';
		parameterSchema: #();
		yourself.
	self assertCode: [
		CtikzSnippetValidator new validate: snippet in: CtikzSnippetCatalog default ] equals: 'snippet_validation_failed'
]
