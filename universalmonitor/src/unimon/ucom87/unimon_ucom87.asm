;;;
;;; Universal Monitor for uCOM-87
;;;   Copyright (C) 2021  Haruo Asano
;;;

	CPU	7800

	INCLUDE	"config.inc"

	INCLUDE	"../common.inc"


	IF USE_CPU_7800
	CPU	7800
	ENDIF

	IF USE_CPU_7810
	CPU	7810
	ENDIF

;;;
;;; ROM area
;;;

	ORG	0000H
	JMP	CSTART

	;; SOFTI
	ORG	0060H
	JMP	SOFTIH

	;; 
	;; CALT table
	;; 
	ORG	0080H
	;; 80-83  CALT 80H-
	DW	CSTART
	DW	WSTART0
	DW	CONOUT
	DW	STROUT
	;; 84-    CALT 88H-
	DW	CONIN
	DW	CONST

	ORG	0100H
CSTART:
	LXI	SP,STACK

	IF USE_CPU_7810
	MVI	A,MM_V
	MOV	MM,A
	ENDIF

	CALL	INIT

	LXI	H,RAM_B
	SHLD	DSADDR
	SHLD	SADDR
	SHLD	GADDR
	MVI	A,'I'
	MOV	HEXMOD,A

	IF USE_REGCMD

	;; Initialize register save area
	LXI	H,REG_B
	MVI	C,(REG_E-REG_B)-1
	XRA	A,A
INIR0:
	STAX	H+
	DCR	C
	JR	INIR0

	LXI	H,STACK
	SHLD	REGSP
	LXI	H,RAM_B
	SHLD	REGPC

	ENDIF			; USE_REGCMD

	;; Opening message
	LXI	H,OPNMSG
	CALL	STROUT
	JR	WSTART

WSTART0:
	POP	H		; Drop not needed return address
WSTART:
	LXI	H,PROMPT
	CALL	STROUT
	CALL	GETLIN
	LXI	H,INBUF
	CALL	SKIPSP
	CALL	UPPER
	ONI	A,0FFH
	JR	WSTART
	NEI	A,'D'
	JRE	DUMP
	NEI	A,'G'
	JMP	GO
	NEI	A,'S'
	JMP	SETM

	NEI	A,'L'
	JMP	LOADH
	NEI	A,'P'
	JMP	SAVEH

	IF USE_REGCMD
	NEI	A,'R'
	JMP	REG
	ENDIF

ERR:
	LXI	H,ERRMSG
	CALL	STROUT
	JRE	WSTART

;;; Dump memory

DUMP:
	INX	H
	CALL	SKIPSP
	CALL	RDHEX		; 1st arg.
	MOV	A,C
	EQI	A,0
	JR	DP0
	;; No arg.
	CALL	SKIPSP
	LDAX	H
	EQI	A,0
	JR	ERR
	LHLD	DSADDR
	ADI	L,128
	ACI	H,0
	SHLD	DEADDR
	JRE	DPM
DP0:
	;; 1st arg. found
	SDED	DSADDR
	CALL	SKIPSP
	LDAX	H+
	NEI	A,','
	JR	DP1
	EQI	A,0
	JRE	ERR
	;; No 2nd arg.
	ADI	E,128
	ACI	D,0
	SDED	DEADDR
	JR	DPM
DP1:
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	NEI	C,0
	JRE	ERR
	LDAX	H
	EQI	A,0
	JRE	ERR
	INX	D
	SDED	DEADDR
DPM:
	;; DUMP main
	LHLD	DSADDR
	ANI	L,0F0H
	XRA	A,A
	MOV	DSTATE,A
DPM0:
	CALL	DPL
	CALL	CONST
	NEI	A,1
	JR	DPM1
	MOV	A,DSTATE
	EQI	A,2
	JR	DPM0
	LHLD	DEADDR
	SHLD	DSADDR
	JMP	WSTART
DPM1:
	CALL	CONIN
	SHLD	DSADDR
	JMP	WSTART

	;; Dump line
