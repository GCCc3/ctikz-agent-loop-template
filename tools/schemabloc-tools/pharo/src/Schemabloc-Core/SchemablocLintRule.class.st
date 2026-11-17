"
I am the abstract schemabloc lint rule.
"
Class {
	#name : 'SchemablocLintRule',
	#superclass : 'Object',
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'accessing' }
SchemablocLintRule >> id [ ^ self subclassResponsibility ]
{ #category : 'accessing' }
SchemablocLintRule >> defaultSeverity [ ^ 'failed' ]
{ #category : 'accessing' }
SchemablocLintRule >> version [ ^ 1 ]
{ #category : 'evaluating' }
SchemablocLintRule >> evaluate: aModel context: aDictionary [ ^ self subclassResponsibility ]
{ #category : 'private' }
SchemablocLintRule >> check: aStatus message: aMessage line: aLine [
	^ SchemablocLintCheck id: self id status: aStatus message: aMessage line: aLine details: nil
]
{ #category : 'private' }
SchemablocLintRule >> passed [ ^ self check: 'passed' message: '' line: nil ]
{ #category : 'private' }
SchemablocLintRule >> failed: aMessage line: aLine [ ^ self check: 'failed' message: aMessage line: aLine ]
{ #category : 'private' }
SchemablocLintRule >> warning: aMessage line: aLine [ ^ self check: 'warning' message: aMessage line: aLine ]
