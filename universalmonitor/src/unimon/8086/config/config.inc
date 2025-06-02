;;; -*- asm -*-
;;;
;;; Universal Monitor 8086 config file (sample)
;;;

;;;
;;; Memory
;;;

ROMSEG:	EQU	0F000H		; CSEG
ROM_B:	EQU	0F000H

RAMSEG:	EQU	0000H		; DSEG & SSEG
WORK_B:	EQU	0F00H
STACK:	EQU	1000H

BUFLEN:	EQU	24
VECSIZ:	EQU	256		; Number of vectors to be initialized

;;;
;;; Options
;;;

USE_IDENT = 1			; CPU Identification
USE_REGCMD = 1			; Register related commands
	
;;;
;;; Intel 8251
;;;

USE_DEV_8251 = 0
	IF USE_DEV_8251
USARTD:	EQU	00H
USARTC:	EQU	01H
	ENDIF
	
;;;
;;; EMILY Board (Shared Memory)
;;;

USE_DEV_EMILY = 1
	IF USE_DEV_EMILY
	;;
SMSEG:	EQU	0000H
SMBASE:	EQU	0FE0H
	ENDIF
