"
I test the supported PNG colour types and the grayscale mask writer.
"
Class {
	#name : 'PmdtPngCodecTest',
	#superclass : 'TestCase',
	#category : 'PngDiagramMeasure-Tests',
	#package : 'PngDiagramMeasure-Tests'
}

{ #category : 'tests' }
PmdtPngCodecTest >> testGrayscaleDecode [
	| image |
	image := PmdtPngDecoder decodeBytes: (PmdtTestFixture grayscalePngWidth: 2 height: 2 pixels: #(0 128 255 64) asByteArray) sha256: 'sha'.
	self assert: image width equals: 2.
	self assert: image height equals: 2.
	self assert: (image rgbaAtX: 0 y: 0) equals: #(0 0 0 255).
	self assert: (image rgbaAtX: 1 y: 0) equals: #(128 128 128 255).
	self assert: (image rgbaAtX: 0 y: 1) equals: #(255 255 255 255)
]

{ #category : 'tests' }
PmdtPngCodecTest >> testRgbDecode [
	| image |
	image := PmdtPngDecoder
		decodeBytes: (PmdtTestFixture rgbPngWidth: 1 height: 1 pixels: #(10 20 30) asByteArray)
		sha256: 'sha'.
	self assert: (image rgbaAtX: 0 y: 0) equals: #(10 20 30 255)
]

{ #category : 'tests' }
PmdtPngCodecTest >> testIndexedDecode [
	| image |
	image := PmdtPngDecoder
		decodeBytes: (PmdtTestFixture
			indexedPngWidth: 2
			height: 1
			pixels: #(0 1) asByteArray
			palette: #(255 0 0 0 255 0) asByteArray)
		sha256: 'sha'.
	self assert: (image rgbaAtX: 0 y: 0) equals: #(255 0 0 255).
	self assert: (image rgbaAtX: 1 y: 0) equals: #(0 255 0 255)
]

{ #category : 'tests' }
PmdtPngCodecTest >> testAlphaDecode [
	| grayAlpha rgba |
	grayAlpha := PmdtPngDecoder
		decodeBytes: (PmdtTestFixture grayAlphaPngWidth: 1 height: 1 pixels: #(7 0) asByteArray)
		sha256: 'sha'.
	self assert: (grayAlpha rgbaAtX: 0 y: 0) equals: #(7 7 7 0).
	rgba := PmdtPngDecoder
		decodeBytes: (PmdtTestFixture rgbaPngWidth: 1 height: 1 pixels: #(1 2 3 4) asByteArray)
		sha256: 'sha'.
	self assert: (rgba rgbaAtX: 0 y: 0) equals: #(1 2 3 4)
]

{ #category : 'tests' }
PmdtPngCodecTest >> testMaskWriterRoundTrip [
	| image parameters mask bytes decoded |
	image := PmdtTestFixture imageWithBlackBox.
	parameters := PmdtMaskParameters default.
	mask := PmdtLuminanceClassifier maskFor: image parameters: parameters.
	bytes := PmdtPngWriter encodeMask: mask.
	decoded := PmdtPngDecoder decodeBytes: bytes sha256: 'mask'.
	self assert: decoded width equals: 10.
	self assert: decoded height equals: 10.
	self assert: (decoded rgbaAtX: 2 y: 2) first equals: 0.
	self assert: (decoded rgbaAtX: 0 y: 0) first equals: 255.
	self assert: (bytes at: 25) equals: 8.
	self assert: (bytes at: 26) equals: 0
]
