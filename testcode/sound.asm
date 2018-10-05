;=================================================================
; 
; joytest.asm
;
; Author: Jason De Boer
;     ID: 30034428
;
;  Class: CPSC599.82
;
;
; compile:
;   dasm scroll.asm -oscroll.prg -v3 
;
; run on (vice) xvic emulator
;   xvic joytest.prg


    Processor 6502
    
;==================================================================
; Constants and Kernel Routines

CHROUT  equ $ffd2
CHRIN   equ $ffcf
GETIN   equ $ffe4 ;from keyb buffer
PLOT    equ $fff0 ;sets if carry is set 
SCNKEY  equ $ff9f
RDTIM   equ $ffde
SETTIM  equ $ffdb
STOP    equ $ffe1

CLOSE   equ $ffc3
OPEN    equ $ffc0
SAVE    equ $ffd8
LOAD    equ $ffd5

;==================================================================
;Colors
BLACK   equ 0
WHITE   equ 1
RED     equ 2
CYAN    equ 3
PURPLE  equ 4
GREEN   equ 5
BLUE    equ 6
YELLOW  equ 7

;===================================================================
; Defined Memory locations
BASE_SCREEN equ $1e00
BASE_COLOR  equ $9600

JOY1_DDRA    equ $9113 ;
JOY1_REGA    equ $9111 ;bit 2 - up, 3 -dn, 4 - left, 5 - fire - (via #1)
JOY1_DDRB    equ $9122
JOY1_REGB    equ $9120 ;bit 7 - rt - (via #2)
SCR_HOR      equ $9000
SCR_VER      equ $9001

VOICE1       equ $900a
VOICE2       equ $900b
VOICE3       equ $900c
NOISE        equ $900d
VOLUME       equ $900e ;first 4 bits


;===================================================================
; User Defined Memory locations
TEMP1       equ $F7
TEMP2       equ $F8
TEMP3       equ $F9
TEMP4       equ $FA

MSG_PTR_L    equ $FB
MSG_PTR_H    equ $FC
MSG_BASE_L   equ $FD
MSG_BASE_H   equ $FE

    ;basic stub start
    org     $1001
    
    dc.w    basicEnd
    dc.w    1234
    dc.b    $9e, "4112", 0 ;4112 = 0x1010

basicEnd:    dc.w    0

    
    org     $1010
startMl:

    jsr     init
    
    ;go through all of the voices
    ldy     #$00
nextVoice: 
    lda     #$80 ;lowest frequency of voice
    sta     TEMP1

mainLoop:
    lda     TEMP1
    ldx     #$30

    jsr     playNote
    ;lda     #$0d
    ;jsr     wait
    
    inc    TEMP1
    lda     TEMP1
    cmp     #$ff
    bne     mainLoop
    
    iny
    cpy     #$04
    bne     nextVoice
    
    jmp     finished


;==================================================================
; playNote - play a note 
; A - the frequency
; X - the duration (just using a dumb loop right now no specific timings
; Y - voice 1,2,3,4 (noise)?
playNote:
    sta     VOICE1,y
    txa
    jsr     wait
    lda     #$00
    sta     VOICE1,y
    rts
    
 ;==================================================================
; init - Initializes stuff
init:
    ;clear screen
    lda     #$93
    jsr     CHROUT
    
    ;set border color
    lda     #8
    sta     $900f
    
    lda     #$0f
    ;ora     VOLUME
    sta     VOLUME
    
    lda     #>string_greet
    ldy     #<string_greet
    sta     MSG_PTR_H
    sty     MSG_PTR_L     
    
    ;lda     #$00        ;greeting string index
    jsr     printString
    jsr     keyWait
    
    ;set volume

    rts
   

;==================================================================
; delay - set a delay from accumulator in jiffys (1/60) seconds 
delay:
    sta     TEMP2
    
    lda     #$00    ;set system clock to 0
    ldx     #$00
    ldy     #$00
    jsr     SETTIM
    
delayLoop:
    jsr     RDTIM
    sty     TEMP3
    lda     TEMP2
    cmp     TEMP3
    bpl     delayLoop
   
    rts     
    
 ;==================================================================
; delay - set a delay from accumulator in jiffys (1/60) seconds 
wait:
    sta     TEMP2
    
waitLoop:
    lda     #$ff
    sta     TEMP3   
innerLoop: 
   
    dec     TEMP3
    lda     #$0
    cmp     TEMP3
    bne     innerLoop
   
   dec     TEMP2
   lda     #$0
   cmp     TEMP2
   bne      waitLoop
    ;brk
   
    rts        
    

;==================================================================
; keyWait - Waits of any key to be pressed
keyWait:

    lda     #>string_press_key
    ldy     #<string_press_key
    sta     MSG_PTR_H
    sty     MSG_PTR_L 
    lda     #$01
    jsr     printString
    
loop_kw:

    jsr     GETIN
    beq     loop_kw
    rts

;==================================================================
; printString- Prints a string x
; accumulator has string index
; 
; 

printString:
    
cont_ps:
    ldy     #$00

loop_printString:    
    lda     (MSG_PTR_L),y
    jsr     CHROUT
    beq     end_print
    iny
    bne     loop_printString
end_print:
    rts
        
finished:
    jsr     keyWait
    rts

string_greet:   dc.b    "***SOUND  TEST***", $0d, $00
string_press_key: dc.b    "ANY KEY TO CONTINUE...", $0d, $00
