    
;==================================================================
; movePlayer - moves the player
; x - direction to move player 0 - do not move., 8 - up, 4 -down, 2 - right, 1 - left

movePlayer:
    txa
    bne     move_player_start ;if no movement
    rts

move_player_start:
    pha    
    ;replace background tile under char
    ldy     PLAYERY
    ldx     PLAYERX
    sty     TEMP2       ;store previous values in case of collision restore
    stx     TEMP3
    
    lda     CHARUNDERPLAYER
    jsr     put_char
    pla
    
    ;compute move
move_player_left:    
    asl 
    bcc     move_player_right
    dec     PLAYERX
    ldy 	#LEFT
    sty 	PLAYERDIR
    
    ;check if player off screen, change map and reset player column
    ldy     #SCREENLEFT-1
    cpy     PLAYERX
    bne     move_player_right
    dec     MAPX
    ldy     #SCREENRIGHT
    sty     PLAYERX
    jmp     move_player_draw_board

move_player_right: 
    asl     
    bcc    	move_player_down
    inc    	PLAYERX
    ldy 	#RIGHT
    sty 	PLAYERDIR
    
    ;check if player off screen, change map and reset player column
    ldy     #SCREENRIGHT+1
    cpy     PLAYERX
    bne     move_player_down
    inc     MAPX
    ldy     #SCREENLEFT
    sty     PLAYERX
    jmp     move_player_draw_board
    
move_player_down: 
    asl    
    bcc     move_player_up
    inc     PLAYERY
    
    ;enable when implemented
    ;ldy 	#DOWN
    ;sty 	PLAYERDIR
    
    ;check if player off screen, change map and reset player row
    ldy     #SCREENBOTTOM+1
    cpy     PLAYERY
    bne     move_player_up
    inc     MAPY
    ldy     #SCREENTOP
    sty     PLAYERY
    jmp     move_player_draw_board
    
move_player_up: 
    asl     
    bcc     move_player_cont
    dec     PLAYERY
    
    ;enable when implemented
    ;ldy 	#UP
    ;sty 	PLAYERDIR
    
    ;check if player off screen, change map and reset player row
    ldy     #SCREENTOP-1
    cpy     PLAYERY
    bne     move_player_cont
    dec     MAPY
    ldy     #SCREENBOTTOM
    sty     PLAYERY

move_player_draw_board:
    jsr     drawBoard
    
move_player_cont:

    ;check what is under the player if > 16 then reload previous values in temp3 and temp2
    ldy     PLAYERY
    ldx     PLAYERX
    jsr     get_char
    cmp     #WALKABLE
    bcc     move_player_check_items
    lda     TEMP3        ;restore last coordinates of player
    sta     PLAYERX
    lda     TEMP2
    sta     PLAYERY
    bcs     move_player_draw_char
    
move_player_check_items:
    jsr     check_items

move_player_draw_char:
    ;draw player in new position
    ldy     PLAYERY
    ldx     PLAYERX

    lda 	PLAYERDIR
    asl
    bcs 	move_player_direction_l
    lda 	#CHAR_PLAYER_R				;facing right
    bcc 	move_player_direction_done

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

    jsr     update_status

move_player_end:
    rts


;==================================================================
; check_items - deals with items under the player
; a - the character under the player
;
check_items:
check_items_check_item1:
    ;is it the castle door?
    cmp     #10
    bne     check_items_item2
    
    ;TODO: check if player has key
    lda     PLAYERHASKEY
    beq     check_items_end
    dec     PLAYERHASKEY
    lda     #4
    sta     PLAYERX
    sta     PLAYERY
    lda     #MAP_START_LEVEL2_X
    sta     MAPX
    lda     #MAP_START_LEVEL2_Y
    sta     MAPY
    
    ; need to swap base tiles
    
    ;lda     #CHAR_BASE_CASTLE
    ;sta     CHAR_BASE
    lda     #CHAR_BORDER_CASTLE
    sta     CHAR_BORDER
    lda     #2  
    sta     char_color+1
    
    jsr     drawBoard           ;redraw the board
    jmp     check_items_end
    
