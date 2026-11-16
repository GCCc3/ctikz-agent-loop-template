"
I test route provider registration, duplicate rejection, and health aggregation.
"
Class {
	#name : 'DsktRouteRegistryTest',
	#superclass : 'TestCase',
	#category : 'Dskt-Tests',
	#package : 'Dskt-Tests'
}

{ #category : 'tests' }
DsktRouteRegistryTest >> testRegistersAndResolvesProvider [
	| registry |
	registry := DsktRouteRegistry new.
	self assert: registry providers isEmpty.
	registry register: DsktDummyProvider new.
	self assert: (registry providerNamed: 'dummy') notNil.
	self assert: ((registry health at: 'dummy') at: 'status') equals: 'ok'
]

{ #category : 'tests' }
DsktRouteRegistryTest >> testRejectsDuplicatePrefix [
	| registry |
	registry := DsktRouteRegistry new.
	registry register: DsktDummyProvider new.
	self should: [ registry register: DsktDummyProvider new ] raise: DsktError
]
