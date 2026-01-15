*
* rawdofmt.s - Wrapper to call Kickstart ROM's RawDoFmt/RawPutChar
*
* This provides the same interface as rawdofmt_new.s but delegates
* to the ROM routines for baseline comparison testing.
*

	INCLUDE	"lvo/exec_lib.i"

	XDEF	vcbprintf,serial_putc

*
* RawDoFmt - Call ROM's RawDoFmt
*
* Input:
*   a0 = format string
*   a1 = data stream (arguments)
*   a2 = putchar function
*   a3 = putchar data
*
vcbprintf:
	move.l	a6,-(sp)
	move.l	$4.w,a6
	jsr	_LVORawDoFmt(a6)
	move.l	(sp)+,a6
	rts

*
* RawPutChar - Call ROM's RawPutChar
*
* Input: d0.b = character to output
*
	IFND	_LVORawPutChar
_LVORawPutChar	EQU	-516
	ENDC

serial_putc:
	move.l	a6,-(sp)
	move.l	$4.w,a6
	jsr	_LVORawPutChar(a6)
	move.l	(sp)+,a6
	rts
