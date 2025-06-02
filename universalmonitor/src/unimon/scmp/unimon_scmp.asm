;;;
;;;	Universal Monitor for National Semiconductor SC/MP
;;;

	CPU	sc/mp

TARGET:	EQU	"SC/MP"


	INCLUDE	"config.inc"

	INCLUDE	"../common.inc"
	INCLUDE	"scmp.inc"

disp	function	x,(x - WORK_B)

;;;
;;; ROM	area
;;;

	ORG	0x0000

	NOP			; Dummy
	DINT
	LJMP	CSTART

	;;
	;;
	;;

	ORG	0x0100
CSTART:
	LDPI0	P1,STACK
	LDPI0	P2,WORK_B
	
	CALL	INIT

	LDI	0x08
	ST	disp(DSADDR)(P2)
	ST	disp(SADDR)(P2)
	ST	disp(GADDR)(P2)
	LDI	0x00
	ST	disp(DSADDR+1)(P2)
	ST	disp(SADDR+1)(P2)
	ST	disp(GADDR+1)(P2)
	LDI	'I'
	ST	disp(HEXMOD)(P2)

	;; Opening message
	LDI	high(OPNMSG)
	ST	disp(PT0)(P2)
	LDI	low(OPNMSG)
	ST	disp(PT0+1)(P2)
	CALL	STROUT

WSTART:
	LDI	high(PROMPT)
	ST	disp(PT0)(P2)
	LDI	low(PROMPT)
	ST	disp(PT0+1)(P2)
	CALL	STROUT
	CALL	GETLIN
	LDPI	P3,INBUF
	CALL	SKIPSP
	CALL	UPPER
	JZ	WSTART
	XAE			; backup A

	LDE
	SCL
	CAI	'D'
	JNZ	M00
	LJMPP	DUMP
M00:
	LDE
	SCL
	CAI	'G'
	JNZ	M01
	LJMPP	GO
M01:
	LDE
	SCL
	CAI	'S'
	JNZ	M02
	LJMPP	SETM
M02:

ERR:
	LDI	high(ERRMSG)
	ST	disp(PT0)(P2)
	LDI	low(ERRMSG)
	ST	disp(PT0+1)(P2)
	CALL	STROUT	
	LJMP	WSTART

;;;
;;; Dump memory
;;;
DUMP:
	PULP	P3
	LD	@1(P3)		; INC P3
	CALL	SKIPSP
	CALL	RDHEX
	LD	disp(CNT)(P2)
	JNZ	DP0
	;; No arg.
	CALL	SKIPSP
	LD	0(P3)
	JNZ	ERR
DP00:	
	LD	disp(DSADDR+1)(P2)
	CCL
	ADI	128
	ST	disp(DEADDR+1)(P2)
	LD	disp(DSADDR)(P2)
	ADI	0
	ST	disp(DEADDR)(P2)
	LJMP	DPM
	;; 1st arg. found
DP0:
	LD	disp(RHVAL+1)(P2) ; DSADDR = RHVAL
	ST	disp(DSADDR+1)(P2)
	LD	disp(RHVAL)(P2)
	ST	disp(DSADDR)(P2)
	CALL	SKIPSP
	LD	0(P3)
	SCL
	CAI	','
	JZ	DP1
	LD	0(P3)
	JZ	DP00		; No 2nd arg.
	LJMP	ERR
	;;
DP1:
	LD	@1(P3)
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	LD	disp(CNT)(P2)
	JZ	DP1E
	LD	0(P3)
	JNZ	DP1E
	LD	disp(RHVAL+1)(P2)
	CCL
	ADI	1
	ST	disp(DEADDR+1)(P2)
	LD	disp(RHVAL)(P2)
	ADI	0
	ST	disp(DEADDR)(P2)
	JMP	DPM
DP1E:
	LJMP	ERR
DPM:
	LD	disp(DSADDR+1)(P2)
	ANI	0xF0
	ST	disp(PT1+1)(P2)
	LD	disp(DSADDR)(P2)
	ST	disp(PT1)(P2)
	LDI	0
	ST	disp(DSTATE)(P2)
DPM0:
	CALL	DPL
	;;
	;;
	CALL	CONST
	JNZ	DPM1
	LD	disp(DSTATE)(P2)
	SCL
	CAI	2
	JP	DPM01
	JMP	DPM0
DPM01:
	LD	disp(DEADDR+1)(P2)
	ST	disp(DSADDR+1)(P2)
	LD	disp(DEADDR)(P2)
	ST	disp(DSADDR)(P2)
	LJMP	WSTART
