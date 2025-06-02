;;; -*- asm -*-
;;;
;;; Universal Monitor Z80 config file (for AKI-80)
;;;

;;;
;;; Memory
;;;

ENTRY:	EQU	0080H		; Entry point

RAM_B:	EQU	8000H
WORK_B:	equ	0FF00H
STACK:	equ	0000H

BUFLEN:	equ	16

;;;
;;; Options
;;;

USE_IDENT = 1			; CPU Identification

USE_REGCMD = 1			; R(egister) command and related functions

USE_RAMCHK = 1			; Check RAM

USE_WARMUP = 0			; DRAM warming up
	IF USE_WARMUP
WARMUP_ADDR = 8000H		;   Start address
WARMUP_INCR = 1			;   Address increment
WARMUP_CNT = 128 * 8		;   Count
	ENDIF

USE_NEWAPI = 1			; New API (RST 30H)

;;; HD64180 specific
DCNTL_V: EQU	00H
RMR_V:	EQU	83H
OMCR_V:	EQU	40H
IOBASE:	EQU	0C0H		; Internal I/O BASE (00H,40H,80H,0C0H)

USE_180TRAP = 1			; Handle HD64180 TRAP (experimental)

;;; Z8S180 specific
	;; CPU Control Register
CCR1_V:	EQU	00H
	
;;; Z280 specific
	;; Bus Timing and Control Register: none additional WAIT
BTCR_V:	EQU	30H		; I/O=00, HM=00, DC=00
	;; Bus Timing and Initialization Register
BTIR_V:	EQU	40H		; (CS=00), LM=00, MP=0, (BS=1), (DIC=0)
	;; Cache Control Register
CCR_V:	EQU	00H		; Instruction & data cache enable, no burst mode
	;; Refresh Rate Register
RRR_V:	EQU	38H		; Disable refresh

;;;
;;; Special initialize routine
;;;

USE_SPINIT = 0
	IF USE_SPINIT

SPINIT	MACRO
	ENDM

	ENDIF

;;;
;;; Console Drivers
;;;

;;; Zilog Z80 SIO
	
USE_DEV_Z80SIO = 1
	IF USE_DEV_Z80SIO
SIOAD:	equ	18H		; 
SIOAC:	equ	19H		;
SIOBD:	equ	1AH		; (Ch.B not supported)
SIOBC:	equ	1BH		; (Ch.B not supported)
USE_Z80CTC = 1			; Use Z80 CTC for baudrate generator
	IF USE_Z80CTC
CTC0:	EQU	10H
TC_V:	EQU	4		; 9600bps @ 9.8304MHz
	ENDIF			; USE_Z80CTC
	ENDIF

;;; Intel 8251

USE_DEV_8251 = 0
	IF USE_DEV_8251
USARTD:	equ	00H		; Data Register
USARTC:	equ	01H		; Control / Status Register
	ENDIF
	
;;; NS NSC858

USE_DEV_NSC858 = 0
	IF USE_DEV_NSC858
NSBASE:	EQU	00H
RTMR_V:	EQU	0B0H		; Internal clock, 8 bit, no parity (RMR/TMR)
GMR_V:	EQU	01H		; 1 stop bit, x16
BRGD_V:	EQU	26		; 9600bps @ 4MHz
	ENDIF

;;; Zilog Z280 (Internal)

USE_DEV_Z280 = 0
	IF USE_DEV_Z280
TCR1:	EQU	(19-1)		; bps = CLK(Xtal) / 8 / (TCR1+1) / 16
	ENDIF

;;; Hitachi HD64180 (Internal)

USE_DEV_64180 = 0
	IF USE_DEV_64180
ASBASE:	EQU	IOBASE+0	; IOBASE+1 for ASCI Ch.1
CNTLA_V: EQU	6CH		; 8bit 1 N
CNTLB_V: EQU	02H		; CLK/640
	ENDIF

;;; EMILY Board (Shared Memory)

USE_DEV_EMILY = 0
	IF USE_DEV_EMILY
SMREG:	EQU	0FF0H
	ENDIF
