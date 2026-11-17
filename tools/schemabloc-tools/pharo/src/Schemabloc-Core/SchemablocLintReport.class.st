"
I am the deterministic report for a schemabloc lint run.
"
Class {
	#name : 'SchemablocLintReport',
	#superclass : 'Object',
	#instVars : [ 'checks', 'counts', 'summary', 'sourceSha256', 'sourceKind', 'sourcePath' ],
	#category : 'Schemabloc-Core',
	#package : 'Schemabloc-Core'
}

{ #category : 'instance creation' }
SchemablocLintReport class >> checks: aCollection counts: aDictionary summary: anotherDictionary sourceSha256: aString [
	^ self new
		checks: aCollection;
		counts: aDictionary;
		summary: anotherDictionary;
		sourceSha256: aString;
		yourself
]
{ #category : 'accessing' }
SchemablocLintReport >> checks [ ^ checks ifNil: [ checks := OrderedCollection new ] ]
{ #category : 'accessing' }
SchemablocLintReport >> checks: anObject [ checks := anObject ]
{ #category : 'accessing' }
SchemablocLintReport >> counts [ ^ counts ifNil: [ counts := Dictionary new ] ]
{ #category : 'accessing' }
SchemablocLintReport >> counts: anObject [ counts := anObject ]
{ #category : 'accessing' }
SchemablocLintReport >> summary [ ^ summary ifNil: [ summary := Dictionary new ] ]
{ #category : 'accessing' }
SchemablocLintReport >> summary: anObject [ summary := anObject ]
{ #category : 'accessing' }
SchemablocLintReport >> sourceSha256 [ ^ sourceSha256 ]
{ #category : 'accessing' }
SchemablocLintReport >> sourceSha256: anObject [ sourceSha256 := anObject ]
{ #category : 'accessing' }
SchemablocLintReport >> sourceKind [ ^ sourceKind ]
{ #category : 'accessing' }
SchemablocLintReport >> sourceKind: anObject [ sourceKind := anObject ]
{ #category : 'accessing' }
SchemablocLintReport >> sourcePath [ ^ sourcePath ]
{ #category : 'accessing' }
SchemablocLintReport >> sourcePath: anObject [ sourcePath := anObject ]
{ #category : 'converting' }
SchemablocLintReport >> asDictionary [
	^ Dictionary new
		at: 'source_kind' put: sourceKind;
		at: 'source_path' put: sourcePath;
		at: 'source_sha256' put: sourceSha256;
		at: 'checks' put: (self checks collect: [ :each | each asDictionary ]);
		at: 'counts' put: self counts;
		at: 'summary' put: self summary;
		yourself
]
