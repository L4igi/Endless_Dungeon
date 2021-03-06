extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.ENEMY

var dangerFieldTexture = preload("res://GameObjects/Enemy/EnemyAttackRange.png")

var highLightEnemy = preload("res://GameObjects/Enemy/selectedEnemyHighLight.png")

var baseMovementCount = 0

var movementCount = 0

var attackCount = 0

var attackRange = 0

var lifePoints = 0

var attackDamage = 0

var baseAttackDamage = 1

var baseAttackRange = 1

var baseLifePoints = 1

var enemyTurnDone = false

var isDisabled = true

signal enemyMadeMove (enemy)

signal enemyAttacked (enemy, attackDirection, attackDamange )

signal enemyDefeated (enemy, CURRENTPHASE)

var isBarrier = false

var barrierKeyValue

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

var waitingForEventBeforeContinue = null

var inflictattackType = null

var hitByProjectile = null

var moveTo = null

var attackTo = Vector2.ZERO

var attackCell = []

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

var helpEnemy = false

var playSavedAnimation = false

onready var healthBar = $HealthBar

onready var previewHealthBar = $PreviewHealthBar

#var mageTowardsDirection = Vector2(1,0)

var ninjaEnemyCheckedDirections = 0

var movedMage = false

func _ready():
	var player = Grid.get_node("Player")
	player.connect("toggleDangerArea", self, "on_toggle_danger_area")

func update_preview_healthBar(damage):
	if !self.isBarrier:
		previewHealthBar.set_value((lifePoints-damage)*10)
	else:
		previewHealthBar.set_value(lifePoints*10)
		for item in Grid.mainPlayer.itemsInPosession:
			if item.keyValue == barrierKeyValue && Grid.mainPlayer.attackType == GlobalVariables.ATTACKTYPE.SWORD:
				previewHealthBar.set_value(0)
			
func on_toggle_danger_area(enemyToToggleArea, toggleAll=false):
	if !helpEnemy:
		update_preview_healthBar(Grid.mainPlayer.get_equip_attack_damage())
		if lifePoints>0:
			if !isDisabled && toggleAll:
				if dangerFieldsVisible:
					previewHealthBar.set_visible(false)
					healthBar.set_visible(true)
					for child in attackRangeNode.get_children():
						child.set_visible(false)
						dangerFieldsVisible = false
						individualDangerFieldVisible = false
				else:
					healthBar.set_visible(false)
					previewHealthBar.set_visible(true)
					for child in attackRangeNode.get_children():
						child.set_visible(true)
						dangerFieldsVisible = true
						individualDangerFieldVisible = true
			elif !isDisabled && enemyToToggleArea != null:
				if dangerFieldsVisible:
					if self != Grid.activeRoom.enemiesInRoom[enemyToToggleArea]:
						previewHealthBar.set_visible(false)
						healthBar.set_visible(true)
						for child in attackRangeNode.get_children():
							child.set_visible(false)
							individualDangerFieldVisible = false
					else:
						previewHealthBar.set_visible(true)
						healthBar.set_visible(false)
						for child in attackRangeNode.get_children():
							child.set_visible(true)
							individualDangerFieldVisible = true
			elif !isDisabled && enemyToToggleArea == null:
				if dangerFieldsVisible:
					previewHealthBar.set_visible(true)
					healthBar.set_visible(false)
					for child in attackRangeNode.get_children():
						child.set_visible(true)
						individualDangerFieldVisible = true
			
func turn_off_danger_fields_on_exit_room():
	for child in attackRangeNode.get_children():
		child.set_visible(false)
		dangerFieldsVisible = false
		individualDangerFieldVisible = false
	healthBar.set_visible(true)
	previewHealthBar.set_visible(false)
			
#func calc_mage_towards():
#	var distance = Grid.world_to_map(Grid.mainPlayer.playerWalkedThroughDoorPosition) - Grid.world_to_map(position)
#	if abs(distance.x) >= abs(distance.y):
#		mageTowardsDirection = Vector2(distance.x/abs(distance.x),0)
#	else:
#		mageTowardsDirection = Vector2(0,distance.y/abs(distance.y))
				
func move_mage_after_hit():
	randomize()
	#print("move mage in move mage after hit")
	movedMage = true
	var possibleLocations = []
	var cell_target = Vector2.ZERO
	var difficultFactor = GlobalVariables.enemyMageDifficulty
	if difficultFactor > 4:
		difficultFactor = 4
