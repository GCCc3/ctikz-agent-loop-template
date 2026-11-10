"
I write an 8-bit grayscale, colour-type-0 PNG for a binary ink mask.
"
Class {
	#name : 'PmdtPngWriter',
	#superclass : 'Object',
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'encoding' }
PmdtPngWriter class >> encodeMask: aPmdtInkMask [
	| width height pixels scanlines compressed |
	width := aPmdtInkMask width.
	height := aPmdtInkMask height.
	pixels := aPmdtInkMask pixels.
	scanlines := ByteArray new: height * (width + 1).
	0 to: height - 1 do: [ :y |
		| base |
		base := y * (width + 1) + 1.
		scanlines at: base put: 0.
		1 to: width do: [ :x |
			scanlines at: base + x put: (pixels at: y * width + x) ] ].
	compressed := self zlibCompress: scanlines.
	^ ByteArray streamContents: [ :stream |
		stream nextPutAll: #(137 80 78 71 13 10 26 10) asByteArray.
		stream nextPutAll: (self chunk: 'IHDR' data: (ByteArray streamContents: [ :ihdr |
			ihdr nextPutAll: (self uint32: width).
			ihdr nextPutAll: (self uint32: height).
			ihdr nextPut: 8;
				nextPut: 0;
				nextPut: 0;
				nextPut: 0;
				nextPut: 0 ])).
		stream nextPutAll: (self chunk: 'IDAT' data: compressed).
		stream nextPutAll: (self chunk: 'IEND' data: ByteArray new) ]
]

{ #category : 'private' }
PmdtPngWriter class >> chunk: aString data: aByteArray [
	| body |
	body := aString asByteArray , aByteArray.
	^ ByteArray streamContents: [ :stream |
		stream nextPutAll: (self uint32: aByteArray size).
		stream nextPutAll: body.
		stream nextPutAll: (self uint32: (CRC crc32FromCollection: body)) ]
]

{ #category : 'private' }
PmdtPngWriter class >> uint32: anInteger [
	^ { (anInteger bitShift: -24) bitAnd: 255 .
		(anInteger bitShift: -16) bitAnd: 255 .
		(anInteger bitShift: -8) bitAnd: 255 .
		anInteger bitAnd: 255 } asByteArray
]

{ #category : 'private' }
PmdtPngWriter class >> zlibCompress: aByteArray [
	| stream |
	stream := ZLibWriteStream on: (ByteArray new).
	stream nextPutAll: aByteArray.
	stream close.
	^ stream encodedStream contents
]
