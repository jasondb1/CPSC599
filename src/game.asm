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
CHAR_BORDER     equ #20

;enemy related
NUM_ENEMIES     equ #4  ;(enemies-1 for 0 indexing)
;SPAWN_CHANCE    equ #92 ;92/255 chance of enemy spawning
SPAWN_CHANCE    equ #254 ;

ENEMY_SMOL		equ #53
ENEMY_BOSS_UL	equ #55
ENEMY_BOSS_UR	equ #56
ENEMY_BOSS_LL	equ #57
ENEMY_BOSS_LR	equ #58

;movement map related
UP              equ #$10
DOWN            equ #$20
RIGHT           equ #$40
LEFT            equ #$80

MAP_START_LEVEL1_X  equ #1
MAP_START_LEVEL1_Y  equ #1
MAP_START_LEVEL2_X  equ #5
MAP_START_LEVEL2_Y  equ #12
MAP_START_LEVEL3_X  equ #19
MAP_START_LEVEL3_Y  equ #14


;==================================================================
;Colors
BLACK           equ #0
WHITE           equ #1
RED             equ #2
CYAN            equ #3
PURPLE          equ #4
GREEN           equ #5
BLUE            equ #6
YELLOW          equ #7

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
COLORREG        equ 646

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

;$26-2A product area for multiplication
TEMP10           equ $26
BORDERTOP        equ $27
BORDERBOTTOM     equ $28
BORDERLEFT       equ $29
BORDERRIGHT      equ $2a

;#3f-42 - BASIC DATA address
MAP_PTR_L        equ $3f
MAP_PTR_H        equ $40
;equ $41
;equ $42


;possible to use $4e-$53 (misc work area) - these will change if some rom routines called
;$4e-53 - misc work area note getin uses (can only use as temp area) 5f?
TEMP1           equ $4e
TEMP2           equ $4f
TEMP3           equ $50
TEMP20          equ $51
TEMP21          equ $52
TEMP_ENEMYNUM   equ $53

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

;TIMERRESOLUTION equ $6d ; no longer used, can use for something else
NOTEDURATION    equ $6e
CURRENTNOTE     equ $6f
;equ $70

;Higher Memory
TEMP_PTR_L      equ $F7
TEMP_PTR_H      equ $F8
COLORMAP_L      equ $F9
COLORMAP_H      equ $FA 
CHARPOS_L       equ $FB 
CHARPOS_H       equ $FC 

PREVJIFFY       equ $FD
COUNTDOWN       equ $FE

;88 bytes should be usable for some stuff once program running
;0200-0258        512-600        BASIC input buffer--where the charac-
;                                   ters being INPUT will go.
BASIC_BUFFER_AREA    equ $0200

;033c-03fb - casette buffer area
;feed in from graphic memory if neeeded
;191 bytes
CASETTE_AREA    equ $033C
USER_LABEL      equ $033C

;nonzpage 0293-029e (rs232 storage)
PLAYERHASKEY       equ $0293  
PLAYERWEAPONDAMAGE equ $0294
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
    include     "scroll_screen.asm"

init_return:
    ;jsr     intro ; disable for testing
    
    ;set custom character set
    lda     #$ff
    sta     CHARSETSELECT
    
    jsr     drawBoard
    jsr     drawScreen
    jsr     move_player_cont

mainLoop:
mainLoop_continue:
        
    ;these events constantly running

    jsr     playNote
    jsr     playSound
    ldx     #0          ;move enemy 0 TODO: move all enemies
    jsr     moveEnemy
    jsr     timer
    lda     COUNTDOWN
    bne     mainLoop
    
    ;events related to timer only every 10/60 second change this as required
    lda     #10
    sta     COUNTDOWN
    jsr     readJoy             ;player movement must be limited
   
    lda     GAMEOVER
    ;jsr     GETIN       ;keyboard input ends program right now
    beq     mainLoop
    
    jsr     ending
    
;==================================================================
; finished - cleanup and end
finished:
    lda     #$0
    sta     VOLUME
    
    lda     #240
    sta     CHARSETSELECT
    
    rts
;end of game

    include     "graphics.asm"
    include     "toolkit.asm"
    include     "enemy.asm"
    include     "player.asm"


;===================================================================
; variable section
;
; these are here to prevent alignment issues
;

;enemy status arrays
enemy_type:           dc.b 00, 00, 00, 00, 00; enemy 0, 1, 2, 3, 4 ... must have equal amounts on all
enemy_speed:          dc.b 00, 00, 00, 00, 00
enemy_move_clock:     dc.b 00, 00, 00, 00, 00
enemy_health:         dc.b 00, 00, 00, 00, 00
enemy_x:              dc.b 00, 00, 00, 00, 00
enemy_y:              dc.b 00, 00, 00, 00, 00
enemy_charunder:      dc.b 00, 00, 00, 00, 00

;title and ending text
;text limited to 255 chars long
title_text:
          dc.b    "WITCHER 0.3", $0d, $0d   
          dc.b    "A BBQ QUEST",$0d,$0d
          dc.b    "P BOROWOY", $0d          
          dc.b    "J DEBOER", $0d          
          dc.b    "A MCALLISTER", $0d       
          dc.b    "J WILSON", $0d ,$00
          
ending_text:
          dc.b    "YOU RETRIEVE THE", $0d
          dc.b    "SMOULDERING BBQ", $0d, $0d
          dc.b    "YOUR STEAK IS RUINED!", $0d, $0d      
          dc.b    "YOU ARE MAD!", $0d          
          dc.b    $0d       
          dc.b    "THE END.", $0d ,$00          

