;==================================================================
; update_status - draws the health and gold status on the screen

update_status:

    ;key icon 
    lda     PLAYERHASKEY
    beq     update_status_cont1
    lda     #YELLOW
    bne     update_status_health
    
update_status_cont1:
    lda     #BLACK

update_status_health:     
    sta     COLORMAPSTATUS + 31
    ldy     #0
update_status_health_loop:
    tya     ;each section of health bar = 2 health
    asl 
    cmp     PLAYERHEALTH
    bcc     update_status_health_red
    lda     #BLACK
    bcs     update_status_health_cont
    
update_status_health_red:
    lda     #RED
    
update_status_health_cont:
    sta     COLORMAPSTATUS+35,y
    iny
    cpy     #10
    bne     update_status_health_loop

    ;display level
    clc
    lda     #30
    adc     LEVEL
    sta     SCREENSTATUS + 3
    lda     #PURPLE
    sta     COLORMAPSTATUS + 3
    
    ;display money
    lda     #YELLOW
    sta     COLORMAPSTATUS+24
    
    ldx     #4
    ldy     #23
    lda     PLAYERGOLD_H
    jsr     print_num
    
    ldx     #6
    ldy     #23
    lda     PLAYERGOLD_L
    jsr     print_num
    
    ;map position (for debugging) does not >9 correctly
    ;map x 
    ;clc
    ;lda     #30
    ;adc     MAPY
    ;sta     SCREENSTATUS+16
    
    ;lda     #30
    ;adc     MAPX
    ;sta     SCREENSTATUS+18
    
    rts
    
;==================================================================
; printNum - prints a 2 digit number to screen in bcd format
;
; a - the number to print
; y - the row to print
; x - the col to print to  
print_num:
    sty     TEMP10
    stx     TEMP11
    pha
    pha
    jsr    position_to_offset
    pla
    lsr
    lsr
    lsr
    lsr
    clc
    adc     #30         ;offset to digits in character memory
    ldy     TEMP10
    ldx     TEMP11
    jsr     put_char
    
    pla 
    and     #$0f
    clc
    adc     #30
    ldy     TEMP10
    ldx     TEMP11
    inx
    jsr     put_char  
    
    rts

;==================================================================
; drawScreen - draws the health and gold indicators
drawScreen:

;clear bottom 2 lines
    ldx     #44
drawScreen_loop
    lda     #CHAR_SOLID
    sta     SCREENSTATUS,x
    lda     #BLACK
    sta     COLORMAPSTATUS,x
    dex
    bne     drawScreen_loop
        
    ;draw all of the status indicators, but leave them black, color them in update status when
    ; they are active
    
    ;L
    lda     #40
    sta     SCREENSTATUS + 2
    lda     #PURPLE
    sta     COLORMAPSTATUS + 2
    
    ; key icon
    lda     #8
    sta     SCREENSTATUS + 31
        
    ;health indicator icon
    lda     #21
    sta     SCREENSTATUS+34
    
    ;color gold and health icons
    lda     #14
    sta     SCREENSTATUS+24
    lda     #RED
    sta     COLORMAPSTATUS+34
    
    jsr     update_status
    rts

;==================================================================
; drawBoard - draws the play area

drawBoard:

    jsr     inactivate_all_enemies
    jsr     get_map_tile
    
    sta     TEMP10      ;this holds map_data also used at end of subroutine
    ldy     CHAR_BASE
    ldx     CHAR_BORDER

;load character for border
drawBoard_border_left:
    lda     #$20
    bit     TEMP10      ;map data
    sty     BORDERLEFT
    bpl     drawBoard_border_right
    stx     BORDERLEFT

drawBoard_border_right:
    sty     BORDERRIGHT
    bvc     drawBoard_border_bottom
    stx     BORDERRIGHT

drawBoard_border_bottom: 
    sty     BORDERBOTTOM
    beq     drawBoard_border_top
    stx     BORDERBOTTOM

drawBoard_border_top:    
    sty     BORDERTOP
    lda     #$10
    bit     TEMP10
    beq     drawBoard_cont1
    stx     BORDERTOP

drawBoard_cont1:
    ;seed for each map sector so maps are consistent
    ldx     MAPX
    ldy     MAPY
    jsr     position_to_offset
    eor     #$6a
    sta     RANDSEED

    ;load screen and color pointers starts at lower right value of the screen and draws upward
    inc     CHARPOS_H
    inc     COLORMAP_H
     
    lda     #SCREENBOTTOM
    sta     TEMP21                 ;keeps track of row (for bottom and top borders)
    lda     #SCREENRIGHT
    sta     TEMP20                 ;count the columns (for detecting left/right borders)
    
    ldx     #$02            
    stx     TEMP1                  ;outer loop iterations
    ldy     #$cd 
    bne     drawBoard_inner

