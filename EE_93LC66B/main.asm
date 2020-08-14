 list n=0,c=250,r=dec
;   Author: DAN1138
;   Date: 2020-AUG-11
;   File: main.asm
;   Targets: PIC16F876A, PIC16F54
;   Compiler: MPASM v5.22, absolute mode.
;
;   Description: 
;       Read and write to 93LCxx type EEPROM using bit-banged SPI interface.
;       Support for 8-bit and 16-bit format devices.
;
;     Operation:
;       1 - Enable 93LCxx write mode.
;       2 - Set EEPROM address to 0x000.
;       3 - Read value from address.
;       4 - Increment value.
;       5 - Write value to address.
;       6 - Read value from address.
;       7 - Increment address.
;       8 - While address is less than 0x64 loop to step 6.
;       9 - Set address to 0x000 and loop to step 6.
;
;   See:
;       https://www.microchip.com/forums/FindPost/1150022
;
;   Created on August 11, 2020, 11:49 PM
;
;   Based on application notes:
;       http://www.microchip.com/wwwAppNotes/AppNotes.aspx?appnote=en023652
;       http://ww1.microchip.com/downloads/en/Appnotes/00993a.pdf
;       http://ww1.microchip.com/downloads/en/Appnotes/00536.pdf
;       http://ww1.microchip.com/downloads/en/AppNotes/00530f.pdf;
;
;                            PIC16F876A
;                    +-----------:_:-----------+
;    ICD_VPP MCLR -> :  1 MCLRn         PGD 28 : <> RB7 ICD_PGD
;             RA0 <> :  2 AN0           PGC 27 : <> RB6 ICD-PGC
;             RA1 <> :  3 AN1               26 : <> RB5 SPI_MOSI
;             RA2 <> :  4 AN2               25 : <> RB4 SPI_MISO
;             RA3 <> :  5 AN3           PGM 24 : <> RB3 SPI_CS 
;             RA4 <> :  6 T0CKI             23 : <> RB2 SPI_CLK
;             RA5 <> :  7 AN4/SS            22 : <> RB1 
;             GND <> :  8 VSS          INT0 21 : <> RB0 
;      20MHz XTAL -> :  9 OSC1          VDD 20 : <- 5v0
;      20MHz XTAL <- : 10 OSC2          VSS 19 : <- GND
;             RC0 -> : 11 T1OSO          RX 18 : <> RC7 
;             RC1 <> : 12 T1OSI          TX 17 : <> RC6 
;             RC2 <> : 13 CCP1          SDO 16 : <> RC5 
;             RC3 <> : 14 SCK/SCL   SDA/SDI 15 : <> RC4 
;                    +-------------------------+
;                              DIP-28
;
;                             PIC16F54A
;                    +-----------:_:-----------+
;              <>  1 : RA2                 RA1 : 18 <> 
;              <>  2 : RA3                 RA0 : 17 <> 
;              <>  3 : T0CKI              OSC1 : 16 <- 20MHz crystal
;      ICD_VPP ->  4 : MCLR               OSC2 : 15 -> 20MHz crystal
;          GND ->  5 : GND                 VDD : 14 <- 5v0
;              <>  6 : RB0             PGD/RB7 : 13 <> ICD_PGD
;     SPI_CS   <>  7 : RB1             PGC/RB6 : 12 <> ICD_PGC
;     SPI_CLK  <>  8 : RB2                 RB5 : 11 <> 
;     SPI_MOSI <>  9 : RB3                 RB4 : 10 <> SPI_MISO
;                    +-------------------------:
;                              DIP-18
;
;                       93LC66A  (8-bit words)
;                    +-----------:_:-----------+
;     SPI_CS   ->  1 : CS                  VCC : 8 <- 5v0
;     SPI_CLK  ->  2 : CLK                 N/C : 7 -- 
;     SPI_MOSI ->  3 : DI                  N/C : 6 -- 
;     SPI_MISO <-  4 : DO                  VSS : 5 <- GND
;                    +-------------------------:
;                              DIP-8
;
;  PICkit 2/3 Connections for 93LC devices
;  ---------------------------------------
;  PICkit 2/3 Pin           93LC Device Pin (DIP)
;  (1) VPP                  1 CS
;  (2) Vdd                  8 VCC
;  (3) GND                  5 VSS
;  (4) PGD                  4 DO
;  (5) PGC                  2 CLK
;  (6) PGM(LVP)             3 DI
;                           7 PE - enabled (Vdd)
;                           6 'C' Device ORG
;                              Set to select word size
;