check_items_item2:
    ;is it the dungeon door?
    cmp     #11
    bne     check_items_item3
    
    ;TODO: check if player has key
    lda     PLAYERHASKEY
    beq     check_items_end
    dec     PLAYERHASKEY
    lda     #4
    sta     PLAYERX
    sta     PLAYERY
    sta     char_color+1
    lda     #1
    sta     char_color+24
    
    lda     #MAP_START_LEVEL3_X
    sta     MAPX
    lda     #MAP_START_LEVEL3_Y
    sta     MAPY

    jsr     drawBoard           ;redraw the board
    jmp     check_items_end
    
check_items_item3:
    ;is it the key?
    cmp     #8
    bne     check_items_item4
    ;pick up key
    jsr     replace_base_char
    inc     PLAYERHASKEY
    
check_items_item4:
    ;found weapon
    cmp     #8
    bne     check_items_item5
    ;TODO: pickup weapon and increase/decrease damage
    
check_items_item5:
    ;found gold
    cmp     #14
    bne     check_items_item6
    jsr     add_gold_rand
    jsr     replace_base_char
    ;TODO: pickup gold and increase score
    
check_items_item6:
    ;found bbq
    cmp     #9
    bne     check_items_end
    ;Pickup BBQ
    lda     #1
    sta     GAMEOVER
    
check_items_end:
    rts


;==================================================================
; player_attack - performs attack
;
;
;
player_attack:

    lda     ATTACK_ACTIVE
    bne     player_attack_end
    ;get direction
    lda     PLAYERDIR
    asl
    bcs     player_attack_left
    asl
    bcs     player_attack_right
    
    ;TODO: implement down and up attack
player_attack_down:
player_attack_up:
player_attack_right:
    ldx     PLAYERX
    inx
    ldy     PLAYERY
    bne     player_attack_cont

player_attack_left:
    ldx     PLAYERX
    dex
    ldy     PLAYERY
    bne     player_attack_cont
    
player_attack_cont:
    stx     ATTACK_X
    sty     ATTACK_Y
    jsr     get_char        ;values must be between 44 and 55, could expand if required
    sta     ATTACK_CHARUNDER
    cmp     #56
    bcs     player_attack_miss
    cmp     #44
    bcs     player_attack_hit
    

player_attack_miss:
    jsr     activate_attack
    ;else miss    
    lda     #$f0        ;miss noise
    sta     VOICE1
    lda     #$04
    sta     V1DURATION
    
    lda     #CHAR_SWORD_R
    bcc     player_attack_cont1
    
player_attack_hit:
    tay                 ;store character underneath in 
    lda     #$e0        ;hit noise
    sta     NOISE
    lda     #$08
    sta     VNDURATION
    
    ;TODO: decide on damage and if enemy is killed or not
    ldx     ATTACK_X
    ldy     ATTACK_Y
    jsr     enemy_at


    
player_attack_enemy_killed:
    ;TODO: drop stuff? reduce health instead of just killing,  something else?
    lda     #$00            ;deactivate enemy
    sta     enemy_type,x
    
    inc     ENEMY_KILLED_L
    bne     player_attack_cont3
    inc     ENEMY_KILLED_H
    bne     player_attack_cont3
    
player_attack_cont2:
    ;enemy not killed
    jsr     activate_attack

player_attack_cont3:
    lda     #CHAR_SPLAT
    
player_attack_cont1:
    ldy     ATTACK_Y
    ldx     ATTACK_X
    jsr     put_char

player_attack_end:
    rts
    
;==================================================================
; activate_attack
;
;   common code for attack activation
;

activate_attack:
    inc     ATTACK_ACTIVE
    lda     #PLAYERSPEED
    lsr
    lsr
    sta     ATTACKDURATION
    rts

;==================================================================
; replace_base_char - replace character under player to base character
;
replace_base_char:
    lda     CHAR_BASE
    ldx     PLAYERX
    ldy     PLAYERY
    jsr     put_char
    
    rts

;==================================================================
; add_gold - adds an amount of gold to player
; note - use bcd numbers
;
; a - amount of gold 
;     or add random gold

add_gold_rand:
    jsr     prand
    and     #$07    ;each gold randomly worth up to 8
    adc     #1
    
add_gold:
    clc
    sed
    adc     PLAYERGOLD_L
    sta     PLAYERGOLD_L
    bcc     add_gold_end
    adc     PLAYERGOLD_H
    sta     PLAYERGOLD_H

add_gold_end:    
    cld
    rts
