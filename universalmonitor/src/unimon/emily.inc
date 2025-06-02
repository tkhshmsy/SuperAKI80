;;; -*- asm -*-
;;;
;;; EMILY Board : Definitions
;;;

	RELAXED	ON

;;;
;;; Offset
;;;

EO_SIG:	EQU	0		; Signature
EO_HSK:	EQU	1		; Handshake
EO_CMD:	EQU	2		; Command
EO_STS:	EQU	3		; Status
EO_DAT:	EQU	4		; Data[0]-[11]

;;;
;;; Signature
;;;

EG_SIG:	EQU	0xA5

;;;
;;; Handshake
;;;

EH_REQ:	EQU	0xCC
EH_ACK:	EQU	0x33

;;;
;;; Command
;;;

EC_INI:	EQU	0x00		; Init
EC_COT:	EQU	0x01		; Console Output
EC_CIN:	EQU	0x02		; Console Input
EC_CST:	EQU	0x03		; Console Status

;;;
;;; Status
;;;

ES_OK:	EQU	0x00		; OK
ES_UK:	EQU	0xFF		; Unknown Command

	RELAXED	OFF
