;;; -*- asm -*-
;;;
;;; Universal Monitor TMS9900 config file (sample)
;;;

;;;
;;;  CPU
;;;
	
	CPU	TMS9995

;;;
;;; Memory
;;;

ENTRY:	EQU	0080H		; Entry point

WORK_B:	EQU	0F000H		;
STACK:	EQU	0FFF0H
	
BUFLEN:	EQU	16		; Buffer length ( 16 or above )

;;;
;;; Options
;;;

;;;
;;; EMILY Board (Shared Memory)
;;;

USE_DEV_EMILY = 1
	IF USE_DEV_EMILY
	;;
SMBASE:	EQU	0FF0H
	ENDIF
