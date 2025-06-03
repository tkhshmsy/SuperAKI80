;;;
;;;	Z80 SIO Console Driver
;;; 

INIT:
	;; Initialize SIO
	IN	A,(SIOAC)
	IN	A,(SIOBC)
	;; Reset both Ch.
	LD	A,18H
	OUT	(SIOAC),A
	OUT	(SIOBC),A

	IF USE_Z80CTC
	LD	A,07H		; Timer mode, 1/16, fall-edge, no ext trigger
	OUT	(CTC0),A
	LD	A,TC_V
	OUT	(CTC0),A
	ENDIF			; USE_CTC

	IF USE_Z80CTC3
	LD	A,CTC_V
	OUT	(CTC3),A
	LD	A,TC_V
	OUT	(CTC3),A
	ENDIF			; USE_CTC3

	;; Ch.A WR1
	LD	A,01H
	OUT	(SIOAC),A
	XOR	A
	OUT	(SIOAC),A

	;; Ch.A WR4
	LD	A,04H
	OUT	(SIOAC),A
	LD	A,44H		; x16 1 N
	OUT	(SIOAC),A

	;; Ch.A WR3
	LD	A,03H
	OUT	(SIOAC),A
	LD	A,0C1H		; 8bit Receiver enable
	OUT	(SIOAC),A
	
	;; Ch.A WR5
	LD	A,05H
	OUT	(SIOAC),A
	LD	A,0EAH		; 8bit Transmitter enable
	OUT	(SIOAC),A

	RET

;;;
;;; SIO Ch.A conin/const/conout w/o interrupt
;;;

CONIN:
	IN	A,(SIOAC)
	AND	01H
	JR	Z,CONIN
	IN	A,(SIOAD)
	RET

CONST:
	IN	A,(SIOAC)
	AND	01H
	RET

CONOUT:
	PUSH	AF
CO0:
	IN	A,(SIOAC)
	AND	04H
	JR	Z,CO0
	POP	AF
	OUT	(SIOAD),A
	RET