DPM1:	
	LD	disp(PT1+1)(P2)
	ST	disp(DSADDR+1)(P2)
	LD	disp(PT1)(P2)
	ST	disp(DSADDR)(P2)
	CALL	CONIN
	LJMP	WSTART

	;; Dump line
DPL:
	PSHP	P3
	LD	disp(PT1)(P2)
	CALL	HEXOUT2
	LD	disp(PT1+1)(P2)
	CALL	HEXOUT2
	LDI	high(DSEP0)
	ST	disp(PT0)(P2)
	LDI	low(DSEP0)
	ST	disp(PT0+1)(P2)
	CALL	STROUT

	LDI	0		; Assume disp(INBUF) == 0
	XAE
	LDI	16
	ST	disp(CNT)(P2)
DPL0:
	CALL	DPB
	DLD	disp(CNT)(P2)
	JNZ	DPL0

	LDI	high(DSEP1)
	ST	disp(PT0)(P2)
	LDI	low(DSEP1)
	ST	disp(PT0+1)(P2)
	CALL	STROUT	

	;; Print ASCII area
	LDPI	P3,INBUF
	LDI	16
	ST	disp(CNT)(P2)
DPL1:
	LD	@1(P3)
	SCL
	CAI	' '
	JP	DPL3
DPL2:	
	LDI	'.'
	JMP	DPL4
DPL3:
	LD	-1(P3)
	SCL
	CAI	0x7F
	JP	DPL2
	LD	-1(P3)
DPL4:
	CALL	CONOUT
	DLD	disp(CNT)(P2)
	JNZ	DPL1

	CALL	CRLF
	PULP	P3
	RET

	;; Dump byte
DPB:
	PSHP	P3
	LDI	' '
	CALL	CONOUT
	LD	disp(DSTATE)(P2)
	JNZ	DPB2
	;; Dump state 0
	LD	disp(DSADDR)(P2)
	SCL
	CAD	disp(PT1)(P2)
	JNZ	DPB0
	LD	disp(DSADDR+1)(P2)
	SCL
	CAD	disp(PT1+1)(P2)
	JZ	DPB1
	;; Still 0 or 2
DPB0:
	LDI	' '
	CALL	CONOUT
	LDI	' '
	CALL	CONOUT

	LDI	16
	SCL
	CAD	disp(CNT)(P2)
	XAE
	LDI	' '
	ST	-128(P2)		; (P2 + E)

	LD	disp(PT1+1)(P2)
	CCL
	ADI	1
	ST	disp(PT1+1)(P2)
	LD	disp(PT1)(P2)
	ADI	0
	ST	disp(PT1)(P2)

	PULP	P3
	RET
	;; Found start address
DPB1:
	LDI	1
	ST	disp(DSTATE)(P2)
DPB2:
	LD	disp(DSTATE)(P2)
	SCL
	CAI	1
	JNZ	DPB0
	;; Dump state 1
	LD	disp(PT1)(P2)
	XPAH	P3
	LD	disp(PT1+1)(P2)
	XPAL	P3
	LD	0(P3)
	ST	@-1(P1)
	CALL	HEXOUT2
	LD	@1(P1)
	XAE
	LDI	16
	SCL
	CAD	disp(CNT)(P2)
	XAE
	ST	-128(P2)		; (P2 + E)

	LD	disp(PT1+1)(P2)
	CCL
	ADI	1
	ST	disp(PT1+1)(P2)
	LD	disp(PT1)(P2)
	ADI	0
	ST	disp(PT1)(P2)
	SCL
	CAD	disp(DEADDR)(P2)
	JNZ	DPBE
	LD	disp(PT1+1)(P2)
	SCL
	CAD	disp(DEADDR+1)(P2)
	JNZ	DPBE
	;; Found end address
	LDI	2
	ST	disp(DSTATE)(P2)
DPBE:
	PULP	P3
	RET

;;;
;;; GO address
;;;
GO:
	PULP	P3
	LD	@1(P3)		; INC P3
	CALL	SKIPSP
	CALL	RDHEX
	LD	0(P3)
	JZ	GO0
	LJMP	ERR
GO0:
	LD	disp(CNT)(P2)
	JZ	G0
	LD	disp(RHVAL+1)(P2)
	ST	disp(GADDR+1)(P2)
	LD	disp(RHVAL)(P2)
	ST	disp(GADDR)(P2)
