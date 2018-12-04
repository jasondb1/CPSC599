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

CHROUT              equ $ffd2
CHRIN               equ $ffcf
GETIN               equ $ffe4 ;from keyb buffer
PLOT                equ $fff0 ;sets if carry is set 
SCNKEY              equ $ff9f
RDTIM               equ $ffde
SETTIM              equ $ffdb
STOP                equ $ffe1

CLOSE               equ $ffc3
OPEN                equ $ffc0
SAVE                equ $ffd8
LOAD                equ $ffd5

;===================================================================
; User Defined constants

;Graphics related
;parts of the playing area
SCRROWS             equ #23
SCRCOLS             equ #22

SCREENLEFT          equ #1      ;screen starts at 1,1
SCREENTOP           equ #1
SCREENRIGHT         equ #22
SCREENBOTTOM        equ #21

;background
CORNER_LENGTH       equ #4
WALKABLE            equ #23 ; everything below this value can be walked on
CHAR_BLANK          equ #00
CHAR_SOLID          equ #42
CHAR_BASE_CASTLE    equ #22
CHAR_BORDER_CASTLE  equ #24
CHAR_BASE_FOREST    equ #1
CHAR_BORDER_FOREST  equ #23

;sprites
CHAR_PLAYER_R       equ #63
CHAR_PLAYER_L       equ #62
CHAR_PLAYER_U	    equ #61
CHAR_PLAYER_D	    equ #60
CHAR_SWORD_R        equ #59
CHAR_SWORD_L        equ #58
CHAR_SWORD_U        equ #57
CHAR_SWORD_D        equ #56

CHAR_SPLAT          equ #15
CHAR_HIT            equ #27
CHAR_MISS           equ #28
CHAR_GOLD           equ #14
CHAR_KEY            equ #8
CHAR_HEALTH         equ #21

GOLD_CHANCE         equ #150     ;chance of spawning gold
HEALTH_CHANCE       equ #70      ;chance of spawning health
CHANCE_TO_HIT       equ #204     ;= 255 * 0.8 modify as needed

;enemy related
NUM_ENEMIES         equ #6  ;(enemies-1 for 0 indexing - 5 allowed in this case)
SPAWN_CHANCE        equ #90 ;x/255 chance of enemy spawning (freeze when no enemy spawned)
;SPAWN_CHANCE       equ #254 ;debug/testing

ENEMY_SMOL		    equ #53

;movement map related
UP                  equ #$10
DOWN                equ #$20
RIGHT               equ #$40
LEFT                equ #$80

MAX_MAP_ROWS        equ #10     ;set this to the number of rows in map_data
MAX_HEALTH          equ #20     ;set this to game variable later if health upgrades are availabled

MAX_LEVELS          equ #5      ;3-7 are good values - this might be a user config option later


;==================================================================
;Colors
BLACK               equ #0
WHITE               equ #1
RED                 equ #2
CYAN                equ #3
PURPLE              equ #4
GREEN               equ #5
BLUE                equ #6
YELLOW              equ #7

;===================================================================
; Defined Memory locations
BASE_SCREEN         equ $1e00
BASE_COLOR          equ $9600

