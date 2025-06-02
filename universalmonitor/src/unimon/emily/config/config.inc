;;; -*- asm -*-

;;;
;;; CPU
;;;

	cpu	ATmega164

	save
	listing	off
	include	"regavr.inc"
	include	"avr/regm164.inc"
	restore
	
;;;
;;; Memory
;;;

WORK_B:	equ	((RAMEND+1)-512)
STACK:	equ	RAMEND

BUFLEN:	equ	48


;;;
;;; DEBUG
;;;

DEBUG = 0

;;;
;;; Atmel ATmega164/644/1284 embedded UART (UART0)
;;;

USE_DEV_MEGA164 = 1