G0:
	LD	disp(GADDR+1)(P2)
	SCL
	CAI	1
	XPAL	P3
	LD	disp(GADDR)(P2)
	CAI	0
	XPAH	P3
	XPPC	P3

;;;
;;; Set memory
;;;
SETM:
	PULP	P3
	LD	@1(P3)		; INC P3
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	LD	0(P3)
	JZ	SM0
	LJMP	ERR
SM0:
	LD	disp(CNT)(P2)
	JZ	SM1
	LD	disp(RHVAL)(P2)
	ST	disp(SADDR)(P2)
	LD	disp(RHVAL+1)(P2)
	ST	disp(SADDR+1)(P2)
SM1:
	LD	disp(SADDR)(P2)
	CALL	HEXOUT2
	LD	disp(SADDR+1)(P2)
	CALL	HEXOUT2

	LDI	high(DSEP1)
	ST	disp(PT0)(P2)
	LDI	low(DSEP1)
	ST	disp(PT0+1)(P2)
	CALL	STROUT	

	LD	disp(SADDR)(P2)
	XPAH	P3
	LD	disp(SADDR+1)(P2)
	XPAL	P3
	LD	0(P3)
	CALL	HEXOUT2
	LDI	' '
	CALL	CONOUT

	CALL	GETLIN
	LDPI	P3,INBUF
	CALL	SKIPSP
	LD	0(P3)
	XAE
	LDE
	JNZ	SM2
	;; Empty (Increment address)
SM10:	
	LD	disp(SADDR+1)(P2)
	CCL
	ADI	1
	ST	disp(SADDR+1)(P2)
	LD	disp(SADDR)(P2)
	ADI	0
	ST	disp(SADDR)(P2)
	LJMP	SM1
SM2:
	LDE
	SCL
	CAI	'-'
	JNZ	SM3
	;; '-' (Decrement address)
	LD	disp(SADDR+1)(P2)
	SCL
	CAI	1
	ST	disp(SADDR+1)(P2)
	LD	disp(SADDR)(P2)
	CAI	0
	ST	disp(SADDR)(P2)
	LJMP	SM1
SM3:
	LDE
	SCL
	CAI	'.'
	JNZ	SM4
	;; '.' (Quit)
	LJMP	WSTART
SM4:
	CALL	RDHEX
	LD	disp(CNT)(P2)
	JNZ	SM5
	LJMP	ERR
SM5:
	LD	disp(SADDR)(P2)
	XPAH	P3
	LD	disp(SADDR+1)(P2)
	XPAL	P3
	LD	disp(RHVAL+1)(P2)
	ST	0(P3)
	JMP	SM10

;;;
;;; Other support routines
;;;

STROUT:
	PSHP	P3
	LD	disp(PT0)(P2)
	XPAH	P3
	LD	disp(PT0+1)(P2)
	XPAL	P3
SOUT0:
	LD	@1(P3)
	JZ	SOUT1
	CALL	CONOUT
	JMP	SOUT0
SOUT1:
	PULP	P3
	RET

HEXOUT2:
	ST	@-1(P1)		; PUSH AC
	RR
	RR
	RR
	RR
	CALL	HEXOUT1
	LD	@1(P1)		; PULL AC
HEXOUT1:
	ANI	0x0F
	CCL
	ADI	'0'
	XAE
	LDE
	SCL
	CAI	'9'+1
	JP	HEXOUT0
	LDE
HEXOUTE:	
	CALL	CONOUT
	RET
HEXOUT0:
	LDE
	CCL
	ADI	'A'-'9'-1
	JMP	HEXOUTE

CRLF:
	LDI	CR
	CALL	CONOUT
	LDI	LF
	CALL	CONOUT
	RET

GETLIN:
	PSPI	P3,INBUF
	LDI	0
	ST	disp(CNT)(P2)
	LD	@-1(P1)		; 
	JMP	GL0
GL0LJ:				; for LJMP
	PULP	P3
GL0:
	CALL	CONIN
	ST	0(P1)		; PUSH ch
	SCL
	CAI	CR
	JZ	GLE
	LD	0(P1)
	SCL
	CAI	LF
	JNZ	GL1
GLE:
	LD	@1(P1)		; Drop stack top
	CALL	CRLF
	LDI	0
	ST	0(P3)
	PULP	P3
	RET
GL1:
	LD	0(P1)
	SCL
	CAI	BS
	JZ	GLB
	LD	0(P1)
	SCL
	CAI	DEL
	JNZ	GL2
