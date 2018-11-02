;==================================================================
; update_status - draws the health and gold status on the screen

update_status:
	;health bars
	lda		#19
	sta		SCREENSTATUS+4
	lda		#19
	sta		SCREENSTATUS+5
	lda		#19
	sta		SCREENSTATUS+6
	lda		#19
	sta		SCREENSTATUS+7
	lda		#19
	sta		SCREENSTATUS+8

	;money numbers
	lda		#30
	sta		SCREENSTATUS+26
	lda		#30
	sta		SCREENSTATUS+27

    lda     #RED
    sta     COLORMAPSTATUS+2
    lda     #YELLOW
    sta     COLORMAPSTATUS+24
	 
	;health bar colours
	lda		#RED
	sta		COLORMAPSTATUS+4
	lda		#YELLOW
	sta		COLORMAPSTATUS+5
	lda		#YELLOW
	sta		COLORMAPSTATUS+6
	lda		#YELLOW
	sta		COLORMAPSTATUS+7
	lda		#GREEN
	sta		COLORMAPSTATUS+8
    
    ;map position (for debugging)
    ;map x 
    clc
    lda     #30
    adc     MAPY
    sta     SCREENSTATUS+16
    
    lda     #30
    adc     MAPX
    sta     SCREENSTATUS+18
    
    rts

;==================================================================
; drawScreen - draws the health and gold indicators
drawScreen:

;clear bottom 2 lines
    ldx     #44
drawScreen_loop
    lda     #CHAR_BLANK
    sta     SCREENSTATUS,x
    dex
    bne     drawScreen_loop

    ;put health and coin indicator 
    lda     #40
    sta     SCREENSTATUS+2
    lda     #14
    sta     SCREENSTATUS+24
    rts

;==================================================================
; drawBoard - draws the play area

drawBoard:

   ;load map data
   ;TODO: could increment/decrement MAP_PTR in player when map moves
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
    sta     TEMP10      ;this holds map_data also used at end of subroutine
    ldy     #CHAR_BASE
    ldx     #CHAR_BORDER

;load character for border
drawBoard_border_left:
    lda     #$20
    bit     TEMP10
    sty     BORDERLEFT
    bne     drawBoard_border_right
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

    ;load screen and color pointers
    lda     #$1f
    sta     CHARPOS_H
    lda     #$97
    sta     COLORMAP_H
    ldy     #$00
    sty     CHARPOS_L
    sty     COLORMAP_L
    
    ;this code starts at lower right value of the screen and draws upward
    lda     #SCREENBOTTOM
    sta     TEMP21                  ;keeps track of row (for bottom and top borders)
    lda     #SCREENRIGHT
    sta     TEMP20                 ;count the columns (for detecting left/right borders)
    
    ldx     #$02            
    stx     TEMP1                   ;outer loop iterations
    ldy     #$cd 
    jmp     drawBoard_inner

drawBoard_outer:
    ldy     #$ff
    
drawBoard_inner:
    
    ;test for borders
    lda     TEMP21
    cmp     #SCREENTOP + 2
    bcs     drawBoard_test_border_bottom
    lda     BORDERTOP
    bcc     drawBoard_to_screen
    
drawBoard_test_border_bottom:
    ;lda     TEMP21
    cmp     #SCREENBOTTOM - 1
    bcc     drawBoard_test_border_left
    lda     BORDERBOTTOM
    bcs     drawBoard_to_screen

drawBoard_test_border_left:
    lda     TEMP20
    cmp     #SCREENLEFT + 2
    bcs     drawBoard_test_border_right
    lda     BORDERLEFT
    bcc     drawBoard_to_screen

drawBoard_test_border_right:    
    cmp     #SCREENRIGHT - 1
    bcc     drawBoard_test_random_elements
    lda     BORDERRIGHT
    bcs     drawBoard_to_screen

