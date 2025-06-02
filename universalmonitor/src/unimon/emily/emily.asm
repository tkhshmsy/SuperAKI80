;;;
;;;	EMILY Board  (Shared Memory Platform 4K)
;;;

	include	"config.inc"

;;; AVR local definitions
XL	reg	r26
XH	reg	r27
YL	reg	r28
YH	reg	r29
ZL	reg	r30
ZH	reg	r31

	include	"../common.inc"
	include	"../emily.inc"
	
PB_CS0	equ	0
PB_CS1	equ	1
PB_CS2	equ	2
PB_CS3	equ	3
PB_RES	equ	4

PD_ALEH	equ	4
PD_ALEL	equ	5
PD_RD	equ	6
PD_WR	equ	7
	
TWI_TO	equ	100		; TWI timeout (0.1ms)  100 = 10ms

;;;
;;; ROM area
;;;
	
	segment	code

	org	0x0000
	rjmp	cstart

	;; org	0x000E
	;; rjmp	pci3_int
	
	org	0x0020
	jmp	t0_int

	org	0x0100

cstart:
	cli
	;; Initialize Stack Pointer
	ldi	r16,low(STACK)
	out	SPL,r16
	ldi	r16,high(STACK)
	out	SPH,r16

	call	init

	;; Initialize ports
	ldi	r16,0b11111111
	out	PORTA,r16
	clr	r16
	out	DDRA,r16

	ldi	r16,0b00001111
	out	PORTB,r16
	ldi	r16,0b00011111
	out	DDRB,r16

	ldi	r16,0b11111100
	out	PORTC,r16

	ldi	r16,0b11110000
	out	PORTD,r16
	out	DDRD,r16
	
	;; Initialize UART1
        ldi     r16,0		; 9600bps (19.2MHz)
        sts     UBRR1H,r16
        ldi     r16,124		; 9600bps (19.2MHz)
        sts     UBRR1L,r16
        ldi     r16,0b00000000
        sts     UCSR1A,r16
        ldi     r16,0b00011000	; Enable Tx,Rx
        sts     UCSR1B,r16
        ldi     r16,0b00000110	; 8bit NONE
        sts     UCSR1C,r16

	;; Initialize timer 0
	ldi	r16,0b00000010	; CTC
	out	TCCR0A,r16
	ldi	r16,0b00001100	; CTC, /256
	out	TCCR0B,r16
	ldi	r16,14		; 200us
	out	OCR0A,r16
	ldi	r16,0b00000010
	sts	TIMSK0,r16

	;; Initialize TWI (I2C)
	ldi	r16,16		; TWBR=16 (400kHz @ 19.2MHz)
	sts	TWBR,r16
	ldi	r16,0		; TWPS=0
	sts	TWSR,r16
	sts	TWCR,r16
	
        ;; Initialize work area
        clr     r0
        sts     saddrh,r0
        sts     saddrl,r0
        sts     dsadrh,r0
        sts     dsadrl,r0

	sts	timer,r0	; timer = 0
	sts	timer2,r0	; timer2 = 0

	ldi	r16,1		; Try target EEPROM
	sts	eenum,r16
	rcall	epread
	brcc	cs0

	sts	eenum,r0	; Try internal EEPROM
	rcall	epread
	brcc	cs0

	ldi	r16,0x0f	; 0FF0 - 0FFF
	sts	shmadr,r16
	ldi	r16,0xf0	; 0FF0 - 0FFF
	sts	shmadr+1,r16
	sts	shmoff,r0	; +1
	sts	shmar,r0
	ldi	r16,1
	sts	mmnum,r16
	sts	mmode,r0
	sts	amode,r0
cs0:
        ldi     r16,'I'
        sts     hexmod,r16
	sts	marea,r0
	sei
	
	;; Opening message
        ldi     ZL,low(opnmsg)
        ldi     ZH,high(opnmsg)
        rcall   msgout
	rcall	mdetect
	rcall	mddisp
        ldi     ZL,low(opnmsg2)
        ldi     ZH,high(opnmsg2)
        rcall   msgout

	rcall	chkmm
	breq	cs1
	clr	r16
	sts	mmode,r16
cs1:	
	rcall	cmdd
	rcall	add
	rcall	cadisp

	;; Auto load
	lds	r16,amode
	tst	r16
	breq	cs2

	;; Load
	rcall	emloadm
	brcs	cse
	rcall	emloadb
	brcs	cse
	
	lds	r16,amode
	cpi	r16,2
	brne	cs2

	;; Start
	cbi	DDRB,PB_RES	;
	rjmp	cs2
cse:
	rjmp	err
cs2:
	
wstart:
        ldi     r16,'>'
        call   conout
        ldi     r16,' '
        call   conout
        rcall   getlin
        ldi     XL,low(inbuf)
        ldi     XH,high(inbuf)
        rcall   skipsp
        tst     r16
        breq    wstart          ; Null command
        rcall   upper

	cpi	r16,'D'
	brne	ml0
	rjmp	dump
ml0:
	cpi	r16,'S'
	brne	ml1
	rjmp	setm
ml1:
        cpi     r16,'L'
        brne    ml2
	rjmp    loadh
ml2:
	cpi	r16,'P'
	brne	ml3
	rjmp	saveh
ml3:
	cpi	r16,'A'
	brne	ml4
	rjmp	addr
ml4:
	cpi	r16,'T'
	brne	ml5
	rjmp	target
ml5:
	cpi	r16,'H'
	brne	ml6
	rjmp	area
ml6:
	cpi	r16,'E'
	brne	ml7
	rjmp	eesub
ml7:
	cpi	r16,'Q'
	brne	ml8
	rjmp	config
ml8:
	cpi	r16,'F'
	brne	ml9
	rjmp	fill
ml9:
	cpi	r16,'M'
	brne	ml10
	rjmp	move
ml10:
	
err:
	ldi	ZL,low(errmsg)
	ldi	ZH,high(errmsg)
	rcall	msgout
	rjmp	wstart

	;;
	;; D(ump)
	;; 
dump:
	rcall	dparam

	adiw	XL,1
	rcall	skipsp
	call	rdadr
	tst	r13
	brne	dp0
	; No arg.
	rcall	skipsp
	tst	r16
	brne	dpe
	lds	r10,dsadrh
	lds	r11,dsadrl
	lds	r16,dlen
	add	r11,r16
	adc	r10,r0
	sts	deadrh,r10
	sts	deadrl,r11
	rjmp	dpm
dpe:
	rjmp	err

dp0:
	sts	dsadrh,r14
	sts	dsadrl,r15
	rcall	skipsp
	cpi	r16,','
	breq	dp1
	tst	r16
	brne	dpe
	; No 2nd arg.
	lds	r16,dlen
	add	r15,r16
	adc	r14,r0
	sts	deadrh,r14
	sts	deadrl,r15
	rjmp	dpm
dp1:
	adiw	XL,1
	rcall	skipsp
	rcall	getmm
	call	rdadr0		; area not allowed here
	rcall	skipsp
	tst	r13
	breq	dpe
	tst	r16
	brne	dpe
	sec
	adc	r15,r0
	adc	r14,r0
	sts	deadrh,r14
	sts	deadrl,r15
dpm:
	lds	r10,dsadrh
	lds	r11,dsadrl
	lds	r16,dmsk
	and	r11,r16
	sts	dstate,r0
dpm0:
	rcall	dpl
	call	const
	tst	r16
	brne	dpm1
	lds	r16,dstate
	cpi	r16,2
	brcs	dpm0
	lds	r10,deadrh
	lds	r11,deadrl
	sts	dsadrh,r10
	sts	dsadrl,r11
	rjmp	wstart
dpm1:
	sts	dsadrh,r10
	sts	dsadrl,r11
	call	conin
	rjmp	wstart

dpl:
	rcall	areaout
	rcall	adrout
	;mov	r16,r10
	;rcall	hexout2
	;mov	r16,r11
	;rcall	hexout2
	ldi	ZH,high(dsep0)
	ldi	ZL,low(dsep0)
	rcall	msgout
	ldi	XH,high(inbuf)
	ldi	XL,low(inbuf)
	lds	r19,dnum
dpl0:
	rcall	dpb
	dec	r19
	brne	dpl0

	lds	r16,mflag
	andi	r16,0x10	; Skip ASCII dump
	brne	dpl4
	
	ldi	ZH,high(dsep1)
	ldi	ZL,low(dsep1)
	rcall	msgout

	ldi	XH,high(inbuf)
	ldi	XL,low(inbuf)
	ldi	r19,16
dpl1:
	ld	r16,X+
	cpi	r16,' '
	brcs	dpl2
	cpi	r16,0x7f
	brcc	dpl2
	call	conout
	rjmp	dpl3
dpl2:
	ldi	r16,'.'
	call	conout
dpl3:
	dec	r19
	brne	dpl1
dpl4:
	rjmp	crlf

dpb:
	ldi	r16,' '
	call	conout
	lds	r16,dstate
	tst	r16
	brne	dpb2
	; Dump state 0
	lds	r16,dsadrl
	cp	r16,r11
	brne	dpb0
	lds	r16,dsadrh
	cp	r16,r10
	breq	dpb1
dpb0:
	rcall	dskp
	ldi	r16,' '
	mov	r8,r16
	mov	r9,r16
	rcall	stasc
	;st	X+,r16
	sec
	adc	r11,r0
	adc	r10,r0
	ret
dpb1:
	ldi	r16,1
	sts	dstate,r16
dpb2:
	lds	r16,dstate
	cpi	r16,1
	brne	dpb0
	;; rcall	open
	call	readw
	;; rcall	close
	;st	X+,r8
	rcall	datout
	rcall	stasc
	sec
	adc	r11,r0
	adc	r10,r0
	lds	r16,deadrl
	cp	r16,r11
	brne	dpbr
	lds	r16,deadrh
	cp	r16,r10
	brne	dpbr
	ldi	r16,2
	sts	dstate,r16
dpbr:
	ret

	;; Skip data output
dskp:
	rcall	getmm
	cpi	r16,(dstabe-dstab)
	brcs	dsk0
	ret
dsk0:	
	ldi	ZH,high(dstab)
	ldi	ZL,low(dstab)
	add	ZL,r16
	adc	ZH,r0
	lsl	ZL
	rol	ZH
	lpm	r16,Z+
	lpm	ZH,Z
	mov	ZL,r16
	ijmp

dstab:
	data	ds00, ds00, ds00, ds00
	data	ds04, ds04, ds04, ds04
	data	ds00, ds00, ds00, ds00
	data	ds00, ds00, ds00, ds00

	data	ds00, ds00, ds00, ds00
	data	ds04, ds04, ds04, ds04
	data	ds00, ds00, ds00, ds00
	data	ds00, ds00, ds00, ds00
dstabe:

ds00:
	ldi	r16,' '
	call	conout
	ldi	r16,' '
	jmp	conout

ds04:
	ldi	r16,' '
	call	conout
	ldi	r16,' '
	call	conout
	rjmp	ds00

	;; Set data for ASCII dump
stasc:
	rcall	getmm
	cpi	r16,(satabe-satab)
	brcs	sta0
	ret
sta0:	
	ldi	ZH,high(satab)
	ldi	ZL,low(satab)
	add	ZL,r16
	adc	ZH,r0
	lsl	ZL
	rol	ZH
	lpm	r16,Z+
	lpm	ZH,Z
	mov	ZL,r16
	ijmp

