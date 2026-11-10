"
I am a structured service error with a stable code, a message, and optional details.
"
Class {
	#name : 'PmdtError',
	#superclass : 'Error',
	#instVars : [
		'code',
		'message',
		'details'
	],
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'instance creation' }
PmdtError class >> code: aString message: aString2 [
	^ self new
		code: aString;
		message: aString2;
		signal
]

{ #category : 'instance creation' }
PmdtError class >> code: aString message: aString2 details: aDictionary [
	^ self new
		code: aString;
		message: aString2;
		details: aDictionary;
		signal
]

{ #category : 'accessing' }
PmdtError >> code [
	^ code
]

{ #category : 'accessing' }
PmdtError >> code: anObject [
	code := anObject
]

{ #category : 'accessing' }
PmdtError >> details [
	^ details ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
PmdtError >> details: anObject [
	details := anObject
]

{ #category : 'accessing' }
PmdtError >> message [
	^ message ifNil: [ super messageText ]
]

{ #category : 'accessing' }
PmdtError >> message: anObject [
	message := anObject
]

{ #category : 'accessing' }
PmdtError >> messageText [
	^ self message
]

{ #category : 'accessing' }
PmdtError >> asDictionary [
	^ Dictionary new
		at: 'code' put: self code;
		at: 'message' put: self message;
		at: 'details' put: self details;
		yourself
]
