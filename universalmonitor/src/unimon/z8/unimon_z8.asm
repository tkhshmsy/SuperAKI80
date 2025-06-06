;;; 
;;; Universal Monitor Z8
;;;

	;; CPU	Z8601

TARGET:	equ	"Z8"
	
	INCLUDE	"config.inc"
	INCLUDE	"stddefz8.inc"

	INCLUDE	"../common.inc"
	
	ORG	0000H

INT0:	DW	0
INT1:	DW	0
INT2:	DW	0
INT3:	DW	0
INT4:	DW	0
INT5:	DW	0

RESET:
	JP	CSTART

	;;
	;; Entry point
	;;

	ORG	ENTRY+0		; Cold start
E_CSTART:
	JP	CSTART

	ORG	ENTRY+8		; Warm start
E_WSTART:
	JP	WSTART

	ORG	ENTRY+16	; Console output
E_CONOUT:
	JP	CONOUT

	ORG	ENTRY+24	; (Console) String output
E_STROUT:
	JP	STROUT

	ORG	ENTRY+32	; Console input
E_CONIN:
	JP	CONIN

	ORG	ENTRY+40	; Console status
E_CONST:
	JP	CONST

	;;
	;;
	;;
	
CSTART:	
	LD	RP,#REGPTR
	ASSUME	RP:REGPTR

	SWITCH EXT_BUS
	CASE 1			; 12-bit address mode
P01M_T := ( P01M_V & 0E4H ) | 12H
	CASE 2			; 16-bit address mode
P01M_T := ( P01M_V & 024H ) | 92H
	ELSECASE		; No external BUS
P01M_T := P01M_V
	ENDCASE

	IF EXT_STACK
	IF EXT_BUS == 0
	ERROR "Cannot use EXTRAM Stack without EXTBUS"
	ENDIF
	ELSE
P01M_T := P01M_T | 04H
	ENDIF
	
	LD	P01M,#P01M_T
	
	IF	EXT_STACK
	;; Allocate STACK on External RAM
	LD	SPH,#high(STACK)
	LD	SPL,#low(STACK)
	ELSE
	;; Allocate STACK on REGISTER FILE
	LD	SPL,#STACK
	ENDIF
	
	CALL	INIT

	CLR	DSADDR
	CLR	DSADDR+1
	CLR	SADDR
	CLR	SADDR+1
	CLR	GADDR
	CLR	GADDR+1
	LD	BANK,#'C'
	LD	HEXMOD,#'I'
	
	;; Main loop
	LD	R8,#high(OPNMSG)
	LD	R9,#low(OPNMSG)
	CALL	MSGOUT
WSTART:
	LD	R8,#high(PROMPT)
	LD	R9,#low(PROMPT)
	CALL	MSGOUT
	CALL	GETLIN
	LD	R8,#INBUF
	CALL	SKIPSP
	CALL	UPPER
	AND	R0,R0
	JR	Z,WSTART

	CP	R0,#'D'
	JR	Z,DUMP
	CP	R0,#'G'
	JP	Z,GO
	CP	R0,#'S'
	JP	Z,SETM
	CP	R0,#'H'
	JP	Z,HBANK

	CP	R0,#'L'
	JP	Z,LOADH
	CP	R0,#'P'
	JP	Z,SAVEH
	
ERR:
	LD	R8,#high(ERRMSG)
	LD	R9,#low(ERRMSG)
	CALL	MSGOUT
	JR	WSTART

;;;
;;; DUMP memory
;;;
DUMP:
	INC	R8
	CALL	SKIPSP
	CALL	RDHEX
	OR	R2,R2
	JR	NZ,DP0
	;; No arg.
	CALL	SKIPSP
	LD	R0,@R8
	OR	R0,R0
	JR	NZ,ERR

	LD	R8,DSADDR
	LD	R9,DSADDR+1
	ADD	R9,#128
	ADC	R8,#0
	LD	DEADDR,R8
	LD	DEADDR+1,R9
	JR	DPM

	;; 1st arg. found
