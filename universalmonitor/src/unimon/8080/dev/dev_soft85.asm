;;;
;;;	Software UART Console Driver
;;;

	;; 8085
	;; TxD: Pin 4 (SOD)
	;; RxD: Pin 5 (SID)

	SAVE
	CPU	8085

INIT:
	MVI	A,11000000B
	SIM

	LXI	B,0
INI0:
	DCX	B
	MOV	A,B
	ORA	C
	JNZ	INI0

	RET

CONIN:				; Cyc
	RIM			;  4
	ANI	10000000B	;  7
	JNZ	CONIN		; 10 / 7  Wiat falling edge of SID

	PUSH	B		; 12
	MVI	C,S85R1L	;  7
CI0:
	DCR	C		;  4
	JNZ	CI0		; 10 / 7
	REPT	S85R1N
	NOP			;  4
	ENDM
	
	XRA	A		;  4
	MVI	B,8		;  7  8 bit
CI1:
	RRC			;  4
	MOV	C,A		;  4
	RIM			;  4
	ANI	10000000B	;  7
	ORA	C		;  4

	MVI	C,S85R2L	;  7
CI2:
	DCR	C		;  4
	JNZ	CI2		; 10 / 7
	REPT	S85R2N
	NOP			;  4
	ENDM

	DCR	B		;  4
	JNZ	CI1		; 10 / 7

	MOV	C,A
CI3:
	RIM
	ANI	10000000B
	JZ	CI3
	MOV	A,C

	POP	B
	RET

CONST:
	MVI	A,0FFH
	RET

CONOUT:				; Cyc
	PUSH	B
	PUSH	PSW
	MVI	A,01000000B
	SIM			;  4  TxD H=>L (Start bit)

	MVI	B,8		;  7
	POP	PSW		; 10

	MVI	C,S85T1L		;  7
CO0:
	DCR	C		;  4
	JNZ	CO0		; 10 / 7
	REPT	S85T1N
	NOP			;  4
	ENDM

CO1:
	RRC			;  4
	PUSH	PSW		; 12
	ANI	10000000B	;  7
	ORI	01000000B	;  7
	SIM			;  4
	POP	PSW		; 10

	MVI	C,S85T2L	;  7
CO2:
	DCR	C		;  4
	JNZ	CO2		; 10 / 7
	REPT	S85T2N
	NOP			;  4
	ENDM

	DCR	B		;  4
	JNZ	CO1		; 10/ 7

	MOV	C,A
	MVI	A,11000000B	;  7
	SIM			;  4  TxD =>H (Stop bit)
	MOV	A,C

	MVI	C,S85T2L
CO3:
	DCR	C
	JNZ	CO3
	REPT	S85T2N
	NOP			;  4
	ENDM

	POP	B
	RET
	
	RESTORE
