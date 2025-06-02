;;; -*- asm -*-
;;;
;;; Universal Monitor SC/MP config file (sample)
;;;

;;;
;;; Memory
;;;

ENTRY:	EQU	0x0080		; Entry point
	
WORK_B:	equ	0x0F80
STACK:	equ	0x0F80

BUFLEN:	equ	16

;;;
;;; Options
;;;

	
;;;
;;; EMILY Board (Shared Memory)
;;; 

USE_DEV_EMILY = 1
	IF USE_DEV_EMILY
SMBASE:	EQU	0x0FF0
	ENDIF
