extends Node2D

onready var Grid = get_parent()

onready var pixelfont = preload("res://GUI/pixelFont.tres")

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.PLAYER

var playerTurnDone = false 

var playerCanAttack = false 
var playerPreviousPosition = Vector2.ZERO

signal playerAttacked (player, attackDirection, attackDamage)

var playerPassedDoor = Vector2.ZERO

var movementCount = 0

var maxTurnActions = 5

var attackCount = 0

var attackDamage = 0.5

var swordAttackDamage = 0.5

var magicAttackDamage = 0.5

var powerBlockAttackDamage = 1.0

var coinCount = 0

var maxLifePoints = 10

var lifePoints = 10

var maxPotions = 2

var currentPotions = 0

var itemsInPosession = []

var usedItems = []

var inClearedRoom = true

var inRoomType = null

var attackType = GlobalVariables.ATTACKTYPE.SWORD

var GUI = preload("res://GUI/GUIScene.tscn")

var Inventory = preload("res://Inventory/Inventory.tscn")

var InventoryItem = preload("res://Inventory/InventorySlot.tscn")

var PlayerCamera = preload("res://Camera/Camera.tscn")

var PauseMenu = preload("res://PauseMenu/PauseMenu.tscn")

var mainCamera = null

var guiElements = null

var inventoryElements = null

var pauseMenu = null

var movedThroughDoorDirection = Vector2.ZERO 

var disablePlayerInput = false 

var waitingForEventBeforeContinue = false

var puzzleBlockInteraction = false

var playerBackupPosition

var playerDefeated = false

var playerPassingDoor = false

var queueInflictDamage = false

var queueInflictEnemyType = null

var enemyQueueAttackDamage = 0

var enemyQueueAttackType = null

var inInventory = false

var toggledDangerArea = false

var enemyToToggleArea = null

var checkNextAction = true

var playerWalkedThroughDoorPosition = Vector2.ZERO

var canRepeatPuzzlePattern = true

signal toggleDangerArea (enemyToToggleArea, toggleAll)

signal puzzleBlockInteractionSignal (player, puzzleBlockDirection)

var restMovesAttack = false

func _ready():
	print(GlobalVariables.chosenDifficulty)
	guiElements = GUI.instance()
	add_child(guiElements)
	#GlobalVariables.turnController.player_next_action(self)
	guiElements.setUpGUI(maxTurnActions, maxLifePoints, lifePoints, coinCount, maxPotions, currentPotions)
	
	inventoryElements = Inventory.instance()
	inventoryElements.currentPlayerPosition = self.position
	guiElements.add_child(inventoryElements)
	
	pauseMenu = PauseMenu.instance()
	guiElements.add_child(pauseMenu)
	
	mainCamera = PlayerCamera.instance()
	mainCamera.make_current()
	Grid.connect("moveCameraSignal", mainCamera, "on_move_camera_signal")
	add_child(mainCamera)
	
	Grid.connect("enemyTurnDoneSignal", self, "_on_enemy_turn_done_signal")
	
	disablePlayerInput = true
	$AnimationPlayer.play("Spawn", -1, 3.5)
	yield($AnimationPlayer, "animation_finished")
	disablePlayerInput = false
	
		
func _process(_delta):
	if !disablePlayerInput && !inInventory:
		if movedThroughDoorDirection!=Vector2.ZERO:
			player_passed_door()
			guiElements.update_current_turns(true)
			toggledDangerArea = false
			movedThroughDoorDirection=Vector2.ZERO
			return 
			
		toggle_enemy_danger_areas()
		get_use_nonkey_items()
		var  attackMode = get_attack_mode()
		if attackMode:
			attackType = attackMode
		
		if puzzleBlockInteraction:
			get_movement_direction()
			var attackDirection = get_attack_direction()
			player_interact_puzzle_block(attackDirection)
		
		if checkNextAction:
			if !puzzleBlockInteraction && !playerPassingDoor && !playerDefeated:
				var movementDirection = get_free_movement_direction()
				var attackDirection = get_attack_direction()
				player_movement(movementDirection)
				player_attack(attackDirection)
				
