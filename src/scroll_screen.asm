
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
    jmp     intro_display_text

intro_game_over:
    lda     #<ending_text
    ldx     #>ending_text
 
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
    ;lda     #$0
    lda     COUNTDOWN
    bne     intro_loop
    
    ;events related to animation timer, smaller is faster
    lda     #3
    sta     COUNTDOWN
    
    ;move screen
    dec     SCR_VER
    lda     #$19        ;standard screen position
    cmp     SCR_VER       
    bne     intro_loop
    
;finished scroll

intro_wait:
    jsr     timer
    jsr     playNote   ;if music is wanted for intro
    lda     #$20       ;test fire button
    bit     JOY1_REGA
    bne     intro_wait
    
intro_end:
    rts



