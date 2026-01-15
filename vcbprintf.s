*
* vcbprintf.s - Clean-room printf implementation
*
* vcbprintf(a0=format, a1=datastream, a2=putcharfunc, a3=putchardata)
* serial_putc(d0=char)
*

	INCLUDE	"hardware/custom.i"

	XDEF vcbprintf,serial_putc

*
* serial_putc - Output character to serial port
*
* Input: d0.b = character to output
*
serial_putc:
	tst.b	d0
	beq.s	.exit

	cmp.b	#10,d0			; LF?
	bne.s	.send_char

	move.w	d0,-(sp)		; Save character
	moveq	#13,d0			; Send CR first
	bsr.s	.send_char
	move.w	(sp)+,d0		; Restore original character

	; Fall through to .send_char

.send_char:
	btst	#13-8,_custom+serdatr	; TBE set?
	beq.s	.send_char

	and.w	#$ff,d0
	or.w	#$0100,d0				; Set stop bit
	move.w	d0,_custom+serdat
.exit:
	rts

*
* vcbprintf - Format string and call putchar function
*
* Input:
*   a0 = format string
*   a1 = data stream (arguments)
*   a2 = putchar function
*   a3 = putchar data
*
vcbprintf:
	movem.l	d0-d7/a0-a6,-(sp)

	move.l	a1,a4			; a4 = datastream pointer
	move.l	a2,a5			; a5 = putchar function
	move.l	a3,a6			; a6 = putchar data

.loop:
	moveq	#0,d0
	move.b	(a0)+,d0		; Get next format char
	beq	.done			; NUL terminator

	cmp.b	#'%',d0
	beq	.format_spec

	; Regular character - just output it
	bsr	.putchar
	bra.s	.loop

.format_spec:
	; Parse format specifier
	; Format: %[flags][width][.precision][length]type
	; We support: %[-][0][width][l]type

	moveq	#0,d1			; d1 = flags (bit 0 = left justify, bit 1 = zero pad)
	moveq	#0,d2			; d2 = width
	moveq	#0,d3			; d3 = is_long flag

	; Check for left justify '-'
	cmp.b	#'-',(a0)
	bne.s	.check_zero_pad
	addq.l	#1,a0
	bset	#0,d1			; Set left justify flag

.check_zero_pad:
	; Check for zero padding '0'
	cmp.b	#'0',(a0)
	bne.s	.parse_width
	addq.l	#1,a0
	bset	#1,d1			; Set zero pad flag

.parse_width:
	; Parse width (decimal number)
.width_loop:
	moveq	#0,d0
	move.b	(a0),d0
	cmp.b	#'0',d0
	blt.s	.check_length
	cmp.b	#'9',d0
	bgt.s	.check_length

	; It's a digit
	addq.l	#1,a0
	sub.b	#'0',d0
	mulu	#10,d2
	add.w	d0,d2
	bra.s	.width_loop

.check_length:
	; Check for 'l' (long)
	cmp.b	#'l',(a0)
	bne.s	.get_type
	addq.l	#1,a0
	moveq	#1,d3			; Set is_long flag

.get_type:
	; Get type character
	moveq	#0,d0
	move.b	(a0)+,d0

	cmp.b	#'s',d0
	beq	.type_string
	cmp.b	#'d',d0
	beq	.type_decimal
	cmp.b	#'u',d0
	beq	.type_unsigned
	cmp.b	#'x',d0
	beq	.type_hex
	cmp.b	#'c',d0
	beq	.type_char

	; Unknown format - just output '%'
	moveq	#'%',d0
	bsr	.putchar
	bra	.loop

.type_char:
	; %c - single character
	moveq	#0,d0
	move.b	(a4)+,d0
	bsr	.putchar
	bra	.loop

.type_string:
	; %s - string
	move.l	(a4)+,a1		; Get string pointer
.string_loop:
	moveq	#0,d0
	move.b	(a1)+,d0
	beq	.loop
	bsr	.putchar
	bra.s	.string_loop

.type_decimal:
	; %d or %ld - signed decimal
	tst.b	d3
	beq.s	.decimal_word
	move.l	(a4)+,d4
	bra.s	.decimal_convert
.decimal_word:
	moveq	#0,d4
	move.w	(a4)+,d4
	ext.l	d4			; Sign extend

.decimal_convert:
	lea	-32(sp),sp		; Buffer for conversion
	move.l	sp,a1

	tst.l	d4
	bpl.s	.decimal_positive

	; Negative - output minus sign and negate
	moveq	#'-',d0
	bsr	.putchar
	neg.l	d4

