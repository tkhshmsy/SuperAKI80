;;; -*- asm -*-
;;;
;;; Universal Monitor AVR config file (sample)
;;;

;;;
;;; CPU
;;;

	cpu	ATmega1284

	save
	listing	off
	include	"regavr.inc"
	include	"avr/regm1284.inc"
	restore
	
;;;
;;; Memory
;;;

WORK_B:	equ	(RAMEND-128)
STACK:	equ	RAMEND

BUFLEN:	equ	48		; Input buffer size (also used for loading HEX file)

;;;
;;; Atmel ATmega164/644/1284 embedded UART (UART0)
;;;

USE_DEV_MEGA164 = 1
