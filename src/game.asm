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
SCRROWS         equ 23
SCRCOLS         equ 22

SCREENLEFT      equ 1      ;screen starts at 1,1
SCREENTOP       equ 1
SCREENRIGHT     equ 22
SCREENBOTTOM    equ 21
CHAR_BLANK      equ #00
CHAR_BASE       equ #01
CHAR_PLAYER     equ #63
CHAR_PLAYER_L	equ #59

;enemy related
NUM_ENEMIES     equ 4 ;(enemies-1 for 0 indexing)
ENEMY_SMOL		equ #53
ENEMY_BOSS_UL	equ #55
ENEMY_BOSS_UR	equ #56
ENEMY_BOSS_LL	equ #57
ENEMY_BOSS_LR	equ #58

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
MAP_PTR_L       equ $3f
MAP_PTR_H       equ $40
;equ $41
;equ $42


;possible to use $4e-$53 (misc work area) - these will change if some rom routines called
;$4e-53 - misc work area note getin uses (can only use as temp area) 5f?
TEMP1           equ $4e
TEMP2           equ $4f
TEMP3           equ $50
TEMP4           equ $51
TEMP5           equ $52
TEMP6           equ $53
TEMP_ENEMYNUM   equ $54

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
NOTEDURATION    equ $6e
CURRENTNOTE     equ $6f

;Higher Memory
TEMP_PTR_L      equ $F7
TEMP_PTR_H      equ $F8
COLORMAP_L      equ $F9
COLORMAP_H      equ $FA 
CHARPOS_L       equ $FB 
CHARPOS_H       equ $FC 

PREVJIFFY       equ $FD
COUNTDOWN       equ $FE

;$26-2A product area for multiplication



;033c-03fb - casette buffer area

;nonzpage 0293-029e (rs232 storage)
PLAYERKEY       equ $0293  
PLAYERUNUSED    equ $0294
CHARUNDERPLAYER equ $0295 
PLAYERHEALTH    equ $0296 
PLAYERGOLD      equ $0297 
PLAYERY         equ $0298 
PLAYERX         equ $0299 
PLAYERDIR		equ	$029a

MAPX            equ $029b;
MAPY            equ $029c;

TEMPVAR			equ $029d

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
    ;initialization loaded into graphic memory and written over after
    
    jmp     $1e00
    
    lda     #0
    sta     MAPX
    sta     MAPY
    
    include     "intro.asm"
 
init_return:
    ;jsr     intro
    
    ;set custom character set
    lda     #$ff
    sta     CHARSETSELECT
    
    jsr     drawBoard
    jsr     drawScreen ;maybe scrap this?
    jsr     move_player_cont

mainLoop:
mainLoop_continue:
        
    ;these events constantly running
    jsr     timer
    jsr     playNote
    jsr     playSound
    jsr     moveEnemy
    lda     #$0
    cmp     COUNTDOWN
    bne     mainLoop
    
    ;events related to timer only every 10/60 second change this as required
    lda     #10
    sta     COUNTDOWN
    jsr     readJoy ;movement must be limited
    ;jsr     moveEnemies
   
    lda     GAMEOVER
    ;jsr     GETIN       ;keyboard input ends program right now
    beq     mainLoop
    
;==================================================================
; finished - cleanup and end
finished:
    lda     #$0
    sta     VOLUME
    
    lda     #240
    sta     CHARSETSELECT
    
    rts

    include     "graphics.asm"
    include     "utilities.asm"
    include     "enemy.asm"
    include     "player.asm"


;===================================================================
; variable section
;
; these are here to prevent alignment issues
;
enemy_type:           dc.b 00, 00, 00, 00, 00; enemy 0, 1, 2, 3, 4 ... must have equal amounts on all
enemy_speed:          dc.b 00, 00, 00, 00, 00
enemy_move_clock:     dc.b 00, 00, 00, 00, 00
enemy_health:         dc.b 00, 00, 00, 00, 00
enemy_x:              dc.b 00, 00, 00, 00, 00
enemy_y:              dc.b 00, 00, 00, 00, 00
enemy_charunder:      dc.b 00, 00, 00, 00, 00

;if space is required move this to cassette buffer or compact to 4 bit colors
char_color: dc.b 00, 05, 07, 07, 07, 07, 07, 07 ;0-7
            dc.b 07, 05, 05, 05, 05, 05, 05, 05 ;8-15
            dc.b 00, 05, 05, 05, 05, 05, 05, 05 ;16-23
            dc.b 00, 05, 05, 05, 05, 05, 07, 07 ;24-31
            dc.b 07, 07, 07, 07, 07, 07, 07, 07 ;32-39;
            dc.b 02, 07, 02, 05, 05, 05, 05, 05 ;40-47
            dc.b 00, 05, 05, 05, 05, 04, 04, 04 ;48-55
            dc.b 00, 05, 05, 07, 05, 01, 07, 07 ;56-63

;map data - holds exit and other information
;note maps are 22 screens wide and up to 256 tall
;upper 4 bits are for exits
;lower 4 bits are for other information such as if castle is on screen, boss, or other data
;
;
;lower bits:
; exits set bits 0000 - all 4 sides open, 1111 - all sides closed,  
; 1000 - left, 0100 - right blocked
; 0010 - down, 0001 - up    blocked
;
;upper bits:
;f - spawn boss (do not spawn enemies)
;e 
;d - 
;c -
;b 
;a
;9 - draw dungeon entrance
;8 - draw castle
; spawn enemies as normal <8
;7 - draw house/hut
;6 
;5
;4 - spawn key
;3 - 
;2 - 
;1 - 
;0 - Spawn enemies as normal

;starts at bottom left of forest map
map_data: 
    dc.b    $a4, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $60
    dc.b    $80, $08, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $90, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $50
;top of forestmap


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


;must go last because the address is after all of this code
    include     "charset.asm"


;these init values will get overwritten once game starts
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
 	
    ;initial character direction is right (1)
    sta 	PLAYERDIR

    ;music/voice settings
    lda     #$00
    sta     CURRENTNOTE
    sta     NOTEDURATION
    sta     PREVJIFFY
    sta     GAMEOVER
    sta     PLAYERGOLD
    
    ;define character starting postion

    ;initial player 
    lda     #10
    sta     PLAYERHEALTH
    sta     PLAYERY
    
    lda     #20
    sta     PLAYERX

    
    ;reset delay
    lda     #15 ;set countdown timer 15 jiffys (resolution 1 jiffy)
    sta     COUNTDOWN
    
    ;initial volume
    lda     #$0f
    sta     VOLUME
    
    clc
    jmp     init_return
