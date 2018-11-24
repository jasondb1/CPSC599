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
    
    ;compute move of enemy - a dumb goto the player ai
    ;TODO: smarter ai?
move_enemy_left:    
    lda     enemy_x,x
    cmp     PLAYERX
    bcc     move_enemy_right
    beq     move_enemy_down
    dec     enemy_x,x
    lda     #LEFT
    sta     TEMP11          ;stores direction
    jmp     move_enemy_cont
    
move_enemy_right: 
    inc     enemy_x,x
    lda     #RIGHT
    sta     TEMP11          ;stores direction
    jmp     move_enemy_cont
    
move_enemy_down: 
    lda     enemy_y,x
    cmp     PLAYERY
    bcs     move_enemy_up
    inc     enemy_y,x
    lda     #DOWN
    sta     TEMP11          ;stores direction
    bcc     move_enemy_cont
    
move_enemy_up: 
    lda     enemy_y,x
    cmp     PLAYERY
    bcc     move_enemy_cont
    lda     #UP
    sta     TEMP11          ;stores direction
    dec     enemy_y,x
    
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
    lda     enemy_move_clock,x  ;check if clock expired
    beq     move_boss_begin

move_boss_done:
    rts
    
    ldx     #NUM_ENEMIES
    stx     TEMP_ENEMYNUM
    
move_boss_begin:    
    ldx     TEMP_ENEMYNUM
    
    lda     enemy_speed,x        ;reset movement points
    sta     enemy_move_clock,x
    
    ;replace background tile under char
    lda     enemy_charunder,x
    jsr     enemy_draw_tile
    
    dex
    bpl     move_boss_begin
    
    ;compute move of enemy - a dumb goto the player ai
    ;TODO: smarter ai?
move_boss_left:   
    ldx     #0 
    lda     enemy_x,x
    cmp     PLAYERX
    bcc     move_boss_right
    beq     move_boss_down
    dec     enemy_x,x
    
    lda     #LEFT
    sta     TEMP11          ;stores direction
    jmp     move_boss_cont
    
move_boss_right: 
    inc     enemy_x,x
    lda     #RIGHT
    sta     TEMP11          ;stores direction
    jmp     move_boss_cont
    
move_boss_down: 
    lda     enemy_y,x
    cmp     PLAYERY
    bcs     move_boss_up
    inc     enemy_y,x
    lda     #DOWN
    sta     TEMP11          ;stores direction
    bcc     move_boss_cont
    
move_boss_up: 
    lda     enemy_y,x
    cmp     PLAYERY
    bcc     move_boss_cont
    lda     #UP
    sta     TEMP11          ;stores direction
    dec     enemy_y,x
    
move_boss_cont:
    
    
    ;collision check
    ;check what is under the enemy if > 16 then reload previous values in temp3 and temp2
    ldy     enemy_y,x
    lda     enemy_x,x
    tax
    jsr     get_char
    cmp     #WALKABLE
    bcc     move_boss_cont1
    
    ldx     TEMP_ENEMYNUM
    lda     TEMP3        ;restore last coordinates of enemy
    sta     enemy_x,x
    lda     TEMP2
    sta     enemy_y,x
    ;TODO: other collision stuff here
    
    ;bcs     move_boss_cont1

move_boss_cont1:
    ldx     TEMP_ENEMYNUM
    ;draw enemy in new position
    lda     enemy_type,x
    jsr     enemy_draw_tile

    
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
    ldx     #NUM_ENEMIES

inactivate_all_enemies_loop:
    sta     enemy_type,x    
    dex     
    bpl     inactivate_all_enemies_loop

    rts
