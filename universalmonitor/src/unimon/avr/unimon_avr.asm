;;;
;;;	Universal Monitor for Atmel AVR
;;;
	
	;; cpu	atmega1284	; See "config.inc"
	
	include	"config.inc"

;;; AVR local definitions
XL	reg	r26
XH	reg	r27
YL	reg	r28
YH	reg	r29
ZL	reg	r30
ZH	reg	r31

	include	"../common.inc"

;;;
;;; ROM area
;;;
	
	segment	code

	org	0x0000
	rjmp	cstart

	;; org	0x000E
	;; rjmp	pci3_int
	
	;; org	0x0020
	;; rjmp	t0_int

	org	0x0100

cstart:
	cli
	;; Initialize Stack Pointer
	ldi	r16,low(STACK)
	out	SPL,r16
	ldi	r16,high(STACK)
	out	SPH,r16

	rcall	init
	
        ;; Initialize work area
        clr     r1
        sts     saddrh,r1
        sts     saddrl,r1
        sts     dsadrh,r1
        sts     dsadrl,r1

        ldi     r16,'I'
        sts     hexmod,r16

	;; Opening message
        ldi     ZL,low(opnmsg)
        ldi     ZH,high(opnmsg)
        rcall   msgout

wstart:
        ldi     ZL,low(prompt)
        ldi     ZH,high(prompt)
        rcall   msgout
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
	
err:
	ldi	ZL,low(errmsg)
	ldi	ZH,high(errmsg)
	rcall	msgout
	rjmp	wstart

dump:
	adiw	XL,1
	rcall	skipsp
	rcall	rdhex0
	tst	r13
	brne	dp0
	; No arg.
	rcall	skipsp
	tst	r16
	brne	dpe
	lds	r10,dsadrh
	lds	r11,dsadrl
	ldi	r16,128
	add	r11,r16
	adc	r10,r1
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
	ldi	r16,128
	add	r15,r16
	adc	r14,r1
	sts	deadrh,r14
	sts	deadrl,r15
	rjmp	dpm
dp1:
	adiw	XL,1
	rcall	skipsp
	rcall	rdhex0
	rcall	skipsp
	tst	r13
	breq	dpe
	tst	r16
	brne	dpe
	sec
	adc	r15,r1
	adc	r14,r1
	sts	deadrh,r14
	sts	deadrl,r15
dpm:
	lds	r10,dsadrh
	lds	r11,dsadrl
	ldi	r16,0xf0
	and	r11,r16
	sts	dstate,r1
dpm0:
	rcall	dpl
	rcall	const
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
	rcall	conin
	rjmp	wstart

dpl:
	mov	r16,r10
	rcall	hexout2
	mov	r16,r11
	rcall	hexout2
	ldi	ZH,high(dsep0)
	ldi	ZL,low(dsep0)
	rcall	msgout
	ldi	ZH,high(inbuf)
	ldi	ZL,low(inbuf)
	ldi	r19,16
dpl0:
	rcall	dpb
	dec	r19
	brne	dpl0

	ldi	ZH,high(dsep1)
	ldi	ZL,low(dsep1)
	rcall	msgout

	ldi	ZH,high(inbuf)
	ldi	ZL,low(inbuf)
	ldi	r19,16
dpl1:
	ld	r16,Z+
	cpi	r16,' '
	brcs	dpl2
	cpi	r16,0x7f
	brcc	dpl2
	rcall	conout
	rjmp	dpl3
dpl2:
	ldi	r16,'.'
	rcall	conout
dpl3:
	dec	r19
	brne	dpl1
	rjmp	crlf

dpb:
	ldi	r16,' '
	rcall	conout
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
	ldi	r16,' '
	rcall	conout
	rcall	conout
	st	Z+,r16
	sec
	adc	r11,r1
	adc	r10,r1
	ret
dpb1:
	ldi	r16,1
	sts	dstate,r16
dpb2:
	lds	r16,dstate
	cpi	r16,1
	brne	dpb0
	;; rcall	open
	rcall	read
	;; rcall	close
	st	Z+,r8
	mov	r16,r8
	rcall	hexout2
	sec
	adc	r11,r1
	adc	r10,r1
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

setm:
	adiw	XL,1
	rcall	skipsp
	rcall	rdhex0
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
	mov	r16,r10
	rcall	hexout2
	mov	r16,r11
	rcall	hexout2
	ldi	ZL,low(dsep1)
	ldi	ZH,high(dsep1)
	rcall	msgout
	;; rcall	open
	rcall	read
	;; rcall	close
	mov	r16,r8
	rcall	hexout2
	ldi	r16,' '
	rcall	conout
	rcall	getlin
	ldi	XL,low(inbuf)
	ldi	XH,high(inbuf)
	rcall	skipsp
	tst	r16
	brne	stm2
	; Empty
	sec
	adc	r11,r1
	adc	r10,r1
	sts	saddrh,r10
	sts	saddrl,r11
	rjmp	stm1