drawBoard_outer:
    ldy     #$ff
    dec     CHARPOS_H
    dec     COLORMAP_H
    
drawBoard_inner:
    
    ;test for borders
    lda     TEMP21              ;row
    cmp     #SCREENTOP + 3
    bcs     drawBoard_test_border_bottom
    
    ;if first 2 or last 2 cols - draw border pieces so all corners are borders
    lda     TEMP20              ;column
    cmp     #SCREENLEFT + 3 + CORNER_LENGTH
    bcs     drawBoard_test_border_top_cont
    lda     CHAR_BORDER
    bcc     drawBoard_to_screen

drawBoard_test_border_top_cont:
    cmp     #SCREENRIGHT - 2 - CORNER_LENGTH
    bcc     drawBoard_test_border_top_cont1
    lda     CHAR_BORDER
    bcs     drawBoard_to_screen
    
drawBoard_test_border_top_cont1:        
    lda     BORDERTOP
    bcc     drawBoard_to_screen
    
drawBoard_test_border_bottom:
    lda     TEMP21              ;row
    cmp     #SCREENBOTTOM - 2
    bcc     drawBoard_test_border_left
    ;if first 2 or last 2 cols - draw border
    lda     TEMP20              ;column
    cmp     #SCREENLEFT + 3 + CORNER_LENGTH
    bcs     drawBoard_test_border_bottom_cont
    lda     CHAR_BORDER
    bcc     drawBoard_to_screen

drawBoard_test_border_bottom_cont:
    cmp     #SCREENRIGHT - 2 - CORNER_LENGTH
    bcc     drawBoard_test_border_bottom_cont1
    lda     CHAR_BORDER
    bcs     drawBoard_to_screen
    
drawBoard_test_border_bottom_cont1:            
    lda     BORDERBOTTOM
    bcc     drawBoard_to_screen

drawBoard_test_border_left:
    lda     TEMP20
    cmp     #SCREENLEFT + 3 
    bcs     drawBoard_test_border_right
    lda     BORDERLEFT
    bcc     drawBoard_to_screen

drawBoard_test_border_right:    
    cmp     #SCREENRIGHT - 2 
    bcc     drawBoard_test_random_elements
    lda     BORDERRIGHT
    bcs     drawBoard_to_screen

drawBoard_test_random_elements:
    ;test for and draw random landscape element
    jsr     prand
    cmp     #6                      ;5/255 chance of being a landscape element
    bcs     drawBoard_base_char
    jsr     prand                   ;randomize which element is drawn
    ;jsr     prand
    and     #$07
    beq     drawBoard_base_char                  
    bne     drawBoard_to_screen

drawBoard_base_char:
    lda     CHAR_BASE
    
drawBoard_to_screen: 
    sta     (CHARPOS_L),y
    tax
    lda     char_color,x
    sta     (COLORMAP_L),y
    dec     TEMP20                  ;column
    bne     drawBoard_inner_cont
    
    ;if col reaches 0 then reset and dec row used for borders
    lda     #SCREENRIGHT
    sta     TEMP20                  ;column
    dec     TEMP21                  ;row

drawBoard_inner_cont:    
    dey
    cpy     #$ff
    bne     drawBoard_inner
    ;end of inner loop
    
    dec     TEMP1                   ;this is the counter for outer loop iterations
    beq     drawBoard_other
    jmp     drawBoard_outer
    ;end of outer loop
    
drawBoard_other:
    ;draw other board elements like castles houses, etc here
    lda     #$0f
    and     TEMP10                  ;map data only use high bits to determine what else is drawn
    sta     TEMP10                  ;map data
    
    cmp     #$0f
    bne     drawBoard_other_cont
    jsr     spawn_boss
    rts
    
drawBoard_other_cont:
    jsr     draw_other
    
drawBoard_enemies:
    jsr     prand
    ldx     #NUM_ENEMIES
drawBoard_end:  
    jsr     spawnEnemy
    dex
    bpl     drawBoard_end
    
    rts

;==================================================================
; draw_other - draws other elements on screen
; a- the lower bits of map data
;
; returns - nothing

draw_other:
    lda     TEMP10                          ; map data
    cmp     #$08                            ; draw castle entrance
    bne     draw_other_dungeon_door
    
    ldx     #$0a                            ; column
    ldy     #$0a                            ; row
    lda     #10                             ; castle door sprite (white)
    jsr     put_char
    jsr     draw_tower
    
draw_other_dungeon_door:
    lda     TEMP10                          ; map data
    cmp     #$09                            ; draw dungeon entrance
    bne     draw_other_gold 
     
    ldx     #$0a                            ; column
    ldy     #$0a                            ; row
    lda     #11                             ; dungeon door sprite (red)
    jsr     put_char
    jsr     draw_tower
    
