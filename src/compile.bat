echo off
dasm game.asm
del test.prg
move a.out test.prg
.\test.prg