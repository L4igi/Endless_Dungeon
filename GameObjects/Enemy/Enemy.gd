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

var attackRangeRight = 0

var attackRangeLeft = 0

var attackRangeUp = 0

var attackRangeDown = 0

var attackRangeUpLeft = 0

var attackRangeUpRight = 0

var attackRangeDownLeft = 0

var attackRangeDownRight = 0

var attackRangeNode = null

func _ready():
	pass
	

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
		enemyMovement()


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
			

func calc_enemy_move_to(calcMode, activeRoom):
	var cell_target = Vector2.ZERO
	var movementdirectionVector = Vector2.ZERO
	match enemyType:
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			movementdirectionVector = Grid.get_enemy_move_towards_player(self)
			cell_target = Grid.world_to_map(position)+ movementdirectionVector

		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			if mageMoveCount == 6:
				mageMoveCount = 0
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
			movementdirectionVector = Grid.get_enemy_move_mage_pattern(self, movementdirection, activeRoom)
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

	if waitingForEventBeforeContinue != null:
		if lifePoints <= 0:
			play_defeat_animation(Grid.mainPlayer, waitingForEventBeforeContinue)
		else:
			play_taken_damage_animation(inflictattackType,Grid.mainPlayer, waitingForEventBeforeContinue)
	elif attackCount + movementCount < maxTurnActions:
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
				emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackTo, attackType,  attackDamage)
			attackCount += 1
			if attackCount + movementCount < maxTurnActions:
				enemyMovement()
			else:
				emit_signal("enemyMadeMove", self)

		
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			if mageOnOff == 1:
				mageOnOff = 0
				if attackTo != Vector2.ZERO:
					set_process(false)
					$MageAnimationPlayer.play("attack", -1, 3.0)
					$Tween.interpolate_property($Sprite, "position", attackTo*GlobalVariables.tileSize, Vector2(), $MageAnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
					$Tween.start()
					yield($MageAnimationPlayer, "animation_finished")
					$MageAnimationPlayer.play("idle")
					set_process(true)
					emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackTo, attackType, attackDamage)
				attackCount += 1
				if attackCount + movementCount < maxTurnActions:
					enemyMovement()
				else:
					emit_signal("enemyMadeMove", self)
			else:
				mageOnOff = 1
				attackCount += 1
				if attackCount + movementCount < maxTurnActions:
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
				emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackTo, attackType, attackDamage)
			attackCount += 1
			if attackCount + movementCount < maxTurnActions:
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
				emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackTo, attackType, attackDamage)
				attackCount += 1
			if attackCount + movementCount < maxTurnActions:
				enemyMovement()
			else:
				emit_signal("enemyMadeMove", self)
				
