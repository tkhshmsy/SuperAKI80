;;; -*- asm -*-
;;;
;;; Universal Monitor NS32000 config file (sample)
;;;

;;;
;;; CPU
;;;

	CPU	NS32016
	FPU	NS32081

;;;
;;; Memory
;;;

RAM_B:	EQU	1000H
WORK_B:	EQU	1F00H
STACK:	EQU	1F00H
USTACK:	EQU	1E00H

BUFLEN:	EQU	24		; Input buffer size

;;;
;;; Options
;;;

USE_REGCMD = 1			; R(egister) command and related functions

USE_FPU = 1			; Also set 'F' flag to SETCFG below.

INITCFG	MACRO			; Initialize CFG register
	SETCFG	[F]
	ENDM

;;;
;;; EMILY Board (Shared Memory)
;;;

USE_DEV_EMILY = 1
	IF USE_DEV_EMILY
	;;
SMBASE:	EQU	1FF0H
	ENDIF
