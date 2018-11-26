;==================================================================
; spawnEnemy - spawns enemies on each screen
; 
; x is enemy number
;
; return x - enemy number

spawnEnemy:

    stx     TEMP_ENEMYNUM
    jsr     prand
    cmp     #SPAWN_CHANCE 
    bcc     spawn_enemy_begin
    lda     #$00
    sta     enemy_type,x
    bcs     spawnEnemy_end

spawn_enemy_begin:
    lda     #48                     ;character type of enemy
    ora     #$80                    ;high bit makes enemy active
    sta     enemy_type,x    
    jsr     spawn_char

spawn_enemy_update:
    pha
    txa
    ldx     TEMP_ENEMYNUM
    sta     enemy_x,x
    tya
    sta     enemy_y,x
    pla
    sta     enemy_charunder,x
    
    ;TODO; base health/strength and speed on some number
    lda     #10
    sta     enemy_health,x
    lda     #40
    sta     enemy_speed,x
    sta     enemy_move_clock,x

spawnEnemy_end:
    rts
 
 
;==================================================================
; spawn_boss - spawns a boss

spawn_boss:

    inc     BOSS_ACTIVE
    
    ldx     #0
    stx     TEMP_ENEMYNUM  
    
    ldy     #10
    sty     BOSS_UL_Y
    sty     BOSS_UR_Y
    iny
    sty     BOSS_LL_Y
    sty     BOSS_LR_Y
    
    ldy     #18
    sty     BOSS_UL_X
    sty     BOSS_LL_X
    iny
    sty     BOSS_UR_X
    sty     BOSS_LR_X
    
    lda     #44     ;character of boss
    ora     #$80
    sta     BOSS_CHAR    
    
     
        
spawn_boss_loop:

    lda     BOSS_CHAR
    sta     enemy_type,x  
    ldy     BOSS_UL_Y,x
    lda     BOSS_UL_X,x
    tax
    lda     BOSS_CHAR
    jsr     put_char
    
    pha
    ldx     TEMP_ENEMYNUM
    ldy     BOSS_UL_Y,x
    lda     BOSS_UL_X,x
    tax    
    pla 
        
    jsr     spawn_enemy_update
    
    inc     TEMP_ENEMYNUM
    inc     BOSS_CHAR
    
    ldx     TEMP_ENEMYNUM
    cpx     #4
    bcc     spawn_boss_loop
    
spawn_boss_end:
    rts

;==================================================================
; moveEnemy - moves the enemy
;
; x is offset of enemy 
;
; return x - enemy number

moveEnemy:
    
    lda     enemy_type,x        ;check if enemy active
    and     #$80
    beq     move_enemy_done             
    
    lda     enemy_move_clock,x  ;check if clock expired
    beq     move_enemy_begin

move_enemy_done:
    rts
    
move_enemy_begin:    
    stx     TEMP_ENEMYNUM
    lda     enemy_speed,x        ;reset movement points
    sta     enemy_move_clock,x
    
    ;TODO: determine if enemy attacks in collisions if close combat, or other if projectile)
    
    ;replace background tile under char
    lda     enemy_charunder,x
    jsr     enemy_draw_tile
    
    ;compute next move
    jsr     dir_to_player
    jsr     pick_move
    jsr     execute_move
    
move_enemy_cont:
    
    ;collision check
    ;check what is under the enemy if > 16 then reload previous values in temp3 and temp2
    ldy     enemy_y,x
    lda     enemy_x,x
    tax
    jsr     get_char
    cmp     #WALKABLE
    bcc     move_enemy_cont1
    
    ldx     TEMP_ENEMYNUM
    lda     TEMP3        ;restore last coordinates of enemy
    sta     enemy_x,x
    lda     TEMP2
    sta     enemy_y,x
    ;TODO: other collision stuff here
    
    ;bcs     move_enemy_cont1

move_enemy_cont1:
    ldx     TEMP_ENEMYNUM
    ;draw enemy in new position
    lda     enemy_type,x
    jsr     enemy_draw_tile

    
    ;step sound
    lda     #$a0
    sta     VOICE3
    lda     #$2
    sta     V3DURATION

move_enemy_end:
    rts
    
;==================================================================
; moveBoss - moves the enemy
;
; x is offset of enemy 
;
; return x - enemy number

moveBoss:
    
    lda     BOSS_ACTIVE  
    beq     move_boss_done
    ldx     #0
    lda     enemy_move_clock,x  ;check if clock expired
    beq     move_boss_begin

move_boss_done:
    rts
    
move_boss_begin:     
    ldx     #3
    stx     TEMP_ENEMYNUM
    
