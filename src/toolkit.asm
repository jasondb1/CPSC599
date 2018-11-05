;==================================================================
; timer - this is a 1 second countdown timer but can be altered
; note this only allows just over 4 seconds
; this should be modified as required
; 
; each jiffy is stored and on expiry 
;
; can use this for other game events as well as required
;
; return countdown

timer: 
    ;read timer value
    ;if > 60 then reset timer and reduce COUNTDOWN by 1
    ;otherwise see if a jiffy has elapsed and inc counter and note duration
    
    
    lda     PREVJIFFY
    cmp     JCLOCKL
    beq     timer_end
    inc     PREVJIFFY      
    dec     V2DURATION   ;  decrement duration of note each jiffy ;
    dec     V1DURATION    ; decrement duration of note each jiffy
    dec     V3DURATION    ; decrement duration of note each jiffy
    dec     VNDURATION    ; decrement duration of note each jiffy
    ldx     #NUM_ENEMIES  ; number of enemies
timer_enemies:    
    dec     enemy_move_clock,x
    dex
    cpx     #$ff
    bne     timer_enemies

resetTimer:
    dec     COUNTDOWN
    lda     COUNTDOWN

timer_end:
    rts  
    
    
;==================================================================
; playNote - play a note from melody, duration memory location

playNote:

    ;if duration >1 (jiffy) then return otherwise if ==1 silence if ==0 nextnote
    lda     #$01
    cmp     V2DURATION
    bmi     playNote_end
    beq     playNote_silence
    
    ;new note
    ldy     CURRENTNOTE
    lda     melody,y
    cmp     #$ff            ;ff is the terminator for the melody line
    bne     playNote_continue
    ldy     #$0
    sty     CURRENTNOTE     ;reset note to first note in melody
    lda     melody,y
    
playNote_continue:    
    sta     VOICE2
    lda     duration,y
    sta     V2DURATION
    inc     CURRENTNOTE; this is the note index
    rts

playNote_silence:   ;cuts off last jiffy, to provide separation of notes
    ldy     #$0
    stx     VOICE2

playNote_end:
    rts
    
;==================================================================
; playSound - play a currently running sound

playSound:

    ;voice 1
    lda     V1DURATION
    bne     playSound_noise
    sta     VOICE1
    
playSound_noise:
    lda     VNDURATION
    bne     playSound_end
    sta     NOISE
    
playSound_end:
    rts
    
;==================================================================
; readJoy - read Joystick controller
;
; return x - return joy position
;

readJoy:   
    ldx     #$00
    
test_fire:
    lda     #$20         ;test fire button
    bit     JOY1_REGA
    bne     test_right
    ;do something if fire
    
    lda     #$e0
    sta     NOISE
    lda     #$02
    sta     VNDURATION
    
test_right:    
    lda     #$7F
    sta     JOY1_DDRB
    lda     #$80        ;get joy1-right status
    bit     JOY1_REGB
    bne     test_left
    ldx     #RIGHT
    
test_left: 
    lda     #$ff
    sta     JOY1_DDRB   ;reset the bit in via#2 to not interfere with keyboard

    lda     #$10         ;test right button
    bit     JOY1_REGA
    bne     test_down
    ldx     #LEFT
    
test_down: 
    lda     #$08         ;test right button
    bit     JOY1_REGA
    bne     test_up
    ldx     #DOWN

test_up: 
    lda     #$04         ;test right button
    bit     JOY1_REGA
    bne     cont_rj
    ldx     #UP

cont_rj:
    jsr     movePlayer
    rts
        
;==================================================================
; position_to_offset - converts rows and columns to offset
;
; a dumb multiplier essentially
;
; y - the row
; x - the col
;
; returns offset_low in y and a
;         offset_high in x
position_to_offset:
    
    dex
    stx     TEMP_PTO   ;stores column
    lda     #$00
    tax             ; x will hold the offset_high
    
pto_loop:           ;multiply y by 22 (num of rows - 1)
    dey
    beq     pto_add_col
    clc
    adc     #SCRCOLS     
    bcc     pto_loop
    inx
    bcs     pto_loop 

pto_add_col:
    ; add x (column offset)
    clc
    adc     TEMP_PTO       ;final result in accumulator  
    bcc     pto_end
    inx
    
pto_end:
    tay
    rts
       
;==================================================================
; prand - simple linear feedback prng
; return prnad number in accumulator

prand_newseed:
    lda     JCLOCKL
    sta     RANDSEED

prand_not_zero:
    ;inc     RANDSEED
    

prand:
    lda     RANDSEED
    asl
    asl
    asl
    asl
    asl
    asl
    asl
    eor     RANDSEED
    sta     RANDSEED
    lsr
    lsr
    lsr
    lsr
    lsr
    eor     RANDSEED
    sta     RANDSEED
    asl
    asl
    asl
    eor     RANDSEED
    beq     prand_newseed

prand_end: 
    sta     RANDSEED
            
    rts
   

;==================================================================
; keyWait - Waits of any key to be pressed
    
;loop_kw:
;    jsr     GETIN
;    beq     loop_kw
;    rts
    
wait_fire:
    lda     #$20         ;test fire button
    bit     JOY1_REGA
    bne     wait_fire   
    rts

;==================================================================
; display_text - displays the text in TEMP_PTR_L
; strings are currently terminated with $00
; 
    
display_text:

    ldy     #00
display_text_next_char:
    lda     (TEMP_PTR_L),y
    beq     display_text_end
    jsr     CHROUT
    iny
    bne     display_text_next_char

display_text_end:
    rts
