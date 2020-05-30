extends TextureRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_dimensions(roomSize, doorPos, doorRoomLeftMostCorner):
	_set_size(roomSize*GlobalVariables.tileSize - Vector2(GlobalVariables.tileSize, GlobalVariables.tileSize)*2)
	var doorCornerDistanceCoords = doorPos-(doorRoomLeftMostCorner+Vector2(GlobalVariables.tileSize, GlobalVariables.tileSize))
	_set_position(Vector2(-doorCornerDistanceCoords.x, -doorCornerDistanceCoords.y)- GlobalVariables.tileOffset)
#	#get_node("showBarrierItemsTrek")._set_position(doorRoomLeftMostCorner)
#	print("doorCornerDistanceCoords" + str(doorCornerDistanceCoords))
#	print("leftmostcorner " + str(doorRoomLeftMostCorner))

func addBoxElement(item):
	match item.itemType:
		GlobalVariables.ITEMTYPE.KEY:
			pass
		GlobalVariables.ITEMTYPE.WEAPON:
			pass
		GlobalVariables.ITEMTYPE.PUZZLESWITCH:
			pass
