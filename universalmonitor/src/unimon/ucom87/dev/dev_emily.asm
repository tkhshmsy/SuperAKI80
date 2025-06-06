;;;
;;;	EMILY Board Console Driver
;;;

	INCLUDE	"../../emily.inc"

INIT:
	XRA	A,A
	MOV	SMBASE+EO_HSK,A
	MOV	SMBASE+EO_CMD,A

	MVI	A,EG_SIG
	MOV	SMBASE+EO_SIG,A

	MVI	A,EH_REQ
	MOV	SMBASE+EO_HSK,A

	RET

CONIN:
	MOV	A,SMBASE+EO_HSK
	NEI	A,EH_REQ
	JR	CONIN

	MVI	A,EC_CIN
	MOV	SMBASE+EO_CMD,A

	MVI	A,EH_REQ
	MOV	SMBASE+EO_HSK,A
CI0:
	MOV	A,SMBASE+EO_HSK
	NEI	A,EH_REQ
	JR	CI0

	MOV	A,SMBASE+EO_DAT

	RET

CONST:
	MOV	A,SMBASE+EO_HSK
	NEI	A,EH_REQ
	JR	CONST

	MVI	A,EC_CST
	MOV	SMBASE+EO_CMD,A

	MVI	A,EH_REQ
	MOV	SMBASE+EO_HSK,A
CS0:
	MOV	A,SMBASE+EO_HSK
	NEI	A,EH_REQ
	JR	CS0

	MOV	A,SMBASE+EO_DAT

	RET

CONOUT:
	PUSH	V
CO0:	
	MOV	A,SMBASE+EO_HSK
	NEI	A,EH_REQ
	JR	CO0

	MVI	A,EC_COT
	MOV	SMBASE+EO_CMD,A

	POP	V
	MOV	SMBASE+EO_DAT,A
	PUSH	V

	MVI	A,EH_REQ
	MOV	SMBASE+EO_HSK,A

	POP	V
	RET
