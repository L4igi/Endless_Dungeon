extends Camera2D

onready var Grid = get_parent()

var standardZoomLevel = Vector2(0.2, 0.2)
var standardPosition = Vector2.ZERO
var controlMap = false
#var standardZoomLevel = Vector2(7,7)

signal cameraSmoothTransition (camera, target_position)

signal toggleMapSignal()

onready var window_size = OS.get_window_size()

func _ready():
	pass
#	var roomSize = float(GlobalVariables.roomDimensions)/2
#	print(roomSize)
#	standardPosition = (Vector2(roomSize,roomSize)*32)
#	self.position = standardPosition
	standardZoomLevel = standardZoomLevel * Vector2(GlobalVariables.roomDimensions, GlobalVariables.roomDimensions)
	self.zoom = standardZoomLevel

func _process(delta):
	var toggleMap = toggle_map()
	if toggleMap:
		emit_signal("toggleMapSignal")
		if get_tree().paused == false:
			get_tree().paused = true
			controlMap = true
		else:
			controlMap = false
			$Tween.interpolate_property(self, "position", position, get_parent().position , 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, "tween_completed")
			get_tree().paused = false
			
			
	if controlMap:
		var moveCameraDirection = move_camera_keyboard()
		match moveCameraDirection:
			GlobalVariables.DIRECTION.LEFT:
				position += Vector2(-20,0)
			GlobalVariables.DIRECTION.RIGHT:
				position += Vector2(20,0)
			GlobalVariables.DIRECTION.UP:
				position += Vector2(0,-20)
			GlobalVariables.DIRECTION.DOWN:
				position += Vector2(0,20)
	
func on_move_camera_signal(activeRoom):
	if activeRoom == null:
		self.zoom = standardZoomLevel
		self.position = standardPosition
#	self.make_current()
	#implement camera zoom
	#use tween to move camera
	#emit_signal("cameraSmoothTransition")
	else:
		print("In camera room type " + str(activeRoom.roomType))
		position = (activeRoom.doorRoomLeftMostCorner + activeRoom.roomSize)
		if(activeRoom.roomSizeMultiplier == Vector2(1,2) || activeRoom.roomSizeMultiplier == Vector2(2,1)):
			zoom = standardZoomLevel*Vector2(2,2)
		else:
			zoom = standardZoomLevel * activeRoom.roomSizeMultiplier
#		self.make_current()
	
func zoomInOut(inOut):
	match inOut:
		"IN":
			if(zoom > standardZoomLevel && zoom - Vector2(1.0,1.0) >= standardZoomLevel):
				zoom = zoom - Vector2(1.0,1.0)
			else:
				zoom = standardZoomLevel
		"OUT":
			zoom = zoom + Vector2(0.5,0.5)
	#self.make_current()
	
func set_camera_starting_room():
	#print("standard zoom level " + str(standardZoomLevel) + " standardposition " + str(standardPosition))
	self.zoom = standardZoomLevel
	self.position = standardPosition
	#self.make_current()

func toggle_map():
	if Input.is_action_just_pressed("toggleMap"):
		return true
	return false
	
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			if event.pressed:
				zoomInOut("IN")
		if event.button_index == BUTTON_WHEEL_DOWN:
			zoomInOut("OUT")
			
func move_camera_keyboard():
	if Input.is_action_pressed("player_down"):
		return GlobalVariables.DIRECTION.DOWN
	elif Input.is_action_pressed("player_up"):
		return GlobalVariables.DIRECTION.UP
	elif Input.is_action_pressed("player_right"):
		return GlobalVariables.DIRECTION.RIGHT
	elif Input.is_action_pressed("player_left"):
		return GlobalVariables.DIRECTION.LEFT
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
