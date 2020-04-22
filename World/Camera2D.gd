extends Camera2D

#var standardZoomLevel = Vector2(1.9,1.9)
var standardZoomLevel = Vector2(7,7)

signal cameraSmoothTransition (camera, target_position)

enum ROOM_LAYOUT{LEFTNORMAL, RIGHTNORMAL, UPNORMAL, DOWNNORMAL, UPLONG, UPLONGLEFT, UPLONGRIGHT, UPBIGLEFT, UPBIGRIGHT, DOWNLONG, DOWNLONGLEFT, DOWNLONGRIGHT, DOWNBIGLEFT, DOWNBIGRIGHT, LEFTLONG, LEFTLONGUP, LEFTLONGDOWN, LEFTBIGUP, LEGTBIGDOWN, RIGHTLONG, RIGHTLONGUP, RIGHTLONGDOWN, RIGHTBIGUP, RIGHTBIGDOWN}

onready var window_size = OS.get_window_size()


func _ready():
	var canvas_transform = get_viewport().get_canvas_transform()
	#print(canvas_transform)
	self.zoom = standardZoomLevel
	self.position = (Vector2(4,4)*32)+Vector2(16,16)
	set_process(true)
	self.make_current()
	#update_camera()

func move_and_zoom_camera_to_room(roomLeftMostCorner, roomDimensions, roomSizeMultiplier):
	#implement camera zoom
	#use tween to move camera
	emit_signal("cameraSmoothTransition")
	position = roomLeftMostCorner + roomDimensions
		
