;;; -*- asm -*-
;;;
;;; Universal Monitor 2650 config file (sample)
;;;


;;;
;;; Memory
;;;

RAM_B:	EQU	H'0800'
WORK_B:	EQU	H'0F80'

BUFLEN:	EQU	16

;;;
;;; Options
;;;

DEBUG = 0
;;;
;;; Signetics 2651
;;;

USE_DEV_2651 = 1
	IF USE_DEV_2651
PCI_B:	EQU	H'00'		; PCI base address
MR1_V:	EQU	H'4E'		; 1 stop bit, no parity, 8 bit, async, x16
MR2_V:	EQU	H'3E'		; 9600bps (@5.0688MHz)
CR_V:	EQU	H'27'		; #RTS='L', RxEN, #DTR='L', TxEN
	ENDIF

;;;
;;; EMILY Board (Shared Memory)
;;;

USE_DEV_EMILY = 0
	IF USE_DEV_EMILY
SMBASE:	EQU	H'0FF0'
	ENDIF
