#
# Makefile
#   Universal Monitor for INS8070 (SC/MP III)
#

.SUFFIXES: .asm .p .hex .sr

devs :=	dev/dev_emily.asm dev/dev_ins8073.asm

all:	unimon_ins8070.hex

.p.hex:
	p2hex -F Intel $*.p $*.hex

.p.sr:
	p2hex -F Moto $*.p $*.sr

.asm.p:	config.inc $(devs)
	asl -L $*.asm

config.inc:
	[ -e config.inc ] || ln -s config/config.inc config.inc

clean:
	rm -f *.p *.hex *.sr *.lst