satab:
	data	sa00, sa00, sa00, sa00
	data	sa04, sa04, sa06, sa06
	data	sa00, sa00, sa00, sa00
	data	sa00, sa00, sa00, sa00

	data	sa00, sa00, sa00, sa00
	data	sa04, sa04, sa06, sa06
	data	sa00, sa00, sa00, sa00
	data	sa00, sa00, sa00, sa00
satabe:

sa00:
	st	X+,r8
	ret
	
sa04:
	st	X+,r8
	st	X+,r9
	ret
	
sa06:
	st	X+,r0
	st	X+,r0
	ret

	;; DUMP parameter
dparam:
	rcall	getmm
	cpi	r16,(mmtabe-mmtab)/2 ; 2 word per entry
	brcs	dprm0
	clr	r16
dprm0:
	lsl	r16		; 2 word per entry
	ldi	ZH,high(mmtab)
	ldi	ZL,low(mmtab)
	add	ZL,r16
	adc	ZH,r0
	lsl	ZL
	rol	ZH
	lpm	r16,Z+
	sts	mflag,r16
	lpm	r16,Z+
	sts	dmsk,r16
	lpm	r16,Z+
	sts	dlen,r16
	lpm	r16,Z+
	sts	dnum,r16
	ret

	;;
	;; S(et)
	;; 
setm:
	adiw	XL,1
	rcall	skipsp
	rcall	rdadr
	rcall	skipsp
	tst	r16
	brne	sete0
	tst	r13
	brne	stm0	; argument found
	lds	r10,saddrh
	lds	r11,saddrl
	rjmp	stm1
sete0:
	rjmp	err
stm0:
	mov	r10,r14
	mov	r11,r15
stm1:
	rcall	areaout
	rcall	adrout
	;mov	r16,r10
	;rcall	hexout2
	;mov	r16,r11
	;rcall	hexout2
	ldi	ZL,low(dsep1)
	ldi	ZH,high(dsep1)
	rcall	msgout
	;; rcall	open
	rcall	readw
	;; rcall	close
	rcall	datout
	ldi	r16,' '
	call	conout
	rcall	getlin
	ldi	XL,low(inbuf)
	ldi	XH,high(inbuf)
	rcall	skipsp
	tst	r16
	brne	stm2
	; Empty
	sec
	adc	r11,r0
	adc	r10,r0
	sts	saddrh,r10
	sts	saddrl,r11
	rjmp	stm1
stm2:
	cpi	r16,'-'
	brne	sm3
	sec
	sbc	r11,r0
	sbc	r10,r0
	sts	saddrh,r10
	sts	saddrl,r11
	rjmp	stm1
sm3:
	cpi	r16,'.'
	brne	sm4
	rjmp	wstart
sm4:
	rcall	rddat
	tst	r13
	breq	sete
	;; rcall	open
	call	writew
	;; rcall	close
	sec
	adc	r11,r0
	adc	r10,r0
	sts	saddrh,r10
	sts	saddrl,r11
	rjmp	stm1
sete:
	rjmp	err

	;;
	;; L(oad)
	;; 
loadh:
	clr	r16
	sts	leaddr,r16
	sts	leaddr+1,r16
	ldi	r16,0xFF
	sts	lsaddr,r16
	sts	lsaddr+1,r16

	adiw	XL,1
	rcall	skipsp
	rcall	rdadr
	rcall	skipsp
	tst	r16
	brne	sete
	tst	r13
	brne	lh0

	clr	r14
	clr	r15
lh0:
	rcall	adrw2b

	call	conin
	rcall	upper
	cpi	r16,'S'
	brne	lh1
	rjmp	lhs1
lh1:
	cpi	r16,':'
	brne	lh0

	ldi	XH,high(inbuf)
	ldi	XL,low(inbuf)
	clr	r19
	clr	r20
lhi1:
	rcall	hexin
	ldi	r18,2
	cp	r9,r18
	brne	lhi2
	st	X+,r8
	add	r20,r8
	inc	r19
	cpi	r19,BUFLEN
	brcs	lhi1
lhi2:
	tst	r20
	brne	lhie		; Checksum error
	lds	r20,inbuf	; Length
	subi	r20,-5		; (Len+Adr*2+Typ+Sum)
	cp	r19,r20
	breq	lhi3
lhie:
	ldi	ZH,high(ihemsg)
	ldi	ZL,low(ihemsg)
	rcall	msgout
	rjmp	wstart
lhi3:
	lds	r20,inbuf	; Length
	tst	r20
	breq	lhir
	lds	r19,inbuf+3	; Type
	tst	r19
	breq	lhi4		; Data record
	cpi	r19,1
	breq	lhir		; End record
	rjmp	lh0		; Unknown record
lhi4:
	lds	r10,inbuf+1
	lds	r11,inbuf+2
	add	r11,r15
	adc	r10,r14
	ldi	XH,high(inbuf+4)
	ldi	XL,low(inbuf+4)
	;; rcall	open
lhi5:
	ld	r8,X+
	rcall	lhr
	rcall	write
	sec
	adc	r11,r0
	adc	r10,r0
	dec	r20
	brne	lhi5
	;; rcall	close
	ldi	r16,'I'
	sts	hexmod,r16
	rjmp	lh0
lhir:
	rcall	lhd
	rjmp	wstart

lhs1:
	call	conin
	subi	r16,'0'
	brcc	lhs3
lhs2:
	rjmp	lh0     ; Record is not a number
lhs3:
	cpi	r16,10
	brcc	lhs2
	ldi	XH,high(inbuf)
	ldi	XL,low(inbuf)
	st	X+,r16	; Record number
	ldi	r19,1
	clr	r20
lhs4:
	rcall	hexin
	ldi	r18,2
	cp	r9,r18
	brne	lhs5
	st	X+,r8
	add	r20,r8
	inc	r19
	cpi	r19,BUFLEN
	brcs	lhs4
lhs5:
	cpi	r20,0xff
	brne	lhse
	lds	r20,inbuf+1	; Length
	subi	r20,-2		; (Typ+Len)
	cp	r19,r20
	breq	lhs6
lhse:
	ldi	ZH,high(shemsg)
	ldi	ZL,low(shemsg)
	rcall	msgout
	rjmp	wstart
lhs6:
	ldi	XH,high(inbuf)
	ldi	XL,low(inbuf)
	ld	r19,X+		; Type
	ld	r20,X+		; Length
	cpi	r19,1
	brne	lhs61
	; Type 1
	ld	r10,X+
	ld	r11,X+
	subi	r20,2+1		; (Adr*2+Sum)
	rjmp	lhs7
lhs61:
	cpi	r19,2
	brne	lhs62
	; Type 2
	adiw	XL,1		; Skip A23-A16
	ld	r10,X+
	ld	r11,X+
	subi	r20,3+1		; (Adr*3+Sum)
	rjmp	lhs7
lhs62:
	cpi	r19,3
	brne	lhs63
	; Type 3
	adiw	XL,2		; Skip A31-A16
	ld	r10,X+
	ld	r11,X+
	subi	r20,4+1		; (Adr*4+Sum)
	rjmp	lhs7
lhs63:
	cpi	r19,9
	breq	lhsr
	cpi	r19,8
	breq	lhsr
	cpi	r19,7
	breq	lhsr
	rjmp	lh0		; Unknown record
lhs7:
	add	r11,r15
	adc	r10,r14
	;; rcall	open
lhs8:
	ld	r8,X+
	rcall	lhr
	rcall	write
	sec
	adc	r11,r0
	adc	r10,r0
	dec	r20
	brne	lhs8
	;; rcall	close
	ldi	r16,'S'
	sts	hexmod,r16
	rjmp	lh0
lhsr:
	rcall	lhd
	rjmp	wstart

lhr:
	lds	r16,lsaddr
	cp	r10,r16
	breq	lhr0
	brcs	lhr1
	rjmp	lhr2
lhr0:
	lds	r16,lsaddr+1
	cp	r11,r16
	brcc	lhr2
lhr1:
	sts	lsaddr,r10
	sts	lsaddr+1,r11
lhr2:
	lds	r16,leaddr
	cp	r10,r16
	breq	lhr3
	brcc	lhr4
	rjmp	lhr5
lhr3:
	lds	r16,leaddr+1
	cp	r11,r16
	brcs	lhr5
lhr4:
	sts	leaddr,r10
	sts	leaddr+1,r11
lhr5:	
	ret

lhd:
        ldi     ZL,low(ldrmsg)
        ldi     ZH,high(ldrmsg)
        rcall   msgout

	lds	r14,lsaddr
	lds	r15,lsaddr+1
	rcall	adrb2w
	mov	r10,r14
	mov	r11,r15
	rcall	adrout
	ldi	r16,'-'
	call	conout
	lds	r14,leaddr
	lds	r15,leaddr+1
	rcall	adrb2w
	mov	r10,r14
	mov	r11,r15
	rcall	adrout

	ldi	r16,' '
	call	conout
	ldi	r16,'('
	call	conout
	
	lds	r16,lsaddr
	rcall	hexout2
	lds	r16,lsaddr+1
	rcall	hexout2
	ldi	r16,'-'
	call	conout
	lds	r16,leaddr
	rcall	hexout2
	lds	r16,leaddr+1
	rcall	hexout2

	ldi	r16,')'
	call	conout
	rjmp	crlf

	;;
	;; P(unch)
	;; 
saveh:
	adiw	XL,1
	ld	r16,X
	rcall	upper
	cpi	r16,'I'
	breq	sh0
	cpi	r16,'S'
	brne	sh1
sh0:
	adiw	XL,1
	sts	hexmod,r16
sh1:
	rcall	skipsp
	rcall	rdadr		; Start address
	tst	r13
	breq	she
	rcall	adrw2b
	mov	r10,r14
	mov	r11,r15
	rcall	skipsp
	cpi	r16,','
	brne	she
	adiw	XL,1
	rcall	skipsp
	rcall	getmm
	rcall	rdadr0		; End address (area not allowed here)
	tst	r13
	breq	she
	rcall	skipsp
	tst	r16
	breq	sh2
she:
	rjmp	err
sh2:
	sec
	adc	r15,r0
	adc	r14,r0
	rcall	adrw2b
	sub	r15,r11
	sbc	r14,r10
sh3:
	rcall	shl
	mov	r16,r14
	or	r16,r15
	brne	sh3	
	lds	r16,hexmod
	cpi	r16,'I'
	brne	sh4
	ldi	ZH,high(ihexer)
	ldi	ZL,low(ihexer)
	rcall	msgout
	rjmp	wstart
sh4:
	ldi	ZH,high(srecer)
	ldi	ZL,low(srecer)
	rcall	msgout
	rjmp	wstart

shl:
	ldi	r19,16
	tst	r14
	brne	shl0
	cp	r15,r19
	brcc	shl0
	mov	r19,r15
shl0:
	lds	r16,hexmod
	cpi	r16,'I'
	brne	shls

	;; Intel HEX
	clr	r20
	ldi	r16,':'
	;sub	r20,r16
	call	conout
	mov	r16,r19
	sub	r20,r16
	rcall	hexout2		; Length
	mov	r16,r10
	sub	r20,r16
	rcall	hexout2		; Address (H)
	mov	r16,r11
	sub	r20,r16
	rcall	hexout2		; Address (L)
	clr	r16
	sub	r20,r16
	rcall	hexout2		; Type
	sub	r15,r19
	sbc	r14,r0
	;; rcall	open
