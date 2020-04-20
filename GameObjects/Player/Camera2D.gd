extends Camera2D

# This script assumes that the zoom.x and zoom.y are always the same.

var current_zoom
var min_zoom
var max_zoom
var zoom_factor = 1.5 # < 1 = zoom_in; > 1 = zoom_out
var transition_time = 0.25

func _ready():
	max_zoom = zoom.x
	min_zoom = max_zoom * zoom_factor

func _process(delta):
	if(Input.is_action_just_pressed("ui_up") == true):
		zoom_in(position - get_camera_position())
	
	
func zoom_in(new_offset):
	transition_camera(Vector2(min_zoom, min_zoom), new_offset)


func zoom_out(new_offset):
	transition_camera(Vector2(max_zoom, max_zoom), new_offset)


func transition_camera(new_zoom, new_offset):
	if new_zoom != current_zoom:
		current_zoom = new_zoom
