		.data
#####################################################################################################
file_in: 	.asciiz 	"input.txt" 		# pad naar inputbestand 
buffer: 	.space 		2048 			# buffergrootte
file_error_msg:	.asciiz		"Inputbestand werd niet geopend. Controlleer of het bestand bestaat of niet."

victory_msg:	.asciiz 	"Victory!"
dead_msg:	.asciiz 	"You died.." 		# Ja, dit is een Dark Souls reference.

column_size:	.word		8			# Zet dit op de kolomgrootte van het inputbestand!!!! (8 voor input.txt, 32 voor input_large.txt)
######################################################################################################

		.text
# Definieeren van waarden #
#######################################################################################################	
.eqv	up	'z'				# voor z doe je 112, voor w is dit 119
.eqv	down	's'
.eqv	left	'q'				# voor q doe je 113, voor a is dit 97
.eqv	right	'd'
.eqv	esc	'x'				# er is nog een andere exit waarde, daarom noemt dit esc. Dit stopt het spel

.eqv	blue	0x0000FF 			# muur
.eqv	black	0x000000			# gang
.eqv	yellow	0xFFFF00			# speler
.eqv	green	0x00FF00			# uitgang
.eqv	red	0xFF0000			# vijand
.eqv	white	0xFFFFFF			# snoepje	


.eqv	wall	'w'				# Muur 
.eqv	passage	'p'				# Gang
.eqv	player	's'				# Speler
.eqv	candy	'c'				# Snoepje
.eqv	enemy	'e'				# Vijand
.eqv	exitt	'u'				# Uitgang (dubbele T omdat er nog een andere "exit-waarde" is.)
.eqv    endl	'\n'				# Volgende rij
#######################################################################################################


######## Volgende code komt van de slides van de les ##########
readfile:
	li $v0, 13 				# system call for open file
	la $a0, file_in 			# output file name
	li $a1, 0 				# Open for writing (flags are 0: read, 1: write)
	li $a2, 0 				# mode is ignored
	syscall 				# open a file (file descriptor returned in $v0)
	
	move $s6, $v0 				# save the file descriptor
	
	bne $s6, 3, file_error			# Eigen stukje code; Geeft error aan als het bestand niet geopend werd.
###############################################################
# Read from file to buffer
	li $v0, 14 				# system call for read from file
	move $a0, $s6 				# file descriptor
	la $a1, buffer 				# address of buffer to which to load the contents
	li $a2, 2048 				# hardcoded max number of characters (equal to size of buffer)
	syscall 				# write to file, $v0 contains number of characters read
###############################################################
# Close the file
	li $v0, 16 				# system call for close file
	move $a0, $s6 				# file descriptor to close
	syscall 				# close file
################ Einde van geleende code ######################
	j init_draw

#===============================================================================================================#

file_error:
	li	$v0, 4
	la	$a0, file_error_msg
	syscall					# Geeft aan gebruiker dat inputbestand niet geopend kon worden.
	j exit
	
#===============================================================================================================#

################# Inputfile uittekenen #################################
# We tekenen in deze reeks functies de maze uit in het Bitmap Display. #
# Zet de display op volgende waarden:				       #
# Voor input.txt:						       #
# - 32 x 32 	voor unit					       #
# - 256 x 256 	voor display 					       #
# - $gp 	als basisadres					       #
#								       #
# Voor input_large.txt:						       #
# - 32 x 32 	voor unit					       #
# - 1024 x 512 	voor display 					       #
# - $gp 	als basisadres					       #
#								       #
# Gebruikte registers						       #
# - $s0: text van inputbestand, dient ook als textindex		       #
# - $s1: kolomindex						       #
# - $s2: rij-index						       #
# - $s3: kolom index player					       #
# - $s4: rij index player					       #
#								       #
# - $a0: kolomindex voor logic-to-address functie		       #
# - $a1: rijindex voor logic-to-address functie			       #
#								       #
# - $v0: Returnwaarde van posfunctie				       #
# - $t0: temp voor mem adres					       #
# - $t1: temp voor character					       #
# - $t2: temp voor pixelkleur					       #
# - $t3: temp voor arithmetic					       #
########################################################################

init_draw: #initiele waarden voordat we beginnen met het tekenen van de maze
	la	$s0, buffer			# File wordt in $s0 geladen
	li 	$s1, -1				# kolomindex
	li 	$s2, 0				# rijindex
	
	subi	$s0, $s0, 1			# we beginnen net voor het bestand

#===============================================================================================================#

