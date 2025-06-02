;;; -*- asm -*-
;;;
;;; Universal Monitor F8 config file (sample)
;;;

;;;
;;; Memory
;;;

WORK_B:	EQU	20H		; Must be multiple of 16

BUFLEN:	EQU	16		; Input buffer length (don't change)

XRAM_B:	EQU	0FE00H		; Temporary subroutine area

;;;
;;; Intel 8251 (memory mapped)
;;;

USE_DEV_8251 = 0
	IF USE_DEV_8251
USARTD:	equ	0FF00H
USARTC:	equ	0FF01H
	ENDIF

;;;
;;; Intel 8251 (I/O mapped)
;;;

USE_DEV_8251P = 1
	IF USE_DEV_8251P
USARTD:	EQU	80H
USARTC:	EQU	81H
	ENDIF
