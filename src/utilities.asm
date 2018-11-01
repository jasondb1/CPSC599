;==================================================================
; timer - this is a 1 second countdown timer but can be altered
; note this only allows just over 4 seconds
; this should be modified as required
; 
; each jiffy is stored and on expiry 
;
; can use this for other game events as well as required

timer: 
    ;read timer value
    ;if > 60 then reset timer and reduce COUNTDOWN by 1
    ;otherwise see if a jiffy has elapsed and inc counter and note duration
    
    lda     PREVJIFFY
    cmp     JCLOCKL
    beq     timer_continue  ; do nothing if a jiffy has not elapsed
    inc     PREVJIFFY      
    dec     V2DURATION   ;  decrement duration of note each jiffy ;
    dec     V1DURATION    ; decrement duration of note each jiffy
    dec     V3DURATION    ; decrement duration of note each jiffy
    dec     VNDURATION    ; decrement duration of note each jiffy
    ldx     #4
timer_enemies:    
    dec     enemy_move_clock,x
    dex
    bne     timer_enemies

timer_continue:
    lda     JCLOCKL
    cmp     TIMERRESOLUTION     ;1/60 of second is a jiffy so 60 is 1 second
    bpl     resetTimer  
    rts

resetTimer:
    dec     COUNTDOWN
    
    lda     #$00    ;set system clock to 0
    sta     JCLOCKL
    sta     PREVJIFFY
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
    ldy     #$00            ;reset note to first note in melody
    sty     CURRENTNOTE
    lda     melody,y
    
playNote_continue:    
    sta     VOICE2
    lda     duration,y
    sta     V2DURATION
    inc     CURRENTNOTE; this is the note index
    rts

playNote_silence:   ;cuts off last jiffy, to provide separation of notes
    lda     #$00
    sta     VOICE2

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
; ?sets JOY1_STATE  bit 5 -fire, 4 - left, 3 - right, 2 - down, 1 - up
; use bit 7 for fire latch? to detect double click
;
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
    ;do something if right
    ldx     #RIGHT
    
test_left: 
    lda     #$ff
    sta     JOY1_DDRB   ;reset the bit in via#2 to not interfere with keyboard

    lda     #$10         ;test right button
    bit     JOY1_REGA
    bne     test_down
    
    ;do something if left
    ldx     #LEFT
    
test_down: 
    lda     #$08         ;test right button
    bit     JOY1_REGA
    bne     test_up
    
    ;do something if down
    ldx     #DOWN

test_up: 
    lda     #$04         ;test right button
    bit     JOY1_REGA
    bne     cont_rj
    
    ;do something if up   
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
; returns offset_low in a
;         offset_high in x
position_to_offset:
    
    dex
    stx     TEMP1   ;stores column
    lda     #$00
    tax             ; x will hold the offset_high
    
pto_loop:           ;multiply y by 22 (num of rows - 1)
    dey
    beq     pto_add_col
    clc
    adc     #SCRCOLS     
    bcc     pto_loop
    inx
    jmp     pto_loop 

pto_add_col:
    ; add x (column offset)
    clc
    adc     TEMP1       ;final result in accumulator  
    bcc     pto_end
    inx
    
pto_end:
    rts
       

;==================================================================
; prand - simple linear feedback prng
; if more randomness is required seed with something related to player input
; return prnad number in accumulator
; A better generator may work better

;prand_newseed:
;    lda     JCLOCKL
;    adc     RANDSEED
;    sta     RANDSEED
;
;prand:
;    lda     RANDSEED
;    beq     doEor ;accounts for 0
;    asl
;    bcc     noEor
;doEor: 
;            eor #$1d
;noEor: 
;    sta     RANDSEED
;            
;    rts
    
prand_newseed:
    lda     JCLOCKL
    adc     RANDSEED
    sta     RANDSEED

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

prand_end: 
    sta     RANDSEED
            
    rts
   

;==================================================================
; keyWait - Waits of any key to be pressed
    
loop_kw:
    jsr     GETIN
    beq     loop_kw
    rts