GLB:
	LD	disp(CNT)(P2)
	JZ	GL9
	DLD	disp(CNT)(P2)
	LD	@-1(P3)		; DEC P3
	LDI	BS
	CALL	CONOUT
	LDI	' '
	CALL	CONOUT
	LDI	BS
	CALL	CONOUT
GL2:
	LD	0(P1)
	SCL
	CAI	' '
	CSA
	ANI	0x80		; CY/L flag
	JZ	GL9		; 0x00-0x1F
	LD	0(P1)
	ANI	0x80
	JNZ	GL9		; 0x80-0xFF
	LD	disp(CNT)(P2)
	SCL
	CAI	BUFLEN-1
	JP	GL9
	ILD	disp(CNT)(P2)
	LD	0(P1)
	ST	@1(P3)
	CALL	CONOUT
	JMP	GL9
GL9:
	LJMPP	GL0LJ

SKIPSP:
	ENTER
SS0:
	LD	@1(P3)
	SCL
	CAI	' '
	JNZ	SSR
	JMP	SS0
SSR:
	LD	@-1(P3)
	LEAVE
	RET

UPPER:
	ST	@-1(P1)		; PUSH A
	SCL
	CAI	'a'
	JP	UP0
	JMP	UPR
UP0:
	LD	0(P1)
	SCL
	CAI	'z'+1
	JP	UPR
	LD	@1(P1)		; PULL A
	CCL
	ADI	'A'-'a'
	RET
UPR:	
	LD	@1(P1)		; PULL A
	RET

RDHEX:
	ENTER
	LDI	0
	ST	disp(CNT)(P2)
	ST	disp(RHVAL)(P2)
	ST	disp(RHVAL+1)(P2)
RH0:
	LD	@1(P3)
	CALL	UPPER
	XAE			; Backup to E-reg
	LDE
	SCL
	CAI	'0'
	JP	RH01
	JMP	RHE
RH01:
	LDE
	SCL
	CAI	'9'+1
	JP	RH02
	LDE
	JMP	RH1
RH02:
	LDE
	SCL
	CAI	'A'
	JP	RH03
	JMP	RHE
RH03:
	LDE
	SCL
	CAI	'F'+1
	JP	RHE
	LDE
	SCL
	CAI	'A'-'9'-1
RH1:
	SCL
	CAI	'0'
	ST	@-1(P1)
	LD	disp(RHVAL)(P2)	; RHVAL[15:8]
	RR
	RR
	RR
	RR
	ANI	0xF0
	ST	disp(RHVAL)(P2)
	LD	disp(RHVAL+1)(P2) ; RHVAL[7:0]
	RR
	RR
	RR
	RR
	ST	@-1(P1)
	ANI	0x0F
	OR	disp(RHVAL)(P2)
	ST	disp(RHVAL)(P2)
	LD	@1(P1)
	ANI	0xF0
	OR	@1(P1)
	ST	disp(RHVAL+1)(P2)
	ILD	disp(CNT)(P2)
	JMP	RH0
RHE:
	LD	@-1(P3)
	LEAVE
	RET
	
;;;
;;; Data area
;;;

OPNMSG:
	DB	CR,LF,"Universal Monitor SC/MP",CR,LF,0x00
PROMPT:
	DB	"] ",0x00

IHEMSG:
	DB	"Error ihex",CR,LF,0x00
SHEMSG:
	DB	"Error srec",CR,LF,0x00
ERRMSG:
	DB	"Error",CR,LF,0x00

DSEP0:
	DB	" :",0x00
DSEP1:
	DB	" : ",0x00
IHEXER:
        DB	":00000001FF",CR,LF,0x00
SRECER:
        DB	"S9030000FC",CR,LF,0x00

	IF USE_DEV_EMILY
	INCLUDE	"dev/dev_emily.asm"
	ENDIF
	    
;;;
;;; RAM area
;;;

	;;
	;; Work Area
	;;
	
	ORG	WORK_B

INBUF:	DS	BUFLEN		; Line input buffer
DSADDR:	DS	2		; Dump start address
DEADDR:	DS	2		; Dump end address
DSTATE:	DS	1		; Dump state
GADDR:	DS	2		; Go address
SADDR:	DS	2		; Set address
HEXMOD:	DS	1		; HEX file mode
RECTYP:	DS	1		; Record type

RHVAL:	DS	2		; RDHEX Value
PT0:	DS	2		; Generic Pointer 0
PT1:	DS	2		; Generic Pointer 1

CNT:	DS	1		; Generic Counter

	END
