


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
    jsr     prand
    and     #$07  
    clc                             ;spawn an enemy between 48 and 56
    adc     #48                     ;starting char of enemies
    ora     #$80                    ;high bit makes enemy active
    ldx     TEMP_ENEMYNUM
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
    lda     enemy_type,x    ;get offset
    and     #$7f
    tay
    lda     char_color,y
    pha
    and     #$38             ;isolate bits 3, 4, 5
    lsr                     ; the result is health * 4
    clc
    adc     BASE_HEALTH
    sta     enemy_health,x
    pla 
    and     #$c0            ;speed = 40 - level *2 - difficulty *2
    rol                     ;carry should still be cleared prior
    rol 
    rol
    rol
    sta     TEMP10
    lda     LEVEL
    asl 
    adc     TEMP10
    sta     TEMP10
    lda     #40
    sec
    sbc     TEMP10    
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
    jsr     enemy_begin_move

    ;compute next move
    jsr     dir_to_player
    jsr     pick_move
    sta     TEMP11
    jsr     execute_move

move_enemy_cont:
    
    ;collision check
    ;check what is under the enemy if > 16 then reload previous values in temp3 and temp2
    ldx     TEMP_ENEMYNUM
    jsr     enemy_check_new_character
    cmp     #WALKABLE
    bcc     move_enemy_cont1        ;is walkable 
    pha
    
    ;keep enemy at same position
    ldx     TEMP_ENEMYNUM
    lda     TEMP3                    ;restore last coordinates of enemy
    sta     enemy_x,x
    lda     TEMP2
    sta     enemy_y,x
    
    pla
    cmp     #60
    bcc     move_enemy_cont1
    
    jsr     enemy_attack

move_enemy_cont1:
    ;draw enemy in new position
    ldx     TEMP_ENEMYNUM
    lda     enemy_type,x
    jsr     enemy_draw_tile

    ;step sound
    jsr     sound_step
    
move_enemy_end:
    rts

;==================================================================
; check_new_character
;
; x - the enemy index to check
; returns a - the character underneath the enemies proposed move
; 
enemy_check_new_character:
    ldy     enemy_y,x
    sty     ENEMY_ATTACK_Y
    lda     enemy_x,x
    sta     ENEMY_ATTACK_X
    tax
    jsr     get_char
    
    rts
    
;==================================================================
; enemy_begin_move 
;
;
enemy_begin_move:
   ;reset movement points
    lda     enemy_speed,x 
    sta     enemy_move_clock,x
    
    ;replace background tile under char
    lda     enemy_charunder,x
    jsr     enemy_draw_tile
    
    rts 
    
;==================================================================
; enemy_begin_move - calculates the hit and damage an enemy does to player
;
; x needs to be attacking enemy index
;  
enemy_attack:
    ;check if enemy hits player    
    ;activate enemy attack if an attack is not already active
    lda     ENEMY_ATTACK_ACTIVE
    bne     enemy_attack_end
    inc     ENEMY_ATTACK_ACTIVE
    lda     #10                     ;could move this to a constant
    sta     ENEMY_ATTACKDURATION
    jsr     prand
    cmp     #CHANCE_TO_HIT
    bcc     enemy_attack_hit
    
enemy_attack_miss:
    ;code for miss   
    jsr     sound_miss
    
    lda     #CHAR_MISS
    bne     enemy_attack_cont
    
enemy_attack_hit:
    
    ;calculate the amount of damage and update player health
    lda     enemy_type,x
    and     #$7f
    tay
    lda     char_color,y
    and     #$c0        ;clear all other bits
    clc
    rol
    rol                 ;bit 7 is now in bit 1, bit 6 is in 0
    rol
    adc     LEVEL
    ;lsr                 ;/2 more fairness
    sta     TEMP10
    sec
    lda     PLAYERHEALTH
    sbc     TEMP10
    sta     PLAYERHEALTH
    bpl     enemy_attack_cont1
    inc     GAMEOVER
    
enemy_attack_cont1:
    lda     #10
    sta     $900f

    jsr     sound_hit
    lda     #CHAR_HIT
    
enemy_attack_cont:    
    ;put the attack miss or hit at the location of the character
;TODO: need to figure this out for boss attack both here and enemy_check_new_character
    ldx     ENEMY_ATTACK_X
    ldy     ENEMY_ATTACK_Y
    jsr     put_char
    jsr     update_status
    
enemy_attack_end:
    rts
    
;==================================================================
; moveBoss - moves the enemy
;
; stub that jumps to enemy move/attack routines if boss is active
;

moveBoss:
    
    lda     BOSS_ACTIVE  
    beq     enemy_attack_end        ;to keep branch within range
    ldx     #0
    stx     FLAG_BOSS_ATTACK
    stx     FLAG_INVALID_MOVE
    
    lda     enemy_move_clock,x       ;check if clock expired
    beq     move_boss_begin
    rts

move_boss_begin:   
    ldx     #3
    stx     TEMP_ENEMYNUM
    
move_boss_loop:    
    ;clears the area underneath the boss
    ldx     TEMP_ENEMYNUM
    jsr     enemy_begin_move
    dec     TEMP_ENEMYNUM
    bpl     move_boss_loop
    
    ;pick where enemy moves
    jsr     dir_to_player
    jsr     pick_move
    sta     TEMP_MOVE
    
    ldx     #3
    stx     TEMP_ENEMYNUM
