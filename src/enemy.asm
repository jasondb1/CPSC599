;==================================================================
; spawnEnemy - spawns enemies on each screen
; 
; x is enemy number
;

spawnEnemy:

    stx     TEMP_ENEMYNUM
    jsr     prand_newseed
    cmp     #SPAWN_CHANCE  ; change this 254/255 chance of enemy being spawned, maybe how many enemies are spawned
    bcs     spawnEnemy_end
    ;TODO randomize what enemy is spawned
    ldx     TEMP_ENEMYNUM
    
    ;TODO randomize where enemy is (never spawn on borders, check if char under is < 16
    lda     #54
    sta     enemy_type,x
    lda     #4
    sta     enemy_y,x
    lda     #16
    sta     enemy_x,x
    lda     #10
    sta     enemy_health,x
    lda     #40
    sta     enemy_speed,x
    sta     enemy_move_clock,x
    jsr     move_enemy_cont ;place enemy on screen

spawnEnemy_end:
    rts
    

;==================================================================
; moveEnemy - moves the enemy
;
; x is offset of enemy 

moveEnemy:

    stx     TEMP_ENEMYNUM
    
    lda     enemy_move_clock,x
    cmp     #0
    beq     move_enemy_begin
    rts
    
move_enemy_begin:    
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

    stx     TEMP_ENEMYNUM ; needed for spawn enemies calling subroutine here
    
    ;collision check
    ;check what is under the player if > 16 then reload previous values in temp3 and temp2
    ldy     enemy_y,x
    lda     enemy_x,x
    tax
    jsr     get_char
    cmp     #16
    bcc     move_enemy_cont1
    ldx     TEMP_ENEMYNUM
    lda     TEMP3        ;restore last coordinates of player
    sta     enemy_x,x
    lda     TEMP2
    sta     enemy_y,x
    ;TODO: other collision stuff here
    
    bcs     move_enemy_cont1

move_enemy_cont1:
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
