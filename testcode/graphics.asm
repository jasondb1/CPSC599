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

SCREENAMP    equ $1e00
COLORMAP    equ $9600
UCASE       equ $8000 ;- upper case character map
LCASE       equ $8800 ;- lower case normal

JCLOCKL     equ $00a2

;===================================================================
; User Defined Memory locations
TEMP1       equ $F7
TEMP2       equ $F8
TEMP3       equ $F9
TEMP4       equ $FA

MSG_PTR_L    equ $FB
MSG_PTR_H    equ $FC
FREE3  equ $FD
COUNTDOWN   equ $FE

;possible to use for (basic fp and numeric area $57 - $70
;possible to use $4e-$53 (misc work area)
;#3f-42 - BASIC DATA address
;$26-2A product area for multiplication


    ;basic stub start
    org     $1001
    
    dc.w    basicEnd
    dc.w    1234
    dc.b    $9e, "4112", 0 ;4112 = 0x1010

basicEnd:    dc.w    0

    
    org     $1010
startMl:

    jsr     init
    
    lda     #20 ;set countdown timer
    sta     COUNTDOWN
mainLoop:

    lda     '.'
    jsr     CHROUT
    
    jsr     timer
    lda     COUNTDOWN
    cmp     #$00
    bne     mainLoop
    
   jsr      keyWait
    
    jmp     finished
    
;==================================================================
; timer - this is a 1 second timer but can be altered
timer: 
    ;read timer value
    ;if > 60 then reset timer and reduce COUNTDOWN by 1

    jsr     RDTIM
    cpy     #59     ;1/60 of second is a jiffy so 60 is 1 second
    bpl     resetTimer
    rts

resetTimer:
    sec
    lda     #$01
    sbc     COUNTDOWN
    
    lda     #$00    ;set system clock to 0
    ldx     #$00
    ldy     #$00
    jsr     SETTIM
   
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
; init - Initializes stuff
init:
    ;clear screen
    lda     #$93
    jsr     CHROUT
    
    ;set border color
    lda     #8
    sta     $900f
    
    
    lda     #>string_greet
    ldy     #<string_greet
    sta     MSG_PTR_H
    sty     MSG_PTR_L     
    
    ;lda     #$00        ;greeting string index
    jsr     printString
    jsr     keyWait
    
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

string_greet:   dc.b    "***TIMER  TEST***", $0d, $00
string_press_key: dc.b    "ANY KEY TO CONTINUE...", $0d, $00
