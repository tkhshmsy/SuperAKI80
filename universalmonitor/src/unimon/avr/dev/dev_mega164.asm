;;; -*- asm -*-

init:
	;; Initialize UART
	ldi     r16,0		; 9600bps (19.2MHz)
        sts	UBRR0H,r16
        ldi     r16,124		; 9600bps (19.2MHz)
        sts     UBRR0L,r16
        ldi     r16,0b00000000
        sts     UCSR0A,r16
        ldi     r16,0b00011000	; Enable Tx,Rx
        sts     UCSR0B,r16
        ldi     r16,0b00000110	; 8bit NONE
        sts     UCSR0C,r16
	ret
	
conin:
	;; Console Input
	lds	r24,UCSR0A
	andi	r24,0b10000000
	breq	conin
	lds	r16,UDR0
	ret

	;; Console status
const:
        clr     r16
	lds	r24,UCSR0A
        sbrc    r24,7
        ldi     r16,1
        ret
	
conout:
	;; Console Output
	lds	r24,UCSR0A
	andi	r24,0b00100000
	breq	conout
	sts	UDR0,r16
	ret
	