func player_movement(movementDirection):
	if GlobalVariables.turnController.queueDropLoot:
		GlobalVariables.turnController.player_turn_done(self)
		return
	if movementDirection && (attackCount + movementCount) < maxTurnActions:
		var target_position = Grid.request_move(self, movementDirection)
		if target_position:
			set_process(false)
			#play attack animation 
			var animationPlay = str("walk_right")
			match movementDirection:
				Vector2(1,0):
					animationPlay = str("walk_right")
				Vector2(-1,0):
					animationPlay = str("walk_left")
				Vector2(0,1):
					animationPlay = str("walk_down")
				Vector2(0,-1):
					animationPlay = str("walk_up")
			$AnimationPlayer.play(animationPlay, -1, 6.0)
			$Tween.interpolate_property(self, "position", position, target_position , $AnimationPlayer.current_animation_length/6.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
			playerPreviousPosition = position
			#position = target_position
			$Tween.start()
			yield($AnimationPlayer, "animation_finished")
			$AnimationPlayer.play("Idle")
			if queueInflictDamage == true:
				inflict_damage_playerDefeated(enemyQueueAttackDamage, enemyQueueAttackType, queueInflictEnemyType)
				queueInflictDamage = false
				enemyQueueAttackDamage = 0
				enemyQueueAttackType = null
			set_process(true)
#			update_enemy_move_attack()
			movementCount += 1
			guiElements.update_current_turns()
			GlobalVariables.turnController.player_turn_done(self)
			
	
func player_attack(attackDirection):
	if attackDirection && (attackCount + movementCount) < maxTurnActions:
		set_process(false)
		#play attack animation 
		var animationPlay = str("attack_right")
		match attackDirection:
			Vector2(1,0):
				animationPlay = str("attack_right")
			Vector2(-1,0):
				animationPlay = str("attack_left")
			Vector2(0,1):
				animationPlay = str("attack_down")
			Vector2(0,-1):
				animationPlay = str("attack_up")
		if attackType == GlobalVariables.ATTACKTYPE.MAGIC:
			animationPlay = str("attack_magic")
		if attackType == GlobalVariables.ATTACKTYPE.BLOCK:
			animationPlay = str("attack_pickaxe")
		if attackType == GlobalVariables.ATTACKTYPE.HAND:
			animationPlay = str("attack_hand")
		$AnimationPlayer.play(animationPlay, -1, 4.5)
#		$Tween.interpolate_property($Sprite, "position",attackDirection * GlobalVariables.tileSize, Vector2(), $AnimationPlayer.current_animation_length/2.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.interpolate_property($Sprite, "position",attackDirection * GlobalVariables.tileSize/4, Vector2(), $AnimationPlayer.current_animation_length/4.5, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
		$Tween.start()
		yield($AnimationPlayer, "animation_finished")
		$AnimationPlayer.play("Idle")
		set_process(true)
		var restMultiplier = 1
		if restMovesAttack:
			restMultiplier = maxTurnActions-movementCount-attackCount
		if attackType == GlobalVariables.ATTACKTYPE.MAGIC:
			emit_signal("playerAttacked", self, attackDirection, magicAttackDamage*restMultiplier, attackType)
		elif attackType == GlobalVariables.ATTACKTYPE.SWORD:
			emit_signal("playerAttacked", self, attackDirection, swordAttackDamage*restMultiplier, attackType)
		else:
			emit_signal("playerAttacked", self, attackDirection, restMultiplier, attackType)
		attackCount += 1
		if restMovesAttack:
			restMovesAttack = false
			attackCount = maxTurnActions-movementCount
			guiElements.update_current_turns(false, attackCount)
		else:
			guiElements.update_current_turns()
		GlobalVariables.turnController.player_turn_done(self)
	
func player_passed_door():
	var targetPosition = Grid.request_move(self,movedThroughDoorDirection)
	if (targetPosition):
		disablePlayerInput = true
		playerPreviousPosition = position
		var animationPlay = str("walk_right")
		match movedThroughDoorDirection:
			Vector2(1,0):
				animationPlay = str("walk_right")
			Vector2(-1,0):
				animationPlay = str("walk_left")
			Vector2(0,1):
				animationPlay = str("walk_down")
			Vector2(0,-1):
				animationPlay = str("walk_up")
		$AnimationPlayer.play(animationPlay, -1, 8.0)
		$Tween.interpolate_property(self, "position", position, targetPosition , $AnimationPlayer.current_animation_length/8.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
		playerPreviousPosition = position
		#position = target_position
		$Tween.start()
		yield($AnimationPlayer, "animation_finished")
		$AnimationPlayer.play("Idle")
		set_process(true)
#		update_enemy_move_attack()
		if Grid.activeRoom != null && Grid.activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
			guiElements.change_hand_on_room(GlobalVariables.ROOM_TYPE.PUZZLEROOM)
			disablePlayerInput = false
#			emit_signal("playerMadeMove")
			#GlobalVariables.turnController.player_turn_done(self)
		else:
			#GlobalVariables.turnController.player_turn_done(self)
			guiElements.change_hand_on_room(GlobalVariables.ROOM_TYPE.ENEMYROOM)
			disablePlayerInput = false
			
	
func player_interact_puzzle_block(puzzleBlockDirection):
	if puzzleBlockDirection:
		emit_signal("puzzleBlockInteractionSignal", self, puzzleBlockDirection)
		#checkNextAction = GlobalVariables.turnController.player_turn_done(self)
	
func get_free_movement_direction():
	if Input.is_action_pressed("player_up"):
		puzzleBlockInteraction = false
		return Vector2(0,-1)
	if Input.is_action_pressed("player_down"):
		puzzleBlockInteraction = false
		return Vector2(0,1)
	if Input.is_action_pressed("player_left"):
		puzzleBlockInteraction = false
		return Vector2(-1,0)
	if Input.is_action_pressed("player_right"):
		puzzleBlockInteraction = false
		return Vector2(1,0)
	
func get_movement_direction():
	if Input.is_action_just_pressed("player_up"):
		puzzleBlockInteraction = false
		return Vector2(0,-1)
	if Input.is_action_just_pressed("player_down"):
		puzzleBlockInteraction = false
		return Vector2(0,1)
	if Input.is_action_just_pressed("player_left"):
		puzzleBlockInteraction = false
		return Vector2(-1,0)
	if Input.is_action_just_pressed("player_right"):
		puzzleBlockInteraction = false
		return Vector2(1,0)

func get_attack_direction():
	if Input.is_action_just_pressed("restActionsAction"):
		match attackType:
			GlobalVariables.ATTACKTYPE.SWORD:
				update_enemy_preview(swordAttackDamage*(maxTurnActions-(movementCount+attackCount)))
			GlobalVariables.ATTACKTYPE.MAGIC:
				update_enemy_preview(magicAttackDamage*(maxTurnActions-(movementCount+attackCount)))
	if Input.is_action_just_released("restActionsAction"):
		match attackType:
			GlobalVariables.ATTACKTYPE.SWORD:
				update_enemy_preview(swordAttackDamage)
			GlobalVariables.ATTACKTYPE.MAGIC:
				update_enemy_preview(magicAttackDamage)
				
	if attackType == GlobalVariables.ATTACKTYPE.SWORD || attackType == GlobalVariables.ATTACKTYPE.MAGIC ||attackType == GlobalVariables.ATTACKTYPE.HAND:
		if Input.is_action_pressed("restActionsAction") && Input.is_action_just_pressed("Attack_Right"):
			restMovesAttack = true
			return Vector2(1,0)
		if Input.is_action_pressed("restActionsAction") && Input.is_action_just_pressed("Attack_Left"):
			restMovesAttack = true
			return Vector2(-1,0)
		if Input.is_action_pressed("restActionsAction") && Input.is_action_just_pressed("Attack_Up"):
			restMovesAttack = true
			return Vector2(0,-1)
		if Input.is_action_pressed("restActionsAction") && Input.is_action_just_pressed("Attack_Down"):
			restMovesAttack = true
			return Vector2(0,1)
	if Input.is_action_just_pressed("Attack_Up"):
		return Vector2(0,-1)
	if Input.is_action_just_pressed("Attack_Down"):
		return Vector2(0,1)
	if Input.is_action_just_pressed("Attack_Left"):
		return Vector2(-1,0)
	if Input.is_action_just_pressed("Attack_Right"):
		return Vector2(1,0)

func get_attack_mode():
	if Input.is_action_just_pressed("Mode_Sword"):
		guiElements.change_attack_mode(GlobalVariables.ATTACKTYPE.SWORD)
		puzzleBlockInteraction = false
		update_enemy_preview(swordAttackDamage)
		return GlobalVariables.ATTACKTYPE.SWORD
		
	if Input.is_action_just_pressed("Mode_Magic"):
		guiElements.change_attack_mode(GlobalVariables.ATTACKTYPE.MAGIC)
		#if used in puzzle room while magic is flying cancels out all magic
		if attackType == GlobalVariables.ATTACKTYPE.MAGIC:
			if GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PUZZLEPROJECTILE:
				Grid.cancelMagicPuzzleRoom=true
		puzzleBlockInteraction = false
		update_enemy_preview(magicAttackDamage)
		return GlobalVariables.ATTACKTYPE.MAGIC
		
	if Input.is_action_just_pressed("Mode_Block"):
		guiElements.change_attack_mode(GlobalVariables.ATTACKTYPE.BLOCK)
		puzzleBlockInteraction = false
		update_enemy_preview(powerBlockAttackDamage)
		return GlobalVariables.ATTACKTYPE.BLOCK                     	
		
	if Input.is_action_just_pressed("Mode_Hand"):
		guiElements.change_attack_mode(GlobalVariables.ATTACKTYPE.HAND)
		puzzleBlockInteraction = false
		return GlobalVariables.ATTACKTYPE.HAND
		
func get_use_nonkey_items():
	if lifePoints < maxLifePoints:
		if Input.is_action_just_pressed("Potion"):
			if guiElements.use_potion():
				if lifePoints + 5 > maxLifePoints:
					lifePoints = maxLifePoints
					guiElements.set_health(maxLifePoints)
					get_node("PotionPlayer").stream = load("res://GameObjects/Player/use_potion.wav")
					get_node("PotionPlayer").play()
				else:
					lifePoints += 5 
					guiElements.change_health(-5)

func toggle_enemy_danger_areas():
	if Grid.activeRoom != null && !Grid.activeRoom.enemiesInRoom.empty():
		if Input.is_action_just_pressed("toggle_danger_area_next") and Input.is_action_just_pressed("toggle_danger_area_previous") || Input.is_action_pressed("toggle_danger_area_next") and Input.is_action_just_pressed("toggle_danger_area_previous") ||Input.is_action_pressed("toggle_danger_area_previous") and Input.is_action_just_pressed("toggle_danger_area_next"):
			#print("pressed both at once")
			if toggledDangerArea:
				toggledDangerArea = false
			else: 
				toggledDangerArea = true
			enemyToToggleArea = null
			emit_signal("toggleDangerArea", enemyToToggleArea, true)
		elif Input.is_action_just_pressed("toggle_danger_area_previous") && toggledDangerArea:
			if Grid.activeRoom !=null:
				if enemyToToggleArea == null:
					enemyToToggleArea = Grid.activeRoom.enemiesInRoom.size()-1
				elif enemyToToggleArea <= 0:
					enemyToToggleArea = null
				else:
					enemyToToggleArea -= 1
					while Grid.activeRoom.enemiesInRoom[enemyToToggleArea].helpEnemy:
						enemyToToggleArea -=1
						if enemyToToggleArea <= 0:
							enemyToToggleArea = 0
							break
				emit_signal("toggleDangerArea", enemyToToggleArea)
		elif Input.is_action_just_pressed("toggle_danger_area_next") && toggledDangerArea:
			if Grid.activeRoom !=null:
				if enemyToToggleArea == null:
					enemyToToggleArea = 0
				elif enemyToToggleArea >= Grid.activeRoom.enemiesInRoom.size()-1:
					enemyToToggleArea = null
				else:
					enemyToToggleArea += 1
					while Grid.activeRoom.enemiesInRoom[enemyToToggleArea].helpEnemy:
						enemyToToggleArea +=1
						if enemyToToggleArea >= Grid.activeRoom.enemiesInRoom.size():
							enemyToToggleArea = 0
							break
				emit_signal("toggleDangerArea", enemyToToggleArea)
				
	elif Grid.activeRoom != null && !inClearedRoom && Grid.activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM && canRepeatPuzzlePattern:
		if Input.is_action_just_pressed("toggle_danger_area_next") and Input.is_action_just_pressed("toggle_danger_area_previous") || Input.is_action_pressed("toggle_danger_area_next") and Input.is_action_just_pressed("toggle_danger_area_previous") ||Input.is_action_pressed("toggle_danger_area_previous") and Input.is_action_just_pressed("toggle_danger_area_next"):
			Grid.play_puzzlepiece_pattern(false)
		#repeat puzzle order
			
func inflict_damage_playerDefeated(attackDamageVar, attackTypeVar, enemyType):
	match enemyType:
		GlobalVariables.ENEMYTYPE.BARRIERENEMY:
			GlobalVariables.hitByBarrier += 1
			if GlobalVariables.hitByBarrier%int((5* GlobalVariables.globalDifficultyMultiplier)):
				if GlobalVariables.enemyBarrierDifficulty > 1:
					GlobalVariables.enemyBarrierDifficulty -= 1
		GlobalVariables.ENEMYTYPE.WARRIROENEMY:
			GlobalVariables.hitByWarrior += 1
			if GlobalVariables.hitByWarrior%int((5* GlobalVariables.globalDifficultyMultiplier)):
				if GlobalVariables.enemyWarriorDifficulty > 1:
					GlobalVariables.enemyWarriorDifficulty -= 1
		GlobalVariables.ENEMYTYPE.MAGEENEMY:
			GlobalVariables.hitByMage += 1
			if GlobalVariables.hitByMage%int((5* GlobalVariables.globalDifficultyMultiplier)):
				if GlobalVariables.enemyMageDifficulty > 1:
					GlobalVariables.enemyMageDifficulty -= 1
		GlobalVariables.ENEMYTYPE.NINJAENEMY:
			GlobalVariables.hitByNinja += 1
			if GlobalVariables.hitByNinja%int((5* GlobalVariables.globalDifficultyMultiplier)):
				if GlobalVariables.enemyNinjaDifficulty > 1:
					GlobalVariables.enemyNinjaDifficulty -= 1
	if !GlobalVariables.turnController.playerTakeDamage.has(self):
		GlobalVariables.turnController.playerTakeDamage.append(self)
	lifePoints -= attackDamageVar
	guiElements.change_health(attackDamageVar)
	if lifePoints > 0:
		var animationToPlay = str("take_damage_physical")
		if attackTypeVar == GlobalVariables.ATTACKTYPE.MAGIC:
			animationToPlay = str("take_damage_magic")
		set_process(false)
		#print("Playing hit animation")
		$AnimationPlayer.play(animationToPlay, -1)
		$Tween.interpolate_property($Sprite, "position", Vector2(), Vector2() , $AnimationPlayer.current_animation_length, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		yield($AnimationPlayer, "animation_finished")
		$AnimationPlayer.play("Idle")
		set_process(true)
		Grid.set_cellv(Grid.world_to_map(position), Grid.get_tileset().find_tile_by_name("PLAYER"))
		disablePlayerInput = false
		waitingForEventBeforeContinue = false
		GlobalVariables.turnController.on_player_taken_damage(self)
	else:
		print ("in player defeated")
		toggledDangerArea = false
		set_process(false)
		$AnimationPlayer.play("defeat", -1, 2.0)
		yield($AnimationPlayer, "animation_finished")
		set_process(true)
		get_node("Sprite").set_visible(false)
		GlobalVariables.turnController.player_defeat()

func add_nonkey_items(itemtype, coinValue = 1):
	match itemtype:
		GlobalVariables.ITEMTYPE.POTION:
			if currentPotions < maxPotions:
				currentPotions+=1
				if currentPotions > maxPotions:
					currentPotions = maxPotions
				guiElements.fill_potions(currentPotions)
		GlobalVariables.ITEMTYPE.COIN:
			coinCount += coinValue
			guiElements.add_coin(coinCount)
		GlobalVariables.ITEMTYPE.FILLUPHALFHEART:
			if lifePoints < maxLifePoints:
				lifePoints+=1
				if lifePoints > maxLifePoints:
					lifePoints = maxLifePoints
				guiElements.set_health(lifePoints)
		GlobalVariables.ITEMTYPE.FILLUPHEART:
			if lifePoints < maxLifePoints:
				lifePoints+=2
				if lifePoints > maxLifePoints:
					lifePoints = maxLifePoints
				guiElements.set_health(lifePoints)

func add_key_item_to_inventory(item):
	var newInventoryItem = InventoryItem.instance()
	newInventoryItem.itemKeyValue = item.keyValue
	newInventoryItem.get_node("ItemTexture").set_texture(item.get_node("Sprite").get_texture())
	newInventoryItem.get_node("ItemTexture").set_modulate(item.get_node("Sprite").get_modulate())
	newInventoryItem.get_node("ItemLabel").set_text(str(item.keyValue))
	if item.itemType == GlobalVariables.ITEMTYPE.KEY:
		inventoryElements.get_node("Tabs/Key/KeyList").add_child(newInventoryItem)
	if item.itemType == GlobalVariables.ITEMTYPE.WEAPON:
		inventoryElements.get_node("Tabs/Weapon/WeaponList").add_child(newInventoryItem)
#	inventoryElements.popup()
#	inventoryElements.rect_position = self.position

func remove_key_item_from_inventory(item):
	itemsInPosession.erase(item)
	var keyItemToDelete 
	if item.itemType == GlobalVariables.ITEMTYPE.KEY:
		for keyitem in inventoryElements.get_node("Tabs/Key/KeyList").get_children():
			if keyitem.itemKeyValue == item.keyValue:
				keyItemToDelete = keyitem
			else:
				pass
		inventoryElements.get_node("Tabs/Key/KeyList").remove_child(keyItemToDelete)
	elif item.itemType == GlobalVariables.ITEMTYPE.WEAPON:
		for keyitem in inventoryElements.get_node("Tabs/Weapon/WeaponList").get_children():
			if keyitem.itemKeyValue == item.keyValue:
				keyItemToDelete = keyitem
			else:
				pass
		inventoryElements.get_node("Tabs/Weapon/WeaponList").remove_child(keyItemToDelete)

func on_upgradeContainer_interaction(upgradeType, addAmount, spentAmount):
	coinCount-=spentAmount
	guiElements.spend_coins(coinCount)
	match upgradeType:
		GlobalVariables.UPGRADETYPE.ACTIONSUP:
			maxTurnActions += addAmount
			guiElements.set_maxturn_actions(maxTurnActions)
		GlobalVariables.UPGRADETYPE.FILLFLASK:
			currentPotions += addAmount
			guiElements.fill_potions(currentPotions)
		GlobalVariables.UPGRADETYPE.FILLHEART:
			if lifePoints + addAmount > maxLifePoints:
				lifePoints = maxLifePoints
				guiElements.set_health(maxLifePoints)
			else:
				lifePoints += addAmount
				guiElements.change_health(-addAmount)
		GlobalVariables.UPGRADETYPE.BOMB:
			powerBlockAttackDamage+=addAmount
		GlobalVariables.UPGRADETYPE.FLASK:
			maxPotions += addAmount
			guiElements.change_max_potions(maxPotions)
		GlobalVariables.UPGRADETYPE.HEART:
			maxLifePoints+=addAmount
			guiElements.change_max_health(maxLifePoints)
		GlobalVariables.UPGRADETYPE.MAGIC:
			magicAttackDamage+=addAmount
		GlobalVariables.UPGRADETYPE.SWORD:
			swordAttackDamage+=addAmount
	
func _on_enemy_turn_done_signal():
	#print("Player turn again ")
	checkNextAction = true
	if movementCount + attackCount == maxTurnActions:
		movementCount = 0
		attackCount = 0
		guiElements.update_current_turns(true)

func do_on_player_defeated():
	position = Vector2(80,80)
	Grid.activeRoom = null
	inClearedRoom = true
	lifePoints = 10
	guiElements.set_health(10)
	get_node("AnimationPlayer").play("Idle")
	movementCount = 0
	attackCount = 0
	guiElements.update_current_turns(true)
	GlobalVariables.turnController.currentTurnWaiting = GlobalVariables.CURRENTPHASE.PLAYER
	print("IN on player defeated current turn waiting " + str(GlobalVariables.turnController.currentTurnWaiting))
	checkNextAction = true
	playerDefeated = false
	
func end_player_turn():
	disablePlayerInput=true
	playerTurnDone=true

	
func get_actions_left():
	return maxTurnActions-movementCount-attackCount
#update enemy attack after each Player move/attack
#func update_enemy_move_attack():
#	if Grid.activeRoom != null: 
#		if !Grid.activeRoom.enemiesInRoom.empty():
#			for enemy in Grid.activeRoom.enemiesInRoom:
#				enemy.calc_enemy_attack_to(GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW)

func get_equip_attack_damage():
	match attackType:
		GlobalVariables.ATTACKTYPE.SWORD:
			return swordAttackDamage
		GlobalVariables.ATTACKTYPE.MAGIC:
			return magicAttackDamage
		GlobalVariables.ATTACKTYPE.BLOCK:
			return powerBlockAttackDamage
		_:
			return 0

func update_enemy_preview(damage):
	if Grid.activeRoom != null:
		for enemy in Grid.activeRoom.enemiesInRoom:
			enemy.update_preview_healthBar(damage)
			
func update_gui_elements():
	guiElements.add_coin(coinCount)
	guiElements.change_max_health(maxLifePoints)
	guiElements.set_health(lifePoints)
	guiElements.fill_potions(currentPotions)
	guiElements.change_max_potions(maxPotions)
	guiElements.set_maxturn_actions(maxTurnActions)
	
func save():
	var save_dict = {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"maxTurnActions" : maxTurnActions,
		"attackCount" : attackCount,
		"attackDamage" : attackDamage,
		"swordAttackDamage" : swordAttackDamage,
		"magicAttackDamage" : magicAttackDamage,
		"powerBlockAttackDamage" : powerBlockAttackDamage,
		"coinCount" : coinCount,
		"maxLifePoints" : maxLifePoints,
		"lifePoints" : lifePoints,
		"maxPotions" : maxPotions,
		"currentPotions" : currentPotions
	}
	return save_dict
	
func resetStats():
	match GlobalVariables.chosenDifficulty:
		GlobalVariables.DIFFICULTYLEVELS.EASY:
			coinCount = 10
			currentPotions = 1
			maxPotions = 3
			maxLifePoints = 12
			lifePoints = 12
			maxTurnActions = 7
		GlobalVariables.DIFFICULTYLEVELS.NORMAL:
			coinCount = 5
			currentPotions = 0
			maxPotions = 2
			maxLifePoints = 10
			lifePoints = 10
			maxTurnActions = 6
		GlobalVariables.DIFFICULTYLEVELS.AUTO:
			coinCount = 0
			currentPotions = 0
			maxPotions = 2
			maxLifePoints = 10
			lifePoints = 10
			maxTurnActions = 6
		GlobalVariables.DIFFICULTYLEVELS.HARD:
			coinCount = 0
			currentPotions = 0
			maxPotions = 1
			maxLifePoints = 8
			lifePoints = 8
			maxTurnActions = 5
	
	attackDamage = 1
	swordAttackDamage = 0.75
	magicAttackDamage = 0.5
	powerBlockAttackDamage = 1.0
	lifePoints = maxLifePoints
	
	guiElements.setUpGUI(maxTurnActions, maxLifePoints, lifePoints, coinCount, maxPotions, currentPotions)
