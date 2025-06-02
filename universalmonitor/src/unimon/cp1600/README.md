# What is this program about?

This is the port of the Universal Monitor ( https://electrelic.com/electrelic/node/1317 ) to the CP-1600 processor, by Kasumi YOSHINO <ykasumi@spamex.com>.

# Differences from other versions

## S command

Since CP-1600 uses 16 bits for its word size (or, more precicely, lower 10 og 16 bits for its word size, upper 6 of 16 bits are reserved for future use), the S commands displays the current memory content in a 4-digit hexadecimal number and accepts 16-bit value.

## D command

The D command produces a 4-digit hexadecimal format dump of the memory. The dump of the memory contents produced includes the contents of at least all words from start address and end address (if specified). These addresses may be altered for the sake of formatting the output for improving readability and cosmetic reason, as is in the other version of the Universal Monitor.

The ASCII format dump is suported. On the right-hand side of the hexadecimal dump, memory word contents are printed out as character equivalents, if printable, as if each word is broken down into a high and low byte. It is noted that, according to the manner in which addresses and memory contents are displayed, the high byte character of a word precedes the low byte characer of a word, e.g., the value 0x4142 is shown as "AB". 

## L command

Both Intel Hex (I8HEX) and Motorola S-Record (S19) format is supported.  It is assumed that values in the address field of Intel Hex records are byte addresses, and hence, the values are always divided by 2 internally to convert them into word addresses (Intel Hex format only). Please remember that the offset address, given by the command line, is treated as a word address, as in other commands.

```
Important Notice for AS (The Macro Assembler) Users:

The p2hex uses byte addressing in Intel Hex format but word addressing in Motorola S-record format.  
```

## Other commands

Other commands other than S, D, G and L commands are not implemented yet.

# Building the monitor

## Assembler

The Macro Assembler AS Version 1.42 Beta Build 223 or later is required.   
Older version does not support `PACKING` directive, which is necessary to assemble the source files. 

http://john.ccac.rwth-aachen.de:8000/as/

## Console driver

Console driver for 16550 UART is only available for the moment.

## Configuration

When reset happens, the CP-1600 loads the start address supplied by an external logic. This address is 0x0000 by pulling the CP-1600 bus down in my home-brewed breadboard computer, to make things easier. If your external logic provides the address other than 0x0000, edit *unimon_cp1600*.asm and modify the line containing `ORG X'0000'`.
