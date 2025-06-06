;;;
;;; Universal Monitor 6800
;;; 

	CPU	6800

TARGET:	equ	"MC6800"


	INCLUDE	"config.inc"

	INCLUDE	"../common.inc"

;;;
;;; ROM area
;;;
	
	ORG	ROM_B

CSTART:
	LDS	#STACK
	JSR	INIT

	LDX	#$0000
	STX	DSADDR
	STX	SADDR
	STX	GADDR
	LDAA	#'S'
	STAA	HEXMOD
	CLR	PSPEC
	IF USE_REGCMD
	CLR	REGA
	CLR	REGB
	STX	REGX
	STS	REGSP
	STX	REGPC
	LDAA	#$C0
	STAA	REGCC
	ENDIF
	
	;; Opening message
	LDX	#OPNMSG
	JSR	STROUT

	;; CPU identification
	IF USE_IDENT
	LDX	#$55AA
	LDAB	#100
	LDAA	#5
	ADDA	#5
	FCB	$18		; DAA on 6800, ABA on 6803, XGDX on 6303
	CMPA	#$55
	BEQ	ID_6301
	CMPA	#110
	BEQ	ID_6801
	CMPA	#$10
	BNE	ID_UK

	LDX	#$FFFF
	FCB	$EC,$01		; CPX $01,X on 6800, ADX $01 on MB8861
	CPX	#$0000
	BEQ	ID_8861
	;; MC6800
	LDX	#IM6800
	CLRA
	BRA	IDE
	;; MC6801/MC6803
ID_6801:
	LDX	#IM6801
	LDAA	#$01
	BRA	IDE
	;; HD6301/HD6303
ID_6301:
	LDX	#IM6301
	LDAA	#$03
	BRA	IDE
	;; MB8861/MB8870
ID_8861:
	LDX	#IM8861
	LDAA	#$04
	BRA	IDE
	;; Unknown
ID_UK:	
	JSR	HEXOUT2
	LDX	#IMUK
	CLRA
IDE:
	STAA	PSPEC
	JSR	STROUT
	ENDIF

WSTART:
	LDX	#PROMPT
	JSR	STROUT
	JSR	GETLIN
	LDX	#INBUF
	JSR	SKIPSP
	JSR	UPPER
	TSTA
	BEQ	WSTART
	CMPA	#'D'
	BNE	M00
	JMP	DUMP
M00:	
	CMPA	#'G'
	BNE	M01
	JMP	GO
M01:	
	CMPA	#'S'
	BNE	M02
	JMP	SETM

M02:	
	CMPA	#'L'
	BNE	M03
	JMP	LOADH
M03:	
	CMPA	#'P'
	BNE	M04
	JMP	SAVEH

M04:
	IF USE_REGCMD
	CMPA	#'R'
	BNE	M05
	JMP	REG
	ENDIF
M05:	
ERR:
	LDX	#ERRMSG
	JSR	STROUT
	BRA	WSTART

;;;
;;; Dump memory
;;;
DUMP:
	INX
	JSR	SKIPSP
	JSR	RDHEX		; 1st arg.
	TSTB
	BNE	DP0
	;; No arg.
	JSR	SKIPSP
	LDAA	,X
	BNE	ERR
	LDAA	DSADDR+1	; DEADDR = DSADDR + 128
	ADDA	#128
	STAA	DEADDR+1
	LDAA	DSADDR
	ADCA	#0
	STAA	DEADDR
	BRA	DPM
	;; 1st arg. found
DP0:
	LDAA	RHVAL+1		; DSADDR = RHVAL
	STAA	DSADDR+1
	LDAA	RHVAL
	STAA	DSADDR
	JSR	SKIPSP
	LDAA	,X
	CMPA	#','
	BEQ	DP1
	TSTA
	BNE	ERR
	;; No 2nd arg.
	LDAA	DSADDR+1	; DEADDR = DSADDR + 128
	ADDA	#128
	STAA	DEADDR+1
	LDAA	DSADDR
	ADCA	#0
	STAA	DEADDR
	BRA	DPM
	;;