#depending on the difficutly mage enemy can move to different spots in the room
	for location in (4+difficultFactor):
		possibleLocations.append(location)
	while(!possibleLocations.empty()):
		var mageMovement = possibleLocations[randi()%(possibleLocations.size())]
		match mageMovement:
			GlobalVariables.DIRECTION.LEFT:
				cell_target = Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Vector2(1,1)
				cell_target = cell_target-Grid.world_to_map(position)
				possibleLocations.erase(GlobalVariables.DIRECTION.LEFT)
			GlobalVariables.DIRECTION.RIGHT:
				cell_target = Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Grid.activeRoom.roomSize + Vector2(-2,-2)
				cell_target = cell_target-Grid.world_to_map(position)
				possibleLocations.erase(GlobalVariables.DIRECTION.RIGHT)
			GlobalVariables.DIRECTION.UP:
				cell_target = Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Vector2(Grid.activeRoom.roomSize.x,0) + Vector2(-2,1)
				cell_target = (cell_target-Grid.world_to_map(position))
				possibleLocations.erase(GlobalVariables.DIRECTION.UP)
			GlobalVariables.DIRECTION.DOWN:
				cell_target = Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Vector2(0,Grid.activeRoom.roomSize.y) + Vector2(1,-2)
				cell_target = (cell_target-Grid.world_to_map(position))
				possibleLocations.erase(GlobalVariables.DIRECTION.DOWN)
			GlobalVariables.DIRECTION.MIDDLE:
				cell_target = Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+ Vector2(int(ceil(((Grid.activeRoom.roomSize + Vector2(-2,-2))/2).x)), int(ceil(((Grid.activeRoom.roomSize + Vector2(-2,-2))/2).y)))
				cell_target = (cell_target-Grid.world_to_map(position))
				possibleLocations.erase(GlobalVariables.DIRECTION.MIDDLE)
			GlobalVariables.DIRECTION.RIGHTDOWN:
				cell_target = Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Vector2(Grid.activeRoom.roomSize.x-2,int(ceil(((Grid.activeRoom.roomSize + Vector2(-2,-2))/2).y)))
				cell_target = (cell_target-Grid.world_to_map(position))
				possibleLocations.erase(GlobalVariables.DIRECTION.RIGHTDOWN)
			GlobalVariables.DIRECTION.RIGHTUP:
				cell_target = Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Vector2(int(ceil(((Grid.activeRoom.roomSize + Vector2(-2,-2))/2).x)),1)
				cell_target = (cell_target-Grid.world_to_map(position))
				possibleLocations.erase(GlobalVariables.DIRECTION.RIGHTUP)
			GlobalVariables.DIRECTION.LEFTDOWN:
				cell_target = Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Vector2(int(ceil(((Grid.activeRoom.roomSize + Vector2(-2,-2))/2).x)),Grid.activeRoom.roomSize.y-2)
				cell_target = (cell_target-Grid.world_to_map(position))
				possibleLocations.erase(GlobalVariables.DIRECTION.LEFTDOWN)
			GlobalVariables.DIRECTION.LEFTUP:
				cell_target = Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Vector2(1,int(ceil(((Grid.activeRoom.roomSize + Vector2(-2,-2))/2).y)))
				cell_target = (cell_target-Grid.world_to_map(position))
				possibleLocations.erase(GlobalVariables.DIRECTION.LEFTUP)

		#print("Possible location size " + str(possibleLocations.size()))
		var target_position = Grid.request_move(self, cell_target)
		if target_position && target_position!=position:
			moveTo = target_position
			possibleLocations.clear()
			break
		else:
			moveTo = null
		
	if moveTo:
		$MageAnimationPlayer.play("walk", -1, 4.5)
		$Tween.interpolate_property(self, "position", position, moveTo, $MageAnimationPlayer.current_animation_length/4.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		return true
	else:
		return false
		
#movement of enemies is calculated in advance to ensure proper interactions
func calc_enemy_move_to(calcMode, activeRoom, count):
	var cell_target = Vector2.ZERO
	var movementdirectionVector = Vector2.ZERO
	match enemyType:
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			movementdirectionVector = Grid.get_enemy_move_towards_player(self, movementCount)
			cell_target = Grid.world_to_map(position)+ movementdirectionVector
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			movementdirectionVector = Vector2(0,0)
			cell_target = Grid.world_to_map(position)+movementdirectionVector
			
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			movementdirectionVector = Grid.get_enemy_move_ninja_pattern(self, movementdirection, movementCount)
			ninjaEnemyCheckedDirections = 0
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
			cell_target = Grid.world_to_map(position)
			var walkTry = 4
			while walkTry >= 0:
				if Grid.get_cellv(Grid.world_to_map(position)+ movementdirectionVector) == Grid.TILETYPES.FLOOR || Grid.get_cellv(Grid.world_to_map(position)+ movementdirectionVector) == Grid.TILETYPES.MAGICPROJECTILE:
					cell_target = Grid.world_to_map(position)+ movementdirectionVector
					walkTry = -1
					break
				if movementdirectionVector == Vector2(1,0):
					movementdirectionVector = Vector2(-1,0)
				elif movementdirectionVector == Vector2(-1,0):
					movementdirectionVector = Vector2(0,1)
				elif movementdirectionVector == Vector2(0,1):
					movementdirectionVector = Vector2(0,-1)
				elif movementdirectionVector == Vector2(0,-1):
					movementdirectionVector = Vector2(1,0)
				walkTry-=1
				
#preview mode shows calculates where an enemy moves to without proper interaction 
	if calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW:
		var target_position = Grid.map_to_world(cell_target) + Grid.cell_size / GlobalVariables.isometricFactor
		if target_position:
			moveTo = target_position
		else:
			moveTo = null
#action mode is used to calculate final movement position all interactions included used for final movement
	elif calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION:
		var target_position = Grid.request_move(self, movementdirectionVector)
		if target_position:
			moveTo = target_position
		else:
			moveTo = null
	count +=1 
	if count >= GlobalVariables.turnController.enemiesToMove.size():
		return
	GlobalVariables.turnController.enemiesToMove[count].calc_enemy_move_to(calcMode,activeRoom, count)
			
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
			if moveTo:
				set_process(false)
				$WarriorAnimationPlayer.play(animationToPlay, -1, 3.0)
				$Tween.interpolate_property(self, "position", position, moveTo, $WarriorAnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($WarriorAnimationPlayer, "animation_finished")
				$WarriorAnimationPlayer.play("idle")
				set_process(true)
		
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			if moveTo:
				set_process(false)
				$MageAnimationPlayer.play("walk", -1, 4.5)
				$Tween.interpolate_property(self, "position", position, moveTo, $MageAnimationPlayer.current_animation_length/4.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($MageAnimationPlayer, "animation_finished")
				$MageAnimationPlayer.play("idle")
				set_process(true)
			mageMoveCount+=1
			
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			if moveTo:
				set_process(false)
				$NinjaAnimationPlayer.play("walk", -1, 4.5)
				$Tween.interpolate_property(self, "position", position, moveTo, $NinjaAnimationPlayer.current_animation_length/4.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($NinjaAnimationPlayer, "animation_finished")
				$NinjaAnimationPlayer.play("idle")
				set_process(true)
				
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			if moveTo:
				set_process(false)
				$AnimationPlayer.play("walk", -1, 1.0)
				$Tween.interpolate_property(self, "position", position, moveTo, $AnimationPlayer.current_animation_length/1.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($AnimationPlayer, "animation_finished")
				$AnimationPlayer.play("idle")
				set_process(true)
				
	check_inflicted_damage()
	emit_signal("enemyMadeMove", self)

#attack of enemies is calculated in advance to ensure proper interactions
func calc_enemy_attack_to(calcMode, activeRoom ,count):
	adjust_enemy_attack_range_enable_attack(calcMode, activeRoom)
	count +=1 
	if count >= activeRoom.enemiesInRoom.size():
		return
	activeRoom.enemiesInRoom[count].calc_enemy_attack_to(calcMode, activeRoom, count)

			
func enemyAttack(): 
	match enemyType:
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			if attackTo != Vector2.ZERO:
				set_process(false)
				$WarriorAnimationPlayer.play("attack", -1, 3.0)
				$Tween.interpolate_property($SpriteWarriorEnemy, "position", attackTo*GlobalVariables.tileSize, Vector2(), $WarriorAnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($WarriorAnimationPlayer, "animation_finished")
				$WarriorAnimationPlayer.play("idle")
				set_process(true)
				emit_signal("enemyAttacked", self, attackCell, attackType,  attackDamage, attackCellArray)
			attackCount += 1
		
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			set_process(false)
			$MageAnimationPlayer.play("attack", -1, 3.0)
			emit_signal("enemyAttacked", self, attackCell, attackType, attackDamage, attackCellArray)
			yield($MageAnimationPlayer, "animation_finished")
			$MageAnimationPlayer.play("idle")
			set_process(true)
			attackCount += 1
		
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			if attackTo.x == 1 || attackTo.y == 1:
				attackDamage = 2
			else:
				attackDamage = 1
			if attackTo != Vector2.ZERO:
				set_process(false)
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
				emit_signal("enemyAttacked", self, attackCell, attackType, attackDamage, attackCellArray)
			attackCount += 1
			
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			if attackTo != Vector2.ZERO:
				set_process(false)
				$AnimationPlayer.play("attack", -1, 3.0)
				$Tween.interpolate_property($Sprite, "position", attackTo*GlobalVariables.tileSize, Vector2(), $AnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($AnimationPlayer, "animation_finished")
				$AnimationPlayer.play("idle")
				set_process(true)
				emit_signal("enemyAttacked", self, attackCell, attackType, attackDamage, attackCellArray)
			attackCount += 1
			
	GlobalVariables.turnController.enemy_attacked_done(self)
	
#diffenrent attack ranges are calculated, it is checked if target is in attack range
func adjust_enemy_attack_range_enable_attack(calcMode, activeRoom):
	if !attackCellArray.empty():
		attackCellArray.clear()
	if !attackCell.empty():
		attackCell.clear()
	var cellsToColor = []
	if attackRangeNode != null:
		attackRangeNode.queue_free()
		attackRangeNode=null
	attackRangeNode = Node2D.new()
	Grid.add_child(attackRangeNode)
	var enemyMapPostion = Grid.world_to_map(position)
	var attackToSet = false
	var count = 0
	var attackedPlayer = []
	var attackedEnemy = []
#creates texturerects in all directions chosen to mirror base direction pattern 
	for direction in mirrorDirectionsArray:
#range of cells in base direction 
		for attackRange in attackRangeArray:
			count +=1
			if !attackRange.empty():
				for values in attackRange:
					var directionVector = Vector2.ZERO
					match direction:
						GlobalVariables.DIRECTION.RIGHT:
							directionVector = Vector2(count, values)
						GlobalVariables.DIRECTION.LEFT:
							directionVector = Vector2(-count, -values)
						GlobalVariables.DIRECTION.DOWN:
							directionVector = Vector2(-values,count)
						GlobalVariables.DIRECTION.UP:
							directionVector = Vector2(values,-count)
					var checkCell = enemyMapPostion + directionVector
					if check_if_cell_valid_position(checkCell, activeRoom):
						var checkCellValue = Grid.get_cellv(checkCell)
						if calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION:
							#if player is on one of the attackcells enemy will attack player 
							if checkCellValue == Grid.get_tileset().find_tile_by_name("PLAYER"):
								attackTo = directionVector
								attackCell.append(checkCell)
								attackToSet = true
								attackedPlayer.append(Grid.get_cell_pawn(checkCell))
							#if helpenemy is on one of the attackcells and no player enemy will attack helpenemy  
							elif checkCellValue == Grid.get_tileset().find_tile_by_name("ENEMY"):
								if Grid.get_cell_pawn(checkCell).helpEnemy:
									if !attackToSet:
										attackTo = directionVector
									attackCell.append(checkCell)
									attackToSet = true
									attackedEnemy.append(Grid.get_cell_pawn(checkCell))
						if checkCellValue == Grid.get_tileset().find_tile_by_name("WALL") || checkCellValue == Grid.get_tileset().find_tile_by_name("DOOR") || checkCellValue == Grid.get_tileset().find_tile_by_name("UNLOCKEDDOOR"):
							break
						else:
							cellsToColor.append(checkCell)
		count = 0
#action mode shows calculates where an enemy attacks to with proper interaction 
	if calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION:
		if !attackedPlayer.empty() && enemyType != GlobalVariables.ENEMYTYPE.MAGEENEMY && calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION:
			GlobalVariables.turnController.playerTakeDamage.append(attackedPlayer[0])
		elif !attackedEnemy.empty() && enemyType != GlobalVariables.ENEMYTYPE.MAGEENEMY && calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION:
			var tempEnemyTakenDamage = attackedEnemy.duplicate()
			for enemy in tempEnemyTakenDamage:
				if Grid.world_to_map(enemy.position) != Grid.world_to_map(position)+attackTo:
					attackedEnemy.erase(enemy)
			GlobalVariables.turnController.enemyTakeDamage.append(attackedEnemy[0])
		else:
			if !attackedPlayer.empty():
				GlobalVariables.turnController.playerTakeDamage.append(attackedPlayer[0])
			for enemy in attackedEnemy:
				if !GlobalVariables.turnController.enemyTakeDamage.has(enemy):
					GlobalVariables.turnController.enemyTakeDamage.append(enemy)
#creates texturerects as children of enemy to show attackRange
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
#higlights cell enemy is cuttently on
	if !helpEnemy:
		var enemyHighLight = TextureRect.new()
		enemyHighLight.set_texture(highLightEnemy)
		enemyHighLight._set_position(position-GlobalVariables.tileOffset)
		if !individualDangerFieldVisible:
			enemyHighLight.set_visible(false)
		attackRangeNode.add_child(enemyHighLight)
	if !attackToSet:
		attackTo = Vector2.ZERO
		attackCell.clear()
	attackCellArray = cellsToColor.duplicate()
	cellsToColor.clear()
	
#mirrors the base direction of the inital attackrangepattern to the opposit direction
func mirror_base_direction():
	var tempattackRangeArray = attackRangeArray.duplicate()
	for attackRange in tempattackRangeArray:
		if !attackRange.empty():
			if mirrorBaseDirection:
				var tempAttackRang = attackRange.duplicate()
				for value in tempAttackRang:
					if value != 0:
						attackRange.append(value*-1)
				tempAttackRang.clear()
						
						
func check_if_cell_valid_position(checkCell, activeRoom):
	if checkCell.x >= (Grid.world_to_map(activeRoom.doorRoomLeftMostCorner)+Vector2(1,1)).x && checkCell.x <= (Grid.world_to_map(activeRoom.doorRoomLeftMostCorner)+activeRoom.roomSize-Vector2(2,2)).x && checkCell.y >= (Grid.world_to_map(activeRoom.doorRoomLeftMostCorner)+Vector2(1,1)).y && checkCell.y <= (Grid.world_to_map(activeRoom.doorRoomLeftMostCorner)+activeRoom.roomSize-Vector2(2,2)).y:
		return true
	return false

#sets up all values to prepare for enemy turn
func make_enemy_turn():
	if !isDisabled:
		movedMage = false
		enemyTurnDone = false
		match Grid.mainPlayer.attackType:
			GlobalVariables.ATTACKTYPE.SWORD:
				update_preview_healthBar(Grid.mainPlayer.swordAttackDamage)
			GlobalVariables.ATTACKTYPE.MAGIC:
				update_preview_healthBar(Grid.mainPlayer.magicAttackDamage)
			GlobalVariables.ATTACKTYPE.BLOCK:
				update_preview_healthBar(Grid.mainPlayer.powerBlockAttackDamage)

#adapts enemy behaviour depending on the current difficulty 
#uses a pattern to change different stats repeating all 3 difficulty levels up
func adapt_difficulty():
	var difficultyLevel = 0
	match enemyType:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			difficultyLevel = GlobalVariables.enemyBarrierDifficulty
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			difficultyLevel = GlobalVariables.enemyWarriorDifficulty
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			difficultyLevel = GlobalVariables.enemyNinjaDifficulty
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			difficultyLevel = GlobalVariables.enemyMageDifficulty
	attackDamage = baseAttackDamage
	lifePoints = baseLifePoints
	attackRange = baseAttackRange
	movementCount = baseMovementCount
	for step in difficultyLevel:
		match enemyType:
			GlobalVariables.ENEMYTYPE.BARRIERENEMY:
				if !helpEnemy:
					if step%3 == 0:
						attackRange += 1
					elif step%3 == 1:
						attackDamage = baseAttackDamage + baseAttackDamage*(difficultyLevel*0.1)
						lifePoints = baseLifePoints + baseLifePoints*(difficultyLevel*0.1)
					elif step%3 == 2:
						movementCount += 1
			GlobalVariables.ENEMYTYPE.MAGEENEMY:
				if step%3 == 0:
					attackRange += 1
				elif step%3 == 1:
					attackDamage = baseAttackDamage + baseAttackDamage*(difficultyLevel*0.1)
					lifePoints = baseLifePoints + baseLifePoints*(difficultyLevel*0.1)
				elif step%3 == 2:
					movementCount += 1
			GlobalVariables.ENEMYTYPE.WARRIROENEMY:
				if step%3 == 0:
					attackRange += 1
				elif step%3 == 1:
					attackDamage = baseAttackDamage + baseAttackDamage*(difficultyLevel*0.2)
					lifePoints = baseLifePoints + baseLifePoints*(difficultyLevel*0.1)
				elif step%3 == 2:
					movementCount += 1
			GlobalVariables.ENEMYTYPE.NINJAENEMY:
				if step%3 == 0:
					attackRange+= 1
				elif step%3 == 1:
					attackDamage = baseAttackDamage + baseAttackDamage*(difficultyLevel*0.1)
					lifePoints = baseLifePoints + baseLifePoints*(difficultyLevel*0.1)
				elif step%3 == 2:
					movementCount += 1
					if movementCount == 5:
						movementCount = randi()%3+2
	attackRangeArray.clear()
#different attack patterterns are set up for demonstration
#depending on the difficulty these patterns change
#2 attackPatternModes for each difficutly level for more varierty  
	for count in attackRange:
		attackRangeArray.append([])
	var attackPatternMode = randi()%2
	match enemyType:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			if !helpEnemy:
				mirrorBaseDirection = false
				if attackPatternMode == 1:
					attackRangeArray[0] = [0]
					attackRangeInitDirection = GlobalVariables.DIRECTION.UP
					mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT]
					if attackRangeArray.size() >=2:
						attackRangeArray[1].append(0)
					if attackRangeArray.size() >= 3:
						mirrorBaseDirection = true
						attackRangeArray[2].append(1)
						attackRangeArray[2].append(2)
					if attackRangeArray.size() >= 4:
						mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN, GlobalVariables.DIRECTION.RIGHT]
					if attackRangeArray.size() >=5:
						attackRangeArray[2].append(0)
						attackRangeArray[3].append(1)
					if attackRangeArray.size()>=6:
						pass
				elif attackPatternMode == 0:
					attackRangeArray[0] = [0]
					attackRangeInitDirection = GlobalVariables.DIRECTION.DOWN
					mirrorDirectionsArray = [GlobalVariables.DIRECTION.RIGHT]
					if attackRangeArray.size() >=2:
						attackRangeArray[1].append(0)
					if attackRangeArray.size() >= 3:
						mirrorBaseDirection = true
						attackRangeArray[2].append(1)
						attackRangeArray[2].append(2)
					if attackRangeArray.size() >= 4:
						mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN, GlobalVariables.DIRECTION.RIGHT]
					if attackRangeArray.size() >=5:
						attackRangeArray[3].append(0)
						attackRangeArray[3].append(1)
					if attackRangeArray.size()>=6:
						pass
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			if attackPatternMode == 1:
				attackRangeArray[0] = [0,1]
				mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN, GlobalVariables.DIRECTION.RIGHT]
				if attackRangeArray.size() >=3:
					attackRangeArray[1] = [0,1,2]
					attackRangeArray[2] = [1,2]
				if attackRangeArray.size() >=4:
					attackRangeArray[2].append(4)
					attackRangeArray[3] = [0,3,4]
				if attackRangeArray.size() >=5:
					attackRangeArray[4] = [0,4,5]
			elif attackPatternMode == 0:
				attackRangeArray[1] = [0,1,2]
				attackRangeArray.append([])
				if attackRangeArray.size() >=4:
					attackRangeArray[2] = [0,2]
					attackRangeArray[3] = [0]
				if attackRangeArray.size() >=5:
					attackRangeArray[3].append(4)
					attackRangeArray[4] = [0,1,4]
				if attackRangeArray.size() >=6:
					attackRangeArray[5] = [1,2,3]
				mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN, GlobalVariables.DIRECTION.RIGHT]
			
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			mirrorBaseDirection = false
			if attackPatternMode == 1:
				attackRangeArray[0] = [0]
				attackRangeInitDirection = GlobalVariables.DIRECTION.LEFT
				mirrorDirectionsArray = [GlobalVariables.DIRECTION.RIGHT]
				if attackRangeArray.size() >=2:
					mirrorBaseDirection = true
					mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN, GlobalVariables.DIRECTION.RIGHT]
				if attackRangeArray.size() >= 3:
					attackRangeArray[0].append(1)
				if attackRangeArray.size() >= 4:
					attackRangeArray[0].erase(1)
					attackRangeArray[1].append(1)
				if attackRangeArray.size() >=5:
					attackRangeArray[0].append(1)
				if attackRangeArray.size()>=6:
					pass
			elif attackPatternMode == 0:
				attackRangeArray[0] = [1]
				attackRangeInitDirection = GlobalVariables.DIRECTION.UP
				mirrorDirectionsArray = [GlobalVariables.DIRECTION.DOWN]
				if attackRangeArray.size() >=2:
					mirrorBaseDirection = true
					mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN, GlobalVariables.DIRECTION.RIGHT]
				if attackRangeArray.size() >= 3:
					attackRangeArray[1].append(0)
				if attackRangeArray.size() >= 4:
					attackRangeArray[1].append(2)
				if attackRangeArray.size() >=5:
					attackRangeArray[1].append(1)
				if attackRangeArray.size()>=6:
					pass
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			mirrorBaseDirection = false
			if attackPatternMode == 1:
				attackRangeArray[0] = [0,1]
				attackRangeInitDirection = GlobalVariables.DIRECTION.LEFT
				mirrorDirectionsArray = [GlobalVariables.DIRECTION.RIGHT]
				if attackRangeArray.size() >=2:
					attackRangeArray[1].append(2)
				if attackRangeArray.size() >= 3:
					mirrorBaseDirection = true
					attackRangeArray[2].append(3)
					attackRangeArray[1].append(0)
					attackRangeArray[2].append(0)
				if attackRangeArray.size() >= 4:
					attackRangeArray[3].append(3)
					attackRangeArray[3].append(4)
					attackRangeArray[3].append(0)
					attackRangeArray[3].append(1)
				if attackRangeArray.size() >=5:
					mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN, GlobalVariables.DIRECTION.RIGHT]
				if attackRangeArray.size()>=6:
					pass
			elif attackPatternMode == 0:
				attackRangeArray[0] = [0,1]
				attackRangeInitDirection = GlobalVariables.DIRECTION.UP
				mirrorDirectionsArray = [GlobalVariables.DIRECTION.DOWN]
				if attackRangeArray.size() >=2:
					attackRangeArray[1].append(2)
				if attackRangeArray.size() >= 3:
					mirrorBaseDirection = true
					attackRangeArray[2].append(3)
					attackRangeArray[1].append(0)
					attackRangeArray[2].append(0)
				if attackRangeArray.size() >= 4:
					attackRangeArray[3].append(3)
					attackRangeArray[3].append(4)
					attackRangeArray[3].append(0)
					attackRangeArray[3].append(1)
				if attackRangeArray.size() >=5:
					mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN, GlobalVariables.DIRECTION.RIGHT]
				if attackRangeArray.size()>=6:
					pass

	if mirrorBaseDirection:
		mirror_base_direction()
	if !mirrorDirectionsArray.has(attackRangeInitDirection):
		mirrorDirectionsArray.append(attackRangeInitDirection)
				