DPL:
	CALL	HEXOUT4
	PUSH	H
	LXI	H,DSEP0
	CALL	STROUT
	POP	H
	LXI	D,INBUF
	MVI	B,16-1
DPL0:
	CALL	DPB
	DCR	B
	JR	DPL0

	PUSH	H
	LXI	H,DSEP1
	CALL	STROUT

	;; Print ASCII area
	LXI	H,INBUF
	MVI	B,16-1
DPL1:
	LDAX	H+
	GTI	A,' '-1
	JR	DPL2
	LTI	A,7FH
	JR	DPL2
	CALL	CONOUT
	JR	DPL3
DPL2:
	MVI	A,'.'
	CALL	CONOUT
DPL3:
	DCR	B
	JR	DPL1
	POP	H
	JMP	CRLF

	;; Dump byte
DPB:
	MVI	A,' '
	CALL	CONOUT
	MOV	A,DSTATE
	EQI	A,0
	JR	DPB2
	;; Dump state 0
	MOV	A,DSADDR
	EQA	A,L
	JR	DPB0
	MOV	A,DSADDR+1
	NEA	A,H
	JR	DPB1
	;; Still 0 or 2
DPB0:
	MVI	A,' '
	CALL	CONOUT
	CALL	CONOUT
	STAX	D+
	INX	H
	RET
	;; Found start address
DPB1:
	MVI	A,1
	MOV	DSTATE,A
DPB2:
	MOV	A,DSTATE
	EQI	A,1
	JR	DPB0
	;; Dump state 1
	LDAX	H+
	STAX	D+
	CALL	HEXOUT2

	MOV	A,DEADDR
	EQA	A,L
	RET
	MOV	A,DEADDR+1
	EQA	A,H
	RET
	;; Found end address
	MVI	A,2
	MOV	DSTATE,A
	RET

;;; GO address

GO:
	INX	H
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	LDAX	H
	EQI	A,0
	JMP	ERR

	IF USE_REGCMD

	EQI	C,0
	SDED	REGPC

	LSPD	REGSP
	MOV	H,REGPSW
	PUSH	H
	INX	SP
	LHLD	REGPC
	PUSH	H

	IF USE_CPU_7810
	LHLD	REGEAX
	DMOV	EA,HL
	ENDIF
	LHLD	REGVAX
	PUSH	H
	LHLD	REGHLX
	LDED	REGDEX
	LBCD	REGBCX
	POP	V
	EXX
	EXA

	IF USE_CPU_7810
	LHLD	REGEA
	DMOV	EA,HL
	ENDIF
	LHLD	REGVA
	PUSH	H
	LHLD	REGHL
	LDED	REGDE
	LBCD	REGBC
	POP	V

	RETI

	ELSE
	
	EQI	C,0
	SDED	GADDR
	LBCD	GADDR
	JB

	ENDIF

;;; SET memory

SETM:
	INX	H
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	STAX	H
	EQI	A,0
	JMP	ERR
	PUSH	D
	POP	H
	EQI	C,0
	JR	SM0
	LHLD	SADDR
SM0:

SM1:
	CALL	HEXOUT4
	PUSH	H
	LXI	H,DSEP1
	CALL	STROUT
	POP	H
	LDAX	H
	PUSH	H
	CALL	HEXOUT2
	MVI	A,' '
	CALL	CONOUT
	CALL	GETLIN
	LXI	H,INBUF
	CALL	SKIPSP
	LDAX	H
	EQI	A,0
	JR	SM2
	;; Empty (Increment address)
	POP	H
	INX	H
	SHLD	SADDR
	JRE	SM1
SM2:
	EQI	A,'-'
	JR	SM3
	;; '-' (Decrement address)
	POP	H
	DCX	H
	SHLD	SADDR
	JRE	SM1
SM3:
	EQI	A,'.'
	JR	SM4
	;; '.' (Quit)
	POP	H
	SHLD	SADDR
	JMP	WSTART
SM4:
	CALL	RDHEX
	POP	H
	NEI	C,0
	JMP	ERR
	MOV	A,E
	STAX	H+
	SHLD	SADDR
	JRE	SM1

