
intro:

    ;clear screen
    lda     #$93
    jsr     CHROUT
    
    ;setup vetrical scroll from bottom
    lda     #$a0       ;position to the bottom of the screen
    sta     SCR_VER
    
    lda     #RED
    sta     646
    
    ;display text
    ldy     #00
intro_next_char:
    lda     title,y
    jsr     CHROUT
    iny
    cpy     #54
    bne     intro_next_char

intro_loop:       
    ;animation timer
    jsr     timer
    jsr     playNote ;if music is wanted for intro
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
    jsr     playNote ;if music is wanted for intro
    jsr     GETIN       ;keyboard input ends intro right now
    beq     intro_wait
    
intro_end:
    rts



