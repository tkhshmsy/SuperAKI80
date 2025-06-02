;;;
;;; Universal Monitor CP-1600
;;; 

;;; The Macro Assembler AS Version 1.42 Beta Build 223 or later is required to assemble the source files

	CPU	CP-1600
	INTSYNTAX	+b'bin'
UPAK	MACRO
	PACKING OFF
	ENDM
	UPAK

TARGET:	equ	"CP1600"


	INCLUDE	"config.inc"

	INCLUDE	"../common.inc"

	;;
	;; ROM area
	;;

	ORG	X'0000'
	DIS
	B CSTART

	;;
	;; Entry point
	;;

	ORG	ENTRY+0		; Cold start
E_CSTART:
	B 	CSTART

	ORG	ENTRY+8		; Warm start
E_WSTART:
	B 	WSTART

	ORG	ENTRY+16	; Console output
E_CONOUT:
	B 	CONOUT

	ORG	ENTRY+24	; (Console) String output
E_STROUT:
	B 	STROUT

	ORG	ENTRY+32	; Console input
E_CONIN:
	B 	CONIN

	ORG	ENTRY+40	; Console status
E_CONST:
	B 	CONST

;;;
;;;
;;;
	
;	ORG	ROM_B
	ORG	X'0100'

CSTART:
	MVII	STACK, R6
	JSR	R5, INIT

;	CLRR	R0
	MVII	X'1000', R0
	;; Memory Dump-start address
	MVO	R0, DSADDR
	MVO	R0, SADDR
	MVO	R0, GADDR
	;; Intel Hex as default file type for saving memory images (not implemented yet)
	MVII	'I', R0
	MVO	R0, HEXMOD	

	IF USE_REGCMD
	; not implemented so far
	; initialization of variables used for REGCMD
	ENDIF
	
	;; Opening message
	MVII	OPNMSG, R4
	JSR	R5, STROUT

	;; CPU identification
	IF USE_IDENT
	; Identification is not necessary, since CP-1600(A) and CP-1610 have the same
	; instruction set and pinouts
	ENDIF

WSTART:
	MVII	PROMPT, R4
	JSR	R5, STROUT
	JSR	R5, GETLIN
	MVII	INBUF, R4
	JSR	R5, SKIPSP
	JSR	R5, UPPER
	TSTR	R0
	BEQ	WSTART

	CMPI	'D', R0
	BEQ	DUMP
;M00:
	CMPI	'G', R0
	BEQ	GO
;M01:
	CMPI	'S', R0
	BEQ	SETM
;M02:
	CMPI	'L', R0
	BEQ	LOADH
;M03:
	CMPI	'P', R0
;	BEQ	SAVEH			; Not implemented so far
	BEQ	WSTART
;M04:
;	IF_USE_REGCMD
	; not implemented so far
	; stub/placeholder
;	ENDIF
;M05:
ERR:
	MVII	ERRMSG, R4	; print error message
	JSR	R5, STROUT
	B 	WSTART			; and get back to command prompt

;;;
;;; Dump memory
;;;
DUMP:
	INCR	R4
	JSR	R5, SKIPSP		; skip unnecessary white space(s)
	JSR	R5, RDHEX		; parse the 1st argument
	TSTR	R1			; it is noted that RDHEX routne also returns the number of characters converted in register R1
	BNEQ	DP0			; first argument (start address) found
;;	No arg
	JSR	R5, SKIPSP		; skip unnecessary white space(s) and look for the second argument
	MVI@	R4, R0
	TSTR	R0
	BNEQ	ERR 		; invalid character detected before end of line. Perform error handling
	MVI	DSADDR, R0	; as the first argument is missing, start address is calculated based on DSADDR
	ADDI	64, R0		; DEADDR := DSADDR + 64
	MVO	R0, DEADDR
	B	DPM 			; perform memory dump