;;; LOAD HEX file

LOADH:
	INX	H
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	LDAX	H
	EQI	A,0
	JMP	ERR
LH0:
	CALL	CONIN
	CALL	UPPER
	NEI	A,'S'
	JMP	LHS0
LH1:
	NEI	A,':'
	JMP	LHI0
LH2:
	;; Skip to EOL
	NEI	A,CR
	JR	LH0
	NEI	A,LF
	JR	LH0
LH3:
	CALL	CONIN
	JR	LH2

LHI0:
	CALL	HEXIN
	MOV	C,A		; Checksum
	MOV	B,A		; Length

	CALL	HEXIN
	MOV	H,A		; Address H
	ADD	C,A		; Checksum

	CALL	HEXIN
	MOV	L,A		; Address L
	ADD	C,A		; Checksum

	;; Add offset
	MOV	A,E
	ADD	L,A
	MOV	A,D
	ADC	H,A

	CALL	HEXIN
	MOV	RECTYP,A
	ADD	C,A		; Checksum
	NEI	A,00H
	JR	LHI00
	NEI	A,01H
	JR	LHI00
	JRE	LH3		; Skip unsupported record type
LHI00:
	NEI	B,0
	JR	LHI3		; Length == 0
	DCR	B
LHI1:
	CALL	HEXIN
	ADD	C,A		; Checksum

	PUSH	V
	MOV	A,RECTYP
	EQI	A,0
	JR	LHI2
	POP	V
	STAX	H+
	JR	LHI20
LHI2:
	POP	V
LHI20:
	DCR	B
	JR	LHI1
LHI3:
	CALL	HEXIN
	ADD	A,C
	EQI	A,0
	JR	LHIE		; Checksum error
	MOV	A,RECTYP
	EQI	A,1
	JRE	LH3
	JMP	WSTART
LHIE:
	LXI	H,IHEMSG
	CALL	STROUT
	JMP	WSTART

LHS0:	
	CALL	CONIN
	NEI	A,'1'
	JR	LHS00
	NEI	A,'9'
	JR	LHS01
	JRE	LH3		; Unsupported record type
LHS00:
	MVI	A,0
LHS01:
	MVI	A,1
	MOV	RECTYP,A

	CALL	HEXIN
	MOV	B,A		; Length+3
	MOV	C,A		; Checksum

	CALL	HEXIN
	MOV	H,A		; Address H
	ADD	C,A		; Checksum

	CALL	HEXIN
	MOV	L,A		; Address L
	ADD	C,A		; Checksum

	;; Add offset
	MOV	A,E
	ADD	L,A
	MOV	A,D
	ADC	H,A

	GTI	B,3
	JR	LHS3
	SUI	B,3+1
LHS1:
	CALL	HEXIN
	ADD	C,A		; Checksum

	PUSH	V
	MOV	A,RECTYP
	EQI	A,0
	JR	LHS2
	POP	V
	STAX	H+
	JR	LHS20
LHS2:
	POP	V
LHS20:
	DCR	B
	JR	LHS1
LHS3:
	CALL	HEXIN
	ADD	A,C
	EQI	A,0FFH
	JR	LHSE		; Checksum error
	MOV	A,RECTYP
	EQI	A,1
	JRE	LH3
	JMP	WSTART
LHSE:
	LXI	H,SHEMSG
	CALL	STROUT
	JMP	WSTART

;;; SAVE HEX file

SAVEH:
	INX	H
	LDAX	H
	CALL	UPPER
	NEI	A,'I'
	JR	SH0
	EQI	A,'S'
	JR	SH1
SH0:
	MOV	HEXMOD,A
	INX	H
SH1:
	CALL	SKIPSP
	CALL	RDHEX
	NEI	C,0
	JMP	ERR
	SDED	PT0		; Start address
	CALL	SKIPSP
	LDAX	H+
	EQI	A,','
	JMP	ERR
	CALL	SKIPSP
	CALL	RDHEX
	NEI	C,0
	JMP	ERR
	CALL	SKIPSP
	LDAX	H
	EQI	A,0
	JMP	ERR