draw_other_gold:
    jsr     prand
    cmp     #GOLD_CHANCE 
    bcs     draw_other_health
    lda     #14
    jsr     spawn_char
    
draw_other_health:
    jsr     prand
    cmp     #HEALTH_CHANCE 
    bcs     draw_other_end
    lda     #21
    jsr     spawn_char
    
    
draw_other_end:
    rts
    
    
draw_tower:
    ldx     #$0b                            ; column
    ldy     #$0a                            ; row
    lda     #25                             ; tower sprite (white)
    pha
    jsr     put_char
    
    ldx     #$09                            ; column
    ldy     #$0a                            ; row
    pla
    jsr     put_char
    
    rts
    
;==================================================================
; spawn_close - puts character onto screen in random location
; this routine is used to drop items from a defeated enemy
;
; a- the character (0-63) to place on screen 
;
; return
; x-  returns col
; y - returns row
;spawn_close:
;    pha
;    
;spawn_close_relocate:
;    jsr     prand 
;    and     #$03    ;change if required
;    adc     ATTACK_Y
;    sbc     #$1
;    beq     spawn_close_relocate    ; if 0
;    cmp     SCREENBOTTOM+1
;    bpl     spawn_close_relocate ;if off the bottom of screen
;    tay
;    sty     SPAWN_Y
;    
;    jsr     prand
;    and     #$03
;    adc     ATTACK_X
;    sbc     #$1
;    tax
;    stx     SPAWN_X
;    jsr     get_char        ;check if char under is < 8
;    cmp     #$08
;    bcs     spawn_close_relocate
;    bcc     spawn_char_at    
    
;==================================================================
; spawn_char - puts character onto screen in random location
; a- the character (0-63) to place on screen 
;
; return
; x-  returns col
; y - returns row

spawn_char:
    pha
    jsr     prand_newseed
    
spawn_char_relocate:
    jsr     prand
    and     #$0f            ;TODO can replace with prand_between
    adc     #$3
    tay
    sty     SPAWN_Y
    jsr     prand
    and     #$0f
    adc     #$3
    tax
    stx     SPAWN_X
    jsr     get_char        ;check if char under is < 8
    cmp     #$08
    bcs     spawn_char_relocate

;==================================================================
; cont'd from spawn_char 
; spawn_char_at - puts character at location y,x
; TOS (top of stack) the character to display
; y - row to place character
; x - col to place character

spawn_char_at:
    ldy     SPAWN_Y
    ldx     SPAWN_X
    pla
    jsr     put_char
    
    ldy     SPAWN_Y
    ldx     SPAWN_X


spawn_char_end:
    rts



;==================================================================
; put_char - puts character onto screen
; a- the character (0-63) to place on screen
; y - the row
; x - the col
;
; returns - previous character

put_char:
    and     #$7f               ; strip high bit of character
    pha 
    jsr     position_to_offset ; return x is offset_high adder a - offset
    
    ;deal with high bit
    stx     TEMP21
    cpx     #$1
    bne     put_char_cont
    inc     CHARPOS_H         ; increment high if set
    inc     COLORMAP_H
    
put_char_cont:
    
    ;store char under position
    lda     (CHARPOS_L),y
    sta     TEMP20
    
    ;draw character in new position
    pla                      ; load the character
    tax
    sta     (CHARPOS_L),y    ; print next character to position
    lda     char_color,x
    and     #$07             ; clear all but last 3 bits
    sta     (COLORMAP_L),y 
    
    ;restore CHARPOS_H and COLORMAP_H to point at start of buffer
    lda     TEMP21
    beq     put_char_end
    dec     CHARPOS_H
    dec     COLORMAP_H
    
put_char_end:    
    lda     TEMP20           ;return the previous character

    rts

;==================================================================
; get_char - puts character onto screen
; 
; y - the row
; x - the col
;
; returns - character at position

get_char:
    
    jsr     position_to_offset  ; return x is offset_high adder a - offset
    
    ;deal with high bit
    cpx     #$1
    bne     get_char_cont
    inc     CHARPOS_H           ; increment high if set
    
get_char_cont:
    ;store char under position
    lda     (CHARPOS_L),y ;return character at y,x        

    ;restore CHARPOS_H and COLORMAP_H
    cpx     #$1
    bne     get_char_end
    dec     CHARPOS_H
    
get_char_end:    
    rts    

;==================================================================
; animateAttack - resolve attack animations
animateAttack:

    lda     ATTACK_ACTIVE
    beq     animateAttack_enemy
    lda     ATTACKDURATION
    bne     animateAttack_enemy

    
    ;replace the character underneath the players attack
    lda     ATTACK_CHARUNDER
    ldx     ATTACK_X
    ldy     ATTACK_Y
    jsr     put_char
    dec     ATTACK_ACTIVE
    