;
;Select EEPROM type
#define EE_93LC46B

    IFDEF __16F876A
#INCLUDE<P16F876a.INC>
 errorlevel -302,-224
 __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _HS_OSC & _WRT_OFF & _LVP_OFF & _CPD_OFF
#define EEPROM_RAM 0x71
;
;SPI DEFINES---------------
;
; This GPIO pin assignment is arbitrary, the bit-banged 
; SPI interface could use almost any four GPIO pins.
;
#define SPI_MOSI_BIT        5
#define SPI_MISO_BIT        4
#define SPI_CS        PORTB,3
#define SPI_CLK       PORTB,2
#define SPI_MISO      PORTB,SPI_MISO_BIT
#define SPI_MOSI_PORT PORTB
#define SPI_MOSI      SPI_MOSI_PORT,SPI_MOSI_BIT
#define SPI_MOSI_MASK (1<<SPI_MOSI_BIT)
;SPI DEFINES END-----------
    ENDIF

    IFDEF __16F54
#INCLUDE<P16F54.INC>
 __CONFIG _CP_OFF & _WDT_OFF & _HS_OSC & _CP_OFF 
#define EEPROM_RAM 0x07
;
;SPI DEFINES--------------- 
;
; These pin outs are from Microchip application note AN993
;
#define SPI_MOSI_BIT        3
#define SPI_MISO_BIT        4
#define SPI_CS        PORTB,1
#define SPI_CLK       PORTB,2
#define SPI_MISO      PORTB,SPI_MISO_BIT
#define SPI_MOSI_PORT PORTB
#define SPI_MOSI      SPI_MOSI_PORT,SPI_MOSI_BIT
#define SPI_MOSI_MASK (1<<SPI_MOSI_BIT)
;SPI DEFINES END-----------
    ENDIF
;
  IFDEF EE_93LC46B
#define EE_16BIT
;
;*******93LC46B Command definitions for 16-bit format, 64 words************
#define CMD_EWEN    b'0000000100110000' ; EWEN command, enable write mode
#define CMD_EWDS    b'0000000100000000' ; EWDS command, disable write mode
#define CMD_ERAL    b'0000000100100000' ; ERAL command, erase all
#define CMD_WRAL    b'0000000100010000' ; WRAL command, write all bytes
#define CMD_ERASE   b'0000000111000000' ; ERASE location command
#define CMD_WRITE   b'0000000101000000' ; WRITE location command
#define CMD_READ    b'0000000110000000' ; READ  location command
#define ADDR_MASK   b'0000000000111111' ; Address mask for byte commands
;*********************FEDCBA9876543210*************************************
  ENDIF
;
;
  IFDEF EE_93LC66A
;
;*******93LC66A Command definitions for 8-bit format, 512 bytes************
#define CMD_EWEN    b'0000100110000000' ; EWEN command, enable write mode
#define CMD_EWDS    b'0000100000000000' ; EWDS command, disable write mode
#define CMD_ERAL    b'0000100100000000' ; ERAL command, erase all
#define CMD_WRAL    b'0000100010000000' ; WRAL command, write all bytes
#define CMD_ERASE   b'0000111000000000' ; ERASE location command
#define CMD_WRITE   b'0000101000000000' ; WRITE location command
#define CMD_READ    b'0000110000000000' ; READ  location command
#define ADDR_MASK   b'0000000111111111' ; Address mask for byte commands
;*********************FEDCBA9876543210*************************************
  ENDIF
;
;
  IFDEF EE_93LC66B
