"
I hold the schema and implementation versions reported by the PNG measurement service.
"
Class {
	#name : 'PmdtVersion',
	#superclass : 'Object',
	#category : 'PngDiagramMeasure-Core',
	#package : 'PngDiagramMeasure-Core'
}

{ #category : 'accessing' }
PmdtVersion class >> schemaVersion [
	^ 1
]

{ #category : 'accessing' }
PmdtVersion class >> toolVersion [
	^ '0.1.0'
]