stm2:
	cpi	r16,'-'
	brne	sm3
	sec
	sbc	r11,r1
	sbc	r10,r1
	sts	saddrh,r10
	sts	saddrl,r11
	rjmp	stm1
sm3:
	cpi	r16,'.'
	brne	sm4
	rjmp	wstart
sm4:
	rcall	rdhex0
	tst	r13
	breq	sete
	mov	r8,r15
	;; rcall	open
	rcall	write
	;; rcall	close
	sec
	adc	r11,r1
	adc	r10,r1
	sts	saddrh,r10
	sts	saddrl,r11
	rjmp	stm1
sete:
	rjmp	err

loadh:
	adiw	XL,1
	rcall	skipsp
	rcall	rdhex0
	rcall	skipsp
	tst	r16
	brne	sete
	tst	r13
	brne	lh0

	clr	r14
	clr	r15
lh0:
	rcall	conin
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
	brne	lhie	; Checksum error
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
	rcall	write
	sec
	adc	r11,r1
	adc	r10,r1
	dec	r20
	brne	lhi5
	;; rcall	close
	ldi	r16,'I'
	sts	hexmod,r16
	rjmp	lh0
lhir:
	rjmp	wstart

lhs1:
	rcall	conin
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
	rcall	write
	sec
	adc	r11,r1
	adc	r10,r1
	dec	r20
	brne	lhs8
	;; rcall	close
	ldi	r16,'S'
	sts	hexmod,r16
	rjmp	lh0
lhsr:
	rjmp	wstart

	
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
	rcall	rdhex0		; Start address
	tst	r13
	breq	she
	mov	r10,r14
	mov	r11,r15
	rcall	skipsp
	cpi	r16,','
	brne	she
	adiw	XL,1
	rcall	skipsp
	rcall	rdhex0		; End address
	tst	r13
	breq	she
	rcall	skipsp
	tst	r16
	breq	sh2
she:
	rjmp	err
sh2:
	sub	r15,r11
	sbc	r14,r10
	sec
	adc	r15,r1
	adc	r14,r1
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
	rcall	conout
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
	sbc	r14,r1
	;; rcall	open
shli0:
	rcall	read
	mov	r16,r8
	sub	r20,r8
	rcall	hexout2
	sec
	adc	r11,r1
	adc	r10,r1
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
	rcall	conout
	ldi	r16,'1'
	rcall	conout
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
	sbc	r14,r1
	;; rcall	open
shls2:
	rcall	read
	mov	r16,r8
	sub	r20,r8
	rcall	hexout2
	sec
	adc	r11,r1
	adc	r10,r1
	dec	r19
	brne	shls2
	;; rcall	close
	mov	r16,r20
	rcall	hexout2		; Checksum
	rcall	crlf
	ret

msgout:
        lsl     ZL
        rol     ZH
mo0:
        lpm
        adiw    ZL,1
        tst     r0
        breq    mo1
        mov     r16,r0
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

rdhex0:
	clr	r12
rdhex:
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

read:
	ldi	YL,low(RAMSTART)
	ldi	YH,high(RAMSTART)
	add	YL,r11
	adc	YH,r10
	ld	r8,Y
	ret

write:
	ldi	YL,low(RAMSTART)
	ldi	YH,high(RAMSTART)
	add	YL,r11
	adc	YH,r10
	st	Y,r8
	ret

	;;
	;;
	;;

	packing	on

opnmsg:
        data	CR,LF,"Universal Monitor AVR",CR,LF,0x00
prompt:
	data	"] ",0x00

ihemsg:
        data	"Error ihex\r\n\0"
shemsg:
        data	"Error srec\r\n\0"
errmsg:
        data	"Error\r\n\0"
namsg:
        data	"N/A\r\n\0"
dsep0:
        data	" :\0"
dsep1:
        data	" : \0"
qmsg:
        data	"Sure(Y/N)? \0"
ihexer:
        data	":00000001FF\r\n\0"
srecer:
        data	"S9030000FC\r\n\0"

	packing	off

	if USE_DEV_MEGA164
	include	"dev/dev_mega164.asm"
	endif

	;;
	;; Work Area
	;;
	
	segment	data

	org	(RAMEND+1)-192
	
inbuf:	res	BUFLEN		; Line input buffer
dsadrh: res	1       	; DUMP start address (H)
dsadrl: res	1		; DUMP start address (L)
deadrh: res	1       	; DUMP end address (H)
deadrl: res	1       	; DUMP end address (L)
dstate: res	1
saddrh: res	1       	; SET address (H)
saddrl: res	1		; SET address (L)
hexmod: res	1		; HEX file mode
llen:   res	1

	end
	
