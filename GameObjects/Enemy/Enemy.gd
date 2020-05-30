extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.ENEMY

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
				$AnimationPlayer.play("walk", -1, 1.0)
				$Tween.interpolate_property(self, "position", position, target_position, $AnimationPlayer.current_animation_length/1.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($AnimationPlayer, "animation_finished")
				$AnimationPlayer.play("idle")
				set_process(true)
				movementCount += 1
		
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
				set_process(false)
				#play defeat animation 
				$MageAnimationPlayer.play("walk", -1, 4.5)
				$Tween.interpolate_property(self, "position", position, target_position, $MageAnimationPlayer.current_animation_length/4.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($MageAnimationPlayer, "animation_finished")
				$MageAnimationPlayer.play("idle")
				set_process(true)
			movementCount += 1
			mageMoveCount+=1
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
				$NinjaAnimationPlayer.play("walk", -1, 4.5)
				$Tween.interpolate_property(self, "position", position, target_position, $NinjaAnimationPlayer.current_animation_length/4.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($NinjaAnimationPlayer, "animation_finished")
				$NinjaAnimationPlayer.play("idle")
				set_process(true)
				movementCount += 1
				
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
				$AnimationPlayer.play("walk", -1, 1.0)
				$Tween.interpolate_property(self, "position", position, target_position, $AnimationPlayer.current_animation_length/1.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
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
			if attackCount + movementCount < maxTurnActions:
				enemyMovement()
			else:
				emit_signal("enemyMadeMove", self)

		
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			if mageOnOff == 1:
				mageOnOff = 0
				var attackDirection = Grid.enableEnemyAttack(self, attackType, horizontalVerticalAttack, diagonalAttack)
				#print("attackDirection  " + str(attackDirection))
				if attackDirection != Vector2.ZERO:
					set_process(false)
					$MageAnimationPlayer.play("attack", -1, 3.0)
					$Tween.interpolate_property($Sprite, "position", attackDirection*GlobalVariables.tileSize, Vector2(), $MageAnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
					$Tween.start()
					yield($MageAnimationPlayer, "animation_finished")
					$MageAnimationPlayer.play("idle")
					set_process(true)
					emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackDirection, attackType, attackDamage)
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
			var attackDirection = Grid.enableEnemyAttack(self, attackType, horizontalVerticalAttack, diagonalAttack)
			if attackDirection.x == 1 || attackDirection.y == 1:
				attackDamage = 2
			else:
				attackDamage = 1
			if attackDirection != Vector2.ZERO:
				set_process(false)
				#play defeat animation 
				$NinjaAnimationPlayer.play("attack", -1, 4.5)
				$Tween.interpolate_property($SpriteNinjaEnemy, "position", Vector2(), attackDirection*GlobalVariables.tileSize, $NinjaAnimationPlayer.current_animation_length/4.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($NinjaAnimationPlayer, "animation_finished")
				$NinjaAnimationPlayer.play("attackBack", -1, 4.5)
				$Tween.interpolate_property($SpriteNinjaEnemy, "position", attackDirection*GlobalVariables.tileSize, Vector2(), $NinjaAnimationPlayer.current_animation_length/4.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($NinjaAnimationPlayer, "animation_finished")
				$NinjaAnimationPlayer.play("idle")
				set_process(true)
				emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackDirection, attackType, attackDamage)
			attackCount += 1
			if attackCount + movementCount < maxTurnActions:
				enemyMovement()
			else:
				emit_signal("enemyMadeMove", self)
			
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			var attackDirection = Grid.enableEnemyAttack(self, attackType, horizontalVerticalAttack, diagonalAttack)
			if attackDirection != Vector2.ZERO:
				set_process(false)
				#play defeat animation 
				$AnimationPlayer.play("attack", -1, 3.0)
				$Tween.interpolate_property($Sprite, "position", attackDirection*32, Vector2(), $AnimationPlayer.current_animation_length/3.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
				$Tween.start()
				yield($AnimationPlayer, "animation_finished")
				$AnimationPlayer.play("idle")
				set_process(true)
				emit_signal("enemyAttacked", self, Grid.world_to_map(position) + attackDirection, attackType, attackDamage)
				attackCount += 1
			if attackCount + movementCount < maxTurnActions:
				enemyMovement()
			else:
				emit_signal("enemyMadeMove", self)

func make_enemy_turn():
	if !isDisabled:
		if(lifePoints > 0):
			movementCount = 0
			attackCount = 0
			enemyTurnDone = false
			matchEnemyTurn()


func matchEnemyTurn():
	match enemyType:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			barrierenemy_type_actions()
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			mageenemy_type_actions()
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			ninjaenemy_type_actions()
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
				warriorenemy_type_actions()
						
func generateEnemy(mageEnemyCount, currentGrid): 
#	var enemieToGenerate = randi()%4
#generate warrior for testing purposes
	var enemieToGenerate = randi()%4
	match enemieToGenerate:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			enemyType = GlobalVariables.ENEMYTYPE.BARRIERENEMY
			attackType = GlobalVariables.ATTACKTYPE.SWORD
			makeEnemyBarrier(currentGrid)
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
			get_node("Sprite").set_visible(false)
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
			$AnimationPlayer.play(animationToPlay, -1, 1.0)
			yield($AnimationPlayer, "animation_finished")
			$AnimationPlayer.play("idle")
			set_process(true)

		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			set_process(false)
			$MageAnimationPlayer.play(animationToPlay, -1, 1.0)
			yield($MageAnimationPlayer, "animation_finished")
			$MageAnimationPlayer.play("idle")
			set_process(true)

		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			set_process(false)
			$NinjaAnimationPlayer.play(animationToPlay, -1, 1.0)
			yield($NinjaAnimationPlayer, "animation_finished")
			$NinjaAnimationPlayer.play("idle")
			set_process(true)

		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			set_process(false)
			$AnimationPlayer.play(animationToPlay, -1, 1.0)
			yield($AnimationPlayer, "animation_finished")
			$AnimationPlayer.play("idle")
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
	Grid.set_cellv(Grid.world_to_map(self.position), Grid.get_tileset().find_tile_by_name("EMPTY")) 
	if CURRENTPHASE == GlobalVariables.CURRENTPHASE.PLAYER:
		mainPlayer.waitingForEventBeforeContinue = true

	elif CURRENTPHASE == GlobalVariables.CURRENTPHASE.BLOCK:
		mainPlayer.waitingForEventBeforeContinue = true
	
	match enemyType:
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			set_process(false)
			$NinjaAnimationPlayer.play("defeat", -1, 1.0)
			yield($NinjaAnimationPlayer, "animation_finished")
			set_process(true)

		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			set_process(false)
			$MageAnimationPlayer.play("defeat", -1, 1.0)
			yield($MageAnimationPlayer, "animation_finished")
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
		
func makeEnemyBarrier(currentGrid):
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
		currentGrid.generate_keyValue_item(barrierKeyValue, get_node("Sprite").get_modulate(), GlobalVariables.ITEMTYPE.WEAPON)