func adjust_enemy_attack_range_enable_attack(calcMode):
	var cellsToColor = []
	if attackRangeNode != null:
		attackRangeNode.queue_free()
	attackRangeNode = Node2D.new()
	Grid.add_child(attackRangeNode)
	var enemyMapPostion = Grid.world_to_map(position)
	var attackToSet = false
	if attackRangeUp > 0: 
		for attackRange in range (1,attackRangeUp+1):
			print(attackRange)
			var checkCell = enemyMapPostion + Vector2(0, -attackRange)
			var checkCellValue = Grid.get_cellv(checkCell)
			if checkCellValue == Grid.get_tileset().find_tile_by_name("PLAYER"):
				attackTo = Vector2(0, -attackRange)
				attackCell = checkCell
				attackToSet = true
			elif checkCellValue != Grid.get_tileset().find_tile_by_name("WALL") || checkCellValue != Grid.get_tileset().find_tile_by_name("DOOR") || checkCellValue != Grid.get_tileset().find_tile_by_name("UNLOCKEDDOOR"):
				var dangerField = TextureRect.new()
				dangerField.set_texture(dangerFieldTexture)
				dangerField._set_position(checkCell*GlobalVariables.tileSize)
				attackRangeNode.add_child(dangerField)
			else:
				attackRangeUp = attackRange - 1
				break
	if attackRangeDown > 0: 
		for attackRange in range (1, attackRangeDown+1):
			var checkCell = enemyMapPostion + Vector2(0, attackRange)
			var checkCellValue = Grid.get_cellv(checkCell)
			if checkCellValue == Grid.get_tileset().find_tile_by_name("PLAYER"):
				attackTo = Vector2(0, attackRange)
				attackCell = checkCell
				attackToSet = true
			elif checkCellValue != Grid.get_tileset().find_tile_by_name("WALL") || checkCellValue != Grid.get_tileset().find_tile_by_name("DOOR") || checkCellValue != Grid.get_tileset().find_tile_by_name("UNLOCKEDDOOR"):
				pass
			else:
				attackRangeDown = attackRange - 1
				break
	if attackRangeRight > 0: 
		for attackRange in range (1,attackRangeRight+1):
			var checkCell = enemyMapPostion + Vector2(attackRange,0)
			var checkCellValue = Grid.get_cellv(checkCell)
			if checkCellValue == Grid.get_tileset().find_tile_by_name("PLAYER"):
				attackTo = Vector2(attackRange,0)
				attackCell = checkCell
				attackToSet = true
			elif checkCellValue != Grid.get_tileset().find_tile_by_name("WALL") || checkCellValue != Grid.get_tileset().find_tile_by_name("DOOR") || checkCellValue != Grid.get_tileset().find_tile_by_name("UNLOCKEDDOOR"):
				pass
			else:
				attackRangeRight = attackRange - 1
				break
	if attackRangeLeft > 0: 
		for attackRange in range (1,attackRangeLeft+1):
			var checkCell = enemyMapPostion + Vector2(-attackRange,0)
			var checkCellValue = Grid.get_cellv(checkCell)
			if checkCellValue == Grid.get_tileset().find_tile_by_name("PLAYER"):
				attackTo = Vector2(-attackRange,0)
				attackCell = checkCell
				attackToSet = true
			elif checkCellValue != Grid.get_tileset().find_tile_by_name("WALL") || checkCellValue != Grid.get_tileset().find_tile_by_name("DOOR") || checkCellValue != Grid.get_tileset().find_tile_by_name("UNLOCKEDDOOR"):
				pass
			else:
				attackRangeLeft = attackRange - 1
				break
	if attackRangeUpLeft > 0: 
		for attackRange in range (1,attackRangeUpLeft+1):
			var checkCell = enemyMapPostion + Vector2(-attackRange, -attackRange)
			var checkCellValue = Grid.get_cellv(checkCell)
			if checkCellValue == Grid.get_tileset().find_tile_by_name("PLAYER"):
				attackTo = Vector2(-attackRange, -attackRange)
				attackCell = checkCell
				attackToSet = true
			elif checkCellValue != Grid.get_tileset().find_tile_by_name("WALL") || checkCellValue != Grid.get_tileset().find_tile_by_name("DOOR") || checkCellValue != Grid.get_tileset().find_tile_by_name("UNLOCKEDDOOR"):
				pass
			else:
				attackRangeUpLeft = attackRange - 1
				break
	if attackRangeUpRight > 0: 
		for attackRange in range (1,attackRangeUpRight+1):
			var checkCell = enemyMapPostion + Vector2(attackRange, -attackRange)
			var checkCellValue = Grid.get_cellv(checkCell)
			if checkCellValue == Grid.get_tileset().find_tile_by_name("PLAYER"):
				attackTo = Vector2(attackRange, -attackRange)
				attackCell = checkCell
				attackToSet = true
			elif checkCellValue != Grid.get_tileset().find_tile_by_name("WALL") || checkCellValue != Grid.get_tileset().find_tile_by_name("DOOR") || checkCellValue != Grid.get_tileset().find_tile_by_name("UNLOCKEDDOOR"):
				pass
			else:
				attackRangeUpRight = attackRange - 1
				break
	if attackRangeDownLeft > 0: 
		for attackRange in range (1,attackRangeDownLeft+1):
			var checkCell = enemyMapPostion + Vector2(-attackRange, attackRange)
			var checkCellValue = Grid.get_cellv(checkCell)
			if checkCellValue == Grid.get_tileset().find_tile_by_name("PLAYER"):
				attackTo = Vector2(-attackRange, attackRange)
				attackCell = checkCell
				attackToSet = true
			elif checkCellValue != Grid.get_tileset().find_tile_by_name("WALL") || checkCellValue != Grid.get_tileset().find_tile_by_name("DOOR") || checkCellValue != Grid.get_tileset().find_tile_by_name("UNLOCKEDDOOR"):
				pass
			else:
				attackRangeDownLeft = attackRange - 1
				break
	if attackRangeDownRight > 0: 
		for attackRange in range (1,attackRangeDownRight+1):
			var checkCell = enemyMapPostion + Vector2(attackRange, attackRange)
			var checkCellValue = Grid.get_cellv(checkCell)
			if checkCellValue == Grid.get_tileset().find_tile_by_name("PLAYER"):
				attackTo = Vector2(attackRange, attackRange)
				attackCell = checkCell
				attackToSet = true
			elif checkCellValue != Grid.get_tileset().find_tile_by_name("WALL") || checkCellValue != Grid.get_tileset().find_tile_by_name("DOOR") || checkCellValue != Grid.get_tileset().find_tile_by_name("UNLOCKEDDOOR"):
				pass
			else:
				attackRangeDownRight = attackRange - 1
				break
	if enemyType == GlobalVariables.ENEMYTYPE.WARRIROENEMY:
		print ("calculating player to attack attackto " + str(attackTo))
		print("current player position " + str(Grid.world_to_map(Grid.mainPlayer.position)))
	if !attackToSet:
		attackTo = Vector2.ZERO
		attackCell = Vector2.ZERO
	
