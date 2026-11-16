"
I am a structured service error with a stable code, a message, and optional details.

Domain packages signal me for both transport and validation failures. The server
converts me to the shared JSON error envelope; domain error codes stay domain-owned.
"
Class {
	#name : 'DsktError',
	#superclass : 'Error',
	#instVars : [
		'code',
		'message',
		'details'
	],
	#category : 'Dskt-Core',
	#package : 'Dskt-Core'
}

{ #category : 'instance creation' }
DsktError class >> code: aString message: aString2 [
	^ self new
		code: aString;
		message: aString2;
		signal
]

{ #category : 'instance creation' }
DsktError class >> code: aString message: aString2 details: aDictionary [
	^ self new
		code: aString;
		message: aString2;
		details: aDictionary;
		signal
]

{ #category : 'accessing' }
DsktError >> code [
	^ code
]

{ #category : 'accessing' }
DsktError >> code: anObject [
	code := anObject
]

{ #category : 'accessing' }
DsktError >> details [
	^ details ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
DsktError >> details: anObject [
	details := anObject
]

{ #category : 'accessing' }
DsktError >> message [
	^ message ifNil: [ super messageText ]
]

{ #category : 'accessing' }
DsktError >> message: anObject [
	message := anObject
]

{ #category : 'accessing' }
DsktError >> messageText [
	^ self message
]

{ #category : 'converting' }
DsktError >> asDictionary [
	^ Dictionary new
		at: 'code' put: self code;
		at: 'message' put: self message;
		at: 'details' put: self details;
		yourself
]
