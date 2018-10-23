;=================================================================
; 
; game.asm
;
; Authors: Jason De Boer - 30034428
;           Phil Borowoy - 
;           Alec
;           John
;
;  Class: CPSC599.82
;
;
; compile:
;   dasm game.asm -ogame.prg -v3 
;
; run on (vice) xvic emulator
;   xvic game.prg


    Processor 6502
    
;==================================================================
; Constants and Kernel Routines

CHROUT          equ $ffd2
CHRIN           equ $ffcf
GETIN           equ $ffe4 ;from keyb buffer
PLOT            equ $fff0 ;sets if carry is set 
SCNKEY          equ $ff9f
RDTIM           equ $ffde
SETTIM          equ $ffdb
STOP            equ $ffe1

CLOSE           equ $ffc3
OPEN            equ $ffc0
SAVE            equ $ffd8
LOAD            equ $ffd5

;===================================================================
; User Defined constants

;Graphics related
;parts of the playing area
ULX             equ $02
ULY             equ $02
LRX             equ $21
LRY             equ $20
CHAR_BLANK      equ #00
CHAR_BASE       equ #01
CHAR_PLAYER     equ #63

;movement related
UP              equ $10
DOWN            equ $20
RIGHT           equ $40
LEFT            equ $80

;==================================================================
;Colors
COLORREG        equ 646
BLACK           equ 0
WHITE           equ 1
RED             equ 2
CYAN            equ 3
PURPLE          equ 4
GREEN           equ 5
BLUE            equ 6
YELLOW          equ 7

;===================================================================
; Defined Memory locations
BASE_SCREEN     equ $1e00
BASE_COLOR      equ $9600