shli0:
	rcall	read
	mov	r16,r8
	sub	r20,r8
	rcall	hexout2
	sec
	adc	r11,r0
	adc	r10,r0
	dec	r19
	brne	shli0
	;; rcall	close
	mov	r16,r20
	rcall	hexout2		; Checksum
	rcall	crlf
	ret

shls:
	; Motorola S record
	ldi	r20,0xff
	ldi	r16,'S'
	call	conout
	ldi	r16,'1'
	call	conout
	mov	r16,r19
	subi	r16,-(2+1)	; (Adr*2+Sum)
	sub	r20,r16
	rcall	hexout2		; Length
	mov	r16,r10
	sub	r20,r16
	rcall	hexout2		; Address (H)
	mov	r16,r11
	sub	r20,r16
	rcall	hexout2		; Address (L)
	sub	r15,r19
	sbc	r14,r0
	;; rcall	open
shls2:
	rcall	read
	mov	r16,r8
	sub	r20,r8
	rcall	hexout2
	sec
	adc	r11,r0
	adc	r10,r0
	dec	r19
	brne	shls2
	;; rcall	close
	mov	r16,r20
	rcall	hexout2		; Checksum
	rcall	crlf
	ret

	;;
	;; F(ill)
	;;
fill:
	adiw	XL,1
	rcall	skipsp
	rcall	rdadr
	tst	r13
	breq	fle
	sts	fmaddr,r14
	sts	fmaddr+1,r15
	rcall	skipsp
	cpi	r16,','
	brne	fle
	adiw	XL,1
	rcall	skipsp
	rcall	getmm
	rcall	rdadr0		; area not allowed here
	tst	r13
	breq	fle
	lds	r16,fmaddr+1
	sub	r15,r16
	lds	r16,fmaddr
	sbc	r14,r16
	sec			; inc r14:r15
	adc	r15,r0
	adc	r14,r0
	sts	fmlen,r14
	sts	fmlen+1,r15
	rcall	skipsp
	cpi	r16,','
	brne	fle
	adiw	XL,1
	rcall	skipsp
	rcall	rddat
	tst	r13
	breq	fle
	rcall	skipsp
	tst	r16
	breq	fl0
fle:
	rjmp	err

fl0:
	lds	r10,fmaddr	; Start address
	lds	r11,fmaddr+1
	lds	r12,fmlen	; Length
	lds	r13,fmlen+1
fl1:
	push	r8
	push	r9
	rcall	writew
	pop	r9
	pop	r8

	sec			; inc r10:r11
	adc	r11,r0
	adc	r10,r0
	sec			; dec r12:r13
	sbc	r13,r0
	sbc	r12,r0
	mov	r16,r12		; tst r12:r13
	or	r16,r13
	brne	fl1
	rjmp	wstart

	;;
	;; M(ove)
	;;
move:
	adiw	XL,1
	rcall	skipsp
	rcall	rdadr
	tst	r13
	breq	mve
	sts	fmaddr,r14
	sts	fmaddr+1,r15
	rcall	skipsp
	cpi	r16,','
	brne	mve
	adiw	XL,1
	rcall	skipsp
	rcall	getmm
	rcall	rdadr0		; area not allowed here
	tst	r13
	breq	mve
	lds	r16,fmaddr+1
	sub	r15,r16
	lds	r16,fmaddr
	sbc	r14,r16
	sec			; inc r14:r15
	adc	r15,r0		;
	adc	r14,r0		;
	sts	fmlen,r14
	sts	fmlen+1,r15
	rcall	skipsp
	cpi	r16,','
	brne	mve
	adiw	XL,1
	rcall	skipsp
	lds	r16,marea
	rcall	rdarea
	sts	marea1,r16
	rcall	getmm0
	rcall	rdadr0		; Destination
	tst	r13
	breq	mve
	rcall	skipsp
	tst	r16
	breq	mv0
mve:
	rjmp	err
mv0:
	lds	r12,fmlen
	lds	r13,fmlen+1
	lds	r16,fmaddr
	cp	r14,r16
	brcs	mvi		; src > dest
	brne	mvd		; src < dest
	lds	r16,fmaddr+1
	cp	r15,r16
	brcs	mvi		; src > dest
	brne	mvd		; src < dest
	rjmp	wstart		; src = dest : Do nothing

mvi:				; Memory copy (LDIR type)
	lds	r10,fmaddr
	lds	r11,fmaddr+1
	rcall	readw
	sec
	adc	r11,r0
	adc	r10,r0
	sts	fmaddr,r10
	sts	fmaddr+1,r11
	mov	r10,r14
	mov	r11,r15
	rcall	writew
	sec			; inc r14:r15
	adc	r15,r0
	adc	r14,r0

	sec			; dec r12:r13
	sbc	r13,r0
	sbc	r12,r0
	mov	r16,r12		; tst r12:r13
	or	r16,r13
	brne	mvi
	rjmp	wstart

mvd:				; Memory copy (LDDR type)
	lds	r16,fmaddr+1	; (fmaddr) = (fmaddr) + r12:r13
	add	r16,r13
	sts	fmaddr+1,r16
	lds	r16,fmaddr
	adc	r16,r12
	sts	fmaddr,r16

	add	r15,r13		; r14:r15 = r14:r15 + r12:r13
	adc	r14,r12
mvd0:
	lds	r10,fmaddr
	lds	r11,fmaddr+1
	sec			; dec r10:r11
	sbc	r11,r0
	sbc	r10,r0
	sts	fmaddr,r10
	sts	fmaddr+1,r11
	rcall	readw
	sec			; dec r14:r15
	sbc	r15,r0
	sbc	r14,r0
	mov	r10,r14
	mov	r11,r15
	rcall	writew
	
	sec			; dec r12:r13
	sbc	r13,r0
	sbc	r12,r0
	mov	r16,r12		; tst r12:r13
	or	r16,r13
	brne	mvd0
	rjmp	wstart

	;;
	;; T(arget)
	;; 
target:
	adiw	XL,1
	ld	r16,X
	rcall	upper
	cpi	r16,'R'
	breq	treset
	cpi	r16,'H'
	breq	thalt
	cpi	r16,'5'
	breq	tpb5
te:	
	rjmp	err

treset:
	adiw	XL,1
	ld	r16,X
	tst	r16
	brne	te

	sbi	DDRB,PB_RES
	ldi	r16,50
	sts	timer,r16
tr0:
	lds	r16,timer
	tst	r16
	brne	tr0
	cbi	DDRB,PB_RES

	rjmp	wstart

thalt:
	adiw	XL,1
	ld	r16,X
	tst	r16
	brne	te

	sbi	DDRB,PB_RES

	rjmp	wstart

tpb5:
	adiw	XL,1
	rcall	skipsp
	ld	r16,X+
	ld	r17,X
	tst	r17
	brne	te
	rcall	upper
	cpi	r16,'I'
	brne	t51
	;; In
	cbi	DDRB,5
	rjmp	wstart
t51:
	cpi	r16,'O'
	brne	t52
	;; Out
	sbi	DDRB,5
	rjmp	wstart
t52:
	cpi	r16,'H'
	brne	t53
	;; High
	sbi	PORTB,5
	rjmp	wstart
t53:
	cpi	r16,'L'
	brne	t54
	;; Low
	cbi	PORTB,5
	rjmp	wstart
t54:
	cpi	r16,'P'
	brne	te
	;; Pulse
	in	r16,PORTB
	ldi	r17,0b00100000
	eor	r16,r17
	out	PORTB,r16
	nop
	eor	r16,r17
	out	PORTB,r16
	rjmp	wstart

	;;
	;; (H) Memory Area
	;;
area:
	adiw	XL,1
	rcall	skipsp
	tst	r16
	breq	ard
	ld	r16,X+
	subi	r16,'0'
	brcs	are
	cpi	r16,7+1
	brcc	are
	mov	r15,r16
	rcall	skipsp
	tst	r16
	brne	are
	lds	r16,mmnum
	cp	r15,r16
	brcc	are
	sts	marea,r15
ard:
	ldi	ZH,high(marmsg)
	ldi	ZL,low(marmsg)
	rcall	msgout
	lds	r16,marea
	ori	r16,'0'
	call	conout
	rcall	crlf
	rjmp	wstart
are:	
	rjmp	err

	;;
	;; (E)EPROM sub-commands
	;;
eesub:
	adiw	XL,1
	ld	r16,X+
	rcall	upper
	cpi	r16,'R'
	brne	ees0
	rjmp	epr
ees0:
	cpi	r16,'W'
	brne	ees1
	rjmp	epw
ees1:
	cpi	r16,'S'
	brne	ees2
	rjmp	ems
ees2:
	cpi	r16,'L'
	brne	ees3
	rjmp	eml
ees3:
	cpi	r16,'V'
	brne	ees4
	rjmp	emv
ees4:
	
eese:
	rjmp	err

	;; (ER) EEPROM parameter read
epr:
	rcall	skipsp
	ld	r16,X+
	tst	r16
	breq	epr1
	subi	r16,'0'
	ld	r17,X
	tst	r17
	breq	epr0
	rjmp	err
epr0:
	sts	eenum,r16
epr1:
	rcall	epread
	brcs	eese

	rcall	chkmm
	breq	epr2
	clr	r16
	sts	mmode,r16
epr2:
	rjmp	wstart	

epread:
	ldi	XL,low(eptmp)
	ldi	XH,high(eptmp)
	clr	YL
	clr	YH
	ldi	r17,32
eprd0:
	rcall	eeread
	brcs	eprde
	st	X+,r8
	adiw	YL,1
	dec	r17
	brne	eprd0

	ldi	XL,low(eptmp)
	ldi	XH,high(eptmp)
	ld	r16,X+
	cpi	r16,0xFF
	brne	eprde
	ld	r16,X+
	cpi	r16,0xAA
	brne	eprde
	ld	r16,X+
	cpi	r16,0x55
	brne	eprde
	ld	r16,X+
	cpi	r16,0x50
	brne	eprde

	ldi	XL,low(eptmp)
	ldi	XH,high(eptmp)
	ldi	YL,low(epbuf)
	ldi	YH,high(epbuf)
	ldi	r17,32
eprd1:
	ld	r16,X+
	st	Y+,r16
	dec	r17
	brne	eprd1
	clc
	ret
eprde:
	sec
	ret
	
	;; (EW) EEPROM parameter write
epw:
	rcall	skipsp
	ld	r16,X+
	tst	r16
	breq	epw1
	subi	r16,'0'
	ld	r17,X
	tst	r17
	breq	epw0
	rjmp	err
epw0:
	sts	eenum,r16
epw1:
	rcall	epwrite
	brcs	epwe
	rjmp	wstart	
epwe:
	rjmp	err
	
epwrite:	
	ldi	XL,low(epbuf)
	ldi	XH,high(epbuf)
	ldi	r16,0xFF
	st	X+,r16
	ldi	r16,0xAA
	st	X+,r16
	ldi	r16,0x55
	st	X+,r16
	ldi	r16,0x50
	st	X+,r16

	ldi	XL,low(epbuf)
	ldi	XH,high(epbuf)
	clr	YL
	clr	YH
	ldi	r17,32