SH2:
	INX	D
	MOV	A,PT0
	SUB	E,A
	MOV	A,PT0+1
	SBB	D,A		; DE = Length
	LHLD	PT0		; HL = Start address
SH3:
	CALL	SHL
	EQI	D,0
	JR	SH3
	EQI	E,0
	JR	SH3

	MOV	A,HEXMOD
	EQI	A,'I'
	JR	SH4
	
	LXI	H,IHEXER
SH4:
	LXI	H,SRECER
	CALL	STROUT
	JMP	WSTART

SHL:
	MVI	B,16
	EQI	D,0
	JR	SHL0
	MOV	A,E
	LTA	A,B
	JR	SHL0
	MOV	B,A
SHL0:
	MOV	A,B
	SUB	E,A
	SBI	D,0

	MOV	A,HEXMOD
	EQI	A,'I'
	JRE	SHLS

	;; Intel HEX
	MVI	A,':'
	CALL	CONOUT

	MOV	A,B		; Length
	MOV	C,A		; Checksum
	CALL	HEXOUT2

	MOV	A,H		; Address H
	ADD	C,A		; Checksum
	CALL	HEXOUT2

	MOV	A,L		; Address L
	ADD	C,A		; Checksum
	CALL	HEXOUT2

	XRA	A,A
	CALL	HEXOUT2

	DCR	B
SHLI0:
	LDAX	H+
	ADD	C,A		; Checksum
	CALL	HEXOUT2

	DCR	B
	JR	SHLI0

	MOV	A,C
	NEGA
	CALL	HEXOUT2
	JMP	CRLF

SHLS:
	;; Motorola S record
	MVI	A,'S'
	CALL	CONOUT
	MVI	A,'1'
	CALL	CONOUT

	MOV	A,B
	ADI	A,2+1		; DataLength + Addr(2) + Sum(1)
	MOV	C,A		; Checksum
	CALL	HEXOUT2

	MOV	A,H		; Address H
	ADD	C,A		; Checksum
	CALL	HEXOUT2

	MOV	A,L		; Address L
	ADD	C,A		; Checksum
	CALL	HEXOUT2

	DCR	B
SHLS0:
	LDAX	H+
	ADD	C,A		; Checksum
	CALL	HEXOUT2

	DCR	B
	JR	SHLS0

	MOV	A,C
	XRI	A,0FFH
	CALL	HEXOUT2
	JMP	CRLF	

;;; Register

	IF USE_REGCMD

REG:
	INX	H
	CALL	SKIPSP
	LDAX	H
	CALL	UPPER
	EQI	A,0
	JR	RG0
	CALL	RDUMP
	JMP	WSTART
RG0:
	LXI	D,RNTAB
RG1:
	NEAX	D
	JR	RG2		; Character match
	MOV	C,A
	INX	D
	LDAX	D
	NEI	A,0
	JMP	ERR		; Found end mark
	MOV	A,C
	ADI	E,5
	ACI	D,0
	JR	RG1
RG2:
	INX	D
	LDAX	D
	EQI	A,0FH
	JR	RG3
	;; Next table
	INX	D
	LDAX	D+
	MOV	C,A
	LDAX	D
	MOV	D,A
	MOV	A,C
	MOV	E,A
	INX	H
	LDAX	H
	CALL	UPPER
	JRE	RG1
RG3:
	NEI	A,0
	JMP	ERR		; Found end mark

	LDAX	D+
	MOV	C,A
	LDAX	D+
	MOV	L,A
	LDAX	D+
	MOV	H,A
	PUSH	H		; Reg storage address
	LDAX	D+
	MOV	B,A
	LDAX	D
	MOV	H,A
	MOV	A,B
	MOV	L,A		; HL: Reg name
	CALL	STROUT
	MVI	A,'='
	CALL	CONOUT

	ANI	C,07H
	EQI	C,1
	JR	RG4
	;; 8 bit register
	POP	H
	LDAX	H
	PUSH	H
	CALL	HEXOUT2
	JR	RG5
