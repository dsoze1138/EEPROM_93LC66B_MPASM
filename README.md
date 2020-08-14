# 93LCxx EEPROM interface in MPASM Assembly language
----------------------------------------------------

This repository contains assembly language source code 
for an SPI like interface to 93LCxx EEPROMs.

This builds with the MPASM assembler from Microchip.

The PIC16F54 baseline and PIC16F876A mid-range are the target controllers.

Only opcode supported baseline controllers are used.

No interrupts are used and the calls are nested a maximum of 2 deep.

WARNING:

With the release of MPLABX 5.40 the MPASM tool chain is no longer supported.


In the fullness of time this code may get ported to the pic-as(v2.20) tool chain.