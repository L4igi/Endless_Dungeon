extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.ENEMY

var dangerFieldTexture = preload("res://GameObjects/Enemy/EnemyAttackRange.png")

var maxTurnActions = 2

var movementCount = 0

var attackCount = 0

var enemyTurnDone = false

var isDisabled = true

signal enemyMadeMove (enemy)

signal enemyAttacked (enemy, attackDirection, attackDamange )

signal enemyDefeated (enemy, CURRENTPHASE)

signal enemyExplosionDone(enemy)

var lifePoints = 1

var isBarrier = false

var barrierKeyValue

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

var waitingForEventBeforeContinue = null

var inflictattackType = null

var hitByProjectile = null

var moveTo = null

var attackTo = Vector2.ZERO

var attackCell = Vector2.ZERO

#attackDirections: 

var attackRangeArray = []

var attackRangeInitDirection = GlobalVariables.DIRECTION.UP

var mirrorBaseDirection = true

var mirrorDirectionsArray = []

var attackRangeNode = null

var dangerFieldsVisible=false

var individualDangerFieldVisible = false

var attackCellArray = []

var queueInflictDamage = false

var playerQueueAttackDamage = 0

var playerQueueAttackType = null

onready var healthBar = $HealthBar

func _ready():
	var player = Grid.get_node("Player")
	player.connect("toggleDangerArea", self, "on_toggle_danger_area")
	

func _process(delta): 
	pass


func barrierenemy_type_actions():
	if !isDisabled:
		enemyAttack()

func ninjaenemy_type_actions():
	if !isDisabled:
		enemyAttack()

func mageenemy_type_actions():
	if !isDisabled:
		enemyAttack()


func warriorenemy_type_actions():
	if !isDisabled:
		enemyAttack()
	
func toggleVisibility(makeInVisible):
	print("changing visibility")
	var spriteToToggle = null
	match enemyType:
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			spriteToToggle = get_node("Sprite")
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			spriteToToggle = get_node("SpriteMageEnemy")
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			spriteToToggle = get_node("SpriteNinjaEnemy")
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			spriteToToggle = get_node("Sprite")
	if makeInVisible:
		spriteToToggle.set_visible(false)
	else:
		spriteToToggle.set_visible(true)
			
func on_toggle_danger_area(enemyToToggleArea, toggleAll=false):
	#print("enemyToToggleArea " + str(enemyToToggleArea))
	if lifePoints>0:
		if !isDisabled && toggleAll:
			if dangerFieldsVisible:
				for child in attackRangeNode.get_children():
						child.set_visible(false)
						dangerFieldsVisible = false
						individualDangerFieldVisible = false
			else:
				for child in attackRangeNode.get_children():
						child.set_visible(true)
						dangerFieldsVisible = true
						individualDangerFieldVisible = true
		elif !isDisabled && enemyToToggleArea != null:
			if dangerFieldsVisible:
				if self != Grid.activeRoom.enemiesInRoom[enemyToToggleArea]:
					for child in attackRangeNode.get_children():
						child.set_visible(false)
						individualDangerFieldVisible = false
				else:
					for child in attackRangeNode.get_children():
						child.set_visible(true)
						individualDangerFieldVisible = true
		elif !isDisabled && enemyToToggleArea == null:
			if dangerFieldsVisible:
				for child in attackRangeNode.get_children():
					child.set_visible(true)
					individualDangerFieldVisible = true
			
func turn_off_danger_fields_on_exit_room():
	for child in attackRangeNode.get_children():
		child.set_visible(false)
		dangerFieldsVisible = false
		individualDangerFieldVisible = false
			
func calc_enemy_move_to(calcMode, activeRoom):
	var cell_target = Vector2.ZERO
	var movementdirectionVector = Vector2.ZERO
	match enemyType:
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			movementdirectionVector = Grid.get_enemy_move_towards_player(self)
			cell_target = Grid.world_to_map(position)+ movementdirectionVector

		GlobalVariables.ENEMYTYPE.MAGEENEMY:
