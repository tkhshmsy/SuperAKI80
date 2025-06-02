;;;
;;;	Software UART Console Driver
;;;

	;; TxD: Pin  4 (Q)
	;; RxD:	Pin 22 (/EF3)
	;; CLK = 1.79MHz
	;; 9600bps 8 bit No-parity

INIT:
	SEQ

	LDI	255
	PLO	7
INI0:
	NLBR	$
	DEC	7
	GLO	7
	BNZ	INI0

	SEP	RETN

CONIN:				; Cyc
	BN3	CONIN		;    : Wait falling edge of /EF3

	LDI	3		;  2
	PLO	7		;  2
CI0:
	DEC	7		;  2
	GLO	7		;  2
	BNZ	CI0		;  2
	NLBR	$		;  3

	LDI	8		;  2 : 8 bit
	PLO	7		;  2
CI1:
	GLO	8		;  2
	SHR			;  2
	B3	CI2		;  2
	ORI	80H		;  2
	BR	CI3		;  2
CI2:
	NBR	$		;  2
	BR	CI3		;  2
CI3:
	PLO	8		;  2

	NBR	$		;  2
	NLBR	$		;  3
	
	DEC	7		;  2
	GLO	7		;  2
	BNZ	CI1		;  2

	SEP	RETN

CONST:
	LDI	0FFH
	PLO	8
	SEP	RETN

CONOUT:				; Cyc
	REQ			;    : TxD H=>L (Start bit)

	GLO	8		;  2
	PHI	7		;  2
	LDI	8		;  2 : 8bit
	PLO	7		;  2

	NLBR	$		;  3
	NBR	$		;  2
CO0:
	GHI	7		;  2
	SHR			;  2
	PHI	7		;  2
	BDF	CO1		;  2
	REQ			;  2
	BR	CO2		;  2
CO1:
	SEQ
	BR	CO2
CO2:
	NBR	$		;  2
	NLBR	$		;  3

	DEC	7		;  2
	GLO	7		;  2
	BNZ	CO0		;  2

	NLBR	$		;  3
	NLBR	$		;  3
	SEQ			;  2 : TxD =>H (Stop bit)

	NLBR	$		;  3
	NLBR	$		;  3

	SEP	RETN

