"
I describe the Dskt toolkit project and its external dependencies.
"
Class {
	#name : 'BaselineOfDskt',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfDskt',
	#package : 'BaselineOfDskt'
}

{ #category : 'baselines' }
BaselineOfDskt >> baseline: spec [
	<baseline>
	| requires |
	requires := OrderedCollection new.
	spec for: #common do: [
		(Smalltalk includesKey: #NeoJSONReader) ifFalse: [
			spec baseline: 'NeoJSON' with: [
				spec repository: 'github://svenvc/NeoJSON:master/repository' ].
			requires add: 'NeoJSON' ].
		(Smalltalk includesKey: #Teapot) ifFalse: [
			spec baseline: 'Teapot' with: [
				spec
					repository: 'github://zeroflag/Teapot:master/source';
					loads: #( 'Deployment' ) ].
			requires add: 'Teapot' ].
		(Smalltalk includesKey: #Beacon) ifFalse: [
			spec baseline: 'Beacon' with: [
				spec repository: 'github://pharo-project/pharo-beacon:master/src' ].
			requires add: 'Beacon' ].
		spec
			package: 'Dskt-Core' with: [
				spec requires: requires asArray ];
			package: 'Dskt-Tests' with: [
				spec requires: #( 'Dskt-Core' ) ].
		spec
			group: 'Core' with: #( 'Dskt-Core' );
			group: 'Tests' with: #( 'Dskt-Tests' );
			group: 'all' with: #( 'Dskt-Core' 'Dskt-Tests' );
			group: 'default' with: #( 'Dskt-Core' ) ]
]