func make_enemy_turn():
	if !isDisabled:
		if(lifePoints > 0):
			movementCount = 0
			attackCount = 0
			enemyTurnDone = false
			matchEnemyTurn()
			
			
func matchEnemyTurn():
	calc_enemy_attack_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION)
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
			get_node("Sprite").set_visible(true)
			makeEnemyBarrier(currentGrid, unlockedDoor)
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.NINJAENEMY
			attackType = GlobalVariables.ATTACKTYPE.NINJA
			get_node("SpriteNinjaEnemy").set_visible(true)
			diagonalAttack = true
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.WARRIROENEMY
			lifePoints = 1
			attackDamage = 1 
			attackType = GlobalVariables.ATTACKTYPE.SWORD
			get_node("SpriteWarriorEnemy").set_visible(true)
			attackRangeRight = 2
			attackRangeLeft = 2
			attackRangeUp = 2
			attackRangeDown = 2
			attackRangeUpLeft = 2
			attackRangeUpRight = 2
			attackRangeDownLeft = 2
			attackRangeDownRight = 2
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.MAGEENEMY
			mageMoveCount = mageEnemyCount
			attackType = GlobalVariables.ATTACKTYPE.MAGIC
			get_node("SpriteMageEnemy").set_visible(true)
	return enemyType

func inflictDamage(inflictattackDamage, inflictattackType, takeDamagePosition, mainPlayer = null, CURRENTPHASE = null):
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
	if lifePoints <= 0:
		if CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYER || CURRENTPHASE == GlobalVariables.CURRENTPHASE.BLOCK || CURRENTPHASE == GlobalVariables.CURRENTPHASE.PROJECTILE:
			play_defeat_animation(mainPlayer, CURRENTPHASE)
		elif CURRENTPHASE == GlobalVariables.CURRENTPHASE.ENEMY:
			waitingForEventBeforeContinue = CURRENTPHASE
	else:
		if CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYER || CURRENTPHASE == GlobalVariables.CURRENTPHASE.BLOCK || CURRENTPHASE == GlobalVariables.CURRENTPHASE.PROJECTILE:
			play_taken_damage_animation(inflictattackDamage, mainPlayer, CURRENTPHASE)
		elif CURRENTPHASE == GlobalVariables.CURRENTPHASE.ENEMY:
				waitingForEventBeforeContinue = CURRENTPHASE
	
	
func play_taken_damage_animation(inflictattackType, mainPlayer, CURRENTPHASE):
	if CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYER:
		mainPlayer.waitingForEventBeforeContinue = true
	elif CURRENTPHASE == GlobalVariables.CURRENTPHASE.BLOCK:
		mainPlayer.waitingForEventBeforeContinue = true
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
	
	if CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYER:
		mainPlayer.waitingForEventBeforeContinue = false
		
	elif CURRENTPHASE == GlobalVariables.CURRENTPHASE.BLOCK:
		emit_signal("enemyExplosionDone", self)
		
		
	elif CURRENTPHASE == GlobalVariables.CURRENTPHASE.ENEMY:
		inflictattackType = null
		waitingForEventBeforeContinue = null
		
		if attackCount + movementCount < maxTurnActions:
			enemyAttack()
		else:
			emit_signal("enemyMadeMove", self)
			
	elif CURRENTPHASE == GlobalVariables.CURRENTPHASE.PROJECTILE:
		hitByProjectile = null
		if hitByProjectile!=null:
			hitByProjectile.emit_signal("playerEnemieProjectileMadeMove",hitByProjectile,"movePlayerProjectiles")
			hitByProjectile.queue_free()
		

func play_defeat_animation(mainPlayer, CURRENTPHASE):
	Grid.set_cellv(Grid.world_to_map(self.position), Grid.get_tileset().find_tile_by_name("FLOOR")) 
	if CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYER:
		mainPlayer.waitingForEventBeforeContinue = true

	elif CURRENTPHASE == GlobalVariables.CURRENTPHASE.BLOCK:
		mainPlayer.waitingForEventBeforeContinue = true
	
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
			
	if CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYER:
		emit_signal("enemyDefeated", self, CURRENTPHASE)
		
	elif CURRENTPHASE == GlobalVariables.CURRENTPHASE.BLOCK:
		emit_signal("enemyExplosionDone", self)
		
	elif CURRENTPHASE == GlobalVariables.CURRENTPHASE.ENEMY:
		emit_signal("enemyDefeated", self, CURRENTPHASE)
		
	elif CURRENTPHASE == GlobalVariables.CURRENTPHASE.PROJECTILE:
		emit_signal("enemyDefeated", self, CURRENTPHASE, hitByProjectile)
		
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
