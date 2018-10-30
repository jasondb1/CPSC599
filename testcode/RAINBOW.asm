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
BASE_SCREEN_B 	equ 7934
BASE_COLOR_B  	equ 38654

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
FIRST       equ $F7
SCREENPART  equ $F8
XOFFESET    equ $F9
NEWY	    equ $FA
OLDS  		equ $FB
COUNTDOWN  	equ $FC
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
	
setscreen:

	;clear screen
    lda     #$93
    jsr     CHROUT
    
    ;set border color
    lda     #0
    sta     $900f

    lda		#2
    sta 	TEMPY

	ldx		#00
	
screentop:
	
	lda		TEMPY
	cmp		#7
	bmi		skipresettop

	lda		#2
	sta 	TEMPY
	
skipresettop:

	lda		TEMPY
	sta		TEMPX
	dec		TEMPX
	lda		TEMPX
    sta     $900f
	
	lda		TEMPY
	sta		FIRST

	lda		TEMPY
	sta		BASE_COLOR_T,x
	
	lda		#127
	sta		BASE_SCREEN_T,x
	
	
	inc		TEMPY
	
	inx	
	cpx		#253
	
	bne		screentop	
	
screenbot:
	
	lda		TEMPY
	cmp		#7
	bmi		skipresetbot

	lda		#2
	sta 	TEMPY

skipresetbot:
	lda		TEMPY
	sta		BASE_COLOR_B,x
	
	lda		#127
	sta		BASE_SCREEN_B,x
	
	
	inc		TEMPY
	
	inx	
	cpx		#253
	
	bne		screenbot	

    lda		TEMPY
	cmp		#2
    bne		setTEMPY
	
	lda		#5

setTEMPY:
	sta		TEMPY
	
	lda		TEMPY
	cmp		FIRST
	bne		loop_kw
		
	inc		TEMPY
	
    
loop_kw:

	jsr     GETIN
	beq     loop_kw
	
	ldx		#00
	
	jmp		skipresettop
	

	