;; 1st arg. found
DP0:
	MVI 	RHVAL, R0	; DSADDR := RHVAL (note: the value of the first argument is stored in RHVAL)
	MVO	R0, DSADDR
	JSR	R5, SKIPSP		; skip unnecessary white space(s) and look for the second argument
	MVI@	R4, R0
	CMPI	',', R0		; arguments should be seperated by comma (',')
	BEQ	DP1				; the second argument (end address) is found
	TSTR	R0
	BNEQ	ERR 		; invalid character detected before end of line. Perform error handling

	;; 1st arg only (No 2nd arg).
	MVI DSADDR, R0		; End address is calculated based on DSADDR. DEADDR := DSADDR + 64
	ADDI	64, R0
	MVO R0, DEADDR
	B	DPM 			; perform memory dump
	;;
DP1:
	JSR	R5, SKIPSP	; skip unnecessary white space(s) and parse the 2nd argument
	JSR	R5, RDHEX
	JSR	R5, SKIPSP
	TSTR	R1		; remember that register R1 holds the number of characters converted
	BEQ	ERR 		; as R1 is zero, the 2nd argument is not a hexadecimal number. Perform error handling
	MVI@	R4, R0
	TSTR	R0
	BNEQ	ERR 	; invalid character detected before end of line. Perform error handling
	MVI RHVAL, R0	; RHVAL holds the value of the second argument
	INCR	R0
	MVO	R0, DEADDR	; DEADDR := RHVAL + 1

	;; DUMP main
DPM:	; Arguments are successfully parsed so far. Start memory dump
	MVI DSADDR, R0		; actual start address is aligned on a 8 words boundary
	ANDI	X'FFF8', R0	; so, leading (and trailing) white-space-padding is required
	MVO R0, DMPPT		; see also DPB routine below
	CLRR	R0
	MVO	R0, DSTATE
;
;					DSTATE	| Status
;					--------+-------------------------------------------------------------------------------------------
;					  0  	| Memory dump is not started yet (DMPPT < DSADDR). Padding with white space is in progress.
;					  1 	| Memory dump is in progress
;					  2 	| Memory dump is finished (DMPPT == DEADDR). Padding with white space will be necessary.
DPM0:
	JSR	R5, DPL 		; dump one line (8 words per line)
	;; DMPPT was already incremented during DPB routine. So, +8 is not needed here
	JSR	R5, CONST		; keypress while memory dump? (non-blocking; not wait for keypress)
	TSTR	R0
	BNEQ	DPM1		; if so, quit memory dumping
	MVI DSTATE, R0 		; reached end address?
	CMPI	2, R0
	BLT	DPM0			; if not, continue memory dumping
	MVI	DEADDR, R0		; end of memory dump. DEADDR is saved for the next memory dump (as a starting address)
	MVO	R0, DSADDR
	B	WSTART
DPM1:		; DMPPT (currenly referenced memory address) is saved for the next memory dump (as a starting address)
	MVI	DMPPT, R0	; DSADDR := DMPPT
	MVO	R0, DSADDR
	B	WSTART			; and get back to command prompt

	;; Dump line
DPL:
	PSHR	R5
	MVI 	DMPPT, R0	; print the current reference address at the beginning of the line
	JSR	R5, HEXOUT4
	MVII	DSEP0, R4	; print the field seperator (' :')
	JSR	R5, STROUT
	MVII	INBUF, R4	; initialize the pointer (ASCPT) with the address of INBUF 
	MVO	R4, ASCPT
	MVII	8, R1		; number of words to be dumped per line
DPL0:
	JSR	R5, DPB 		; dump one word. The scratch pad area is filled with memory value in DPB subroutine
	DECR	R1
	BNEQ	DPL0		; repeat the number of times specified by Register R1

	MVII	DSEP1, R4	; print the field separator (' : ')
	JSR	R5, STROUT

	MVII	INBUF, R4	; beginning of the scratch pad area
	MVII	8, R1		; number of words to be printed as characters (as opposed to hexadecimal digits)
DPL1:
	MVI@	R4, R0
	PSHR	R0
	; high byte of the word
	SWAP	R0
	ANDI	X'FF', R0
	CMPI	' ', R0		; is it pribtable?
	BLT DPL2H			; if not, print '.' instead
	CMPI	X'7F', R0	; is it an extended (graphic) character?
	BGE	DPL2H			; if so, print '.' instead
	JSR	R5, CONOUT
	B 	DPL4
