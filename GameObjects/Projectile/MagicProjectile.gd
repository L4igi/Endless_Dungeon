#handles all types of projectiles
#could be more modular by making each projectile type a seperate scene 
extends Node2D

onready var Grid = get_parent()

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.MAGICPROJECTILE

var movementDirection 
var attackDamage = 0.5
var projectileType = null
var isMiniProjectile = false
var tickAlreadyMoved = false
var deleteProjectilePlayAnimation = null
var moveTo = null
var requestedMoveCount = 0
var hitObstacleOnDelete = false

signal projectileMadeMove (projectile)

signal playerEnemieProjectileMadeMove (projectile)

signal tickingProjectileMadeMove(projectile, type)

func _ready():
	pass
	
#pre calcualtes projectiles move to position including proper interactions
func calc_projectiles_move_to(calcMode, count, playerEnemy = "player"):
	var calcArray = null
	match playerEnemy:
		"player":
			calcArray = GlobalVariables.turnController.playerProjectilesToMove
		"enemy":
			calcArray = GlobalVariables.turnController.enemyProjectilesToMove
	if projectileType == GlobalVariables.PROJECTILETYPE.ENEMY || projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
		var cell_target = Grid.world_to_map(position) + movementDirection
		if calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW:
			var target_position = Grid.map_to_world(cell_target) + Grid.cell_size / GlobalVariables.isometricFactor
			if target_position:
				moveTo = target_position
			count+=1
			if count >= calcArray.size():
				return
			else:
				calcArray[count].calc_projectiles_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.PREVIEW, count)
		elif calcMode == GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION:
			if movementDirection != Vector2(0,0):
				var target_position = Grid.request_move(self, movementDirection)
				if target_position && deleteProjectilePlayAnimation==null:
					moveTo = target_position
				else:
					moveTo = null
			else:
				moveTo = null
			count+=1
			if count >= calcArray.size():
				return
			else:
				calcArray[count].calc_projectiles_move_to(GlobalVariables.MOVEMENTATTACKCALCMODE.ACTION, count, playerEnemy)
		
