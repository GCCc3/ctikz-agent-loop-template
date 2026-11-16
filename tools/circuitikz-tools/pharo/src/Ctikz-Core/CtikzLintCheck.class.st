"
I am one check in a CircuitTikZ lint report.

I carry an id, a status (`passed`, `warning`, or `failed`), a message, a source
line, and optional details. I convert to a canonical dictionary.
"
Class {
	#name : 'CtikzLintCheck',
	#superclass : 'Object',
	#instVars : [
		'id',
		'status',
		'message',
		'line',
		'details'
	],
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'instance creation' }
CtikzLintCheck class >> id: anId status: aStatus [
	^ self id: anId status: aStatus message: nil line: nil details: nil
]

{ #category : 'instance creation' }
CtikzLintCheck class >> id: anId status: aStatus message: aMessage line: aLine details: aDetails [
	^ self new
		id: anId;
		status: aStatus;
		message: aMessage;
		line: aLine;
		details: aDetails;
		yourself
]

{ #category : 'accessing' }
CtikzLintCheck >> id [ ^ id ]
{ #category : 'accessing' }
CtikzLintCheck >> id: anObject [ id := anObject ]
{ #category : 'accessing' }
CtikzLintCheck >> status [ ^ status ]
{ #category : 'accessing' }
CtikzLintCheck >> status: anObject [ status := anObject ]
{ #category : 'accessing' }
CtikzLintCheck >> message [ ^ message ]
{ #category : 'accessing' }
CtikzLintCheck >> message: anObject [ message := anObject ]
{ #category : 'accessing' }
CtikzLintCheck >> line [ ^ line ]
{ #category : 'accessing' }
CtikzLintCheck >> line: anObject [ line := anObject ]
{ #category : 'accessing' }
CtikzLintCheck >> details [ ^ details ]
{ #category : 'accessing' }
CtikzLintCheck >> details: anObject [ details := anObject ]
{ #category : 'testing' }
CtikzLintCheck >> isFailed [ ^ status = 'failed' ]
{ #category : 'testing' }
CtikzLintCheck >> isWarning [ ^ status = 'warning' ]
{ #category : 'testing' }
CtikzLintCheck >> isPassed [ ^ status = 'passed' ]
{ #category : 'converting' }
CtikzLintCheck >> asDictionary [
	^ Dictionary new
		at: 'id' put: id;
		at: 'status' put: status;
		at: 'message' put: message;
		at: 'line' put: line;
		at: 'details' put: (details ifNil: [ Dictionary new ]);
		yourself
]
