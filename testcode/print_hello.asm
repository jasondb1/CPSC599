;=================================================================
; 
; second.asm
;
; Author: Jason De Boer
;     ID: 30034428
;
;  Class: CPSC599.82
;
;
; compile:
;   dasm first.asm -oname.prg -v3 
;
; run on (vice) xvic emulator


    Processor 6502
    
;==================================================================
; Constants and Kernel Routines

CHROUT  equ $ffd2
CHRIN   equ $ffcf
GETIN   equ $ffe4 ;from keyb buffer
PLOT    equ $fff0 ;sets if carry is set 
SCNKEY  equ $ff9f
RDTIM   equ $ffde
STOP    equ $ffe1

CLOSE   equ $ffc3
OPEN    equ $ffc0
SAVE    equ $ffd8
LOAD    equ $ffd5




    
    ;basic stub start
    org     $1001
    
    dc.w    basicEnd
    dc.w    1234
    dc.b    $9e, "4112", 0 ;4112 = 0x1010

basicEnd:    dc.w    0

    
    org     $1010
startMl:

    jsr     init
    
mainLoop:
    

;==================================================================
; init - Initializes stuff
init:
    ;clear screen
    lda     #$93
    jsr     CHROUT
    
    ;set border color
    lda     #11
    sta     $900f
    rts
    

;==================================================================
; keyWait - Waits of any key to be pressed
keyWait:
    jsr     GETIN
    beq     keyWait
    lda     #$00
    rts

;==================================================================
; printString- Prints a string at address of accumulator
printString:
    ldx     #$00

loop_printString:    

    lda     message,x
    jsr     CHROUT
    beq     keyWait
    inx
    bne     loop
 
        
finished:
    rts

message:     dc.b "HELLO", $00  

