#the main camera
#moves to the current room player is in 
#has a free controle mode, to navigate the map rest of the game is paused
extends Camera2D

onready var Grid = get_parent()

var standardZoomLevel = Vector2(0.214, 0.214)
var standardPosition = Vector2.ZERO
var controlMap = false
var beforeMapPosition = Vector2.ZERO
var beforeMapZoom = Vector2.ZERO

signal toggleMapSignal()

onready var window_size = OS.get_window_size()

#set camera to match starting room size
func _ready():
	position = Vector2.ZERO + Vector2(GlobalVariables.roomDimensions, GlobalVariables.roomDimensions)*GlobalVariables.tileSize/2
	set_as_toplevel(true)
	standardZoomLevel = standardZoomLevel * Vector2(GlobalVariables.roomDimensions, GlobalVariables.roomDimensions)
	self.zoom = standardZoomLevel

#check if map is toggled by player
func _process(delta):
	if Input.is_action_just_pressed("toggleMap"):
		open_close_map()
	if controlMap:
		move_zoom_map()
		
#move and zoom camera position
func move_zoom_map():
	var moveCameraDirection = move_camera()
	match moveCameraDirection:
		GlobalVariables.DIRECTION.LEFT:
			position += Vector2(-20,0)
		GlobalVariables.DIRECTION.RIGHT:
			position += Vector2(20,0)
		GlobalVariables.DIRECTION.UP:
			position += Vector2(0,-20)
		GlobalVariables.DIRECTION.DOWN:
			position += Vector2(0,20)
	
	var zoomCamera = zoom_camera()
	match zoomCamera:
		"IN":
			if(zoom > standardZoomLevel && zoom - Vector2(1.0,1.0) >= standardZoomLevel):
				zoom = zoom - Vector2(0.3,0.3)
			else:
				zoom = standardZoomLevel
		"OUT":
			zoom = zoom + Vector2(0.3,0.3)
	
#handles open and close map while not in camera transition tween 
func open_close_map():
	if !get_node("Tween").is_active():
		if get_tree().paused == false:
			get_tree().paused = true
			beforeMapPosition = position
			beforeMapZoom = zoom
			$Tween.interpolate_property(self, "zoom", zoom, Vector2(10,10) , 0.8, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
			emit_signal("toggleMapSignal")
			controlMap = true
		else:
			controlMap = false
			emit_signal("toggleMapSignal")
			$Tween.interpolate_property(self, "position", position, beforeMapPosition , 0.7, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$Tween.start()
			yield($Tween, "tween_completed")
			$Tween.interpolate_property(self, "zoom", zoom, beforeMapZoom , 0.8, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$Tween.start()
			yield($Tween, "tween_completed")
			get_tree().paused = false
			
#moves camera to fit new room dimension
func on_move_camera_signal(activeRoom):
	get_parent().disablePlayerInput = true
	if activeRoom == null:
		var goToPos = Vector2.ZERO + Vector2(GlobalVariables.roomDimensions, GlobalVariables.roomDimensions)*GlobalVariables.tileSize/2
		$Tween.interpolate_property(self, "position", position, goToPos , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.interpolate_property(self, "zoom", zoom, standardZoomLevel , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		yield($Tween, "tween_completed")
		get_parent().disablePlayerInput = false
	else:
		var goToPos = activeRoom.doorRoomLeftMostCorner + activeRoom.roomSize *GlobalVariables.tileSize/2 - GlobalVariables.tileOffset
		var goToZoom = standardZoomLevel
		match activeRoom.roomSizeMultiplier:
			Vector2(1,1):
				goToZoom = standardZoomLevel
			Vector2(1,2):
				goToZoom = standardZoomLevel * Vector2(2,2)
			Vector2(2,1):
				goToZoom = standardZoomLevel * Vector2(2,2)
			Vector2(2,2):
				goToZoom = standardZoomLevel * Vector2(2.2,2.2)
		$Tween.interpolate_property(self, "position", position, goToPos , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.interpolate_property(self, "zoom", zoom, goToZoom , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		yield($Tween, "tween_completed")
		get_parent().disablePlayerInput = false
			
func zoom_camera():
	if Input.is_action_pressed("Attack_Up"):	
		return("IN")
	elif Input.is_action_pressed("Attack_Down"):
		return("OUT")
			
func move_camera():
	if Input.is_action_pressed("player_down"):
		return GlobalVariables.DIRECTION.DOWN
	elif Input.is_action_pressed("player_up"):
		return GlobalVariables.DIRECTION.UP
	elif Input.is_action_pressed("player_right"):
		return GlobalVariables.DIRECTION.RIGHT
	elif Input.is_action_pressed("player_left"):
		return GlobalVariables.DIRECTION.LEFT
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
