"
I resolve repository-relative paths and enforce a canonical root boundary.

I follow symlinks component by component because Pharo's `canonicalize` and
`resolve` do not resolve symlinks. I compare path segments, not string prefixes,
so a sibling directory whose name starts with the root name is rejected.
"
Class {
	#name : 'DsktPathResolver',
	#superclass : 'Object',
	#category : 'Dskt-Core',
	#package : 'Dskt-Core'
}

{ #category : 'resolving' }
DsktPathResolver class >> resolveExisting: aPath under: aRoot [
	^ self
		resolve: aPath
		under: aRoot
		mustExist: true
		code: 'path_outside_repo'
]

{ #category : 'resolving' }
DsktPathResolver class >> resolveWritable: aPath under: aRoot [
	^ self
		resolve: aPath
		under: aRoot
		mustExist: false
		code: 'output_path_rejected'
]

{ #category : 'private' }
DsktPathResolver class >> resolve: aPath under: aRoot mustExist: aBoolean code: aCode [
	| root candidate |
	root := self resolveSymlinks: aRoot asFileReference.
	candidate := aPath asFileReference.
	candidate isAbsolute ifFalse: [ candidate := root / aPath ].
	candidate := self resolveSymlinks: candidate.
	(self is: candidate under: root)
		ifFalse: [ DsktError code: aCode message: 'The path escapes the configured root: ' , aPath printString ].
	(aBoolean and: [ candidate exists not ])
		ifTrue: [ DsktError code: 'source_not_found' message: 'The path does not exist: ' , aPath printString ].
	^ candidate
]

{ #category : 'private' }
DsktPathResolver class >> resolveSymlinks: aFileReference [
	| current segments |
	current := aFileReference canonicalize.
	segments := current pathSegments.
	current := '/' asFileReference.
	segments do: [ :segment |
		| next depth |
		next := current / segment.
		depth := 0.
		[ next isSymlink ] whileTrue: [
			depth := depth + 1.
			depth > 40
				ifTrue: [ DsktError code: 'path_outside_repo' message: 'Symlink loop while resolving ' , aFileReference pathString ].
			next := next targetFileReference ].
		current := next ].
	^ current
]

{ #category : 'private' }
DsktPathResolver class >> is: aFileReference under: aRoot [
	| candidateSegments rootSegments |
	candidateSegments := aFileReference pathSegments.
	rootSegments := aRoot pathSegments.
	candidateSegments size < rootSegments size ifTrue: [ ^ false ].
	rootSegments withIndexDo: [ :segment :index |
		(candidateSegments at: index) = segment ifFalse: [ ^ false ] ].
	^ true
]
