#
# Makefile
#   Universal Monitor for CP-1600
#

.SUFFIXES: .asm .p .hex .sr

devs := dev/dev_16550.asm

all:	unimon_cp1600.hex unimon_cp1600_high.bin unimon_cp1600_low.bin unimon_cp1600.tar.gz

unimon_cp1600.tar.gz: unimon_cp1600.asm unimon_cp1600.lst unimon_cp1600_high.bin unimon_cp1600_low.bin
	tar zcvf unimon_cp1600.tar.gz unimon_cp1600.asm unimon_cp1600.lst unimon_cp1600_high.bin unimon_cp1600_low.bin   

unimon_cp1600_high.bin: unimon_cp1600.p
	p2bin -m even unimon_cp1600.p unimon_cp1600_high.bin

unimon_cp1600_low.bin: unimon_cp1600.p
	p2bin -m odd unimon_cp1600.p unimon_cp1600_low.bin

.p.hex:
	p2hex -F Intel $*.p $*.hex

.p.sr:
	p2hex -F Moto $*.p $*.sr

.asm.p:	config.inc $(devs)
	asl -L $*.asm

config.inc:
	[ -e config.inc ] || ln -s config/config.inc config.inc

clean:
	rm -f *.p *.hex *.sr *.lst *.bin *.tar.gz
