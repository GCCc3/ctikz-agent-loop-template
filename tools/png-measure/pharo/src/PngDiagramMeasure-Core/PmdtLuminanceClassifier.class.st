"
I classify visible pixels as ink or background using alpha compositing and integer luminance.

I compute the primary binary mask and full-image bounding boxes for every sensitivity threshold in one pass.
"
Class {
	#name : 'PmdtLuminanceClassifier',
	#superclass : 'Object',
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'classification' }
PmdtLuminanceClassifier class >> maskFor: aPmdtRgbaImage parameters: aPmdtMaskParameters [
	| width height src thresholds count primaryLimit mask primaryIndex minsX minsY maxsX maxsY boxes bg |
	width := aPmdtRgbaImage width.
	height := aPmdtRgbaImage height.
	src := aPmdtRgbaImage pixels.
	thresholds := aPmdtMaskParameters thresholds asArray.
	count := thresholds size.
	primaryLimit := aPmdtMaskParameters threshold * 2550000.
	primaryIndex := thresholds indexOf: aPmdtMaskParameters threshold.
	mask := ByteArray new: width * height withAll: 255.
	minsX := Array new: count withAll: width.
	minsY := Array new: count withAll: height.
	maxsX := Array new: count withAll: -1.
	maxsY := Array new: count withAll: -1.
	bg := aPmdtMaskParameters backgroundRgb.
	0 to: height - 1 do: [ :y |
		0 to: width - 1 do: [ :x |
			| index r g b a score |
			index := ((y * width) + x) * 4 + 1.
			r := src at: index.
			g := src at: index + 1.
			b := src at: index + 2.
			a := src at: index + 3.
			a = 255
				ifFalse: [
					r := (r * a + ((bg at: 1) * (255 - a))) // 255.
					g := (g * a + ((bg at: 2) * (255 - a))) // 255.
					b := (b * a + ((bg at: 3) * (255 - a))) // 255 ].
			score := 2126 * r + (7152 * g) + (722 * b).
			score < primaryLimit ifTrue: [ mask at: (y * width) + x + 1 put: 0 ].
			1 to: count do: [ :i |
				| threshold |
				threshold := thresholds at: i.
				score < (threshold * 2550000) ifTrue: [
					x < (minsX at: i) ifTrue: [ minsX at: i put: x ].
					y < (minsY at: i) ifTrue: [ minsY at: i put: y ].
					x > (maxsX at: i) ifTrue: [ maxsX at: i put: x ].
					y > (maxsY at: i) ifTrue: [ maxsY at: i put: y ] ] ] ] ].
	boxes := Dictionary new.
	1 to: count do: [ :i |
		| box |
		box := (maxsX at: i) < 0
			ifTrue: [ nil ]
			ifFalse: [
				PmdtBBox
					x0: (minsX at: i)
					y0: (minsY at: i)
					x1: (maxsX at: i) + 1
					y1: (maxsY at: i) + 1 ].
		boxes
			at: (PmdtCanonicalJson toString: (thresholds at: i))
			put: box ].
	^ PmdtInkMask
		width: width
		height: height
		pixels: mask
		parameters: aPmdtMaskParameters
		boundingBoxes: boxes
]

{ #category : 'classification' }
PmdtLuminanceClassifier class >> boundingBoxIn: aPmdtRgbaImage x0: anInteger y0: anInteger2 x1: anInteger3 y1: anInteger4 threshold: aNumber backgroundRgb: background [
	| width src minX minY maxX maxY bg limit |
	width := aPmdtRgbaImage width.
	src := aPmdtRgbaImage pixels.
	bg := background.
	limit := aNumber * 2550000.
	minX := anInteger3.
	minY := anInteger4.
	maxX := -1.
	maxY := -1.
	anInteger2 to: anInteger4 - 1 do: [ :y |
		anInteger to: anInteger3 - 1 do: [ :x |
			| index r g b a score |
			index := ((y * width) + x) * 4 + 1.
			r := src at: index.
			g := src at: index + 1.
			b := src at: index + 2.
			a := src at: index + 3.
			a = 255
				ifFalse: [
					r := (r * a + ((bg at: 1) * (255 - a))) // 255.
					g := (g * a + ((bg at: 2) * (255 - a))) // 255.
					b := (b * a + ((bg at: 3) * (255 - a))) // 255 ].
			score := 2126 * r + (7152 * g) + (722 * b).
			score < limit ifTrue: [
				x < minX ifTrue: [ minX := x ].
				y < minY ifTrue: [ minY := y ].
				x > maxX ifTrue: [ maxX := x ].
				y > maxY ifTrue: [ maxY := y ] ] ] ].
	^ maxX < 0
		ifTrue: [ nil ]
		ifFalse: [ PmdtBBox x0: minX y0: minY x1: maxX + 1 y1: maxY + 1 ]
]
