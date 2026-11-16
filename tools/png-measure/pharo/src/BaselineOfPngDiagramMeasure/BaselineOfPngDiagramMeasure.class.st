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
			baseline: 'Dskt' with: [
				spec repository: 'tonel://' , (FileSystem workingDirectory / 'tools' / 'dskt' / 'pharo' / 'src') pathString ].
		spec
			package: 'PngDiagramMeasure-Core' with: [
				spec requires: #( 'Dskt' ) ];
			package: 'PngDiagramMeasure-Tests' with: [
				spec requires: #( 'PngDiagramMeasure-Core' ) ].
		spec
			group: 'Core' with: #( 'PngDiagramMeasure-Core' );
			group: 'Tests' with: #( 'PngDiagramMeasure-Tests' );
			group: 'all' with: #( 'PngDiagramMeasure-Core' 'PngDiagramMeasure-Tests' );
			group: 'default' with: #( 'PngDiagramMeasure-Core' ) ]
]
