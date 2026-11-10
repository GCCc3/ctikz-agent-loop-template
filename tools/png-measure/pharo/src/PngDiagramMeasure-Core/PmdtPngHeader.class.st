"
I hold the validated PNG metadata needed by the measurement operations.
"
Class {
	#name : 'PmdtPngHeader',
	#superclass : 'Object',
	#instVars : [
		'width',
		'height',
		'bitDepth',
		'colorType',
		'interlace',
		'palette',
		'transparency',
		'physX',
		'physY',
		'physUnit'
	],
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'instance creation' }
PmdtPngHeader class >> width: anInteger height: anInteger2 bitDepth: anInteger3 colorType: anInteger4 interlace: anInteger5 [
	^ self new
		width: anInteger;
		height: anInteger2;
		bitDepth: anInteger3;
		colorType: anInteger4;
		interlace: anInteger5;
		yourself
]

{ #category : 'accessing' }
PmdtPngHeader >> width [ ^ width ]

{ #category : 'accessing' }
PmdtPngHeader >> width: anObject [ width := anObject ]

{ #category : 'accessing' }
PmdtPngHeader >> height [ ^ height ]

{ #category : 'accessing' }
PmdtPngHeader >> height: anObject [ height := anObject ]

{ #category : 'accessing' }
PmdtPngHeader >> bitDepth [ ^ bitDepth ]

{ #category : 'accessing' }
PmdtPngHeader >> bitDepth: anObject [ bitDepth := anObject ]

{ #category : 'accessing' }
PmdtPngHeader >> colorType [ ^ colorType ]

{ #category : 'accessing' }
PmdtPngHeader >> colorType: anObject [ colorType := anObject ]

{ #category : 'accessing' }
PmdtPngHeader >> interlace [ ^ interlace ]

{ #category : 'accessing' }
PmdtPngHeader >> interlace: anObject [ interlace := anObject ]

{ #category : 'accessing' }
PmdtPngHeader >> palette [ ^ palette ]

{ #category : 'accessing' }
PmdtPngHeader >> palette: anObject [ palette := anObject ]

{ #category : 'accessing' }
PmdtPngHeader >> transparency [ ^ transparency ]

{ #category : 'accessing' }
PmdtPngHeader >> transparency: anObject [ transparency := anObject ]

{ #category : 'accessing' }
PmdtPngHeader >> physX [ ^ physX ]

{ #category : 'accessing' }
PmdtPngHeader >> physX: anObject [ physX := anObject ]

{ #category : 'accessing' }
PmdtPngHeader >> physY [ ^ physY ]

{ #category : 'accessing' }
PmdtPngHeader >> physY: anObject [ physY := anObject ]

{ #category : 'accessing' }
PmdtPngHeader >> physUnit [ ^ physUnit ]

{ #category : 'accessing' }
PmdtPngHeader >> physUnit: anObject [ physUnit := anObject ]

{ #category : 'accessing' }
PmdtPngHeader >> colorTypeName [
	^ { 0 -> 'grayscale' . 2 -> 'rgb' . 3 -> 'indexed' . 4 -> 'grayscale_alpha' . 6 -> 'rgba' }
		asDictionary at: self colorType ifAbsent: [ 'unknown' ]
]

{ #category : 'testing' }
PmdtPngHeader >> hasAlpha [
	^ self colorType = 4 or: [ self colorType = 6 or: [ self transparency notNil ] ]
]

{ #category : 'testing' }
PmdtPngHeader >> isInterlaced [
	^ self interlace ~= 0
]

{ #category : 'accessing' }
PmdtPngHeader >> dpiX [
	^ self physUnit = 1
		ifTrue: [ (self physX / 39.37007874015748) asFloat ]
		ifFalse: [ nil ]
]

{ #category : 'accessing' }
PmdtPngHeader >> dpiY [
	^ self physUnit = 1
		ifTrue: [ (self physY / 39.37007874015748) asFloat ]
		ifFalse: [ nil ]
]

{ #category : 'converting' }
PmdtPngHeader >> asDictionary [
	^ Dictionary new
		at: 'width_px' put: self width;
		at: 'height_px' put: self height;
		at: 'bit_depth' put: self bitDepth;
		at: 'colour_type' put: self colorTypeName;
		at: 'has_alpha' put: self hasAlpha;
		at: 'interlaced' put: self isInterlaced;
		yourself
]
