;;; -*- asm -*-
;;;
;;;	MACROs and FUNCTIONs definition for SC/MP
;;;


LDPI	MACRO	preg,val	; LoaD P-register immediate
	XPAH	preg
	LDI	high(val)
	XPAH	preg
	XPAL	preg
	LDI	low(val)
	XPAL	preg
	ENDM

LDPI0	MACRO	preg,val	; LoaD P-register immediate, without preserving acc
	LDI	high(val)
	XPAH	preg
	LDI	low(val)
	XPAL	preg
	ENDM

CALL	MACRO	addr		; CALL subroutine
	XPAH	P3
	ST	@-1(P1)
	LDI	high(addr-1)
	XPAH	P3
	XPAL	P3
	ST	@-1(P1)
	LDI	low(addr-1)
	XPAL	P3
	XPPC	P3
	XPAL	P3
	LD	@1(P1)
	XPAL	P3
	XPAH	P3
	LD	@1(P1)
	XPAH	P3
	ENDM

RET	MACRO			; RETurn from subroutine
	XPPC	P3
	ENDM

LJMP	MACRO	addr		; Long JuMP
	XPAH	P3
	LDI	high(addr-1)
	XPAH	P3
	XPAL	P3
	LDI	low(addr-1)
	XPAL	P3
	XPPC	P3
	ENDM
	
LJMPP	MACRO	addr		; Long JuMP, with P1 pushed
	XPAH	P3
	ST	@-1(P1)
	LDI	high(addr-1)
	XPAH	P3
	XPAL	P3
	ST	@-1(P1)
	LDI	low(addr-1)
	XPAL	P3
	XPPC	P3
	ENDM
	
PSHP	MACRO	preg		; PuSH P-register
	XPAH	preg
	ST	@-1(P1)
	XPAH	preg
	XPAL	preg
	ST	@-1(P1)
	XPAL	preg
	ENDM

PSPI	MACRO	preg,imm	; PuSh P-register, and load immediate
	XPAH	preg
	ST	@-1(P1)
	LDI	high(imm)
	XPAH	preg
	XPAL	preg
	ST	@-1(P1)
	LDI	low(imm)
	XPAL	preg
	ENDM

PULP	MACRO	preg		; PULl P-register
	XPAL	preg
	LD	@1(P1)
	XPAL	preg
	XPAH	preg
	LD	@1(P1)
	XPAH	preg
	ENDM
	
ENTER	MACRO			; push P1; get callers P1
	XPAH	P3
	ST	@-1(P1)
	LD	2(P1)
	XPAH	P3
	XPAL	P3
	ST	@-1(P1)
	LD	2(P1)
	XPAL	P3
	ENDM

LEAVE	MACRO
	XPAL	P3
	ST	2(P1)
	LD	@1(P1)
	XPAL	P3
	XPAH	P3
	ST	2(P1)
	LD	@1(P1)
	XPAH	P3
	ENDM