DP0:
	LD	DSADDR,R10
	LD	DSADDR+1,R11
	CALL	SKIPSP
	LD	R0,@R8
	CP	R0,#','
	JR	Z,DP1
	OR	R0,R0
	JR	NZ,ERR
	;; No 2nd arg.
	ADD	R11,#128
	ADC	R10,#0
	LD	DEADDR,R10
	LD	DEADDR+1,R11
	JR	DPM
DP1:
	INC	R8
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	OR	R2,R2
	JR	Z,ERR
	LD	R0,@R8
	OR	R0,R0
	JR	NZ,ERR
	INCW	RR10
	LD	DEADDR,R10
	LD	DEADDR+1,R11
DPM:
	;; DUMP main
	LD	R10,DSADDR
	LD	R11,DSADDR+1
	AND	R11,#0F0H
	LD	DSTATE,#0
DPM0:
	PUSH	R10
	PUSH	R11
	CALL	DPL
	POP	R11
	POP	R10
	ADD	R11,#16
	ADC	R10,#0
	CALL	CONST
	JR	NZ,DPM1
	CP	DSTATE,#2
	JR	C,DPM0
	LD	R10,DEADDR
	LD	R11,DEADDR+1
	LD	DSADDR,R10
	LD	DSADDR+1,R11
	JP	WSTART
DPM1:
	LD	DSADDR,R10
	LD	DSADDR+1,R11
	CALL	CONIN
	JP	WSTART

DPL:
	;; DUMP line
	CALL	BNKOUT
	LD	R0,#':'
	CALL	CONOUT

	LD	R8,R10
	LD	R9,R11
	CALL	HEXOUT4
	LD	R8,#high(DSEP0)
	LD	R9,#low(DSEP0)
	CALL	MSGOUT
	LD	R12,#INBUF
	LD	R2,#16
DPL0:
	CALL	DPB
	DJNZ	R2,DPL0

	LD	R8,#high(DSEP1)
	LD	R9,#low(DSEP1)
	CALL	MSGOUT

	LD	R12,#INBUF
	LD	R2,#16
DPL1:
	LD	R0,@R12
	INC	R12
	CP	R0,#' '
	JR	C,DPL2
	CP	R0,#7FH
	JR	NC,DPL2
	CALL	CONOUT
	JR	DPL3
DPL2:
	LD	R0,#'.'
	CALL	CONOUT
DPL3:
	DJNZ	R2,DPL1
	JP	CRLF

DPB:
	;; DUMP byte
	LD	R0,#' '
	CALL	CONOUT
	LD	R0,DSTATE
	OR	R0,R0
	JR	NZ,DPB2
	;; State 0
	CP	R11,DSADDR+1
	JR	NZ,DPB0
	CP	R10,DSADDR
	JR	Z,DPB1
DPB0:
	;; Still 0 or 2
	LD	R0,#' '
	CALL	CONOUT
	CALL	CONOUT
	LD	@R12,R0
	INCW	RR10
	INC	R12
	RET
DPB1:
	;; Found start address
	LD	DSTATE,#1
DPB2:
	CP	DSTATE,#1
	JR	NZ,DPB0		; state 2
	;; DUMP state 1
	LD	R8,R10
	LD	R9,R11
	CALL	READ
	LD	@R12,R0
	CALL	HEXOUT2
	INCW	RR10
	INC	R12

	CP	R11,DEADDR+1
	JR	NZ,DPB3
	CP	R10,DEADDR
	JR	NZ,DPB3
	;; Found end address
	LD	DSTATE,#2
DPB3:
	RET

;;;
;;; GO
;;; 
GO:
	INC	R8
	CALL	SKIPSP
	CALL	RDHEX
	LD	R0,@R8
	OR	R0,R0
	JP	NZ,ERR
	OR	R2,R2
	JR	Z,G0
	LD	GADDR,R10
	LD	GADDR+1,R11