#moves projectiles according to their type
func move_projectile(type = null):
	if projectileType == GlobalVariables.PROJECTILETYPE.ENEMY || projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
		if moveTo:
			$Tween.interpolate_property(self, "position", position, moveTo , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
			if deleteProjectilePlayAnimation == null:
				emit_signal("playerEnemieProjectileMadeMove",self)
			else:
				play_projectile_animation(false, deleteProjectilePlayAnimation)
		else:
			play_projectile_animation(false, "delete")

	elif projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
		var target_position = Grid.request_move(self, movementDirection)
		if target_position:
			$Tween.interpolate_property(self, "position", position, target_position , 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
			if deleteProjectilePlayAnimation == null:
				emit_signal("projectileMadeMove",self)
			else:
				play_projectile_animation(false, deleteProjectilePlayAnimation)
		else:
			play_projectile_animation(false, "delete")
		
	elif projectileType == GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE:
		var target_position = position + movementDirection
		movementDirection = movementDirection*-1
		tickAlreadyMoved = true
		$Tween.interpolate_property(self, "position", position, target_position , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		yield($Tween, "tween_completed")
		tickAlreadyMoved = false
		emit_signal("tickingProjectileMadeMove", self, projectileType)
		
	elif type == "allProjectiles":
		var target_position = Grid.request_move(self, movementDirection)
		if(target_position):
			$Tween.interpolate_property(self, "position", position, target_position , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
			position = target_position
			emit_signal("projectileMadeMove", self)
			
	elif type == "clearedRoomProjectile":
		var target_position = Grid.request_move(self, movementDirection)
		if(target_position):
			$Tween.interpolate_property(self, "position", position, target_position , 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
			position = target_position
			move_projectile("clearedRoomProjectile")
		else:
			play_projectile_animation(false, deleteProjectilePlayAnimation)
			emit_signal("projectileMadeMove", self)
	else:
		emit_signal("projectileMadeMove", self)

func play_player_projectile_animation():
	$AnimationPlayer.play("shoot")
	
func play_enemy_projectile_animation():
	#print("Animationplayer enemy shoot")
	$AnimationPlayer.play("enemy_shoot")

func play_powerBlock_projectile_animation():
	$AnimationPlayer.play("powerblock_shoot")

func play_projectile_animation(onSpot=true, projectileAnimation="attack",projectileInteraction = false, setTileEnemy= false):
	if !GlobalVariables.turnController.projectileInteraction.has(self):
		GlobalVariables.turnController.projectileInteraction.append(self)
	var animationMode = 1
	if GlobalVariables.turnController.currentTurnWaiting != GlobalVariables.CURRENTPHASE.PLAYERPROJECTILE && GlobalVariables.turnController.currentTurnWaiting != GlobalVariables.CURRENTPHASE.ENEMYPROJECTILE && GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYER || GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMY || GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYATTACK:
		animationMode = 1
	elif Grid.activeRoom != null && Grid.activeRoom.roomType == GlobalVariables.ROOM_TYPE.PUZZLEROOM:
		animationMode = 2
	else:
		animationMode = 3
	
	var animationToPlay = projectileAnimation
	match projectileAnimation : 
		"delete":
			deleteProjectilePlayAnimation = "delete"
			if projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
				animationToPlay = "EnemyProjectileDelete"
			elif projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
				animationToPlay = "PlayerProjectileDelete"
			elif projectileType == GlobalVariables.PROJECTILETYPE.POWERBLOCK:
				animationToPlay = "PowerBlockProjectileDelete"
		"attack":
			if projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
				animationToPlay = "enemyProjectileAttack"
			elif projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
				animationToPlay = "playerProjectileAttack"
		"merge":
			if projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
				animationToPlay = "enemy_shoot"
			elif projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
				isMiniProjectile = false
				attackDamage = 1.0
				animationToPlay = "playerPoweredUpProjectile"
		"mini":
			if projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
				animationToPlay = "enemy_shoot"
			elif projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
				animationToPlay = "to_mini_projectile"
				isMiniProjectile = true
				attackDamage = 0.5
	if projectileAnimation != "mini":
		set_process(false)
		$AnimationPlayer.play(animationToPlay)
		if !onSpot:
			$Tween.interpolate_property($Sprite, "position", Vector2(), movementDirection*GlobalVariables.tileSize, $AnimationPlayer.current_animation_length, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
		yield($AnimationPlayer, "animation_finished")
		set_process(true)
	if projectileAnimation == "merge": 
		if projectileType == GlobalVariables.PROJECTILETYPE.ENEMY:
			$AnimationPlayer.play("enemy_shoot")
		elif projectileType == GlobalVariables.PROJECTILETYPE.PLAYER:
			$AnimationPlayer.play("shoot")
		GlobalVariables.turnController.on_projectile_interaction(self, false)
	elif projectileAnimation == "mini":
		var target_position = Grid.request_move(self, movementDirection)
		Grid.set_cellv(Grid.world_to_map(position), Grid.get_tileset().find_tile_by_name("FLOOR"))
		if target_position:
			set_process(false)
			$AnimationPlayer.play(animationToPlay)
			$Tween.interpolate_property(self, "position", position, target_position , $AnimationPlayer.current_animation_length, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
			if deleteProjectilePlayAnimation != "delete":
				$AnimationPlayer.play("mini1shoot")
			set_process(true)
		if deleteProjectilePlayAnimation == "delete":
			GlobalVariables.turnController.on_projectile_interaction(self, true)
		else:
			GlobalVariables.turnController.on_projectile_interaction(self, false)
	elif animationMode == 1:
		Grid.projectilesInActiveRoom.erase(self)
		if projectileType == GlobalVariables.PROJECTILETYPE.ENEMY && GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.PLAYER:
			if !setTileEnemy:
				Grid.set_cellv(Grid.world_to_map(position),Grid.get_tileset().find_tile_by_name("FLOOR"))
			pass
		elif projectileType == GlobalVariables.PROJECTILETYPE.ENEMY && GlobalVariables.turnController.currentTurnWaiting == GlobalVariables.CURRENTPHASE.ENEMYATTACK:
			pass
		GlobalVariables.turnController.on_projectile_interaction(self, true)
	elif animationMode == 2:
		Grid.projectilesInActiveRoom.erase(self)
		emit_signal("projectileMadeMove", self)
	elif animationMode == 3:
		Grid.projectilesInActiveRoom.erase(self)
		if !hitObstacleOnDelete:
			Grid.set_cellv(Grid.world_to_map(position),Grid.get_tileset().find_tile_by_name("FLOOR"))
		GlobalVariables.turnController.on_projectile_interaction(self, true)
		emit_signal("playerEnemieProjectileMadeMove",self)
		
	
#ticking projectiles are used in puzzle rooms to handle interaction timing between projectiles
func create_ticking_projectile(currentRoomLeftMostCorner):
	projectileType = GlobalVariables.PROJECTILETYPE.TICKERPROJECTILE
	position = currentRoomLeftMostCorner
	movementDirection = Vector2(0,1)
	$Sprite.set_visible(false)
	
