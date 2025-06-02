;;;
;;;	EMILY Board Console Driver
;;;

INIT:
	LD	A,00H
	LD	(SMBASE+1),A
	LD	(SMBASE+2),A	; Command

	LD	A,0A5H
	LD	(SMBASE),A	; Signature

	LD	A,0CCH
	LD	(SMBASE+1),A	; Handshake

	RET

CONIN:
	LD	A,(SMBASE+1)	; Handshake
	CP	A,0CCH
	JR	Z,CONIN

	LD	A,02H
	LD	(SMBASE+2),A	; Command

	LD	A,0CCH
	LD	(SMBASE+1),A	; Handshake
CI0:
	LD	A,(SMBASE+1)	; Handshake
	CP	A,0CCH
	JR	Z,CI0

	LD	A,(SMBASE+4)	; Data[0]

	RET

CONST:
	LD	A,(SMBASE+1)	; Handshake
	CP	A,0CCH
	JR	Z,CONST

	LD	A,03H
	LD	(SMBASE+2),A	; Command

	LD	A,0CCH
	LD	(SMBASE+1),A	; Handshake
CS0:
	LD	A,(SMBASE+1)	; Handshake
	CP	A,0CCH
	JR	Z,CS0

	LD	A,(SMBASE+4)	; Data[0]

	RET
	
CONOUT:
	PUSH	AF
CO0:
	LD	A,(SMBASE+1)	; Handshake
	CP	A,0CCH
	JR	Z,CO0

	LD	A,01H
	LD	(SMBASE+2),A	; Command

	POP	AF
	LD	(SMBASE+4),A	; Data[0]

	LD	A,0CCH
	LD	(SMBASE+1),A	; Handshake

	RET
	
