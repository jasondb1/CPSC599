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

ULX             equ $1      ;screen starts at 1,1
ULY             equ $1
LRX             equ 1+21
LRY             equ 1+20
CHAR_BLANK      equ #00
CHAR_BASE       equ #01
CHAR_PLAYER     equ #63
CHAR_PLAYER_L	equ #59

;enemy related
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

CHARPOS_L     equ $FB ; actual screen address of player keeps track of player 
CHARPOS_H     equ $FC ; and serves as a pointer where to place graphic character of player

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
PLAYERY         equ $0298 ;
PLAYERX         equ $0299 ;
PLAYERDIR		equ	$029a
TEMPVAR			equ $029b

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
    jsr     move_player_cont

mainLoop:
mainLoop_continue:
        
    ;these events constantly running
    jsr     timer
    jsr     moveEnemy
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

	;health bars
	lda		#19
	sta		SCREENSTATUS+4
	lda		#19
	sta		SCREENSTATUS+5
	lda		#19
	sta		SCREENSTATUS+6
	lda		#19
	sta		SCREENSTATUS+7
	lda		#19
	sta		SCREENSTATUS+8

	;money numbers
	lda		#30
	sta		SCREENSTATUS+26
	lda		#30
	sta		SCREENSTATUS+27

    lda     #RED
    sta     COLORMAPSTATUS+2
    lda     #YELLOW
    sta     COLORMAPSTATUS+24
	 
	;health bar colours
	lda		#RED
	sta		COLORMAPSTATUS+4
	lda		#YELLOW
	sta		COLORMAPSTATUS+5
	lda		#YELLOW
	sta		COLORMAPSTATUS+6
	lda		#YELLOW
	sta		COLORMAPSTATUS+7
	lda		#GREEN
	sta		COLORMAPSTATUS+8
    
    rts


;==================================================================
; drawBoard - draws the screen - not the play area

drawBoard:

;TODO - draw random background elements - rocks trees, paths, houses
    lda     #$1f
    sta     TEMP_PTR_H
    lda     #$97
    sta     COLORMAP_H
    ldy     #$00
    sty     TEMP_PTR_L
    sty     COLORMAP_L
    
    ldx     #$02
    stx     TEMP1
    ldy     #$cd 
    jmp     drawBoard_inner
drawBoard_outer:
    
    ldy     #$ff

drawBoard_inner:
    ;if random element then
    jsr     prand_newseed
    cmp     #3  ;5/255 chance of being a GRASS element
    bcs     drawBoard_rock
    lda     #4  ;TODO randomize what is drawn - these will be something in the first 8-10 characters
    jmp     drawBoard_to_screen

drawBoard_rock:
    jsr     prand_newseed
    cmp     #2  ;2/255 chance of being a ROCK element
    bcs     drawBoard_enemy_smol
    lda     #3
    jmp     drawBoard_to_screen

drawBoard_enemy_smol:
	jsr     prand_newseed
	cmp 	#2
    bcs     drawBoard_base_char
    lda     #53
    jmp     drawBoard_to_screen

drawBoard_base_char:
    lda     #CHAR_BASE
    
drawBoard_to_screen:   
    sta     (TEMP_PTR_L),y
    tax
    lda     char_color,x
    sta     (COLORMAP_L),y
    dey
    cpy     #$ff
    bne     drawBoard_inner
    
    dec     TEMP_PTR_H
    dec     COLORMAP_H
    dec     TEMP1 
    bne     drawBoard_outer

    jsr     spawnEnemy
    
;move_player_return: ;needed for movePlayer because subroutine is too long to jump to end
    rts
    
;==================================================================
; spawnEnemy - spawns enemies on each screen
; 

spawnEnemy:

    jsr     prand_newseed
    cmp     #254  ; change this 254/255 chance of enemy being spawned, maybe how many enemies are spawned
    bcs     spawnEnemy_end
    ;TODO randomize what enemy is spawned
    lda     #54
    sta     enemy1_type
    lda     #4
    sta     enemy1_y
    lda     #16
    sta     enemy1_x
    lda     #10
    sta     enemy1_health
    lda     #40
    sta     enemy1_speed
    sta     enemy1_move_clock
    
    jsr     move_enemy_cont ;place enemy on screen

spawnEnemy_end:
    rts
    
