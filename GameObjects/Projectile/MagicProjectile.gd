extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.MAGICPROJECTILE

var movementDirection 
var attackDamage = 1
var projectileType
var toBeDeleted = false
var isMiniProjectile = false
var tickAlreadyMoved = false

signal projectileMadeMove (type)

func _ready():
	pass

func move_projectile(type):

	if(type == "moveEnemyProjectiles" && projectileType == GlobalVariables.PROJECTILETYPE.ENEMY || type =="movePlayerProjectiles" && projectileType == GlobalVariables.PROJECTILETYPE.PLAYER|| type == "movePowerProjectile" && projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK):
		var target_position = Grid.request_move(self, movementDirection)
		if(target_position):
			$Tween.interpolate_property(self, "position", position, target_position , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
			emit_signal("projectileMadeMove",type)
	elif(type == "tickingProjectile" &&  projectileType == GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE):
		var target_position = position + movementDirection
		movementDirection = movementDirection*-1
		$Tween.interpolate_property(self, "position", position, target_position , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		yield($Tween, "tween_completed")
		emit_signal("projectileMadeMove",type)
	elif type == "allProjectiles":
		var target_position = Grid.request_move(self, movementDirection)
		if(target_position):
			$Tween.interpolate_property(self, "position", position, target_position , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
			position = target_position
			emit_signal("projectileMadeMove",type)
	else:
		emit_signal("projectileMadeMove",type)

func play_enemy_projectile_animation():
	#print("Animationplayer enemy shoot")
	$AnimationPlayer.play("enemy_shoot")
	
func create_mini_projectile(projectile):
	isMiniProjectile = true
	attackDamage = 0.5
	if projectile == 1:
		$AnimationPlayer.play("mini1shoot")
		var target_position = Grid.request_move(self, movementDirection)
		if(target_position):
			position = target_position
	if projectile == 2:
		$AnimationPlayer.play("mini2shoot")
		var target_position = Grid.request_move(self, movementDirection)
		if(target_position):
			position = target_position

func create_ticking_projectile(currentRoomLeftMostCorner):
	projectileType = GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE
	position = currentRoomLeftMostCorner
	movementDirection = Vector2(0,1)
	$Sprite.set_visible(false)
	
