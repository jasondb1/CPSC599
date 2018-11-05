    
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
    ldy 	#$00
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
    ldy 	#$01
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
    cmp     #16
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
    beq 	move_player_direction_l
    lda 	#CHAR_PLAYER 				;facing right
    bne 	move_player_direction_done

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
; replace_base_char - replace character under player to base character
;
replace_base_char:
    lda     #CHAR_BASE
    ldx     PLAYERX
    ldy     PLAYERY
    jsr     put_char
    
    rts
