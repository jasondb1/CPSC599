;=================================================================
; 
; graphics.asm
;
; Author: Jason De Boer
;     ID: 30034428
;
;  Class: CPSC599.82
;
;
; compile:
;   dasm graphics.asm -ographics.prg -v3 
;
; run on (vice) xvic emulator
;   xvic graphics.prg


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

;parts of the splaying area
ULX     equ $02
ULY     equ $02
LRX     equ $21
LRY     equ $20

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

SCREENMAP   equ $1e00
COLORMAP    equ $9600
UCASE       equ $8000 ;- upper case character map
LCASE       equ $8800 ;- lower case normal

JCLOCKL     equ $00a2
CHARSET     equ $1c00
CHARSETSELECT equ $9005

;===================================================================
; User Defined Memory locations
FREE1       equ $F7
FREE2       equ $F8
FREE3       equ $F9
TIMERRESOLUION  equ $FA ; in Jiffys

MSG_PTR_L    equ $FB
MSG_PTR_H    equ $FC

CURRENTNOTE     equ $3f ; index value, there are only 255 notes available each note is 2 bytes
NOTEDURATION    equ $40
NOISEFREQ       equ $41
NOISEDURATION   equ $42

PREVJIFFY   equ $FD
COUNTDOWN   equ $FE

;$57-$66 -  float point  area
V1FREQ      equ $61      ;audio
V2FREQ      equ $62
V3FREQ      equ $63
VNFREQ      equ $64
V1DURATION  equ $69
V2DURATION  equ $6a
V3DURATION  equ $6b
VNDURATION  equ $6c
CURRENTSOUND equ $60

FREE4       equ $6d
FREE5       equ $6e
FREE6       equ $6f;?


;possible to use for (basic fp and numeric area $57 - $70
;possible to use $4e-$53 (misc work area)
;#3f-42 - BASIC DATA address
;$26-2A product area for multiplication


    ;basic stub start
    org     $1001
    
    dc.w    basicEnd
    dc.w    1234
    dc.b    $9e, "4112", 0 ; 4109 = 0x100d 4112 = 0x1010

basicEnd:    dc.w    0

    
    org     $1010
startMl:
    jsr     init
    
mainLoop:
    
   
    jsr     delay
    ;jsr     GETIN
    ;beq     mainLoop
    jsr     loop_kw
    jmp     finished
    
;==================================================================
; delay - in TIMERRESOLUTION
; this could be made to take a as argument of timer delay time
delay:
    lda     #8
delayLoop:
    sta     COUNTDOWN
    lda     #$0
    cmp     COUNTDOWN
    bne     delayLoop
    rts
    

;==================================================================
; timer - this is a 1 second countdown timer but can be altered
; note this only allows just over 4 seconds
; this should be modified as required
; 
; each jiffy is stored and on expiry 
;
; can use this for other game events as well as required

timer: 
    ;read timer value
    ;if > 60 then reset timer and reduce COUNTDOWN by 1
    ;otherwise see if a jiffy has elapsed and inc counter and note duration

    lda     PREVJIFFY
    cmp     JCLOCKL
    beq     timer_continue  ; do nothing if a jiffy has not elapsed
    inc     PREVJIFFY       ;
    dec     V1DURATION    ; decrement duration of note each jiffy
    dec     V2DURATION    ; decrement duration of note each jiffy
    dec     V3DURATION    ; decrement duration of note each jiffy
    dec     VNDURATION    ; decrement duration of note each jiffy

timer_continue:
    lda     JCLOCKL
    cmp     TIMERRESOLUION     ;1/60 of second is a jiffy so 60 is 1 second
    bpl     resetTimer  
    rts

resetTimer:
    dec     COUNTDOWN
    
    lda     #$00    ;set system clock to 0
    sta     JCLOCKL
    sta     PREVJIFFY
timer_end:
    rts   
    
;==================================================================
; init - Initializes stuff
init:
    ;clear screen
    ;lda     #$93
    ;jsr     CHROUT
    
    lda     #$59
    sta     TIMERRESOLUION
    
    ;set custom character set
    lda     #$ff
    sta     CHARSETSELECT
    
    ;set border color
    lda     #9
    sta     $900f
    
colorChar:    
    ;ldx     #$00
    
   ; lda     #YELLOW
   ; sta     COLORMAP,x
   ; cpx     #$00
   ; bne     colorChar
    
    ;lda     #>string_greet
    ;ldy     #<string_greet
    ;sta     MSG_PTR_H
    ;sty     MSG_PTR_L
    
    ;lda     #$00        ;greeting string index
    ;jsr     printString
    ;jsr     keyWait
    
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
    ;clear screen
    lda     #$93
    jsr     CHROUT
    jsr     keyWait
    rts

string_greet:   dc.b    "***DRAWSCREEN  TEST***", $0d, $00
string_press_key: dc.b    "ANY KEY TO CONTINUE...", $0d, $00

    include     "charset.asm"
    
    org $1e00

    dc.b    $07, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $07
    dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06
    dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06
    dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06
    dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06 
    dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06 
    dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06 
    dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06 
    dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06 
    dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06 
    
    ;org     $1ed6
    ;dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06 
    ;dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06 
    ;dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06 
    ;dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06 
    ;dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06 
    ;dc.b    $06, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $06     
    dc.b    $07, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $07

 
    ;org $9600
    ;org 38400
    ;dc.b    06, 06, 06, 06, 06, 06, 06, 06, 06, 06, 06, 06, 06, 06, 06, 60, 60, 06