#sets up base stats fot different enemy types 
func generateEnemy(enemieToGenerate, currentGrid, unlockedDoor): 
	match enemieToGenerate:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			makeEnemyBarrier(currentGrid, unlockedDoor)
			enemyType = GlobalVariables.ENEMYTYPE.BARRIERENEMY
			attackType = GlobalVariables.ATTACKTYPE.SWORD
			baseLifePoints = 1
			baseAttackDamage = 1
			baseAttackRange = 1
			baseMovementCount = 1
			attackDamage = baseAttackDamage
			lifePoints = baseLifePoints
			attackRange = baseAttackRange
			movementCount = baseMovementCount
			get_node("Sprite").set_visible(true)
			#create help enemies at random if they aren't barrieres
			if !isBarrier && randi()%2 && GlobalVariables.countEnemyRoomsCleared >= 2:
				baseLifePoints = 3 - GlobalVariables.globalDifficultyMultiplier
				if baseLifePoints <= 0: 
					baseLifePoints = 0.5
				baseAttackDamage = 0
				baseAttackRange = 0
				baseMovementCount = 1
				attackDamage = baseAttackDamage
				lifePoints = baseLifePoints
				attackRange = baseAttackRange
				movementCount = baseMovementCount
				helpEnemy = true
				get_node("HelpSign").set_visible(true)
				get_node("Sprite").set_scale(Vector2(0.5,0.5))
				get_node("Sprite").set_offset(Vector2(0,14))
			else:
				adapt_difficulty()
			
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.NINJAENEMY
			attackType = GlobalVariables.ATTACKTYPE.NINJA
			baseLifePoints = 1
			baseAttackDamage = 1
			baseAttackRange = 1
			baseMovementCount = 2
			attackDamage = baseAttackDamage
			lifePoints = baseLifePoints
			attackRange = baseAttackRange
			movementCount = baseMovementCount
			get_node("SpriteNinjaEnemy").set_visible(true)
			adapt_difficulty()
			
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.WARRIROENEMY
			attackType = GlobalVariables.ATTACKTYPE.SWORD
			baseLifePoints = 1
			baseAttackDamage = 1
			baseAttackRange = 1
			baseMovementCount = 1
			attackDamage = baseAttackDamage
			lifePoints = baseLifePoints
			attackRange = baseAttackRange
			movementCount = baseMovementCount
			get_node("SpriteWarriorEnemy").set_visible(true)
			adapt_difficulty()
				
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.MAGEENEMY
			attackType = GlobalVariables.ATTACKTYPE.MAGIC
			get_node("SpriteMageEnemy").set_visible(true)
