"
I describe the PngDiagramMeasure project and its external dependencies.
"
Class {
	#name : 'BaselineOfPngDiagramMeasure',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfPngDiagramMeasure',
	#package : 'BaselineOfPngDiagramMeasure'
}

{ #category : 'baselines' }
BaselineOfPngDiagramMeasure >> baseline: spec [
	<baseline>
	spec for: #common do: [
		spec
			baseline: 'NeoJSON' with: [
				spec repository: 'github://svenvc/NeoJSON:master/repository' ];
			baseline: 'Teapot' with: [
				spec
					repository: 'github://zeroflag/Teapot:master/source';
					loads: #( 'Deployment' ) ].
		spec
			package: 'PngDiagramMeasure-Core' with: [
				spec requires: #( 'NeoJSON' 'Teapot' ) ];
			package: 'PngDiagramMeasure-Tests' with: [
				spec requires: #( 'PngDiagramMeasure-Core' ) ].
		spec
			group: 'Core' with: #( 'PngDiagramMeasure-Core' );
			group: 'Tests' with: #( 'PngDiagramMeasure-Tests' );
			group: 'all' with: #( 'PngDiagramMeasure-Core' 'PngDiagramMeasure-Tests' );
			group: 'default' with: #( 'PngDiagramMeasure-Core' ) ]
]
