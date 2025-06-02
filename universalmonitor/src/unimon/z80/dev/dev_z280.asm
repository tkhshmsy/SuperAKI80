;;;
;;; 
;;;

INIT:
	LD	L,0FEH
	LD	C,08H		; I/O Bank register
	DB	0EDH,06EH	; LDCTL (C),HL

	;; Initialize C/T1 for prescaler
	
	LD	A,88H
	OUT	(0E8H),A	; C/T1 Configuration/Status Register

	LD	HL,TCR1
	LD	C,0EAH		; C/T1 Time-Constant Register
	DB	0EDH,0BFH	; OUTW (C),HL

	LD	A,0E0H
	OUT	(0E9H),A

	;; Initialize UART

	LD	A,0CAH		; 8bit No-parity x16
	OUT	(10H),A		; UART Configuration Register

	LD	A,80H		; Enable transmitter
	OUT	(12H),A		; Transmitter Control/Status Register

	LD	A,80H		; Enable Receiver
	OUT	(14H),A		; Receiver Control/Status Register

	;;
	LD	L,00H
	LD	C,08H		; I/O Bank register
	DB	0EDH,06EH	; LDCTL (C),HL

	RET
	
CONIN:
	PUSH	BC
	PUSH	HL
	LD	C,08H		; I/O Bank register
	DB	0EDH,66H	; LDCTL HL,(C)
	LD	B,L
	LD	L,0FEH
	DB	0EDH,06EH	; LDCTL (C),HL

CIN0:
	IN	A,(14H)
	AND	10H
	JR	Z,CIN0
	IN	A,(16H)
	
	LD	L,B
	LD	C,08H		; I/O Bank register
	DB	0EDH,06EH	; LDCTL (C),HL
	POP	HL
	POP	BC
	RET
	
CONST:
	PUSH	BC
	PUSH	HL
	LD	C,08H		; I/O Bank register
	DB	0EDH,66H	; LDCTL HL,(C)
	LD	B,L
	LD	L,0FEH
	DB	0EDH,06EH	; LDCTL (C),HL

	IN	A,(14H)
	AND	10H
	
	LD	L,B
	LD	C,08H		; I/O Bank register
	DB	0EDH,06EH	; LDCTL (C),HL
	POP	HL
	POP	BC
	RET

CONOUT:
	PUSH	BC
	PUSH	HL
	LD	C,08H		; I/O Bank register
	DB	0EDH,66H	; LDCTL HL,(C)
	LD	B,L
	LD	L,0FEH
	DB	0EDH,06EH	; LDCTL (C),HL

	PUSH	AF
COUT0:
	IN	A,(12H)
	AND	01H
	JR	Z,COUT0
	POP	AF
	OUT	(18H),A
	
	LD	L,B
	LD	C,08H		; I/O Bank register
	DB	0EDH,06EH	; LDCTL (C),HL
	POP	HL
	POP	BC
	RET
