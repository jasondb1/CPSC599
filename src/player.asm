;==================================================================
; movePlayer - moves the player
; x - direction to move player 0 - do not move., 8 - up, 4 -down, 2 - right, 1 - left

movePlayer:
    txa
    bne     move_player_start ;if movement >0
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
    ldx     #CHAR_PLAYER_L
    stx     PLAYER_SPRITE_CURRENT
    dec     PLAYERX
    ldy     #LEFT
    sty     PLAYERDIR

    ;check if player off screen, change map and reset player column
    ldy     PLAYERX
    bne     move_player_right
    dec     MAPX
    ldy     #SCREENRIGHT
    sty     PLAYERX
    jmp     move_player_draw_board

move_player_right: 
    asl     
    bcc     move_player_down
    ldx     #CHAR_PLAYER_R
    stx     PLAYER_SPRITE_CURRENT
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
    ldx     #CHAR_PLAYER_D
    stx     PLAYER_SPRITE_CURRENT
    inc     PLAYERY

    ldy 	#DOWN
    sty 	PLAYERDIR
    
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
    ldx     #CHAR_PLAYER_U
    stx     PLAYER_SPRITE_CURRENT
    dec     PLAYERY
    
    ldy 	#UP
    sty 	PLAYERDIR
    
    ;check if player off screen, change map and reset player row
    ldy     PLAYERY
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
    lda     TEMP3                   ;restore last coordinates of player
    sta     PLAYERX
    lda     TEMP2
    sta     PLAYERY
    bcs     move_player_draw_char
    
move_player_check_items:
    jsr     check_items
    beq     move_player_end         ;when going through an exit do not redraw the player or an artifact is created
                                    
move_player_draw_char:
    ;draw player in new position
    ldy     PLAYERY
    ldx     PLAYERX
    lda     PLAYER_SPRITE_CURRENT
    jsr     put_char
    sta     CHARUNDERPLAYER

    jsr     update_status

move_player_end:
    rts

;==================================================================
; check_items - deals with items under the player
; a - the character under the player
check_items:

check_over_castle_door:
    ;is it the castle door?
    cmp     #10
    bne     check_over_dungeon_door
    
    ;check if player has key
    lda     PLAYERHASKEY
    beq     check_over_dungeon_door   
    dec     PLAYERHASKEY
    jsr     new_level
    jsr     drawBoard           ;redraw the board
    lda     #CHAR_PLAYER_L      ;spawn player location
     
    jsr     spawn_char

    sty     PLAYERY
    stx     PLAYERX
    sta     CHARUNDERPLAYER
    lda     #0
    
    rts
    
check_over_dungeon_door:
    cmp     #11                     ; Over the dungeon entrance
    bne     check_over_key

    lda     LEVEL                   ; Only enter dungeon on level 3

    cmp     #3                      
    bne     check_over_key

    jsr     new_level
    jsr     set_current_map_final_boss

    jsr     drawBoard           ;redraw the board
    lda     #CHAR_PLAYER_L      ;spawn player location

    ldx     #5
    ldy     #10
    stx     SPAWN_X
    sty     SPAWN_Y
    sty     PLAYERY
    stx     PLAYERX

    jsr     put_char

    sta     CHARUNDERPLAYER
    lda     #2
    ; Change the color of the final boss
    sta     char_color+44
    sta     char_color+45
    sta     char_color+46
    sta     char_color+47

    lda     #0
    rts

check_over_key:
    ;is it the key?
    cmp     #8
    bne     check_over_gold
    ;pick up key
    jsr     replace_base_char
    inc     PLAYERHASKEY
  
check_over_gold:
    ;found gold
    cmp     #14
    bne     check_over_bbq
    jsr     add_gold_rand
    jsr     replace_base_char
    
check_over_bbq:
    ;found bbq
    cmp     #9
    bne     check_over_health
    ;Pickup BBQ
    lda     #2                                  ;win condition
    sta     GAMEOVER
    
check_over_health:
    ;found health
    cmp     #21
    bne     check_items_end
    jsr     replace_base_char
    inc     PLAYERHEALTH  
    inc     PLAYERHEALTH
    lda     #MAX_HEALTH
    cmp     PLAYERHEALTH
    bcs     check_items_sound
    sta     PLAYERHEALTH
    bne     check_items_sound
    
check_items_end:
    cmp     #8
    bcc     check_items_end1
    cmp     #15
    beq     check_items_end1
    
check_items_sound:
    lda     #$f8                                ;pickup item noise
    sta     VOICE3
    lda     #$05
    sta     V3DURATION
    rts
    
check_items_end1:
    ;step sound
    jsr     sound_step
    rts
    

;==================================================================
; player_attack - performs attack
player_attack:

    lda     ATTACK_ACTIVE
    bne     player_attack_skip
    lda     PLAYERDIR
    ldx     PLAYERX
    ldy     PLAYERY
    
    asl
    bcs     player_attack_left
    asl
    bcs     player_attack_right
    asl
    bcs     player_attack_down
    asl
    bcs     player_attack_up
    
player_attack_skip:
    rts

player_attack_right:
    inx
    bne     player_attack_cont

player_attack_left:
    dex
    bne     player_attack_cont
    
player_attack_down:
    iny
    bne     player_attack_cont

player_attack_up:
    dey


player_attack_cont:
    txa
    cmp     #SCREENLEFT
    bcc     player_attack_end
    cmp     #SCREENRIGHT+1
    bcs     player_attack_end
    tya
    cmp     #SCREENTOP
    bcc     player_attack_end
    cmp     #SCREENBOTTOM+1
    bcs     player_attack_end

    stx     ATTACK_X
    sty     ATTACK_Y
    jsr     get_char                    ;values must be between 44 and 55, could expand if required
    sta     ATTACK_CHARUNDER
    cmp     #44
    bcs     player_attack_hit
    

player_attack_miss:
    jsr     activate_attack
    ;else miss    
    jsr     sound_miss

    lda     PLAYER_SPRITE_CURRENT       ;animate with sword sprite the miss player sprite and sword are always 4 apart
    sec
    sbc     #4                       
    bcs     player_attack_cont1
    
player_attack_hit:
    jsr     sound_hit
        
    ldx     ATTACK_X
    ldy     ATTACK_Y
    jsr     enemy_at
    
    ;subtract damage from enemy
    lda     enemy_health,x
    sbc     PLAYERWEAPONDAMAGE
    sta     enemy_health,x
    bmi     player_attack_enemy_killed
    
    lda     BOSS_ACTIVE
    beq     player_attack_cont2
    jsr     boss_health_decrease
    
player_attack_cont2:
    jsr     activate_attack
    lda     #CHAR_HIT
    bne     player_attack_cont1
    
player_attack_enemy_killed:
    lda     BOSS_ACTIVE
    beq     player_attack_cont4
    jsr     boss_killed

    ; KILLED THE BOSS HERE
    ; Write 0 to the lower byte of map[PLAYERX, PLAYERY]
    jsr     set_current_map_key_dropped

    rts

player_attack_cont4:
    lda     #$00                            ;deactivate enemy
    sta     enemy_type,x

    ;this counts the stats of number of enemies killed (delete if not used)
    inc     ENEMY_KILLED_L
    bne     player_attack_cont3
    inc     ENEMY_KILLED_H

player_attack_cont3:
    ;drop stuff
    lda     #CHAR_GOLD
    jsr     spawn_char
    
    lda     #0
    sta     ATTACK_ACTIVE
    ;put splat on screen
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