G0:
	LD	R10,GADDR
	LD	R11,GADDR+1
	JP	@RR10

;;;
;;; SET memory
;;;
SETM:
	INC	R8
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	LD	R0,@R8
	OR	R0,R0
	JP	NZ,ERR
	OR	R2,R2
	JR	NZ,SM0
	LD	R10,SADDR
	LD	R11,SADDR+1
SM0:
	LD	R8,R10
	LD	R9,R11
SM1:
	CALL	BNKOUT
	LD	R0,#':'
	CALL	CONOUT

	CALL	HEXOUT4
	PUSH	R8
	PUSH	R9
	LD	R8,#high(DSEP1)
	LD	R9,#low(DSEP1)
	CALL	MSGOUT
	POP	R9
	POP	R8
	CALL	READ
	PUSH	R8
	PUSH	R9
	CALL	HEXOUT2
	LD	R0,#' '
	CALL	CONOUT
	CALL	GETLIN
	LD	R8,#INBUF
	CALL	SKIPSP
	OR	R0,R0
	JR	NZ,SM2
	;; Empty (Increment address)
	POP	R9
	POP	R8
	INCW	RR8
	LD	SADDR,R8
	LD	SADDR+1,R9
	JR	SM1
SM2:
	CP	R0,#'-'
	JR	NZ,SM3
	;; '-' (Decrement address)
	POP	R9
	POP	R8
	DECW	RR8
	LD	SADDR,R8
	LD	SADDR+1,R9
	JR	SM1
SM3:
	CP	R0,#'.'
	JR	NZ,SM4
	;; '.' (Quit)
	POP	R9
	POP	R8
	LD	SADDR,R8
	LD	SADDR+1,R9
	JP	WSTART
SM4:
	CALL	RDHEX
	POP	R9
	POP	R8
	LD	R0,R11
	OR	R2,R2
	JP	Z,ERR
	CALL	WRITE
	INCW	RR8
	LD	SADDR,R8
	LD	SADDR+1,R9
	JR	SM1
	
;;;
;;; H(bank)
;;;

HBANK:
	INC	R8
	CALL	SKIPSP
	CALL	UPPER
	OR	R0,R0
	JR	Z,HBV
	INC	R8
	LD	R2,R0
	CALL	SKIPSP
	LD	R1,@R8
	OR	R1,R1
	JP	NZ,ERR
	CP	R2,#'C'
	JR	Z,HB0
	CP	R2,#'D'
	JR	Z,HB0
	CP	R2,#'R'
	JR	Z,HB0
	JP	ERR
HB0:
	LD	BANK,R2
	JP	WSTART
HBV:
	CALL	BNKOUT
	CALL	CRLF
	JP	WSTART

BNKOUT:
	LD	R0,BANK
	CP	R0,#'C'
	JR	Z,BO3
	CP	R0,#'D'
	JR	Z,BO3
	CP	R0,#'R'
	JR	Z,BO3
	LD	R0,#'C'
	LD	BANK,R0
BO3:
	JP	CONOUT

;;;
;;; LOAD HEX file
;;;

LOADH:	
	INC	R8
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	OR	R0,R0
	JP	NZ,ERR

	LD	R12,R10		; Offset
	LD	R13,R11
	OR	R2,R2
	JR	NZ,LH0

	CLR	R12		; Offset
	CLR	R13
LH0:
	CALL	CONIN
	CALL	UPPER
	CP	R0,#'S'
	JR	Z,LHS0
LH1:
	CP	R0,#':'
	JR	Z,LHI0
LH2:
	;; Skip to EOL
	CP	R0,#CR
	JR	Z,LH0
	CP	R0,#LF
	JR	Z,LH0
LH3:	
	CALL	CONIN
	JR	LH2