draw_maze:	
	addi	$s1, $s1, 1			# kolomindex ++
	addi 	$s0, $s0, 1			# textindex ++ 

	move	$a0, $s1			# Kolomargument
	move	$a1, $s2			# Rijargument
	jal 	logic_to_address		# Zet logische coordinaten om tot memory address
	
	move 	$t0, $v0			# Temp krijgt mem adres
	
	# Characterwaarde inlezen en juiste kleur tekenen.
	lb 	$t1, ($s0)			# laadt de character in waar de textindex naar wijst

	beq	$t1, wall,	draw_wall	# tekent een muur 	(blauw)
	beq	$t1, passage,	draw_passage	# tekent een gang 	(zwart)
	beq	$t1, player,	draw_player	# tekent een speler	(geel)
	beq	$t1, 'c',	draw_candy	# tekent een snoepje	(wit) 	# Geen idee waarom het candy niet normaal inleest 
	beq	$t1, enemy,	draw_enemy	# tekent een vijand	(rood)
	beq	$t1, exitt,	draw_exit	# tekent de uitgang	(groen)
	
	beq	$t1, '\n',	next_row	# Nieuwe lijn, leest waarde van label newline ook niet goed in, net als candy
	beqz	$t1, init_game			# Einde van inlezen van inputbestand (null terminated)
	
	j 	draw_wall			# Onbekende characters worden muren

#===============================================================================================================#

next_row:
	addi	$s2, $s2, 1			# rijindex ++
	li	$s1, -1				# kolomindex wordt gereset
	j	draw_maze
			
#===============================================================================================================#

draw_wall:					# kleurt pixel blauw
	la	$t2, blue
	sw	$t2, ($t0)
	j	draw_maze

#===============================================================================================================#

draw_passage:					# kleurt pixel zwart
	la	$t2, black
	sw	$t2, ($t0)
	j	draw_maze
	
#===============================================================================================================#

draw_player:					# kleurt pixel wit en houdt locatie van speler bij
	move 	$s3, $s1			# Slaagt kolomindex op
	move	$s4, $s2			# Slaagt rijindex op
	
	la	$t2, yellow
	sw	$t2, ($t0)
	j	draw_maze
	
#===============================================================================================================#

draw_candy:					# kleurt pixel wit
	# Pixel inkleuren
	la	$t2, white
	sw	$t2, ($t0)
	j	draw_maze
	
#===============================================================================================================#

draw_enemy:					#kleurt pixel rood
	la	$t2, red
	sw	$t2, ($t0)
	j	draw_maze

#===============================================================================================================#

draw_exit:					#kleurt pixel groen
	la	$t2, green			
	sw	$t2, ($t0)
	j	draw_maze

################ Bron: Project van Yonah Thienpont 2020-2021 ############################## (met enkele aanpassingen)
	# Argumenten:			#
	# - $a0: Kolomindex		#
	# - $a1: Rij-index		#
	# 				#
	# Gebruikte temps:		#
	# - $t0: Voor adres		#
	#				#
	# Return register: 		#
	# - $v0: bevat mem adres	#
	#################################
	
logic_to_address:				# Get a memory address from logical coordinates
	sw	$fp, 0($sp)			# Push old frame pointer (dynamic link)
	move	$fp, $sp			# Frame pointer now points to the top of the stack
	
	# Save used registers and return adress in stackframe
	sw	$ra, -4($fp)			# Store the value of the return address
	sw	$s0, -8($fp)			#
	sw	$s1, -12($fp)			#
	sw	$s2, -16($fp)			# Save locally used registers
	sw	$s3, -20($fp)			#
	sw	$s4, -24($fp)			#
	
	move	$s0, $a0			# ColIndex
	move	$s1, $a1			# RowIndex
	li	$s2, 4				# dataSize
	move	$s3, $gp			# base address
	lw	$s4, column_size 		# colSize
	
	mul	$t0, $s1, $s4			# (rowIndex * colSize)
	add	$t0, $t0, $s0			# (rowIndex*colSize + colIndex)
	mul	$t0, $t0, $s2			# (rowIndex*colSize + colIndex) * dataSize
			
	add	$t0, $t0, $s3			# baseAddr + (rowIndex*colSize + colIndex) * dataSize
	
	move	$v0, $t0			# Place result in return value location
	
	lw	$s4, -24($fp)			#
	lw	$s3, -20($fp)			#
	lw	$s2, -16($fp)			# Restore locally used registers
	lw	$s1, -12($fp)			#
	lw	$s0, -8($fp)			#
	lw	$ra, -4($fp)			# Get return address from frame
	move	$sp, $fp			# Get old frame pointer from current frame
	lw	$fp, ($sp)			# restore old frame pointer
	
	jr	$ra				# go back
	
#################### Einde code van Yonah Thienpont 2020-2021 #############################

############################################## Main Game Loop! ##################################################
#################################################################################################################
# Argument-registers:
#	- $a0: kolomindex voor logic-to-address functie
#	- $a1: rijindex voor logic-to-address functie
#
# s-registers:
#	- $s0: Voor de inputchecker van toetsenbordsimulator (0xffff0000)
#	- $s1: bevat originele kolomindex van speler
#	- $s2: bevat originele rij-index  van speler
#	- $s3: bevat nieuwe kolomindex
#	- $s4: bevat nieuwe rijindex
#
# temp-registers:
#	- $t0: toetsenbord input en check byte
#	- $t1: geheugenadres oude locatie
#	- $t2: geheugenadres nieuwe locatie
#################################################################################################################