animateAttack_enemy:
    lda     ENEMY_ATTACKDURATION
    bne     animateAttack_end
    lda     ENEMY_ATTACK_ACTIVE
    beq     animateAttack_end
   
    ;replace characters player sprite from hit/miss sprite
    lda     PLAYER_SPRITE_CURRENT
    ldx     PLAYERX
    ldy     PLAYERY
    jsr     put_char
    
    lda     #8
    sta     $900f
    
    dec     ENEMY_ATTACK_ACTIVE    


animateAttack_end:
    rts

;==================================================================
; new_level - generates new position for boss, exit, and player locations
;
new_level:

    
    ; CHANGE THE COLOR
    ; REMOVE THE CASTLE FROM THE CURRENT MAP
    jsr     clear_current_map_contents

    inc     LEVEL
    
    lda     LEVEL            ;BASE_HEALTH = 3 * level
    asl     
    clc
    adc     LEVEL   
    sta     BASE_HEALTH 
     ;empty map tile for 
    lda     #3
    sta     TEMP10 
    
;new_level_loop:
;    ;draw n number of bosses
;    jsr     find_empty_map_tile
;    lda     (MAP_PTR_L),y 
;    ora     #$0f             ;last 4 bytes will always be 0 because of find_empty_map_tile
;    sta     (MAP_PTR_L),y 
;    
;    ;draw n number of exits
;    jsr     find_empty_map_tile
;    lda     (MAP_PTR_L),y 
;    ora     #$08             ;last 4 bytes will always be 0 because of find_empty_map_tile
;    sta     (MAP_PTR_L),y 
;    
;    dec     TEMP10
;    bpl     new_level_loop
;    
;    ;set player starting position, stored in MAPX and MAPY
;    jsr     find_empty_map_tile
    
new_level_new_color:
    lda     LEVEL
    cmp     #1
    bne     new_level_new_color_2

    ldx     #PURPLE
    ldy     #YELLOW
    jmp     new_level_new_color_end

new_level_new_color_2:
    cmp     #2
    bne     new_level_new_color_3

    ldx     #BLUE
    ldy     #WHITE
    jmp     new_level_new_color_end

new_level_new_color_3:
    cmp     #3
    bne     new_level_new_color_4

    ldx     #RED
    ldy     #CYAN
    jmp     new_level_new_color_end

new_level_new_color_4:
    ldx     #BLACK
    ldy     #WHITE

new_level_new_color_end:
    stx     char_color+1            ;base tile
    sty     char_color+23

    rts

;==================================================================
; find_empty_map_tile - gets an empty map tile
; note; don't mess with the y value when between this call
; and when you use the map pointer
;
; sets map x, and map y
; offset is returned in y
;
find_empty_map_tile: 
    ;number between 1 and 22 inclusive
    jsr     prand
    and     #$0f    ;0-15
    sta     TEMP20
    jsr     prand
    and     #$07    ;0-7
    clc
    adc     TEMP20
    sta     MAPX
     
find_empty_map_tile_loop1:
    jsr     prand
    and     #$0f    ;0-15
    cmp     #MAX_MAP_ROWS + 1
    bcs     find_empty_map_tile_loop1
    sta     MAPY

    jsr     get_map_tile
    cmp     #$f0                    ; Borders on all sides, don't go here
    bcs     find_empty_map_tile
    and     #$0f
    bne     find_empty_map_tile
    
    rts

;==================================================================
; get_map_tile - gets the map pointer for MAPX, MAPY
; returns map offset in y
; returns tile value in a
;
get_map_tile:
    lda     #<map_data
    sta     MAP_PTR_L
    lda     #>map_data
    sta     MAP_PTR_H
    ldx     MAPX
    ldy     MAPY
    jsr     position_to_offset

    ;deal with high bit (add high bit offset to h)
    clc
    txa
    adc     MAP_PTR_H
    sta     MAP_PTR_H
    lda     (MAP_PTR_L),y

    rts
    
;==================================================================
; clear_map_tiles - clears everything off of the map except for borders
; returns map offset in y
; returns tile value in a
;
;clear_map_tiles:
;    lda     #MAX_MAP_ROWS
;    sta     MAPY
;
;clear_map_outer_loop:
;    lda     #22
;    sta     MAPX
;
;clear_map_inner_loop:
;    jsr     get_map_tile    ;this is slow, but small, and only happens on new level
;                            ;so will probably be acceptable
;    and     #$f0            ;clear bottom bits
;    sta     (MAP_PTR_L),y
;    
;    dec     MAPX
;    bne     clear_map_inner_loop
;    ;end inner loop
;    
;    dec     MAPY
;    bne     clear_map_outer_loop     
;    ;end outer loop
;    
;    rts
