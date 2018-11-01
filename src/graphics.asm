;==================================================================
; update_status - draws the status on the screen

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
; drawScreen - draws the screen - not the play area
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

    ldx     MAPX
    ldy     MAPY
    jsr     position_to_offset
    eor     #$6a
    sta     RANDSEED

;TODO - draw random background elements - rocks trees, paths, houses
    lda     #$1f
    sta     TEMP_PTR_H
    lda     #$97
    sta     COLORMAP_H
    ldy     #$00
    sty     TEMP_PTR_L
    sty     COLORMAP_L
    
    ldx     #$02            ;this code draws board from bottom offset to top
    stx     TEMP1
    ldy     #$cd 
    jmp     drawBoard_inner

drawBoard_outer:
    ldy     #$ff

drawBoard_inner:
    ;if random element then
    jsr     prand
    cmp     #3  ;5/255 chance of being a GRASS element
    bcs     drawBoard_rock
    lda     #4  ;TODO randomize what is drawn - these will be something in the first 8-10 characters
    jmp     drawBoard_to_screen

drawBoard_rock:
    jsr     prand
    cmp     #2  ;2/255 chance of being a ROCK element
    bcs     drawBoard_base_char
    lda     #3
    jmp     drawBoard_to_screen

;default background graphic
drawBoard_base_char:
    lda     #CHAR_BASE
    
drawBoard_to_screen:   
    sta     (TEMP_PTR_L),y
    tax
    lda     char_color,x
    sta     (COLORMAP_L),y
    dey
    cpy     #$ff
    bne     drawBoard_inner
    
    dec     TEMP_PTR_H
    dec     COLORMAP_H
    dec     TEMP1 
    bne     drawBoard_outer

    jsr     spawnEnemy
    
;move_player_return: ;needed for movePlayer because subroutine is too long to jump to end
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
    tay
    
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
    tay
    
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