move_boss_loop2:
    ldx     TEMP_ENEMYNUM
    lda     TEMP_MOVE
    jsr     execute_move
    
    ;check if offscreen
    ldy     enemy_x,x
    ;cpy     #SCREENLEFT-1      ;removed this equates to 0 in current configuration
    beq     move_boss_illegal_move
    cpy     #SCREENRIGHT+1
    beq     move_boss_illegal_move
    ldy     enemy_y,x
    ;cpy     #SCREENTOP-1        ;removed this equates to 0 in current config
    beq     move_boss_illegal_move
    cpy     SCREENBOTTOM+1
    beq     move_boss_illegal_move
    
    ;check if player under
    jsr     enemy_check_new_character
    cmp     #WALKABLE
    bcc     move_boss_cont2
    
    cmp     #60                 ;player character number
    bcc     move_boss_cont4
    ;set player X and Y
    ;do the attack right now
    inc     FLAG_INVALID_MOVE
    jsr     enemy_attack
    
    ;inc     FLAG_BOSS_ATTACK            ;temp var 2 is a flag to determine if boss attacks player

    bne     move_boss_cont2
    
move_boss_cont4:
    cmp     #44                 ;check if tile is a boss tile and ignore collision if true
    bcs     move_boss_cont2
move_boss_illegal_move:
    inc     FLAG_INVALID_MOVE            ;FLAG_INVALID_MOVE is set when boss cannot move to this location
    


move_boss_cont2:
    dec     TEMP_ENEMYNUM
    bpl     move_boss_loop2
    
move_boss_cont:
    lda     FLAG_INVALID_MOVE            ;do nothing if tiles are unobstructed
    beq     move_boss_cont1
    
    ;keep boss in same position
    ;reverse move if character is unable to move
    lda     TEMP_MOVE             ;note only one bit is set so testing for 1 in left or down
                                ;causes move to be reversed with a shift right
                                ; and when bits 6 or 4 are set will reverse with a shift left
    and     #$a0
    beq     move_boss_cont3
    lsr     TEMP_MOVE                ;reverses the move
    bne     move_boss_cont5       ; uncond branch
    
move_boss_cont3:
    asl     TEMP_MOVE
    
move_boss_cont5:
    ldx     #3 
    stx     TEMP_ENEMYNUM
move_boss_loop3:
    ldx     TEMP_ENEMYNUM
    lda     TEMP_MOVE
    jsr     execute_move
    
    dec     TEMP_ENEMYNUM
    bpl     move_boss_loop3

;draw all 4 tiles of enemy to the board
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
    
    jsr     sound_step

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
    sty     TEMP2       ;store previous values in case of collision restore in TEMP2 nd TEMP3
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

    lda     #00                     
    sta     BOSS_ACTIVE             ;reset boss to not active
    sta     ATTACK_ACTIVE
    sta     ENEMY_ATTACK_ACTIVE
    ldx     #NUM_ENEMIES

inactivate_all_enemies_loop:
    sta     enemy_type,x           ;store 0 to all enemies
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
    beq     dir_to_player_end
    bcs     dir_to_player_up
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
    pha
    and     #$30 ; check bits 4 and 5 if this is 0 only l/r applies
    bne     pick_move_choice
    pla
    rts

pick_move_choice:    
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
     
;==================================================================
; activate_attack (removed when boss combined with enemy move)
;
;   common code for attack activation
;

;enemy_activate_attack:
    ;inc     ENEMY_ATTACK_ACTIVE
    ;lda     #2                  ;could move this to a constant
    ;sta     ENEMY_ATTACKDURATION
    ;rts
    
    
;==================================================================
; erase_enemies - erases all enemies on screen
;                 and replace with splat
;
erase_boss:
    ldx     #3
    stx     TEMP_ENEMYNUM

erase_boss_loop:
    ldx     TEMP_ENEMYNUM
    lda     #CHAR_SPLAT
    jsr     enemy_draw_tile
    dec     TEMP_ENEMYNUM    
    bpl     erase_boss_loop

    rts
    
;==================================================================
; boss_killed - kills the boss
; 
boss_killed:
    jsr     inactivate_all_enemies
    jsr     erase_boss
    
    lda     LEVEL
    cmp     #4
    bne     boss_killed_drop_key
    lda     #9                          ;bbq end object
    bne     boss_killed_cont
    
boss_killed_drop_key:
    lda     #CHAR_KEY
    
boss_killed_cont:
    jsr     spawn_char

    ;spawn health and gold
    lda     #5
    sta     TEMP1
boss_killed_loop1:
    lda     #CHAR_HEALTH
    jsr     spawn_char
    lda     #CHAR_GOLD
    jsr     spawn_char
    dec     TEMP1
    bpl     boss_killed_loop1
    
    rts


;==================================================================
; boss_health_decrease
;
; x - boss
;
boss_health_decrease:
    lda     enemy_health,x
    
    ldx     #3
boss_health_decrease_loop:
    sta     enemy_health,x
    dex     
    bpl     boss_health_decrease_loop

    rts
