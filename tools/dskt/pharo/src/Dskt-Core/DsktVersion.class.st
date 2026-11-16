"
I hold the shared schema version and toolkit version reported by the common service layer.
"
Class {
	#name : 'DsktVersion',
	#superclass : 'Object',
	#category : 'Dskt-Core',
	#package : 'Dskt-Core'
}

{ #category : 'accessing' }
DsktVersion class >> schemaVersion [
	^ 1
]

{ #category : 'accessing' }
DsktVersion class >> toolVersion [
	^ '0.2.0'
]
