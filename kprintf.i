	include	"lvo/exec_lib.i"

	xref	vcbprintf,serial_putc


kprintf	MACRO
	IFD	ENABLE_KPRINTF

	ifnc	"","\9"
		move.l  \9,-(sp)
	endc
	ifnc	"","\8"
		move.l  \8,-(sp)
	endc
	ifnc	"","\7"
		move.l  \7,-(sp)
	endc
	ifnc	"","\6"
		move.l  \6,-(sp)
	endc
	ifnc	"","\5"
		move.l  \5,-(sp)
	endc
	ifnc	"","\4"
		move.l  \4,-(sp)
	endc
	ifnc	"","\3"
		move.l  \3,-(sp)
	endc
	ifnc	"","\2"
		move.l  \2,-(sp)
	endc

	pea	.fmt\@
;	pea	.ret\@
	bsr	_kprintf
	adda.w	#NARG*4,sp
	bra.b	.ret\@
.fmt\@
	dc.b	\1,0
	even

.ret\@

	ENDC
	ENDM

;	IFD	ENABLE_KPRINTF
	bra	_kprintf_end
_kprintf:	movem.l	d0/d1/a0/a1/a2/a3/a6,-(sp)	

		move.l	$4.w,a6
;		jsr	-504(a6)		; _LVORawIOInit (execPrivate7)
;		move.w	#(3546895/115200),$dff032
		move.l	32(sp),a0
		lea	36(sp),a1
		lea	.putch(pc),a2
		move.l	a6,a3
		jsr	vcbprintf

		movem.l	(sp)+,d0/d1/a0/a1/a2/a3/a6
		rts

.putch:		exg.l	a3,a6
		jsr	serial_putc
		exg.l	a6,a3
		rts

; rawdofmt implementation linked separately

_kprintf_end:
;	ENDC