DPL2H:
	MVII	'.', R0
	JSR	R5, CONOUT
DPL4:
	; low byte of the word
	PULR	R0
	ANDI	X'FF', R0
	CMPI	' ', R0		; see above
	BLT	DPL2L
	CMPI	X'7F', R0
	BGE	DPL2L
	JSR	R5, CONOUT
	B 	DPL3
DPL2L:
	MVII	'.', R0
	JSR	R5, CONOUT
DPL3:
	DECR	R1			; repeat the number of times specified by Register R1
	BNEQ	DPL1
	JSR	R5, CRLF		; ends with a carrage return and line feed
	PULR	R7

	;; Dump word
DPB:
	PSHR	R5
	MVII	' ', R0
	JSR	R5, CONOUT
	MVI	DSTATE, R0
	TSTR	R0
	BNEQ	DPB2	; if DSTATE is not 0, leading padding is not needed
	;; Dump state 0
	MVI 	DSADDR, R0
	MVI 	DMPPT, R2
	CMPR	R2, R0	; does DMPPT (dump pointer) reach to the actual start address (DSADDR)?
	BEQ	DPB1		; if so, start memory dump

; padding with white space before (DSTATE == 0) and after (DSTATE == 2) the actual memory dump
DPB0:
	MVII	' ', R0	; print 4 white spaces instead of 4 hexadecimal digits
	JSR	R5, CONOUT
	JSR	R5, CONOUT
	JSR	R5, CONOUT
	JSR	R5, CONOUT
	MVI 	ASCPT, R4
;	MVO@	R0, R4	; write 2 white spaces into the scratch pad area
	MVII	X'2020', R0	; write 2 white spaces into the scratch pad area
	MVO@	R0, R4	; Remember that R4 (ASCPT) is auto post-incremented.
	MVO	R4, ASCPT
	MVI 	DMPPT, R0
	INCR	R0		; advance the printers (DMPPT)
	MVO	R0, DMPPT
	PULR	R7

; Found start address (actual memory dump is ready to start)
DPB1:
	MVII	1, R0	; set DSTATE (dump state) to 1, which means that memory dump is in progress
	MVO	R0, DSTATE
DPB2:
	MVI 	DSTATE, R0
	CMPI	1, R0	; if DSTATE is not 1, leading/trailing padding requires
	BNEQ	DPB0
	MVI	DMPPT, R4	; R0 := *DMPPT++
	MVI@	R4, R0	; auto post-increment (R4)
	MVO	R4, DMPPT
	MVI	ASCPT, R4	; *ASCPT++ := R0
	MVO@	R0, R4
	MVO	R4, ASCPT
	JSR	R5, HEXOUT4	; print one word (contents of R0)
	MVI 	DEADDR, R0
	MVI 	DMPPT, R2
	CMPR	R2, R0	; reached end address?
	BNEQ	DPBE
	MVII	2, R0	; then, changed DSTATE (from 1) to 2
	MVO	R0, DSTATE
DPBE:
	PULR	R7

;;;
;;; Go address
;;;
GO:
	INCR	R4
	JSR	R5, SKIPSP	; skip unnecessary white space(s)
	JSR	R5, RDHEX	; parse the argument
	MVI@	R4, R0	; end of line is expected
	TSTR	R0
	BEQ	GO0
	B 	ERR 		; invalid character detected before end of line. Perform error handling
GO0:
	TSTR	R1		; remember that register R1 holds the number of characters converted
	BEQ	G0			; No argument found. Jump to the address where it is stored in GAADR
	MVI RHVAL, R0	; RHVAL holds the jump target address
	IF USE_REGCMD
	; not implemented so far
	; stub/placeholder
	ENDIF
	MVO	R0, GADDR	; GADDR holds the jump target address now (GADDR := RHVAL)
G0:
	MVI GADDR, R0
	MOVR	R0, R7	; jump to the target address

