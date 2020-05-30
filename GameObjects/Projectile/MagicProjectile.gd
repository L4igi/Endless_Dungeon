extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.MAGICPROJECTILE

var movementDirection 
var attackDamage = 1
var projectileType
var isMiniProjectile = false
var tickAlreadyMoved = false
var deleteProjectile = false

var waitingForEventBeforeContinue = false

signal projectileMadeMove (type)

signal playerEnemieProjectileMadeMove (projectile ,type, projectileArray)

func _ready():
	pass

func move_projectile(type=null):
	
	if(type == "moveEnemyProjectiles" && projectileType == GlobalVariables.PROJECTILETYPE.ENEMY || type =="movePlayerProjectiles" && projectileType == GlobalVariables.PROJECTILETYPE.PLAYER):
		var target_position = Grid.request_move(self, movementDirection)
		if(target_position):
			$Tween.interpolate_property(self, "position", position, target_position , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
		if !waitingForEventBeforeContinue:
			emit_signal("playerEnemieProjectileMadeMove",self, type)

	elif (type == "movePowerProjectile" && projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK):
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
			
	elif type == "clearedRoomProjectile":
		var target_position = Grid.request_move(self, movementDirection)
		if(target_position):
			$Tween.interpolate_property(self, "position", position, target_position , 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
			position = target_position
			move_projectile("clearedRoomProjectile")
		else:
			emit_signal("projectileMadeMove",type)
	else:
		emit_signal("projectileMadeMove",type)

func play_player_projectile_animation():
	$AnimationPlayer.play("shoot")
	
func play_enemy_projectile_animation():
	#print("Animationplayer enemy shoot")
	$AnimationPlayer.play("enemy_shoot")

func play_powerBlock_projectile_animation():
	$AnimationPlayer.play("powerblock_shoot")

func play_playerProjectile_attack_animation(onSpot=true):
	set_process(false)
	$AnimationPlayer.play("playerProjectileAttack")
	if !onSpot:
		$Tween.interpolate_property($Sprite, "position", Vector2(), movementDirection*GlobalVariables.tileSize, $AnimationPlayer.current_animation_length, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
	yield($AnimationPlayer, "animation_finished")
	set_process(true)
	if !waitingForEventBeforeContinue:
		self.queue_free()
	
func play_enemyProjectile_attack_animation(onSpot=true):
	print("Playing projectile animation")
	set_process(false)
	$AnimationPlayer.play("enemyProjectileAttack")
	if !onSpot:
		$Tween.interpolate_property($Sprite, "position", Vector2(), movementDirection*GlobalVariables.tileSize, $AnimationPlayer.current_animation_length, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
	yield($AnimationPlayer, "animation_finished")
	set_process(true)
	self.queue_free()
	
func create_mini_projectile(projectile, mainPlayer, currentPhase):
	if currentPhase == GlobalVariables.CURRENTPHASE.PLAYER:
		mainPlayer.disablePlayerInput = true
	isMiniProjectile = true
	attackDamage = 0.5
	if projectile == 1:
		$AnimationPlayer.play("mini1shoot")

	if projectile == 2:
		$AnimationPlayer.play("mini2shoot")
	if currentPhase == GlobalVariables.CURRENTPHASE.PLAYER:
		var target_position = Grid.request_move(self, movementDirection)
		if(target_position):
			$Tween.interpolate_property(self, "position", position, target_position , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
		mainPlayer.disablePlayerInput = false
			
func makeNormalProjectile():
	isMiniProjectile = true
	attackDamage = 1.0
	$AnimationPlayer.play("shoot")

func create_ticking_projectile(currentRoomLeftMostCorner):
	projectileType = GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE
	position = currentRoomLeftMostCorner
	movementDirection = Vector2(0,1)
	$Sprite.set_visible(false)
	
