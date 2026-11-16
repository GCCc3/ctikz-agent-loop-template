"
I am the ordered registry of domain route providers.

I install each provider's routes exactly once and reject duplicate prefixes so that
two domains can never silently overwrite each other's routes.
"
Class {
	#name : 'DsktRouteRegistry',
	#superclass : 'Object',
	#instVars : [
		'providers'
	],
	#classVars : [
		'Current'
	],
	#category : 'Dskt-Core',
	#package : 'Dskt-Core'
}

{ #category : 'accessing' }
DsktRouteRegistry class >> current [
	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
DsktRouteRegistry class >> initialize [
	Current := self new
]

{ #category : 'accessing' }
DsktRouteRegistry class >> register: provider [
	^ self current register: provider
]

{ #category : 'initialization' }
DsktRouteRegistry >> initialize [
	super initialize.
	providers := OrderedCollection new
]

{ #category : 'accessing' }
DsktRouteRegistry >> providers [ ^ providers ]

{ #category : 'accessing' }
DsktRouteRegistry >> register: provider [
	| name |
	name := provider name.
	(providers anySatisfy: [ :each | each name = name ])
		ifTrue: [ DsktError code: 'route_registration_failed' message: 'Duplicate route prefix: ' , name ].
	providers add: provider
]

{ #category : 'installing' }
DsktRouteRegistry >> installRoutesOn: server [
	providers do: [ :provider | provider installRoutesOn: server ]
]

{ #category : 'accessing' }
DsktRouteRegistry >> providerNamed: name [
	^ providers detect: [ :provider | provider name = name ] ifNone: [ nil ]
]

{ #category : 'health' }
DsktRouteRegistry >> health [
	^ Dictionary newFrom: (providers collect: [ :provider | provider name -> provider health ])
]
