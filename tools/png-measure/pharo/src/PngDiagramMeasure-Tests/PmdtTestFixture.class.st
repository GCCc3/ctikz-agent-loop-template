"
I build small PNG fixtures and synthetic RGBA images for the measurement tests.
"
Class {
	#name : 'PmdtTestFixture',
	#superclass : 'Object',
	#category : 'PngDiagramMeasure-Tests',
	#package : 'PngDiagramMeasure-Tests'
}

{ #category : 'png' }
PmdtTestFixture class >> grayscalePngWidth: width height: height pixels: pixels [
	^ self pngWidth: width height: height colorType: 0 channels: 1 pixels: pixels palette: nil transparency: nil
]

{ #category : 'png' }
PmdtTestFixture class >> rgbPngWidth: width height: height pixels: pixels [
	^ self pngWidth: width height: height colorType: 2 channels: 3 pixels: pixels palette: nil transparency: nil
]

{ #category : 'png' }
PmdtTestFixture class >> indexedPngWidth: width height: height pixels: pixels palette: palette [
	^ self pngWidth: width height: height colorType: 3 channels: 1 pixels: pixels palette: palette transparency: nil
]

{ #category : 'png' }
PmdtTestFixture class >> grayAlphaPngWidth: width height: height pixels: pixels [
	^ self pngWidth: width height: height colorType: 4 channels: 2 pixels: pixels palette: nil transparency: nil
]

{ #category : 'png' }
PmdtTestFixture class >> rgbaPngWidth: width height: height pixels: pixels [
	^ self pngWidth: width height: height colorType: 6 channels: 4 pixels: pixels palette: nil transparency: nil
]

{ #category : 'png' }
PmdtTestFixture class >> pngWidth: width height: height colorType: colorType channels: channels pixels: pixels palette: palette transparency: transparency [
	| raw |
	raw := ByteArray new: height * (width * channels + 1).
	0 to: height - 1 do: [ :y |
		| base |
		base := y * (width * channels + 1) + 1.
		raw at: base put: 0.
		1 to: width * channels do: [ :i |
			raw at: base + i put: (pixels at: y * width * channels + i) ] ].
	^ ByteArray streamContents: [ :stream |
		stream nextPutAll: #(137 80 78 71 13 10 26 10) asByteArray.
		stream nextPutAll: (PmdtPngWriter
			chunk: 'IHDR'
			data: (ByteArray streamContents: [ :ihdr |
				ihdr nextPutAll: (PmdtPngWriter uint32: width).
				ihdr nextPutAll: (PmdtPngWriter uint32: height).
				ihdr nextPut: 8; nextPut: colorType; nextPut: 0; nextPut: 0; nextPut: 0 ])).
		palette ifNotNil: [
			stream nextPutAll: (PmdtPngWriter chunk: 'PLTE' data: palette) ].
		transparency ifNotNil: [
			stream nextPutAll: (PmdtPngWriter chunk: 'tRNS' data: transparency) ].
		stream nextPutAll: (PmdtPngWriter chunk: 'pHYs' data: (ByteArray streamContents: [ :phys |
			phys nextPutAll: (PmdtPngWriter uint32: 4724).
			phys nextPutAll: (PmdtPngWriter uint32: 4724).
			phys nextPut: 1 ])).
		stream nextPutAll: (PmdtPngWriter chunk: 'IDAT' data: (PmdtPngWriter zlibCompress: raw)).
		stream nextPutAll: (PmdtPngWriter chunk: 'IEND' data: ByteArray new) ]
]

{ #category : 'images' }
PmdtTestFixture class >> rgbaImageWidth: width height: height background: background rects: rects [
	| pixels |
	pixels := ByteArray new: width * height * 4.
	0 to: height - 1 do: [ :y |
		0 to: width - 1 do: [ :x |
			| index color |
			index := ((y * width) + x) * 4 + 1.
			color := background.
			rects do: [ :rect |
				((x >= (rect at: 1)) and: [ x < (rect at: 3) and: [ y >= (rect at: 2) and: [ y < (rect at: 4) ] ] ])
					ifTrue: [ color := rect at: 5 ] ].
			pixels at: index put: (color at: 1).
			pixels at: index + 1 put: (color at: 2).
			pixels at: index + 2 put: (color at: 3).
			pixels at: index + 3 put: (color at: 4) ] ].
	^ PmdtRgbaImage
		width: width
		height: height
		pixels: pixels
		header: (PmdtPngHeader width: width height: height bitDepth: 8 colorType: 6 interlace: 0)
		sha256: 'fixture'
]

{ #category : 'images' }
PmdtTestFixture class >> imageWithBlackBox [
	^ self
		rgbaImageWidth: 10
		height: 10
		background: #(255 255 255 255)
		rects: { { 2 . 2 . 8 . 8 . #(0 0 0 255) } }
]