LHI0:	
	CALL	HEXIN
	LD	R3,R4		; Checksum
	LD	R2,R4		; Length

	CALL	HEXIN
	ADD	R3,R4		; Checksum
	LD	R10,R4		; Address H

	CALL	HEXIN
	ADD	R3,R4		; Checksum
	LD	R11,R4		; Address L

	ADD	R11,R13
	ADC	R10,R12
	
	CALL	HEXIN
	ADD	R3,R4		; Checksum
	LD	R6,R4		; Record type

	OR	R2,R2
	JR	Z,LHI3
LHI1:
	CALL	HEXIN
	ADD	R3,R4

	CP	R6,#00H
	JR	NZ,LHI2

	LD	R8,R10
	LD	R9,R11
	LD	R0,R4
	CALL	WRITE
	INCW	RR10
LHI2:	
	DJNZ	R2,LHI1
LHI3:	
	CALL	HEXIN
	ADD	R3,R4
	JR	NZ,LHIE		; Checksum error
	CP	R6,#00H
	JR	Z,LH3
	JP	WSTART
LHIE:
	LD	R8,#high(IHEMSG)
	LD	R9,#low(IHEMSG)
	CALL	MSGOUT
	JP	WSTART
	
LHS0:
	CALL	CONIN
	LD	R6,R0		; Record type

	CALL	HEXIN
	LD	R3,R4		; Checksum
	LD	R2,R4		; Length+3

	CALL	HEXIN
	ADD	R3,R4		; Checksum
	LD	R10,R4		; Address H

	CALL	HEXIN
	ADD	R3,R4		; Checksum
	LD	R11,R4		; Address L

	ADD	R11,R13
	ADC	R10,R12

	SUB	R2,#3
	OR	R2,R2
	JR	Z,LHS3
LHS1:
	CALL	HEXIN
	ADD	R3,R4		; Checksum

	CP	R6,#'1'
	JR	NZ,LHS2

	LD	R8,R10
	LD	R9,R11
	LD	R0,R4
	CALL	WRITE
	INCW	RR10
LHS2:
	DJNZ	R2,LHS1
LHS3:	
	CALL	HEXIN
	ADD	R3,R4
	CP	R3,#0FFH
	JR	NZ,LHSE		; Checksum error
	CP	R6,#'1'
	JP	Z,LH3
	CP	R6,#'9'
	JP	Z,WSTART
LHSE:
	LD	R8,#high(SHEMSG)
	LD	R9,#low(SHEMSG)
	CALL	MSGOUT
	JP	WSTART
	
	

	
;;;
;;; SAVE HEX file
;;;
SAVEH:
	INC	R8
	LD	R0,@R8
	CALL	UPPER
	CP	R0,#'I'
	JR	Z,SH0
	CP	R0,#'S'
	JR	NZ,SH1
SH0:
	INC	R8
	LD	HEXMOD,R0
SH1:
	CALL	SKIPSP
	CALL	RDHEX
	OR	R2,R2
	JR	Z,SHE
	LD	R12,R10
	LD	R13,R11		; R12:R13 = Start address
	CALL	SKIPSP
	CP	R0,#','
	JR	NZ,SHE
	INC	R8
	CALL	SKIPSP
	CALL	RDHEX		; R10:R11 = End address
	OR	R2,R2
	JR	Z,SHE
	CALL	SKIPSP
	OR	R0,R0
	JR	Z,SH2
SHE:
	JP	ERR

SH2:
	SUB	R11,R13
	SBC	R10,R12
	INCW	RR10		; R10:R11 = Length
SH3:
	CALL	SHL
	LD	R0,R10
	OR	R0,R11
	JR	NZ,SH3

	CP	HEXMOD,#'I'
	JR	NZ,SH4
	;; End record for Intel HEX
	LD	R8,#high(IHEXER)
	LD	R9,#low(IHEXER)
	CALL	MSGOUT
	JP	WSTART