DP1:
	INX
	JSR	SKIPSP
	JSR	RDHEX
	JSR	SKIPSP
	TSTB
	BEQ	ERR
	TST	,X
	BNE	ERR
	LDX	RHVAL
	INX
	STX	DEADDR
	;; DUMP main
DPM:
	LDAA	DSADDR+1
	ANDA	#$F0
	STAA	DMPPT+1
	LDAA	DSADDR
	STAA	DMPPT
	CLR	DSTATE
DPM0:
	BSR	DPL
	;; DMPPT already incremented during DPB
	;; Do not need to +16 here
	JSR	CONST
	BNE	DPM1
	LDAA	DSTATE
	CMPA	#2
	BCS	DPM0
	LDAA	DEADDR+1
	STAA	DSADDR+1
	LDAA	DEADDR
	STAA	DSADDR
	JMP	WSTART
DPM1:
	LDAA	DMPPT+1
	STAA	DSADDR+1
	LDAA	DMPPT
	STAA	DSADDR
	JSR	CONIN
	JMP	WSTART

	;; Dump line
DPL:
	LDAA	DMPPT
	LDAB	DMPPT+1
	JSR	HEXOUT4
	LDX	#DSEP0
	JSR	STROUT
	LDX	#INBUF
	STX	ASCPT
	LDAB	#16
DPL0:
	BSR	DPB
	DECB
	BNE	DPL0

	LDX	#DSEP1
	JSR	STROUT

	;; Print ASCII area
	LDX	#INBUF
	LDAB	#16
DPL1:
	LDAA	,X
	INX
	CMPA	#' '
	BCS	DPL2
	CMPA	#$7F
	BCC	DPL2
	JSR	CONOUT
	BRA	DPL3
DPL2:
	LDAA	#'.'
	JSR	CONOUT
DPL3:
	DECB
	BNE	DPL1
	JMP	CRLF

	;; Dump byte
DPB:
	LDAA	#' '
	JSR	CONOUT
	LDAA	DSTATE
	BNE	DPB2
	;; Dump state 0
	LDAA	DSADDR
	CMPA	DMPPT
	BNE	DPB0
	LDAA	DSADDR+1
	CMPA	DMPPT+1
	BEQ	DPB1
	;; Still 0 or 2
DPB0:
	LDAA	#' '
	JSR	CONOUT
	JSR	CONOUT
	LDX	ASCPT
	STAA	,X
	INX
	STX	ASCPT
	LDX	DMPPT
	INX
	STX	DMPPT
	RTS
	;; Found start address
DPB1:
	LDAA	#1
	STAA	DSTATE
DPB2:
	LDAA	DSTATE
	CMPA	#1
	BNE	DPB0
	;; Dump state 1
	LDX	DMPPT
	LDAA	,X
	INX
	STX	DMPPT
	LDX	ASCPT
	STAA	,X
	INX
	STX	ASCPT
	JSR	HEXOUT2
	LDAA	DEADDR
	CMPA	DMPPT
	BNE	DPBE
	LDAA	DEADDR+1
	CMPA	DMPPT+1
	BNE	DPBE
	LDAA	#2
	STAA	DSTATE
DPBE:
	RTS

;;;
;;; Go address
;;;
GO:
	INX
	JSR	SKIPSP
	JSR	RDHEX
	LDAA	,X
	BEQ	GO0
	JMP	ERR
GO0:	
	TSTB
	BEQ	G0
	LDX	RHVAL
	IF USE_REGCMD
	STX	REGPC
G0:
	LDAA	REGSP
	ORAA	REGSP+1
	BEQ	GO1
	LDS	REGSP
GO1:
	LDAA	REGPC+1
	PSHA			; PC(L)
	LDAA	REGPC
	PSHA			; PC(H)
	LDAA	REGX+1
	PSHA			; X(L)
	LDAA	REGX
	PSHA			; X(H)
	LDAA	REGA
	PSHA			; A
	LDAA	REGB
	PSHA			; B
	LDAA	REGCC
	PSHA			; CC
	RTI
	ELSE
	STX	GADDR
