#
# Makefile
#   Universal Monitor for MC680x0
#

.SUFFIXES: .asm .p .hex .sr

devs := dev/dev_6850.asm dev/dev_68681.asm dev/dev_68901.asm \
		dev/dev_emily.asm

all:	unimon_68000.hex unimon_68000.even.bin unimon_68000.odd.bin

unimon_68000.even.bin:	unimon_68000.p
	p2bin -m even unimon_68000.p unimon_68000.even.bin

unimon_68000.odd.bin:	unimon_68000.p
	p2bin -m odd unimon_68000.p unimon_68000.odd.bin

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
