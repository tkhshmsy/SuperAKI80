;;; -*- asm -*-
;;;
;;; Universal Monitor MN1610 config file (sample)
;;;

;;;
;;; CPU
;;;

CPU_MN1613 = 1			; MN1613 / MN1613A
	IF CPU_MN1613
RSBASE:	EQU	X'0110'		; Reset Base address
	ENDIF

;;;
;;; Memory
;;;

ENTRY:	EQU	X'0010'		; Entry table (must fit in ZERO page)
WORK_B:	equ	X'0020'		; Work area (must fit in ZERO page)
STACK:	equ	X'0FFF'

BUFLEN:	equ	16

BRKADR:	EQU	X'000F'		; 'BAL (BRKADR)' can be used as BREAK

;;;
;;; Options
;;;

USE_HEXCMD = 1			; L(oad) and P(unch) commands
USE_REGCMD = 1			; R(egister) command and related functions

;;;
;;; EMILY Board (Shared Memory)
;;;

USE_DEV_EMILY = 1
	IF USE_DEV_EMILY
SMBASE:	EQU	X'0040'		; Must fit in ZERO page ('A 0081,2' on EMILY side)
	ENDIF