G0:
	LDX	GADDR
	JMP	,X
	ENDIF

;;;
;;; Set memory
;;;
SETM:
	INX
	JSR	SKIPSP
	JSR	RDHEX
	JSR	SKIPSP
	TST	,X
	BNE	SMER
	TSTB
	BEQ	SM1
	LDX	RHVAL
	STX	SADDR
SM1:
	LDAA	SADDR
	LDAB	SADDR+1
	JSR	HEXOUT4
	LDX	#DSEP1
	JSR	STROUT
	LDX	SADDR
	LDAA	,X
	JSR	HEXOUT2
	LDAA	#' '
	JSR	CONOUT
	JSR	GETLIN
	LDX	#INBUF
	JSR	SKIPSP
	LDAA	,X
	BNE	SM2
	;; Empty (Increment address)
	LDX	SADDR
	INX
	STX	SADDR
	BRA	SM1
SM2:
	CMPA	#'-'
	BNE	SM3
	;; '-' (Decrement address)
	LDX	SADDR
	DEX
	STX	SADDR
	BRA	SM1
SM3:
	CMPA	#'.'
	BNE	SM4
	;; '.' (Quit)
	JMP	WSTART
SM4:	
	JSR	RDHEX
	TSTB
	BEQ	SMER
	LDX	SADDR
	LDAA	RHVAL+1
	STAA	,X
	INX
	STX	SADDR
	BRA	SM1
SMER:
	JMP	ERR

;;;
;;; LOAD HEX file
;;;
LOADH:
	INX
	JSR	SKIPSP
	JSR	RDHEX
	JSR	SKIPSP
	TST	,X
	BNE	SMER
	
	;;TSTB
	;;BNE	LH0

	;;CLR	RHVAL
	;;CLR	RHVAL+1
LH0:	
	JSR	CONIN
	JSR	UPPER
	CMPA	#'S'
	BEQ	LHS0
LH1:
	CMPA	#':'
	BEQ	LHI0
LH2:
	;; Skip to EOL
	CMPA	#CR
	BEQ	LH0
	CMPA	#LF
	BEQ	LH0
LH3:
	JSR	CONIN
	BRA	LH2

LHI0:
	JSR	HEXIN
	STAA	CKSUM
	TAB			; Length

	JSR	HEXIN
	STAA	DMPPT		; Address H
	ADDA	CKSUM
	STAA	CKSUM

	JSR	HEXIN
	STAA	DMPPT+1		; Address L
	ADDA	CKSUM
	STAA	CKSUM

	;; Add offset
	LDAA	DMPPT+1
	ADDA	RHVAL+1
	STAA	DMPPT+1
	LDAA	DMPPT
	ADCA	RHVAL
	STAA	DMPPT
	LDX	DMPPT

	JSR	HEXIN
	STAA	RECTYP
	ADDA	CKSUM
	STAA	CKSUM

	TSTB
	BEQ	LHI3
LHI1:
	JSR	HEXIN
	PSHA
	ADDA	CKSUM
	STAA	CKSUM
	PULA

	TST	RECTYP
	BNE	LHI2

	STAA	,X
	INX
LHI2:
	DECB
	BNE	LHI1
LHI3:
	JSR	HEXIN
	ADDA	CKSUM
	BNE	LHIE		; Checksum error
	TST	RECTYP
	BEQ	LH3
	JMP	WSTART
LHIE:
	LDX	#IHEMSG
	JSR	STROUT
	JMP	WSTART
	