#define EE_16BIT
;
;*******93LC66B Command definitions for 16-bit format, 256 words***********
#define CMD_EWEN    b'0000010011000000' ; EWEN command, enable write mode
#define CMD_EWDS    b'0000010000000000' ; EWDS command, disable write mode
#define CMD_ERAL    b'0000010010000000' ; ERAL command, erase all
#define CMD_WRAL    b'0000010001000000' ; WRAL command, write all bytes
#define CMD_ERASE   b'0000011100000000' ; ERASE location command
#define CMD_WRITE   b'0000010100000000' ; WRITE location command
#define CMD_READ    b'0000011000000000' ; READ  location command
#define ADDR_MASK   b'0000000011111111' ; Address mask for byte commands
;*********************FEDCBA9876543210*************************************
  ENDIF
;
;
  IFDEF EE_93LC46A
;
;*******93LC46A Command definitions for 8-bit format, 128 bytes************
#define CMD_EWEN    b'0000001001100000' ; EWEN command, enable write mode
#define CMD_EWDS    b'0000001000000000' ; EWDS command, disable write mode
#define CMD_ERAL    b'0000001001000000' ; ERAL command, erase all
#define CMD_WRAL    b'0000001000100000' ; WRAL command, write all bytes
#define CMD_ERASE   b'0000001110000000' ; ERASE location command
#define CMD_WRITE   b'0000001010000000' ; WRITE location command
#define CMD_READ    b'0000001100000000' ; READ  location command
#define ADDR_MASK   b'0000000001111111' ; Address mask for byte commands
;*********************FEDCBA9876543210*************************************
  ENDIF
;
;
  IFDEF EE_93C06
#define EE_16BIT
;
;*******93C46 Command definitions for 16-bit format, 16 words************
#define CMD_EWEN    b'0000000100110000' ; EWEN command, enable write mode
#define CMD_EWDS    b'0000000100000000' ; EWDS command, disable write mode
#define CMD_ERAL    b'0000000100100000' ; ERAL command, erase all
#define CMD_WRAL    b'0000000100010000' ; WRAL command, write all bytes
#define CMD_ERASE   b'0000000111000000' ; ERASE location command
#define CMD_WRITE   b'0000000101000000' ; WRITE location command
#define CMD_READ    b'0000000110000000' ; READ  location command
#define ADDR_MASK   b'0000000000001111' ; Address mask for byte commands
;*********************FEDCBA9876543210*************************************
  ENDIF
;
; Define how the GPIO pin are initialized
;
#define OPTIONS   0xFF
#define PORTA_DIR 0x00
#define PORTB_DIR 0x00|(1<<SPI_MISO_BIT)
;
; RAM use for 93LCxx interface
;
  cblock EEPROM_RAM
    SPI_TEMP:1
    SPI_COUNT:1
    EEPROM_ADDRESS:2
    EEPROM_DATA:2
  endc
;
; Power-On-Reset entry point
;
    org     0x000
RESET:
    goto    Init
;
; Function: BB_SPI_TX
;
; Description:
;   Bit-Bang SPI transmit/receive function.
;
; Input:    WREG = 8-bits of data to send to SPI slave
;
; Output:   SPI_TEMP = 8-bits of data received from SPI slave
;
; Uses:     SPI_TEMP, SPI_COUNT
;
BB_SPI_TX:
    MOVWF   SPI_TEMP
    RLF     SPI_TEMP,W
    XORWF   SPI_TEMP,F
    CLRF    SPI_COUNT
    BSF     SPI_COUNT,3
    BCF     SPI_MOSI
BB_SPI_TX1:
    BCF     SPI_CLK
    MOVLW   SPI_MOSI_MASK
    BTFSC   STATUS,C
    XORWF   SPI_MOSI_PORT,F  ; Update MOSI output bit
    RLF     SPI_TEMP,F
    BCF     SPI_TEMP,0
    BSF     SPI_CLK
    BTFSC   SPI_MISO
    BSF     SPI_TEMP,0
    DECFSZ  SPI_COUNT,F
    GOTO    BB_SPI_TX1
    BCF     SPI_CLK
    BCF     SPI_MOSI
    RETLW   0