#			if mageMoveCount == 6:
#				mageMoveCount = 0
#			match mageMoveCount:
#				0:
#					movementdirection = GlobalVariables.DIRECTION.MIDDLE
#				1:
#					#moves to right top corner 
#					movementdirection = GlobalVariables.DIRECTION.RIGHT
#				2:
#					#moves to right down corner 
#					movementdirection = GlobalVariables.DIRECTION.DOWN
#				3:
#					#moves to middle of the field
#					movementdirection = GlobalVariables.DIRECTION.MIDDLE
#				4:
#					#moves to left down corner 
#					movementdirection = GlobalVariables.DIRECTION.LEFT
#				5:
#					#moves to left top corner 
#					movementdirection = GlobalVariables.DIRECTION.UP
#			movementdirectionVector = Grid.get_enemy_move_mage_pattern(self, movementdirection, activeRoom)
			movementdirectionVector = Grid.get_enemy_move_towards_player(self)
			cell_target = Grid.world_to_map(position)+ movementdirectionVector
					

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
			movementdirectionVector = Grid.get_enemy_move_ninja_pattern(self, movementdirection, moveCellCount)
			cell_target = Grid.world_to_map(position)+ movementdirectionVector
			

		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			var upDownLeftRight = randi()%4+1
			match upDownLeftRight:
				1:
					movementdirectionVector = Vector2(1,0)
				2:
					movementdirectionVector = Vector2(-1,0)
				3: 
					movementdirectionVector = Vector2(0,1)
				4:
					movementdirectionVector = Vector2(0,-1)
			cell_target = Grid.world_to_map(position)+ movementdirectionVector

	if calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW:
		var target_position = Grid.map_to_world(cell_target) + Grid.cell_size / GlobalVariables.isometricFactor
		if target_position:
			moveTo = target_position
	elif calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION:
		var target_position = Grid.request_move(self, movementdirectionVector)
		#print("target position "+ str(target_position))
		if target_position:
			moveTo = target_position
		else:
			moveTo = null
			
func enemyMovement():
	match enemyType:
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			var animationToPlay = "walk_up"
			match movementdirection:
				Vector2(-1,0):
					animationToPlay = "walk_left"
				Vector2(1,0):
					animationToPlay = "walk_right"
				Vector2(0,-1):
					animationToPlay = "walk_up"
				Vector2(0,1):
					animationToPlay = "walk_down"
