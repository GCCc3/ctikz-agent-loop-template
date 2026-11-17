"
I test the schemabloc source scanner.
"
Class {
	#name : 'SchemablocSourceScannerTest',
	#superclass : 'TestCase',
	#category : 'Schemabloc-Tests',
	#package : 'Schemabloc-Tests'
}

{ #category : 'tests' }
SchemablocSourceScannerTest >> testControlSourceInventory [
	| model |
	model := SchemablocSourceScanner new scan: SchemablocTestFixtures controlSource.
	self assert: model tikzPictures equals: 1.
	self assert: (model hasPackage: 'schemabloc').
	self assert: model definitions size equals: 4.
	self assert: model links size equals: 2.
	self assert: model labels size equals: 2.
	self assert: model unknownMacros isEmpty.
	self assert: (model definitionNames includes: 'vref').
	self assert: (model definitionNames includes: 'sumv').
	self assert: (model definitionNames includes: 'Gva').
	self assert: (model definitionNames includes: 'iout').
	self assert: (model counts at: 'entries') equals: 1.
	self assert: (model counts at: 'exits') equals: 1.
	self assert: (model counts at: 'blocks') equals: 1.
	self assert: (model counts at: 'comparators') equals: 1
]

{ #category : 'tests' }
SchemablocSourceScannerTest >> testCommentsAndVerbatimAreIgnored [
	| model |
	model := SchemablocSourceScanner new scan: '\begin{verbatim}
\sbEntree{ignored}
\end{verbatim}
% \sbEntree{commented}
\usepackage{schemabloc}
\begin{tikzpicture}
\sbEntree{vref}
\end{tikzpicture}'.
	self assert: model definitions size equals: 1.
	self assert: (model definitions first at: 'name') equals: 'vref'.
	self assert: model unknownMacros isEmpty
]
