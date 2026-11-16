"
I test lint edge cases: verbatim masking, relative coordinates, and request typing.
"
Class {
	#name : 'CtikzLintEdgeTest',
	#superclass : 'CtikzTestCase',
	#category : 'Ctikz-Tests',
	#package : 'Ctikz-Tests'
}

{ #category : 'helpers' }
CtikzLintEdgeTest >> lint: aSource [
	^ CtikzLintService default lintSource: (Dictionary new
		at: 'source_text' put: aSource;
		at: 'required_labels' put: #();
		yourself)
]

{ #category : 'helpers' }
CtikzLintEdgeTest >> statusOf: anId in: aResult [
	^ ((aResult at: 'checks') detect: [ :each | (each at: 'id') = anId ]) at: 'status'
]

{ #category : 'tests' }
CtikzLintEdgeTest >> testVerbatimIsUnsupportedAndNotForbidden [
	| result |
	result := self lint: '\documentclass{standalone}
\usepackage{circuitikz}
\begin{document}
\begin{circuitikz}
\begin{verbatim}
\includegraphics{x}
\end{verbatim}
\end{circuitikz}
\end{document}'.
	self assert: (self statusOf: 'unsupported_construct' in: result) equals: 'warning'.
	self assert: (self statusOf: 'no_image_inclusion' in: result) equals: 'passed'
]

{ #category : 'tests' }
CtikzLintEdgeTest >> testSinglePlusIsAmbiguous [
	| result |
	result := self lint: '\documentclass{standalone}
\usepackage{circuitikz}
\begin{document}
\begin{circuitikz}
\coordinate (a) at (0,0);
\coordinate (b) at (1,0);
\draw (a) + (1,0) -- (b);
\end{circuitikz}
\end{document}'.
	self assert: (self statusOf: 'ambiguous_coordinates' in: result) equals: 'warning'
]

{ #category : 'tests' }
CtikzLintEdgeTest >> testInvalidPathTypeRejected [
	self assertCode: [
		CtikzLintService default lintSource: (Dictionary new at: 'path' put: 42; yourself) ]
		equals: 'invalid_request'
]

{ #category : 'tests' }
CtikzLintEdgeTest >> testOversizeFileRejected [
	| root file |
	root := DsktSettings repoRoot asFileReference / 'tmp'.
	root ensureCreateDirectory.
	file := root / ('ctikz-oversize-' , UUID new asString , '.tex').
	file writeStreamDo: [ :stream |
		stream nextPutAll: (String new: 1000001 withAll: $x) ].
	[ self assertCode: [
		CtikzLintService default lintSource: (Dictionary new
			at: 'path' put: 'tmp/' , file basename;
			yourself) ] equals: 'source_too_large' ]
		ensure: [ file delete ]
]