epwr0:
	rcall	eeread
	brcs	epwre
	ld	r16,X+
	cp	r16,r8
	breq	epwr1

	mov	r8,r16
	rcall	eewrite
epwr1:
	adiw	YL,1
	dec	r17
	brne	epwr0

	clc
	ret	
epwre:
	sec
	ret

	;; (ES) EEPROM memory save
ems:
	rcall	skipsp
	ld	r16,X
	tst	r16
	breq	ems0

	rcall	rdhex
	tst	r13
	breq	emse
	rcall	adrw2b
	sts	emadr,r14
	sts	emadr+1,r15
	rcall	skipsp
	ld	r16,X+
	cpi	r16,','
	brne	emse
	rcall	skipsp
	rcall	rdhex
	tst	r13
	breq	emse

	sec
	adc	r15,r0
	adc	r14,r0
	rcall	adrw2b
	rjmp	ems1
ems0:
	lds	r16,lsaddr
	sts	emadr,r16
	lds	r16,lsaddr+1
	sts	emadr+1,r16
	lds	r14,leaddr
	lds	r15,leaddr+1

	sec
	adc	r15,r0
	adc	r14,r0
ems1:
	lds	r16,emadr+1
	sub	r15,r16
	lds	r16,emadr
	sbc	r14,r16
	sts	emlen,r14
	sts	emlen+1,r15

	rcall	emsb
	brcs	emse
	rcall	emsm
	brcs	emse
	rjmp	wstart
	
emse:	
	rjmp	err

emsm:				; Save Meta Data
	ldi	XL,low(emsig0)	; Signature
	ldi	XH,high(emsig0)
	ldi	r16,0xFF
	st	X+,r16
	ldi	r16,0xAA
	st	X+,r16
	ldi	r16,0x55
	st	X+,r16
	ldi	r16,0x53
	st	X+,r16

	ldi	XL,low(embuf)
	ldi	XH,high(embuf)
	ldi	YL,low(128)
	ldi	YH,high(128)
	ldi	r17,16
emsm0:
	ld	r8,X+
	rcall	ee1write
	brcs	emsme
	adiw	YL,1
	dec	r17
	brne	emsm0
	clc
	ret
emsme:
	sec
	ret

emsb:				; Save Binary Data
	lds	XH,emadr
	lds	XL,emadr+1
	ldi	YH,high(256)
	ldi	YL,low(256)
	lds	r19,emlen
	lds	r20,emlen+1
emsb0:
	push	YH
	push	YL
	mov	r10,XH
	mov	r11,XL
	rcall	read
	pop	YL
	pop	YH
	rcall	ee1write
	brcs	emsbe
	adiw	XL,1
	adiw	YL,1
	sec
	sbc	r20,r0
	sbc	r19,r0
	mov	r16,r20
	or	r16,r19
	brne	emsb0
	clc
	ret
emsbe:
	sec
	ret
	
	;; (EL) EEPROM memory load
eml:
	rcall	skipsp
	clr	r14
	clr	r15
	ld	r16,X
	tst	r16
	breq	eml0

	rcall	rdhex
	tst	r13
	breq	emle
	ld	r16,X
	tst	r16
	brne	emle
	rcall	adrw2b
eml0:
	rcall	emloadm
	brcs	emle
	lds	r16,emadr+1
	add	r16,r15
	sts	emadr+1,r16
	lds	r16,emadr
	adc	r16,r14
	sts	emadr,r16

	rcall	emloadb
	brcs	emle
	rjmp	wstart
	
emle:	
	rjmp	err

	;; (EM) EEPROM memory verify
emv:
	rcall	skipsp
	clr	r14
	clr	r15
	ld	r16,X
	tst	r16
	breq	emv0

	rcall	rdhex
	tst	r13
	breq	emve
	ld	r16,X
	tst	r16
	brne	emve
	rcall	adrw2b
emv0:
	rcall	emloadm
	brcs	emve
	lds	r16,emadr+1
	add	r16,r15
	sts	emadr+1,r16
	lds	r16,emadr
	adc	r16,r14
	sts	emadr,r16

	rcall	emverib
	brcs	emve
	rjmp	wstart
	
emve:	
	rjmp	err

emloadm:			; Load Meta Data
	ldi	XH,high(embuf)
	ldi	XL,low(embuf)
	ldi	YH,high(128)
	ldi	YL,low(128)
	ldi	r17,16
emlm0:
	rcall	ee1read
	brcs	emlme
	st	X+,r8
	adiw	YL,1
	dec	r17
	brne	emlm0

	ldi	XH,high(embuf)
	ldi	XL,low(embuf)
	ld	r16,X+
	cpi	r16,0xFF
	brne	emlme
	ld	r16,X+
	cpi	r16,0xAA
	brne	emlme
	ld	r16,X+
	cpi	r16,0x55
	brne	emlme
	ld	r16,X+
	cpi	r16,0x53
	brne	emlme
	
	clc
	ret
emlme:
	sec
	ret

emloadb:			; Load Binary Data
	lds	XH,emadr
	lds	XL,emadr+1
	ldi	YH,high(256)
	ldi	YL,low(256)
	lds	r19,emlen
	lds	r20,emlen+1
emlb0:
	rcall	ee1read
	brcs	emlbe
	push	YH
	push	YL
	mov	r10,XH
	mov	r11,XL
	rcall	write
	pop	YL
	pop	YH
	adiw	YL,1
	adiw	XL,1
	sec
	sbc	r20,r0
	sbc	r19,r0
	mov	r16,r20
	or	r16,r19
	brne	emlb0
	clc
	ret
emlbe:
	sec
	ret

emverib:			; Verify Binary Data
	lds	XH,emadr
	lds	XL,emadr+1
	ldi	YH,high(256)
	ldi	YL,low(256)
	lds	r19,emlen
	lds	r20,emlen+1
emvb0:
	rcall	ee1read
	brcs	emvbe
	mov	r9,r8
	push	YH
	push	YL
	mov	r10,XH
	mov	r11,XL
	rcall	read
	pop	YL
	pop	YH
	cp	r8,r9
	breq	emvb1
	mov	r14,XH
	mov	r15,XL
	rcall	adrb2w
	mov	r10,r14
	mov	r11,r15
	rcall	adrout
	rcall	crlf
emvb1:	
	adiw	YL,1
	adiw	XL,1
	sec
	sbc	r20,r0
	sbc	r19,r0
	mov	r16,r20
	or	r16,r19
	brne	emvb0
	clc
	ret
emvbe:
	sec
	ret

	;;
	;; (Q) Config sub-commands
	;;
config:
	adiw	XL,1
	ld	r16,X+
	rcall	upper
	tst	r16
	brne	cfg0
	rcall	cmdd
	rcall	add
	rcall	cadisp
	rjmp	wstart
cfg0:	
	cpi	r16,'A'
	brne	cfg1
	rjmp	cauto
cfg1:
	cpi	r16,'M'
	brne	cfg2
	rjmp	cmode
cfg2:
	cpi	r16,'S'
	brne	cfg3
	rjmp	cshare
cfg3:

cfge:
	rjmp	err

	;; (QA) Auto load
cauto:
	rcall	skipsp
	ld	r16,X+
	tst	r16
	breq	cau1
	ld	r17,X
	tst	r17
	breq	cau0
caue:	
	rjmp	err
cau0:
	cpi	r16,'0'
	brcs	caue
	cpi	r16,'2'+1
	brcc	caue
	subi	r16,'0'
	sts	amode,r16
cau1:
	rcall	cadisp
	rjmp	wstart

cadisp:
	ldi	ZH,high(aldmsg)
	ldi	ZL,low(aldmsg)
	rcall	msgout
	lds	r16,amode
	cpi	r16,2+1
	brcs	cad0
	clr	r16
cad0:	
	subi	r16,-'0'
	rcall	conout
	rjmp	crlf

	;; (QM) Memory mode
cmode:
	rcall	skipsp
	ld	r16,X
	tst	r16
	breq	cmd4
	clr	r18		; count
	ldi	YH,high(mmode)
	ldi	YL,low(mmode)
cmd0:	
	rcall	rdhex
	tst	r13
	breq	cmde
	rcall	skipsp

	st	Y+,r15
	inc	r18
	sts	mmnum,r18
	cpi	r18,8
	brcc	cmd1
	
	cpi	r16,','
	brne	cmd1
	adiw	XL,1
	rcall	skipsp
	rjmp	cmd0
cmd1:
	tst	r16
	brne	cmde

	rcall	chkmm
	brne	cmde
cmd4:
	rcall	cmdd
	rjmp	wstart

cmdd:
	ldi	ZH,high(mmdmsg)
	ldi	ZL,low(mmdmsg)
	rcall	msgout

	lds	r19,mmnum
	ldi	YH,high(mmode)
	ldi	YL,low(mmode)
cmd5:	
	ld	r16,Y+
	rcall	hexout2
	dec	r19
	breq	cmd6
	ldi	r16,','
	rcall	conout
	rjmp	cmd5
cmd6:	
	rjmp	crlf
cmde:
	rjmp	err

	;; (QS) Shared memory address
addr:
	adiw	XL,1
cshare:	
	rcall	skipsp
	ld	r16,X
	tst	r16
	breq	ad2

	rcall	rdarea
	brcc	ad0
	clr	r16		; default to area 0
ad0:	
	sts	shmar,r16
	rcall	getmm0
	rcall	rdadr0
	tst	r13
	breq	ade
	rcall	skipsp

	sts	shmadr,r14
	sts	shmadr+1,r15
	sts	shmoff,r0
	
	ld	r16,X+
	tst	r16
	breq	ad2

	cpi	r16,','
	brne	ade
	rcall	skipsp
	ld	r16,X+
	ld	r13,X
	tst	r13
	brne	ade
	cpi	r16,'1'
	breq	ad2
	cpi	r16,'2'
	brne	ad1
	ldi	r16,1
	sts	shmoff,r16
	rjmp	ad2
ad1:
	cpi	r16,'4'
	brne	ade
	ldi	r16,3
	sts	shmoff,r16
ad2:
	rcall	add
adr:	
	rjmp	wstart
ade:
	rjmp	err

add:	
	ldi	ZH,high(shmmsg0)
	ldi	ZL,low(shmmsg0)
	rcall	msgout
	lds	r16,shmar
	ori	r16,'0'
	rcall	conout
	ldi	r16,':'
	rcall	conout
	lds	r10,shmadr
	lds	r11,shmadr+1
	ldi	r16,0b11110011
	and	r11,r16
	lds	r16,shmar
	rcall	getmm0
	rcall	adrout0
	
	ldi	ZH,high(shmmsg1)
	ldi	ZL,low(shmmsg1)
	rcall	msgout

	lds	r16,shmoff
	andi	r16,0b00000011
	inc	r16
	ori	r16,'0'
	rcall	conout

	ldi	r16,')'
	rcall	conout

	rjmp	crlf

	
	;; Detect memories
mdetect:
	cli
	clr	r16
	sts	mavail,r16
	ldi	r17,4
	ldi	r18,0b00000001	; (1<<PB_CS0)