;;;
;;; Set memory
;;;
SETM:
	INCR	R4
	JSR	R5, SKIPSP	; skip unnecessary white space(s)
	JSR	R5, RDHEX	; parse the argument
	JSR	R5, SKIPSP	; skip unnecessary white space(s)
	MVI@	R4, R0
	TSTR	R0
	BNEQ	SMER	; invalid character detected before end of line. Perform error handling
	TSTR	R1		; Register R1 holds the number of characters converted
	BEQ	SM1			; No argument found. The value of SADDR will be used as a target address
	MVI RHVAL, R0
	MVO	R0, SADDR	; SADDR holds the target address now (SADDR := RHVAL)
SM1:
	MVI SADDR, R0
	JSR	R5, HEXOUT4	; print the target address
	MVII	DSEP1, R4
	JSR	R5, STROUT	; print field separator (' : ')
	MVI	SADDR, R4
	MVI@	R4, R0	; read the current memory contents
	JSR	R5, HEXOUT4	; and print it out
	MVII	' ', R0
	JSR	R5, CONOUT
	JSR	R5, GETLIN	; input one line at a time
	MVII	INBUF, R4
	JSR	R5, SKIPSP	; skip unnecessary white space(s)
	MVI@	R4, R0	; end of line? (i.e. no argument)
	TSTR	R0
	BNEQ	SM2		; if not, continue parsing the line
	;; Empty (Increment address)
	MVI	SADDR, R0
	INCR	R0
	MVO	R0, SADDR
	B	SM1
SM2:
	CMPI	'-', R0	; decrement-address sub-command?
	BNEQ	SM3
	;; '-' (Decrement address)
	MVI	SADDR, R0
	DECR	R0
	MVO	R0, SADDR
	B	SM1
SM3:
	CMPI	'.', R0	; quit sub-command?
	BNEQ	SM4
	;; '.' (Quit)
	B	WSTART		; then, get back to command prompt
SM4:
	DECR	R4		; move the pointer to the beginning of the string entered in the buffer
	JSR	R5, RDHEX	; read the new value
	TSTR	R1
	BEQ	SMER		; invalid input (nothing converted). Perform error handling
	MVI	SADDR, R4
	MVI	RHVAL, R0
	MVO@	R0, R4	; write the new value onto the memory address specified by register R4
	MVO	R4, SADDR	; update the pointer. Remember that R4 is auto post-incremented
	B	SM1
SMER:
	B	ERR 		; print error message and get back to command prompt

;;;
;;; LOAD HEX file
;;;
;;; Reminder: 
;;; Each line in a HEX file contains one HEX record. These records are made up of byte data and each address field represents a byte-address.
;;; Meanwhile, CP-1600 has a 16-bit bus (D15-D0) and read/write is on 16-bit blocks.
;;; So, the following points should be considered (for Intel HEX format only):
;;;
;;; 1) From CP-1600 side, the address value in the address field is twice as much as the address value used for actual memory access.
;;; 2) Byte data with even byte-address (A) is transferred on D15-D8 (i.e. higher 8-bit) of the memory with the address A divided by 2.
;;; 3) Byte data with odd byte-address (A) is transerred on D7-D0 (i.e. lower 8-bit) of the memory with the address A divided by 2.
;;; 
LOADH:
	INCR	R4
	JSR	R5, SKIPSP	; skip unnecessary white space(s)
	JSR	R5, RDHEX	; read the offset address
	JSR	R5, SKIPSP	; skip unnecessary white space(s)
	TSTR	R0
	BNEQ	SMER	; invalid character detected. Perform error handling
	
LH0:
	JSR	R5, CONIN	; read start code
	JSR	R5, UPPER
	CMPI	'S', R0	; Motorola S-record?
	BEQ	LHS0
LH1:
	CMPI	':', R0	; Intel HEX?
	BEQ	LHI0
LH2:				; neither Motorola S-record nor Intel HEX
	;; Skip to EOL
	CMPI	CR, R0
	BEQ	LH0
	CMPI	LF, R0
	BEQ	LH0
LH3:
	JSR	R5, CONIN
	B	LH2

