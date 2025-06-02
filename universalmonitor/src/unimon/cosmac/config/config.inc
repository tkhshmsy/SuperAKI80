;;; -*- asm -*-
;;;
;;; Universal Monitor COSMAC config file (sample)
;;;


;;;
;;; CPU
;;;


;;;
;;; Memory
;;;

RAM_B:	EQU	0800H
WORK_B:	EQU	0F00H		; Work area must fit in single 256 byte page
STACK:	EQU	0FEFH

BUFLEN:	EQU	16

;;;
;;; Options
;;;


;;;
;;; EMILY Board (Shared Memory)
;;;

USE_DEV_EMILY = 0
	IF USE_DEV_EMILY
	;;
SMBASE:	EQU	0FF0H
	ENDIF

;;;
;;; Software UART
;;;

USE_DEV_SOFT = 0
	IF USE_DEV_SOFT
	;;
	ENDIF

;;;
;;; Intel 8251
;;;


USE_DEV_8251 = 1
	IF USE_DEV_8251
USARTD:	EQU	2
USARTC:	EQU	3
	ENDIF