RG4:
	;; 16 bit register
	POP	H
	INX	H
	LDAX	H-
	CALL	HEXOUT2
	LDAX	H
	CALL	HEXOUT2
	PUSH	H
RG5:
	MVI	A,' '
	CALL	CONOUT
	PUSH	B		; C: reg size
	CALL	GETLIN
	LXI	H,INBUF
	CALL	SKIPSP
	CALL	RDHEX
	NEI	C,0
	JMP	WSTART
	POP	B
	POP	H
	EQI	C,1
	JR	RG6
	;; 8 bit register
	MOV	A,E
	STAX	H
	JR	RG7
RG6:
	;; 16 bit register
	MOV	A,E
	STAX	H+
	MOV	A,D
	STAX	H
RG7:
	JMP	WSTART

RDUMP:
	LXI	D,RDTAB
RD0:
	LDAX	D+
	MOV	L,A
	LDAX	D+
	MOV	H,A
	ORA	A,L
	NEI	A,0
	JMP	CRLF		; End
	CALL	STROUT

	LDAX	D+
	MOV	L,A
	LDAX	D+
	MOV	H,A
	LDAX	D+
	EQI	A,1
	JR	RD1
	;; 1 byte
	LDAX	H
	CALL	HEXOUT2
	JR	RD0
RD1:
	;; 2 byte
	INX	H
	LDAX	H-
	CALL	HEXOUT2		; High byte
	LDAX	H
	CALL	HEXOUT2		; Low byte
	JRE	RD0
	
	ENDIF			; USE_REGCMD

	;;
	;; Other support routines
	;;

STROUT:
	LDAX	H+
	NEI	A,0
	RET
	CALL	CONOUT
	JR	STROUT

HEXOUT4:
	MOV	A,H
	CALL	HEXOUT2
	MOV	A,L
HEXOUT2:
	PUSH	V
	IF USE_CPU_7800
	SHAR
	SHAR
	SHAR
	SHAR
	ENDIF
	IF USE_CPU_7810
	SLR	A
	SLR	A
	SLR	A
	SLR	A
	ENDIF
	CALL	HEXOUT1
	POP	V
HEXOUT1:
	ANI	A,0FH
	ADI	A,'0'
	GTI	A,'9'
	JMP	CONOUT
	ADI	A,'A'-'9'-1
	JMP	CONOUT

HEXIN:
	XRA	A,A
	CALL	HI0
	IF USE_CPU_7800
	SHAL
	SHAL
	SHAL
	SHAL
	ENDIF
	IF USE_CPU_7810
	SLL	A
	SLL	A
	SLL	A
	SLL	A
	ENDIF
HI0:
	PUSH	B
	MOV	C,A
	CALL	CONIN
	CALL	UPPER
	GTI	A,'0'-1
	JR	HIR
	GTI	A,'9'
	JR	HI1
	GTI	A,'A'-1
	JR	HIR
	LTI	A,'F'+1
	JR	HIR
	SUI	A,'A'-'9'-1
HI1:
	SUI	A,'0'
	ORA	A,C
HIR:
	POP	B
	RET

CRLF:
	MVI	A,CR
	CALL	CONOUT
	MVI	A,LF
	JMP	CONOUT

GETLIN:
	LXI	H,INBUF
	MVI	B,0
GL0:
	CALL	CONIN
	NEI	A,CR
	JRE	GLE
	NEI	A,LF
	JRE	GLE
	NEI	A,BS
	JR	GLB
	NEI	A,DEL
	JR	GLB
	GTI	A,' '-1
	JR	GL0
	LTI	A,80H
	JR	GL0
	MOV	C,A
	MOV	A,B
	LTI	A,BUFLEN-1
	JR	GL0		; Too long
	INR	B		; Never overflows
	MOV	A,C
	CALL	CONOUT
	STAX	H+
	JRE	GL0
