;=================================================================
; 
; first.asm
;
; Author: Jason De Boer
;     ID: 30034428
;
;  Class: CPSC599.82
;
;
; compile:
;   dasm first.asm -ofirst.prg -v3 
;
; run on (vice) xvic emulator


    Processor 6502
    
;==================================================================
; Constants and Kernel Routines
;
CHROUT equ $ffd2

    ;basic stub start
    org     $1001
    
    dc.w    basicStubEnd
    dc.w    1234
    dc.b    $9e, "4112", 0 ;4112 = 0x1010

basicStubEnd:    dc.w    0

    org     $1010
startMl:
    ;clear screen
    lda     #$93
    jsr     CHROUT
    
    ;change colour
    lda     #11
    sta     $900f
        
    ldx     #$00

;print a message
loop:    
    lda     message,x
    jsr     CHROUT
    beq     finishMl
    inx
    bne     loop
        
finishMl:
    rts

message:     dc.b "HELLO", $00  
