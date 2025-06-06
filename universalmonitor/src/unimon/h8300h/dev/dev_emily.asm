;;;
;;;	EMILY Board Console Driver
;;;

	INCLUDE	"../../emily.inc"

INIT:
	XOR	R0L,R0L
	MOV	R0L,SMBASE+EO_HSK
	MOV	R0L,SMBASE+EO_CMD

	MOV	#EG_SIG,R0L
	MOV	R0L,SMBASE+EO_SIG

	MOV	#EH_REQ,R0L
	MOV	R0L,SMBASE+EO_HSK

	RTS
	
CONIN:
	MOV	SMBASE+EO_HSK,R0H
	CMP	#EH_REQ,R0H
	BEQ	CONIN

	MOV	#EC_CIN,R0H
	MOV	R0H,SMBASE+EO_CMD

	MOV	#EH_REQ,R0H
	MOV	R0H,SMBASE+EO_HSK
CI0:
	MOV	SMBASE+EO_HSK,R0H
	CMP	#EH_REQ,R0H
	BEQ	CI0

	MOV	SMBASE+EO_DAT,R0L

	RTS

CONST:
	MOV	SMBASE+EO_HSK,R0H
	CMP	#EH_REQ,R0H
	BEQ	CONST

	MOV	#EC_CST,R0H
	MOV	R0H,SMBASE+EO_CMD

	MOV	#EH_REQ,R0H
	MOV	R0H,SMBASE+EO_HSK
CS0:
	MOV	SMBASE+EO_HSK,R0H
	CMP	#EH_REQ,R0H
	BEQ	CS0

	MOV	SMBASE+EO_DAT,R0L

	RTS

CONOUT:
	MOV	SMBASE+EO_HSK,R0H
	CMP	#EH_REQ,R0H
	BEQ	CONOUT

	MOV	#EC_COT,R0H
	MOV	R0H,SMBASE+EO_CMD

	MOV	R0L,SMBASE+EO_DAT

	MOV	#EH_REQ,R0H
	MOV	R0H,SMBASE+EO_HSK

	RTS