move_boss_loop0:    
    ;clears the area underneath the enemies
    ldx     TEMP_ENEMYNUM
    
    lda     enemy_speed,x        ;reset movement points
    sta     enemy_move_clock,x
    
    ;replace background tile under char
    lda     enemy_charunder,x
    jsr     enemy_draw_tile
    
    dec     TEMP_ENEMYNUM
    bpl     move_boss_loop0
    
    
    ;pick where enemy moves
    jsr     dir_to_player
    jsr     pick_move
    sta     TEMP11
    
    ldx     #3
move_boss_loop2:   
    lda     TEMP11
    jsr     execute_move
    
move_boss_cont2:
    dex
    bpl     move_boss_loop2
    
move_boss_cont:
    ldx     #0
    ;collision check
    ;check what is under the enemy if > 16 then reload previous values in temp3 and temp2
    ldy     enemy_y,x
    lda     enemy_x,x
    tax
    jsr     get_char
    cmp     #WALKABLE
    bcc     move_boss_cont1
    
    
    ;maybe if left unavailable move right up/dn etc instead of restore last
    ldx     TEMP_ENEMYNUM
    lda     TEMP3        ;restore last coordinates of enemy
    sta     enemy_x,x
    lda     TEMP2
    sta     enemy_y,x
    ;TODO: other collision stuff here
    
    ;bcs     move_boss_cont1
move_boss_cont1:
    ldx     #3
    stx     TEMP_ENEMYNUM
move_boss_loop1:
    ldx     TEMP_ENEMYNUM
    ;draw enemy in new position
    lda     enemy_type,x
    jsr     enemy_draw_tile
    
    dec     TEMP_ENEMYNUM
    bpl     move_boss_loop1
    
    ;step sound
    lda     #$a0
    sta     VOICE3
    lda     #$2
    sta     V3DURATION

move_boss_end:
    rts
    
    
;==================================================================
; enemy_draw_tile - draws a character tile at location of enemy x
;
; a is the character to draw
; x is enemy number
;
; return x - enemy number

enemy_draw_tile:

    pha
    ldy     enemy_y,x
    lda     enemy_x,x
    sty     TEMP2       ;store previous values in case of collision restore
    sta     TEMP3
    tax
    pla
    jsr     put_char
    ldx     TEMP_ENEMYNUM
    sta     enemy_charunder,x
    
    rts

;==================================================================
; enemy_at - returns the index of the enemy at row/col
;
; y is row
; x is col
;
; return x - enemy number returns $ff if not found 

enemy_at:
    stx     TEMP1
    
    ldx     #NUM_ENEMIES
enemy_at_loop:  
    lda     TEMP1
    cmp     enemy_x,x
    bne     enemy_at_cont
    tya
    cmp     enemy_y,x
    beq     enemy_at_end
    
enemy_at_cont:
    dex
    bpl    enemy_at_loop

enemy_at_end:
    rts
    
;==================================================================
; inactivate all_enemies
;
    
inactivate_all_enemies:

    lda     #00                     ;character type of enemy
    sta     BOSS_ACTIVE  
    ldx     #NUM_ENEMIES

inactivate_all_enemies_loop:
    sta     enemy_type,x    
    dex     
    bpl     inactivate_all_enemies_loop

    rts

;==================================================================
; dir_to_player - direction to player
; x - enemy number
;
; returns a - direction to move

dir_to_player:    
    lda     #0
    
    ldy     enemy_x,x
    cpy     PLAYERX
    bcc     dir_to_player_right
    beq     dir_to_player_down
    ora     #LEFT
    bcs     dir_to_player_down
    
dir_to_player_right: 
    ora     #RIGHT
    
dir_to_player_down: 
    ldy     enemy_y,x
    cpy     PLAYERY
    bcs     dir_to_player_up
    beq     dir_to_player_end
    ora     #DOWN
    bcc     dir_to_player_end
    
dir_to_player_up: 
    ora     #UP

dir_to_player_end:
    sta     DIRECTION_TO_PLAYER
    rts

;==================================================================
; pick move - determine move to take
; a - direction to move
;
; returns a - direction to move
pick_move:
    pha     ;push direction to stack
    lda     #$30 ; check bits 4 and 5
    beq     pick_move_end
    
    jsr     prand            ;randomly choose one direction to move
    bit     RANDSEED
    pla
    bvc     pick_move_cont
    and     #$c0             ;pick left or right
    bvs     pick_move_end

pick_move_cont:
    and     #$30             ;pick up/dn
    
pick_move_end:
    rts

;==================================================================
; pick move - determine move to take
; a - direction to move
; x - enemy to move
;
execute_move:
    asl     
    bcc     execute_move_right
    dec     enemy_x,x
    
execute_move_right:
    asl
    bcc     execute_move_down
    inc     enemy_x,x

execute_move_down:
    asl
    bcc     execute_move_up
    inc     enemy_y,x
    
execute_move_up:
    asl
    bcc     execute_move_end
    dec     enemy_y,x

execute_move_end:
    rts