.decimal_positive:
	bsr	.convert_decimal
	lea	32(sp),sp
	bra	.loop

.type_unsigned:
	; %u or %lu - unsigned decimal
	tst.b	d3
	beq.s	.unsigned_word
	move.l	(a4)+,d4
	bra.s	.unsigned_convert
.unsigned_word:
	moveq	#0,d4
	move.w	(a4)+,d4

.unsigned_convert:
	lea	-32(sp),sp
	move.l	sp,a1
	bsr	.convert_decimal
	lea	32(sp),sp
	bra	.loop

.type_hex:
	; %x or %lx - hexadecimal
	tst.b	d3
	beq.s	.hex_word
	move.l	(a4)+,d4
	bra.s	.hex_convert
.hex_word:
	moveq	#0,d4
	move.w	(a4)+,d4

.hex_convert:
	lea	-32(sp),sp
	move.l	sp,a1
	move.w	d2,d5			; d5 = width
	btst	#1,d1			; Zero pad?
	seq	d6			; d6 = $ff if zero pad, 0 if not
	bsr	.convert_hex
	lea	32(sp),sp
	bra	.loop

.done:
	movem.l	(sp)+,d0-d7/a0-a6
	rts

*
* .putchar - Call putchar function
* Input: d0.b = character
*
.putchar:
	move.l	d0,-(sp)
	move.l	a6,a3
	jsr	(a5)
	move.l	(sp)+,d0
	rts

*
* .convert_decimal - Convert unsigned 32-bit number to decimal and output
* Input: d4.l = number
*
.convert_decimal:
	lea	.powers_of_10(pc),a1
	moveq	#0,d5			; Leading zero flag

.dec_loop:
	move.l	(a1)+,d1		; Get power of 10
	beq.s	.dec_done		; End of table

	moveq	#0,d0			; Digit counter
.div_loop:
	cmp.l	d1,d4
	blt.s	.got_digit
	sub.l	d1,d4
	addq.b	#1,d0
	bra.s	.div_loop

.got_digit:
	tst.b	d5			; Skip leading zeros?
	bne.s	.output_digit
	tst.b	d0
	beq.s	.dec_loop		; Skip if zero and no digits yet

	moveq	#1,d5			; Found first non-zero digit
.output_digit:
	add.b	#'0',d0
	bsr	.putchar
	bra.s	.dec_loop

.dec_done:
	; Output final digit (ones place)
	move.b	d4,d0
	add.b	#'0',d0
	bsr	.putchar
	rts

.powers_of_10:
	dc.l	1000000000
	dc.l	100000000
	dc.l	10000000
	dc.l	1000000
	dc.l	100000
	dc.l	10000
	dc.l	1000
	dc.l	100
	dc.l	10
	dc.l	0			; End marker

*
* .convert_hex - Convert number to hex string and output with padding
* Input: d4.l = number, d5.w = width, d6.b = pad char (0='0', $ff=' ')
*
.convert_hex:
	; Count actual digits needed
	moveq	#0,d7
	move.l	d4,d0
	bne.s	.count_start
	; Special case: value is 0, need 1 digit
	moveq	#1,d7
	bra.s	.do_padding
.count_start:
.count_loop:
	addq.w	#1,d7
	lsr.l	#4,d0
	bne.s	.count_loop
.do_padding:

	; Output padding if needed
	move.w	d5,d1
	sub.w	d7,d1			; d1 = padding needed
	ble.s	.no_padding

	moveq	#'0',d0
	tst.b	d6
	bne.s	.use_space
	; Use '0' for padding (already in d0)
	bra.s	.pad_loop
.use_space:
	moveq	#' ',d0
.pad_loop:
	move.l	d0,-(sp)
	bsr	.putchar
	move.l	(sp)+,d0
	subq.w	#1,d1
	bgt.s	.pad_loop

.no_padding:
	; Output hex digits
	subq.w	#1,d7
	lsl.w	#2,d7			; d7 = shift count for first digit
.hex_loop:
	move.l	d4,d0
	lsr.l	d7,d0
	and.b	#$0f,d0
	cmp.b	#10,d0
	blt.s	.hex_digit
	add.b	#'A'-10,d0
	bra.s	.hex_output
.hex_digit:
	add.b	#'0',d0
.hex_output:
	bsr	.putchar
	subq.w	#4,d7
	bge.s	.hex_loop
	rts