#			if moveTo && !enemyDefeated:
			if moveTo:
				#print("moving to " + str(Grid.world_to_map(moveTo)))
				set_process(false)
				#play defeat animation 
				$WarriorAnimationPlayer.play(animationToPlay, -1, 3.0)
				$Tween.interpolate_property(self, "position", position, moveTo, $WarriorAnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($WarriorAnimationPlayer, "animation_finished")
				$WarriorAnimationPlayer.play("idle")
				set_process(true)
			movementCount += 1
		
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			if moveTo:
				set_process(false)
				#play defeat animation 
				$MageAnimationPlayer.play("walk", -1, 4.5)
				$Tween.interpolate_property(self, "position", position, moveTo, $MageAnimationPlayer.current_animation_length/4.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($MageAnimationPlayer, "animation_finished")
				$MageAnimationPlayer.play("idle")
				set_process(true)
			movementCount += 1
			mageMoveCount+=1
			
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			if moveTo:
				set_process(false)
				#play defeat animation 
				$NinjaAnimationPlayer.play("walk", -1, 4.5)
				$Tween.interpolate_property(self, "position", position, moveTo, $NinjaAnimationPlayer.current_animation_length/4.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($NinjaAnimationPlayer, "animation_finished")
				$NinjaAnimationPlayer.play("idle")
				set_process(true)
			movementCount += 1
				
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			if moveTo:
				set_process(false)
				#play defeat animation 
				$AnimationPlayer.play("walk", -1, 1.0)
				$Tween.interpolate_property(self, "position", position, moveTo, $AnimationPlayer.current_animation_length/1.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($AnimationPlayer, "animation_finished")
				$AnimationPlayer.play("idle")
				set_process(true)
			movementCount += 1

	if queueInflictDamage:
		if lifePoints <= 0:
			print("Play defeat animation")
			play_defeat_animation(Grid.mainPlayer, GlobalVariables.turnController.currentTurnWaiting)
		else:
			play_taken_damage_animation(playerQueueAttackType,Grid.mainPlayer)
		queueInflictDamage = false
		queueInflictDamage = 0
		playerQueueAttackType = null
	if attackCount + movementCount < maxTurnActions:
		enemyAttack()
	else:
		emit_signal("enemyMadeMove", self)

func calc_enemy_attack_to(calcMode):
	adjust_enemy_attack_range_enable_attack(calcMode)

			
func enemyAttack(): 
	match enemyType:
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			if attackTo != Vector2.ZERO:
				print("attack to " + str(attackTo))
				set_process(false)
				#play defeat animation 
				$WarriorAnimationPlayer.play("attack", -1, 3.0)
				$Tween.interpolate_property($SpriteWarriorEnemy, "position", attackTo*GlobalVariables.tileSize, Vector2(), $WarriorAnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($WarriorAnimationPlayer, "animation_finished")
				$WarriorAnimationPlayer.play("idle")
				set_process(true)
				emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackTo, attackType,  attackDamage, attackCellArray)
			attackCount += 1
			if attackCount + movementCount < maxTurnActions:
				calc_enemy_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION, Grid.activeRoom)
				enemyMovement()
			else:
				emit_signal("enemyMadeMove", self)

		
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			#print("Doing attack mage")
			set_process(false)
			$MageAnimationPlayer.play("attack", -1, 3.0)
#			$Tween.interpolate_property($Sprite, "position", Vector2(), Vector2(), $MageAnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
#			$Tween.start()
			emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackTo, attackType, attackDamage, attackCellArray)
			yield($MageAnimationPlayer, "animation_finished")
			$MageAnimationPlayer.play("idle")
			set_process(true)
			attackCount += 1
			if attackCount + movementCount < maxTurnActions:
				calc_enemy_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION, Grid.activeRoom)
				enemyMovement()
			else:
				emit_signal("enemyMadeMove", self)
		
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			if attackTo.x == 1 || attackTo.y == 1:
				attackDamage = 2
			else:
				attackDamage = 1
			if attackTo != Vector2.ZERO:
				set_process(false)
				#play defeat animation 
				$NinjaAnimationPlayer.play("attack", -1, 4.5)
				$Tween.interpolate_property($SpriteNinjaEnemy, "position", Vector2(), attackTo*GlobalVariables.tileSize, $NinjaAnimationPlayer.current_animation_length/4.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($NinjaAnimationPlayer, "animation_finished")
				$NinjaAnimationPlayer.play("attackBack", -1, 4.5)
				$Tween.interpolate_property($SpriteNinjaEnemy, "position", attackTo*GlobalVariables.tileSize, Vector2(), $NinjaAnimationPlayer.current_animation_length/4.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($NinjaAnimationPlayer, "animation_finished")
				$NinjaAnimationPlayer.play("idle")
				set_process(true)
				emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackTo, attackType, attackDamage, attackCellArray)
			attackCount += 1
			if attackCount + movementCount < maxTurnActions:
				calc_enemy_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION, Grid.activeRoom)
				enemyMovement()
			else:
				emit_signal("enemyMadeMove", self)
			
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			if attackTo != Vector2.ZERO:
				set_process(false)
				#play defeat animation 
				$AnimationPlayer.play("attack", -1, 3.0)
				$Tween.interpolate_property($Sprite, "position", attackTo*GlobalVariables.tileSize, Vector2(), $AnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($AnimationPlayer, "animation_finished")
				$AnimationPlayer.play("idle")
				set_process(true)
				emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackTo, attackType, attackDamage, attackCellArray)
			attackCount += 1
			if attackCount + movementCount < maxTurnActions:
				calc_enemy_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION, Grid.activeRoom)
				enemyMovement()
			else:
				emit_signal("enemyMadeMove", self)
				
