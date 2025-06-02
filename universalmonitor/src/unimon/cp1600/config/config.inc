;;; -*- asm -*-
;;;
;;; Universal Monitor CP-1600 config file (CP-1600A Breadboard Computer)
;;;

;;;
;;; Memory
;;;
	
;ROM_B:	EQU	X'F000'		; ROM begin
ENTRY:	EQU	X'0080'		; Entry point
	
WORK_B:	EQU	X'0F00'		; WORK area begin
STACK:	EQU	X'0FF0'		; Stack grows from here to higher address

BUFLEN:	EQU	16 		; Buffer length ( 16 or above )

;;;
;;; Options
;;;

USE_IDENT = 0 			; CPU Identification

USE_REGCMD = 0 			; Register related commands

USE_DEBUG = 0 			; Eneable debug options

;;;
;;; General Purpose Output
;;;
	IF USE_DEBUG
PORT	EQU	X'E000'
	ENDIF


;;;
;;; Texas Instruments PC16550
;;;

USE_DEV_16550 = 1
 	IF USE_DEV_16550
DIVISOR EQU    12	; 9600 bps
UARTDA  EQU     X'EF00' ; RBR/THR
UARTIE  EQU     X'EF01' ; IER
UARTFC  EQU     X'EF02' ; FCR
UARTLC  EQU     X'EF03' ; LCR
UARTMC  EQU     X'EF04' ; MCR
UARTLS  EQU     X'EF05' ; LSR
UARTDL  EQU     X'EF00' ; DLL
UARTDM  EQU     X'EF01' ; DLM
 	ENDIF
