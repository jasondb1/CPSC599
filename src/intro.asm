
intro:

    ;clear screen
    lda     #$93
    jsr     CHROUT
    
    ;setup vetrical scroll from bottom
    lda     #$a0       ;position to the bottom of the screen
    sta     SCR_VER
    
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
    jsr     GETIN       ;keyboard input ends intro right now
    beq     intro_wait

   ;set custom character set
    lda     #$ff
    sta     CHARSETSELECT
    
    rts

    

title:    dc.b    "WITCHER 0.3", $0d, $0d   ;13
          dc.b    "P BOROWOY", $0d          ;10
          dc.b    "J DEBOER", $0d           ;9
          dc.b    "A MCALLISTER", $0d       ;13
          dc.b    "J WILSON", $0d           ;9 54 total chars



