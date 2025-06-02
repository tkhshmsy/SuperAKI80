;;; -*- asm -*-
;;;
;;; Universal Monitor SuperH config file (sample)
;;;

;;;
;;; CPU
;;;

	CPU	SH7000

;;;
;;; Memory
;;;

WORK_B:	EQU	$FFFFFF00
STACK:	EQU	$00000000	; Initial SP

BUFLEN:	EQU	24		; Input buffer size

;;;
;;; Options
;;;

	;; Bus State Controller
BCR1_V:	EQU	$2025		;  CS0:16bit, CS1:32bit, CS2:16bit, CS3:8bit
BCR2_V:	EQU	$55FF

	;; Pin Function Controller
PAIORL_V: EQU	$0004		; SCK0: output
PACRH_V: EQU	$5000		; Enable: WRHH,WRHL
PACRL1_V: EQU	$4050		; CS0,CS1:enable
PACRL2_V: EQU	$A015		; $A015 for SC0, $A540 for SCI1  CS2,CS3:enable
PDCRH1_V: EQU	$5555		; Enable: D31-D24
PDCRH2_V: EQU	$5555		; Enable: D23-D16

;;;
;;; Internal SCI
;;;

USE_DEV_SCI = 1
	IF USE_DEV_SCI
SCI_B:	EQU	$FFFF81A0	; SCI base  $FFFF81A0 for SCI0, $FFFF81B0 for SCI1
SMR_V:	EQU	$01		;   8bit, N-parity, 1-stopbit, Phi/4
BRR_V:	EQU	23		;   9600bps @ 28.64MHz
SCR_V:	EQU	$31		;   Rx/Tx enable, Int-CLK, polling
	ENDIF

;;;
;;; EMILY Board (Shared Memory)
;;;

USE_DEV_EMILY = 0
	IF USE_DEV_EMILY
PACRL1_V: EQU	$4050		; CS0,CS1:enable
PACRL2_V: EQU	$A000		; CS2,CS3:enable
SMBASE:	EQU	$00801FF0	; CS2 area
	ENDIF