;TODO: for multiple enemies make this into a struct or array type 
enemy1_speed:         dc.b 00 ; x jiffys per move. An enemy can move once every x jiffys
enemy1_move_clock:    dc.b 00 ; the actual timer for the move, reset to speed after each move
enemy1_type:          dc.b 00
enemy1_health:        dc.b 00
enemy1_x:             dc.b 00        
enemy1_y:             dc.b 00
enemy1_charunder:     dc.b 00

;==================================================================
; moveEnemy - moves the player
; todo could use y register to be thee offset for multiple enemies

moveEnemy:

    lda     #0
    cmp     enemy1_move_clock
    bne     move_enemy_end
    
    lda     enemy1_speed        ;reset movement points
    sta     enemy1_move_clock

    pha
    jsr     isMoveValid ; or integrate into movements? collisions? 
    bcs     move_enemy_end
    
    ;determine if attack
    
    ;replace background tile under char
    ldy     enemy1_y
    ldx     enemy1_x
    lda     enemy1_charunder
    jsr     put_char

    pla
    
    ;compute move of enemy
    ;TODO: smarter ai?
move_enemy_left:    
    lda     enemy1_x
    cmp     PLAYERX
    bcc     move_enemy_right
    beq     move_enemy_down
    dec     enemy1_x
    jmp     move_enemy_cont
    
move_enemy_right: 
    inc     enemy1_x
    jmp     move_enemy_cont
    
move_enemy_down: 
    lda     enemy1_y
    cmp     PLAYERY
    bcs     move_enemy_up
    inc     enemy1_y
    jmp     move_enemy_cont
    
move_enemy_up: 
    lda     enemy1_y
    cmp     PLAYERY
    bcc     move_enemy_cont
    dec     enemy1_y
    
move_enemy_cont:

    ;draw enemy in new position
    ldy     enemy1_y
    ldx     enemy1_x
    lda     enemy1_type
    jsr     put_char
    sta     enemy1_charunder
    
    ;step sound
    lda     #$a0
    sta     VOICE1
    lda     #$2
    sta     V1DURATION

move_enemy_end:
    rts
    
;==================================================================
; movePlayer - moves the player
; x - direction to move player 0 - do not move., 8 - up, 4 -down, 2 - right, 1 - left

movePlayer:
    txa
    beq     move_player_end ;if no movement

    pha
    jsr     isMoveValid ; or integrate into movements? collisions?
    bcs     move_player_end


    ;TODO: get character under player to store and process if coin or other
    
    ;replace background tile under char
    ldy     PLAYERY
    ldx     PLAYERX
    lda     CHARUNDERPLAYER
    jsr     put_char

    pla
    
    ;compute move
    ;TODO: move player off screen if player is at edges, play sounds etc
move_player_left:    
    asl 
    bcc     move_player_right
    dec     PLAYERX
    sta 	TEMPVAR
    lda 	#$00
    sta 	PLAYERDIR
    lda 	TEMPVAR

move_player_right: 
    asl     
    bcc    	move_player_down
    inc    	PLAYERX
    sta 	TEMPVAR
    lda 	#$01
    sta 	PLAYERDIR
    lda 	TEMPVAR
    
move_player_down: 
    asl    
    bcc     move_player_up
    inc     PLAYERY
    
move_player_up: 
    asl     
    bcc     move_player_cont
    dec     PLAYERY
    
move_player_cont:

    ;draw player in new position
    ldy     PLAYERY
    ldx     PLAYERX

    lda 	PLAYERDIR
    cmp 	#$01

    bne 	move_player_direction_l
    lda 	#CHAR_PLAYER 				;facing right
    jmp 	move_player_direction_done

move_player_direction_l:
    lda     #CHAR_PLAYER_L 				;facing left

move_player_direction_done:
    jsr     put_char
    sta     CHARUNDERPLAYER
    
    ;step sound
    lda     #$a0
    sta     VOICE1
    lda     #$2
    sta     V1DURATION

    ;jsr update player status

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
; readJoy - read Joystick controller
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
; position_to_offset - converts rows and columns to offset
;
; a dumb multiplier essentially
;
; y - the row
; x - the col
;
; returns offset_low in a
;         offset_high in x
position_to_offset:
    
    dex
    stx     TEMP1   ;stores column
    lda     #$00
    tax             ; x will hold the offset_high
    
