extends Node2D

onready var Grid = get_parent()

onready var pixelfont = preload("res://GUI/pixelFont.tres")

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.PLAYER

var playerTurnDone = false 

var playerCanAttack = false 
var playerPreviousPosition = Vector2.ZERO

signal playerMadeMove 

signal playerAttacked (player, attackDirection, attackDamage)

signal onPlayerDefeated (player, lifepoints)

var playerPassedDoor = Vector2.ZERO

var movementCount = 0

var maxTurnActions = 10
var attackCount = 0

var attackDamage = 0.5

var maxLifePoints = 10

var lifePoints = 10

var itemsInPosession = []

var usedItems = []

var inClearedRoom = true

var inRoomType = null

var attackType = GlobalVariables.ATTACKTYPE.SWORD

var GUI = preload("res://GUI/GUIScene.tscn")

var Inventory = preload("res://Inventory/Inventory.tscn")

var InventoryItem = preload("res://Inventory/InventorySlot.tscn")

var PlayerCamera = preload("res://Camera/Camera.tscn")

var mainCamera = null

var guiElements = null

var inventoryElements = null

var movedThroughDoorDirection = Vector2.ZERO 

var disablePlayerInput = false 

var waitingForEventBeforeContinue = false

var puzzleBlockInteraction = false

var playerBackupPosition

var playerDefeated = false

var playerPassingDoor = false

var queueInflictDamage = false

var enemyQueueAttackDamage = 0

var enemyQueueAttackType = null

var inInventory = false

var toggledDangerArea = false

var enemyToToggleArea = null

signal toggleDangerArea (enemyToToggleArea, toggleAll)

signal puzzleBlockInteractionSignal (player, puzzleBlockDirection)

func _ready():
	guiElements = GUI.instance()
	add_child(guiElements)
	guiElements.set_health(lifePoints)
	guiElements.set_maxturn_actions(maxTurnActions)

	
	inventoryElements = Inventory.instance()
	inventoryElements.currentPlayerPosition = self.position
	guiElements.add_child(inventoryElements)
	
	mainCamera = PlayerCamera.instance()
	mainCamera.make_current()
	Grid.connect("moveCameraSignal", mainCamera, "on_move_camera_signal")
	add_child(mainCamera)
	
	Grid.connect("enemyTurnDoneSignal", self, "_on_enemy_turn_done_signal")

func _process(delta):
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
		
		if !playerTurnDone:
			var checkNextAction = GlobalVariables.turnController.player_next_action()
		
			if checkNextAction && !puzzleBlockInteraction && !playerPassingDoor:
				var movementDirection = get_free_movement_direction()
				var attackDirection = get_attack_direction()
				player_movement(movementDirection)
				player_attack(attackDirection)

#
func player_movement(movementDirection):
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
				inflict_damage_playerDefeated(enemyQueueAttackDamage, enemyQueueAttackType)
				queueInflictDamage = false
				enemyQueueAttackDamage = 0
				enemyQueueAttackType = null
			set_process(true)
#			update_enemy_move_attack()
			movementCount += 1
			guiElements.update_current_turns()
			
	if attackCount + movementCount == maxTurnActions && !playerTurnDone:
		playerTurnDone = true
		emit_signal("playerMadeMove")
	
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
#		update_enemy_move_attack()
		if attackType == GlobalVariables.ATTACKTYPE.BLOCK:
			waitingForEventBeforeContinue = true
		
		emit_signal("playerAttacked", self, attackDirection, attackDamage, attackType)
		attackCount += 1
		guiElements.update_current_turns()
		
	if attackCount + movementCount == maxTurnActions && !playerTurnDone:
		playerTurnDone = true
		emit_signal("playerMadeMove")
	
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
			emit_signal("playerMadeMove")
		else:
			guiElements.change_hand_on_room(GlobalVariables.ROOM_TYPE.ENEMYROOM)
			movementCount = 0
			attackCount = 0
			playerTurnDone = false
			disablePlayerInput = false
			
	
func player_interact_puzzle_block(puzzleBlockDirection):
	if puzzleBlockDirection:
		emit_signal("puzzleBlockInteractionSignal", self, puzzleBlockDirection)
	
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
		attackDamage = 1
		puzzleBlockInteraction = false
		return GlobalVariables.ATTACKTYPE.SWORD
		
	if Input.is_action_just_pressed("Mode_Magic"):
		guiElements.change_attack_mode(GlobalVariables.ATTACKTYPE.MAGIC)
		attackDamage = 0.5
		#if used in puzzle room while magic is flying cancels out all magic
		if attackType == GlobalVariables.ATTACKTYPE.MAGIC:
			if Grid.currentActivePhase == GlobalVariables.CURRENTPHASE.PUZZLEPROJECTILE:
				Grid.cancelMagicPuzzleRoom=true
		puzzleBlockInteraction = false
		return GlobalVariables.ATTACKTYPE.MAGIC
		
	if Input.is_action_just_pressed("Mode_Block"):
		guiElements.change_attack_mode(GlobalVariables.ATTACKTYPE.BLOCK)
		attackDamage = 0  
		puzzleBlockInteraction = false
		return GlobalVariables.ATTACKTYPE.BLOCK                     	
		
	if Input.is_action_just_pressed("Mode_Hand"):
		guiElements.change_attack_mode(GlobalVariables.ATTACKTYPE.HAND)
		attackDamage = 0
		puzzleBlockInteraction = false
		return GlobalVariables.ATTACKTYPE.HAND
		
func get_use_nonkey_items():
	if lifePoints < maxLifePoints:
		if Input.is_action_just_pressed("Potion"):
			if guiElements.use_potion():
				if lifePoints + 5 > maxLifePoints:
					lifePoints = maxLifePoints
					guiElements.set_health(maxLifePoints)
				else:
					lifePoints += 5 
					guiElements.change_health(-5)

func toggle_enemy_danger_areas():
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
			emit_signal("toggleDangerArea", enemyToToggleArea)
	elif Input.is_action_just_pressed("toggle_danger_area_next") && toggledDangerArea:
		if Grid.activeRoom !=null:
			if enemyToToggleArea == null:
				enemyToToggleArea = 0
			elif enemyToToggleArea >= Grid.activeRoom.enemiesInRoom.size()-1:
				enemyToToggleArea = null
			else:
				enemyToToggleArea += 1
			emit_signal("toggleDangerArea", enemyToToggleArea)
		
func inflict_damage_playerDefeated(attackDamage, attackType):
	GlobalVariables.turnController.playerTakeDamage.append(self)
	lifePoints -= attackDamage
	if lifePoints > 0:
		guiElements.change_health(attackDamage)
		var animationToPlay = str("take_damage_physical")
		if attackType == GlobalVariables.ATTACKTYPE.MAGIC:
			animationToPlay = str("take_damage_magic")
		set_process(false)
		print("Playing hit animation")
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
		GlobalVariables.turnController.player_defeat()

func add_nonkey_items(itemtype):
	match itemtype:
		GlobalVariables.ITEMTYPE.POTION:
			guiElements.fill_one_potion()

func add_key_item_to_inventory(item):
	var newInventoryItem = InventoryItem.instance()
	newInventoryItem.itemKeyValue = item.keyValue
	newInventoryItem.get_node("ItemTexture").set_texture(item.get_node("Sprite").get_texture())
	newInventoryItem.get_node("ItemTexture").set_modulate(item.modulation)
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

func _on_enemy_turn_done_signal():
	movementCount = 0
	attackCount = 0
	guiElements.update_current_turns(true)
	playerTurnDone = false
	disablePlayerInput = false

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