drawBoard_test_random_elements:
    ;test for and draw random landscape element
    jsr     prand
    cmp     #5                      ;5/255 chance of being a landscape element
    bcs     drawBoard_base_char
    jsr     prand                   ;randomize which element is drawn
    and     #06                     ; only allow characters 2-7 to be drawn
    jmp     drawBoard_to_screen

;default background graphic
drawBoard_base_char:
    lda     #CHAR_BASE
    
drawBoard_to_screen: 
    sta     (CHARPOS_L),y
    tax
    lda     char_color,x
    sta     (COLORMAP_L),y
    dec     TEMP20                  ;keep track of column
    bne     drawBoard_inner_cont
    ; if col reaches 0 then reset and dec row
    lda     #SCREENRIGHT
    sta     TEMP20
    dec     TEMP21

drawBoard_inner_cont:    
    dey
    cpy     #$ff
    bne     drawBoard_inner
    ;end of inner loop
    
    dec     CHARPOS_H
    dec     COLORMAP_H
    dec     TEMP1               ; this is the counter for outer loop iterations
    bne     drawBoard_outer
    ;end of outer loop
    
    ;draw other board elements like castles houses, etc here
    ;spawn enemies here
    jsr     spawnEnemy
    
    rts

;==================================================================
; put_char - puts character onto screen
; a- the character (0-63) to place on screen
; y - the row
; x - the col
;
; returns - previous character

put_char:
    pha
    lda     #<BASE_SCREEN
    sta     CHARPOS_L
    lda     #>BASE_SCREEN
    sta     CHARPOS_H
    
    jsr     position_to_offset ; return x is offset_high adder a - offset
    
    ;deal with high bit
    cpx     #$1
    bne     put_char_cont
    inc     CHARPOS_H         ; increment high if set
    
put_char_cont:
    ;color position
    lda     CHARPOS_L        
    sta     COLORMAP_L
    clc
    lda     CHARPOS_H
    adc     #120                ;distance between screenmap and colormap
    sta     COLORMAP_H
    
    ;store char under position
    lda     (CHARPOS_L),y
    sta     TEMP1
    
    ;draw character in new position
    pla       ; load the character
    tax
    sta     (CHARPOS_L),y    ; print next character to position
    lda     char_color,x
    sta     (COLORMAP_L),y 
    
    lda     TEMP1           ;return the previous character

    rts

;==================================================================
; get_char - puts character onto screen
; 
; y - the row
; x - the col
;
; returns - previous character

get_char:
 
    lda     #<BASE_SCREEN
    sta     CHARPOS_L
    lda     #>BASE_SCREEN
    sta     CHARPOS_H
    
    jsr     position_to_offset ; return x is offset_high adder a - offset
    
    ;deal with high bit
    cpx     #$1
    bne     get_char_cont
    inc     CHARPOS_H         ; increment high if set
    
get_char_cont:
    ;store char under position
    lda     (CHARPOS_L),y ;return character at y,x        

    rts    

;==================================================================
; mirror_char - mirrors the character in a and changes char in memory
;
; use to reverse direction of character
; 
; a - character
;

mirror_char:
    asl     ;multiply a by 8 to get offset
    asl
    asl
    
    lda     #<char_set  ;set character pointer
    sta     TEMP_PTR_L
    lda     #>char_set
    sta     TEMP_PTR_H
    lda     #$1
    sta     TEMP1
    ldy     #7

mc_loop_outer:              ;loop through each byte of character
    ldx     #7
    lda     (TEMP_PTR_L),y
    sta     TEMP2

mc_loop_inner:              ;loop through each bit of byte
    lsr     TEMP2
    bcs     mc_bitset
    asl
    jmp     mc_loop_inner_test

mc_bitset:
    asl
    ora     TEMP1
    
mc_loop_inner_test:    
    dex
    cpx     $ff
    bne     mc_loop_inner
    
    sta     (TEMP_PTR_L),y  ;store reversed byte into place
    dey
    cpy     $ff
    bne     mc_loop_outer

mc_end:
    rts