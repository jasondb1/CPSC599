;=================================================================
; 
; sound.asm
;
; Author: Jason De Boer
;     ID: 30034428
;
;  Class: CPSC599.82
;
;
; compile:
;   dasm sound.asm -osound.prg -v3 
;
; run on (vice) xvic emulator
;   xvic sound.prg


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
; Defined Memory locations and registers
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

JCLOCKL      equ $a2

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

;$4e-53 - misc work area note getin uses (can only use as temp area) 5f?
TEMP1 equ $4e
TEMP2 equ $4f
TEMP3 equ $50
TEMP4 equ $51
TEMP5 equ $52
TEMP6 equ $53
TEMP7 equ $54


;possible to use for (basic fp and numeric area $57 - $70
;possible to use $4e-$53 (misc work area)
;#3f-42 - BASIC DATA address
;$26-2A product area for multiplication

;033c-03fb - casette buffer area
;nonzpage 0293-029e (rs232 storage)

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

    ;while countdown !=0
    lda     COUNTDOWN
    cmp     #$00
    bne     mainLoop_continue
    
    lda     #$02        ;restore countdown
    sta     COUNTDOWN
    
    inc     CURRENTSOUND
    ldx     CURRENTSOUND
    lda     sound,x
    ldy     sound_duration,x
    ldx     #$03    ;change this voice as desired
    
    jsr     newSound
    
mainLoop_continue:
    ldx     #$03 ; change this voice as desired
    jsr     playSound
    jsr     timer
    jsr     GETIN
    beq     mainLoop
    
    jmp     finished

;==================================================================
; playNote - play a note from melody, duration memory location
; A is frequency
; y is duration/modulation  high 2 bits modulation/ low 6 bits duration in jiffys
;
; or modulation 00 - no modulation, 01 - mod up, 10, mod down, 11 - ?

newSound:
    sta     V1FREQ,x
    sta     VOICE1,x
    
    sty     V1DURATION,x

playSound:

    ;x is voice
    lda     V1DURATION,x
    ;lda     VNDURATION
    and     #$3f
    ;cmp     #$00
    
    bne     playSound_continue

playSound_silence:   ;turns off sound/note
    lda     #$00
    sta     VOICE1,x
    rts

playSound_continue:
    
    lda     V1DURATION,x
    and     #$C0
    cmp     #$40
    bmi     playSound_end       ;no modulation
    beq     playSound_modup     
    dec     V1FREQ,x
    beq     playSound_end

playSound_modup:
    inc     V1FREQ,x

playSound_end:
    lda     V1FREQ,x
    sta     VOICE1,x
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

    lda     #$00
    sta     PREVJIFFY
    sta     CURRENTSOUND
    
    lda     #$01
    sta     COUNTDOWN
    
    lda     #59
    sta     TIMERRESOLUION

    ;clear screen
    lda     #$93
    jsr     CHROUT
    
    ;set border color
    ;lda     #8
    ;sta     $900f
    
    lda     #$0f
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
    lda     #$00
    sta     VOLUME
    jsr     keyWait
    rts

string_greet:   dc.b    "***SOUND  TEST***", $0d, $00
string_press_key: dc.b    "ANY KEY TO CONTINUE...", $0d, $00

;           TABLE OF MUSICAL NOTES
;
; ------------------------------------------
; APPROX.                 APPROX.
;  NOTE       VALUE        NOTE       VALUE
; ------------------------------------------
;   C          135          G          215
;   C#         143          G#         217
;   D          147          A          219
;   D#         151          A#         221
;   E          159          B          223
;   F          163          C          225
;   F#         167          C#         227
;   G          175          D          228
;   G#         179          D#         229
;   A          183          E          231
;   A#         187          E#         232
;   B          191          F          233
;   C          195          G          235
;   C#         199          G#         236
;   D          201          A          237
;   D#         203          A#         238
;   E          207          B          239
;   F          209          C          240
;   F#         212          C#         241


; SPEAKER COMMANDS:    WHERE X CAN BE:      FUNCTION:
; -------------------------------------------------------
;   POKE 36878,X          0 to 15           sets volume
;   POKE 36874,X        128 to 255          plays tone
;   POKE 36875,X        128 to 255          plays tone
;   POKE 36876,X        128 to 255          plays tone
;   POKE 36877,X        128 to 255          plays "noise"


;melody is defined as 2 bytes byte 1 freq(note) and length byte 2
; 
;note index
;note: more data could be stored in bits 5-7 of duration
;duration is in number of jiffies
; using 64 jiffies per measure  - tentatively used 16 for quarter notes, 8 for 8th notes
; if slower tempo is required then need to increase durations
;            e        d       c       
melody:   dc.b 207, 201, 195, 207, 201, 195, 195, 195, 195, 195, 201, 201, 201, 201, 207, 201, 195,  00, 255
duration: dc.b  16,  16,  32,  16,  16,  32,   8,   8,   8,   8,   8,   8,   8,   8,  16,  16,  32,  64, 255

drums: 
          dc.b 130, 000, 200, 000, 130, 000, 200, 000,   130, 000, 200, 000, 130, 000, 200, 000, 130, 000, 200, 000, 130, 000, 200, 000, 130, 000, 200, 000, 130, 000, 200, 000, 000, 255 
drum_duration:
          dc.b  4,   12,   8,   8,   4,   8,   8,  12,     4,   12,   8,   8,   4,   8,   8,  12,  4,  12,   8,   8,   4,   8,   8,  12,   4,   12,   8,   8,   4,   8,   8,  12, 64, 255

sound:          dc.b    128, 150, 170, 190, 210, 230, 250, 128, 150, 170, 190, 210, 230, 250, 128, 150, 170, 190, 210, 230, 250
sound_duration: dc.b    $01, $02, $03, $04, $05, $06, $07, $43, $43, $48, $41, $47, $4a, $4f, $86, $a0, $88, $84, $81, $8d, $8f
