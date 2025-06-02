;;;
;;;	Internal SCI Console Driver
;;;

SMR:	EQU	0		; Serial Mode Register (disp. from SCI_B)
BRR:	EQU	1		; Bit Rate Register (disp. from SCI_B)
SCR:	EQU	2		; Serial Control Register (disp. from SCI_B)
TDR:	EQU	3		; Transmit Data Register (disp. from SCI_B)
SSR:	EQU	4		; Serial Status Register (disp. from SCI_B)
RDR:	EQU	5		; Receive Data Register (disp. from SCI_B)

INIT:
	;; Initialize SCI
	MOV.L	#SCI_B,R13

	MOV.B	#SMR_V,R0
	MOV.B	R0,@(SMR,R13)
	MOV.B	#BRR_V,R0
	MOV.B	R0,@(BRR,R13)
	MOV.B	#SCR_V,R0
	MOV.B	R0,@(SCR,R13)

	RTS
	NOP

CONIN:
	MOV.L	#SCI_B+SSR,R13
CI0:
	MOV.B	@R13,R0
	TST	#$18,R0
	BF	CIE
	TST	#$40,R0
	BT	CI0
	AND	#$9F,R0		; Clear RDRF,ORER bit
	MOV	R0,R14

	MOV.L	#SCI_B+RDR,R13
	MOV.B	@R13,R0
	MOV.L	#SCI_B+SSR,R13
	RTS
	MOV.B	R14,@R13
CIE:
	AND	#$E7,R0		; Clear FER,PER bit
	BRA	CI0
	MOV.B	R0,@R13

CONST:
	MOV.L	#SCI_B+SSR,R13
	MOV.B	@R13,R0
	AND	#$40,R0

	RTS
	NOP

CONOUT:
	MOV	R0,R14
	MOV.L	#SCI_B+SSR,R13
CO0:
	MOV.B	@R13,R0
	TST	#$80,R0
	BT	CO0
	AND	#$7F,R0

	MOV.L	#SCI_B+TDR,R13
	MOV.B	R14,@R13
	MOV.L	#SCI_B+SSR,R13
	MOV.B	R0,@R13

	RTS
	MOV	R14,R0

	ALIGN	4
	LTORG
