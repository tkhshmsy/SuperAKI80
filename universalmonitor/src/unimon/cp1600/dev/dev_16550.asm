;;;
;;;	PC16550 (UART with FIFO) Console Driver
;;; 

INIT:
	MVII    X'83', R0		; Turn Divisor latch access bit (DLAB) on
	MVO     R0, UARTLC
	MVII    DIVISOR, R0		; Set baud rate to 9600
	MVO     R0, UARTDL		; Xtal freq. (1.8432 MHz) / (16 * DIVISOR) = 9600
	CLRR    R0
	MVO     R0, UARTDM
	MVII    3, R0			; Turn DLAB off again. 8-bit, none-party and 1 stop bit
	MVO     R0, UARTLC
	CLRR    R0				; Disable interrupts (16550)
	MVO     R0, UARTIE
;	MVII    1, R0			; Enable and clear RCVR/XMIT FIFO. FIFO Polled mode
	MVO     R0, UARTFC		; Enter 16450 mode
	MOVR    R5, R7
	
CONIN:
	MVI UARTLS, R0
    ANDI    1, R0	; Bit 0 is set to a logic 1 whenever a complete incoming character has been reveived.
	BEQ     CONIN
	MVI     UARTDA, R0
	ANDI	X'00FF', R0

	MOVR    R5, R7

CONST:
	MVI UARTLS, R0
	ANDI    1, R0

	MOVR    R5, R7	
	
CONOUT:
	PSHR    R0
-	MVI     UARTLS, R0
	ANDI    b'00100000', R0	; The UART is ready to accept a new character for transmission when Bit 5 is set to logic 1.
	BEQ     -
	PULR    R0
	MVO     R0, UARTDA

	MOVR    R5, R7
