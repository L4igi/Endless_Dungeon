extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR = 6}
export(CELL_TYPES) var type = CELL_TYPES.ENEMY

var alreadyMovedThisTurn = false

var alreadyAttackedThisTurn = false

var isDisabled = true

signal enemyMadeMove

signal enemyAttacked (enemy, attackDirection, attackDamange )

var lifePoints = 2

var barrierEnemy = false

var attackDamage = 0.1 

signal enemmyAttacked 

func _ready():
	pass
	

func _process(delta): 
	randomize()
	if(isDisabled == false): 
		if(!alreadyMovedThisTurn || !alreadyAttackedThisTurn):
			var attackCell = Grid.enableEnemyAttack(self)
			if(attackCell != Vector2.ZERO):
				emit_signal("enemyAttacked", self, attackCell, attackDamage)
				alreadyAttackedThisTurn = true
			if(alreadyMovedThisTurn == false):
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
					position=target_position
					alreadyMovedThisTurn = true
					
					if(alreadyAttackedThisTurn == false):
						attackCell = Grid.enableEnemyAttack(self)
						if(attackCell != Vector2.ZERO):
							#attack player
							emit_signal("enemyAttacked", self, attackCell, attackDamage)
						alreadyAttackedThisTurn = true
			if(alreadyMovedThisTurn && alreadyAttackedThisTurn):
				emit_signal("enemyMadeMove")
			
#func _process(delta): 
#	randomize()
#	if(!isDisabled):
#		var attackDirection = Grid.enableEnemyAttack(self)
#		if(attackDirection != Vector2.ZERO):
#			pass
#			#alreadyAttackedThisTurn = true
#		if(alreadyMovedThisTurn == false):
#			var upDownLeftRight = randi()%4+1
#			var movement_direction = Vector2.ZERO
#			match upDownLeftRight:
#				1:
#					movement_direction = Vector2(1,0)
#				2:
#					movement_direction = Vector2(-1,0)
#				3: 
#					movement_direction = Vector2(0,1)
#				4:
#					movement_direction = Vector2(0,-1)
#
#			var target_position = Grid.request_move(self, movement_direction)
#			if(target_position):
#				position=target_position
#				alreadyMovedThisTurn = true
#
#		if(alreadyMovedThisTurn == true):
#			emit_signal("enemyMadeMove")

func generateEnemy(): 
	pass 

func enemyDefeated(attackDamage):
	lifePoints -= attackDamage
	if lifePoints == 0:
		return true
	return false
	#set enemy difficulty and type set enemy stats based on difficulty set amount of enemies to spawn based on room size and difficulty 

