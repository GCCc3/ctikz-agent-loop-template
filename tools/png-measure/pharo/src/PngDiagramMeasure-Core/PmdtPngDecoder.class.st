"
I decode the supported PNG subset into RGBA8 pixels.

Supported: bit depth 8, non-interlaced, colour types 0, 2, 3, 4, and 6.
I validate signature, chunk lengths, CRC-32, IHDR fields, and IDAT inflation.
"
Class {
	#name : 'PmdtPngDecoder',
	#superclass : 'Object',
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'decoding' }
PmdtPngDecoder class >> decodeFile: aPath [
	| bytes sha |
	bytes := [ aPath asFileReference binaryReadStreamDo: [ :stream | stream upToEnd ] ]
		on: Error
		do: [ :error | PmdtError code: 'image_not_found' message: 'Cannot read image: ' , aPath printString ].
	sha := (SHA256 hashMessage: bytes) hex.
	^ self decodeBytes: bytes sha256: sha
]

{ #category : 'decoding' }
PmdtPngDecoder class >> decodeBytes: bytes sha256: aString [
	| position header idat palette transparency physUnit physX physY sawIhdr sawIend |
	(bytes size < 8 or: [ (bytes copyFrom: 1 to: 8) ~= #(137 80 78 71 13 10 26 10) asByteArray ])
		ifTrue: [ PmdtError code: 'not_a_png' message: 'The file does not have a PNG signature' ].
	position := 9.
	idat := OrderedCollection new.
	sawIhdr := false.
	sawIend := false.
	[ position <= bytes size ] whileTrue: [
		| length type dataStart data end crc computed |
		length := self uint32At: position in: bytes.
		(position + 11) > bytes size
			ifTrue: [ PmdtError code: 'truncated_png' message: 'PNG chunk header is truncated' ].
		type := (bytes copyFrom: position + 4 to: position + 7) asString.
		dataStart := position + 8.
		end := dataStart + length - 1.
		end > bytes size
			ifTrue: [ PmdtError code: 'truncated_png' message: 'PNG chunk data is truncated' ].
		(end + 4) > bytes size
			ifTrue: [ PmdtError code: 'truncated_png' message: 'PNG chunk CRC is truncated' ].
		data := bytes copyFrom: dataStart to: end.
		crc := self uint32At: end + 1 in: bytes.
		computed := CRC crc32FromCollection: (bytes copyFrom: position + 4 to: end).
		crc = computed
			ifFalse: [ PmdtError code: 'crc_mismatch' message: 'PNG chunk CRC mismatch for ' , type ].
		type = 'IHDR' ifTrue: [
			sawIhdr := true.
			header := self decodeHeader: data ].
		type = 'PLTE' ifTrue: [ palette := self decodePalette: data ].
		type = 'tRNS' ifTrue: [ transparency := data ].
		type = 'pHYs' ifTrue: [
			(length ~= 9)
				ifTrue: [ PmdtError code: 'invalid_chunk' message: 'pHYs must contain nine bytes' ].
			physX := self uint32At: 1 in: data.
			physY := self uint32At: 5 in: data.
			physUnit := data at: 9 ].
		type = 'IDAT' ifTrue: [ idat add: data ].
		type = 'IEND' ifTrue: [ sawIend := true ].
		(self isCritical: type)
			ifTrue: [
				(#('IHDR' 'PLTE' 'IDAT' 'IEND') includes: type)
					ifFalse: [ PmdtError code: 'invalid_chunk' message: 'Unknown critical PNG chunk: ' , type ] ].
		position := end + 5.
		sawIend ifTrue: [ position := bytes size + 1 ] ].
	sawIhdr
		ifFalse: [ PmdtError code: 'truncated_png' message: 'PNG has no IHDR chunk' ].
	sawIend
		ifFalse: [ PmdtError code: 'truncated_png' message: 'PNG has no IEND chunk' ].
	header
		palette: palette;
		transparency: transparency;
		physX: physX;
		physY: physY;
		physUnit: physUnit.
	^ self decodeImage: bytes header: header idat: idat sha256: aString
]

{ #category : 'private' }
PmdtPngDecoder class >> decodeHeader: data [
	| width height bitDepth colorType compression filter interlace |
	data size = 13
		ifFalse: [ PmdtError code: 'invalid_chunk' message: 'IHDR must contain thirteen bytes' ].
	width := self uint32At: 1 in: data.
	height := self uint32At: 5 in: data.
	bitDepth := data at: 9.
	colorType := data at: 10.
	compression := data at: 11.
	filter := data at: 12.
	interlace := data at: 13.
	(width > 0 and: [ height > 0 ])
		ifFalse: [ PmdtError code: 'invalid_chunk' message: 'PNG dimensions must be positive' ].
	bitDepth = 8
		ifFalse: [ PmdtError code: 'unsupported_bit_depth' message: 'Only 8-bit PNGs are supported' ].
	(#(0 2 3 4 6) includes: colorType)
		ifFalse: [ PmdtError code: 'unsupported_color_type' message: 'Unsupported PNG colour type' ].
	compression = 0
		ifFalse: [ PmdtError code: 'unsupported_color_type' message: 'Unsupported PNG compression method' ].
	filter = 0
		ifFalse: [ PmdtError code: 'unsupported_color_type' message: 'Unsupported PNG filter method' ].
	interlace = 0
		ifFalse: [ PmdtError code: 'unsupported_interlace' message: 'Adam7 interlacing is not supported' ].
	^ PmdtPngHeader
		width: width
		height: height
		bitDepth: bitDepth
		colorType: colorType
		interlace: interlace
]

{ #category : 'private' }
PmdtPngDecoder class >> decodePalette: data [
	| entries |
	(data size \\ 3) = 0
		ifFalse: [ PmdtError code: 'invalid_chunk' message: 'PLTE length must be a multiple of three' ].
	entries := Array new: data size // 3.
	1 to: entries size do: [ :i |
		| base |
		base := (i - 1) * 3 + 1.
		entries at: i put: { data at: base . data at: base + 1 . data at: base + 2 } ].
	^ entries
]

{ #category : 'private' }
PmdtPngDecoder class >> decodeImage: bytes header: header idat: idat sha256: aString [
	| raw rowBytes expected filterBytes decoded rgba channels bpp |
	idat isEmpty
		ifTrue: [ PmdtError code: 'truncated_png' message: 'PNG contains no IDAT data' ].
	channels := self channelsForColorType: header colorType.
	bpp := channels.
	rowBytes := header width * channels.
	expected := header height * (rowBytes + 1).
	raw := [ (ZLibReadStream on: (self concatenate: idat)) upToEnd ]
		on: Error
		do: [ :error | PmdtError code: 'decompression_failed' message: 'PNG IDAT decompression failed' ].
	raw size < expected
		ifTrue: [ PmdtError code: 'decompression_failed' message: 'PNG IDAT data is shorter than expected' ].
	raw size > expected
		ifTrue: [ PmdtError code: 'trailing_idat_data' message: 'PNG IDAT data is longer than expected' ].
	decoded := self unfilter: raw width: header width height: header height bpp: bpp rowBytes: rowBytes.
	rgba := self expand: decoded header: header width: header width height: header height.
	^ PmdtRgbaImage
		width: header width
		height: header height
		pixels: rgba
		header: header
		sha256: aString
]

{ #category : 'private' }
PmdtPngDecoder class >> unfilter: raw width: width height: height bpp: bpp rowBytes: rowBytes [
	| output previous rowStart |
	output := ByteArray new: height * rowBytes.
	previous := ByteArray new: rowBytes.
	0 to: height - 1 do: [ :y |
		| filter source target left up upperLeft predictor |
		rowStart := y * (rowBytes + 1) + 1.
		filter := raw at: rowStart.
		source := rowStart + 1.
		target := y * rowBytes + 1.
		1 to: rowBytes do: [ :i |
			| value rawValue |
			rawValue := raw at: source + i - 1.
			left := i > bpp ifTrue: [ output at: target + i - 1 - bpp ] ifFalse: [ 0 ].
			up := y > 0 ifTrue: [ previous at: i ] ifFalse: [ 0 ].
			upperLeft := (i > bpp and: [ y > 0 ]) ifTrue: [ previous at: i - bpp ] ifFalse: [ 0 ].
			filter = 0 ifTrue: [ value := rawValue ].
			filter = 1 ifTrue: [ value := rawValue + left ].
			filter = 2 ifTrue: [ value := rawValue + up ].
			filter = 3 ifTrue: [ value := rawValue + ((left + up) // 2) ].
			filter = 4 ifTrue: [
				predictor := self paethLeft: left above: up upperLeft: upperLeft.
				value := rawValue + predictor ].
			filter > 4
				ifTrue: [ PmdtError code: 'invalid_chunk' message: 'Unsupported PNG filter type' ].
			output at: target + i - 1 put: (value bitAnd: 255) ].
		previous := output copyFrom: target to: target + rowBytes - 1 ].
	^ output
]

{ #category : 'private' }
PmdtPngDecoder class >> expand: decoded header: header width: width height: height [
	| output channels transparency colorType |
	channels := self channelsForColorType: header colorType.
	colorType := header colorType.
	transparency := header transparency.
	output := ByteArray new: width * height * 4.
	0 to: height - 1 do: [ :y |
		0 to: width - 1 do: [ :x |
			| source index r g b a |
			source := y * width * channels + (x * channels) + 1.
			index := ((y * width) + x) * 4 + 1.
			colorType = 0 ifTrue: [
				r := decoded at: source.
				g := r.
				b := r.
				a := 255.
				(transparency notNil and: [ transparency size >= 2 and: [ r = (self uint16At: 1 in: transparency) ] ])
					ifTrue: [ a := 0 ] ].
			colorType = 2 ifTrue: [
				r := decoded at: source.
				g := decoded at: source + 1.
				b := decoded at: source + 2.
				a := 255.
				(transparency notNil and: [ transparency size >= 6 and: [
					r = (self uint16At: 1 in: transparency) and: [
						g = (self uint16At: 3 in: transparency) and: [
							b = (self uint16At: 5 in: transparency) ] ] ] ])
					ifTrue: [ a := 0 ] ].
			colorType = 3 ifTrue: [
				| paletteIndex entry |
				paletteIndex := (decoded at: source) + 1.
				entry := header palette at: paletteIndex ifAbsent: [ nil ].
				entry ifNil: [ PmdtError code: 'invalid_chunk' message: 'Palette index is out of range' ].
				r := entry at: 1.
				g := entry at: 2.
				b := entry at: 3.
				a := transparency notNil
					ifTrue: [ transparency at: paletteIndex ifAbsent: [ 255 ] ]
					ifFalse: [ 255 ] ].
			colorType = 4 ifTrue: [
				r := decoded at: source.
				g := r.
				b := r.
				a := decoded at: source + 1 ].
			colorType = 6 ifTrue: [
				r := decoded at: source.
				g := decoded at: source + 1.
				b := decoded at: source + 2.
				a := decoded at: source + 3 ].
			output at: index put: r.
			output at: index + 1 put: g.
			output at: index + 2 put: b.
			output at: index + 3 put: a ] ].
	^ output
]

{ #category : 'private' }
PmdtPngDecoder class >> channelsForColorType: aNumber [
	aNumber = 0 ifTrue: [ ^ 1 ].
	aNumber = 2 ifTrue: [ ^ 3 ].
	aNumber = 3 ifTrue: [ ^ 1 ].
	aNumber = 4 ifTrue: [ ^ 2 ].
	aNumber = 6 ifTrue: [ ^ 4 ].
	PmdtError code: 'unsupported_color_type' message: 'Unsupported PNG colour type'
]

{ #category : 'private' }
PmdtPngDecoder class >> paethLeft: left above: above upperLeft: upperLeft [
	| p pLeft pAbove pUpperLeft |
	p := left + above - upperLeft.
	pLeft := p - left abs.
	pAbove := p - above abs.
	pUpperLeft := p - upperLeft abs.
	(pLeft <= pAbove and: [ pLeft <= pUpperLeft ]) ifTrue: [ ^ left ].
	(pAbove <= pUpperLeft) ifTrue: [ ^ above ].
	^ upperLeft
]

{ #category : 'private' }
PmdtPngDecoder class >> isCritical: aString [
	^ aString first isUppercase
]

{ #category : 'private' }
PmdtPngDecoder class >> concatenate: aCollection [
	| size output position |
	size := aCollection inject: 0 into: [ :sum :each | sum + each size ].
	output := ByteArray new: size.
	position := 1.
	aCollection do: [ :each |
		output replaceFrom: position to: position + each size - 1 with: each.
		position := position + each size ].
	^ output
]

{ #category : 'private' }
PmdtPngDecoder class >> uint16At: anInteger in: bytes [
	^ ((bytes at: anInteger) bitShift: 8) + (bytes at: anInteger + 1)
]

{ #category : 'private' }
PmdtPngDecoder class >> uint32At: anInteger in: bytes [
	^ ((bytes at: anInteger) bitShift: 24)
		+ ((bytes at: anInteger + 1) bitShift: 16)
		+ ((bytes at: anInteger + 2) bitShift: 8)
		+ (bytes at: anInteger + 3)
]
