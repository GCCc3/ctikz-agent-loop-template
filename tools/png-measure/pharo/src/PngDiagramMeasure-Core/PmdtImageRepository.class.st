"
I cache decoded images and masks by SHA-256 and mask parameters.

I am an optimization only; a miss must reproduce identical output.
"
Class {
	#name : 'PmdtImageRepository',
	#superclass : 'Object',
	#instVars : [
		'images',
		'masks',
		'imageOrder',
		'maskOrder',
		'mutex',
		'imageLimit',
		'maskLimit'
	],
	#classVars : [
		'Default'
	],
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'instance creation' }
PmdtImageRepository class >> default [
	^ Default ifNil: [ Default := self new ]
]

{ #category : 'initialization' }
PmdtImageRepository >> initialize [
	super initialize.
	images := Dictionary new.
	masks := Dictionary new.
	imageOrder := OrderedCollection new.
	maskOrder := OrderedCollection new.
	mutex := Semaphore forMutualExclusion.
	imageLimit := 4.
	maskLimit := 8
]

{ #category : 'accessing' }
PmdtImageRepository >> imageLimit: anInteger [ imageLimit := anInteger ]

{ #category : 'accessing' }
PmdtImageRepository >> maskLimit: anInteger [ maskLimit := anInteger ]

{ #category : 'accessing' }
PmdtImageRepository >> imageForSha: aString ifAbsent: aBlock [
	^ mutex critical: [
		| image |
		image := images at: aString ifAbsent: [ nil ].
		image ifNotNil: [
			imageOrder remove: aString ifAbsent: [ nil ].
			imageOrder addLast: aString ].
		image ifNil: [ aBlock value ] ]
]

{ #category : 'accessing' }
PmdtImageRepository >> putImage: aPmdtRgbaImage [
	mutex critical: [
		images at: aPmdtRgbaImage sha256 put: aPmdtRgbaImage.
		imageOrder remove: aPmdtRgbaImage sha256 ifAbsent: [ nil ].
		imageOrder addLast: aPmdtRgbaImage sha256.
		[ imageOrder size > imageLimit ] whileTrue: [
			| oldest |
			oldest := imageOrder removeFirst.
			images removeKey: oldest ifAbsent: [ nil ] ] ].
	^ aPmdtRgbaImage
]

{ #category : 'accessing' }
PmdtImageRepository >> maskForSha: aString key: aKey ifAbsent: aBlock [
	^ mutex critical: [
		| cacheKey mask |
		cacheKey := aString , '|' , aKey.
		mask := masks at: cacheKey ifAbsent: [ nil ].
		mask ifNotNil: [
			maskOrder remove: cacheKey ifAbsent: [ nil ].
			maskOrder addLast: cacheKey ].
		mask ifNil: [ aBlock value ] ]
]

{ #category : 'accessing' }
PmdtImageRepository >> putMask: aPmdtInkMask sha: aString [
	| cacheKey |
	cacheKey := aString , '|' , aPmdtInkMask parameters cacheKey.
	mutex critical: [
		masks at: cacheKey put: aPmdtInkMask.
		maskOrder remove: cacheKey ifAbsent: [ nil ].
		maskOrder addLast: cacheKey.
		[ maskOrder size > maskLimit ] whileTrue: [
			| oldest |
			oldest := maskOrder removeFirst.
			masks removeKey: oldest ifAbsent: [ nil ] ] ].
	^ aPmdtInkMask
]

{ #category : 'accessing' }
PmdtImageRepository >> imageCount [
	^ mutex critical: [ images size ]
]

{ #category : 'accessing' }
PmdtImageRepository >> maskCount [
	^ mutex critical: [ masks size ]
]

{ #category : 'accessing' }
PmdtImageRepository >> clear [
	mutex critical: [
		images removeAll.
		masks removeAll.
		imageOrder removeAll.
		maskOrder removeAll ]
]
