"
I am the PNG domain route provider for the shared DsktServer.

I install the existing /png/* routes directly on the common server and report the
PNG measurement health. I hold the PNG measurement service but no HTTP, envelope,
trace, or lifecycle logic.
"
Class {
	#name : 'PngMeasureRouteProvider',
	#superclass : 'DsktRouteProvider',
	#instVars : [
		'service'
	],
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'instance creation' }
PngMeasureRouteProvider class >> default [
	^ self new
]

{ #category : 'initialization' }
PngMeasureRouteProvider class >> initialize [
	DsktRouteRegistry register: self new
]

{ #category : 'initialization' }
PngMeasureRouteProvider >> initialize [
	super initialize
]

{ #category : 'accessing' }
PngMeasureRouteProvider >> name [ ^ 'png' ]
{ #category : 'accessing' }
PngMeasureRouteProvider >> service [
	^ service ifNil: [ service := PngMeasureService default ]
]
{ #category : 'accessing' }
PngMeasureRouteProvider >> service: anObject [ service := anObject ]

{ #category : 'routes' }
PngMeasureRouteProvider >> installRoutesOn: server [
	server teapot
		GET: '/png/health' -> [ :request | server handleHealth: 'png' request: request ];
		GET: '/png/trace' -> [ :request | server handleTrace: request ];
		POST: '/png/inspect_image' -> [ :request | server handleOperation: 'png_inspect_image' selector: #inspectImage: request: request service: self service details: [ :result | self traceDetailsFor: result request: request ] ];
		POST: '/png/make_ink_mask' -> [ :request | server handleOperation: 'png_make_ink_mask' selector: #makeInkMask: request: request service: self service details: [ :result | self traceDetailsFor: result request: request ] ];
		POST: '/png/measure_bounds' -> [ :request | server handleOperation: 'png_measure_bounds' selector: #measureBounds: request: request service: self service details: [ :result | self traceDetailsFor: result request: request ] ];
		POST: '/png/measure_regions' -> [ :request | server handleOperation: 'png_measure_regions' selector: #measureRegions: request: request service: self service details: [ :result | self traceDetailsFor: result request: request ] ];
		POST: '/png/normalize_geometry' -> [ :request | server handleOperation: 'png_normalize_geometry' selector: #normalizeGeometry: request: request service: self service details: [ :result | self traceDetailsFor: result request: request ] ];
		POST: '/png/create_baseline' -> [ :request | server handleOperation: 'png_create_baseline' selector: #createBaseline: request: request service: self service details: [ :result | self traceDetailsFor: result request: request ] ]
]

{ #category : 'health' }
PngMeasureRouteProvider >> health [
	| repository |
	repository := self service repository.
	^ Dictionary new
		at: 'status' put: 'ok';
		at: 'output_root' put: PngMeasureSettings outputRoot;
		at: 'cache' put: (Dictionary new
			at: 'images' put: repository imageCount;
			at: 'masks' put: repository maskCount;
			yourself);
		yourself
]

{ #category : 'status' }
PngMeasureRouteProvider >> statusFor: code [
	^ (#('invalid_request' 'path_outside_repo' 'unknown_basis' 'invalid_region' 'sha_mismatch' 'output_path_rejected' 'image_too_large') includes: code)
		ifTrue: [ 400 ]
		ifFalse: [
			(#('image_not_found') includes: code)
				ifTrue: [ 404 ]
				ifFalse: [
					(#('not_a_png' 'truncated_png' 'invalid_chunk' 'crc_mismatch' 'unsupported_bit_depth' 'unsupported_interlace' 'unsupported_color_type' 'decompression_failed' 'trailing_idat_data') includes: code)
						ifTrue: [ 422 ]
						ifFalse: [ 500 ] ] ]
]

{ #category : 'private' }
PngMeasureRouteProvider >> traceDetailsFor: result request: request [
	| image regions |
	image := (result isKindOf: Dictionary) ifTrue: [ result at: 'image' ifAbsent: [ nil ] ] ifFalse: [ nil ].
	regions := (result isKindOf: Dictionary) ifTrue: [ result at: 'regions' ifAbsent: [ nil ] ] ifFalse: [ nil ].
	^ Dictionary new
		at: 'image_path' put: (request at: 'image_path' ifAbsent: [ nil ]);
		at: 'image_sha256' put: ((image isKindOf: Dictionary) ifTrue: [ image at: 'sha256' ifAbsent: [ nil ] ] ifFalse: [ request at: 'image_sha256' ifAbsent: [ nil ] ]);
		at: 'region_count' put: ((regions isKindOf: Dictionary) ifTrue: [ regions size ] ifFalse: [ 0 ]);
		at: 'empty_region_count' put: ((regions isKindOf: Dictionary) ifTrue: [ regions values count: [ :each | (each at: 'status' ifAbsent: [ '' ]) = 'empty' ] ] ifFalse: [ 0 ]);
		at: 'output_written' put: ((result isKindOf: Dictionary) and: [ (result includesKey: 'mask_path') or: [ result includesKey: 'baseline_sha256' ] ]);
		yourself
]