JOY1_DDRA       equ $9113 ;
JOY1_REGA       equ $9111 ;bit 2 - up, 3 -dn, 4 - left, 5 - fire - (via #1)
JOY1_DDRB       equ $9122
JOY1_REGB       equ $9120 ;bit 7 - rt - (via #2)
SCR_HOR         equ $9000
SCR_VER         equ $9001

SCREENMAP       equ $1e00
SCREENSTATUS    equ $1fcd
COLORMAP        equ $9600
COLORMAPSTATUS  equ $97cd

VOICE1          equ $900a
VOICE2          equ $900b
VOICE3          equ $900c
NOISE           equ $900d
VOLUME          equ $900e ;first 4 bits

JCLOCKL         equ $00a2
CHARSET         equ $1c00
CHARSETSELECT   equ $9005

RANDSEED        equ $8b

;===================================================================
; User Defined Memory locations

;#3f-42 - BASIC DATA address
;CURRENTNOTE     equ $3f ; index value, there are only 255 notes available each note is 2 bytes
NOTEDURATION    equ $40
NOISEFREQ       equ $41
NOISEDURATION   equ $42

;possible to use $4e-$53 (misc work area) - these will change if some rom routines called
;$4e-53 - misc work area note getin uses (can only use as temp area) 5f?
TEMP1           equ $4e
TEMP2           equ $4f
TEMP3           equ $50
TEMP4           equ $51
TEMP5           equ $52
TEMP6           equ $53
TEMP7           equ $54

;possible to use for (basic fp and numeric area $57 - $70
;$57-$66 -  float point  area
CURRENTSOUND    equ $60
V1FREQ          equ $61      ;audio
V2FREQ          equ $62
V3FREQ          equ $63
VNFREQ          equ $64
V1DURATION      equ $69
V2DURATION      equ $6a
V3DURATION      equ $6b
VNDURATION      equ $6c


TIMERRESOLUTION equ $6d ; in Jiffys May not be necessary and hardcoded in if not changing
FREE7           equ $6e
CURRENTNOTE     equ $6f

;Higher Memory
TEMP_PTR_L      equ $F7
TEMP_PTR_H      equ $F8
COLORMAP_L      equ $F9
COLORMAP_H      equ $FA 

PLAYERPOS_L     equ $FB ; actual screen address of player keeps track of player 
PLAYERPOS_H     equ $FC ; and serves as a pointer where to place graphic character of player

PREVJIFFY       equ $FD
COUNTDOWN       equ $FE

;$26-2A product area for multiplication
;033c-03fb - casette buffer area

;nonzpage 0293-029e (rs232 storage)
PLAYERSECTOR    equ $0293   ;the sector where the player is (keeps track of where in the
                            ;      world the player is)
CHARUNDERPLAYER equ $0294 ; 
COLORUNDERPLAYER equ $0295 ; 
PLAYERHEALTH    equ $0296 ;
PLAYERGOLD      equ $0297 ;

GAMEOVER        equ $029e


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;basic stub start
    org     $1001
    
    dc.w    basicEnd
    dc.w    1234
    dc.b    $9e, "4109", 0 ;4112 = 0x100d

basicEnd:    dc.w    0

    org     $100d

;==================================================================
; init - Initializes stuff
init:
    ;basic init is in screen memory to save memory
    jmp     $1e00
    
    include     "intro.asm"
 
init_return:
    jsr     intro
    
    ;set custom character set
    lda     #$ff
    sta     CHARSETSELECT
    
    jsr     drawBoard
    jsr     drawScreen ;maybe scrap this?
    jsr     move_player_display

mainLoop:
mainLoop_continue:
        
    ;these events constantly running
    jsr     timer
    jsr     playSound
    jsr     playNote
    lda     #$0
    cmp     COUNTDOWN
    bne     mainLoop
    
    ;events related to timer only every 10/60 second change this as required
    lda     #10
    sta     COUNTDOWN
    jsr     readJoy ;movement must be limited
    ;jsr     moveEnemies
   
    jsr     GETIN       ;keyboard input ends program right now
    beq     mainLoop
    
    jmp     finished
    
;==================================================================
; drawScreen - draws the screen - not the play area
drawScreen:

;clear bottom 2 lines
    ldx     #44
drawScreen_loop
    lda     #CHAR_BLANK
    sta     SCREENSTATUS,x
    dex
    bne     drawScreen_loop

    ;put health and coin indicator 
    lda     #40
    sta     SCREENSTATUS+2
    lda     #41
    sta     SCREENSTATUS+24
    
    lda     #RED
    sta     COLORMAPSTATUS+2
    lda     #YELLOW
    sta     COLORMAPSTATUS+24
    
    rts


;==================================================================
; drawBoard - draws the screen - not the play area

drawBoard:

;TODO - draw random background elements - rocks trees, paths, houses
    
    ldx     #$00
    lda     #$1f
    sta     TEMP_PTR_H
    lda     #$97
    sta     COLORMAP_H
    ldy     #$00
    sty     TEMP_PTR_L
    sty     COLORMAP_L
    
    ldx     #$02
    ldy     #$cd 
    jmp     drawBoard_inner
drawBoard_outer:
    
    ldy     #$ff

drawBoard_inner:
    ;if random element then
    jsr     prand_newseed
    cmp     #4  ;4/255 chance of being a scenery element
    bcs     drawBoard_base_char
    lda     #4  ;TODO randomize what is drawn - these will be something in the first 8-10 characters
    jmp     drawBoard_to_screen
    ;else
drawBoard_base_char:
    lda     #CHAR_BASE
    
drawBoard_to_screen:   
    sta     (TEMP_PTR_L),y
    lda     #GREEN
    sta     (COLORMAP_L),y
    dey
    cpy     #$ff
    bne     drawBoard_inner
    
    dec     TEMP_PTR_H
    dec     COLORMAP_H
    dex 
    bne     drawBoard_outer

    ;spawn enemies
    
move_player_return: ;needed for movePlayer because subroutine is too long to jump to end
    rts
    
;==================================================================
; movePlayer - moves the player
; x - direction to move player 0 - do not move., 8 - up, 4 -down, 2 - right, 1 - left

movePlayer:
    txa
    beq     move_player_return ;if no movement

    pha
    jsr     isMoveValid ; or integrate into movements? collisions?
    bcs     move_player_return


    ;TODO: get character under player to store and process if coin or other
    
    ;replace background tile under char
    ldy     #0
    lda     CHARUNDERPLAYER  ;put back background tile
    sta     (PLAYERPOS_L),y
    
    lda     PLAYERPOS_L        ; color character
    sta     COLORMAP_L
    clc
    lda     PLAYERPOS_H
    adc     #120                ;distance between screenmap and colormap
    sta     COLORMAP_H
    lda     COLORUNDERPLAYER
    sta     (COLORMAP_L),y

    pla
    
    ;compute move
    ;TODO: move player off screen if player is at edges, play sounds etc
move_player_left:    
    asl 
    bcc     move_player_right
    ldx     #1
    ldy     #1

move_player_right: 
    asl     
    bcc    move_player_down
    ldx    #1
    ldy    #0

move_player_down: 
    asl    
    bcc     move_player_up
    ldx     #22
    ldy     #0

move_player_up: 
    asl     
    bcc     move_player_cont
    ldx     #22
    ldy     #1
    
move_player_cont:

    ;add correct values to player movement - may need to separate subtraction and addition
    txa
    cpy     #1              ;subtract if y is set
    beq     move_player_sub
    
    ;add 
    clc
    adc     PLAYERPOS_L
    sta     PLAYERPOS_L
    lda     #0
    adc     PLAYERPOS_H
    sta     PLAYERPOS_H
    
    jmp     move_player_display
    
move_player_sub:
    sta     TEMP1
    lda     PLAYERPOS_L
    sec
    sbc     TEMP1
    sta     PLAYERPOS_L
    lda     PLAYERPOS_H
    sbc     #$0
    sta     PLAYERPOS_H

move_player_display:       

    ;player color position
    lda     PLAYERPOS_L        
    sta     COLORMAP_L
    clc
    lda     PLAYERPOS_H
    adc     #120                ;distance between screenmap and colormap
    sta     COLORMAP_H

    ;store char under player
    ldy     #$0
    lda     (PLAYERPOS_L),y
    sta     CHARUNDERPLAYER
    lda     (COLORMAP_L),y
    sta     COLORUNDERPLAYER
    
    ;draw player in new position
    lda     #CHAR_PLAYER       ; load the character sprite
    sta     (PLAYERPOS_L),y    ; print next character to position
    lda     #YELLOW               
    sta     (COLORMAP_L),y 
    
    ;step sound
    lda     #$a0
    sta     VOICE1
    lda     #$2
    sta     V1DURATION

move_player_end:
    rts

;==================================================================
; isMoveValid
isMoveValid:
    clc
    rts
    
;==================================================================
; playNote - play a note from melody, duration memory location

playNote:

    ;if duration >1 (jiffy) then return otherwise if ==1 silence if ==0 nextnote
    lda     #$01
    cmp     V2DURATION
    bmi     playNote_end
    beq     playNote_silence
    
    ;new note
    ldy     CURRENTNOTE
    lda     melody,y
    cmp     #$ff            ;ff is the terminator for the melody line
    bne     playNote_continue
    ldy     #$00            ;reset note to first note in melody
    sty     CURRENTNOTE
    lda     melody,y
    
playNote_continue:    
    sta     VOICE2
    lda     duration,y
    sta     V2DURATION
    inc     CURRENTNOTE; this is the note index
    rts

playNote_silence:   ;cuts off last jiffy, to provide separation of notes
    lda     #$00
    sta     VOICE2

playNote_end:
    rts
    
;==================================================================
; playSound - play a currently running sound

playSound:

    ;voice 1
    lda     V1DURATION
    bne     playSound_noise
    sta     VOICE1
    
playSound_noise:
    lda     VNDURATION
    bne     playSound_end
    sta     NOISE
    
playSound_end:
    rts
    
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

    ldx     #$00
    
test_fire:
    lda     #$20         ;test fire button
    bit     JOY1_REGA
    bne     test_right
    ;do something if fire
    
    lda     #$e0
    sta     NOISE
    lda     #$02
    sta     VNDURATION
    
test_right:    
    lda     #$7F
    sta     JOY1_DDRB
    lda     #$80        ;get joy1-right status
    bit     JOY1_REGB
    bne     test_left
    ;do something if right
    ldx     #RIGHT
    
test_left: 
    lda     #$ff
    sta     JOY1_DDRB   ;reset the bit in via#2 to not interfere with keyboard

    lda     #$10         ;test right button
    bit     JOY1_REGA
    bne     test_down
    
    ;do something if left
    ldx     #LEFT
    
test_down: 
    lda     #$08         ;test right button
    bit     JOY1_REGA
    bne     test_up
    
    ;do something if down
    ldx     #DOWN

test_up: 
    lda     #$04         ;test right button
    bit     JOY1_REGA
    bne     cont_rj
    
    ;do something if up   
    ldx     #UP

cont_rj:
    jsr     movePlayer
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
    inc     PREVJIFFY      
    dec     V2DURATION   ;  decrement duration of note each jiffy ;
    dec     V1DURATION    ; decrement duration of note each jiffy
    dec     V3DURATION    ; decrement duration of note each jiffy
    dec     VNDURATION    ; decrement duration of note each jiffy

timer_continue:
    lda     JCLOCKL
    cmp     TIMERRESOLUTION     ;1/60 of second is a jiffy so 60 is 1 second
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
; prand - simple linear feedback prng
; if more randomness is required seed with something related to player input
; return prnad number in accumulator
; A better generator may work better

prand_newseed:
    lda     JCLOCKL
    adc     RANDSEED
    sta     RANDSEED

prand:
    lda     RANDSEED
    beq     doEor ;accounts for 0
    asl
    bcc     noEor
doEor: 
            eor #$1d
noEor: 
    sta     RANDSEED
            
    rts
   

;==================================================================
; keyWait - Waits of any key to be pressed
    
loop_kw:
    jsr     GETIN
    beq     loop_kw
    rts
    
;==================================================================
; finished - cleanup and end
finished:
    lda     #$0
    sta     VOLUME
    
    lda     #240
    sta     CHARSETSELECT
    
    rts

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


    include     "charset.asm"
    
;initialization loaded into graphic memory and written over after

	org	$1e00  

    ;set border/screen color
    lda     #8
    sta     $900f
    
    ;set timerresolution 1 jiffy
    lda     #$01
    sta     TIMERRESOLUTION
    sta     JOY1_DDRA
 
    ;initial character under player is blank
    sta     CHARUNDERPLAYER
    
    ;music/voice settings
    lda     #$00
    sta     CURRENTNOTE
    sta     NOTEDURATION
    sta     PREVJIFFY
    sta     GAMEOVER
    sta     PLAYERGOLD
    
    ;define character starting postion
    lda     #$36
    sta     PLAYERPOS_L
    lda     #$1e
    sta     PLAYERPOS_H

    ;initial player 
    lda     #10
    sta     PLAYERHEALTH
    
    ;reset delay
    lda     #15 ;set countdown timer 15 jiffys (resolution 1 jiffy)
    sta     COUNTDOWN
    
    ;initial volume
    lda     #$0f
    sta     VOLUME
    
    clc
    jmp     init_return
