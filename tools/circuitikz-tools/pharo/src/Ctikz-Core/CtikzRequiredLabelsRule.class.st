"
I am the rule that requires specific labels in active source.

I compare label text against the required labels, matching whole tokens.
"
Class {
	#name : 'CtikzRequiredLabelsRule',
	#superclass : 'CtikzLintRule',
	#category : 'Ctikz-Core',
	#package : 'Ctikz-Core'
}

{ #category : 'accessing' }
CtikzRequiredLabelsRule >> id [ ^ 'required_labels' ]

{ #category : 'evaluating' }
CtikzRequiredLabelsRule >> evaluate: model context: context [
	| required labels |
	required := (context at: 'required_labels' ifAbsent: [ nil ])
		ifNil: [ #('L_f' 'R_f' 'i' 'v' '+' '-' 'Z_g' 'v_g' 'DC' 'AC' 'GFM converter' 'grid') ].
	labels := model labels collect: [ :each | each at: 'text' ].
	required do: [ :label |
		(labels anySatisfy: [ :each | self matchesToken: label in: each ])
			ifFalse: [ ^ self failed: 'Missing required label: ' , label line: nil ] ].
	^ self passed
]

{ #category : 'private' }
CtikzRequiredLabelsRule >> matchesToken: aLabel in: aText [
	| stripped |
	stripped := aText copyReplaceAll: '$' with: ''.
	^ stripped trimBoth = aLabel
]