GLB:
	MOV	A,B
	NEI	A,0
	JRE	GL0
	DCR	B		; Never overflows
	DCX	H
	MVI	A,BS
	CALL	CONOUT
	MVI	A,' '
	CALL	CONOUT
	MVI	A,BS
	CALL	CONOUT
	JRE	GL0
GLE:
	CALL	CRLF
	XRA	A,A
	STAX	H
	RET

SKIPSP:
	LDAX	H
	EQI	A,' '
	RET
	INX	H
	JR	SKIPSP

UPPER:
	GTI	A,'a'-1
	RET
	LTI	A,'z'+1
	RET
	ADI	A,'A'-'a'
	RET

RDHEX:
	MVI	E,0
	LXI	B,0
RH0:
	LDAX	H+
	CALL	UPPER
	GTI	A,'0'-1
	JRE	RHE
	GTI	A,'9'
	JR	RH1
	GTI	A,'A'-1
	JRE	RHE
	LTI	A,'F'+1
	JRE	RHE
	SUI	A,'A'-'9'-1
RH1:
	SUI	A,'0'
	IF USE_CPU_7800
	PUSH	V
	MOV	A,B
	SHAL
	SHAL
	SHAL
	SHAL
	MOV	B,A
	MOV	A,C
	SHAR
	SHAR
	SHAR
	SHAR
	ADD	B,A
	MOV	A,C
	SHAL
	SHAL
	SHAL
	SHAL
	MOV	C,A
	POP	V
	ADD	C,A
	ENDIF
	IF USE_CPU_7810
	RLL	A
	RLL	A
	RLL	A
	RLL	A
	RLL	A
	RLL	C
	RLL	B
	RLL	A
	RLL	C
	RLL	B
	RLL	A
	RLL	C
	RLL	B
	RLL	A
	RLL	C
	RLL	B
	ENDIF
	ADI	E,1
	JRE	RH0
RHE:
	DCX	H
	PUSH	B
	MOV	A,E
	MOV	C,A
	POP	D
	RET

	;;
	;; SOFTI Handter
	;;
SOFTIH:
	IF USE_REGCMD

	PUSH	V
	SBCD	REGBC
	SDED	REGDE
	SHLD	REGHL
	POP	H
	SHLD	REGVA
	IF USE_CPU_7810
	DMOV	HL,EA
	SHLD	REGEA
	ENDIF

	EXA
	EXX
	PUSH	V
	SBCD	REGBCX
	SDED	REGDEX
	SHLD	REGHLX
	POP	H
	SHLD	REGVAX
	IF USE_CPU_7810
	DMOV	HL,EA
	SHLD	REGEAX
	ENDIF

	POP	H
	IF USE_CPU_7810
	DCX	H		; Adjust PC to point SOFTI
	ENDIF
	SHLD	REGPC
	DCX	SP
	POP	H
	MOV	REGPSW,H
	SSPD	REGSP

	LXI	SP,STACK
	LXI	H,SOFTIMSG
	CALL	STROUT
	CALL	RDUMP
	JMP	WSTART

	ELSE			; USE_REGCMD

	LXI	SP,STACK
	LXI	H,SOFTIMSG
	CALL	STROUT
	JMP	WSTART

	ENDIF			; USE_REGCMD

OPNMSG:
	DB	CR,LF,"Universal Monitor uCOM-87",CR,LF,00H

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

SOFTIMSG:
	DB	"SOFTI",CR,LF,00H

	IF USE_REGCMD

	;; Register dump table
RDTAB:
	IF USE_CPU_7810
	DW	RDSEA,  REGEA
	DB	2
	ENDIF
	DW	RDSV,   REGVA+1
	DB	1
	DW	RDSA,   REGVA
	DB	1
	DW	RDSBC,  REGBC
	DB	2
	DW	RDSDE,  REGDE
	DB	2
	DW	RDSHL,  REGHL
	DB	2
	DW	RDSPC,  REGPC
	DB	2
	DW	RDSSP,  REGSP
	DB	2

	IF USE_CPU_7810
	DW	RDSEAX, REGEAX
	DB	2
	ENDIF
	DW	RDSVX,  REGVAX+1
	DB	1
	DW	RDSAX,  REGVAX
	DB	1
	DW	RDSBCX, REGBCX
	DB	2
	DW	RDSDEX, REGDEX
	DB	2
	DW	RDSHLX, REGHLX
	DB	2
	DW	RDSPSW, REGPSW
	DB	1

	DW	0000H, 0000H
	DB	0

	IF USE_CPU_7800
