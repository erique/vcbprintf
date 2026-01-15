# Makefile for printf test suite

AMIGA_BASE = /opt/amiga
CC = $(AMIGA_BASE)/bin/m68k-amigaos-gcc
AS = $(AMIGA_BASE)/bin/vasmm68k_mot
LD = $(AMIGA_BASE)/bin/m68k-amigaos-gcc
ASFLAGS = -Fhunk -m68000 -quiet -I$(AMIGA_BASE)/m68k-amigaos/ndk-include -I../src -DENABLE_KPRINTF -esc
LDFLAGS = -noixemul -s

all: test_baseline test_new

# Baseline version using Kickstart ROM routines
test_baseline: test_main.o rawdofmt.o
	$(LD) $(LDFLAGS) -o $@ $^

# New version using our implementation
test_new: test_main.o vcbprintf.o
	$(LD) $(LDFLAGS) -o $@ $^

clean:
	rm -f *.o *.txt test_baseline test_new

.PHONY: all clean
