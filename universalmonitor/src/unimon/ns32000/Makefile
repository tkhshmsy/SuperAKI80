#
# Makefile
#   Universal Monitor for NS32000 family
#

.SUFFIXES: .asm .p .hex .sr

devs := dev/dev_emily.asm

all:	unimon_ns32000.hex unimon_ns32000.even.bin unimon_ns32000.odd.bin

unimon_ns32000.even.bin:	unimon_ns32000.p
	p2bin -m even unimon_ns32000.p unimon_ns32000.even.bin

unimon_ns32000.odd.bin:	unimon_ns32000.p
	p2bin -m odd unimon_ns32000.p unimon_ns32000.odd.bin

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