SH4:	
	;; End record for Motorola S record
	LD	R8,#high(SRECER)
	LD	R9,#low(SRECER)
	CALL	MSGOUT
	JP	WSTART

SHL:
	LD	R2,#16		; Maximum record length
	OR	R10,R10
	JR	NZ,SHL0
	CP	R11,R2
	JR	NC,SHL0
	LD	R2,R11
SHL0:
	SUB	R11,R2
	SBC	R10,#0

	CP	HEXMOD,#'I'
	JR	NZ,SHLS

	;; Intel HEX
	CLR	R3		; Checksum
	LD	R0,#':'
	CALL	CONOUT

	LD	R0,R2
	SUB	R3,R0
	CALL	HEXOUT2		; Length

	LD	R0,R12
	SUB	R3,R0
	CALL	HEXOUT2		; Address H

	LD	R0,R13
	SUB	R3,R0
	CALL	HEXOUT2		; Address L

	CLR	R0
	CALL	HEXOUT2		; Type (00H)
SHLI0:
	LD	R8,R12
	LD	R9,R13
	CALL	READ
	SUB	R3,R0
	CALL	HEXOUT2

	INCW	RR12
	DJNZ	R2,SHLI0

	LD	R0,R3
	CALL	HEXOUT2
	JP	CRLF

SHLS:
	;; Motorola S record
	LD	R3,#0FFH
	LD	R0,#'S'
	CALL	CONOUT
	LD	R0,#'1'
	CALL	CONOUT

	LD	R0,R2
	ADD	R0,#2+1		; DataLength + Addr(2) + Sum(1)
	SUB	R3,R0
	CALL	HEXOUT2		; Length

	LD	R0,R12
	SUB	R3,R0
	CALL	HEXOUT2		; Address H
	
	LD	R0,R13
	SUB	R3,R0
	CALL	HEXOUT2		; Address L
SHLS0:
	LD	R8,R12
	LD	R9,R13
	CALL	READ
	SUB	R3,R0
	CALL	HEXOUT2

	INCW	RR12
	DJNZ	R2,SHLS0

	LD	R0,R3
	CALL	HEXOUT2		; Checksum
	JP	CRLF
	
MSGOUT:
	LDC	R0,@RR8
	INCW	RR8
	AND	R0,R0
	JR	Z,MOR
	CALL	CONOUT
	JR	MSGOUT
MOR:
	RET
	
STROUT:
	LDE	R0,@RR8
	INCW	RR8
	AND	R0,R0
	JR	Z,SOR
	CALL	CONOUT
	JR	MSGOUT
SOR:
	RET

HEXOUT4:
	LD	R0,R8
	CALL	HEXOUT2
	LD	R0,R9
HEXOUT2:
	PUSH	R0
	RR	R0
	RR	R0
	RR	R0
	RR	R0
	CALL	HEXOUT1
	POP	R0
HEXOUT1:
	AND	R0,#0FH
	ADD	R0,#'0'
	CP	R0,#'9'+1
	JP	C,CONOUT
	ADD	R0,#'A'-'9'-1
	JP	CONOUT

HEXIN:
	CLR	R4
	;CLR	R5
	CALL	HI0
	;OR	R5,R5
	;JR	Z,HIR
	SWAP	R4
HI0:
	CALL	CONIN
	CALL	UPPER
	CP	R0,#'0'
	JR	C,HIR
	CP	R0,#'9'+1
	JR	C,HI1
	CP	R0,#'A'
	JR	C,HIR
	CP	R0,#'F'+1
	JR	NC,HIR
	SUB	R0,#'A'-'9'-1
HI1:
	SUB	R0,#'0'
	OR	R4,R0
	;INC	R5
HIR:
	RET

CRLF:
	LD	R0,#CR
	CALL	CONOUT
	LD	R0,#LF
	JP	CONOUT
	
GETLIN:
	LD	R8,#INBUF
	LD	R2,#0
