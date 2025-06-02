;;; -*- asm -*-
;;;
;;; Universal Monitor IM6100 config file (sample)
;;;

;;;
;;; CPU
;;;

;;;
;;; Memory
;;;

ENTRY:	EQU	00100		; Entry table (must fit in ZERO page)
WORK_B:	EQU	00120		; Work area (must fit in ZERO page)
PROG_B:	EQU	05000		; Program area (must be writable)

BUFLEN:	EQU	16

;;;
;;; Options
;;;

USE_HEXCMD = 1			; L(oad) command
	
;;;
;;; Console Driver
;;;

;;; EMILY Board (Shared Memory)

USE_DEV_EMILY = 1
	IF USE_DEV_EMILY
	;;
SMBASE:	EQU 00160
	ENDIF