mdt0:
	in	r16,PORTB
	com	r16
	or	r16,r18
	com	r16
	out	PORTB,r16

	clr	r10
	clr	r11
	rcall	read0
	mov	r19,r8		; Save

	ldi	r20,0xAA
	mov	r8,r20
	rcall	write0		; Write 0xAA

	rcall	read0
	cp	r8,r20
	brne	mdt1

	ldi	r20,0x55
	mov	r8,r20
	rcall	write0		; Write 0x55

	rcall	read0
	cp	r8,r20
	brne	mdt1

	lds	r20,mavail
	or	r20,r18
	sts	mavail,r20
mdt1:
	mov	r8,r19
	rcall	write0		; Restore

	in	r16,PORTB
	ori	r16,0b00001111
	out	PORTB,r16
	
	lsl	r18
	dec	r17
	brne	mdt0

	sei
	ret

mddisp:
	lds	r16,mavail
	andi	r16,0b00001111
	cpi	r16,0b00001111
	brne	mddsp0
	ldi	ZH,high(md32msg)
	ldi	ZL,low(md32msg)
	rjmp	mddspr
mddsp0:	
	lds	r16,mavail
	andi	r16,0b00000011
	cpi	r16,0b00000011
	brne	mddsp1
	ldi	ZH,high(md16msg)
	ldi	ZL,low(md16msg)
	rjmp	mddspr
mddsp1:	
	lds	r16,mavail
	andi	r16,0b00000001
	cpi	r16,0b00000001
	brne	mddsp2
	ldi	ZH,high(md8msg)
	ldi	ZL,low(md8msg)
	rjmp	mddspr
mddspr:
	rjmp	msgout
mddsp2:
	ldi	r16,'['
	rcall	conout
	lds	r16,mavail
	rcall	hexout2
	ldi	r16,']'
	rjmp	conout

getmm:
	lds	r16,marea
getmm0:
	lds	r17,mmnum
	cp	r16,r17
	brcs	gmm0
	clr	r16
	sts	marea,r16	; Fix
gmm0:	
	ldi	ZH,high(mmode)
	ldi	ZL,low(mmode)
	add	ZL,r16
	adc	ZH,r0
	ld	r16,Z
	ret

	;; Check memory mode
chkmm:
	lds	r18,mmnum
	cpi	r18,1
	brcs	cmme
	cpi	r18,9
	brcc	cmme

	ldi	YH,high(mmode)
	ldi	YL,low(mmode)
cmm0:
	ld	r16,Y+
	cpi	r16,(mmtabe-mmtab)/2 ; 2 word per entry
	brcs	cmm1
cmme:	
	clz
	ret
cmm1:
	lsl	r16		; 2 word per entry
	ldi	ZH,high(mmtab)
	ldi	ZL,low(mmtab)
	add	ZL,r16
	adc	ZH,r0
	lsl	ZL
	rol	ZH
	lpm	r16,Z
	andi	r16,0x0f
	breq	cmme

	lds	r17,mavail
	and	r17,r16
	cp	r17,r16
	brne	cmme

	dec	r18
	brne	cmm0
	ret

mmtab:
	packing	on

	;; 00:
	data	0x01, 0xf0
	data	128, 16
mmtab1:
	;; 01:
	data	0x02, 0xf0
	data	128, 16
	;; 02:
	data	0x03, 0xf0
	data	128, 16
	;; 03:
	data	0x03, 0xf0
	data	128, 16
	;; 04
	data	0x03, 0xf8
	data	 64,  8
	;; 05:
	data	0x03, 0xf8
	data	 64,  8
	;; 06:
	data	0x13, 0xf8
	data	 64,  8
	;; 07:
	data	0x13, 0xf8
	data	 64,  8
	;; 08:
	data	0x03, 0xf0
	data	128, 16
	;; 09: (dummy)
	data	0x00, 0xf0
	data	128, 16
	;; 0A: (dummy)
	data	0x00, 0xf0
	data	128, 16
	;; 0B: (dummy)
	data	0x00, 0xf0
	data	128, 16
	;; 0C: (dummy)
	data	0x00, 0xf0
	data	128, 16
	;; 0D: (dummy)
	data	0x00, 0xf0
	data	128, 16
	;; 0E: (dummy)
	data	0x00, 0xf0
	data	128, 16
	;; 0F: (dummy)
	data	0x00, 0xf0
	data	128, 16

	;; 10:
	data	0x04, 0xf0
	data	128, 16
	;; 11:
	data	0x08, 0xf0
	data	128, 16
	;; 12:
	data	0x0c, 0xf0
	data	128, 16
	;; 13:
	data	0x0c, 0xf0
	data	128, 16
	;; 14
	data	0x0c, 0xf8
	data	 64,  8
	;; 15:
	data	0x0c, 0xf8
	data	 64,  8
	;; 16:
	data	0x1c, 0xf8
	data	 64,  8
	;; 17:
	data	0x1c, 0xf8
	data	 64,  8
	;; 18:
	data	0x0c, 0xf0
	data	128, 16
	;; 19: (dummy)
	data	0x00, 0xf0
	data	128, 16
	;; 1A: (dummy)
	data	0x00, 0xf0
	data	128, 16
	;; 1B: (dummy)
	data	0x00, 0xf0
	data	128, 16
	;; 1C: (dummy)
	data	0x00, 0xf0
	data	128, 16
	;; 1D: (dummy)
	data	0x00, 0xf0
	data	128, 16
	;; 1E: (dummy)
	data	0x00, 0xf0
	data	128, 16
	;; 1F: (dummy)
	data	0x00, 0xf0
	data	128, 16

	;; Dummy
	data	0x00, 0xf0
	data	128, 16

	packing	off
mmtabe:
	
;;;
;;;
;;;
	
msgout:
        lsl     ZL
        rol     ZH
mo0:
        lpm	r16,Z+
        tst     r16
        breq    mo1
        rcall   conout
        rjmp    mo0
mo1:
        ret

strout:
        ld      r16,Z+
        tst     r16
        breq    so0
        rcall   conout
        rjmp    strout
so0:
        ret

hexout2:
        mov     r18,r16
        swap    r16
        rcall   hexout1
        mov     r16,r18
hexout1:
        andi    r16,0b00001111
        ori     r16,'0'
        cpi     r16,'9'+1
        brcs    ho1
        ldi     r17,'A'-'9'-1
        add     r16,r17
ho1:
        rjmp    conout

octout4:
	push	r16
	lsr	r16
	rcall	octout1
	pop	r16
	push	r17
	lsl	r17
	rol	r16
	lsl	r17
	rol	r16
	rcall	octout1
	pop	r17
	mov	r16,r17
	lsr	r16
	lsr	r16
	lsr	r16
	rcall	octout1
	mov	r16,r17
octout1:
	andi	r16,0x07
	ori	r16,'0'
	rjmp	conout

hexin:
	clr	r8
	clr	r9
	rcall	hi0
	tst	r9
	breq	hir	; Non HEX character found
	swap	r8
hi0:
	rcall	conin
	rcall	upper
	cpi	r16,'0'
	brcs	hir
	cpi	r16,'9'+1
	brcs	hi1
	cpi	r16,'A'
	brcs	hir
	cpi	r16,'F'+1
	brcc	hir
	subi	r16,'A'-'9'-1
hi1:
	subi	r16,'0'
	or	r8,r16
	inc	r9
hir:
	ret

crlf:
        ldi     r16,CR
        rcall   conout
        ldi     r16,LF
        rcall   conout
	ret

	;; Get line
getlin:
        clr     r16
        sts     llen,r16
        ldi     XL,low(inbuf)
        ldi     XH,high(inbuf)
gl0:
        rcall   conin
        andi    r16,0b01111111

        cpi     r16,BS
        breq    gl1
        cpi     r16,DEL
        brne    gl2
gl1:
        lds     r16,llen
        tst     r16
        breq    gl0
        dec     r16
        sts     llen,r16
        ld      r16,-X
        ldi     r16,BS
        rcall   conout
        ldi     r16,' '
        rcall   conout
        ldi     r16,BS
        rcall   conout
        rjmp    gl0
gl2:
        cpi     r16,CR
        breq    gl3
        cpi     r16,LF
        brne    gl4
gl3:
        rcall   crlf
        rjmp    gl9
gl4:
        cpi     r16,' '
        brcs    gl0

	;; Insert char.
	lds	r17,llen
        cpi     r17,(BUFLEN-1)
        brcc    gl0
        inc     r17
        sts     llen,r17
        st      X+,r16
        rcall   conout
        rjmp    gl0
gl9:
        clr     r16
        st      X,r16           ; Terminate
        ret

skipsp:
	ld	r16,X+
	cpi	r16,' '
	breq	skipsp
	cpi	r16,0x09
	breq	skipsp
	sbiw	XL,1
	ret

upper:
	cpi	r16,'a'
	brcs	upr
	cpi	r16,'z'+1
	brcc	upr
	subi	r16,'a'-'A'
upr:
	ret

rdhex:
	clr	r12
	clr	r13
	clr	r14		; Value(H)
	clr	r15		; Value(L)
rh0:
	ld	r16,X
	rcall	upper
	cpi	r16,'0'
	brcs	rhe
	cpi	r16,'9'+1
	brcs	rh1
	cpi	r16,'A'
	brcs	rhe
	cpi	r16,'F'+1
	brcc	rhe
	subi	r16,'A'-'9'-1
rh1:
	subi	r16,'0'
	lsl	r15
	rol	r14
	lsl	r15
	rol	r14
	lsl	r15
	rol	r14
	lsl	r15
	rol	r14
	or	r15,r16	
	ld	r16,X+		; inc X
	inc	r13
	dec	r12
	brne	rh0
rhe:
	ret

rdoct:
	clr	r12
	clr	r13
	clr	r14		; Value(H)
	clr	r15		; Value(L)
ro0:
	ld	r16,X
	cpi	r16,'0'
	brcs	rhe
	cpi	r16,'7'+1
	brcc	rhe
	subi	r16,'0'
	lsl	r15
	rol	r14
	lsl	r15
	rol	r14
	lsl	r15
	rol	r14
	or	r15,r16	
	ld	r16,X+		; inc X
	inc	r13
	dec	r12
	brne	ro0
roe:
	ret

	;; Area output
areaout:
	lds	r16,mmnum
	cpi	r16,1
	breq	aro0
	lds	r16,marea
	ori	r16,'0'
	rcall	conout
	ldi	r16,':'
	rcall	conout
aro0:
	ret

	;; Address output
adrout:
	rcall	getmm
adrout0:
	cpi	r16,(aotabe-aotab)
	brcs	ao0
	clr	r16
ao0:	
	ldi	ZH,high(aotab)
	ldi	ZL,low(aotab)
	add	ZL,r16
	adc	ZH,r0
	lsl	ZL
	rol	ZH
	lpm	r16,Z+
	lpm	ZH,Z
	mov	ZL,r16
	ijmp

aotab:
	data	aoh4, aoh4, aoh4, aoh4
	data	aoh4, aoh4, aoo4, aoo4
	data	aoh4, aoh4, aoh4, aoh4
	data	aoh4, aoh4, aoh4, aoh4

	data	aoh4, aoh4, aoh4, aoh4
	data	aoh4, aoh4, aoo4, aoo4
	data	aoh4, aoh4, aoh4, aoh4
	data	aoh4, aoh4, aoh4, aoh4
aotabe:

aoh4:
	;; Address: HEX4
	mov	r16,r10
	rcall	hexout2
	mov	r16,r11
	rjmp	hexout2

