	org	$1c00
	
char_set:
	;TODO: swap out base charset for different levels?
	
	;chars under 16 can be walked over/on
	hex 00 00 00 00 00 00 00 00 ;0 - blank
	hex 00 10 00 40 04 00 02 00 ;1 - base landscape
	
	; 2 through 7 can be randomly generated
	hex	3e 6b 7f 6f 36 0c 14 3a ;2 - tree? maybe not necessary with tree border
	hex	00 00 42 18 18 38 6c b4 ;3 - rock
	hex	00 00 00 00 00 00 54 38 ;4 - grass
	hex 00 00 00 00 00 00 00 00 ;5 - stump?
	hex 00 00 00 00 00 00 00 00 ;6 - sign?
	hex 00 00 00 00 00 00 00 00 ;7 - vines?
	
	;other landscape that can be walked on but might have action associated 
	hex 18 24 24 18 08 38 08 38 ;8 - key
    hex 00 52 29 52 29 ff ff 42 ;9 - bbq
	hex 00 18 3c 7e 7e 7e 7e 7e ;10 - door
	hex 00 18 3c 7e 7e 7e 7e 7e ;11 - dungeon door
	hex aa 55 aa 55 aa 55 aa 55 ;12 - 
	hex aa 55 aa 55 aa 55 aa 55 ;13 - 
	hex 00 3c 7e 7e 7e 7e 3c 00 ;14 - coin
	hex aa 55 aa 55 aa 55 aa 55 ;15 - path?
	hex	00 00 00 ff ff 00 00 00 ;16 - horiz line
	hex	18 18 18 18 18 18 18 18 ;17 - vert line
	hex 18 18 3c e7 e7 3c 18 18 ;18 - corner
	hex ff ff ff ff ff ff ff ff ;19 - solid
	hex	3e 6b 7f 6f 36 0c 14 3a ;20 - tree (border element)
	hex aa 55 aa 55 aa 55 aa 55 ;21 - castle tower
	hex aa 55 aa 55 aa 55 aa 55 ;22 - flag?
	hex aa 55 aa 55 aa 55 aa 55 ;23
	hex aa 55 aa 55 aa 55 aa 55 ;24
	hex aa 55 aa 55 aa 55 aa 55 ;25
	hex aa 55 aa 55 aa 55 aa 55 ;26
	hex aa 55 aa 55 aa 55 aa 55 ;27
	hex aa 55 aa 55 aa 55 aa 55 ;28
	hex aa 55 aa 55 aa 55 aa 55 ;29
	hex 3c 42 46 5a 62 42 3c 00 ;30 - 0
	hex 08 18 28 08 08 08 3e 00 ;31 - 1
	hex 3c 42 02 0c 30 40 7e 00 ;32 - 2
	hex 3c 42 02 1c 02 42 3c 00 ;33 - 3
	hex 04 0c 14 24 7e 04 04 00 ;34 - 4
	hex 7e 40 78 04 02 44 38 00 ;35 - 5
	hex 1c 20 40 7c 42 42 3c 00 ;36 - 6
	hex 7e 42 04 08 10 10 10 00 ;37 - 7
	hex 3c 42 42 3c 42 42 3c 00 ;38 - 8
	hex 3c 42 42 3e 02 04 38 00 ;39 - 9
	hex 00 18 18 7e 7e 18 18 00 ;40 - +
	hex 00 00 00 00 00 00 00 00 ;41 - 
	hex 09 a2 2c 7c 5e 76 3c 84 ;42 - splat (when char hit?)
	hex aa 55 aa 55 aa 55 aa 55 ;43
	hex aa 55 aa 55 aa 55 aa 55 ;44
	hex aa 55 aa 55 aa 55 aa 55 ;45
	hex aa 55 aa 55 aa 55 aa 55 ;46
	hex aa 55 aa 55 aa 55 aa 55 ;47
	hex aa 55 aa 55 aa 55 aa 55 ;48
	hex aa 55 aa 55 aa 55 aa 55 ;49
	hex aa 55 aa 55 aa 55 aa 55 ;50
	hex aa 55 aa 55 aa 55 aa 55 ;51
	hex aa 55 aa 55 aa 55 aa 55 ;52
	hex 42 24 5a 3c 3c da 1a 24 ;53 - small creature
	hex 80 98 a4 db f7 5b 18 34 ;54 - swordsman
	hex 00 00 10 38 7f dd fe 0d ;55 - griffen ul
	hex 04 1a 3e d6 bc 58 b0 50 ;56 - griffen ur
	hex 4f 3f 58 33 12 01 00 00 ;57 - griffen ll
	hex b0 f8 9c 5e 6b 91 60 00 ;58 - griffen lr
	hex 18 2e 18 bc 5a 14 2a 36 ;59 - char 1 hero char left
	hex 18 24 24 3c 5a 3c 7e 14 ;60 - princess
	hex 00 00 40 7c f8 40 00 00 ;61 - sword
	hex 18 24 58 3c 2c 34 5a 36 ;62 - char 1 walk
	hex	18 74 18 3d 5a 28 54 6c ;63 - char 1 hero char right