init_game:					# initialiseert de waarden voor de main loop
	li	$s0, 0xffff0000			# laadt keyboard input checker in $s1
	
	move	$s1, $s3			# verplaats kolomindex van speler naar juiste argument
	move	$s2, $s4			# verplaats rijindex van speler naar juiste argument
	


#===============================================================================================================#

game_loop:
	lw 	$t0, ($s0)			# Verplaats waarde in 0xffff0000 naar $t1 voor berekeningen
	bnez 	$t0, read_input			# Speler heeft een toets ingedrukt (namelijk de waarde in 0xffff0000 is niet 0)
	
	li 	$v0, 32 			#
	li 	$a0, 60 			# Programma slaapt voor 60ms als er geen input is.
	syscall					#
	
	j	game_loop			# loopt

	
#===============================================================================================================#

read_input:					# Leest input in en zet dit om naar een beweging
	lw	$t0, 0xffff0004			# Laatste input wordt in $t1 geplaats
	
	beq	$t0, up, go_up			# z ingevoerd
	beq 	$t0, down, go_down		# s ingevoerd
	beq	$t0, left, go_left		# q ingevoerd
	beq	$t0, right, go_right		# d ingevoerd
	
	beq     $t0, esc, exit			# x ingevoerd
	
	li 	$v0, 32 			#
	li 	$a0, 60 			# Programma slaapt voor 60ms als de input niet geldt.
	syscall
	
	j 	game_loop

#===============================================================================================================#

go_up:
	move	$s3, $s1		
	addi	$s4, $s2, -1 			# Rij-index --
	
	j 	update_position

#===============================================================================================================#

go_down:
	move	$s3, $s1		
	addi	$s4, $s2, 1 			# Rij_index ++
	
	j 	update_position

#===============================================================================================================#

go_left:
	addi	$s3, $s1, -1			# Kolomindex --
	move	$s4, $s2

	j 	update_position

#===============================================================================================================#

go_right:
	addi	$s3, $s1, 1			# Kolomindex ++
	move	$s4, $s2

	j 	update_position

#===============================================================================================================#

update_position:	
	move	$v0, $s1			# Originele kolomindex (als er geen verplaatsing nodig is)
	move	$v1, $s2			# Originele rij-index 

	bltz	$s3, end_update			# Negatieve index, niet mogelijk
	bltz	$s4, end_update			# 
	
	move	$a0, $s3			#
	move	$a1, $s4			# verplaatsen voor logic-to-adress 
	
	jal	logic_to_address		# zet om naar geheugenadres
	move 	$t2, $v0			# mem. adres gaat in $t0
	
	move	$v0, $s1			# Originele kolomindex opnieuw herstellen
	
	lw	$t0, ($t2)			# kleur opslagen in $t0
	beq	$t0, blue, end_update		# muur
	beq	$t0, black, move_player		# gang
	beq	$t0, green, victory		# uitgang
	beq	$t0, red, die			# vijand
	beq	$t0, white, move_player		# snoepje, in extended wordt dit uitgebreid
	
	j	end_update
		
#===============================================================================================================#
	
move_player:	 
	move 	$a0, $s1			#
	move	$a1, $s2			# Bereken geheugenadres van originele positie
	jal 	logic_to_address		#
	move    $t1, $v0			# Sla op in $t1
	
	la 	$t0, black
	sw	$t0, ($t1)			# Kleurt originele positie zwart
	
	la	$t0, yellow
	sw	$t0, ($t2)
	
	move	$v0, $s3			# plaatst nieuwe positie in returnwaarden
	move	$v1, $s4			#
	
	j 	end_update

#===============================================================================================================#
			
end_update:
	move	$s1, $v0			#
	move	$s2, $v1			# (nieuwe) positie opslagen als positie van speler
			
	li	$v0, 32				#
	li	$a0, 60				# Programma slaapt voor 60ms 
	syscall					#
	
	j	game_loop
	
##################################################################################################################

die:
	move 	$a0, $s1			#
	move	$a1, $s2			# Bereken geheugenadres van originele positie
	jal 	logic_to_address		#
	move    $t1, $v0			# Sla op in $t1
	
	la 	$t0, black
	sw	$t0, ($t1)			# Kleurt originele positie zwart
	
	la	$t0, red			# Speler verdwijnt (aka dood/rood :^)
	sw	$t0, ($t2)
	
	li	$v0, 4
	la	$a0, dead_msg			# geeft aan dat speler dood is 
	syscall	
	
	j exit
	
#===============================================================================================================#

victory:
	move 	$a0, $s1			#
	move	$a1, $s2			# Bereken geheugenadres van originele positie
	jal 	logic_to_address		#
	move    $t1, $v0			# Sla op in $t1
	
	la 	$t0, black
	sw	$t0, ($t1)			# Kleurt originele positie zwart
	
	la	$t0, green			# Speler heeft de uitgang verloren, geen geel pixel meer
	sw	$t0, ($t2)
	
	li	$v0, 4
	la	$a0, victory_msg
	syscall	
	j	exit
	
#===============================================================================================================#
		
exit:
	li	$v0, 10
	syscall

##################################################################################################################




















