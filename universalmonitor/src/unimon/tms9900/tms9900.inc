;;; -*- asm -*-
;;;
;;;     MACROs definition for TMS9900
;;;

NOP	MACRO
	JMP	0
	ENDM

RT	MACRO
	B	*R11
	ENDM

PUSH	MACRO	reg		; PUSH register to stack (SP=R15)
	DECT	R15
	MOV	reg,*R15
	ENDM

POP	MACRO	reg		; POP register from stack (SP=R15)
	MOV	*R15+,reg
	ENDM

RTS	MACRO			; RETURN using stack (SP=R15)
	MOV	*R15+,R11
	B	*R11
	ENDM
