;=================================================================
; 
; joytest.asm
;
; Author: Jason De Boer
;     ID: 30034428
;
;  Class: CPSC599.82
;
;
; compile:
;   dasm scroll.asm -oscroll.prg -v3 
;
; run on (vice) xvic emulator
;   xvic joytest.prg


    Processor 6502
    
;==================================================================
; Constants and Kernel Routines

CHROUT  equ $ffd2
CHRIN   equ $ffcf
GETIN   equ $ffe4 ;from keyb buffer
PLOT    equ $fff0 ;sets if carry is set 
SCNKEY  equ $ff9f
RDTIM   equ $ffde
SETTIM  equ $ffdb
STOP    equ $ffe1

CLOSE   equ $ffc3
OPEN    equ $ffc0
SAVE    equ $ffd8
LOAD    equ $ffd5

;==================================================================
;Colors
BLACK   equ 0
WHITE   equ 1
RED     equ 2
CYAN    equ 3
PURPLE  equ 4
GREEN   equ 5
BLUE    equ 6
YELLOW  equ 7

;===================================================================
; Defined Memory locations
BASE_SCREEN_T 	equ 7680  ;1e00
BASE_COLOR_T  	equ 38400
BASE_SCREEN_M 	equ 7812
BASE_COLOR_M  	equ 38532
BASE_SCREEN_B 	equ 7944
BASE_COLOR_B  	equ 38664