func adjust_enemy_attack_range_enable_attack(calcMode):
	if !attackCellArray.empty():
		attackCellArray.clear()
	var cellsToColor = []
	if attackRangeNode != null:
		attackRangeNode.queue_free()
		attackRangeNode=null
	attackRangeNode = Node2D.new()
	Grid.add_child(attackRangeNode)
	var enemyMapPostion = Grid.world_to_map(position)
	var attackToSet = false
	var count = 0
	#print("mirrordirectionArray " + str(mirrorDirectionsArray))
	for direction in mirrorDirectionsArray:
		for attackRange in attackRangeArray:
			count +=1
			if !attackRange.empty():
				for values in attackRange:
					var directionVector = Vector2.ZERO
					match direction:
						GlobalVariables.DIRECTION.RIGHT:
							directionVector = Vector2(count, values)
						GlobalVariables.DIRECTION.LEFT:
							directionVector = Vector2(-count, values)
						GlobalVariables.DIRECTION.DOWN:
							directionVector = Vector2(values,count)
						GlobalVariables.DIRECTION.UP:
							directionVector = Vector2(values,-count)
					var checkCell = enemyMapPostion + directionVector
					#print(str(enemyMapPostion) +"-" +str(directionVector) +"="+ str(checkCell))
					if check_if_cell_valid_position(checkCell):
						#print("valid")
						var checkCellValue = Grid.get_cellv(checkCell)
						if checkCellValue == Grid.get_tileset().find_tile_by_name("PLAYER"):
							attackTo = directionVector
							attackCell = checkCell
							attackToSet = true
						if checkCellValue == Grid.get_tileset().find_tile_by_name("WALL") || checkCellValue == Grid.get_tileset().find_tile_by_name("DOOR") || checkCellValue == Grid.get_tileset().find_tile_by_name("UNLOCKEDDOOR"):
							break
						else:
							cellsToColor.append(checkCell)
		count = 0
	#print ("cellstocolor size " + str(cellsToColor.size()))
	for cell in cellsToColor:
		var alreadyColored = false
		for child in attackRangeNode.get_children():
			if child.get_position() == cell*GlobalVariables.tileSize:
				alreadyColored = true
		if !alreadyColored:
			var dangerField = TextureRect.new()
			dangerField.set_texture(dangerFieldTexture)
			dangerField._set_position(cell*GlobalVariables.tileSize)
			if !individualDangerFieldVisible:
				dangerField.set_visible(false)
			attackRangeNode.add_child(dangerField)
	if !attackToSet:
		attackTo = Vector2.ZERO
		attackCell = Vector2.ZERO
	attackCellArray = cellsToColor.duplicate()
	cellsToColor.clear()
	
func mirror_base_direction():
	#if mirror base is true append oppsit direction to base direction 
	var tempattackRangeArray = attackRangeArray.duplicate()
	for attackRange in tempattackRangeArray:
		if !attackRange.empty():
			if mirrorBaseDirection:
				var tempAttackRang = attackRange.duplicate()
				for value in tempAttackRang:
					if value != 0:
						attackRange.append(value*-1)
				tempAttackRang.clear()
						
						
func check_if_cell_valid_position(checkCell):
	if checkCell.x >= (Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Vector2(1,1)).x && checkCell.x <= (Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Grid.activeRoom.roomSize-Vector2(2,2)).x && checkCell.y >= (Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Vector2(1,1)).y && checkCell.y <= (Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Grid.activeRoom.roomSize-Vector2(2,2)).y:
		#print("in range")
		return true
	#print("not in range")
	return false
	
func make_enemy_turn():
	if !isDisabled:
		movementCount = 0
		attackCount = 0
		enemyTurnDone = false
		matchEnemyTurn()
			
			
func matchEnemyTurn():
	#calc_enemy_attack_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION)
	match enemyType:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			barrierenemy_type_actions()
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			mageenemy_type_actions()
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			ninjaenemy_type_actions()
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			warriorenemy_type_actions()
						
