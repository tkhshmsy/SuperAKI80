;;; -*- asm -*-
;;;
;;;     Register definition for TLCS-90
;;;

IRFH:	EQU	0FFC3H		; Interrupt Request Flip-Flop
P3CR:	EQU	0FFC7H		; Port 3 Control Register
P4CR:	EQU	0FFC9H		; Port 4 Control Register
WDMOD:	EQU	0FFD2H		; Watchdog Timer Mode Register
WDCR:	EQU	0FFD3H		; Watchdog Timer Control Register
SCMOD:	EQU	0FFE9H		; Serial Channel Mode Register
SCCR:	EQU	0FFEAH		; Serial Channel Control Register
SCBUF:	EQU	0FFEBH		; Serial Transmission/Receiving Buffer Register
BX:	EQU	0FFECH		; Bank Register BX
BY:	EQU	0FFEDH		; Bank Register BY
TRUN:	EQU	0FFDBH		; Timer/Serial Channel Operation Control Register
