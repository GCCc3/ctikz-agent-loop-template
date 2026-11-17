"
I am one schemabloc lint check.
"
Class {
	#name : 'SchemablocLintCheck',
	#superclass : 'Object',
	#instVars : [ 'id', 'status', 'message', 'line', 'details' ],
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'instance creation' }
SchemablocLintCheck class >> id: anId status: aStatus message: aMessage line: aLine details: aDetails [
	^ self new
		id: anId;
		status: aStatus;
		message: aMessage;
		line: aLine;
		details: aDetails;
		yourself
]
{ #category : 'accessing' }
SchemablocLintCheck >> id [ ^ id ]
{ #category : 'accessing' }
SchemablocLintCheck >> id: anObject [ id := anObject ]
{ #category : 'accessing' }
SchemablocLintCheck >> status [ ^ status ]
{ #category : 'accessing' }
SchemablocLintCheck >> status: anObject [ status := anObject ]
{ #category : 'accessing' }
SchemablocLintCheck >> message [ ^ message ]
{ #category : 'accessing' }
SchemablocLintCheck >> message: anObject [ message := anObject ]
{ #category : 'accessing' }
SchemablocLintCheck >> line [ ^ line ]
{ #category : 'accessing' }
SchemablocLintCheck >> line: anObject [ line := anObject ]
{ #category : 'accessing' }
SchemablocLintCheck >> details [ ^ details ifNil: [ Dictionary new ] ]
{ #category : 'accessing' }
SchemablocLintCheck >> details: anObject [ details := anObject ]
{ #category : 'testing' }
SchemablocLintCheck >> isWarning [ ^ status = 'warning' ]
{ #category : 'testing' }
SchemablocLintCheck >> isFailed [ ^ status = 'failed' ]
{ #category : 'converting' }
SchemablocLintCheck >> asDictionary [
	^ Dictionary new
		at: 'id' put: id;
		at: 'status' put: status;
		at: 'message' put: message;
		at: 'line' put: line;
		at: 'details' put: self details;
		yourself
]