LHS0:
	JSR	CONIN
	STAA	RECTYP		; Record type

	JSR	HEXIN
	TAB			; B = Length+3
	STAA	CKSUM

	JSR	HEXIN
	STAA	DMPPT		; Address H
	ADDA	CKSUM
	STAA	CKSUM

	JSR	HEXIN
	STAA	DMPPT+1		; Address L
	ADDA	CKSUM
	STAA	CKSUM

	;; Add offset
	LDAA	DMPPT+1
	ADDA	RHVAL+1
	STAA	DMPPT+1
	LDAA	DMPPT
	ADCA	RHVAL
	STAA	DMPPT
	LDX	DMPPT

	SUBB	#3
	BEQ	LHS3
LHS1:	
	JSR	HEXIN
	PSHA
	ADDA	CKSUM
	STAA	CKSUM		; Checksum

	LDAA	RECTYP
	CMPA	#'1'
	BNE	LHS2

	PULA
	STAA	,X
	INX
	BRA	LHS20
LHS2:
	PULA
LHS20:
	DECB
	BNE	LHS1
LHS3:
	JSR	HEXIN
	ADDA	CKSUM
	CMPA	#$FF
	BNE	LHSE		; Checksum error

	LDAA	RECTYP
	CMPA	#'7'
	BEQ	LHSR
	CMPA	#'8'
	BEQ	LHSR
	CMPA	#'9'
	BEQ	LHSR
	JMP	LH3
LHSE:
	LDX	#SHEMSG
	JSR	STROUT
LHSR:
	JMP	WSTART

;;;
;;; SAVE HEX file
;;;
SAVEH:
	INX
	LDAA	,X
	JSR	UPPER
	CMPA	#'I'
	BEQ	SH0
	CMPA	#'S'
	BNE	SH1
SH0:
	INX
	STAA	HEXMOD
SH1:
	JSR	SKIPSP
	JSR	RDHEX
	TSTB
	BEQ	SHE
	LDAA	RHVAL
	STAA	ASCPT
	LDAA	RHVAL+1
	STAA	ASCPT+1		; (ASCPT) = Start address
	JSR	SKIPSP
	LDAA	,X
	CMPA	#','
	BNE	SHE
	INX
	JSR	SKIPSP
	JSR	RDHEX		; (RHVAL) = End address
	TSTB
	BEQ	SHE
	JSR	SKIPSP
	TST	,X
	BEQ	SH2
SHE:
	JMP	ERR

SH2:
	LDX	RHVAL
	INX
	STX	RHVAL
	LDAA	RHVAL+1
	SUBA	ASCPT+1
	STAA	RHVAL+1
	LDAA	RHVAL
	SBCA	ASCPT
	STAA	RHVAL		; (RHVAL) = Length
	LDX	ASCPT		; IX = Start address
SH3:
	BSR	SHL
	LDAA	RHVAL
	ORAA	RHVAL+1
	BNE	SH3

	LDAA	HEXMOD
	CMPA	#'I'
	BNE	SH4
	;; End record for Intel HEX
	LDX	#IHEXER
	JSR	STROUT
	JMP	WSTART
SH4:
	;; End record for Motorola S record
	LDX	#SRECER
	JSR	STROUT
	JMP	WSTART

SHL:
	LDAB	#16
	TST	RHVAL
	BNE	SHL0
	LDAA	RHVAL+1		; Length L
	CBA			; (A - B)
	BCC	SHL0
	TAB			; B = A
SHL0:
	LDAA	RHVAL+1
	SBA
	STAA	RHVAL+1
	LDAA	RHVAL
	SBCA	#0
	STAA	RHVAL

	LDAA	HEXMOD
	CMPA	#'I'
	BNE	SHLS

SHLI:	
	;; Intel HEX
	LDAA	#':'
	JSR	CONOUT

	TBA
	JSR	HEXOUT2		; Length
	STAB	CKSUM		; Checksum

	STX	ASCPT
	LDAA	ASCPT		; Address H
	JSR	HEXOUT2
	LDAA	ASCPT
	ADDA	CKSUM
	STAA	CKSUM

	LDAA	ASCPT+1		; Address L
	JSR	HEXOUT2
	LDAA	ASCPT+1
	ADDA	CKSUM
	STAA	CKSUM

	CLRA
	JSR	HEXOUT2		; Record type
