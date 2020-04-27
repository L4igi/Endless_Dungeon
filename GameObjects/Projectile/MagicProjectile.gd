extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.MAGICPROJECTILE

var movementDirection 
var playerProjectile 
var attackDamage = 1
var projectileType
var isMiniProjectile = false

func _ready():
	pass # Replace with function body.

func move_projectile():
	var target_position = Grid.request_move(self, movementDirection)
	if(target_position):
		position=target_position

func play_enemy_projectile_animation():
	print("Animationplayer enemy shoot")
	$AnimationPlayer.play("enemy_shoot")
	
func create_mini_projectile(projectile):
	isMiniProjectile = true
	attackDamage = 0.5
	if projectile == 1:
		$AnimationPlayer.play("mini1shoot")
	if projectile == 2:
		$AnimationPlayer.play("mini2shoot")
