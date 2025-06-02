;;; -*- asm -*-
;;;
;;; Universal Monitor H8/500 config file (sample)
;;;


;;;
;;; CPU
;;;

	CPU	HD6475328

USE_MAXIMUM = 1

;;;
;;; Memory
;;;

ROM_B:	EQU	$00000		; ROM start address (Don't change!!!)
RAM_B:	EQU	$00C00
WORK_B:	EQU	$0FF00		; Internal RAM
STACK:	EQU	$0FF80

BUFLEN:	EQU	24

;;;
;;; Options
;;;

USE_REGCMD = 1			; Register related commands

;;;
;;; Internal SCI
;;;

USE_DEV_SCI = 1
	IF USE_DEV_SCI
SCI_B:	EQU	$0FFD8		; SCI base address
SMR_V:	EQU	$00		;   8bit, N-parity, 1-stopbit, Phi
BRR_V:	EQU	25		;   9600bps @ 16MHz(Xtal)
SCR_V:	EQU	$31		;   Rx/Tx enable, Int-CLK, polling
	ENDIF

;;;
;;; EMILY Board (Shared Memory)
;;;

USE_DEV_EMILY = 0
	IF USE_DEV_EMILY
	;;
SMBASE:	EQU	$0FF0		; SMBASE and WORK_B must in same page.
	ENDIF
