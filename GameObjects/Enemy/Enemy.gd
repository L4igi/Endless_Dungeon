extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.ENEMY


var movementCount = 0

var attackCount = 0

var enemyTurnDone = false

var isDisabled = true

signal enemyMadeMove

signal enemyAttacked (enemy, attackDirection, attackDamange )

signal enemyDefeated (enemy)

var lifePoints = 1

var barrierEnemy = false

var attackDamage = 1

var attackType = GlobalVariables.ATTACKTYPE.SWORD

var enemyType = GlobalVariables.ENEMYTYPE.BARRIERENEMY

#counts how many cells are moved per turn 
var moveCellCount = 1

#depending if the player is moving up/down, left/right decides in which of the two he is moving 
var movementdirection = randi()%4

var mageMoveCount = 0

var mageOnOff = randi()%2

var enemyDefeated = false

var diagonalAttack = false

var horizontalVerticalAttack = true

var ninjaAttackRange = 5

func _ready():
	Grid.connect("playerTurnDoneSignal", self, "_on_player_turn_done_signal")
	

func _process(delta): 
	randomize()
	if(isDisabled == false): 
		if lifePoints > 0:
			if !enemyTurnDone :
				#&& !enemyDefeated
				if movementCount >= 1 && attackCount >= 1 :
					enemyTurnDone = true 
					#print("SIGNAL ENEMY MADE MOVE TO PLAYER")
					emit_signal("enemyMadeMove")


func barrierenemy_type_actions():
	enemyAttack()

func ninjaenemy_type_actions():
	enemyAttack()

func mageenemy_type_actions():
	enemyMovement()


func warriorenemy_type_actions():
	enemyAttack()
	
	#enemyAttack()
			
