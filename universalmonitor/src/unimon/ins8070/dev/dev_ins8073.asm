;;;
;;;	INS8073 Console Driver  (Use routines in NSC Tiny BASIC ROM)
;;;

INIT:
	RET

CONIN:
	JSR	0x092B
	BZ	CONIN

	PLI	P3,=DEVMEM
	ST	A,0,P3
	POP	P3

	RET

CONST:
	LD	A,=0xFF
	RET

CONOUT:
	PLI	P3,=DEVMEM
	PUSH	A
	SUB	A,0,P3
	BNZ	CO0
	POP	A
	BRA	CO1
CO0:
	POP	A
	CALL	7
CO1:
	LD	A,=0
	ST	A,0,P3
	POP	P3

	RET