aoo4:
	;; Address: OCT4
	mov	r16,r10
	mov	r17,r11
	rjmp	octout4

	;; Data output
datout:
	rcall	getmm
	cpi	r16,(dotabe-dotab)
	brcs	do0
	clr	r16
do0:	
	ldi	ZH,high(dotab)
	ldi	ZL,low(dotab)
	add	ZL,r16
	adc	ZH,r0
	lsl	ZL
	rol	ZH
	lpm	r16,Z+
	lpm	ZH,Z
	mov	ZL,r16
	ijmp

dotab:
	data	doh2, doh2, doh2, doh2
	data	doh4, doh4, doo4, doo4
	data	doh2, doh2, doh2, doh2
	data	doh2, doh2, doh2, doh2

	data	doh2, doh2, doh2, doh2
	data	doh4, doh4, doo4, doo4
	data	doh2, doh2, doh2, doh2
	data	doh2, doh2, doh2, doh2
dotabe:

doh2:
	;; Data: HEX2
	mov	r16,r8
	rjmp	hexout2
doh4:
	;; Data: HEX4
	mov	r16,r8
	rcall	hexout2
	mov	r16,r9
	rjmp	hexout2

doo4:
	;; Data: OCT4
	mov	r16,r8
	mov	r17,r9
	rjmp	octout4

	;; Read area
rdarea:
	ld	r16,X+
	ld	r17,X+
	cpi	r17,':'
	brne	rdare

	subi	r16,'0'
	brcs	rdare
	lds	r17,mmnum
	cp	r16,r17
	brcc	rdare
	clc
	ret
rdare:
	sbiw	XL,2
	sec			; error flag
	ret
	
	;; Read address from buffer
rdadr:
	lds	r16,marea
	rcall	rdarea
	sts	marea,r16
	rcall	getmm
rdadr0:
	cpi	r16,(rdatabe-rdatab)
	brcs	rda0
	ret
rda0:	
	ldi	ZH,high(rdatab)
	ldi	ZL,low(rdatab)
	add	ZL,r16
	adc	ZH,r0
	lsl	ZL
	rol	ZH
	lpm	r16,Z+
	lpm	ZH,Z
	mov	ZL,r16
	ijmp

rdatab:
	data	rda00, rda00, rda00, rda00
	data	rda00, rda00, rda06, rda06
	data	rda00, rda00, rda00, rda00
	data	rda00, rda00, rda00, rda00

	data	rda00, rda00, rda00, rda00
	data	rda00, rda00, rda06, rda06
	data	rda00, rda00, rda00, rda00
	data	rda00, rda00, rda00, rda00
rdatabe:

rda00:
	rcall	rdhex
	ret

rda06:
	rcall	rdoct
	ret

	;; Read data from buffer
rddat:
	rcall	getmm
	cpi	r16,(rddtabe-rddtab)
	brcs	rdd0
	ret
rdd0:	
	ldi	ZH,high(rddtab)
	ldi	ZL,low(rddtab)
	add	ZL,r16
	adc	ZH,r0
	lsl	ZL
	rol	ZH
	lpm	r16,Z+
	lpm	ZH,Z
	mov	ZL,r16
	ijmp

rddtab:
	data	rdd00, rdd00, rdd00, rdd00
	data	rdd04, rdd04, rdd06, rdd06
	data	rdd00, rdd00, rdd00, rdd00
	data	rdd00, rdd00, rdd00, rdd00

	data	rdd00, rdd00, rdd00, rdd00
	data	rdd04, rdd04, rdd06, rdd06
	data	rdd00, rdd00, rdd00, rdd00
	data	rdd00, rdd00, rdd00, rdd00
rddtabe:

rdd00:
	rcall	rdhex
	mov	r8,r15
	ret

rdd04:
	rcall	rdhex
	mov	r8,r14
	mov	r9,r15
	ret

rdd06:
	rcall	rdoct
	mov	r8,r14
	mov	r9,r15
	ret

	;; Convert WORD address to BYTE address
adrw2b:
	rcall	getmm
	cpi	r16,(awbtabe-awbtab)
	brcs	awb0
	ret
awb0:	
	ldi	ZH,high(awbtab)
	ldi	ZL,low(awbtab)
	add	ZL,r16
	adc	ZH,r0
	lsl	ZL
	rol	ZH
	lpm	r16,Z+
	lpm	ZH,Z
	mov	ZL,r16
	ijmp

awbtab:
	data	awb00, awb00, awb00, awb00
	data	awb04, awb04, awb04, awb04
	data	awb00, awb00, awb00, awb00
	data	awb00, awb00, awb00, awb00

	data	awb00, awb00, awb00, awb00
	data	awb04, awb04, awb04, awb04
	data	awb00, awb00, awb00, awb00
	data	awb00, awb00, awb00, awb00
awbtabe:

awb00:
	ret

awb04:
	lsl	r15
	rol	r14
	ret

	;; Convert BYTE address to WORD address
adrb2w:
	rcall	getmm
	cpi	r16,(abwtabe-abwtab)
	brcs	abw0
	ret
abw0:	
	ldi	ZH,high(abwtab)
	ldi	ZL,low(abwtab)
	add	ZL,r16
	adc	ZH,r0
	lsl	ZL
	rol	ZH
	lpm	r16,Z+
	lpm	ZH,Z
	mov	ZL,r16
	ijmp

abwtab:
	data	abw00, abw00, abw00, abw00
	data	abw04, abw04, abw04, abw04
	data	abw00, abw00, abw00, abw00
	data	abw00, abw00, abw00, abw00

	data	abw00, abw00, abw00, abw00
	data	abw04, abw04, abw04, abw04
	data	abw00, abw00, abw00, abw00
	data	abw00, abw00, abw00, abw00
abwtabe:

abw00:
	clc
	ret

abw04:
	lsr	r14
	ror	r15
	ret

	;;
	;; DPSRAM Access
	;;

read:
	if DEBUG
	lds	r16,mmode
	cpi	r16,0xFF
	brne	rd0
	mov	YH,r10
	mov	YL,r11
	ld	r8,Y
	ret
rd0:	
	endif
	
	cli

	push	r10
	push	r11

	rcall	atrans
	rcall	read0
	rcall	negcs

	pop	r11
	pop	r10
	
	sei
	ret

write:
	if DEBUG
	lds	r16,mmode
	cpi	r16,0xFF
	brne	wr0
	mov	YH,r10
	mov	YL,r11
	st	Y,r8
	ret
wr0:
	endif
	
	cli

	push	r10
	push	r11

	rcall	atrans
	rcall	write0
	rcall	negcs

	pop	r11
	pop	r10
	
	sei
	ret

	;; Read WORD from DPSRAM
readw:
	rcall	getmm
	cpi	r16,(rdtabe-rdtab)
	brcs	rdw0
	ldi	r16,0xFF
	mov	r8,r16
	mov	r9,r16
	ret
rdw0:
	ldi	ZH,high(rdtab)
	ldi	ZL,low(rdtab)
	add	ZL,r16
	adc	ZH,r0
	lsl	ZL
	rol	ZH
	lpm	r16,Z+
	lpm	ZH,Z
	mov	ZL,r16

	cli
	icall
	sei
	ret
	
rdtab:
	data	rdw00, rdw01, rdw02, rdw03
	data	rdw04, rdw04, rdw04, rdw04
	data	rdw08, rdw00, rdw00, rdw00
	data	rdw00, rdw00, rdw00, rdw00

	data	rdw10, rdw11, rdw12, rdw13
	data	rdw14, rdw14, rdw14, rdw14
	data	rdw18, rdw00, rdw00, rdw00
	data	rdw00, rdw00, rdw00, rdw00	
rdtabe:

rdw00:
	;; MMode: 00
	cbi	PORTB,PB_CS0	; CS0=0
	rcall	read0
	rjmp	negcs
	
rdw01:
	;; MMode: 01
	cbi	PORTB,PB_CS1	; CS1=0
	rcall	read0
	rjmp	negcs

rdw02:
	;; MMode: 02
	push	r10
	push	r11
	rcall	at02
	rcall	read0
	pop	r11
	pop	r10
	rjmp	negcs
	
rdw03:
	;; MMode: 03
	push	r10
	push	r11
	rcall	at03
	rcall	read0
	pop	r11
	pop	r10
	rjmp	negcs

rdw04:
	;; MMode: 04-07
	cbi	PORTB,PB_CS0	; CS0=0
	rcall	read0
	rcall	negcs
	mov	r9,r8
	cbi	PORTB,PB_CS1	; CS1=0
	rcall	read0
	rjmp	negcs

rdw08:
	;; MMode: 08
	rcall	at08
	rcall	read0
	rjmp	negcs

rdw10:
	;; MMode: 10
	cbi	PORTB,PB_CS2	; CS2=0
	rcall	read0
	rjmp	negcs
	
rdw11:
	;; MMode: 11
	cbi	PORTB,PB_CS3	; CS3=0
	rcall	read0
	rjmp	negcs
	
rdw12:
	;; MMode: 12
	push	r10
	push	r11
	rcall	at12
	rcall	read0
	pop	r11
	pop	r10
	rjmp	negcs
	
rdw13:
	;; MMode: 13
	push	r10
	push	r11
	rcall	at13
	rcall	read0
	pop	r11
	pop	r10
	rjmp	negcs

rdw14:
	;; MMode: 14-17
	cbi	PORTB,PB_CS2	; CS2=0
	rcall	read0
	rcall	negcs
	mov	r9,r8
	cbi	PORTB,PB_CS3	; CS3=0
	rcall	read0
	rjmp	negcs

rdw18:
	;; MMode: 18
	rcall	at18
	rcall	read0
	rjmp	negcs

	;; Write WORD to DPSRAM
writew:
	rcall	getmm
	cpi	r16,(wrtabe-wrtab)
	brcs	wrw0
	ret
wrw0:
	ldi	ZH,high(wrtab)
	ldi	ZL,low(wrtab)
	add	ZL,r16
	adc	ZH,r0
	lsl	ZL
	rol	ZH
	lpm	r16,Z+
	lpm	ZH,Z
	mov	ZL,r16

	cli
	icall
	sei
	ret

wrtab:
	data	wrw00, wrw01, wrw02, wrw03
	data	wrw04, wrw04, wrw04, wrw04
	data	wrw08, wrw00, wrw00, wrw00
	data	wrw00, wrw00, wrw00, wrw00

	data	wrw10, wrw11, wrw12, wrw13
	data	wrw14, wrw14, wrw14, wrw14
	data	wrw18, wrw00, wrw00, wrw00
	data	wrw00, wrw00, wrw00, wrw00
wrtabe:

wrw00:
	;; MMode: 00
	cbi	PORTB,PB_CS0	; CS0=0
	rcall	write0
	rjmp	negcs
	
wrw01:
	;; MMode: 01
	cbi	PORTB,PB_CS1	; CS1=0
	rcall	write0
	rjmp	negcs

wrw02:
	;; MMode: 02
	push	r10
	push	r11
	rcall	at02
	rcall	write0
	pop	r11
	pop	r10
	rjmp	negcs
	
wrw03:
	;; MMode: 03
	push	r10
	push	r11
	rcall	at03
	rcall	write0
	pop	r11
	pop	r10
	rjmp	negcs

