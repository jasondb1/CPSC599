
intro:
ending:

    ;setup vetrical scroll from bottom
    lda     #$a0       ;position to the bottom of the screen
    sta     SCR_VER
    
    ;clear screen
    lda     #$93
    jsr     CHROUT
    
    lda     #RED        ;text color
    sta     646
    
    ;display text
    lda     GAMEOVER
    bne     intro_game_over
    lda     #<title_text
    ldx     #>title_text
    bne     intro_display_text

intro_game_over:
    cmp     #2              ;if gameover = 2 then game is won
    bne     intro_game_died
    lda     #<ending_text
    ldx     #>ending_text
    bne     intro_display_text
    
intro_game_died:
    lda     #<died_text
    ldx     #>died_text
 
;can display regular text on blank screen if desired here.
intro_display_text:
    sta     TEMP_PTR_L
    stx     TEMP_PTR_H

    lda     #240
    sta     CHARSETSELECT

    jsr     display_text

intro_loop:       
    ;animation timer
    jsr     playNote    ;if music is wanted for intro
    jsr     playSound
    jsr     timer
    lda     COUNTDOWN
    bne     intro_loop
    
    ;events related to animation timer, smaller is faster
    ;lda     #3
    lda     #1  ;for testing restore 
    sta     COUNTDOWN
    
    ;move screen
    dec     SCR_VER
    ldx     GAMEOVER
    beq     intro_loop_cont
    lda     #25
    bne     intro_loop_cont2
    
intro_loop_cont:    
    lda     #72        ;standard screen position
    ;cmp     SCR_VER    
intro_loop_cont2:
    cmp     SCR_VER       
    bne     intro_loop

;finished scroll

intro_wait:
    jsr wait_for_user_input
        
intro_end:
    lda     #25
    sta     SCR_VER
    rts