RDSV:	DB	"V =", 00H
	ENDIF
	IF USE_CPU_7810
RDSEA:	DB	"EA =",00H
RDSV:	DB	" V =", 00H
	ENDIF
RDSA:	DB	" A =", 00H
RDSBC:	DB	" BC =",00H
RDSDE:	DB	" DE =",00H
RDSHL:	DB	" HL =",00H
RDSPC:	DB	"  PC=",00H
RDSSP:	DB	" SP=",00H

	IF USE_CPU_7800
RDSVX:	DB	CR,LF,"V'=", 00H
	ENDIF
	IF USE_CPU_7810
RDSEAX:	DB	CR,LF,"EA'=",00H
RDSVX:	DB	" V'=", 00H
	ENDIF
RDSAX:	DB	" A'=", 00H
RDSBCX:	DB	" BC'=",00H
RDSDEX:	DB	" DE'=",00H
RDSHLX:	DB	" HL'=",00H
RDSPSW:	DB	"  PSW=",00H

RNTAB:
	DB	'A',0FH		; "A?"
	DW	RNTABA,0
	DB	'B',0FH		; "B?"
	DW	RNTABB,0
	DB	'C',0FH		; "C?"
	DW	RNTABC,0
	DB	'D',0FH		; "D?"
	DW	RNTABD,0
	DB	'E',0FH		; "E?"
	DW	RNTABE,0
	DB	'H',0FH		; "H?"
	DW	RNTABH,0
	DB	'L',0FH		; "L?"
	DW	RNTABL,0
	DB	'P',0FH		; "P?"
	DW	RNTABP,0
	DB	'S',0FH		; "S?"
	DW	RNTABS,0
	DB	'V',0FH		; "V?"
	DW	RNTABV,0

	DB	00H,0		; End mark

RNTABA:
	DB	00H,1		; "A"
	DW	REGVA,RNA
	DB	'\'',1		; "A'"
	DW	REGVAX,RNAX

	DB	00H,0

RNTABB:
	DB	00H,1		; "B"
	DW	REGBC+1,RNB
	DB	'\'',1		; "B'"
	DW	REGBCX+1,RNBX
	DB	'C',0FH		; "BC?"
	DW	RNTABBC,0

	DB	00H,0	

RNTABBC:
	DB	00H,2		; "BC"
	DW	REGBC,RNBC
	DB	'\'',2		; "BC'"
	DW	REGBCX,RNBCX

	DB	00H,0	

RNTABC:
	DB	00H,1		; "C"
	DW	REGBC,RNC
	DB	'\'',1		; "C'"
	DW	REGBCX,RNCX

	DB	00H,0	
	
RNTABD:
	DB	00H,1		; "D"
	DW	REGDE+1,RND
	DB	'\'',1		; "D'"
	DW	REGDEX+1,RNDX
	DB	'E',0FH		; "DE?"
	DW	RNTABDE,0

	DB	00H,0	

RNTABDE:
	DB	00H,2		; "DE"
	DW	REGDE,RNDE
	DB	'\'',2		; "DE'"
	DW	REGDEX,RNDEX

	DB	00H,0	

RNTABE:
	DB	00H,1		; "E"
	DW	REGDE,RNE
	DB	'\'',1		; "E'"
	DW	REGDEX,RNEX
	IF USE_CPU_7810
	DB	'A',0FH		; "EA?"
	DW	RNTABEA,0
	ENDIF

	DB	00H,0	

	IF USE_CPU_7810
RNTABEA:
	DB	00H,2		; "EA"
	DW	REGEA,RNEA
	DB	'\'',2		; "EA'"
	DW	REGEAX,RNEAX

	DB	00H,0
	ENDIF

