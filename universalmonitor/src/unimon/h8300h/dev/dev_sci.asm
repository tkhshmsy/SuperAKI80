;;;
;;;	H8/3048 internal SCI Console Driver
;;;

SMR:	EQU	0		; Serial Mode Register (disp. from SCI_B)
BRR:	EQU	1		; Bit Rate Register (disp. from SCI_B)
SCR:	EQU	2		; Serial Control Register (disp. from SCI_B)
TDR:	EQU	3		; Transmit Data Register (disp. from SCI_B)
SSR:	EQU	4		; Serial Status Register (disp. from SCI_B)
RDR:	EQU	5		; Receive Data Register (disp. from SCI_B)

INIT:
	MOV	#SMR_V,R0L
	MOV	R0L,@SCI_B+SMR
	MOV	#BRR_V,R0L
	MOV	R0L,@SCI_B+BRR
	MOV	#SCR_V,R0L
	MOV	R0L,@SCI_B+SCR
	RTS

CONIN:
	MOV	@SCI_B+SSR,R0H
	BTST	#3,R0H
	BNE	CIE
	BTST	#4,R0H
	BNE	CIE
	BTST	#6,R0H		; RDRF
	BEQ	CONIN

	MOV	@SCI_B+RDR,R0L

	AND	#$9F,R0H	; Clear RDRF,ORER bit
	MOV	R0H,@SCI_B+SSR
	RTS
CIE:
	AND	#$E7,R0H	; Clear FER,PER bit
	MOV	R0H,@SCI_B+SSR
	BRA	CONIN

CONST:
	MOV	@SCI_B+SSR,R0L
	AND	#$40,R0L

	RTS

CONOUT:
	MOV	@SCI_B+SSR,R0H
	BTST	#7,R0H		; TDRE
	BEQ	CONOUT

	MOV	R0L,@SCI_B+TDR

	BCLR	#7,R0H		; Clr TDRE
	MOV	R0H,@SCI_B+SSR

	RTS