func generateEnemy(mageEnemyCount, currentGrid, unlockedDoor): 
#	var enemieToGenerate = randi()%4
#generate warrior for testing purposes
	var enemieToGenerate = randi()%4
	match enemieToGenerate:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.BARRIERENEMY
			attackType = GlobalVariables.ATTACKTYPE.SWORD
			lifePoints = 1
			attackDamage = 2
			var attackRange = 5
			get_node("Sprite").set_visible(true)
			for count in attackRange:
				attackRangeArray.append([])
			attackRangeArray[0] = [0]
			attackRangeArray[1] = [0, 1]
			mirrorBaseDirection = true
			attackRangeInitDirection = GlobalVariables.DIRECTION.RIGHT
			mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN]
			if mirrorBaseDirection:
				mirror_base_direction()
			if !mirrorDirectionsArray.has(attackRangeInitDirection):
				mirrorDirectionsArray.append(attackRangeInitDirection)
			
			
			
			makeEnemyBarrier(currentGrid, unlockedDoor)
			
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.NINJAENEMY
			attackType = GlobalVariables.ATTACKTYPE.NINJA
			lifePoints = 1
			attackDamage = 2
			var attackRange = 5
			get_node("SpriteNinjaEnemy").set_visible(true)
			for count in attackRange:
				attackRangeArray.append([])
			attackRangeArray[0] = [0, 1]
			attackRangeArray[1] = [0, 2]
			attackRangeArray[2] = [0, 3]
			attackRangeArray[3] = [0, 4]
			attackRangeArray[4] = [0, 5]
			mirrorBaseDirection = true
			attackRangeInitDirection = GlobalVariables.DIRECTION.RIGHT
			mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN]
			if mirrorBaseDirection:
				mirror_base_direction()
			if !mirrorDirectionsArray.has(attackRangeInitDirection):
				mirrorDirectionsArray.append(attackRangeInitDirection)
			
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.WARRIROENEMY
			lifePoints = 1
			attackDamage = 3
			attackType = GlobalVariables.ATTACKTYPE.SWORD
			var attackRange = 5
			get_node("SpriteWarriorEnemy").set_visible(true)
			for count in attackRange:
				attackRangeArray.append([])
			attackRangeArray[0] = [0, 1, 2]
			#attackRangeArray[1] = [0,2]
			mirrorBaseDirection = true
			attackRangeInitDirection = GlobalVariables.DIRECTION.RIGHT
			mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN]
			if mirrorBaseDirection:
				mirror_base_direction()
			if !mirrorDirectionsArray.has(attackRangeInitDirection):
				mirrorDirectionsArray.append(attackRangeInitDirection)
				
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.MAGEENEMY
			attackType = GlobalVariables.ATTACKTYPE.MAGIC
			get_node("SpriteMageEnemy").set_visible(true)
			lifePoints = 1
			attackDamage = 3
			var attackRange = 5
			for count in attackRange:
				attackRangeArray.append([])
			attackRangeArray[0] = [0]
			attackRangeArray[1] = [0,2]
			mirrorBaseDirection = true
			attackRangeInitDirection = GlobalVariables.DIRECTION.RIGHT
			mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN]
			if mirrorBaseDirection:
				mirror_base_direction()
			if !mirrorDirectionsArray.has(attackRangeInitDirection):
				mirrorDirectionsArray.append(attackRangeInitDirection)
	
	#set health bar stats 
	healthBar.set_max(lifePoints*10)
	healthBar.set_value(lifePoints*10)
	healthBar.set_step(1)
	return enemyType


func inflictDamage(inflictattackDamage, inflictattackType, takeDamagePosition, mainPlayer = null, CURRENTPHASE = null):
	GlobalVariables.turnController.enemyTakeDamage.append(self)
	var barrierDefeatItem = null
	self.inflictattackType = inflictattackType
	#if enemy is barriere only if player posesses item and attacks with sword enemy is killed
	if mainPlayer!=null && self.isBarrier:
		for item in mainPlayer.itemsInPosession:
			print ("Item Key Values: " + str(item.keyValue))
			if item.keyValue == barrierKeyValue:
				print("Enemy Barrier " + str(barrierKeyValue) + " was defeated using item weapon " + str(item.keyValue))
				lifePoints = 0
				mainPlayer.remove_key_item_from_inventory(item)
				Grid.activeRoom.on_use_key_item(item)
				isBarrier = false
				break 
		if !barrierDefeatItem:
			print("need weapon: " + str(barrierKeyValue) + " to defeat enemy ")

	if !self.isBarrier:
		lifePoints -= inflictattackDamage
		healthBar.set_value(lifePoints*10)
	if lifePoints <= 0:
		enemyDefeated = true
		if CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYER || CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE || CURRENTPHASE == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
			play_defeat_animation(mainPlayer, CURRENTPHASE)
		else:
			queueInflictDamage = true
			playerQueueAttackType =  inflictattackType
			playerQueueAttackDamage = attackDamage
			playerQueueAttackType = attackType
	else:
		if CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYER || CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE || CURRENTPHASE == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE:
			play_taken_damage_animation(inflictattackDamage, mainPlayer)
		else:
			queueInflictDamage = true
			playerQueueAttackType =  inflictattackType
	