pto_loop:           ;multiply y by 22 (num of rows - 1)
    dey
    beq     pto_add_col
    clc
    adc     #SCRCOLS     
    bcc     pto_loop
    inx
    jmp     pto_loop 

pto_add_col:
    ; add x (column offset)
    clc
    adc     TEMP1       ;final result in accumulator  
    bcc     pto_end
    inx
    
pto_end:
    rts
    
;==================================================================
; put_char - puts character onto screen
; a- the character (0-63) to place on screen
; y - the row
; x - the col
;
; returns - previous character

put_char:
    pha
    lda     #<BASE_SCREEN
    sta     CHARPOS_L
    lda     #>BASE_SCREEN
    sta     CHARPOS_H
    
    jsr     position_to_offset ; return x is offset_high adder a - offset
    tay
    
    ;deal with high bit
    cpx     #$1
    bne     put_char_cont
    inc     CHARPOS_H         ; increment high if set
    
put_char_cont:
    ;color position
    lda     CHARPOS_L        
    sta     COLORMAP_L
    clc
    lda     CHARPOS_H
    adc     #120                ;distance between screenmap and colormap
    sta     COLORMAP_H
    
    ;store char under position
    lda     (CHARPOS_L),y
    sta     TEMP1
    
    ;draw character in new position
    pla       ; load the character
    tax
    sta     (CHARPOS_L),y    ; print next character to position
    lda     char_color,x
    sta     (COLORMAP_L),y 
    
    lda     TEMP1           ;return the previous character

    rts

;==================================================================
; get_char - puts character onto screen
; 
; y - the row
; x - the col
;
; returns - previous character

get_char:
 
    lda     #<BASE_SCREEN
    sta     CHARPOS_L
    lda     #>BASE_SCREEN
    sta     CHARPOS_H
    
    jsr     position_to_offset ; return x is offset_high adder a - offset
    tay
    
    ;deal with high bit
    cpx     #$1
    bne     put_char_cont
    inc     CHARPOS_H         ; increment high if set
    
get_char_cont:
    ;store char under position
    lda     (CHARPOS_L),y ;return character at y,x        

    rts    

;==================================================================
; mirror_char - mirrors the character in a and changes char in memory
;
; use to reverse direction of character
; 
; a - character
;

mirror_char:
    asl     ;multiply a by 8 to get offset
    asl
    asl
    
    lda     #<char_set  ;set character pointer
    sta     TEMP_PTR_L
    lda     #>char_set
    sta     TEMP_PTR_H
    lda     #$1
    sta     TEMP1
    ldy     #7

mc_loop_outer:              ;loop through each byte of character
    ldx     #7
    lda     (TEMP_PTR_L),y
    sta     TEMP2

mc_loop_inner:              ;loop through each bit of byte
    lsr     TEMP2
    bcs     mc_bitset
    asl
    jmp     mc_loop_inner_test

mc_bitset:
    asl
    ora     TEMP1
    
mc_loop_inner_test:    
    dex
    cpx     $ff
    bne     mc_loop_inner
    
    sta     (TEMP_PTR_L),y  ;store reversed byte into place
    dey
    cpy     $ff
    bne     mc_loop_outer

mc_end:
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
    dec     enemy1_move_clock;

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

;if space is required move this to cassette buffer or compact to 4 bit colors
char_color: dc.b 00, 05, 05, 01, 07, 07, 05, 05 ;0-7
            dc.b 00, 05, 05, 05, 05, 05, 05, 05 ;8-15
            dc.b 00, 05, 05, 05, 05, 05, 05, 05 ;16-23
            dc.b 00, 05, 05, 05, 05, 05, 07, 07 ;24-31
            dc.b 07, 07, 07, 07, 07, 07, 07, 07 ;32-39;
            dc.b 02, 07, 02, 05, 05, 05, 05, 05 ;40-47
            dc.b 00, 05, 05, 05, 05, 04, 04, 04 ;48-55
            dc.b 00, 05, 05, 07, 05, 01, 07, 07 ;56-63

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
    sta     PLAYERX
    sta     PLAYERY
    
    ;reset delay
    lda     #15 ;set countdown timer 15 jiffys (resolution 1 jiffy)
    sta     COUNTDOWN
    
    ;initial volume
    lda     #$0f
    sta     VOLUME
    
    clc
    jmp     init_return