LHI0:				; decode Intel HEX
	JSR	R5, HEXIN	; read next 1 byte (byte count). Note: byte count is the number of data byte in the record of the current line
	MVO	R0, CKSUM	; prepare for calculating checksum
	MOVR	R0, R1	; preserve the value in register 1

	JSR	R5, HEXIN	; read next 1 byte (address H; high-order byte)
	MOVR	R0, R2	; R2 := R0 << 8
	SWAP	R2
	ADD CKSUM, R0
	MVO	R0, CKSUM

	PSHR	R2		; preserve R2 because HEXIN destroys it
	JSR	R5, HEXIN	; read next 1 byte (address L; low-order byte)
	PULR	R2		; restore R2, which holds high order byte
	PSHR	R0
	ADD	CKSUM, R0
	MVO	R0, CKSUM
	PULR	R0
	ADDR	R2, R0	; sum together (high order byte + low order byte)
	MOVR	R0, R4	; now R4 contains byte-address

	JSR	R5, HEXIN
	MVO	R0, RECTYP
	ADD	CKSUM, R0
	MVO	R0, CKSUM

	TSTR	R1		; was byte count zero?
	BEQ	LHI3		; if so, proceed to validate checksum
LHI1:
	JSR	R5, HEXIN	; read next 1 byte in the current record
	PSHR	R0
	ADD	CKSUM, R0
	MVO	R0, CKSUM
	PULR	R0

	MVI	RECTYP, R2
	TSTR	R2		; is record type zero?
	BNEQ	LHI2	; if non-zero, the record is end-of-file (or extended address recored). skip to next byte

;	MVO@	R0, R4	; data record. write 1 byte onto the memory

	MOVR	R4, R3	; remember that the address field contains byte-address and CP-1600 performs Read/Write 2 bytes (=word) at a time 
	CLRC
	RRC	R3			; even-byte boundary?
	BNC	.even
	ADD RHVAL, R3	; add offset. Remember that RHVAL holds word-address offset specified in the argument
	MVI@	R3, R2	; odd-byte boundary. only low-byte is changed with high-byte left untouched
	ANDI	X'FF00', R2
	ADDR	R2, R0
	MVO@	R0, R3	; write 1 _word_ onto the memory
	B	LHI2
.even:				; even-byte boundary
	SWAP	R0 		; R0 := R0 << 8 so that high-byte is changed with low-byte left untouched
	ADD RHVAL, R3	; add offset. See also above
	MVI@	R3, R2
	ANDI	X'00FF', R2
	ADDR	R2, R0
	MVO@	R0, R3	; write 1 _word_ onto the memory
LHI2:
	INCR	R4		; increment the address pointer (again, byte-aligned)
	DECR	R1		; decrement the byte counter
	BNEQ	LHI1	; skip to next byte of the record