SHLI0:
	LDAA	,X
	PSHA
	JSR	HEXOUT2		; Data
	PULA
	ADDA	CKSUM
	STAA	CKSUM

	INX
	DECB
	BNE	SHLI0

	LDAA	CKSUM
	NEGA
	JSR	HEXOUT2
	JMP	CRLF

SHLS:
	;; Motorola S record
	LDAA	#'S'
	JSR	CONOUT
	LDAA	#'1'
	JSR	CONOUT

	TBA
	ADDA	#2+1		; DataLength + Addr(2) + Sum(1)
	STAA	CKSUM
	JSR	HEXOUT2
	
	STX	ASCPT
	LDAA	ASCPT
	JSR	HEXOUT2		; Address H
	LDAA	ASCPT
	ADDA	CKSUM
	STAA	CKSUM
	
	LDAA	ASCPT+1
	JSR	HEXOUT2		; Address L
	LDAA	ASCPT+1
	ADDA	CKSUM
	STAA	CKSUM
SHLS0:
	LDAA	,X
	PSHA
	JSR	HEXOUT2		; Data
	PULA
	ADDA	CKSUM
	STAA	CKSUM

	INX
	DECB
	BNE	SHLS0

	LDAA	CKSUM
	COMA
	JSR	HEXOUT2		; Checksum
	JMP	CRLF

;;;
;;; Register
;;;
	IF USE_REGCMD
REG:
	INX
	JSR	SKIPSP
	JSR	UPPER
	TSTA
	BNE	RG0
	JSR	RDUMP
	JMP	WSTART
RG0:
	STX	DMPPT
	LDX	#RNTAB
RG1:
	TST	,X
	BEQ	RGE
	CMPA	,X
	BEQ	RG2
	INX
	INX
	INX
	INX
	INX
	INX
	BRA	RG1
RG2:
	STX	ASCPT
	LDX	DMPPT
	INX
	JSR	SKIPSP
	TST	,X
	BNE	RGE
	LDX	ASCPT
	LDX	4,X
	JSR	STROUT
	LDAA	#'='
	JSR	CONOUT
	LDX	ASCPT
	LDAB	1,X
	LDX	2,X
	CMPB	#1
	BNE	RG3
	;; 8 bit register
	LDAA	,X
	JSR	HEXOUT2
	BRA	RG4
RG3:
	;; 16 bit register
	LDAA	,X
	JSR	HEXOUT2
	LDAA	1,X
	JSR	HEXOUT2
RG4:
	LDAA	#' '
	JSR	CONOUT
	JSR	GETLIN
	LDX	#INBUF
	JSR	SKIPSP
	LDAA	,X
	BEQ	RGR
	JSR	RDHEX
	TSTB
	BEQ	RGE
	LDX	ASCPT
	LDAB	1,X
	LDX	2,X
	CMPB	#1
	BNE	RG5
	;; 8 bit register
	LDAA	RHVAL+1
	STAA	,X
	BRA	RG6
RG5:
	;; 16 bit register
	LDAA	RHVAL
	STAA	,X
	LDAA	RHVAL+1
	STAA	1,X
RG6:	
RGR:	
	JMP	WSTART
RGE:
	JMP	ERR
	
RDUMP:
	LDX	#RDSA
	JSR	STROUT
	LDAA	REGA
	JSR	HEXOUT2

	LDX	#RDSB
	JSR	STROUT
	LDAA	REGB
	JSR	HEXOUT2

	LDX	#RDSX
	JSR	STROUT
	LDAA	REGX
	LDAB	REGX+1
	JSR	HEXOUT4
	
	LDX	#RDSSP
	JSR	STROUT
	LDAA	REGSP
	LDAB	REGSP+1
	JSR	HEXOUT4
	
	LDX	#RDSPC
	JSR	STROUT
	LDAA	REGPC
	LDAB	REGPC+1
	JSR	HEXOUT4
	
	LDX	#RDSCC
	JSR	STROUT
	LDAA	REGCC
	JSR	HEXOUT2

	JMP	CRLF
	ENDIF
	
