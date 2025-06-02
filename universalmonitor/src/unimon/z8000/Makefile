#
# Makefile
#   Universal Monitor for Z8000
#

.SUFFIXES: .asm .p .hex .sr

devs := dev/dev_8530.asm

all:	unimon_z8000.hex unimon_z8000.even.bin unimon_z8000.odd.bin

unimon_z8000.even.bin: unimon_z8000.p
	p2bin -m even unimon_z8000.p unimon_z8000.even.bin

unimon_z8000.odd.bin: unimon_z8000.p
	p2bin -m odd unimon_z8000.p unimon_z8000.odd.bin

.p.hex:
	p2hex -F Intel $*.p $*.hex

.p.sr:
	p2hex -F Moto $*.p $*.sr

.asm.p:	config.inc $(devs)
	asl -L $*.asm

config.inc:
	[ -e config.inc ] || ln -s config/config.inc config.inc

clean:
	rm -f *.p *.hex *.sr *.lst *.bin
