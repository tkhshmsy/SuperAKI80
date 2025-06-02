;;;
;;;	H8/532 internal SCI Console Driver
;;;

SMR:	EQU	0		; Serial Mode Register
BRR:	EQU	1		; Bit Rate Register
SCR:	EQU	2		; Serial Control Register
TDR:	EQU	3		; Transmit Data Register
SSR:	EQU	4		; Serial Status Register
RDR:	EQU	5		; Receive Data Register

INIT:
	MOV.B	#SMR_V,R0
	MOV.B	R0,@SCI_B+SMR
	MOV.B	#BRR_V,R0
	MOV.B	R0,@SCI_B+BRR
	MOV.B	#SCR_V,R0
	MOV.B	R0,@SCI_B+SCR
	RTS

CONIN:
	MOV.B	@SCI_B+SSR,R0
	BTST	#3,R0
	BNE	CIE
	BTST	#4,R0
	BNE	CIE
	BTST	#6,R0		; RDRF
	BEQ	CONIN

	MOV.B	@SCI_B+RDR,R0

	MOV	R0,@-SP
	MOV.B	@SCI_B+SSR,R0
	AND.B	#$9F,R0		; Clear RDRF,ORER bit
	MOV.B	R0,@SCI_B+SSR
	MOV	@SP+,R0
	RTS
CIE:
	AND.B	#$E7,R0		; Clear FER,PER bit
	MOV.B	R0,@SCI_B+SSR
	BRA	CONIN

CONST:
	MOV.B	@SCI_B+SSR,R0
	AND.B	#$40,R0

	RTS

CONOUT:
	BTST.B	#7,@SCI_B+SSR	; TDRE
	BEQ	CONOUT

	MOV.B	R0,@SCI_B+TDR

	BCLR.B	#7,@SCI_B+SSR	; Clr TDRE

	RTS
