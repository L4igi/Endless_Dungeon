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
					emit_signal("playerAttacked", self, attack_direction, attackDamage)
					alreadyAttackedThisMove=true
				if movement_direction && !alreadyMovedThisTurn:
					var targetPosition = Grid.request_move(self, movement_direction)
					if targetPosition:
						playerPreviousPosition = position
						position = targetPosition
						alreadyMovedThisTurn=true

		
		else:
			if movement_direction:
				var targetPosition = Grid.request_move(self, movement_direction)
				if targetPosition:
					alreadyMovedThisTurn=true
					playerPreviousPosition = position
					position = targetPosition
					
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
		
#func _process(delta):
#	if(madeMove == false):
#		var movement_direction = get_movement_direction()
#		var attack_direction = get_attack_direction()
#
#		if(attack_direction):
#			print("Attackdirection: " + str(attack_direction))
#
#		if(playerPassedDoor == Vector2.ZERO):
#			var target_position = Grid.request_move(self, movement_direction)
#		#	if (target_position && madeMove == false):
#			if target_position:
#				playerPreviousPosition = position
#				position = target_position
#
#				emit_signal("playerMadeMove")
#				#print("Current FrameRate: " + str(Engine.get_frames_per_second())) 
#				#Grid._spawn_enemy_after_move(self)
#				#Grid.create_doors(self.position, Vector2(16,16), true)
#		else:
#			var target_position = Grid.request_move(self,playerPassedDoor)
#			if (target_position):
#				playerPreviousPosition = position
#				position = target_position
#			playerPassedDoor = Vector2.ZERO
#



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
