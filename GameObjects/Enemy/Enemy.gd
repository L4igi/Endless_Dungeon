extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.ENEMY

var dangerFieldTexture = preload("res://GameObjects/Enemy/EnemyAttackRange.png")

var highLightEnemy = preload("res://GameObjects/Enemy/selectedEnemyHighLight.png")

var maxTurnActions = 2

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

var mageTowardsDirection = Vector2(1,0)

var ninjaEnemyCheckedDirections = 0

func _ready():
	var player = Grid.get_node("Player")
	player.connect("toggleDangerArea", self, "on_toggle_danger_area")
	
	
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
			
func calc_mage_towards():
	var distance = Grid.world_to_map(Grid.mainPlayer.playerWalkedThroughDoorPosition) - Grid.world_to_map(position)
	if abs(distance.x) >= abs(distance.y):
		mageTowardsDirection = Vector2(distance.x/abs(distance.x),0)
	else:
		mageTowardsDirection = Vector2(0,distance.y/abs(distance.y))
				
func move_mage_after_hit():
	var moveTryCount = 0
	var cell_target = Vector2.ZERO
	var mageMovement = 0
	match mageMovement:
		GlobalVariables.DIRECTION.LEFT:
			cell_target = Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Vector2(1,1)
			cell_target = cell_target-Grid.world_to_map(position)
		GlobalVariables.DIRECTION.RIGHT:
			cell_target = Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Grid.activeRoom.roomSize + Vector2(-2,-2)
			cell_target = cell_target-Grid.world_to_map(position)
		GlobalVariables.DIRECTION.UP:
			cell_target = Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Vector2(Grid.activeRoom.roomSize.x,0) + Vector2(-1,1)
			
		GlobalVariables.DIRECTION.DOWN:
			cell_target = Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+Vector2(0,Grid.activeRoom.roomSize.y) + Vector2(1,-1)
		GlobalVariables.DIRECTION.MIDDLE:
			cell_target = Grid.world_to_map(Grid.activeRoom.doorRoomLeftMostCorner)+ int((Grid.activeRoom.roomSize + Vector2(-2,-2))/2)
		GlobalVariables.DIRECTION.RIGHTDOWN:
			pass
		GlobalVariables.DIRECTION.RIGHTUP:
			pass
		GlobalVariables.DIRECTION.LEFTDOWN:
			pass
		GlobalVariables.DIRECTION.LEFTUP:
			pass
	print(cell_target)
	print(Grid.world_to_map(position))
	print(cell_target-Grid.world_to_map(position))
	var target_position = Grid.request_move(self, cell_target)
	#print("target position "+ str(target_position))
	if target_position:
		moveTo = target_position
	else:
		moveTo = null
		
	if moveTo:
		set_process(false)
		#play defeat animation 
		$MageAnimationPlayer.play("walk", -1, 4.5)
		$Tween.interpolate_property(self, "position", position, moveTo, $MageAnimationPlayer.current_animation_length/4.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		return true
	else:
		return false
		

			
func calc_enemy_move_to(calcMode, activeRoom, count):
	var cell_target = Vector2.ZERO
	var movementdirectionVector = Vector2.ZERO
	match enemyType:
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			movementdirectionVector = Grid.get_enemy_move_towards_player(self, movementCount)
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
				if Grid.get_cellv(Grid.world_to_map(position)+ movementdirectionVector) == Grid.TILETYPES.FLOOR:
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

	if calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW:
		var target_position = Grid.map_to_world(cell_target) + Grid.cell_size / GlobalVariables.isometricFactor
		if target_position:
			moveTo = target_position
		else:
			moveTo = null
	elif calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION:
		var target_position = Grid.request_move(self, movementdirectionVector)
		#print("target position "+ str(target_position))
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

	check_inflicted_damage()
#	if attackCount + movementCount < maxTurnActions:
#		enemyAttack()
	emit_signal("enemyMadeMove", self)

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
				#print("attack to " + str(attackTo))
				set_process(false)
				#play defeat animation 
				$WarriorAnimationPlayer.play("attack", -1, 3.0)
				$Tween.interpolate_property($SpriteWarriorEnemy, "position", attackTo*GlobalVariables.tileSize, Vector2(), $WarriorAnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($WarriorAnimationPlayer, "animation_finished")
				$WarriorAnimationPlayer.play("idle")
				set_process(true)
				emit_signal("enemyAttacked", self, attackCell, attackType,  attackDamage, attackCellArray)
			attackCount += 1
			
#			if attackCount + movementCount < maxTurnActions:
#				calc_enemy_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION, Grid.activeRoom)
#				enemyMovement()
#			else:
#				emit_signal("enemyMadeMove", self)

		
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			#print("Doing attack mage")
			set_process(false)
			$MageAnimationPlayer.play("attack", -1, 3.0)
#			$Tween.interpolate_property($Sprite, "position", Vector2(), Vector2(), $MageAnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
#			$Tween.start()
			emit_signal("enemyAttacked", self, attackCell, attackType, attackDamage, attackCellArray)
			yield($MageAnimationPlayer, "animation_finished")
			$MageAnimationPlayer.play("idle")
			set_process(true)
			attackCount += 1
#			if attackCount + movementCount < maxTurnActions:
#				calc_enemy_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION, Grid.activeRoom)
#				enemyMovement()
#			else:
#				emit_signal("enemyMadeMove", self)
		
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
				emit_signal("enemyAttacked", self, attackCell, attackType, attackDamage, attackCellArray)
			attackCount += 1
#			if attackCount + movementCount < maxTurnActions:
#				calc_enemy_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION, Grid.activeRoom)
#				enemyMovement()
#			else:
#				emit_signal("enemyMadeMove", self)
			
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
				emit_signal("enemyAttacked", self, attackCell, attackType, attackDamage, attackCellArray)
			attackCount += 1
			
	#check_inflicted_damage()
#	if attackCount + movementCount < maxTurnActions:
#		enemyAttack()
	GlobalVariables.turnController.enemy_attacked_done(self)

#todo check if cell target is free or used calcmode active
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
							directionVector = Vector2(-count, -values)
						GlobalVariables.DIRECTION.DOWN:
							directionVector = Vector2(-values,count)
						GlobalVariables.DIRECTION.UP:
							directionVector = Vector2(values,-count)
					var checkCell = enemyMapPostion + directionVector
					#print(str(enemyMapPostion) +"-" +str(directionVector) +"="+ str(checkCell))
					if check_if_cell_valid_position(checkCell, activeRoom):
						#print("valid")
						var checkCellValue = Grid.get_cellv(checkCell)
						if calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION:
							if checkCellValue == Grid.get_tileset().find_tile_by_name("PLAYER"):
								attackTo = directionVector
								attackCell.append(checkCell)
								attackToSet = true
								attackedPlayer.append(Grid.get_cell_pawn(checkCell))
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
	#print ("cellstocolor size " + str(cellsToColor.size()))
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
	print(cellsToColor.size())
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
						
						
func check_if_cell_valid_position(checkCell, activeRoom):
	if checkCell.x >= (Grid.world_to_map(activeRoom.doorRoomLeftMostCorner)+Vector2(1,1)).x && checkCell.x <= (Grid.world_to_map(activeRoom.doorRoomLeftMostCorner)+activeRoom.roomSize-Vector2(2,2)).x && checkCell.y >= (Grid.world_to_map(activeRoom.doorRoomLeftMostCorner)+Vector2(1,1)).y && checkCell.y <= (Grid.world_to_map(activeRoom.doorRoomLeftMostCorner)+activeRoom.roomSize-Vector2(2,2)).y:
		#print("in range")
		return true
	#print("not in range")
	return false
	
func make_enemy_turn():
	if !isDisabled:
		enemyTurnDone = false
			
func adapt_difficulty(difficultyLevel):
	var statToAdapt = difficultyLevel%3
	if difficultyLevel == 0:
		statToAdapt = -1
		attackDamage = baseAttackDamage
		lifePoints = baseLifePoints
		attackRange = baseAttackRange
		movementCount = baseMovementCount
	match enemyType:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			if statToAdapt == 0:
				attackRange += 1
			elif statToAdapt == 1:
				attackDamage = baseAttackDamage + baseAttackDamage*(difficultyLevel*0.2)
				lifePoints = baseLifePoints + baseLifePoints*(difficultyLevel*0.2)
			elif statToAdapt == 2:
				movementCount += 1
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			if statToAdapt == 0:
				attackRange += 1
			elif statToAdapt == 1:
				attackDamage = baseAttackDamage + baseAttackDamage*(difficultyLevel*0.2)
				lifePoints = baseLifePoints + baseLifePoints*(difficultyLevel*0.2)
			elif statToAdapt == 2:
				movementCount += 1
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			if statToAdapt == 0:
				attackRange += 1
			elif statToAdapt == 1:
				attackDamage = baseAttackDamage + baseAttackDamage*(difficultyLevel*0.2)
				lifePoints = baseLifePoints + baseLifePoints*(difficultyLevel*0.2)
			elif statToAdapt == 2:
				movementCount += 1
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			if statToAdapt == 0:
				attackRange += 1
			elif statToAdapt == 1:
				attackDamage = baseAttackDamage + baseAttackDamage*(difficultyLevel*0.2)
				lifePoints = baseLifePoints + baseLifePoints*(difficultyLevel*0.2)
			elif statToAdapt == 2:
				movementCount += movementCount*0.5
				if movementCount == 5:
					movementCount = randi()%3+2
	attackRangeArray.clear()
	for count in attackRange:
		attackRangeArray.append([])
	var attackPatternMode = 0
	match enemyType:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			mirrorBaseDirection = false
			if attackPatternMode == 1:
				attackRangeArray[0] = [0]
				attackRangeInitDirection = GlobalVariables.DIRECTION.UP
				mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT]
				if attackRangeArray.size() >=2:
					#mirrorBaseDirection = true
					#mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN, GlobalVariables.DIRECTION.RIGHT]
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
					#mirrorBaseDirection = true
					#mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN, GlobalVariables.DIRECTION.RIGHT]
					attackRangeArray[1].append(0)
				if attackRangeArray.size() >= 3:
					mirrorBaseDirection = true
					attackRangeArray[2].append(1)
					attackRangeArray[2].append(2)
					#mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT,GlobalVariables.DIRECTION.RIGHT]
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
					#mirrorBaseDirection = true
					#mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN, GlobalVariables.DIRECTION.RIGHT]
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
					#mirrorBaseDirection = true
					#mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN, GlobalVariables.DIRECTION.RIGHT]
					attackRangeArray[1].append(2)
				if attackRangeArray.size() >= 3:
					mirrorBaseDirection = true
					attackRangeArray[2].append(3)
					attackRangeArray[1].append(0)
					attackRangeArray[2].append(0)
					#mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT,GlobalVariables.DIRECTION.RIGHT]
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
				
func generateEnemy(mageEnemyCount, currentGrid, unlockedDoor): 
	randomize()
#	var enemieToGenerate = randi()%4
#generate warrior for testing purposes
	var enemieToGenerate = GlobalVariables.ENEMYTYPE.MAGEENEMY
#	if randi()%4 == 1:
#		enemieToGenerate = 2
	match enemieToGenerate:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			makeEnemyBarrier(currentGrid, unlockedDoor)
			enemyType = GlobalVariables.ENEMYTYPE.BARRIERENEMY
			attackType = GlobalVariables.ATTACKTYPE.SWORD
			baseLifePoints = 1
			baseAttackDamage = 1
			baseAttackRange = 1
			baseMovementCount = 3
			get_node("Sprite").set_visible(true)
			#randomly make to save enemy 
			if !isBarrier && randi()%2:
				lifePoints = 1
				movementCount = 1
				attackRange = 0
				helpEnemy = true
				get_node("HelpSign").set_visible(true)
#				get_node("HealthBar").set_visible(false)
				get_node("Sprite").set_scale(Vector2(0.5,0.5))
				get_node("Sprite").set_offset(Vector2(0,14))
			else:
				adapt_difficulty(GlobalVariables.enemyBarrierDifficulty)
			
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.NINJAENEMY
			attackType = GlobalVariables.ATTACKTYPE.NINJA
			baseLifePoints = 1
			baseAttackDamage = 1
			baseAttackRange = 1
			baseMovementCount = 2
			get_node("SpriteNinjaEnemy").set_visible(true)
			adapt_difficulty(GlobalVariables.enemyNinjaDifficulty)
			
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.WARRIROENEMY
			attackType = GlobalVariables.ATTACKTYPE.SWORD
			baseLifePoints = 1
			baseAttackDamage = 1
			baseAttackRange = 1
			baseMovementCount = 1
			get_node("SpriteWarriorEnemy").set_visible(true)
			adapt_difficulty(GlobalVariables.enemyWarriorDifficulty)
				
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.MAGEENEMY
			attackType = GlobalVariables.ATTACKTYPE.MAGIC
			get_node("SpriteMageEnemy").set_visible(true)
			calc_mage_towards()
			baseLifePoints = 1
			baseAttackDamage = 1
			baseAttackRange = 5
			baseMovementCount = 1
#			for count in attackRange:
#				attackRangeArray.append([])
#			attackRangeArray[0] = [0,1,2,4]
#			attackRangeArray[1] = [0,1,2,4]
#			attackRangeArray[2] = [0,1,2,4]
#			attackRangeArray[3] = [0,1,2,4]
#			attackRangeArray[4] = [0,1,2,4]
#			mirrorBaseDirection = true
#			match mageTowardsDirection:
#				Vector2(1,0):
#					attackRangeInitDirection = GlobalVariables.DIRECTION.RIGHT
#				Vector2(-1,0):
#					attackRangeInitDirection = GlobalVariables.DIRECTION.LEFT
#				Vector2(0,1):
#					attackRangeInitDirection = GlobalVariables.DIRECTION.DOWN
#				Vector2(0,-1):
#					attackRangeInitDirection = GlobalVariables.DIRECTION.UP
#
#			mirrorDirectionsArray = [GlobalVariables.DIRECTION.RIGHT, GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN]
##			mirrorDirectionsArray = [GlobalVariables.DIRECTION.LEFT, GlobalVariables.DIRECTION.UP, GlobalVariables.DIRECTION.DOWN]
#			if mirrorBaseDirection:
#				mirror_base_direction()
#			if !mirrorDirectionsArray.has(attackRangeInitDirection):
#				mirrorDirectionsArray.append(attackRangeInitDirection)
			adapt_difficulty(GlobalVariables.enemyMageDifficulty)
			
			
	
	#set health bar stats 
	healthBar.set_max(lifePoints*10)
	healthBar.set_value(lifePoints*10)
	healthBar.set_step(1)
	return enemyType


func inflictDamage(inflictattackDamageVar, inflictattackTypeVar, takeDamagePosition, mainPlayer = null, CURRENTPHASE = null):
	print("IN INFLICT DAMAGE TURNCONTROLLER PHASE " + str(GlobalVariables.turnController.currentTurnWaiting))
	var barrierDefeatItem = null
	self.inflictattackType = inflictattackTypeVar
	if inflictattackType == GlobalVariables.ATTACKTYPE.SAVED:
		#print("ENEMY WAS SAVED")
		playSavedAnimation = true
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
		lifePoints -= inflictattackDamageVar
		healthBar.set_value(lifePoints*10)
	if lifePoints <= 0:
		enemyDefeated = true
		if CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYER || CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE || CURRENTPHASE == GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE || CURRENTPHASE == GlobalVariables.CURRENTPHASE.ENEMYATTACK:
			print("Playing defeat animation")
			play_defeat_animation(mainPlayer, CURRENTPHASE)
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
			#move mage enmy after being hit 
			set_process(false)
			$MageAnimationPlayer.play(animationToPlay, -1, 2.0)
			yield($MageAnimationPlayer, "animation_finished")
			set_process(true)
			if move_mage_after_hit():
				print("IN here")
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
	print("Played defeat animation")
	emit_signal("enemyDefeated", self)
		
func makeEnemyBarrier(currentGrid, unlockedDoor):
	randomize()
	#determins if door is barrier or not 
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
