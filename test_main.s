*
* test_main.s - Test program for kprintf implementation
*

	include "exec/types.i"
	include "dos/dos.i"

	xdef	_main

	section code,code

	include "kprintf.i"

_main:
	kprintf "=== kprintf Test Suite ===\n"

	; Test 1: Plain string
	kprintf "Test 1: Plain string\n"

	; Test 2: %s - string substitution
	kprintf "Test 2: Module: %s\n", #test_string

	; Test 3: %ld - long decimal
	kprintf "Test 3: Size: %ld bytes\n", #1234

	; Test 4: %08lx - long hex, 8 digits, zero-padded
	kprintf "Test 4: Address: %08lx\n", #$12345678

	; Test 5: %08lx with small value (padding test)
	kprintf "Test 5: Address: %08lx\n", #$AB

	; Test 6: %04x - hex, 4 digits, zero-padded
	kprintf "Test 6: Checksum: %04x\n", #$1234

	; Test 7: %02lx - long hex, 2 digits
	kprintf "Test 7: Flags: %02lx\n", #$0F

	; Test 8: Multiple arguments
	kprintf "Test 8: Handler at %08lx, modinfo at %08lx\n", #$1000, #$2000

	; Test 9: Mixed format specifiers
	kprintf "Test 9: RomTag: %s (flags=%02lx, pri=%ld)\n", #test_string, #$01, #100

	; Test 10: Newline handling
	kprintf "Test 10: Line 1\nLine 2\nLine 3\n"

	; Test 11: Negative numbers
	kprintf "Test 11: Negative: %ld\n", #-1234

	; Test 12: Very large negative
	kprintf "Test 12: Large negative: %ld\n", #-999999

	; Test 13: Zero
	kprintf "Test 13: Zero: %ld\n", #0

	; Test 14: Zero with padding
	kprintf "Test 14: Zero padded: %08lx\n", #0

	; Test 15: Maximum values
	kprintf "Test 15: Max signed: %ld\n", #$7FFFFFFF

	kprintf "Test 16: All bits: %08lx\n", #$FFFFFFFF

	kprintf "=== Test Suite Complete ===\n"

	moveq	#0,d0
	rts

test_string:
	dc.b	"testmodule",0
short_str:
	dc.b	"foo",0
	cnop	0,2
