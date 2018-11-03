
intro:
ending:
    lda     #240
    sta     CHARSETSELECT

    ;clear screen
    lda     #$93
    jsr     CHROUT
    
    ;setup vetrical scroll from bottom
    lda     #$a0       ;position to the bottom of the screen
    sta     SCR_VER
    
    lda     #RED
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
    
intro_display_text:
    sta     TEMP_PTR_L
    stx     TEMP_PTR_H

    jsr     display_text

intro_loop:       
    ;animation timer
    jsr     playNote ;if music is wanted for intro
    jsr     playSound
    jsr     timer
    lda     #$0
    cmp     COUNTDOWN
    bne     intro_loop
    
    ;events related to animation timer, smaller is faster
    lda     #4
    sta     COUNTDOWN
    
    ;move screen
    dec     SCR_VER
    lda     #$25        ;standard screen position
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



