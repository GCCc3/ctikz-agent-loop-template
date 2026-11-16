"
I test the shared path resolver's root boundary and symlink handling.
"
Class {
	#name : 'DsktPathResolverTest',
	#superclass : 'TestCase',
	#category : 'Dskt-Tests',
	#package : 'Dskt-Tests'
}

{ #category : 'helpers' }
DsktPathResolverTest >> assertCode: aBlock equals: aCode [
	| error |
	error := nil.
	[ aBlock value ] on: DsktError do: [ :each | error := each ].
	self assert: error notNil.
	self assert: error code equals: aCode
]

{ #category : 'helpers' }
DsktPathResolverTest >> temporaryRoot [
	| root |
	root := FileSystem workingDirectory / 'tmp' / ('dskt-path-test-' , UUID new asString).
	root ensureCreateDirectory.
	^ root
]

{ #category : 'tests' }
DsktPathResolverTest >> testAcceptsInsideRoot [
	| root file resolved |
	root := self temporaryRoot.
	file := root / 'inside.tex'.
	file writeStreamDo: [ :stream | stream nextPutAll: 'x' ].
	[ resolved := DsktPathResolver resolveExisting: 'inside.tex' under: root.
	self assert: resolved pathString equals: file pathString ]
		ensure: [ file delete. root delete ]
]

{ #category : 'tests' }
DsktPathResolverTest >> testRejectsSiblingPrefix [
	| root sibling file |
	root := self temporaryRoot.
	sibling := root parent / (root basename , '-evil').
	sibling ensureCreateDirectory.
	file := sibling / 'secret.tex'.
	file writeStreamDo: [ :stream | stream nextPutAll: 'x' ].
	[ self assertCode: [ DsktPathResolver resolveExisting: file pathString under: root ] equals: 'path_outside_repo' ]
		ensure: [ file delete. sibling delete. root delete ]
]

{ #category : 'tests' }
DsktPathResolverTest >> testRejectsMissingPath [
	| root |
	root := self temporaryRoot.
	[ self assertCode: [ DsktPathResolver resolveExisting: 'missing.tex' under: root ] equals: 'source_not_found' ]
		ensure: [ root delete ]
]

{ #category : 'tests' }
DsktPathResolverTest >> testRejectsSymlinkOutsideRoot [
	| root outside link |
	root := self temporaryRoot.
	outside := FileSystem workingDirectory / 'tmp' / ('dskt-outside-' , UUID new asString , '.tex').
	outside writeStreamDo: [ :stream | stream nextPutAll: 'x' ].
	link := root / 'link.tex'.
	LibC system: 'ln -sf ' , outside pathString , ' ' , link pathString.
	[ self assertCode: [ DsktPathResolver resolveExisting: 'link.tex' under: root ] equals: 'path_outside_repo' ]
		ensure: [ link exists ifTrue: [ link delete ]. outside delete. root delete ]
]
