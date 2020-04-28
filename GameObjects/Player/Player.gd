extends Node2D

onready var Grid = get_parent()

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

var attackCount = 0

var attackDamage = 1.5

var maxLifePoints = 10

var lifePoints = 10

var itemsInPosession = []

var usedItems = []

var inClearedRoom = true

var attackType = GlobalVariables.ATTACKTYPE.SWORD

var GUI = preload("res://GUI/GUIScene.tscn")

var guiElements = null

var movedThroughDoorDirection = Vector2.ZERO 

var disablePlayerInput = false 

var waitingForEventBeforeContinue = false

func _ready():
	guiElements = GUI.instance()
	guiElements.set_health(lifePoints)
	add_child(guiElements)
	
	Grid.connect("enemyTurnDoneSignal", self, "_on_enemy_turn_done_signal")

func _process(delta):	
	if !disablePlayerInput:
		if movedThroughDoorDirection!=Vector2.ZERO:
			player_passed_door()
			movedThroughDoorDirection=Vector2.ZERO
			return 
			
		get_use_nonkey_items()
		var  attackMode = get_attack_mode()
		if attackMode:
			attackType = attackMode
			

		if !playerTurnDone && ! waitingForEventBeforeContinue:
			var movementDirection = get_movement_direction()
			if inClearedRoom:
				movementDirection = get_free_movement_direction()
			var attackDirection = get_attack_direction()
			
			player_movement(movementDirection)
			player_attack(attackDirection)
			
			if movementCount == 1 && attackCount == 1:
				playerTurnDone=true
				emit_signal("playerMadeMove")
			elif movementCount >= 2 && attackCount >= 0: 
				playerTurnDone=true
				emit_signal("playerMadeMove")
			elif attackCount >= 2 && movementCount >= 0:
				playerTurnDone=true
				emit_signal("playerMadeMove")
				
func player_movement(movementDirection):
	if movementDirection:
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
			set_process(true)
			movementCount += 1
	
func player_attack(attackDirection):
	if attackDirection:
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
		$AnimationPlayer.play(animationPlay, -1, 2.5)
		$Tween.interpolate_property($Sprite, "position",attackDirection * GlobalVariables.tileSize, Vector2(), $AnimationPlayer.current_animation_length/2.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		yield($AnimationPlayer, "animation_finished")
		$AnimationPlayer.play("Idle")
		set_process(true)
		if attackType == GlobalVariables.ATTACKTYPE.BLOCK:
			waitingForEventBeforeContinue = true
		
		emit_signal("playerAttacked", self, attackDirection, attackDamage, attackType)
		attackCount += 1
	
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
		$AnimationPlayer.play(animationPlay, -1, 6.0)
		$Tween.interpolate_property(self, "position", position, targetPosition , $AnimationPlayer.current_animation_length/6.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
		playerPreviousPosition = position
		#position = target_position
		$Tween.start()
		yield($AnimationPlayer, "animation_finished")
		$AnimationPlayer.play("Idle")
		set_process(true)
		movementCount = 0
		attackCount = 0
		playerTurnDone = false
		disablePlayerInput = false
	
func get_free_movement_direction():
	if Input.is_action_pressed("player_up"):
		return Vector2(0,-1)
	if Input.is_action_pressed("player_down"):
		return Vector2(0,1)
	if Input.is_action_pressed("player_left"):
		return Vector2(-1,0)
	if Input.is_action_pressed("player_right"):
		return Vector2(1,0)
	
func get_movement_direction():
	if Input.is_action_just_pressed("player_up"):
		return Vector2(0,-1)
	if Input.is_action_just_pressed("player_down"):
		return Vector2(0,1)
	if Input.is_action_just_pressed("player_left"):
		return Vector2(-1,0)
	if Input.is_action_just_pressed("player_right"):
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
		attackDamage = 1.5
		return GlobalVariables.ATTACKTYPE.SWORD
		
	if Input.is_action_just_pressed("Mode_Magic"):
		guiElements.change_attack_mode(GlobalVariables.ATTACKTYPE.MAGIC)
		attackDamage = 1
		return GlobalVariables.ATTACKTYPE.MAGIC
		
	if Input.is_action_just_pressed("Mode_Block"):
		guiElements.change_attack_mode(GlobalVariables.ATTACKTYPE.BLOCK)
		attackDamage = 0  
		return GlobalVariables.ATTACKTYPE.BLOCK                     	
		
	if Input.is_action_just_pressed("Mode_Hand"):
		guiElements.change_attack_mode(GlobalVariables.ATTACKTYPE.HAND)
		attackDamage = 0
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
			
func inflict_damage_playerDefeated(attackDamage, attackType):
	lifePoints -= attackDamage
	guiElements.change_health(attackDamage)
	if lifePoints == 0:
		guiElements.set_health(10)
		emit_signal("onPlayerDefeated", self, lifePoints)
		return true
	return false

func add_nonkey_items(itemtype):
	match itemtype:
		"POTION":
			guiElements.fill_one_potion()


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			if event.pressed:
				MainCamera.zoomInOut("IN")
		if event.button_index == BUTTON_WHEEL_DOWN:
			MainCamera.zoomInOut("OUT")

func _on_enemy_turn_done_signal():
	movementCount = 0
	attackCount = 0
	playerTurnDone = false
