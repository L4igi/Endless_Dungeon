extends "res://GameObjects/gameObject.gd"

onready var Grid = get_parent()

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

func _ready():
	pass

func _process(delta):
	if(playerPassedDoor == Vector2.ZERO):
		Grid.enablePlayerAttack(self)
		var movement_direction = get_movement_direction()
		var attack_direction = get_attack_direction()
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
					
					emit_signal("playerAttacked", self, attack_direction, attackDamage)
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
						$Tween.interpolate_property($Sprite, "position", -movement_direction * 32, Vector2.ZERO, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
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
					$Tween.interpolate_property($Sprite, "position", -movement_direction * 32, Vector2.ZERO, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN)
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

func playerDefeated(attackDamage):
	lifePoints -= attackDamage
	if lifePoints == 0:
		return true
	return false