;;;
;;; Other support routines
;;;
	
STROUT:
	LDAA	0,X
	BEQ	STROE
	JSR	CONOUT
	INX
	BRA	STROUT
STROE:
	RTS

HEXOUT4:
	BSR	HEXOUT2
	TBA
HEXOUT2:
	PSHA
	LSRA
	LSRA
	LSRA
	LSRA
	BSR	HEXOUT1
	PULA
HEXOUT1:
	ANDA	#$0F
	ADDA	#'0'
	CMPA	#'9'+1
	BCS	HEXOUTE
	ADDA	#'A'-'9'-1
HEXOUTE:	
	JMP	CONOUT

HEXIN:
	CLRA
	BSR	HI0
	ASLA
	ASLA
	ASLA
	ASLA
HI0:
	PSHB
	TAB
	JSR	CONIN
	JSR	UPPER
	CMPA	#'0'
	BCS	HIR
	CMPA	#'9'+1
	BCS	HI1
	CMPA	#'A'
	BCS	HIR
	CMPA	#'F'+1
	BCC	HIR
	SUBA	#'A'-'9'-1
HI1:
	SUBA	#'0'
	ABA
HIR:
	PULB
	RTS
	
CRLF:
	LDAA	#CR
	JSR	CONOUT
	LDAA	#LF
	JMP	CONOUT

GETLIN:
	LDX	#INBUF
	CLRB
GL0:
	JSR	CONIN
	CMPA	#CR
	BEQ	GLE
	CMPA	#LF
	BEQ	GLE
	CMPA	#BS
	BEQ	GLB
	CMPA	#DEL
	BEQ	GLB
	CMPA	#' '
	BCS	GL0
	CMPA	#$80
	BCC	GL0
	CMPB	#BUFLEN-1
	BCC	GL0		; Too long
	INCB
	STAA	0,X
	INX
	JSR	CONOUT
	BRA	GL0
GLB:	
	TSTB
	BEQ	GL0
	DECB
	DEX
	LDAA	#BS
	JSR	CONOUT
	LDAA	#' '
	JSR	CONOUT
	LDAA	#BS
	JSR	CONOUT
	BRA	GL0
GLE:
	BSR	CRLF
	CLR	0,X
	RTS

SKIPSP:
	LDAA	0,X
	CMPA	#' '
	BNE	SSE
	INX
	BRA	SKIPSP
SSE:
	RTS

UPPER:
	CMPA	#'a'
	BCS	UPE
	CMPA	#'z'+1
	BCC	UPE
	ADDA	#'A'-'a'
UPE:
	RTS

RDHEX:
	CLRB
	CLR	RHVAL
	CLR	RHVAL+1
RH0:
	LDAA	,X
	BSR	UPPER
	CMPA	#'0'
	BCS	RHE
	CMPA	#'9'+1
	BCS	RH1
	CMPA	#'A'
	BCS	RHE
	CMPA	#'F'+1
	BCC	RHE
	SUBA	#'A'-'9'-1
RH1:
	SUBA	#'0'
	ROLA
	ROLA
	ROLA
	ROLA
	ROLA
	ROL	RHVAL+1
	ROL	RHVAL
	ROLA
	ROL	RHVAL+1
	ROL	RHVAL
	ROLA
	ROL	RHVAL+1
	ROL	RHVAL
	ROLA
	ROL	RHVAL+1
	ROL	RHVAL
	INX
	INCB
	BRA	RH0
RHE:
	RTS

;;;
;;; Interrupt handler
;;;
SWIH:
	IF USE_REGCMD
	LDX	#SWIMSG
	JSR	STROUT

	PULA			; CCR
	STAA	REGCC
	PULA			; B
	STAA	REGB
	PULA			; A
	STAA	REGA
	PULA			; X(H)
	STAA	REGX
	PULA			; X(L)
	STAA	REGX+1
	PULA			; PC(H)
	PULB			; PC(L)
	SUBB	#1
	STAB	REGPC+1
	SBCA	#0
	STAA	REGPC
	STS	REGSP
	JSR	RDUMP
	JMP	WSTART
	ELSE
	;; Dummy
	RTI
	ENDIF

