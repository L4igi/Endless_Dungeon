extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.MAGICPROJECTILE

var movementDirection 
var attackDamage = 1
var projectileType
var toBeDeleted = false
var isMiniProjectile = false

signal projectileMadeMove (projectile)

func _ready():
	pass

func move_projectile():
	var target_position = Grid.request_move(self, movementDirection)
	if(target_position):
		$Tween.interpolate_property(self, "position", position, target_position , 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		yield($Tween, "tween_completed")
		emit_signal("projectileMadeMove", self)

func play_enemy_projectile_animation():
	#print("Animationplayer enemy shoot")
	$AnimationPlayer.play("enemy_shoot")
	
func create_mini_projectile(projectile):
	isMiniProjectile = true
	attackDamage = 0.5
	if projectile == 1:
		$AnimationPlayer.play("mini1shoot")
	if projectile == 2:
		$AnimationPlayer.play("mini2shoot")