;
; Wait for 93LCxx to complete write or erase action
;
Poll:
    bcf     SPI_CS
    nop
    nop
    bsf     SPI_CS
PollWait:
    nop
    nop
    nop
    nop
    nop
    btfss   SPI_MISO
    goto    PollWait
    bcf     SPI_CS
    retlw   0
;
; Enable writes to 93LCxx
;
EWEN:
    clrf    PORTB
    bsf     SPI_CS
    movlw   HIGH(CMD_EWEN)
    call    BB_SPI_TX
    movlw   LOW(CMD_EWEN)
    call    BB_SPI_TX
    bcf     SPI_CS
    retlw   0
;
; Erase all of the 93LCxx
;
ERAL:
    clrf    PORTB
    bsf     SPI_CS
    movlw   HIGH(CMD_ERAL)
    call    BB_SPI_TX
    movlw   LOW(CMD_ERAL)
    call    BB_SPI_TX
    goto    Poll
;
; Erase byte/word at address
;
ERASE:
    clrf    PORTB
    bsf     SPI_CS
    clrf    PORTB
    bsf     SPI_CS
    movlw   HIGH(ADDR_MASK)
    andwf   EEPROM_ADDRESS+1,W
    iorlw   HIGH(CMD_WRITE)
    call    BB_SPI_TX
    movlw   LOW(ADDR_MASK)
    andwf   EEPROM_ADDRESS,W
    iorlw   LOW(CMD_WRITE)
    call    BB_SPI_TX
    goto    Poll
;
; Read a byte from selected address
;
READ:
    clrf    PORTB
    bsf     SPI_CS
    movlw   HIGH(ADDR_MASK)
    andwf   EEPROM_ADDRESS+1,W
    iorlw   HIGH(CMD_READ)
    call    BB_SPI_TX
    movlw   LOW(ADDR_MASK)
    andwf   EEPROM_ADDRESS,W
    iorlw   LOW(CMD_READ)
    call    BB_SPI_TX
  IFDEF EE_16BIT
    clrw
    call    BB_SPI_TX
    movf    SPI_TEMP,W
    movwf   EEPROM_DATA+1
  endif
    clrw
    call    BB_SPI_TX
    movf    SPI_TEMP,W
    movwf   EEPROM_DATA
    bcf     SPI_CS
    retlw   0
;
; Write a byte to selected address
;
WRITE:
    clrf    PORTB
    bsf     SPI_CS
    movlw   HIGH(ADDR_MASK)
    andwf   EEPROM_ADDRESS+1,W
    iorlw   HIGH(CMD_WRITE)
    call    BB_SPI_TX
    movlw   LOW(ADDR_MASK)
    andwf   EEPROM_ADDRESS,W
    iorlw   LOW(CMD_WRITE)
    call    BB_SPI_TX
  IFDEF EE_16BIT
    movf    EEPROM_DATA+1,W
    call    BB_SPI_TX
  endif
    movf    EEPROM_DATA,W
    call    BB_SPI_TX
    goto    Poll
;
; Main application
;
Main:
    call    EWEN

    clrf    EEPROM_DATA
    clrf    EEPROM_DATA+1
    clrf    EEPROM_ADDRESS
    clrf    EEPROM_ADDRESS+1
    call    READ

    incf    EEPROM_DATA,F
    incf    EEPROM_DATA,W
    movwf   EEPROM_DATA+1
    call    WRITE

ReadLoop:
    call    READ
    incf    EEPROM_ADDRESS,F
    skpnz
    incf    EEPROM_ADDRESS+1,F
    movf    EEPROM_ADDRESS,W
    xorlw   64
    bnz     ReadLoop

    clrf    EEPROM_ADDRESS
    clrf    EEPROM_ADDRESS+1
    goto    ReadLoop
;
; Power-On-Reset initialization
;
Init:
    movlw   OPTIONS
    option
    
    movlw   PORTA_DIR
    tris    PORTA
    movlw   PORTB_DIR
    tris    PORTB
    clrf    PORTA
    clrf    PORTB
    goto Main 
    end