JOY1_DDRA           equ $9113 ;
JOY1_REGA           equ $9111 ;bit 2 - up, 3 -dn, 4 - left, 5 - fire - (via #1)
JOY1_DDRB           equ $9122
JOY1_REGB           equ $9120 ;bit 7 - rt - (via #2)
SCR_HOR             equ $9000
SCR_VER             equ $9001

SCREENMAP           equ $1e00
SCREENSTATUS        equ $1fcd
COLORMAP            equ $9600
COLORMAPSTATUS      equ $97cd
COLORREG            equ 646

VOICE1              equ $900a
VOICE2              equ $900b
VOICE3              equ $900c
NOISE               equ $900d
VOLUME              equ $900e ;first 4 bits

JCLOCKL             equ $00a2
CHARSET             equ $1c00
CHARSETSELECT       equ $9005

;BASIC RAND SEED $8B-$8F
RANDSEED                equ $8b
ENEMY_ATTACKDURATION    equ $8c
PLAYERHEALTH            equ $8d
ATTACKDURATION          equ $8e
ATTACK_ACTIVE           equ $8f

;===================================================================
; User Defined Memory locations

;$14-15 integer area
TEMP_MOVE           equ $14
;SPAWN_X             equ $15

;$69 -$70 current variable name
TEMP_VAR            equ $69
;SPAWN_Y             equ $70

;$26-2A product area for multiplication
TEMP10              equ $26
BORDERTOP           equ $27
BORDERBOTTOM        equ $28
BORDERLEFT          equ $29
BORDERRIGHT         equ $2a

;#3f-42 - BASIC DATA address
MAP_PTR_L           equ $3f
MAP_PTR_H           equ $40
TEMP_PTO            equ $41
TEMP11              equ $42


;possible to use $4e-$53 (misc work area) - these will change if some rom routines called
;$4e-53 - misc work area note getin uses (can only use as temp area) 5f?
TEMP1               equ $4e
TEMP2               equ $4f
TEMP3               equ $50
TEMP20              equ $51
TEMP21              equ $52
TEMP_ENEMYNUM       equ $53

;possible to use for (basic fp and numeric area $57 - $70
;$57-$66 -  float point  area

MAPX                equ $57
MAPY                equ $58

LEVEL               equ $59
BASE_HEALTH         equ $5a
ENEMY_ATTACK_ACTIVE equ $5b
ATTACK_X            equ $5c
ATTACK_Y            equ $5d
ENEMY_ATTACK_X      equ $5e
ENEMY_ATTACK_Y      equ $5f

CURRENTSOUND        equ $60
V1FREQ              equ $61      ;audio
V2FREQ              equ $62
V3FREQ              equ $63
VNFREQ              equ $64

PLAYERY             equ $65
PLAYERX             equ $66

V1DURATION          equ $67
V2DURATION          equ $68
V3DURATION          equ $69
VNDURATION          equ $6a

CHAR_BORDER         equ $6b
ATTACK_CHARUNDER    equ $6c

CURRENTNOTE_BASS    equ $6d
NOTEDURATION        equ $6e
CURRENTNOTE         equ $6f
PLAYERSPEED         equ $70

;Higher Memory
TEMP_PTR_L          equ $F7
TEMP_PTR_H          equ $F8

COLORMAP_L          equ $F9
COLORMAP_H          equ $FA 
CHARPOS_L           equ $FB 
CHARPOS_H           equ $FC 

PREVJIFFY           equ $FD
COUNTDOWN           equ $FE

;88 bytes should be usable for some stuff once program running
;0200-0258        512-600       88 bytes BASIC input buffer--where the charac-
;                                   ters being INPUT will go.
BASIC_BUFFER_AREA   equ $0200
;not currently used

;033c-03fb - casette buffer area
;191 bytes
;arrays can vary depending on number of enemies
enemy_type              equ $033c
enemy_speed             equ $033c + ((NUM_ENEMIES + 1) * 1)       
enemy_move_clock        equ $033c + ((NUM_ENEMIES + 1) * 2)
enemy_health            equ $033c + ((NUM_ENEMIES + 1) * 3)  
enemy_x                 equ $033c + ((NUM_ENEMIES + 1) * 4)  
enemy_y                 equ $033c + ((NUM_ENEMIES + 1) * 5)  
enemy_charunder         equ $033c + ((NUM_ENEMIES + 1) * 6)  

;used to keep track of number of enemies killed
ENEMY_KILLED_L          equ $033c + ((NUM_ENEMIES + 1) * 7) 
ENEMY_KILLED_H          equ ENEMY_KILLED_L + 1

SPAWN_X                 equ ENEMY_KILLED_H + 1
SPAWN_Y                 equ ENEMY_KILLED_H + 2
TEMPVAR			        equ ENEMY_KILLED_H + 3
FLAG_BOSS_ATTACK		equ ENEMY_KILLED_H + 4
FLAG_INVALID_MOVE		equ ENEMY_KILLED_H + 5
CHAR_BASE               equ ENEMY_KILLED_H + 6
;TEMP_MOVE               equ ENEMY_KILLED_H + 7

;used for boss spawning
BOSS_ACTIVE             equ ENEMY_KILLED_H + 8
BOSS_UL_X               equ BOSS_ACTIVE + 1
BOSS_UR_X               equ BOSS_ACTIVE + 2
BOSS_LL_X               equ BOSS_ACTIVE + 3
BOSS_LR_X               equ BOSS_ACTIVE + 4
BOSS_UL_Y               equ BOSS_ACTIVE + 5
BOSS_UR_Y               equ BOSS_ACTIVE + 6
BOSS_LL_Y               equ BOSS_ACTIVE + 7
BOSS_LR_Y               equ BOSS_ACTIVE + 8
BOSS_CHAR               equ BOSS_ACTIVE + 10
DIRECTION_TO_PLAYER     equ BOSS_ACTIVE + 11
FLAG_OFFSCREEN          equ BOSS_ACTIVE + 12

;Less used player variables
HIGHEST_LEVEL           equ $03ec
MUSIC_INTERVAL          equ $03ed
PLAYER_SPRITE_CURRENT   equ $03ee
SWORD_SPRITE_CURRENT    equ $03ef
PLAYERHASKEY            equ $03f0  
PLAYERWEAPONDAMAGE      equ $03f1
CHARUNDERPLAYER         equ $03f2 
PLAYERGOLD_H            equ $03f3       ;BCD number
PLAYERGOLD_L            equ $03f4       ;BCD number
 
PLAYERDIR		        equ	$03f7

GAMEOVER                equ $03fb

;nonzpage 0293-029e (rs232 storage) available for use 
    org     $0293

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

    ;set border/screen color
    lda     #8
    sta     $900f
    
    ;The intro needs to be here before initializing variables otherwise
    ;some of the variables used with basic routines could get overwritten
    jsr     intro ; disable for testing  
    
    ;0 initial values in cassette buffer
    lda     #$00
    ldx     #$bf
init_loop1:
    sta     $033c,x
    dex
    bne     init_loop1  

    ldx     #$19
init_loop2:
    sta     $57,x
    dex
    bne     init_loop2
    
    sta     ATTACK_ACTIVE
    
    ;pointer settings
    sta     CHARPOS_L
    sta     COLORMAP_L
    
    ;values set to 1
    lda     #1
    sta     JOY1_DDRA
 	sta     CHAR_BASE
    
    ;map and graphic pointers
    sta     MAPX
    sta     MAPY
    
    lda     #7
    sta     PLAYERWEAPONDAMAGE
    
    ;reset delay
    lda     #10
    
    ;initial player 
    sta     PLAYERSPEED
    sta     COUNTDOWN
    
    lda     #MAX_HEALTH
    sta     PLAYERHEALTH
    
    lda     #MAX_LEVELS
    sta     HIGHEST_LEVEL
    
    ;set border character for first level
    lda     #23
    sta     CHAR_BORDER 
    
    ;initial volume
    lda     #$0f
    sta     VOLUME

    lda     #>BASE_SCREEN
    sta     CHARPOS_H
    lda     #>COLORMAP
    sta     COLORMAP_H

;==================================================================
; 
;

    ;set custom character set
    lda     #$ff
    sta     CHARSETSELECT
    
    jsr     drawBoard
    jsr     drawScreen
    lda     #CHAR_PLAYER_L
    jsr     spawn_char
    sty     PLAYERY
    stx     PLAYERX
    sta     CHARUNDERPLAYER

    ;jsr     wait_for_user_input

;==================================================================
; mainLoop
;

mainLoop:
mainLoop_continue:
        
    ;these events constantly running

    jsr     timer       ;timer returns countdown, branch if not 0

    jsr     playMusic
    jsr     playSound
    jsr     animateAttack
    
    lda     BOSS_ACTIVE
    bne     main_loop_move_cont

    ldx     #NUM_ENEMIES
main_loop_move_enemy:  
    jsr     moveEnemy
    dex
    bpl     main_loop_move_enemy

main_loop_move_cont:
    jsr     moveBoss
    lda     COUNTDOWN
    bne     mainLoop
    
    ;events related to timer only every 10/60 second change this as required
    lda     PLAYERSPEED
    sta     COUNTDOWN
    jsr     readJoy             ;player movement must be limited
   
    lda     GAMEOVER
    beq     mainLoop
    
    jsr     ending              ;play the ending
    lda     #0
    sta     GAMEOVER
    jmp     init
    
;==================================================================
; finished - cleanup and end
finished:
    ;lda     #$0
    ;sta     VOLUME
    
    ;lda     #240
    ;sta     CHARSETSELECT
    
    ;rts
;end of game

    include     "scroll_screen.asm"
    include     "graphics.asm"
    include     "toolkit.asm"
    include     "enemy.asm"
    include     "player.asm"
    include     "music.asm"

;===================================================================
; variable section
;
; these are here to prevent alignment issues
;

;title and ending text
;text limited to 255 chars long
title_text:
          dc.b    "WITCHER 0.3", $0d, $0d   
          dc.b    "BBQ SIDE QUEST",$0d,$0d
length_text:
          dc.b    "FIRE TO START", $00
          
ending_text:
          dc.b    "YOU WIN BUT YOUR", $0d
          dc.b    "STEAK IS RUINED!", $0d, $0d              
          dc.b    "THE END.", $00     
          
died_text:
          dc.b    "YOU DIED", $00
          


;map data - holds exit and other information
;note: maps are 22 screens wide and n tall
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
;upper bits:
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

;lower bits:
;f - spawn boss (do not spawn other enemies?)
;e 
; spawn enemies as normal <14 (can move this up or down if required just change code in graphics.asm
;c - draw river - vertical with bridge ; not implemented
;b - draw river - horiz with bridge ; not implemented
;a - draw lake ; not implemented
;9 - draw dungeon entrance
;8 - draw castle entrance
;7 - draw house/hut ; not implemented
;6 
;5 - spawn bbq ; removed only spawns with end boss
;4 - spawn key ; removed spawns with boss to save space
;3 - 
;2 - 
;1 - 
;0 - Spawn enemies as normal

;starts at top left of map, can partition into other areas, just adjust map position
; must be 22 wide for offset calculation to work (currently uses the screen dimensions for offset)

; if you alter the rows set the constan MAX_MAP_ROWS to be the same
map_data:
;          1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22
    hex     D0 90 50 D0 F0 F0 F0 90 10 50 F0 F0 90 10 10 10 50 90 30 30 30 50
    hex     C0 80 40 A0 30 30 30 00 20 20 30 30 40 80 60 80 60 C0 90 30 50 C0
    hex     A0 60 80 10 10 10 10 00 10 10 50 90 60 A0 50 A0 50 C0 C0 D0 C0 C0
    hex     90 50 A0 20 20 00 20 00 20 00 60 A0 50 90 60 90 60 C0 C0 C0 C0 C0
    hex     80 00 30 30 70 A0 30 60 B0 60 D0 F0 C0 A0 50 A0 50 80 40 C0 C0 C0
    hex     80 40 B0 30 50 90 30 30 10 70 80 30 40 90 60 90 60 C0 C0 C0 C0 C0
    hex     80 60 D0 D0 C0 80 50 F0 80 F0 E0 90 40 A0 50 A0 50 C0 C0 C0 C0 C0
    hex     C0 90 00 40 A0 00 60 B0 00 10 10 00 40 90 60 90 60 C0 A0 60 C0 C0
    hex     A0 00 40 A0 30 00 30 30 60 A0 00 20 60 E0 F0 80 50 A0 30 30 60 C0
    hex     F0 A0 20 30 70 A0 30 30 30 30 20 30 30 30 30 20 20 30 30 30 30 60
    ;hex    80 00 00 00 00 00 00 00 00 00 00 00 40 80 00 00 00 00 00 00 00 40;10
    ;hex    80 00 00 00 00 00 00 00 00 00 00 00 40 80 00 00 00 00 00 00 00 40;11
    ;hex    80 00 00 00 04 08 00 00 00 00 00 00 40 80 00 00 00 00 00 00 00 40;12
    ;hex    80 00 00 00 00 00 00 00 00 00 00 00 40 80 00 00 00 00 00 00 00 40;13
    ;hex    80 00 00 00 00 00 00 00 00 00 00 00 40 80 00 00 00 00 00 00 00 40;14
    ;hex    80 00 00 00 00 00 00 00 00 00 00 00 40 80 00 00 00 00 00 00 00 40;15

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
;lowest 3 bits are color info

char_color  hex 00 05 01 03 03 07 03 04 ;0-7
            hex 07 02 01 01 05 05 07 02 ;8-15
            hex 00 05 05 05 05 02 02 05 ;16-23
            hex 01 01 06 04 01 05 01 01 ;24-31
            hex 01 01 01 01 01 01 01 01 ;32-39;
            
            ;for enemies bits  6 and 7 (high) are for enemy difficulty calcluated as level + diffficulty so player health when hit is health-= level + 1 + difficulty
            ;bits 3,4,5 are for health and is calculated as base + 4 * health
            hex 02 01 02 06 fb fb fb fb ;40-47
            hex 01 4c 5e 57 8b 92 d2 d4 ;48-55
            hex 01 01 01 01 07 07 07 07 ;56-63
            
;must go last because the address is after all of this code
    include     "charset.asm"
