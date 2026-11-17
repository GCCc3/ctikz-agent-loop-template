"
I provide source fixtures for schemabloc tests.
"
Class {
	#name : 'SchemablocTestFixtures',
	#superclass : 'Object',
	#category : 'Schemabloc-Tests',
	#package : 'Schemabloc-Tests'
}

{ #category : 'fixtures' }
SchemablocTestFixtures class >> controlSource [
	^ '\documentclass[border=5mm]{standalone}
\usepackage{schemabloc}
\begin{document}
\begin{tikzpicture}
\sbEntree{vref}
\sbComp{sumv}{vref}
\sbBloc{Gva}{$G_{va}$}{sumv}
\sbSortie{iout}{Gva}
\sbRelier[$\hat v_{ref}$]{vref}{sumv}
\sbRelier{Gva}{iout}
\node[sign] at (sumv) {$+$};
\node[sign] at (sumv) {$-$};
\end{tikzpicture}
\end{document}
'
]

{ #category : 'fixtures' }
SchemablocTestFixtures class >> sourceWithCircuitikz [
	^ '\documentclass{standalone}
\usepackage{circuitikz}
\begin{document}
\begin{circuitikz}
\end{circuitikz}
\end{document}
'
]

{ #category : 'fixtures' }
SchemablocTestFixtures class >> sourceWithManualRectangle [
	^ '\documentclass{standalone}
\usepackage{schemabloc}
\begin{document}
\begin{tikzpicture}
\draw (0,0) rectangle (1,1);
\sbEntree{vref}
\end{tikzpicture}
\end{document}
'
]
