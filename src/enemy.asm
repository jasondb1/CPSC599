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
    lda     #48
    ora     #$80                    ;high bit makes enemy active
    sta     enemy_type,x

    jsr     spawn_char
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
    pha
    ldy     enemy_y,x
    lda     enemy_x,x
    sty     TEMP2       ;store previous values in case of collision restore
    sta     TEMP3
    tax
    pla
    jsr     put_char
    ldx     TEMP_ENEMYNUM
    
    ;compute move of enemy - a dumb goto the player ai
    ;TODO: smarter ai?
move_enemy_left:    
    lda     enemy_x,x
    cmp     PLAYERX
    bcc     move_enemy_right
    beq     move_enemy_down
    dec     enemy_x,x
    jmp     move_enemy_cont
    
move_enemy_right: 
    inc     enemy_x,x
    jmp     move_enemy_cont
    
move_enemy_down: 
    lda     enemy_y,x
    cmp     PLAYERY
    bcs     move_enemy_up
    inc     enemy_y,x
    jmp     move_enemy_cont
    
move_enemy_up: 
    lda     enemy_y,x
    cmp     PLAYERY
    bcc     move_enemy_cont
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
    pha
    ldy     enemy_y,x
    lda     enemy_x,x
    tax
    pla
    jsr     put_char
    ldx     TEMP_ENEMYNUM
    sta     enemy_charunder,x
    
    ;step sound
    lda     #$a0
    sta     VOICE1
    lda     #$2
    sta     V1DURATION

move_enemy_end:
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
