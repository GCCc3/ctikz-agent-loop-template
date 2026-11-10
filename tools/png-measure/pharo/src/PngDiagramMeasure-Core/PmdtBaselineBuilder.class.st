"
I assemble the deterministic baseline document from the inspect, mask, bounds, and region results.
"
Class {
	#name : 'PmdtBaselineBuilder',
	#superclass : 'Object',
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'building' }
PmdtBaselineBuilder class >> buildImage: aPmdtRgbaImage path: aPath parameters: aPmdtMaskParameters mask: aPmdtInkMask bounds: bounds regions: regions regionUnits: aString warnings: warnings [
	| document |
	document := Dictionary new
		at: 'schema_version' put: PmdtVersion schemaVersion;
		at: 'tool_version' put: PmdtVersion toolVersion;
		at: 'image' put: (Dictionary new
			at: 'path' put: aPath;
			at: 'sha256' put: aPmdtRgbaImage sha256;
			at: 'width_px' put: aPmdtRgbaImage width;
			at: 'height_px' put: aPmdtRgbaImage height;
			yourself);
		at: 'parameters' put: (aPmdtMaskParameters asDictionary
			at: 'region_units' put: aString;
			yourself);
		at: 'mask' put: (Dictionary new
			at: 'ink_pixel_count' put: aPmdtInkMask inkCount;
			at: 'ink_fraction' put: aPmdtInkMask inkFraction;
			at: 'ink_bbox_px' put: (aPmdtInkMask primaryBoundingBox ifNil: [ nil ] ifNotNil: [ :box | box asArray ]);
			at: 'bbox_sensitivity' put: (self boxesDictionary: aPmdtInkMask boundingBoxes);
			yourself);
		at: 'bounds' put: bounds;
		at: 'regions' put: (regions ifNil: [ Dictionary new ]);
		at: 'warnings' put: (warnings ifNil: [ #() ]);
		yourself.
	^ document
]

{ #category : 'building' }
PmdtBaselineBuilder class >> boxesDictionary: aDictionary [
	| result |
	result := Dictionary new.
	aDictionary keysAndValuesDo: [ :key :box |
		result at: key put: (box ifNil: [ nil ] ifNotNil: [ :each | each asArray ]) ].
	^ result
]

{ #category : 'building' }
PmdtBaselineBuilder class >> withHash: aDictionary [
	| document hash |
	document := aDictionary copy.
	hash := (SHA256 hashMessage: (PmdtCanonicalJson toString: document) asByteArray) hex.
	document at: 'baseline_sha256' put: hash.
	^ document
]
