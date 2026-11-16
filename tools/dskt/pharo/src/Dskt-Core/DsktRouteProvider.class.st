"
I am the protocol a domain package implements to install routes on the shared DsktServer.

A domain exposes a short `name` (the route prefix), installs its routes on the server,
reports its own health, and maps its domain error codes to HTTP statuses. The server
never imports a domain class; it only talks to providers through this protocol.
"
Class {
	#name : 'DsktRouteProvider',
	#superclass : 'Object',
	#category : 'Dskt-Core',
	#package : 'Dskt-Core'
}

{ #category : 'accessing' }
DsktRouteProvider >> name [
	^ self subclassResponsibility
]

{ #category : 'routes' }
DsktRouteProvider >> installRoutesOn: server [
	^ self subclassResponsibility
]

{ #category : 'health' }
DsktRouteProvider >> health [
	^ self subclassResponsibility
]

{ #category : 'status' }
DsktRouteProvider >> statusFor: code [
	^ 500
]
