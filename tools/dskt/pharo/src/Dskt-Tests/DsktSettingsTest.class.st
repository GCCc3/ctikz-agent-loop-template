"
I test common Dskt settings that affect the server boundary.
"
Class {
	#name : 'DsktSettingsTest',
	#superclass : 'TestCase',
	#category : 'Dskt-Tests',
	#package : 'Dskt-Tests'
}

{ #category : 'tests' }
DsktSettingsTest >> testBindAddressDefault [
	| address |
	OSEnvironment current setEnv: 'DSKT_HOST' value: '127.0.0.1' during: [
		address := DsktSettings bindAddress ].
	self assert: address asArray equals: #(127 0 0 1)
]

{ #category : 'tests' }
DsktSettingsTest >> testInvalidHostRejected [
	| error |
	error := nil.
	OSEnvironment current setEnv: 'DSKT_HOST' value: 'not-an-ip' during: [
		[ DsktSettings bindAddress ] on: DsktError do: [ :each | error := each ] ].
	self assert: error notNil.
	self assert: error code equals: 'invalid_host'
]
