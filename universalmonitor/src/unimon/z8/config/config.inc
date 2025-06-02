;;; -*- asm -*-
;;;
;;; Universal Monitor Z8 config file (sample)
;;;

;;;
;;; CPU
;;;

	CPU	Z8601

;;;
;;; Memory
;;;

ENTRY:	EQU	0080H		; Entry point

	
EXT_BUS = 1			; 0:no_EXT_BUS, 1:12bit_address, 2:16bit_address
EXT_STACK = 0			; 0:Stack_on_REG, 1:Stack_on_EXTRAM

P01M_V:	EQU	00H		; Port 0 and 1 Mode Register (bits needed for EXT_BUS & EXT_STACK are overridden)

	
	IF EXT_STACK

	;; Stack area on RAM
STACK:	EQU	7FF0H

	ELSE

	;; Stack area on REG file
STACK:	EQU	50H

	ENDIF

WORK_B:	EQU	50H
REGPTR:	EQU	70H

BUFLEN:	EQU	16


;;;
;;; Zilog Z8601 embedded UART
;;;

USE_DEV_Z8 = 1
	IF USE_DEV_Z8
	;; bps = CLK / SDIV0 / SDIV1 / 16 / 8
SDIV0:	EQU	1		; T0	1-256 (0 means 256)
SDIV1:	EQU	13		; PRE0	1-64 (0 means 64)
	ENDIF