#			calc_mage_towards()
			baseLifePoints = 1
			baseAttackDamage = 1
			baseAttackRange = 1
			baseMovementCount = 1
			attackDamage = baseAttackDamage
			lifePoints = baseLifePoints
			attackRange = baseAttackRange
			movementCount = baseMovementCount
			adapt_difficulty()
			
	#set health bar stats 
	setup_healthbars()
	return enemyType

func setup_healthbars():
	healthBar.set_max(lifePoints*10)
	healthBar.set_value(lifePoints*10)
	healthBar.set_step(0.1)
	previewHealthBar.set_max(lifePoints*10)
	previewHealthBar.set_value(lifePoints*10)
	previewHealthBar.set_step(0.1)

#is called after all other animations are finished to properly play defeat/damage animation
func check_inflicted_damage():
	if queueInflictDamage:
		if lifePoints <= 0:
			print("Play defeat animation")
			play_defeat_animation(Grid.mainPlayer, GlobalVariables.turnController.currentTurnWaiting)
		else:
			play_taken_damage_animation(playerQueueAttackType,Grid.mainPlayer)
		queueInflictDamage = false
		queueInflictDamage = 0
		playerQueueAttackType = null
		
#inflicts damage on enemy 
func inflictDamage(inflictattackDamageVar, inflictattackTypeVar, takeDamagePosition, mainPlayer = null, CURRENTPHASE = null):
	var barrierDefeatItem = null
	self.inflictattackType = inflictattackTypeVar
	if inflictattackType == GlobalVariables.ATTACKTYPE.SAVED:
		playSavedAnimation = true
