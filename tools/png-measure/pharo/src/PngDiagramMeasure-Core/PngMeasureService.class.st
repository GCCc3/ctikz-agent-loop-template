"
I am the measurement facade used by the HTTP server.

I decode and cache images, build ink masks, measure bounds and regions, and convert geometry.
"
Class {
	#name : 'PngMeasureService',
	#superclass : 'Object',
	#instVars : [
		'repository'
	],
	#classVars : [
		'Default'
	],
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'instance creation' }
PngMeasureService class >> default [
	^ Default ifNil: [ Default := self new ]
]

{ #category : 'initialization' }
PngMeasureService >> initialize [
	super initialize.
	repository := PmdtImageRepository default
]

{ #category : 'accessing' }
PngMeasureService >> repository [ ^ repository ]

{ #category : 'accessing' }
PngMeasureService >> repository: anObject [ repository := anObject ]

{ #category : 'operations' }
PngMeasureService >> inspectImage: request [
	| image warnings resolution |
	image := self imageFor: request.
	warnings := OrderedCollection new.
	resolution := Dictionary new.
	(image header dpiX isNil or: [ image header dpiY isNil ])
		ifTrue: [
			resolution at: 'dpi_x' put: nil; at: 'dpi_y' put: nil; at: 'source' put: 'unknown'.
			warnings add: (self warning: 'dpi_unknown' message: 'The PNG does not provide physical resolution metadata') ]
		ifFalse: [
			resolution
				at: 'dpi_x' put: image header dpiX;
				at: 'dpi_y' put: image header dpiY;
				at: 'source' put: 'metadata' ].
	^ Dictionary new
		at: 'image' put: (self imageDictionaryFor: image request: request);
		at: 'resolution' put: resolution;
		at: 'warnings' put: warnings asArray;
		yourself
]

{ #category : 'operations' }
PngMeasureService >> makeInkMask: request [
	| image parameters mask warnings maskBytes maskPath maskSha base thresholdText backgroundText |
	image := self imageFor: request.
	parameters := self maskParametersFor: request.
	mask := self maskFor: image parameters: parameters.
	warnings := self maskWarningsFor: image mask: mask.
	maskBytes := PmdtPngWriter encodeMask: mask.
	maskSha := (SHA256 hashMessage: maskBytes) hex.
	base := self safeBaseNameFor: (self imagePathFor: request).
	thresholdText := self canonicalNumber: parameters threshold.
	backgroundText := parameters background copyReplaceAll: '#' with: ''.
	maskPath := (self outputDirectory: request) / (base , '.ink-mask.' , (maskSha copyFrom: 1 to: 12) , '.' , parameters method , '.' , thresholdText , '.' , backgroundText , '.png').
	self writeBytes: maskBytes to: maskPath request: request.
	^ Dictionary new
		at: 'mask_id' put: ('mask-' , (image sha256 copyFrom: 1 to: 12) , '-' , parameters method , '-' , thresholdText , '-' , backgroundText);
		at: 'mask_path' put: maskPath pathString;
		at: 'mask_sha256' put: maskSha;
		at: 'mask_format' put: 'png';
		at: 'mask_encoding' put: (Dictionary new at: 'ink' put: 0; at: 'background' put: 255; yourself);
		at: 'method' put: parameters method;
		at: 'threshold' put: parameters threshold;
		at: 'background' put: parameters background;
		at: 'ink_pixel_count' put: mask inkCount;
		at: 'ink_fraction' put: mask inkFraction;
		at: 'ink_bbox_px' put: (mask primaryBoundingBox ifNil: [ nil ] ifNotNil: [ :box | box asArray ]);
		at: 'bbox_sensitivity' put: (self boxesDictionary: mask boundingBoxes);
		at: 'warnings' put: warnings;
		yourself
]

{ #category : 'operations' }
PngMeasureService >> measureBounds: request [
	| image parameters mask dpi warnings result |
	image := self imageFor: request.
	parameters := self maskParametersFor: request.
	mask := self maskFor: image parameters: parameters.
	dpi := self dpiFor: image request: request.
	warnings := OrderedCollection new.
	result := PmdtBoundsMeasurer
		measure: image
		mask: mask
		dpiX: (dpi at: 1)
		dpiY: (dpi at: 2)
		source: (dpi at: 3).
	result at: 'warnings' put: ((result at: 'warnings') , warnings) asArray.
	^ result
]

{ #category : 'operations' }
PngMeasureService >> measureRegions: request [
	| image parameters mask regions units result |
	image := self imageFor: request.
	parameters := self maskParametersFor: request.
	mask := self maskFor: image parameters: parameters.
	regions := request at: 'regions' ifAbsent: [ DsktError code: 'invalid_request' message: 'regions is required' ].
	(regions isKindOf: Dictionary)
		ifFalse: [ DsktError code: 'invalid_request' message: 'regions must be an object' ].
	units := request at: 'region_units' ifAbsent: [ 'normalized_ink' ].
	(units = 'image_pixels')
		ifTrue: [
			| expected |
			expected := request at: 'image_sha256' ifAbsent: [ DsktError code: 'invalid_request' message: 'image_sha256 is required for image_pixels regions' ].
			expected = image sha256
				ifFalse: [ DsktError code: 'sha_mismatch' message: 'image_sha256 does not match the decoded image' ] ].
	result := PmdtRegionMeasurer measure: image mask: mask regions: regions units: units.
	^ result
]

{ #category : 'operations' }
PngMeasureService >> normalizeGeometry: request [
	| image parameters mask geometry from to dpi |
	image := self imageFor: request.
	parameters := self maskParametersFor: request.
	mask := self maskFor: image parameters: parameters.
	geometry := request at: 'geometry' ifAbsent: [ DsktError code: 'invalid_request' message: 'geometry is required' ].
	from := request at: 'from' ifAbsent: [ DsktError code: 'invalid_request' message: 'from is required' ].
	to := request at: 'to' ifAbsent: [ DsktError code: 'invalid_request' message: 'to is required' ].
	dpi := self dpiFor: image request: request.
	^ PmdtGeometryConverter
		convert: geometry
		from: from
		to: to
		image: image
		mask: mask
		dpiX: (dpi at: 1)
		dpiY: (dpi at: 2)
]

{ #category : 'private' }
PngMeasureService >> imageFor: request [
	| path bytes sha image cache |
	path := self imageAbsolutePathFor: request.
	bytes := [ path asFileReference binaryReadStreamDo: [ :stream | stream upToEnd ] ]
		on: Error
		do: [ :error | DsktError code: 'image_not_found' message: 'Cannot read image: ' , path ].
	sha := (SHA256 hashMessage: bytes) hex.
	cache := repository imageForSha: sha ifAbsent: [ nil ].
	cache ifNotNil: [ ^ cache ].
	image := PmdtPngDecoder decodeBytes: bytes sha256: sha.
	(image width * image height) > PngMeasureSettings maxPixels
		ifTrue: [ DsktError code: 'image_too_large' message: 'The image exceeds the configured pixel limit' ].
	repository putImage: image.
	^ image
]

{ #category : 'private' }
PngMeasureService >> maskFor: image parameters: parameters [
	| cache |
	cache := repository
		maskForSha: image sha256
		key: parameters cacheKey
		ifAbsent: [ nil ].
	cache ifNotNil: [ ^ cache ].
	cache := PmdtLuminanceClassifier maskFor: image parameters: parameters.
	repository putMask: cache sha: image sha256.
	^ cache
]

{ #category : 'private' }
PngMeasureService >> imageAbsolutePathFor: request [
	| path resolved |
	path := request at: 'image_abs_path' ifAbsent: [ nil ].
	path ifNil: [ path := request at: 'image_path' ifAbsent: [ DsktError code: 'invalid_request' message: 'image_abs_path is required' ] ].
	path := path asString.
	resolved := DsktPathResolver resolveExisting: path under: PngMeasureSettings repoRoot.
	resolved isFile
		ifFalse: [ DsktError code: 'image_not_found' message: 'Image is not a regular file: ' , path ].
	^ resolved pathString
]

{ #category : 'private' }
PngMeasureService >> imagePathFor: request [
	^ request at: 'image_path' ifAbsent: [ (request at: 'image_abs_path' ifAbsent: [ '' ]) ]
]

{ #category : 'private' }
PngMeasureService >> imageDictionaryFor: image request: request [
	^ Dictionary new
		at: 'path' put: (self imagePathFor: request);
		at: 'sha256' put: image sha256;
		at: 'width_px' put: image width;
		at: 'height_px' put: image height;
		at: 'bit_depth' put: image header bitDepth;
		at: 'colour_type' put: image header colorTypeName;
		at: 'has_alpha' put: image header hasAlpha;
		at: 'interlaced' put: image header isInterlaced;
		yourself
]

{ #category : 'private' }
PngMeasureService >> maskParametersFor: request [
	| mask top |
	mask := request at: 'mask' ifAbsent: [ nil ].
	mask ifNotNil: [ ^ PmdtMaskParameters fromDictionary: mask ].
	top := Dictionary new.
	#('background' 'method' 'threshold' 'sensitivity_thresholds') do: [ :key |
		(request at: key ifAbsent: [ nil ]) ifNotNil: [ :value | top at: key put: value ] ].
	^ PmdtMaskParameters fromDictionary: top
]

{ #category : 'private' }
PngMeasureService >> dpiFor: image request: request [
	| override x y |
	override := request at: 'dpi_override' ifAbsent: [ nil ].
	override ifNotNil: [
		x := (override at: 'x' ifAbsent: [ nil ]) ifNotNil: [ :value | value asFloat ].
		y := (override at: 'y' ifAbsent: [ nil ]) ifNotNil: [ :value | value asFloat ].
		(x notNil and: [ y notNil and: [ x > 0 and: [ y > 0 ] ] ])
			ifTrue: [ ^ { x . y . 'override' } ] ].
	^ { image header dpiX . image header dpiY . (image header dpiX isNil ifTrue: [ 'unknown' ] ifFalse: [ 'metadata' ]) }
]

{ #category : 'private' }
PngMeasureService >> maskWarningsFor: image mask: mask [
	| warnings parameters bbox maxSensitivity limit |
	warnings := OrderedCollection new.
	parameters := mask parameters.
	mask inkCount = 0 ifTrue: [ warnings add: (self warning: 'no_ink' message: 'No ink was found in the image') ].
	mask inkFraction > 0.9 ifTrue: [ warnings add: (self warning: 'mostly_ink' message: 'Most of the image is classified as ink') ].
	mask inkFraction > 0.5 ifTrue: [ warnings add: (self warning: 'threshold_unsuitable' message: 'The selected threshold may be unsuitable for this image') ].
	bbox := mask primaryBoundingBox.
	bbox ifNotNil: [
		maxSensitivity := 0.
		mask boundingBoxes valuesDo: [ :box |
			box ifNotNil: [
				maxSensitivity := maxSensitivity max: (bbox x0 - box x0) abs.
				maxSensitivity := maxSensitivity max: (bbox y0 - box y0) abs.
				maxSensitivity := maxSensitivity max: (bbox x1 - box x1) abs.
				maxSensitivity := maxSensitivity max: (bbox y1 - box y1) abs ] ].
		limit := 2 max: (0.005 * (image width max: image height)).
		maxSensitivity > limit ifTrue: [ warnings add: (self warning: 'bbox_unstable' message: 'The ink bounding box changes materially across sensitivity thresholds') ] ].
	(self backgroundIsLight: parameters)
		ifFalse: [ warnings add: (self warning: 'background_not_light' message: 'The background is not predominantly light') ].
	^ warnings asArray
]

{ #category : 'private' }
PngMeasureService >> backgroundIsLight: parameters [
	| rgb |
	rgb := parameters backgroundRgb.
	^ ((0.2126 * (rgb at: 1)) + (0.7152 * (rgb at: 2)) + (0.0722 * (rgb at: 3))) / 255 > 0.5
]

{ #category : 'private' }
PngMeasureService >> warning: code message: message [
	^ Dictionary new at: 'code' put: code; at: 'message' put: message; at: 'details' put: Dictionary new; yourself
]

{ #category : 'private' }
PngMeasureService >> boxesDictionary: aDictionary [
	| result |
	result := Dictionary new.
	aDictionary keysAndValuesDo: [ :key :box |
		result at: key put: (box ifNil: [ nil ] ifNotNil: [ :each | each asArray ]) ].
	^ result
]

{ #category : 'private' }
PngMeasureService >> canonicalNumber: aNumber [
	^ DsktCanonicalJson toString: aNumber
]

{ #category : 'private' }
PngMeasureService >> safeBaseNameFor: aPath [
	| name sanitized |
	name := aPath asString.
	name := name asFileReference basename.
	name := name copyReplaceAll: '.png' with: ''.
	sanitized := name select: [ :each | each isAlphaNumeric or: [ each = $_ or: [ each = $- ] ] ].
	^ sanitized isEmpty ifTrue: [ 'image' ] ifFalse: [ sanitized ]
]

{ #category : 'private' }
PngMeasureService >> outputDirectory: request [
	| configured root |
	configured := PngMeasureSettings outputRoot.
	root := DsktPathResolver
		resolveWritable: (request at: 'output_root' ifAbsent: [ configured ])
		under: configured.
	root ensureCreateDirectory.
	^ root
]

{ #category : 'private' }
PngMeasureService >> writeBytes: bytes to: aFileReference request: request [
	| root temp destination |
	root := self outputDirectory: request.
	destination := DsktPathResolver resolveWritable: aFileReference under: root.
	temp := destination parent / (destination basename , '.tmp').
	temp binaryWriteStreamDo: [ :stream | stream nextPutAll: bytes ].
	destination exists ifTrue: [ destination delete ].
	temp renameTo: destination pathString
]
