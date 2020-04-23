extends Camera2D

var standardZoomLevel = Vector2(1.9,1.9)
#var standardZoomLevel = Vector2(7,7)

signal cameraSmoothTransition (camera, target_position)

onready var window_size = OS.get_window_size()


func _ready():
	var canvas_transform = get_viewport().get_canvas_transform()
	#print(canvas_transform)
	self.zoom = standardZoomLevel
	self.position = (Vector2(4.5,4.5)*32)
	#set_process(true)
	self.make_current()
	#update_camera()

func move_and_zoom_camera_to_room(roomLeftMostCorner, roomDimensions, roomSizeMultiplier):
	#implement camera zoom
	#use tween to move camera
	#emit_signal("cameraSmoothTransition")
	position = (roomLeftMostCorner + roomDimensions)
	if(roomSizeMultiplier == Vector2(1,2) || roomSizeMultiplier == Vector2(2,1)):
		zoom = standardZoomLevel*Vector2(2,2)
	else:
		zoom = standardZoomLevel * roomSizeMultiplier
	self.make_current()
	
func zoomInOut(inOut):
	match inOut:
		"IN":
			if(zoom > standardZoomLevel && zoom - Vector2(1.0,1.0) >= standardZoomLevel):
				zoom = zoom - Vector2(1.0,1.0)
			else:
				zoom = standardZoomLevel
		"OUT":
			zoom = zoom + Vector2(0.5,0.5)
	self.make_current()
	
func set_camera_starting_room():
	self.zoom = standardZoomLevel
	self.position = (Vector2(4.5,4.5)*32)
	self.make_current()
