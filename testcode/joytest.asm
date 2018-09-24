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
;   dasm joytest.asm -ojoytest.prg -v3 
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



;===================================================================
; User Defined Memory locations
TEMP1       equ $F7
TEMP2       equ $F8
TEMP3       equ $F9
JOY1_STATE  equ $FA

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
    ;jsr     keyWait; pause here
    
mainLoop:
    jsr     readJoy
    jsr     GETIN
    beq     mainLoop
    
    jmp     finished
    
 
;==================================================================
; readJoy - read Joystik controller
;
; ?sets JOY1_STATE  bit 5 -fire, 4 - left, 3 - right, 2 - down, 1 - up
; use bit 7 for fire latch? to detect double click
;
;

readJoy:   
    ;TODO: joy state in one byte
    ;lda     #$00
    ;sta     JOY1_STATE

test_fire:
    lda     #$20         ;test fire button
    bit     JOY1_REGA
    bne     test_right
    
    lda     #>string_fire
    ldy     #<string_fire
    sta     MSG_PTR_H
    sty     MSG_PTR_L 
    jsr     printString
    
test_right:    
    lda     #$7F
    sta     JOY1_DDRB
    lda     #$80        ;get joy1-right status
    bit     JOY1_REGB
    bne     test_left
    
    lda     #>string_right
    ldy     #<string_right
    sta     MSG_PTR_H
    sty     MSG_PTR_L 
    jsr     printString
    
test_left: 
    lda     #$ff
    sta     JOY1_DDRB   ;reset the bit in via#2 to not interfere with keyboard

    lda     #$10         ;test right button
    bit     JOY1_REGA
    bne     test_down
    
    lda     #>string_left
    ldy     #<string_left
    sta     MSG_PTR_H
    sty     MSG_PTR_L 
    jsr     printString
    
test_down: 
    lda     #$08         ;test right button
    bit     JOY1_REGA
    bne     test_up
    
    lda     #>string_down
    ldy     #<string_down
    sta     MSG_PTR_H
    sty     MSG_PTR_L 
    jsr     printString

test_up: 
    lda     #$04         ;test right button
    bit     JOY1_REGA
    bne     cont_rj
    
    lda     #>string_up
    ldy     #<string_up
    sta     MSG_PTR_H
    sty     MSG_PTR_L 
    jsr     printString    

cont_rj:
    rts
    
;==================================================================
; init - Initializes stuff
init:
    ;clear screen
    lda     #$93
    jsr     CHROUT
    
    ;set border color
    ;lda     #11
    ;sta     $900f
    
    ;set ddr port 1 to input
    lda     #$00
    sta     JOY1_DDRA
    
    lda     #>string_greet
    ldy     #<string_greet
    sta     MSG_PTR_H
    sty     MSG_PTR_L 
    ;lda     #$00        ;greeting string index
    jsr     printString
    
    rts

;==================================================================
; keyWait - Waits of any key to be pressed
keyWait:

    ;lda     #>string_press_key
    ;ldy     #<string_press_key
    ;sta     MSG_PTR_H
    ;sty     MSG_PTR_L 
    ;lda     #$01
    ;jsr     printString
    
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
;sta     TEMP1

;    lda     MSG_BASE_L ;next message address High
;    ldy     MSG_BASE_H
    
    ;find starting address of message
;next1_ps:
;    sta     MSG_PTR_L
;    sty     MSG_PTR_H
;    cpx     TEMP1
;    beq     cont_ps
; inx     
;  jmp     next1_ps
    
cont_ps:
    ldy     #$00

loop_printString:    
    ;lda     message_press_key,x
    ;brk
    lda     (MSG_PTR_L),y
    jsr     CHROUT
    beq     finished
    iny
    bne     loop_printString
    rts
        
finished:
    rts

; message_x     dc.w  next_string_location  
;               dc.b  "MESSAGE", 00
STRINGS:

string0:        dc.w    string1
string_greet:   dc.b    "***JOYSTICK TEST***", $0d, $0a,  "ANY KEY EXITS...", $0d, $0a, $00
string1:        dc.w    string2
string_press_key: dc.b    "ANY KEY TO CONTINUE...", $10, $13, $00
string2:        dc.w    $0000
string_fire:    dc.b    " FIRE", $0d, $00
string_left:    dc.b    " LEFT", $0d, $00
string_right:    dc.b   "RIGHT", $0d, $00
string_up:    dc.b      "   UP", $0d, $00
string_down:    dc.b    " DOWN", $0d, $00


