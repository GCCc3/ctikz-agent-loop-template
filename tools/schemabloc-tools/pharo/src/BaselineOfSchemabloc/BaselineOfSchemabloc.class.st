"
I describe the Schemabloc control-diagram domain and its dependencies.
"
Class {
	#name : 'BaselineOfSchemabloc',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfSchemabloc',
	#package : 'BaselineOfSchemabloc'
}

{ #category : 'baselines' }
BaselineOfSchemabloc >> baseline: spec [
	<baseline>
	| requires |
	requires := OrderedCollection new.
	spec for: #common do: [
		spec baseline: 'Dskt' with: [
			spec repository: 'tonel://' , (FileSystem workingDirectory / 'tools' / 'dskt' / 'pharo' / 'src') pathString ].
		requires add: 'Dskt'.
		(Smalltalk includesKey: #MustacheTemplate) ifFalse: [
			spec baseline: 'Mustache' with: [
				spec repository: 'github://noha/mustache:v1.3/repository' ].
			requires add: 'Mustache' ].
		spec
			package: 'Schemabloc-Core' with: [ spec requires: requires asArray ];
			package: 'Schemabloc-Tests' with: [ spec requires: #( 'Schemabloc-Core' ) ].
		spec
			group: 'Core' with: #( 'Schemabloc-Core' );
			group: 'Tests' with: #( 'Schemabloc-Tests' );
			group: 'all' with: #( 'Schemabloc-Core' 'Schemabloc-Tests' );
			group: 'default' with: #( 'Schemabloc-Core' ) ]
]
