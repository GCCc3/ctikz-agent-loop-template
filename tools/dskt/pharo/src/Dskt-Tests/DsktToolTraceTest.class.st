"
I test that the common trace wrapper returns results and re-raises domain errors.
"
Class {
	#name : 'DsktToolTraceTest',
	#superclass : 'TestCase',
	#category : 'Dskt-Tests',
	#package : 'Dskt-Tests'
}

{ #category : 'helpers' }
DsktToolTraceTest >> request [
	^ Dictionary new
		at: 'request_id' put: 'test-request';
		at: 'client_id' put: 'test-client';
		at: 'client_role' put: 'tester';
		yourself
]

{ #category : 'tests' }
DsktToolTraceTest >> testReturnsResult [
	| result |
	result := DsktToolTrace
		tool: 'dummy'
		request: self request
		do: [ Dictionary new at: 'ok' put: true; yourself ].
	self assert: (result at: 'ok')
]

{ #category : 'tests' }
DsktToolTraceTest >> testReraisesDomainError [
	self should: [
		DsktToolTrace
			tool: 'dummy'
			request: self request
			do: [ DsktError code: 'dummy_error' message: 'expected failure' ] ]
		raise: DsktError
]