DUMMYH:
	RTI
	
;;;
;;; Strings
;;;
	
OPNMSG:
	DC	CR,LF,"Universal Monitor 6800",CR,LF,$00

PROMPT:
	DC	"] ",$00

IHEMSG:
	DC	"Error ihex",CR,LF,$00

SHEMSG:
	DC	"Error srec",CR,LF,$00

ERRMSG:
	DC	"Error",CR,LF,$00

DSEP0:
	DC	" :",$00
DSEP1:
	DC	" : ",$00
IHEXER:
        DC	":00000001FF",CR,LF,$00
SRECER:
        DC	"S9030000FC",CR,LF,$00

	IF USE_IDENT
IMUK:	FCB	"Unknown",CR,LF,$00
IM6800:	FCB	"MC6800",CR,LF,$00
IM6801:	FCB	"MC6801",CR,LF,$00
IM6301:	FCB	"HD6301",CR,LF,$00
IM8861:	FCB	"MB8861",CR,LF,$00
	ENDIF
	
	IF USE_REGCMD

SWIMSG:	DC	"SWI",CR,LF,$00

RDSA:	DC	"A=",$00
RDSB:	DC	" B=",$00
RDSX:	DC	" X=",$00
RDSSP:	DC	" SP=",$00
RDSPC:	DC	" PC=",$00
RDSCC:	DC	" CCR=",$00

RNTAB:
	DC	'A',1
	DC.W	REGA,RNA
	DC	'B',1
	DC.W	REGB,RNB
	DC	'X',2
	DC.W	REGX,RNX
	DC	'S',2
	DC.W	REGSP,RNSP
	DC	'P',2
	DC.W	REGSP,RNPC
	DC	'C',1
	DC.W	REGCC,RNCC

	DC	$00,0		; End mark
	DC.W	0

RNA:	DC	"A",$00
RNB:	DC	"B",$00
RNX:	DC	"X",$00
RNSP:	DC	"SP",$00
RNPC:	DC	"PC",$00
RNCC:	DC	"CCR",$00

	ENDIF

	IF USE_DEV_6850
	INCLUDE	"dev/dev_6850.asm"
	ENDIF
	
	IF USE_DEV_6801
	INCLUDE	"dev/dev_6801.asm"
	ENDIF

	;;
	;; Entry point
	;;

	ORG	ENTRY+0		; Cold start
E_CSTART:
	JMP	CSTART

	ORG	ENTRY+8		; Warm start
E_WSTART:
	JMP	WSTART

	ORG	ENTRY+16	; Console output
E_CONOUT:
	JMP	CONOUT

	ORG	ENTRY+24	; (Console) String output
E_STROUT:
	JMP	STROUT

	ORG	ENTRY+32	; Console input
E_CONIN:
	JMP	CONIN

	ORG	ENTRY+40	; Console status
E_CONST:
	JMP	CONST
	
	;;
	;; Vector Area
	;;
	
	ORG	$fff8

	DC.W	DUMMYH		; IRQ

	DC.W	SWIH		; SWI

	DC.W	DUMMYH		; NMI

	DC.W	CSTART		; RESET

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
PSPEC:	DS	1		; Processor spec.
	
	IF USE_REGCMD
REGA:	DS	1		; Accumulator A
REGB:	DS	1		; Accumulator B
REGX:	DS	2		; Index register X
REGSP:	DS	2		; Stack pointer SP
REGPC:	DS	2		; Program counter PC
REGCC:	DS	1		; Condition code register CCR
	ENDIF
	
RHVAL:	DS	2		; RDHEX Value
DMPPT:	DS	2		; DUMP pointer
ASCPT:	DS	2		; ASCII pointer
CKSUM:	DS	1		; Checksum

	END
	
