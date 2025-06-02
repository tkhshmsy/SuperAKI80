;;; -*- asm -*-
;;;
;;; Universal Monitor TLCS-90 config file (sample)
;;;

;;;
;;; Memory
;;;

ENTRY:	EQU	0080H		; Entry point
	
WORK_B:	equ	0EF00H
STACK:	equ	0EFEFH

BUFLEN:	equ	16

;;;
;;; Options
;;;

USE_IDENT = 1			; CPU Identification
	
USE_REGCMD = 1			; R(egister) command and related functions

	;; Port 4 Control Register
P4CR_V:	EQU	0FH		; Port 4 : Output A16-A19
	
;;;
;;; Toshiba TLCS-90 internal
;;;
	
USE_DEV_TLCS90 = 1
	IF USE_DEV_TLCS90

	;; Serial Channel Mode Register
SCMOD_V:EQU	3BH		;     8bit, BRG/2

	;; Timer/Serial Channel Operation Control Register
TRUN_V:	EQU	0E0H		;     19200/9600bps

	;; Port 3 Control Register
P3CR_V:	EQU	4AH		;     Normal wait, TxD,RxD

	ENDIF

;;;
;;; EMILY Board (Shared Memory)
;;; 

USE_DEV_EMILY = 0
	IF USE_DEV_EMILY
SMBASE:	EQU	0EFF0H
	ENDIF