JOY1_DDRA    	equ $9113 ;
JOY1_REGA    	equ $9111 ;bit 2 - up, 3 -dn, 4 - left, 5 - fire - (via #1)
JOY1_DDRB    	equ $9122
JOY1_REGB    	equ $9120 ;bit 7 - rt - (via #2)
SCR_HOR      	equ $9000
SCR_VER      	equ $9001

;SCREENMAP    	equ $1e00
;COLORMAP    	equ $9600
UCASE       	equ $8000 ;- upper case character map
LCASE   		equ $8800 ;- lower case normal

JCLOCKL  		equ $00a2

TEXTLOCATION	equ 7748

KEYBIN			equ $CB

;===================================================================
; User Defined Memory locations
TEMP1       equ $F7
TEMP2       equ $F8
NEWX        equ $F9
NEWY	    equ $FA
OLDS  		equ $FB
OLDC	   	equ $FC
TEMPX  		equ $FD
TEMPY   	equ $FE


;possible to use for (basic fp and numeric area $57 - $70
;possible to use $4e-$53 (misc work area)
;#3f-42 - BASIC DATA address
;$26-2A product area for multiplication


    ;basic stub start
    org     $1001
    
    dc.w    basicEnd
    dc.w    1234
    dc.b    $9e, "4112", 0 ;4112 = 0x1010

basicEnd:    dc.w    0

    org     $1010
startMl:

	jsr		setscreen

	ldx		#$0A
	ldy		#$08
	lda		#$06
	sta		TEMP1
	stx		TEMPX				;TEMP X Y IS PLAYER X Y
	sty		TEMPY
	
newX:
	lda		TEMPX 				;load x value into accumulator
	adc		#$15   				;add 21 to it for each row up y = 3 = 3 rows up + 63
	sta     TEMPX  				;store new X
	dec		TEMPY
	lda		TEMPY
	cmp		TEMP1
	bne		newX   				;if all the y are out store x 
	ldx		TEMPX  				;LOAD new x in x register 
	stx 	TEMPX
	sty		TEMPY
	
	stx 	NEWX
	sty		NEWY
	
	lda		BASE_SCREEN_M,x
	sta		OLDS
	
	lda		BASE_COLOR_M,x
	sta		OLDC
	
	jsr		draw2
								; draws in correct position
;==================================================================
; readJoy - read Joystik controller
;
; ?sets JOY1_STATE  bit 5 -fire, 4 - left, 3 - right, 2 - down, 1 - up
; use bit 7 for fire latch? to detect double click
;
;

readJoy:   

loop_kw:
	jsr		SCNKEY
    jsr     GETIN
    beq     loop_kw
    
	ldx		TEMPX
	ldy		TEMPY
	
test_right:    
    lda     KEYBIN
    cmp		#$12					;KEYBIN = D
    bne     test_left
	stx		TEMPX
	sty		TEMPY
	inx
	stx		NEWX
	sty		NEWY
	
    jsr		drawcheck

test_left: 
    lda     KEYBIN
    cmp		#$11					;KEYBIN = A
    bne     test_down
    stx		TEMPX
	sty		TEMPY
	dex
	stx		NEWX
	sty		NEWY
	jsr		drawcheck
    
test_down: 
    lda     KEYBIN        
    cmp		#$1A		  			;KEYBIN = X
    bne     test_up
	stx		TEMPX
	sty		TEMPY
    dey	
	stx		NEWX
	sty		NEWY
	jsr		MCDOWN

test_up: 
	lda		KEYBIN
    cmp		#$09					;KEYBIN = W
	bne		nokey
	stx		TEMPX
	sty		TEMPY
	iny
	stx		NEWX
	sty		NEWY
	jsr		MCUP
	
nokey:	
	stx		TEMPX
	sty		TEMPY
	
	jsr		readJoy

MCUP:
	ldx		NEWX
	ldy		NEWY
	lda		NEWX  				;load x value into accumulator
	sbc		#$16  				;add 21 to it for each row up y = 3 = 3 rows up + 63
	sta     NEWX
	sty		NEWY
	jsr		drawcheck

MCDOWN:
	ldx		NEWX
	ldy		NEWY
	lda		NEWX  				;load x value into accumulator
	adc		#$15   				;add 21 to it for each row up y = 3 = 3 rows up + 63
	sta     NEWX
	sty		NEWY
	jsr		drawcheck
	
drawcheck:

	ldy		NEWY
		
	cpy		#$06				
	bmi		draw1
	cpy		#$06
	beq		draw1
	cpy		#$0C
	bmi		draw2
	cpy		#$0C
	beq		draw2
	cpy		#$17
	bmi		draw3
	
draw1:
	ldy		TEMPY				;currently existing y position
	ldx		TEMPX				;currently existing x position
	
	lda		OLDS				;draw previous location information before MC was there
	sta		BASE_SCREEN_T,x	
	
	lda		OLDC
	sta		BASE_COLOR_T,x
		
	ldy		NEWY				;load new x and y positions 
	ldx		NEWX
	
	lda		BASE_SCREEN_T,x		;store existing information for new locatoin to OLD
	sta		OLDS
	
	lda		BASE_COLOR_T,x
	sta		OLDC
	
	lda		#2					;draw MC in the new location
	sta		BASE_COLOR_T,x
	
	lda		#$41
	sta		BASE_SCREEN_T,x	

	stx		TEMPX				;store newX and newY as current in TMEP X and TMEPY
	sty		TEMPY

	jsr 	readJoy
	
draw2:
	ldy		TEMPY				;currentyl existing y position
	ldx		TEMPX				;currently existing x position
	
	lda		OLDS				;draw previous location information before MC was there
	sta		BASE_SCREEN_M,x	
	
	lda		OLDC
	sta		BASE_COLOR_M,x
		
	ldy		NEWY				;load new x and y positions 
	ldx		NEWX
	
	lda		BASE_SCREEN_M,x		;store existing information for new locatoin to OLD
	sta		OLDS
	
	lda		BASE_COLOR_M,x
	sta		OLDC
	
	lda		#2					;draw MC in the new location
	sta		BASE_COLOR_M,x
	
	lda		#$41
	sta		BASE_SCREEN_M,x	

	stx		TEMPX				;store newX and newY as current in TMEP X and TMEPY
	sty		TEMPY

	jsr 	readJoy
	
		
draw3:
	ldy		TEMPY				;currentyl existing y position
	ldx		TEMPX				;currently existing x position
	
	lda		OLDS				;draw previous location information before MC was there
	sta		BASE_SCREEN_B,x	
	
	lda		OLDC
	sta		BASE_COLOR_B,x
		
	ldy		NEWY				;load new x and y positions 
	ldx		NEWX
	
	lda		BASE_SCREEN_B,x		;store existing information for new locatoin to OLD
	sta		OLDS
	
	lda		BASE_COLOR_B,x
	sta		OLDC
	
	lda		#2					;draw MC in the new location
	sta		BASE_COLOR_B,x
	
	lda		#$41
	sta		BASE_SCREEN_B,x	

	stx		TEMPX				;store newX and newY as current in TMEP X and TMEPY
	sty		TEMPY

	jsr 	readJoy
	
	
;==================================================================
; setscreen - Sets start screen
	
setscreen:

	;clear screen
    lda     #$93
    jsr     CHROUT
    
    ;set border color
    lda     #8
    sta     $900f

	ldx		#00
screentop:
	lda		_colour_data_T,x
	sta		BASE_COLOR_T,x
	
	lda		_screen_data_T,x
	sta		BASE_SCREEN_T,x
	
	inx	
	cpx		#132
	
	bne		screentop
	
	ldx		#00
screenmid:
	lda		_colour_data_M,x
	sta		BASE_COLOR_M,x
	
	lda		_screen_data_M,x
	sta		BASE_SCREEN_M,x
	
	inx	
	cpx		#132
	
	bne		screenmid
	
	
	ldx		#00
screenbot:
	lda		_colour_data_B,x
	sta		BASE_COLOR_B,x
	
	lda		_screen_data_B,x
	sta		BASE_SCREEN_B,x
	
	inx	
	cpx		#242
	
	bne		screenbot	
	
	
	rts
	

_screen_data_T
	BYTE	$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$E6,$E6,$E6,$66,$66,$66,$66,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$E6,$E6,$E6,$66,$66,$66,$66,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$E6,$E6,$E6,$66,$66,$66,$66,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$66,$00,$00,$66,$66,$66,$E6,$E6,$E6,$66,$66,$66,$66,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$66,$00,$00,$66,$66,$66,$E6,$E6,$E6,$E6,$66,$66,$66,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$66,$66,$66,$66,$66,$66,$66,$66

_screen_data_M
	BYTE	$66,$66,$66,$66,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$66,$66,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$66,$66,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6
	BYTE	$66,$66,$66,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6
	BYTE	$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6

_screen_data_B
	BYTE	$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6
	BYTE	$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$66,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$66,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$66,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$66,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$66,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66
	BYTE	$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66

; Screen 1 -  Colour data
_colour_data_T
	BYTE	$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$0F,$0F,$0F,$05,$05,$05,$05,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$0F,$0F,$0F,$05,$05,$05,$05,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$0F,$0F,$0F,$05,$05,$05,$05,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$05,$00,$00,$05,$05,$05,$0F,$0F,$0F,$05,$05,$05,$05,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$05,$00,$00,$05,$05,$05,$0F,$0F,$0F,$0F,$05,$05,$05,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$05,$05,$05,$05,$05,$05,$05,$05

_colour_data_M	
	BYTE	$05,$05,$05,$05,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$05,$05,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$05,$05,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
	BYTE	$05,$05,$05,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
	BYTE	$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
	
_colour_data_B
	BYTE	$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
	BYTE	$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$05,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$05,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$05,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$05,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$05,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	BYTE	$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05

        
finished:
    rts

