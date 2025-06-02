#
# Makefile
#   Universal Monitor
#

subdirs :=	6800 6809 8080 z8 z80 avr 6502 tlcs90 scmp mn1610 \
			tms9900 8086 8051 f8 z8000 68000 sh h8300h cosmac \
			ins8070 ucom87 2650 im6100 cp1600 h8500 ns32000 emily

.PHONY: all $(subdirs)


all: $(subdirs)

$(subdirs):
	$(MAKE) -C $@

clean: $(subdirs:=-clean)

$(subdirs:=-clean):
	$(MAKE) -C $(@:-clean=) clean