func enemyMovement():
	match enemyType:
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			var movementdirection = Grid.get_enemy_move_towards_player(self)
#			print(movement_direction)
			var target_position = Grid.request_move(self, movementdirection)
			if(target_position && !enemyDefeated):
				set_process(false)
				#play defeat animation 
				$AnimationPlayer.play("walk", -1, 3.0)
				$Tween.interpolate_property(self, "position", position, target_position, $AnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($AnimationPlayer, "animation_finished")
				$AnimationPlayer.play("idle")
				set_process(true)
				movementCount += 1
				if attackCount < 1:
					enemyAttack()
		
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			#print("MageEnemy Moving")
			if mageMoveCount == 6:
				mageMoveCount = 0
		#move towards enemy get direction from the grid
			match mageMoveCount:
				0:
					movementdirection = GlobalVariables.DIRECTION.MIDDLE
				1:
					#moves to right top corner 
					movementdirection = GlobalVariables.DIRECTION.RIGHT
				2:
					#moves to right down corner 
					movementdirection = GlobalVariables.DIRECTION.DOWN
				3:
					#moves to middle of the field
					movementdirection = GlobalVariables.DIRECTION.MIDDLE
				4:
					#moves to left down corner 
					movementdirection = GlobalVariables.DIRECTION.LEFT
				5:
					#moves to left top corner 
					movementdirection = GlobalVariables.DIRECTION.UP
			var mage_target_pos = Grid.get_enemy_move_mage_pattern(self, movementdirection)
			var target_position = Grid.request_move(self, mage_target_pos)
			if(target_position):
				position=target_position
				mageMoveCount += 1
				movementCount += 1
				if attackCount < 1:
					enemyAttack()
				
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			if movementdirection == GlobalVariables.DIRECTION.LEFT:
				movementdirection = GlobalVariables.DIRECTION.RIGHT
			elif movementdirection == GlobalVariables.DIRECTION.RIGHT:
				movementdirection = GlobalVariables.DIRECTION.LEFT
			elif movementdirection == GlobalVariables.DIRECTION.UP:
				movementdirection = GlobalVariables.DIRECTION.DOWN
			elif movementdirection == GlobalVariables.DIRECTION.DOWN:
				movementdirection = GlobalVariables.DIRECTION.UP
			if moveCellCount == 1:
				moveCellCount = 2
			elif moveCellCount == 2: 
				moveCellCount = 1
			var movement_direction = Grid.get_enemy_move_ninja_pattern(self, movementdirection, moveCellCount)
			var target_position = Grid.request_move(self, movement_direction)
			if(target_position):
				set_process(false)
				#play defeat animation 
				$NinjaAnimationPlayer.play("walk", -1, 3.5)
				$Tween.interpolate_property(self, "position", position, target_position, $NinjaAnimationPlayer.current_animation_length/3.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($NinjaAnimationPlayer, "animation_finished")
				$NinjaAnimationPlayer.play("idle")
				set_process(true)
				movementCount += 1
				if attackCount < 1:
					enemyAttack()
				
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
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
				set_process(false)
				#play defeat animation 
				$AnimationPlayer.play("walk", -1, 3.0)
				$Tween.interpolate_property(self, "position", position, target_position, $AnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($AnimationPlayer, "animation_finished")
				$AnimationPlayer.play("idle")
				set_process(true)
				movementCount += 1
				if attackCount < 1:
					enemyAttack()
	
			
func enemyAttack(): 
	match enemyType:
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			var attackDirection = Grid.enableEnemyAttack(self, attackType, horizontalVerticalAttack, diagonalAttack)
			if(attackDirection != Vector2.ZERO):
				set_process(false)
				#play defeat animation 
				$AnimationPlayer.play("defeat", -1, 3.0)
				$Tween.interpolate_property($Sprite, "position", attackDirection*GlobalVariables.tileSize, Vector2(), $AnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($AnimationPlayer, "animation_finished")
				$AnimationPlayer.play("idle")
				set_process(true)
				emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackDirection, attackType,  attackDamage)
				attackCount += 1
				if movementCount < 1:
					enemyMovement()
			else:
				if movementCount == 1:
					attackCount += 1
				if movementCount < 1:
					enemyMovement()

		
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			if mageOnOff == 1:
				mageOnOff = 0
				var attackDirection = Grid.enableEnemyAttack(self, attackType, horizontalVerticalAttack, diagonalAttack)
				if attackDirection != Vector2.ZERO:
					set_process(false)
					#play defeat animation 
					$AnimationPlayer.play("defeat", -1, 5.0)
					$Tween.interpolate_property($Sprite, "position", attackDirection*GlobalVariables.tileSize, Vector2(), $AnimationPlayer.current_animation_length/5.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
					$Tween.start()
					yield($AnimationPlayer, "animation_finished")
					$AnimationPlayer.play("idle")
					set_process(true)
					emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackDirection, attackType, attackDamage)
					attackCount += 1
				else:
					attackCount += 1
			else:
				mageOnOff = 1
				attackCount += 1
		
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			var attackDirection = Grid.enableEnemyAttack(self, attackType, horizontalVerticalAttack, diagonalAttack)
			if attackDirection.x == 1 || attackDirection.y == 1:
				attackDamage = 2
			else:
				attackDamage = 1
			if attackDirection != Vector2.ZERO:
				set_process(false)
				#play defeat animation 
				$NinjaAnimationPlayer.play("attack", -1, 3.0)
				$Tween.interpolate_property($SpriteNinjaEnemy, "position", Vector2(), attackDirection*GlobalVariables.tileSize, $NinjaAnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($NinjaAnimationPlayer, "animation_finished")
				$NinjaAnimationPlayer.play("attackBack", -1, 3.0)
				$Tween.interpolate_property($SpriteNinjaEnemy, "position", attackDirection*GlobalVariables.tileSize, Vector2(), $NinjaAnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($NinjaAnimationPlayer, "animation_finished")
				$NinjaAnimationPlayer.play("idle")
				set_process(true)
				emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackDirection, attackType, attackDamage)
				attackCount += 1
				if movementCount < 1:
					enemyMovement()
			else:
				if movementCount == 1:
					attackCount += 1
				if movementCount < 1:
					enemyMovement()
			
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			var attackDirection = Grid.enableEnemyAttack(self, attackType, horizontalVerticalAttack, diagonalAttack)
			if attackDirection != Vector2.ZERO:
				set_process(false)
				#play defeat animation 
				$AnimationPlayer.play("defeat", -1, 3.0)
				$Tween.interpolate_property($Sprite, "position", attackDirection*32, Vector2(), $AnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($AnimationPlayer, "animation_finished")
				$AnimationPlayer.play("idle")
				set_process(true)
				emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackDirection, attackType, attackDamage)
				attackCount += 1
				if movementCount < 1:
					enemyMovement()
			else:
				if movementCount == 1:
					attackCount += 1
				if movementCount < 1:
					enemyMovement()

func _on_player_turn_done_signal():
	if !isDisabled:
		if(lifePoints > 0):
			movementCount = 0
			attackCount = 0
			enemyTurnDone = false
		
			match enemyType:
				GlobalVariables.ENEMYTYPE.BARRIERENEMY:
					barrierenemy_type_actions()
				GlobalVariables.ENEMYTYPE.MAGEENEMY:
					mageenemy_type_actions()
				GlobalVariables.ENEMYTYPE.NINJAENEMY:
					ninjaenemy_type_actions()
				GlobalVariables.ENEMYTYPE.WARRIROENEMY:
						warriorenemy_type_actions()
	
func generateEnemy(mageEnemyCount): 
#	var enemieToGenerate = randi()%4
#generate warrior for testing purposes
	var enemieToGenerate = 3
	match enemieToGenerate:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.BARRIERENEMY
			attackType = GlobalVariables.ATTACKTYPE.SWORD
			#get_node("Sprite").set_modulate(Color(randf(),randf(),randf(),1.0))
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.NINJAENEMY
			attackType = GlobalVariables.ATTACKTYPE.NINJA
			get_node("Sprite").set_visible(false)
			get_node("SpriteNinjaEnemy").set_visible(true)
			diagonalAttack = true
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.WARRIROENEMY
			lifePoints = 1
			attackDamage = 1 
			diagonalAttack = true
			attackType = GlobalVariables.ATTACKTYPE.SWORD
			get_node("Sprite").set_modulate(Color(255,0,0,1.0))
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.MAGEENEMY
			mageMoveCount = mageEnemyCount
			attackType = GlobalVariables.ATTACKTYPE.MAGIC
			get_node("Sprite").set_modulate(Color(0,0,255,1.0))
	return enemyType

func inflictDamage(inflictattackDamage, inflictattackType, takeDamagePosition):
	lifePoints -= inflictattackDamage
	if lifePoints <= 0 :
		enemyDefeated = true
		Grid.activeRoom.enemiesInRoom.erase(self)
		Grid.set_cellv(Grid.world_to_map(position),Grid.get_tileset().find_tile_by_name("EMPTY")) 
		set_process(false)
		#play defeat animation 
		match enemyType:
			GlobalVariables.ENEMYTYPE.NINJAENEMY:
				$NinjaAnimationPlayer.play("defeat", -1, 1.0)
				#move sprite to position of death 
				$Tween.interpolate_property(self, "position",  Grid.map_to_world(takeDamagePosition) + GlobalVariables.tileOffset,Grid.map_to_world(takeDamagePosition) + GlobalVariables.tileOffset, $NinjaAnimationPlayer.current_animation_length/1.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($NinjaAnimationPlayer, "animation_finished")
				set_process(true)
				emit_signal("enemyDefeated", self)
				return false
			_:
				$AnimationPlayer.play("defeat", -1, 3.0)
				#move sprite to position of death 
				$Tween.interpolate_property(self, "position",  Grid.map_to_world(takeDamagePosition) + GlobalVariables.tileOffset,Grid.map_to_world(takeDamagePosition) + GlobalVariables.tileOffset, $AnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($AnimationPlayer, "animation_finished")
				set_process(true)
				emit_signal("enemyDefeated", self)
				return false
	else:
		match enemyType:
			GlobalVariables.ENEMYTYPE.NINJAENEMY:
				return true
			_:
				return true
		
	#set enemy difficulty and type set enemy stats based on difficulty set amount of enemies to spawn based on room size and difficulty 