#checks if player is in posession of key item to defeat enemy
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

	elif !self.isBarrier:
		lifePoints -= inflictattackDamageVar
		healthBar.set_value(lifePoints*10)
		update_preview_healthBar(inflictattackDamageVar)
	if lifePoints <= 0:
		enemyDefeated = true
		if CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYER || CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE || CURRENTPHASE == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE || CURRENTPHASE == GlobalVariables.CURRENTPHASE.ENEMYATTACK:
			print("Playing defeat animation")
			play_defeat_animation(mainPlayer, CURRENTPHASE)
#queues inflict damage animation to play after enemy is all other animations are finished
		else:
			queueInflictDamage = true
			playerQueueAttackType =  inflictattackType
			playerQueueAttackDamage = attackDamage
			playerQueueAttackType = attackType
	else:
		if CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYER || CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE || CURRENTPHASE == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE || CURRENTPHASE == GlobalVariables.CURRENTPHASE.ENEMYATTACK:
			play_taken_damage_animation(inflictattackDamageVar, mainPlayer)
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
			print("Mage play hit animation")
			set_process(false)
			$MageAnimationPlayer.play(animationToPlay, -1, 2.0)
			yield($MageAnimationPlayer, "animation_finished")
			if !movedMage:
				if move_mage_after_hit():
					yield($MageAnimationPlayer, "animation_finished")
					Grid.set_cellv(Grid.world_to_map(position),Grid.get_tileset().find_tile_by_name("ENEMY"))
					adjust_enemy_attack_range_enable_attack(GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW, Grid.activeRoom)
			else:
				movedMage = false
			set_process(true)
			$MageAnimationPlayer.play("idle")

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
	print("Played taken damage animation")
	GlobalVariables.turnController.on_enemy_taken_damage(self)
	check_inflicted_damage()

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
		
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			set_process(false)
			if playSavedAnimation:
				$AnimationPlayer.play("saved", -1, 1.5)
			else:
				$AnimationPlayer.play("defeat", -1, 3.0)
			yield($AnimationPlayer, "animation_finished")
			set_process(true)
		_:
			set_process(false)
			$AnimationPlayer.play("defeat", -1, 3.0)
			yield($AnimationPlayer, "animation_finished")
			set_process(true)
	#print("Played defeat animation")