GL0:
	CALL	CONIN
	CP	R0,#CR
	JR	Z,GLE
	CP	R0,#LF
	JR	Z,GLE
	CP	R0,#BS
	JR	Z,GLB
	CP	R0,#DEL
	JR	Z,GLB
	CP	R0,#' '
	JR	C,GL0
	CP	R0,#80H
	JR	NC,GL0
	CP	R2,#BUFLEN-1
	JR	NC,GL0		; Too long
	INC	R2
	CALL	CONOUT
	LD	@R8,R0
	INC	R8
	JR	GL0
GLB:
	AND	R2,R2
	JR	Z,GL0
	DEC	R2
	DEC	R8
	LD	R0,#BS
	CALL	CONOUT
	LD	R0,#' '
	CALL	CONOUT
	LD	R0,#BS
	CALL	CONOUT
	JR	GL0
GLE:
	CALL	CRLF
	LD	@R8,#0
	RET

SKIPSP:
	LD	R0,@R8
	CP	R0,#' '
	JR	NZ,SSR
	INC	R8
	JR	SKIPSP
SSR:
	RET

UPPER:
	CP	R0,#'a'
	JR	C,UPR
	CP	R0,#'z'+1
	JR	NC,UPR
	ADD	R0,#'A'-'a'
UPR:
	RET

RDHEX:
	LD	R2,#0
	LD	R10,#0
	LD	R11,#0
RH0:
	LD	R0,@R8
	CALL	UPPER
	CP	R0,#'0'
	JR	C,RHE
	CP	R0,#'9'+1
	JR	C,RH1
	CP	R0,#'A'
	JR	C,RHE
	CP	R0,#'F'+1
	JR	NC,RHE
	SUB	R0,#'A'-'9'-1
RH1:
	SUB	R0,#'0'
	SWAP	R0
	RL	R0
	RLC	R11
	RLC	R10
	RL	R0
	RLC	R11
	RLC	R10
	RL	R0
	RLC	R11
	RLC	R10
	RL	R0
	RLC	R11
	RLC	R10
	INC	R8
	INC	R2
	JR	RH0
RHE:
	RET

READ:
	CP	BANK,#'C'
	JR	NZ,RD0
	;; Area CODE
	LDC	R0,@RR8
	RET
RD0:
	CP	BANK,#'D'
	JR	NZ,RD1
	;; Area DATA
	LDE	R0,@RR8
	RET
RD1:
	;; Area REG
	LD	R0,@R9
	RET

WRITE:
	CP	BANK,#'C'
	JR	NZ,WR0
	;; Area CODE
	RET
WR0:
	CP	BANK,#'D'
	JR	NZ,WR1
	;; Area DATA
	LDE	@RR8,R0
	RET
WR1:
	;; Area REG
	LD	@R9,R0
	RET
	
OPNMSG:
	DB	CR,LF,"Universal Monitor Z8",CR,LF,00H

PROMPT:
	DB	"] ",00H

IHEMSG:
	DB	"Error ihex",CR,LF,00H

SHEMSG:
	DB	"Error srec",CR,LF,00H

ERRMSG:
	DB	"Error",CR,LF,00H

DSEP0:
	DB	" :",00H
DSEP1:
	DB	" : ",00H

IHEXER:
        DB	":00000001FF",CR,LF,00H
SRECER:
        DB	"S9030000FC",CR,LF,00H

	
	IF USE_DEV_Z8
	INCLUDE "dev/dev_z8.asm"
	ENDIF

	;;
	;; Work Area
	;; 

	SEGMENT DATA
	ORG	WORK_B

INBUF:	DS	BUFLEN		; Line input buffer
DSADDR:	DS	2		; Dump start address
DEADDR:	DS	2		; Dump end address
DSTATE:	DS	1		; Dump state
GADDR:	DS	2		; Go address
SADDR:	DS	2		; Set address
BANK:	DS	1		; Memory bank
HEXMOD:	DS	1		; HEX file mode

	END
	
