;;; -*- asm -*-
;;;
;;; Universal Monitor 8051 config file (sample)
;;;

;;;
;;; Memory
;;;

WORK_B:	EQU	60H
STACK:	EQU	3FH

USER_B:	EQU	0800H		; Initial address for D,S,G commands
	
BUFLEN:	EQU	16

;;;
;;; Options
;;;

DEBUG = 0
	
;;;
;;; 8051 internal UART
;;;

USE_DEV_8051 = 1
	IF USE_DEV_8051
PCON_V:	EQU	80H	; Double baudrate mode
TMOD_V:	EQU	20H	; Timer 1 Mode 2
TH1_V:	EQU	250	; 9600bps (11.0592MHz, double baudrate)
TCON_V:	EQU	40H	; Timer 1 enable
SCON_V:	EQU	50H	; Mode 1, Rcv enable	
	;;
	ENDIF

;;;
;;; EMILY Board (Shared Memory)
;;;

USE_DEV_EMILY = 0
	IF USE_DEV_EMILY
SMBASE:	EQU	0FF0H
	ENDIF

