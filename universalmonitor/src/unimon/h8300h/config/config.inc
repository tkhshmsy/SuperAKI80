;;; -*- asm -*-
;;;
;;; Universal Monitor H8/300H config file (sample)
;;;


;;;
;;; CPU
;;;

	CPU	H8/300H

USE_ADVANCED = 1

;;;
;;; Memory
;;;

RAM_B:	EQU	$FEF10
WORK_B:	EQU	$FFE80
STACK:	EQU	$FFF10

BUFLEN:	EQU	24

;;;
;;; Options
;;;


;;;
;;; Internal SCI
;;;

USE_DEV_SCI = 1
	IF USE_DEV_SCI
SCI_B:	EQU	$FFFB0		; SCI base : $*FFB0 for SCI0, $*FFB8 for SCI1
SMR_V:	EQU	$00		;   8bit, N-parity, 1-stopbit, Phi
BRR_V:	EQU	80		;   9600bps @ 25MHz
SCR_V:	EQU	$31		;   Rx/Tx enable, Int-CLK, polling
	ENDIF

;;;
;;; EMILY Board (Shared Memory)
;;;

USE_DEV_EMILY = 0
	IF USE_DEV_EMILY
	;;
SMBASE:	EQU	$0FF0
	ENDIF