RNTABH:
	DB	00H,1		; "H"
	DW	REGHL+1,RNH
	DB	'\'',1		; "H'"
	DW	REGHLX+1,RNHX
	DB	'L',0FH		; "HL?"
	DW	RNTABHL,0

	DB	00H,0	

RNTABHL:
	DB	00H,2		; "HL"
	DW	REGHL,RNHL
	DB	'\'',2		; "HL'"
	DW	REGHLX,RNHLX

	DB	00H,0	

RNTABL:
	DB	00H,1		; "L"
	DW	REGHL,RNL
	DB	'\'',1		; "L'"
	DW	REGHLX,RNLX

	DB	00H,0	

RNTABP:
	DB	'C',2		; "PC"
	DW	REGPC,RNPC
	DB	'S',0FH		; "PS?"
	DW	RNTABPS,0

	DB	00H,0	

RNTABPS:
	DB	'W',1		; "PSW"
	DW	REGPSW,RNPSW

	DB	00H,0	

RNTABS:
	DB	'P',2		; "SP"
	DW	REGSP,RNSP

	DB	00H,0
	
RNTABV:
	DB	00H,1		; "V"
	DW	REGVA+1,RNV
	DB	'\'',1		; "V'"
	DW	REGVAX+1,RNVX

	DB	00H,0	


RNA:	DB	"A",00H
RNAX:	DB	"A'",00H
RNB:	DB	"B",00H
RNBX:	DB	"B'",00H
RNBC:	DB	"BC",00H
RNBCX:	DB	"BC'",00H
RNC:	DB	"C",00H
RNCX:	DB	"C'",00H
RND:	DB	"D",00H
RNDX:	DB	"D'",00H
RNDE:	DB	"DE",00H
RNDEX:	DB	"DE'",00H
RNE:	DB	"E",00H
RNEX:	DB	"E'",00H
	IF USE_CPU_7810
RNEA:	DB	"EA",00H
RNEAX:	DB	"EA'",00H
	ENDIF
RNH:	DB	"H",00H
RNHX:	DB	"H'",00H
RNHL:	DB	"HL",00H
RNHLX:	DB	"HL'",00H
RNL:	DB	"L",00H
RNLX:	DB	"L'",00H
RNPC:	DB	"PC",00H
RNPSW:	DB	"PSW",00H
RNSP:	DB	"SP",00H
RNV:	DB	"V",00H
RNVX:	DB	"V'",00H

	ENDIF

	;;
	;; Console Drivers
	;;

	IF USE_DEV_7810
	INCLUDE	"dev/dev_7810.asm"
	ENDIF

	IF USE_DEV_EMILY
	INCLUDE	"dev/dev_emily.asm"
	ENDIF

;;;
;;; RAM area
;;;
	
	;;
	;; Work area
	;;

	ORG	WORK_B

INBUF:	DS	BUFLEN		; Line input buffer
DSADDR:	DS	2		; Dump start address
DEADDR:	DS	2		; Dump end address
DSTATE:	DS	1		; Dump state
GADDR:	DS	2		; Go address
SADDR:	DS	2		; Set address
HEXMOD:	DS	1		; HEX file mode
RECTYP:	DS	1		; Record Type

PT0:	DS	2		; Temporary pointer

	IF USE_REGCMD
REG_B:
	IF USE_CPU_7810
REGEA:	DS	2
	ENDIF
REGVA:	DS	2
REGBC:	DS	2
REGDE:	DS	2
REGHL:	DS	2
	IF USE_CPU_7810
REGEAX:	DS	2
	ENDIF
REGVAX:	DS	2
REGBCX:	DS	2
REGDEX:	DS	2
REGHLX:	DS	2
REGPC:	DS	2
REGSP:	DS	2
REGPSW:	DS	1
REG_E:
	ENDIF			; USE_REGCMD

	IFDEF MEMREQ
DEVMEM:	DS	MEMREQ
	ENDIF

	END
