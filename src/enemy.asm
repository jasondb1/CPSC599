;==================================================================
; spawnEnemy - spawns enemies on each screen
; 
; x is enemy number
;

spawnEnemy:

    jsr     prand_newseed
    cmp     #254  ; change this 254/255 chance of enemy being spawned, maybe how many enemies are spawned
    bcs     spawnEnemy_end
    ;TODO randomize what enemy is spawned
    ldx     #0          ; hard code in enemy 0 right now TODO: use x from parameters
    
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
; moveEnemy - moves the player
; todo could use y register to be thee offset for multiple enemies
; x is offset of enemy 

moveEnemy:

    ldx     #0 ;TODO: use parameter instead of hardcoded enemy
    stx     TEMP1
    
    lda     enemy_move_clock,x
    cmp     #0
    bne     move_enemy_end
    
    lda     enemy_speed,x        ;reset movement points
    sta     enemy_move_clock,x

    pha
    ;jsr     isMoveValid ; or integrate into movements? collisions? 
    ;bcs     move_enemy_end
    
    ;determine if attack
    
    ;replace background tile under char
    lda     enemy_charunder,x
    pha
    ldy     enemy_y,x
    lda     enemy_x,x
    tax
    pla
    jsr     put_char

    pla
    ldx     TEMP1
    
    ;compute move of enemy
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
    stx     TEMP1; needed for spawn enemies calling subroutine here here
    ;draw enemy in new position
    lda     enemy_type,x
    pha
    ldy     enemy_y,x
    lda     enemy_x,x
    tax
    pla
    jsr     put_char
    ldx     TEMP1
    sta     enemy_charunder,x
    
    ;step sound
    lda     #$a0
    sta     VOICE1
    lda     #$2
    sta     V1DURATION

move_enemy_end:
    rts
