"
I am an immutable decoded PNG image: extent, RGBA bytes, header metadata, and source SHA-256.
"
Class {
	#name : 'PmdtRgbaImage',
	#superclass : 'Object',
	#instVars : [
		'width',
		'height',
		'pixels',
		'header',
		'sha256'
	],
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'instance creation' }
PmdtRgbaImage class >> width: anInteger height: anInteger2 pixels: aByteArray header: aHeader sha256: aString [
	^ self new
		width: anInteger;
		height: anInteger2;
		pixels: aByteArray;
		header: aHeader;
		sha256: aString;
		yourself
]

{ #category : 'accessing' }
PmdtRgbaImage >> width [ ^ width ]

{ #category : 'accessing' }
PmdtRgbaImage >> width: anObject [ width := anObject ]

{ #category : 'accessing' }
PmdtRgbaImage >> height [ ^ height ]

{ #category : 'accessing' }
PmdtRgbaImage >> height: anObject [ height := anObject ]

{ #category : 'accessing' }
PmdtRgbaImage >> pixels [ ^ pixels ]

{ #category : 'accessing' }
PmdtRgbaImage >> pixels: anObject [ pixels := anObject ]

{ #category : 'accessing' }
PmdtRgbaImage >> header [ ^ header ]

{ #category : 'accessing' }
PmdtRgbaImage >> header: anObject [ header := anObject ]

{ #category : 'accessing' }
PmdtRgbaImage >> sha256 [ ^ sha256 ]

{ #category : 'accessing' }
PmdtRgbaImage >> sha256: anObject [ sha256 := anObject ]

{ #category : 'accessing' }
PmdtRgbaImage >> extent [
	^ width @ height
]

{ #category : 'accessing' }
PmdtRgbaImage >> rgbaAtX: anInteger y: anInteger2 [
	| index |
	index := ((anInteger2 * width) + anInteger) * 4 + 1.
	^ { pixels at: index . pixels at: index + 1 . pixels at: index + 2 . pixels at: index + 3 }
]

{ #category : 'converting' }
PmdtRgbaImage >> asDictionary [
	^ Dictionary new
		at: 'width_px' put: width;
		at: 'height_px' put: height;
		at: 'sha256' put: sha256;
		yourself
]
