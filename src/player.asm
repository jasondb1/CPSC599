    
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
    sty     TEMP2       ;store previous values in case of collission restore
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
    dec     MAPY
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
    inc     MAPY
    ldy     #SCREENBOTTOM
    sty     PLAYERY

move_player_draw_board:
    jsr     drawBoard
    
move_player_cont:

    ;check what is under the player if > 16 then reload previous values in temp1 and temp2
    ldy     PLAYERY
    ldx     PLAYERX
    jsr     get_char
    cmp     #16
    bcc     move_player_check_item
    lda     TEMP3        ;restore last coordinates of player
    sta     PLAYERX
    lda     TEMP2
    sta     PLAYERY

move_player_check_item:
    ;check if coin or other
    

move_player_draw_char:
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

    jsr     update_status

move_player_end:
    rts
