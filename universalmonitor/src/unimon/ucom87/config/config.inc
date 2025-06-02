;;; -*- asm -*-
;;;
;;; Universal Monitor uCOM-87 config file (sample)
;;;


;;;
;;; CPU
;;;

USE_CPU_7800 = 1
USE_CPU_7810 = 0

	;; Memory Mapping Register
MM_V:	EQU	0FH		; Expansion mode (16-bit address), RAM enable

;;;
;;; Memory
;;;

RAM_B:	EQU	0FF00H
WORK_B:	EQU	0F80H	;0FF80H
STACK:	EQU	0F80H	;0000H

BUFLEN:	EQU	16

;;;
;;; Options
;;;

USE_REGCMD = 1			; R(egister) command and related functions

;;;
;;; NEC uPD7810 (Internal)
;;;

USE_DEV_7810 = 0
	IF USE_DEV_7810
	;; Serial Mode High Register
SMH_V:	EQU	0CH		; Internal clock, Tx/Rx enable
	;; Serial Mode Low Register
SML_V:	EQU	4EH		; stop-bit 1, no-parity, 8 bit, x16
	;; Mode Control C Register
MCC_V:	EQU	03H		; PC0:TxD, PC1:RxD, PC2-PC7:Port
USE_TIMER = 1
	IF USE_TIMER
	;; Timer Mode Register
TMM_V:	EQU	00H		; Use TIMER0, phi12
	;; Timer REG0
TM0_V:	EQU	13		; 2400bps @ 12.0MHz
	ENDIF			; USE_TIMER
MEMREQ = 2			; Need 2 bytes work area
	ENDIF

;;;
;;; EMILY Board (Shared Memory)
;;;

USE_DEV_EMILY = 1
	IF USE_DEV_EMILY
	;;
SMBASE:	EQU	0FF0H
	ENDIF
