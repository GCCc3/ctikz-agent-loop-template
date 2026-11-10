"
I test masking, bounds, regions, geometry conversion, and baseline assembly on a synthetic image.
"
Class {
	#name : 'PmdtMeasurementTest',
	#superclass : 'TestCase',
	#category : 'PngDiagramMeasure-Tests',
	#package : 'PngDiagramMeasure-Tests'
}

{ #category : 'fixtures' }
PmdtMeasurementTest >> image [
	^ PmdtTestFixture imageWithBlackBox
]

{ #category : 'fixtures' }
PmdtMeasurementTest >> parameters [
	^ PmdtMaskParameters fromDictionary: (Dictionary new
		at: 'background' put: '#ffffff';
		at: 'threshold' put: 0.5;
		at: 'sensitivity_thresholds' put: #(0.25 0.5 0.75);
		yourself)
]

{ #category : 'tests' }
PmdtMeasurementTest >> testMaskAndBounds [
	| image mask bounds |
	image := self image.
	mask := PmdtLuminanceClassifier maskFor: image parameters: self parameters.
	self assert: mask inkCount equals: 36.
	self assert: mask primaryBoundingBox asArray equals: #(2 2 8 8).
	self assert: mask inkFraction closeTo: 0.36 precision: 0.0001.
	bounds := PmdtBoundsMeasurer
		measure: image
		mask: mask
		dpiX: 100.0
		dpiY: 100.0
		source: 'override'.
	self assert: (bounds at: 'ink_bbox_px') equals: #(2 2 8 8).
	self assert: ((bounds at: 'margins_px') at: 'left') equals: 2.
	self assert: ((bounds at: 'tight_crop') at: 'tightly_cropped') equals: false.
	self assert: (((bounds at: 'tight_crop') at: 'tight_crop_reasons') includes: 'ink bounding-box coverage is below 0.90')
]

{ #category : 'tests' }
PmdtMeasurementTest >> testTransparentPixelIsBackground [
	| image params mask |
	image := PmdtTestFixture
		rgbaImageWidth: 2
		height: 1
		background: #(255 255 255 255)
		rects: { { 0 . 0 . 1 . 1 . #(0 0 0 0) } }.
	params := self parameters.
	mask := PmdtLuminanceClassifier maskFor: image parameters: params.
	self assert: mask inkCount equals: 0.
	self assert: mask primaryBoundingBox isNil
]

{ #category : 'tests' }
PmdtMeasurementTest >> testRegions [
	| image mask result region |
	image := self image.
	mask := PmdtLuminanceClassifier maskFor: image parameters: self parameters.
	result := PmdtRegionMeasurer
		measure: image
		mask: mask
		regions: (Dictionary new at: 'box' put: #(0.2 0.2 0.8 0.8); yourself)
		units: 'normalized_image'.
	region := (result at: 'regions') at: 'box'.
	self assert: (region at: 'status') equals: 'measured'.
	self assert: (region at: 'requested_bbox_px') equals: #(2 2 8 8).
	self assert: (region at: 'tight_bbox_px') equals: #(2 2 8 8).
	self assert: (region at: 'warnings') isEmpty
]

{ #category : 'tests' }
PmdtMeasurementTest >> testGeometryConversion [
	| image mask result |
	image := self image.
	mask := PmdtLuminanceClassifier maskFor: image parameters: self parameters.
	result := PmdtGeometryConverter
		convert: (Dictionary new at: 'type' put: 'point'; at: 'coordinates' put: #(5 5); yourself)
		from: 'image_pixels'
		to: 'normalized_ink'
		image: image
		mask: mask
		dpiX: 100.0
		dpiY: 100.0.
	self assert: (result at: 'geometry' at: 'coordinates') equals: #(0.5 0.5).
	self assert: (result at: 'exact') equals: true.
	self assert: (result at: 'warnings') isEmpty
]

{ #category : 'tests' }
PmdtMeasurementTest >> testBaselineHash [
	| image mask bounds document hashed |
	image := self image.
	mask := PmdtLuminanceClassifier maskFor: image parameters: self parameters.
	bounds := PmdtBoundsMeasurer
		measure: image mask: mask dpiX: nil dpiY: nil source: 'unknown'.
	document := PmdtBaselineBuilder
		buildImage: image
		path: 'fixture.png'
		parameters: self parameters
		mask: mask
		bounds: bounds
		regions: Dictionary new
		regionUnits: 'normalized_ink'
		warnings: #().
	hashed := PmdtBaselineBuilder withHash: document.
	self assert: (hashed at: 'baseline_sha256') size equals: 64.
	self assert: (hashed at: 'image' at: 'sha256') equals: 'fixture'
]