wrw04:
	;; MMode: 04-07
	cbi	PORTB,PB_CS1	; CS1=0
	rcall	write0
	rcall	negcs
	mov	r8,r9
	cbi	PORTB,PB_CS0	; CS0=0
	rcall	write0
	rjmp	negcs

wrw08:
	;; MMode: 08
	rcall	at08
	rcall	write0
	rjmp	negcs

wrw10:
	;; MMode: 10
	cbi	PORTB,PB_CS2	; CS2=0
	rcall	write0
	rjmp	negcs
	
wrw11:
	;; MMode: 11
	cbi	PORTB,PB_CS3	; CS3=0
	rcall	write0
	rjmp	negcs
	
wrw12:
	;; MMode: 12
	push	r10
	push	r11
	rcall	at12
	rcall	write0
	pop	r11
	pop	r10
	rjmp	negcs
	
wrw13:
	;; MMode: 13
	push	r10
	push	r11
	rcall	at13
	rcall	write0
	pop	r11
	pop	r10
	rjmp	negcs

wrw14:
	;; MMode: 14-17
	cbi	PORTB,PB_CS3	; CS3=0
	rcall	write0
	rcall	negcs
	mov	r8,r9
	cbi	PORTB,PB_CS2	; CS2=0
	rcall	write0
	rjmp	negcs

wrw18:
	;; MMode: 18
	rcall	at18
	rcall	write0
	rjmp	negcs

	;; Address translation and assert appropriate CSn line (for BYTE access)
atrans:
	rcall	getmm
	cpi	r16,(attabe-attab)
	brcs	atr0
	ret
atr0:	
	ldi	ZH,high(attab)
	ldi	ZL,low(attab)
	add	ZL,r16
	adc	ZH,r0
	lsl	ZL
	rol	ZH
	lpm	r16,Z+
	lpm	ZH,Z
	mov	ZL,r16
	ijmp

attab:	
	data	at00, at01, at02, at03
	data	at02, at03, at02, at03
	data	at08, at00, at00, at00
	data	at00, at00, at00, at00

	data	at10, at11, at12, at13
	data	at12, at13, at12, at13
	data	at18, at00, at00, at00
	data	at00, at00, at00, at00
attabe:

at00:
	;; MMode: 00 (8)
	cbi	PORTB,PB_CS0	; CS0=0
	ret

at01:	
	;; MMode: 01 (+8)
	cbi	PORTB,PB_CS1	; CS1=0
	ret

at02:
	;; MMode: 02 (16bit little endian)
	mov	r16,r11
	andi	r16,0b00000001
	brne	at020
	cbi	PORTB,PB_CS0	; CS0=0
	rjmp	at021
at020:
	cbi	PORTB,PB_CS1	; CS1=0
at021:
	clc
	ror	r10		; Addr H
	ror	r11		; Addr L
	ret

at03:
	;; MMode: 03 (16bit big endian)
	mov	r16,r11
	andi	r16,0b00000001
	brne	at030
	cbi	PORTB,PB_CS1	; CS1=0
	rjmp	at031
at030:
	cbi	PORTB,PB_CS0	; CS0=0
at031:
	clc
	ror	r10		; Addr H
	ror	r11		; Addr L
	ret

at08:	
	;; MMode: 08
	mov	r16,r10		; Addr H
	andi	r16,0b00010000
	brne	at080
	cbi	PORTB,PB_CS0	; CS0=0
	rjmp	at081
at080:
	cbi	PORTB,PB_CS1	; CS1=0
at081:
	ret

at10:
	;; MMode: 10 (+16)
	cbi	PORTB,PB_CS2	; CS2=0
	ret

at11:
	;; MMode: 11 (+16)
	cbi	PORTB,PB_CS3	; CS3=0
	ret

at12:
	;; MMode: 12 (16bit little endian)
	mov	r16,r11
	andi	r16,0b00000001
	brne	at120
	cbi	PORTB,PB_CS2	; CS2=0
	rjmp	at121
at120:
	cbi	PORTB,PB_CS3	; CS3=0
at121:
	clc
	ror	r10		; Addr H
	ror	r11		; Addr L
	ret

at13:
	;; MMode: 13 (16bit big endian)
	mov	r16,r11
	andi	r16,0b00000001
	brne	at130
	cbi	PORTB,PB_CS3	; CS3=0
	rjmp	at131
at130:
	cbi	PORTB,PB_CS2	; CS2=0
at131:
	clc
	ror	r10		; Addr H
	ror	r11		; Addr L
	ret

at18:	
	;; MMode: 18
	mov	r16,r10		; Addr H
	andi	r16,0b00010000
	brne	at180
	cbi	PORTB,PB_CS2	; CS2=0
	ret
at180:
	cbi	PORTB,PB_CS3	; CS3=0
	ret

	;; Negate CSn line
negcs:
	in	r16,PORTB
	ori	r16,0b00001111
	out	PORTB,r16	; CS0,CS1,CS2,CS3=1
	ret

	;; Read BYTE from DPSRAM (CSn must be asserted before)
read0:
	push	r10

	ldi	r16,0b00001111
	and	r10,r16
	
	ldi	r16,0b11111111
	out	DDRA,r16

	out	PORTA,r10	; Addr H
	cbi	PORTD,PD_ALEH	; ALEH=0
	sbi	PORTD,PD_ALEH	; ALEH=1

	out	PORTA,r11	; Addr L
	cbi	PORTD,PD_ALEL	; ALEL=0
	sbi	PORTD,PD_ALEL	; ALEL=1

	ldi	r16,0b11111111
	out	PORTA,r16
	clr	r16
	out	DDRA,r16

	cbi	PORTD,PD_RD	; RD=0
	nop
	nop
	in	r8,PINA
	sbi	PORTD,PD_RD	; RD=1

	pop	r10
	ret

	;; Write BYTE to DPSRAM (CSn must be asserted before)	
write0:
	push	r10
	ldi	r16,0b00001111
	and	r10,r16
	
	ldi	r16,0b11111111
	out	DDRA,r16

	out	PORTA,r10	; Addr H
	cbi	PORTD,PD_ALEH	; ALEH=0
	sbi	PORTD,PD_ALEH	; ALEH=1

	out	PORTA,r11	; Addr L
	cbi	PORTD,PD_ALEL	; ALEL=0
	sbi	PORTD,PD_ALEL	; ALEL=1

	out	PORTA,r8

	cbi	PORTD,PD_WR	; WR=0
	nop
	nop
	sbi	PORTD,PD_WR	; WR=1

	nop
	ldi	r16,0b11111111
	out	PORTA,r16
	clr	r16
	out	DDRA,r16

	pop	r10
	ret


	;;
	;; EEPROM routines
	;;
	;;	Addr: (YH:YL)
	;;	Data: (r8)
	;;

	;; Read BYTE from EEPROM
eeread:
	lds	r16,eenum
	tst	r16
	brne	eer0
	rjmp	ee0read
eer0:
	rjmp	ee1read

	;; Write BYTE to EEPROM
eewrite:
	lds	r16,eenum
	tst	r16
	brne	eew0
	rjmp	ee0write
eew0:
	rjmp	ee1write
	
	;; Read BYTE from internal EEPROM
ee0read:
	cli
ee0r0:	
	sbic	EECR,EEPE
	rjmp	ee0r0
	out	EEARH,YH
	out	EEARL,YL
	sbi	EECR,EERE
	in	r8,EEDR
	clc

	sei
	ret

	;; Write BYTE to internal EEPROM
ee0write:
	cli
ee0w0:	
	sbic	EECR,EEPE
	rjmp	ee0w0
	out	EEARH,YH
	out	EEARL,YL
	out	EEDR,r8
	sbi	EECR,EEMPE
	sbi	EECR,EEPE
	clc

	sei
	ret

	;; Read BYTE from target EEPROM
ee1read:
	ldi	r16,0b10100000	; 0xA0_W
	rcall	twist		; START
	brcs	ee1re
	mov	r16,YH
	rcall	twitr		; Addr H
	brcs	ee1re
	mov	r16,YL
	rcall	twitr		; Addr L
	brcs	ee1re

	ldi	r16,0b10100001	; 0xA0_R
	rcall	twist		; START
	brcs	ee1re
	rcall	twirc		; Data
	brcs	ee1re
	mov	r8,r16
	rcall	twisp		; STOP

	clc
	ret
ee1re:	
	sec
	ret

	;; Write BYTE to target EEPROM
ee1write:
	ldi	r16,0b10100000	; 0xA0_W
	rcall	twist		; START
	brcs	ee1we
	mov	r16,YH
	rcall	twitr		; Addr H
	brcs	ee1we
	mov	r16,YL
	rcall	twitr		; Addr L
	brcs	ee1we
	mov	r16,r8
	rcall	twitr		; Data
	brcs	ee1we
	rcall	twisp		; STOP

	clc
	ret
ee1we:	
	sec
	ret

	;; I2C: Transmit START & SLA
twist:
	ldi	r18,200
	sts	retry,r18
