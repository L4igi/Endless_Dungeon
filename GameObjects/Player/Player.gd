extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR = 6, MAGICPROJECTILE=7}
export(CELL_TYPES) var type = CELL_TYPES.PLAYER

enum attackTyped{SWORD = 1, MAGIC = 2} 

var madeMove = false 

var playerCanAttack = false 
var playerPreviousPosition = Vector2.ZERO

signal playerMadeMove 

signal playerAttacked (player, attackDirection, attackDamage)

var playerPassedDoor = Vector2.ZERO

var alreadyAttackedThisMove = false

var alreadyMovedThisTurn = false

var attackDamage = 1

var lifePoints = 5

var itemsInPosession = []

var usedItems = []

var inClearedRoom = true

var attackType = attackTyped.SWORD

			

func _ready():
	pass

func _process(delta):
	var  attackMode = get_attack_mode()
	if attackMode:
		attackType = attackMode
	if(playerPassedDoor == Vector2.ZERO):
		if(inClearedRoom):
			var movement_direction = get_free_movement_direction()
			var target_position = Grid.request_move(self, movement_direction)
			if (target_position):
				set_process(false)
				#play attack animation 
				var animationPlay = str("walk_right")
				match movement_direction:
					Vector2(1,0):
						animationPlay = str("walk_right")
					Vector2(-1,0):
						animationPlay = str("walk_left")
					Vector2(0,1):
						animationPlay = str("walk_down")
					Vector2(0,-1):
						animationPlay = str("walk_up")
				$AnimationPlayer.play(animationPlay, -1, 10.0)
				$Tween.interpolate_property($Sprite, "position", Vector2.ZERO, Vector2.ZERO, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
				alreadyMovedThisTurn=true
				playerPreviousPosition = position
				position = target_position
				$Tween.start()
				yield($AnimationPlayer, "animation_finished")
				$AnimationPlayer.play("Idle")
				set_process(true)
		else:
			Grid.enablePlayerAttack(self)
			var movement_direction = get_movement_direction()
			var attack_direction = get_attack_direction()
			if(alreadyMovedThisTurn && movement_direction):
				var target_position = Grid.request_move(self, movement_direction)
				if(target_position):
					playerPreviousPosition = position
					position = target_position
					alreadyAttackedThisMove = true
					emit_signal("playerMadeMove")
			if playerCanAttack:
				if(movement_direction || attack_direction):
					if attack_direction && !alreadyAttackedThisMove:
						#do attack stuff
						set_process(false)
						#play attack animation 
						var animationPlay = str("attack_right")
						match attack_direction:
							Vector2(1,0):
								animationPlay = str("attack_right")
							Vector2(-1,0):
								animationPlay = str("attack_left")
							Vector2(0,1):
								animationPlay = str("attack_down")
							Vector2(0,-1):
								animationPlay = str("attack_up")
						$AnimationPlayer.play(animationPlay, -1, 2.5)
						$Tween.interpolate_property($Sprite, "position", attack_direction * 32, Vector2.ZERO, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN)
						$Tween.start()
						yield($AnimationPlayer, "animation_finished")
						$AnimationPlayer.play("Idle")
						set_process(true)
						
						emit_signal("playerAttacked", self, attack_direction, attackDamage, attackType)
						alreadyAttackedThisMove=true
					if movement_direction && !alreadyMovedThisTurn:
						var targetPosition = Grid.request_move(self, movement_direction)
						if targetPosition:
							set_process(false)
							#play attack animation 
							var animationPlay = str("walk_right")
							match movement_direction:
								Vector2(1,0):
									animationPlay = str("walk_right")
								Vector2(-1,0):
									animationPlay = str("walk_left")
								Vector2(0,1):
									animationPlay = str("walk_down")
								Vector2(0,-1):
									animationPlay = str("walk_up")
							$AnimationPlayer.play(animationPlay, -1, 10.0)
							$Tween.interpolate_property($Sprite, "position", Vector2.ZERO, Vector2.ZERO, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
							alreadyMovedThisTurn=true
							playerPreviousPosition = position
							position = targetPosition
							$Tween.start()
							yield($AnimationPlayer, "animation_finished")
							$AnimationPlayer.play("Idle")
							set_process(true)
	
			
			else:
				if movement_direction:
					var targetPosition = Grid.request_move(self, movement_direction)
					if targetPosition:
						set_process(false)
						#play attack animation 
						var animationPlay = str("walk_right")
						match movement_direction:
							Vector2(1,0):
								animationPlay = str("walk_right")
							Vector2(-1,0):
								animationPlay = str("walk_left")
							Vector2(0,1):
								animationPlay = str("walk_down")
							Vector2(0,-1):
								animationPlay = str("walk_up")
						$AnimationPlayer.play(animationPlay, -1, 8.0)
						$Tween.interpolate_property($Sprite, "position", Vector2.ZERO, Vector2.ZERO, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN)
						alreadyMovedThisTurn=true
						playerPreviousPosition = position
						position = targetPosition
						$Tween.start()
						yield($AnimationPlayer, "animation_finished")
						$AnimationPlayer.play("Idle")
						set_process(true)
						
						Grid.enablePlayerAttack(self)
						if !playerCanAttack:
							alreadyAttackedThisMove=true
			
			if(alreadyAttackedThisMove && alreadyMovedThisTurn):
				emit_signal("playerMadeMove")
	else:
		var target_position = Grid.request_move(self,playerPassedDoor)
		if (target_position):
			playerPreviousPosition = position
			position = target_position
		playerPassedDoor = Vector2.ZERO
		
func get_free_movement_direction():
	var UP = Input.is_action_pressed("player_up")
	var DOWN = Input.is_action_pressed("player_down")
	var LEFT = Input.is_action_pressed("player_left")
	var RIGHT = Input.is_action_pressed("player_right")
	
	var movedir = Vector2.ZERO
	movedir.x = -int(LEFT) + int(RIGHT) # if pressing both directions this will return 0
	movedir.y = -int(UP) + int(DOWN)
	
	return movedir
	
func get_movement_direction():
	var UP = Input.is_action_just_pressed("player_up")
	var DOWN = Input.is_action_just_pressed("player_down")
	var LEFT = Input.is_action_just_pressed("player_left")
	var RIGHT = Input.is_action_just_pressed("player_right")
	
	var movedir = Vector2.ZERO
	movedir.x = -int(LEFT) + int(RIGHT) # if pressing both directions this will return 0
	movedir.y = -int(UP) + int(DOWN)
	
	return movedir

func get_attack_direction():
	var UP = Input.is_action_just_pressed("Attack_Up")
	var DOWN = Input.is_action_just_pressed("Attack_Down")
	var LEFT = Input.is_action_just_pressed("Attack_Left")
	var RIGHT = Input.is_action_just_pressed("Attack_Right")
	
	var attackdir = Vector2.ZERO
	attackdir.x = -int(LEFT) + int(RIGHT) # if pressing both directions this will return 0
	attackdir.y = -int(UP) + int(DOWN)
	
	return attackdir

func get_attack_mode():
	if Input.is_action_just_pressed("Mode_Sword"):
		return attackTyped.SWORD
	if Input.is_action_just_pressed("Mode_Magic"):
		return attackTyped.MAGIC
			
func inflict_damage_playerDefeated(attackDamage):
	lifePoints -= attackDamage
	if lifePoints == 0:
		return true
	return false


