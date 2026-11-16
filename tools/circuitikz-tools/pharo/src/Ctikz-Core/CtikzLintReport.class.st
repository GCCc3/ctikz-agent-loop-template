"
I am the deterministic report produced by a CircuitTikZ lint run.

I carry ordered checks, counts, a summary, and the source SHA-256. I convert to a
canonical dictionary without timestamps.
"
Class {
	#name : 'CtikzLintReport',
	#superclass : 'Object',
	#instVars : [
		'checks',
		'counts',
		'summary',
		'sourceSha256',
		'sourceKind',
		'sourcePath'
	],
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'instance creation' }
CtikzLintReport class >> checks: aCollection counts: aDictionary summary: anotherDictionary sourceSha256: aString [
	^ self new
		checks: aCollection;
		counts: aDictionary;
		summary: anotherDictionary;
		sourceSha256: aString;
		yourself
]

{ #category : 'accessing' }
CtikzLintReport >> checks [ ^ checks ifNil: [ checks := OrderedCollection new ] ]
{ #category : 'accessing' }
CtikzLintReport >> checks: anObject [ checks := anObject ]
{ #category : 'accessing' }
CtikzLintReport >> counts [ ^ counts ifNil: [ counts := Dictionary new ] ]
{ #category : 'accessing' }
CtikzLintReport >> counts: anObject [ counts := anObject ]
{ #category : 'accessing' }
CtikzLintReport >> summary [ ^ summary ifNil: [ summary := Dictionary new ] ]
{ #category : 'accessing' }
CtikzLintReport >> summary: anObject [ summary := anObject ]
{ #category : 'accessing' }
CtikzLintReport >> sourceSha256 [ ^ sourceSha256 ]
{ #category : 'accessing' }
CtikzLintReport >> sourceSha256: anObject [ sourceSha256 := anObject ]
{ #category : 'accessing' }
CtikzLintReport >> sourceKind [ ^ sourceKind ]
{ #category : 'accessing' }
CtikzLintReport >> sourceKind: anObject [ sourceKind := anObject ]
{ #category : 'accessing' }
CtikzLintReport >> sourcePath [ ^ sourcePath ]
{ #category : 'accessing' }
CtikzLintReport >> sourcePath: anObject [ sourcePath := anObject ]
{ #category : 'converting' }
CtikzLintReport >> asDictionary [
	^ Dictionary new
		at: 'source_kind' put: sourceKind;
		at: 'source_path' put: sourcePath;
		at: 'source_sha256' put: sourceSha256;
		at: 'checks' put: (self checks collect: [ :each | each asDictionary ]);
		at: 'counts' put: self counts;
		at: 'summary' put: self summary;
		yourself
]