tws00:
	ldi	r18,TWI_TO
	sts	timer2,r18
	
	ldi	r18,(1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
	sts	TWCR,r18
tws0:
	lds	r18,timer2
	tst	r18
	breq	twse		; timeout

	lds	r18,TWCR
	sbrs	r18,TWINT
	rjmp	tws0

	lds	r18,TWSR
	andi	r18,0xF8
	cpi	r18,0x08
	breq	tws1
	cpi	r18,0x10
	breq	tws1
	rjmp	twse
tws1:
	ldi	r18,TWI_TO
	sts	timer2,r18
	
	sts	TWDR,r16	; SLA_W / SLA_R
	ldi	r18,(1<<TWINT)|(1<<TWEN)
	sts	TWCR,r18
tws2:
	lds	r18,timer2
	tst	r18
	breq	twse		; timeout
	
	lds	r18,TWCR
	sbrs	r18,TWINT
	rjmp	tws2

	lds	r18,TWSR
	andi	r18,0xF8
	cpi	r18,0x18	; SLA_W
	breq	twsf
	cpi	r18,0x40	; SLA_R
	breq	twsf
	cpi	r18,0x20	; SLA_W Not_ACK
	breq	twsrt
	cpi	r18,0x48	; SLA_R Not_ACK
	breq	twsrt
twse:
	sec
	ret
twsrt:
	rcall	twisp
	lds	r18,retry
	dec	r18
	breq	twse
	sts	retry,r18
	rjmp	tws00
twsf:	
	clc
	ret
	
	;; I2C: Transmit DATA
twitr:
	ldi	r18,TWI_TO
	sts	timer2,r18
	
	sts	TWDR,r16	; DATA
	ldi	r18,(1<<TWINT)|(1<<TWEN)
	sts	TWCR,r18
twt0:
	lds	r18,timer2
	tst	r18
	breq	twte		; timeout
	
	lds	r18,TWCR
	sbrs	r18,TWINT
	rjmp	twt0

	lds	r18,TWSR
	andi	r18,0xF8
	cpi	r18,0x28
	brne	twte

	clc
	ret
twte:
	sec
	ret

	;; I2C: Receive DATA with ACK
twirca:
	ldi	r18,TWI_TO
	sts	timer2,r18
	
	ldi	r18,(1<<TWINT)|(1<<TWEN)|(1<<TWEA)
	sts	TWCR,r18
	rjmp	twr0
	
	;; I2C: Receive DATA
twirc:
	ldi	r18,TWI_TO
	sts	timer2,r18
	
	ldi	r18,(1<<TWINT)|(1<<TWEN)
	sts	TWCR,r18
twr0:
	lds	r18,timer2
	tst	r18
	breq	twre		; timeout
	
	lds	r18,TWCR
	sbrs	r18,TWINT
	rjmp	twr0

	lds	r18,TWSR
	andi	r18,0xF8
	cpi	r18,0x50
	breq	twrr
	cpi	r18,0x58
	breq	twrr

twre:	
	sec
	ret
twrr:
	lds	r16,TWDR

	clc
	ret

	;; I2C: Transmit STOP
twisp:
	ldi	r18,(1<<TWINT)|(1<<TWEN)|(1<<TWSTO)
	sts	TWCR,r18
twp0:
	lds	r18,TWCR
	sbrc	r18,TWSTO
	rjmp	twp0
	;; rcall	hexout2
	;; rcall	crlf
	
	clc
	ret

	;;
	;; Interrupt handler (T0)
	;;
t0_int:
	in	r7,SREG

	;; Timer
	lds	r6,timer
	tst	r6
	breq	t0_it0

	dec	r6
	sts	timer,r6
t0_it0:	

	;; Timer 2
	lds	r6,timer2
	tst	r6
	breq	t0_it1

	dec	r6
	sts	timer2,r6
t0_it1:	

	lds	r22,shmadr
	lds	r23,shmadr+1
	andi	r23,0b11110011	; [+0] Signature
	rcall	iread
	cpi	r21,EG_SIG
	breq	t0_i00
t0_i0r
	rjmp	t0_ir
t0_i00:	
	rcall	iainc		; [+1] Handshake
	rcall	iread
	cpi	r21,EH_REQ
	brne	t0_i0r

	rcall	iainc		; [+2] Command
	rcall	iread
	cpi	r21,EC_INI
	brne	t0_i1

	;; 00 Init (dummy)
	clr	r21
	lds	r21,UDR1	; Dummy read 
	lds	r21,UDR1	; Dummy read 
	lds	r21,UDR1	; Dummy read 
	lds	r21,UDR1	; Dummy read 
	rjmp	t0_if

t0_i1:
	cpi	r21,EC_COT
	brne	t0_i2

	;; 01 Console Output
	lds	r21,UCSR1A
	andi	r21,0b00100000
	breq	t0_ir		; Busy => do nothing

	rcall	iainc
	rcall	iainc
	rcall	iread
	sts	UDR1,r21
	clr	r21		; Status = 0
	rjmp	t0_if
	
t0_i2:
	cpi	r21,EC_CIN
	brne	t0_i3

	;; 02 Console Input
	lds	r21,UCSR1A
	andi	r21,0b10000000
	breq	t0_ir

	lds	r21,UDR1
	rcall	iainc
	rcall	iainc
	rcall	iwrite
	clr	r21
	rjmp	t0_if
	
t0_i3:
	cpi	r21,EC_CST
	brne	t0_i4

	;; 03 Console Status
	lds	r21,UCSR1A
	andi	r21,0b10000000
	rol	r21
	rol	r21
	
	rcall	iainc
	rcall	iainc
	rcall	iwrite
	clr	r21
	rjmp	t0_if
	
t0_i4:

	ldi	r21,ES_UK	; Error	

t0_if:
	lds	r22,shmadr
	lds	r23,shmadr+1
	andi	r23,0b11110011
	rcall	iainc
	rcall	iainc
	rcall	iainc		; [+3] Status
	rcall	iwrite

	rcall	iadec
	rcall	iadec		; [+1]
	ldi	r21,EH_ACK
	rcall	iwrite

t0_ir:
	out	SREG,r7
	reti

iread:
	push	r8
	push	r10
	push	r11
	push	r16
	push	ZH
	push	ZL

	mov	r10,r22
	mov	r11,r23
	rcall	itrans
	rcall	read0
	rcall	negcs
	mov	r21,r8

	pop	ZL
	pop	ZH
	pop	r16
	pop	r11
	pop	r10
	pop	r8

	ret

iwrite:
	push	r8
	push	r10
	push	r11
	push	r16
	push	ZH
	push	ZL
	
	mov	r10,r22
	mov	r11,r23
	mov	r8,r21
	rcall	itrans
	rcall	write0
	rcall	negcs

	pop	ZL
	pop	ZH
	pop	r16
	pop	r11
	pop	r10
	pop	r8

	ret

	;; Address translation for interrupt
itrans:
	lds	r16,shmar
	lds	ZL,mmnum
	cp	r16,ZL
	brcs	itr0
	clr	r16
itr0:	
	ldi	ZH,high(mmode)
	ldi	ZL,low(mmode)
	add	ZL,r16
	adc	ZH,r0
	ld	r16,Z
	cpi	r16,(ittabe-ittab)
	brcs	itr1
	ret
itr1:	
	ldi	ZH,high(ittab)
	ldi	ZL,low(ittab)
	add	ZL,r16
	adc	ZH,r0
	lsl	ZL
	rol	ZH
	lpm	r16,Z+
	lpm	ZH,Z
	mov	ZL,r16
	ijmp

ittab:	
	data	it00, it01, it02, it03
	data	it00, it00, it00, it00
	data	it08, it00, it00, it00
	data	it00, it00, it00, it00

	data	it10, it11, it12, it13
	data	it10, it10, it10, it10
	data	it18, it00, it00, it00
	data	it00, it00, it00, it00
ittabe:

it00:
	;; MMode: 00
	cbi	PORTB,PB_CS0	; CS0=0
	ret

it01:	
	;; MMode: 01
	cbi	PORTB,PB_CS1	; CS1=0
	ret

it02:
	;; MMode: 02 (16bit little endian)
	lsr	r10		; Addr H
	ror	r11		; Addr L
	brcs	it020
	cbi	PORTB,PB_CS0	; CS0=0
	ret
it020:
	cbi	PORTB,PB_CS1	; CS1=0
	ret

it03:
	;; MMode: 03 (16bit big endian)
	lsr	r10		; Addr H
	ror	r11		; Addr L
	brcs	it030
	cbi	PORTB,PB_CS1	; CS1=0
	ret
it030:
	cbi	PORTB,PB_CS0	; CS0=0
	ret

it08:	
	;; MMode: 08
	mov	r16,r10		; Addr H
	andi	r16,0b00010000
	brne	it080
	cbi	PORTB,PB_CS0	; CS0=0
	ret
it080:
	cbi	PORTB,PB_CS1	; CS1=0
	ret

it10:
	;; MMode: 10
	cbi	PORTB,PB_CS2	; CS2=0
	ret

it11:
	;; MMode: 11
	cbi	PORTB,PB_CS3	; CS3=0
	ret

it12:
	;; MMode: 12 (16bit little endian)
	lsr	r10		; Addr H
	ror	r11		; Addr L
	brcs	it120
	cbi	PORTB,PB_CS2	; CS2=0
	ret
it120:
	cbi	PORTB,PB_CS3	; CS3=0
	ret

it13:
	;; MMode: 13 (16bit big endian)
	lsr	r10		; Addr H
	ror	r11		; Addr L
	brcs	it130
	cbi	PORTB,PB_CS3	; CS3=0
	ret
it130:
	cbi	PORTB,PB_CS2	; CS2=0
	ret

it18:	
	;; MMode: 18
	mov	r16,r10		; Addr H
	andi	r16,0b00010000
	brne	it180
	cbi	PORTB,PB_CS2	; CS2=0
	ret
it180:
	cbi	PORTB,PB_CS3	; CS3=0
	ret

	
iainc:
	lds	r25,shmoff
	andi	r25,0b00000011
	sec
	adc	r23,r25
	adc	r22,r0
	
	ret
	
iadec:
	lds	r25,shmoff
	andi	r25,0b00000011
	sec
	sbc	r23,r25
	sbc	r22,r0

	ret

	;;
	;; String
	;;
	packing	on
opnmsg:
        data	CR,LF,"####  EMILY Board ",0
md0msg:
	data	0
md8msg:
	data	"8bit",0
md16msg:
	data	"16bit (with +8)",0
md32msg:
	data	"32bit (with +8 and +16)",0
opnmsg2:
	data	"  ####",CR,LF,0
ihemsg:
        data	"Error ihex",CR,LF,0
shemsg:
        data	"Error srec",CR,LF,0
errmsg:
        data	"Error",CR,LF,0
namsg:
        data	"N/A",CR,LF,0
dsep0:
        data	" :",0
dsep1:
        data	" : ",0
ihexer:
        data	":00000001FF",CR,LF,0
srecer:
        data	"S9030000FC",CR,LF,0
shmmsg0:
        data	"SHM Address: ",0
shmmsg1:
        data	"- (+",0
mmdmsg:
	data	"Memory Mode: ",0
ldrmsg:
	data	"Loaded: ",0
aldmsg:
	data	"Auto Load:   ",0
marmsg:
	data	"Memory Area: ",0
	packing	off

	if USE_DEV_MEGA164
	include	"dev/mega164.asm"
	endif

	;;
	;; Work Area
	;;
	
	segment	data

	org	WORK_B
	
inbuf:	res	BUFLEN		; Line input buffer
dsadrh: res	1       	; DUMP start address (H)
dsadrl: res	1		; DUMP start address (L)
deadrh: res	1       	; DUMP end address (H)
deadrl: res	1       	; DUMP end address (L)
dstate: res	1
saddrh: res	1       	; SET address (H)
saddrl: res	1		; SET address (L)
llen:	res	1
lsaddr:	res	2		; LOAD start address
leaddr:	res	2		; LOAD end address
fmaddr:	res	2		; FILL/MOVE start address
fmlen:	res	2		; FILL/MOVE length

eenum:	res	1		; EEPROM number 0:mega164,1:target
mavail:	res	1		; Available memory

mflag:	res	1		; MMode flag  bit4: Skip ASCII dump , bit3-0: Mem required
dmsk:	res	1		; DUMP mask (0xf0 for 8bit, 0xf8 for 12/16bit)
dlen:	res	1		; DUMP length (128 for 8bit, 64 for 12/16bit)
dnum:	res	1		; DUMP number per line (16 for 8bit, 8 for 12/16bit)

marea:	res	1		; Area code
marea0:	res	1		;   for M command source address
marea1:	res	1		;   for M command destination address

timer:	res	1		; Timer
timer2:	res	1		; Timer 2 (used for TWI timeout)
retry:	res	1		; Retry counter

	;; EEPROM Buffer for settings
epbuf:
eesig0:	res	4		; Signature FF:AA:55:50

hexmod:	res	1		; HEX file mode

shmar:	res	1		; Shared Memory Area
shmadr:	res	2		; Shared Memory Address
shmoff:	res	1		; Shared Memory Offset

mmnum:	res	1		; Number of memory mode
mmode:	res	8		; Memory mode

amode:	res	1		; Auto load mode

eppad:	res	(epbuf+32-eppad) ; Padding
epend:	

eptmp:	res	32

	;; EEPROM Buffer for program meta data ("ES","EL" command)
embuf:
emsig0:	res	4		; Signature FF:AA:55:53

emadr:	res	2		; Address
emlen:	res	2		; Length

empad:	res	(embuf+16-empad) ; Padding
emend:

emtmp:	res	16

	end