LHI3:
	JSR	R5, HEXIN	; read next 1 byte (checksum is represented using 2's complement of total sum)
	ADD	CKSUM, R0	; CKSUM is total sum so far. if the record is read successfully, (CKSUM + checksum) should be zero by its nature
	ANDI	X'00FF', R0	; only the low-order byte is significant
	BNEQ	LHIE	; if non-zero,  checksum error detected. Quit decoding
	MVI RECTYP, R0	; if record type is happen to be "data", skip to EOL
	TSTR	R0
	BEQ	LH3
	B	WSTART		; end of decoding/loading in success. Get back to command prompt
LHIE:
	MVII	IHEMSG, R4
	JSR	R5, STROUT	; Print error message
	B	WSTART		; and get back to command prompt

LHS0:				; decode Motorola S-record
	JSR	R5, CONIN	; read next 1 character, which denotes the type of record
	MVO	R0, RECTYP	; store it for late use. it should be ranged from '0' to '9' ('1' for data with 16-bit address)

	JSR	R5, HEXIN	; read next 1 byte, which denotes the byte count of the rest of the current record
	MOVR	R0, R1	; R1 holds byte count.
					; Different from Intel HEX, it always has a value of (actual number of bytes of data + 3)
					; (extra 3 bytes: 2 bytes for address and 1 byte for checksum)
	MVO	R0, CKSUM	; prepare for calculating checksum
	; the following 2 bytes of data denote the address to be written to
	JSR	R5, HEXIN	; read next 1 byte (address H; high-order byte)
	MOVR	R0, R2	; R2 := R0 << 8
	SWAP	R2
	PSHR	R0
	ADD CKSUM, R0
	MVO	R0, CKSUM
	PULR	R0

	PSHR	R2		; preserve R2 because HEXIN destroys it
	JSR	R5, HEXIN	; read next 1 byte (address L; low-order byte)
	PULR	R2		; restore R2, which holds address H
	PSHR	R0
	ADD	CKSUM, R0
	MVO	R0, CKSUM
	PULR	R0
	ADDR	R2, R0	; compose address value
	ADD RHVAL, R0	; add offset. Remember that RHVAL also holds word-address offset specified in the argument
	MVO	R0, DMPPT	; and store it in DMPPT (address to be written to)
	CLRR	R4
	MOVR	R4, R3

	SUBI	3, R1	; no data byte? (i.e. the current record contains address fieled (2 bytes) and checksum (1 byte) only)
	BEQ	LHS3		; if so, end of file. start validation
LHS1:
	JSR	R5, HEXIN	; read 1 byte data in thecurrent record
	PSHR	R0
	ADD	CKSUM, R0	; update checksum
	MVO	R0, CKSUM

	MVI RECTYP, R0
	CMPI	'1', R0	; S1 record? (16-bit address field and data)
	BNEQ	LHS2

	PULR	R0
;	MVO@	R0, R4	; write 1 byte onto the memory
	MOVR	R4, R3
	RRC	R3			; even-byte boundary?
	BNC	.even
	MVI DMPPT, R3
	MVI@	R3, R2	; odd-byte boundary. only low-byte is changed with high-byte left untouched
	ANDI	X'FF00', R2
	ADDR	R2, R0
	MVO@	R0, R3	; write 1 _word_ onto the memory
	MVI DMPPT, R0
	INCR	R0
	MVO R0, DMPPT
	B	LHS20
.even:				; even-byte boundary
	SWAP	R0 		; R0 := R0 << 8 so that high-byte is changed with low-byte left untouched
	MVI DMPPT, R3
	MVI@	R3, R2
	ANDI	X'00FF', R2
	ADDR	R2, R0
	MVO@	R0, R3	; write 1 _word_ onto the memory
	B	LHS20
LHS2:
	PULR	R0
LHS20:
	INCR	R4		; increment the address pointer (again, byte-aligned)
	DECR	R1 		; decrement the byte counter
	BNEQ	LHS1	; repeat data-writing R1 times
LHS3:
	JSR	R5, HEXIN	; read next 1 byte, which denotes the checksum using 1's complement
	; CKSUM is total sum so far. if the record is read successully, (CKSUM + checksum) should be $FF by its nature
	MVI CKSUM, R2
	ANDI	X'00FF', R2	; only the low-order byte is significant
	MVO R2, CKSUM
	ADD	CKSUM, R0
	CMPI	X'00FF', R0
	BNEQ	LHSE	; If the result is not $FF, it means that checksum error is detected. Quit decoding
	; In case of S7, S8 and S9 record, the address field specifies the execution start address (address of 0 can be used, though)
	; and these records are placed at the end of file. So, It's an end mark
	MVI	RECTYP, R0
	CMPI	'7', R0
	BEQ	LHSR
	CMPI	'8', R0
	BEQ	LHSR
	CMPI	'9', R0
	BEQ	LHSR
	B	LH3			; In case of S0, S2..S5 record, skip to EOL
LHSE:
	MVII	SHEMSG, R4
	JSR	R5, STROUT
LHSR:
	B	WSTART

;;;
;;; Register
;;;
	IF USE_REGCMD
	; not implemented (yet)
	ENDIF

;;;
;;; Other support routines
;;;
	
STROUT:
	PSHR	R5
-	MVI@	R4, R0		; Implicit auto post-increment (R4)
	TSTR	R0			; Null-word termination
	BEQ	+
	JSR	R5, CONOUT
	B  -

+	PULR	R7
                                        
HEXOUT4:				; print out the contents of R0, in 4 digits
	PSHR	R5			; save the return address on the stack
	PSHR	R0			; save the contents of R0 on to the stack for later use
	SWAP	R0			; print high-order byte 
	JSR	R5, HEXOUT2
	PULR	R0			; restore the contents of R0
	JSR	R5, HEXOUT2		; and print low-order byte
	PULR	R7

HEXOUT2:				; print out the contents of R0, in 2 digits
	PSHR	R5			; save the return addres on the stack
	ANDI	X'FF', R0	; ignore high-order byte
	PSHR	R0			; save the contents of R0
	SLR	R0, 2
	SLR	R0, 2
	JSR	R5, HEXOUT1		; print high nibble
	PULR	R0			; restore the contents od R0
	JSR	R5, HEXOUT1		; and print low nibble
	PULR	R7

HEXOUT1:				; print out one hexadecial digit
	PSHR	R5			; save the return address on the stack
	ANDI	X'0F', R0	; ignore high nibble at this moment
	ADDI	'0', R0		; convert the number to character
	CMPI	'9'+1, R0
	BLT	HEXOUTE			; print it if R0 >=0 and R0 <= 9
	ADDI	'A'-'9'-1, R0	; additional adjustment is required if R0 > 9
HEXOUTE:
	JSR	R5, CONOUT 		; print one digit
	PULR	R7

HEXIN:					; read one byte (2 hex. digits) from the terminal and store it in R0
	PSHR	R5
	CLRR	R0			; initial return value is zero, of course
	JSR	R5, HI0			; read 1st digit
	MOVR	R0, R2		; R2 holds the 1st digit's value
	SLL	R2, 2 			; R2 := R0 << 4
	SLL	R2, 2
	JSR	R5, HI0			; read 2nd digit. R0 holds the 2nd digit's value
	ADDR	R2, R0		; sum together
	PULR	R7
HI0:
	PSHR	R5
	PSHR	R1			; preserve the contents of R1
	JSR	R5, CONIN		; read 1 character
	JSR	R5, UPPER 		; make it uppercase, if applicable
	CMPI	'0', R0
	BLT	HIR				; incoming character is not a number. exit
	CMPI	'9'+1, R0
	BLT	HI1				; incoming character is between '0' to '9'. proceed to convert the character to number
	CMPI	'A', R0
	BLT	HIR				; incoming character is not a hexadecimal number. exit
	CMPI	'F'+1, R0
	BGE	HIR				; incoming character is not a hexadecimal number. exit
	; additional adjustment for conversion (for 'A' .. 'F')
	SUBI	'A'-'9'-1, R0
HI1:
	SUBI	'0', R0		; convert the character to the number
HIR:
	PULR	R1			; restore the contents of R1
	PULR	R7

CRLF:
	PSHR	R5
	MVII	CR, R0
	JSR	R5, CONOUT
	MVII	LF, R0
	JSR	R5, CONOUT
	PULR	R7

GETLIN:					; input one line at a time
	PSHR	R5
	MVII	INBUF, R4	; INBUF is the starting address of the input buffer
	CLRR	R1			; R1 holds the number of characters read into the input buffer
GL0:
	JSR	R5, CONIN		; read one character
	CMPI	CR, R0		; end of line?
	BEQ	GLE
	CMPI	LF, R0
	BEQ	GLE				; then, exit
	CMPI	BS, R0		; back-space or DEL?
	BEQ	GLB				; then, erase the previous character
	CMPI	DEL, R0
	BEQ	GLB
	CMPI 	' ', R0		; control or graphic character?
	BLT	GL0
	CMPI	X'80', R0
	BGE	GL0
	CMPI	BUFLEN-1, R1	; buffer boundary check
	BGE	GL0
	INCR	R1			; increment the count and store the character
	MVO@	R0, R4		; and store the character in the buffer. Remember that R4 will be automatically incremented.
	JSR	R5, CONOUT		; print the character (echo back)
	B	GL0
GLB:
	TSTR	R1			; if no characters are read from the terminal so far, ignore it
	BEQ	GL0
	DECR	R1			; decrement the counter and buffer pointer
	DECR	R4
	MVII	BS, R0		; move the cursor to the last character
	JSR R5, CONOUT
	MVII	' ', R0		; overwite it with white-space
	JSR	R5, CONOUT
	MVII	BS, R0		; move the cursor to the last position
	JSR	R5, CONOUT
	B	GL0
GLE:
	JSR	R5, CRLF		; print \n\r
	CLRR	R0			; null-word termination
	MVO@	R0, R4
	PULR	R7

SKIPSP:
	PSHR	R5
-	MVI@	R4, R0		; read the character pointed at (R4). Note: R4 is automatically incremented.
	CMPI	' ', R0		; space character?
	BNZE 	SSE			; then, advance the buffer pointer until next non-space character
	B 	-
SSE:
	DECR	R4			; Update R4 (input buffer pointer). R4 now points the last non-space character in the buffer
	PULR	R7

UPPER:					; convert the character to uppercase
	PSHR	R5
	CMPI	'a', R0		; is character between 'a' and 'z'?
	BLT	UPE
	CMPI	'z'+1, R0
	BGE	UPE
	SUBI	'a'-'A', R0	; then, convert it to uppercase.
UPE:
	PULR	R7

RDHEX:					;  convert hex string in the buffer to number
	PSHR	R5
	CLRR	R1			; initialize the result variable (RHVAL)  and counter (R1) to 0
	MVO	R1, RHVAL
RH0:
	MVI@	R4, R0		; read 1 character
	JSR	R5, UPPER		; make it uppercase, if applicable
	CMPI	'0', R0		; is the character is between '0' and '9'?
	BLT	RHE
	CMPI	'9'+1, R0
	BLT	RH1
	CMPI	'A', R0		; is the character is between 'A' and 'F'?
	BLT	RHE
	CMPI	'F'+1, R0
	BGE	RHE
	SUBI	'A'-'9'-1, R0	; then proceed to the conversion after the additional ajustment
RH1:
	SUBI	'0', R0		; perform conversion (1 digit = 1 character)
	MVI 	RHVAL, R2	; update the result value
	SLL	R2, 2
	SLL	R2, 2
	ADDR	R0, R2
	MVO	R2, RHVAL
	INCR	R1
	B	RH0				; continue converting
RHE:
	DECR	R4
	PULR	R7

;;;
;;; Interrupt handler
;;;
;	Not implemented (yet)
	
;;;
;;; Strings
;;;
	
OPNMSG:
	TEXT	CR, LF, "Universal Monitor CP-1600", CR, LF, 0

PROMPT:
	TEXT	"] ", 0

IHEMSG:
	TEXT	"Error ihex", CR, LF, 0

SHEMSG:
	TEXT	"Error srec", CR, LF, 0

ERRMSG:
	TEXT	"Error", CR, LF, 0

DSEP0:
	TEXT	" :", 0
DSEP1:
	TEXT	" : ", 0
;
	IF USE_DEBUG
PREAMBL:
	TEXT	"<<<<<<< ", 0
	ENDIF

	IF USE_IDENT
;	not implemented
	ENDIF
	
	IF USE_REGCMD
;	not implemented (yet)
	ENDIF


	IF USE_DEV_16550
	INCLUDE "dev/dev_16550.asm"
	ENDIF
	
	;;
	;; Vector Area
	;; no vector area is available for CP-1600, since interrupt vectors are provided by hardware 	
	;;

	;;
	;; RAM Area
	;;
	;; Work Area
	;;

	ORG	WORK_B
	
INBUF:	RES	BUFLEN		; Line input buffer
DSADDR:	RES	1		; Dump start address
DEADDR:	RES	1		; Dump end address
DSTATE:	RES	1		; Dump state
GADDR:	RES	1 		; Go address
SADDR:	RES	1		; Set address
HEXMOD:	RES	1		; HEX file mode
RECTYP:	RES	1		; Record type
	
	IF USE_REGCMD
;	not implemented (yet)
	ENDIF
	
RHVAL:	RES	1		; RDHEX Value
DMPPT:	RES	1		; DUMP pointer
ASCPT:	RES	1		; ASCII pointer
CKSUM:	RES	1		; Checksum
;
	IF USE_DEBUG

	ORG	X'1000'
GTEST:
	J 	WSTART

	ENDIF
;

	END
