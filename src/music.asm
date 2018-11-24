
;           TABLE OF MUSICAL NOTES
;
; ------------------------------------------
; APPROX.                 APPROX.
;  NOTE       VALUE        NOTE       VALUE
; ------------------------------------------
;   C1         135          G          215
;   C#         143          G#         217
;   D          147          A          219
;   D#         151          A#         221
;   E          159          B          223
;   F          163          C3         225
;   F#         167          C#         227
;   G          175          D          228
;   G#         179          D#         229
;   A          183          E          231
;   A#         187          E#         232
;   B          191          F          233
;   C2         195          G          235
;   C#         199          G#         236
;   D          201          A          237
;   D#         203          A#         238
;   E          207          B          239
;   F          209          C4         240
;   F#         212          C#         241


; SPEAKER COMMANDS:    WHERE X CAN BE:      FUNCTION:
; -------------------------------------------------------
;   POKE 36878,X          0 to 15           sets volume
;   POKE 36874,X        128 to 255          plays tone
;   POKE 36875,X        128 to 255          plays tone
;   POKE 36876,X        128 to 255          plays tone
;   POKE 36877,X        128 to 255          plays "noise"


;melody is defined as 2 bytes byte 1 freq(note) and length byte 2
; 

;note index
;note: more data could be stored in bits 5-7 of duration
;duration is in number of jiffies
; using 64 jiffies per measure  - tentatively used 16 for quarter notes, 8 for 8th notes
; if slower tempo is required then need to increase durations

;Normal
melody:		dc.b 215, 191, 207, 191,  215, 191, 207, 191,  215, 191, 207, 191,  215, 191, 207, 191,		             215, 191, 207, 191,  215, 191, 207, 191,  225, 195, 207, 195,  223, 191, 207, 191,		             221, 187, 207, 187,  215, 187, 207, 187,  215, 187, 207, 187,  215, 187, 207, 187,		             215, 187, 207, 187,  215, 187, 207, 187,  221, 187, 207, 187,  223, 167, 191, 212, 255

duration:	dc.b   8,   8,   8,   8,    8,   8,   8,   8,    8,   8,   8,   8,    8,   8,   8,   8,	 	               8,   8,   8,   8,    8,   8,   8,   8,    8,   8,   8,   8,    8,   8,   8,   8,	 	               8,   8,   8,   8,    8,   8,   8,   8,    8,   8,   8,   8,    8,   8,   8,   8,	 	               8,   8,   8,   8,    8,   8,   8,   8,    8,   8,   8,   8,    8,   8,   8,   8, 255

;BASS
bMelody:	dc.b    0, 191,   0,   0, 195, 191,   0, 187,   0,   0, 167, 255
bDuration:   dc.b  32,  64,  64,  32,  32,  32,  32,  64,  64,  64,  32, 255


; APPROX.                 APPROX.
;  NOTE       VALUE        NOTE       VALUE
;   C1         135          G          215
;   C#         143          G#         217
;   D          147          A          219
;   D#         151          A#         221
;   E          159          B          223
;   F          163          C3         225
;   F#         167          C#         227
;   G          175          D          228
;   G#         179          D#         229
;   A          183          E          231
;   A#         187          E#         232
;   B          191          F          233
;   C2         195          G          235
;   C#         199          G#         236
;   D          201          A          237
;   D#         203          A#         238
;   E          207          B          239
;   F          209          C4         240
;   F#         212          C#         241

