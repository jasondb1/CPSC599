	org	$1c00
	
char_set:
	
	;chars under 22 can be walked over/on
	hex 00 00 00 00 00 00 00 00 ;0 - blank
	hex 00 10 00 40 04 00 02 00 ;1 - base landscape
	
	; 2 through 7 can be randomly generated
	hex	3e 6b 7f 6f 36 0c 14 3a ;2 - tree? maybe not necessary with tree border
	hex	00 00 42 18 18 38 6c b4 ;3 - rock
	hex	00 00 00 00 00 00 54 38 ;4 - grass
	hex 02 52 d6 74 3c 1a 18 18 ;5 - stump
	hex 00 7e 7e 7e 7e 18 18 18 ;6 - sign
	hex 21 08 42 10 45 a8 02 48 ;7 - sand?
	
	;other landscape that can be walked on but might have action associated 
	
	;the following are items or non generic tiles
	hex 18 24 24 18 08 38 08 38 ;8 - key
    hex 00 52 29 52 29 ff ff 42 ;9 - bbq
	;hex 00 18 3c 7e 7e 7e 7e 7e ;10 - door
	hex 00 ff 99 bd bd b5 bd bd ;10 - door
	hex 00 18 3c 7e 7e 7e 7e 7e ;11 - dungeon door
	hex aa 55 aa 55 aa 55 aa 55 ;12 - bridge / tile
	hex aa 55 aa 55 aa 55 aa 55 ;13 - wall
	hex 00 3c 7e 7e 7e 7e 3c 00 ;14 - coin
	hex 09 a2 2c 7c 5e 76 3c 84 ;15 - splat
	hex aa 55 aa 55 aa 55 aa 55 ;16 - path?
	hex aa 55 aa 55 aa 55 aa 55 ;17 - 
	hex aa 55 aa 55 aa 55 aa 55 ;18
	hex aa 55 aa 55 aa 55 aa 55 ;19
	hex aa 55 aa 55 aa 55 aa 55 ;20
	hex 00 18 18 7e 7e 18 18 00 ;21 - +
	hex 44 44 44 7c 44 44 c7 44 ;22 - base - brick
	
;;;;;;not walkable vvv
	hex	3e 6b 7f 6f 36 0c 14 3a ;23 - tree (border element)
	hex bb bb bb 83 bb bb 38 bb ;24 - wall (border element)
	;hex 3c d7 ab d5 ab d5 ab ff ;25 - castle tower
	hex c3 ff dd ab d5 ab d5 ff ;25 - alternate tower	
	hex aa 55 aa 55 aa 55 aa 55 ;26 - water?
	hex	00 00 00 ff ff 00 00 00 ;27 - horiz line?
	hex	18 18 18 18 18 18 18 18 ;28 - vert line?
	hex aa 55 aa 55 aa 55 aa 55 ;29 - checkerboard

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
	hex 00 00 00 00 00 00 00 00 ;40 - 
	hex 00 00 00 18 18 00 00 00 ;41 - projectile (dot)
	hex ff ff ff ff ff ff ff ff ;42 - solid
	
	hex 18 24 24 3c 5a 3c 7e 14 ;43 - princess
	
	;enemies are all above 44, can lower this as needed
	hex 00 00 10 38 7f dd fe 0d ;44 - griffen ul
	hex 04 1a 3e d6 bc 58 b0 50 ;45 - griffen ur
	hex 4f 3f 58 33 12 01 00 00 ;46 - griffen ll
	hex b0 f8 9c 5e 6b 91 60 00 ;47 - griffen lr
	
	hex 42 24 5a 3c 3c da 1a 24 ;48 - small creature
	hex 80 98 a4 db f7 5b 18 34 ;49 - swordsman

	hex aa 55 aa 55 aa 55 aa 55 ;50
	hex aa 55 aa 55 aa 55 aa 55 ;51
	hex aa 55 aa 55 aa 55 aa 55 ;52
	hex aa 55 aa 55 aa 55 aa 55 ;53
	hex aa 55 aa 55 aa 55 aa 55 ;54
	hex aa 55 aa 55 aa 55 aa 55 ;55
	
	hex 10 3c 18 18 18 18 18 08 ;56 - sword down
	hex 08 18 18 18 18 18 3c 10 ;57 - sword up
	hex 00 00 02 7e 3f 02 00 00 ;58 - sword left
	hex 00 00 40 7e fc 40 00 00 ;59 - sword right
	hex 18 24 18 7c 76 fd dc 14 ;60 - char hero down
	hex 18 18 3c 76 ab ad 1e 14 ;61 - char hero up
	hex 18 2e 18 bc 5a 14 2a 36 ;62 - char hero left
	hex	18 74 18 3d 5a 28 54 6c ;63 - char hero right

	;hex 18 24 58 3c 2c 34 5a 36 ;62 - char 1 walk 
