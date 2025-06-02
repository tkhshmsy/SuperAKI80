;;;
;;;	NS NSC858 Console Driver
;;;

NSRXR:	EQU	NSBASE+00H	; Rx Holding Register
NSTXR:	EQU	NSBASE+00H	; Tx Holding Register
NSRMR:	EQU	NSBASE+01H	; Receiver Mode Register
NSTMR:	EQU	NSBASE+02H	; Transmitter Mode Register
NSGMR:	EQU	NSBASE+03H	; Global Mode Register
NSCR:	EQU	NSBASE+04H	; Command Register
NSBRGL:	EQU	NSBASE+05H	; Baud Rate Generator Divisor Latch (L)
NSBRGU:	EQU	NSBASE+06H	; Baud Rate Generator Divisor Latch (U)
NSSMR:	EQU	NSBASE+07H	; R-T Status Mask Register
NSSR:	EQU	NSBASE+08H	; R-T Status Register

INIT:
	LD	A,RTMR_V
	OUT	(NSRMR),A
	OUT	(NSTMR),A
	LD	A,GMR_V
	OUT	(NSGMR),A

	LD	A,low(BRGD_V)
	OUT	(NSBRGL),A
	LD	A,high(BRGD_V)
	OUT	(NSBRGU),A
	
	LD	A,0C3H		; Enable Transceiver, RTS, and DTR
	OUT	(NSCR),A

	RET

CONIN:
	IN	A,(NSSR)
	AND	01H
	JR	Z,CONIN

	IN	A,(NSRXR)
	RET

CONST:
	IN	A,(NSSR)
	AND	01H

	RET

CONOUT:
	PUSH	AF
CO0:
	IN	A,(NSSR)
	AND	02H
	JR	Z,CO0

	POP	AF
	OUT	(NSTXR),A

	RET
