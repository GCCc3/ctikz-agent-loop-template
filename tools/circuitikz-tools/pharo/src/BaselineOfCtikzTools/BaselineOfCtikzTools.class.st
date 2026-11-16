"
I describe the Ctikz tools project: the CircuitTikZ snippet catalog and source linter.

I depend on the common Dskt toolkit and on the Pharo Mustache package. I do not
depend on the PNG measurement domain.
"
Class {
	#name : 'BaselineOfCtikzTools',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfCtikzTools',
	#package : 'BaselineOfCtikzTools'
}

{ #category : 'baselines' }
BaselineOfCtikzTools >> baseline: spec [
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
			package: 'Ctikz-Core' with: [
				spec requires: requires asArray ];
			package: 'Ctikz-Tests' with: [
				spec requires: #( 'Ctikz-Core' ) ].
		spec
			group: 'Core' with: #( 'Ctikz-Core' );
			group: 'Tests' with: #( 'Ctikz-Tests' );
			group: 'all' with: #( 'Ctikz-Core' 'Ctikz-Tests' );
			group: 'default' with: #( 'Ctikz-Core' ) ]
]
