"
I hold reusable TeX sources for the Ctikz catalog and lint tests.
"
Class {
	#name : 'CtikzTestFixtures',
	#superclass : 'Object',
	#category : 'Ctikz-Tests',
	#package : 'Ctikz-Tests'
}

{ #category : 'sources' }
CtikzTestFixtures class >> validSource [
	^ '\documentclass[border=6pt]{standalone}
\usepackage[european]{circuitikz}
\usetikzlibrary{arrows.meta}
\begin{document}
\begin{circuitikz}
\coordinate (a) at (0,0);
\coordinate (b) at (1,0);
\draw (a) to[R] (b);
\node at (0.5,0.5) {$R_f$};
\end{circuitikz}
\end{document}'
]

{ #category : 'sources' }
CtikzTestFixtures class >> twoCircuitikzEnvironments [
	^ '\documentclass{standalone}
\usepackage{circuitikz}
\begin{document}
\begin{circuitikz}\end{circuitikz}
\begin{circuitikz}\end{circuitikz}
\end{document}'
]

{ #category : 'sources' }
CtikzTestFixtures class >> tikzClassOption [
	^ '\documentclass[tikz]{standalone}
\usepackage{circuitikz}
\begin{document}
\begin{circuitikz}\end{circuitikz}
\end{document}'
]

{ #category : 'sources' }
CtikzTestFixtures class >> imageInclusion [
	^ '\documentclass{standalone}
\usepackage{circuitikz}
\begin{document}
\begin{circuitikz}
\includegraphics{target.png}
\end{circuitikz}
\end{document}'
]

{ #category : 'sources' }
CtikzTestFixtures class >> commentWithForbiddenToken [
	^ '\documentclass{standalone}
\usepackage{circuitikz}
\begin{document}
\begin{circuitikz}
% \includegraphics{target.png}
\coordinate (a) at (0,0);
\end{circuitikz}
\end{document}'
]

{ #category : 'sources' }
CtikzTestFixtures class >> escapedPercent [
	^ '\documentclass{standalone}
\usepackage{circuitikz}
\begin{document}
\begin{circuitikz}
\coordinate (a) at (0,0);
\node at (0,0) {\%};
\end{circuitikz}
\end{document}'
]

{ #category : 'sources' }
CtikzTestFixtures class >> mismatchedEnvironment [
	^ '\documentclass{standalone}
\usepackage{circuitikz}
\begin{document}
\begin{circuitikz}
\end{document}
\end{circuitikz}'
]

{ #category : 'sources' }
CtikzTestFixtures class >> unbalancedBrace [
	^ '\documentclass{standalone}
\usepackage{circuitikz}
\begin{document}
\begin{circuitikz}
\draw (a) -- (b);
\end{circuitikz}
\end{document'
]

{ #category : 'sources' }
CtikzTestFixtures class >> undefinedCoordinate [
	^ '\documentclass{standalone}
\usepackage{circuitikz}
\begin{document}
\begin{circuitikz}
\coordinate (a) at (0,0);
\draw (a) -- (missing);
\end{circuitikz}
\end{document}'
]

{ #category : 'sources' }
CtikzTestFixtures class >> relativeCoordinate [
	^ '\documentclass{standalone}
\usepackage{circuitikz}
\begin{document}
\begin{circuitikz}
\coordinate (a) at (0,0);
\coordinate (b) at (1,0);
\draw (a) ++ (1,0) -- (b);
\end{circuitikz}
\end{document}'
]

{ #category : 'sources' }
CtikzTestFixtures class >> mathLabel [
	^ '\documentclass{standalone}
\usepackage{circuitikz}
\begin{document}
\begin{circuitikz}
\node at (0,0) {$v_g$};
\end{circuitikz}
\end{document}'
]

{ #category : 'sources' }
CtikzTestFixtures class >> nestedLabel [
	^ '\documentclass{standalone}
\usepackage{circuitikz}
\begin{document}
\begin{circuitikz}
\node at (0,0) {$R_{load}$};
\end{circuitikz}
\end{document}'
]
