extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR = 6, MAGICPROJECTILE=7}
export(CELL_TYPES) var type = CELL_TYPES.ENEMY

enum MOVEMENTDIRECTION{LEFT=0, RIGHT=1, UP=2, DOWN=3, MIDDLE = 4}

var alreadyMovedThisTurn = true

var alreadyAttackedThisTurn = true

var isDisabled = true

signal enemyMadeMove

signal enemyAttacked (enemy, attackDirection, attackDamange )

signal enemyDefeated (enemy)

var lifePoints = 1

var barrierEnemy = false

var attackDamage = 1

var enemyType = GlobalVariables.ENEMYTYPE.BARRIERENEMY

#counts how many cells are moved per turn 
var moveCellCount = 1

#depending if the player is moving up/down, left/right decides in which of the two he is moving 
var movementdirection = randi()%4

var mageMoveCount = randi()%5

var enemyDefeated = false

var diagonalAttack = false

var horizontalVerticalAttack = true

func _ready():
	pass
	

func _process(delta): 
	randomize()
	if(isDisabled == false): 
		if lifePoints == 0 && enemyDefeated == false:
			enemyDefeated = true
			Grid.set_cellv(Grid.world_to_map(position),Grid.get_tileset().find_tile_by_name("EMPTY")) 
			set_process(false)
			#play defeat animation 
			$AnimationPlayer.play("defeat", -1, 1.5)
			$Tween.interpolate_property($Sprite, "position", 0, 0, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($AnimationPlayer, "animation_finished")
			set_process(true)
			emit_signal("enemyDefeated", self)
			return
		elif lifePoints != 0:
			match enemyType:
				GlobalVariables.ENEMYTYPE.BARRIERENEMY:
					barrierenemy_type_actions()
				GlobalVariables.ENEMYTYPE.MAGEENEMY:
					mageenemy_type_actions()
				GlobalVariables.ENEMYTYPE.NINJAENEMY:
					ninjaenemy_type_actions()
				GlobalVariables.ENEMYTYPE.WARRIROENEMY:
					warriorenemy_type_actions()
				

func barrierenemy_type_actions():
	if(!alreadyMovedThisTurn || !alreadyAttackedThisTurn):
		var attackCell = Grid.enableEnemyAttack(self, horizontalVerticalAttack, diagonalAttack)
		if(attackCell != Vector2.ZERO):
			emit_signal("enemyAttacked", self, attackCell, attackDamage)
			alreadyAttackedThisTurn = true
		if(alreadyMovedThisTurn == false):
			var upDownLeftRight = randi()%4+1
			var movement_direction = Vector2.ZERO
			match upDownLeftRight:
				1:
					movement_direction = Vector2(1,0)
				2:
					movement_direction = Vector2(-1,0)
				3: 
					movement_direction = Vector2(0,1)
				4:
					movement_direction = Vector2(0,-1)
					
			var target_position = Grid.request_move(self, movement_direction)
			if(target_position):
				position=target_position
				alreadyMovedThisTurn = true
				
				if(alreadyAttackedThisTurn == false):
					attackCell = Grid.enableEnemyAttack(self)
					if(attackCell != Vector2.ZERO):
						#attack player
						emit_signal("enemyAttacked", self, attackCell, attackDamage)
					alreadyAttackedThisTurn = true
		if(alreadyMovedThisTurn && alreadyAttackedThisTurn):
			emit_signal("enemyMadeMove")
			
func warriorenemy_type_actions():
	#print ("already moved this turn " + str(alreadyMovedThisTurn))
	if(!alreadyMovedThisTurn || !alreadyAttackedThisTurn):
		var attackCell = Grid.enableEnemyAttack(self, horizontalVerticalAttack, diagonalAttack)
		if(attackCell != Vector2.ZERO):
			emit_signal("enemyAttacked", self, attackCell, attackDamage)
			alreadyAttackedThisTurn = true
		if(alreadyMovedThisTurn == false):
		#move towards enemy get direction from the grid
			var movement_direction = Grid.get_enemy_move_towards_player(self)
			print(movement_direction)
			var target_position = Grid.request_move(self, movement_direction)
			if(target_position):
				position=target_position
				alreadyMovedThisTurn = true
				
				if(alreadyAttackedThisTurn == false):
					attackCell = Grid.enableEnemyAttack(self,horizontalVerticalAttack, diagonalAttack)
					if(attackCell != Vector2.ZERO):
						#attack player
						emit_signal("enemyAttacked", self, attackCell, attackDamage)
					alreadyAttackedThisTurn = true
		if(alreadyMovedThisTurn && alreadyAttackedThisTurn):
			emit_signal("enemyMadeMove")
			
func ninjaenemy_type_actions():
	if !alreadyMovedThisTurn:
	#move towards enemy get direction from the grid
		if movementdirection == MOVEMENTDIRECTION.LEFT:
			movementdirection = MOVEMENTDIRECTION.RIGHT
		elif movementdirection == MOVEMENTDIRECTION.RIGHT:
			movementdirection = MOVEMENTDIRECTION.LEFT
		elif movementdirection == MOVEMENTDIRECTION.UP:
			movementdirection = MOVEMENTDIRECTION.DOWN
		elif movementdirection == MOVEMENTDIRECTION.DOWN:
			movementdirection = MOVEMENTDIRECTION.UP
		if moveCellCount == 1:
			moveCellCount = 2
		elif moveCellCount == 2: 
			moveCellCount = 1
		var movement_direction = Grid.get_enemy_move_ninja_pattern(self, movementdirection, moveCellCount)
		print(movement_direction)
		var target_position = Grid.request_move(self, movement_direction)
		if(target_position):
			position=target_position
			alreadyMovedThisTurn = true
		alreadyAttackedThisTurn=true
		if(alreadyMovedThisTurn && alreadyAttackedThisTurn):
			emit_signal("enemyMadeMove")
	
func mageenemy_type_actions():
	if !alreadyMovedThisTurn:
		if mageMoveCount == 6:
			mageMoveCount = 0
	#move towards enemy get direction from the grid
		match mageMoveCount:
			0:
				movementdirection = MOVEMENTDIRECTION.MIDDLE
			1:
				#moves to right top corner 
				movementdirection = MOVEMENTDIRECTION.RIGHT
			2:
				#moves to right down corner 
				movementdirection = MOVEMENTDIRECTION.DOWN
			3:
				#moves to middle of the field
				movementdirection = MOVEMENTDIRECTION.MIDDLE
			4:
				#moves to left down corner 
				movementdirection = MOVEMENTDIRECTION.LEFT
			5:
				#moves to left top corner 
				movementdirection = MOVEMENTDIRECTION.UP
		var movement_direction = Grid.get_enemy_move_mage_pattern(self, movementdirection)
		var target_position = Grid.request_move(self, movement_direction)
		if(target_position):
			position=target_position
			mageMoveCount+=1
			alreadyMovedThisTurn = true
		alreadyAttackedThisTurn=true
		if(alreadyMovedThisTurn && alreadyAttackedThisTurn):
			emit_signal("enemyMadeMove")
	
func generateEnemy(): 
#	var enemieToGenerate = randi()%4
#generate warrior for testing purposes
	var enemieToGenerate = GlobalVariables.ENEMYTYPE.WARRIROENEMY
	match enemieToGenerate:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.BARRIERENEMY
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.NINJAENEMY
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.WARRIROENEMY
			lifePoints = 1
			attackDamage = 1 
			diagonalAttack = true
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.MAGEENEMY

func inflictDamage(attackDamage):
	lifePoints -= attackDamage
	#set enemy difficulty and type set enemy stats based on difficulty set amount of enemies to spawn based on room size and difficulty 