;==================================================================
;Colors
;BLACK           equ #0
;WHITE           equ #1
;RED             equ #2
;CYAN            equ #3
;PURPLE          equ #4
;GREEN           equ #5
;BLUE            equ #6
;YELLOW          equ #7

;if space is required move this to cassette buffer or keyboard buffer and/or compact to 4 bit colors
char_color: dc.b 00, 05, 07, 07, 07, 07, 07, 07 ;0-7
            dc.b 07, 02, 01, 01, 05, 05, 05, 05 ;8-15
            dc.b 00, 05, 05, 05, 05, 03, 05, 05 ;16-23
            dc.b 00, 05, 05, 05, 05, 05, 07, 07 ;24-31
            dc.b 07, 07, 07, 07, 07, 07, 07, 07 ;32-39;
            dc.b 02, 07, 02, 05, 05, 05, 05, 05 ;40-47
            dc.b 00, 05, 05, 05, 05, 04, 04, 04 ;48-55
            dc.b 00, 05, 05, 07, 05, 01, 07, 07 ;56-63

;map data - holds exit and other information
;note maps are 22 screens wide and up to 256 tall
;
;
;
;note: make sure adjacent tiles have matching borders
;  ex: if border is on right make sure tile to right has border on left
;      or the player might get trapped in the border
;
;upper 4 bits are for exits
;lower 4 bits are for other information such as if castle is on screen, boss, or other data
;
;
;lower bits:
; exits set bits 0000 - all 4 sides open, 1111 - all sides closed,  
; $8-L, $4-R, $2-B $1-T    BORDER SIDES BITS to set
; $f - all sides (maybe useful for a pit or boss?
;
;basic borders
; $9 TL, $1 T, $5 TR
; $8 L ,     , $4 R
; $A BL, $2 B, $6 BR
;
;2 sides opposing borders
; $C LR; $3 BT
;
; 3 sides
; $D - Opening Bottom; $E - Opening Top; $7 - Opening Left; $B - Opening Right

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
;5 - spawn bbq
;4 - spawn key
;3 - 
;2 - 
;1 - 
;0 - Spawn enemies as normal

;starts at top left of map, can partition into other areas, just adjust map position
; must be 22 wide
; forest: 1,1 thru 13,8
; castle: 1,9 thru 13,16
map_data: ;                                                  <<<  forest    |  dungeon >>
;             1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22
    dc.b    $D4, $90, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $50, $90, $10, $10, $10, $10, $10, $15, $10, $50
    dc.b    $C0, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40, $80, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $A0, $60, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40, $80, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $90, $10, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40, $80, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40, $80, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40, $80, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40, $80, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $a0, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $60, $80, $00, $00, $00, $00, $00, $00, $00, $40
; ------forest ^^^  town vvv   
    dc.b    $90, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $50, $80, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40, $80, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40, $80, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $80, $00, $00, $00, $04, $09, $00, $00, $00, $00, $00, $00, $40, $80, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40, $80, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40, $80, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40, $80, $00, $00, $00, $00, $00, $00, $00, $40
    dc.b    $a0, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $60, $a0, $20, $20, $20, $20, $20, $20, $20, $60


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
; notes: need to be careful so that basic can start program
; bytes need to be counted
; notes: may not be able to load if ready prompt is not at bootup position
; or if error text cursor is above or below a certain line

	org	$1e00  

    ;set border/screen color
    lda     #8
    sta     $900f
    
    ;music/voice settings
    lda     #$00
    sta     CURRENTNOTE
    sta     NOTEDURATION
    sta     PREVJIFFY
    sta     GAMEOVER
    
    ;player settings
    sta     PLAYERGOLD
    sta     PLAYERHASKEY
    
    ;pointer settings
    sta     CHARPOS_L
    sta     COLORMAP_L
    
    ;set timerresolution 1 jiffy
    lda     #$01
    sta     JOY1_DDRA
 
    ;initial character under player is blank
    sta     CHARUNDERPLAYER
 	
    ;initial character direction is right (1)
    sta 	PLAYERDIR

    ;reset delay
    lda     #10 ;set countdown timer 15 jiffys (resolution 1 jiffy)
    sta     COUNTDOWN
    
    ;initial volume
    lda     #$0f
    sta     VOLUME
    
    ;define character starting postion

    ;initial player 
    lda     #10
    sta     PLAYERHEALTH
    sta     PLAYERY
    
    lda     #20
    sta     PLAYERX
    
    ;map and graphic pointers
    lda     #MAP_START_LEVEL1_X
    sta     MAPX
    lda     #MAP_START_LEVEL1_Y
    sta     MAPY
    
    lda     #>BASE_SCREEN
    sta     CHARPOS_H
    lda     #>COLORMAP
    sta     COLORMAP_H
    
    ;*** these are just placeholders - if bytes are added must remove bytes below
    ;can fill this with more instructions or bytes to write to cassette buffer 

    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200
    
    ;jsr     loop_wait_fire ;for debuggin memory before graphics area overwritten
    jmp     init2
    
    org	$1f00
   
init2:
    ;*** these are just placeholders - if bytes are added must remove bytes below
    ;more bytes available
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200

;transfer to casette buffer area
    ldx     #0
write_to_casette_buffer:
    lda     xfer_to_casette,x
    sta     CASETTE_AREA,x
    inx
    cpx     #190
    bne     write_to_casette_buffer
    jmp     init_return
    
xfer_to_casette:
;189 bytes follows:
    dc.b    201, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200
    dc.b    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 201
    

