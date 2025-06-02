#
# Makefile
#   Universal Monitor for SuperH
#

.SUFFIXES: .asm .p .hex .sr

devs := dev/dev_sci.asm dev/dev_emily.asm

all:	unimon_sh.hex unimon_sh.rev.hex unimon_sh.even.bin unimon_sh.odd.bin

unimon_sh.even.bin:	unimon_sh.p
	p2bin -m even unimon_sh.p unimon_sh.even.bin

unimon_sh.odd.bin:	unimon_sh.p
	p2bin -m odd unimon_sh.p unimon_sh.odd.bin

unimon_sh.rev.hex: unimon_sh.hex
	objcopy -I ihex -O ihex --reverse-bytes=2 unimon_sh.hex unimon_sh.rev.hex

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
