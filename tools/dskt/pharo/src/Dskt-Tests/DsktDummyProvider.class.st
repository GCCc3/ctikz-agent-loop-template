"
I am a minimal DsktRouteProvider used by the Dskt-Core tests.

I prove that a domain can register a route provider without editing DsktServer.
"
Class {
	#name : 'DsktDummyProvider',
	#superclass : 'DsktRouteProvider',
	#category : 'Dskt-Tests',
	#package : 'Dskt-Tests'
}

{ #category : 'accessing' }
DsktDummyProvider >> name [ ^ 'dummy' ]

{ #category : 'routes' }
DsktDummyProvider >> installRoutesOn: server [
	server teapot GET: '/dummy/health' -> [ :request | server handleHealth: 'dummy' request: request ]
]

{ #category : 'health' }
DsktDummyProvider >> health [
	^ Dictionary new
		at: 'status' put: 'ok';
		yourself
]