#adapts the difficulty level for all enemies after enemy defeat 
	match enemyType:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			GlobalVariables.enemyBarrierDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
			if int(GlobalVariables.enemyBarrierDifficulty)%5 == 0:
				GlobalVariables.enemyWarriorDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
				GlobalVariables.enemyMageDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
				GlobalVariables.enemyNinjaDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			GlobalVariables.enemyWarriorDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
			if int(GlobalVariables.enemyWarriorDifficulty)%5 == 0:
				GlobalVariables.enemyBarrierDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
				GlobalVariables.enemyMageDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
				GlobalVariables.enemyNinjaDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			GlobalVariables.enemyMageDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
			if int(GlobalVariables.enemyMageDifficulty)%5 == 0:
				GlobalVariables.enemyWarriorDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
				GlobalVariables.enemyBarrierDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
				GlobalVariables.enemyNinjaDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			GlobalVariables.enemyNinjaDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
			if int(GlobalVariables.enemyNinjaDifficulty)%5 == 0:
				GlobalVariables.enemyWarriorDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
				GlobalVariables.enemyMageDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
				GlobalVariables.enemyBarrierDifficulty += 0.5 * GlobalVariables.globalDifficultyMultiplier
	emit_signal("enemyDefeated", self)
		
func makeEnemyBarrier(currentGrid, unlockedDoor):
	randomize()
	var barrierChance = randi()%3
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
