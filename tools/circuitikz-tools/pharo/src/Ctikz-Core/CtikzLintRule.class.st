"
I am one CircuitTikZ lint rule.

I have an id and a default severity and I evaluate a CtikzSourceModel, returning
one CtikzLintCheck or a collection of checks. Subclasses implement each check.
"
Class {
	#name : 'CtikzLintRule',
	#superclass : 'Object',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzLintRule >> id [ ^ self subclassResponsibility ]

{ #category : 'accessing' }
CtikzLintRule >> defaultSeverity [ ^ 'failed' ]

{ #category : 'accessing' }
CtikzLintRule >> version [ ^ 1 ]

{ #category : 'evaluating' }
CtikzLintRule >> evaluate: aModel context: aDictionary [
	^ self subclassResponsibility
]

{ #category : 'private' }
CtikzLintRule >> check: aStatus message: aMessage line: aLine [
	^ CtikzLintCheck id: self id status: aStatus message: aMessage line: aLine details: nil
]

{ #category : 'private' }
CtikzLintRule >> passed [
	^ self check: 'passed' message: '' line: nil
]

{ #category : 'private' }
CtikzLintRule >> failed: aMessage line: aLine [
	^ self check: 'failed' message: aMessage line: aLine
]

{ #category : 'private' }
CtikzLintRule >> warning: aMessage line: aLine [
	^ self check: 'warning' message: aMessage line: aLine
]