func play_taken_damage_animation(inflictattackType, mainPlayer):
	var animationToPlay = str("take_damage_physical")
	if inflictattackType == GlobalVariables.ATTACKTYPE.MAGIC:
		animationToPlay = str("take_damage_magic")
	match enemyType:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			set_process(false)
			$AnimationPlayer.play(animationToPlay, -1, 2.0)
			yield($AnimationPlayer, "animation_finished")
			$AnimationPlayer.play("idle")
			set_process(true)

		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			set_process(false)
			$MageAnimationPlayer.play(animationToPlay, -1, 2.0)
			yield($MageAnimationPlayer, "animation_finished")
			$MageAnimationPlayer.play("idle")
			set_process(true)

		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			set_process(false)
			$NinjaAnimationPlayer.play(animationToPlay, -1, 2.0)
			yield($NinjaAnimationPlayer, "animation_finished")
			$NinjaAnimationPlayer.play("idle")
			set_process(true)

		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			set_process(false)
			$WarriorAnimationPlayer.play(animationToPlay, -1, 2.0)
			yield($WarriorAnimationPlayer, "animation_finished")
			$WarriorAnimationPlayer.play("idle")
			set_process(true)
	GlobalVariables.turnController.on_enemy_taken_damage(self)

func play_defeat_animation(mainPlayer, CURRENTPHASE):
	if attackRangeNode != null:
		attackRangeNode.queue_free()
	Grid.set_cellv(Grid.world_to_map(self.position), Grid.get_tileset().find_tile_by_name("FLOOR")) 
	match enemyType:
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			set_process(false)
			$NinjaAnimationPlayer.play("defeat", -1, 2.0)
			yield($NinjaAnimationPlayer, "animation_finished")
			set_process(true)

		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			set_process(false)
			$MageAnimationPlayer.play("defeat", -1, 2.0)
			yield($MageAnimationPlayer, "animation_finished")
			set_process(true)
			
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			set_process(false)
			$WarriorAnimationPlayer.play("defeat", -1, 2.0)
			yield($WarriorAnimationPlayer, "animation_finished")
			set_process(true)
		_:
			set_process(false)
			$AnimationPlayer.play("defeat", -1, 3.0)
			yield($AnimationPlayer, "animation_finished")
			set_process(true)
			
	emit_signal("enemyDefeated", self)
		
func makeEnemyBarrier(currentGrid, unlockedDoor):
	randomize()
	#determins if door is barrier or not 
	var barrierChance = 1
	var checkBarrierPossible = currentGrid.manage_barrier_creation(GlobalVariables.BARRIERTYPE.ENEMY)
	if(barrierChance == 1 && currentGrid.currentNumberRoomsgenerated!=0 && checkBarrierPossible):
		isBarrier = true
		get_node("Sprite").set_modulate(Color(randf(),randf(),randf(),1.0))
		barrierKeyValue = str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10)
		#check if generated value is unique and not already used 
		for count in range (0,currentGrid.barrierKeysNoSolution.size()):
			if barrierKeyValue == currentGrid.barrierKeysNoSolution[count].keyValue:
				barrierKeyValue = str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10) + str(randi()%10)
				count = 0
		currentGrid.generate_keyValue_item(barrierKeyValue, get_node("Sprite").get_modulate(), GlobalVariables.ITEMTYPE.WEAPON, unlockedDoor)
