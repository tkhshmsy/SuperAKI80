;;; -*- asm -*-
;;;
;;; Universal Monitor INS8070 config file (sample)
;;;

;;;
;;; Memory
;;;

ROM_B:	EQU	0x0000
RAM_B:	EQU	0x3800
WORK_B:	equ	0x3FC0
STACK:	equ	0x3F00

BUFLEN:	equ	16

;;;
;;; Options
;;;

USE_REGCMD = 1			; R(egister) command and related functions

FOR_INS8073 = 0			; Called from BASIC (do not initialize SP)

CONSOLE_FOR_BASIC = 0		; Make BASIC use dev/dev_xxxx as console
	
;;;
;;; EMILY Board (Shared Memory)
;;; 

USE_DEV_EMILY = 1
	IF USE_DEV_EMILY
SMBASE:	EQU	0x0FF0
	ENDIF

;;;
;;; INS8073  (Call routine in NSC Tiny BASIC ROM)
;;;

USE_DEV_INS8073 = 0
	IF USE_DEV_INS8073
MEMREQ = 1
	ENDIF
