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
	get_node("BoxBarrierItems")._set_size(roomSize*GlobalVariables.tileSize - Vector2(GlobalVariables.tileSize, GlobalVariables.tileSize)*2)
	self.set_visible(false)
#	#get_node("showBarrierItemsTrek")._set_position(doorRoomLeftMostCorner)
#	print("doorCornerDistanceCoords" + str(doorCornerDistanceCoords))
#	print("leftmostcorner " + str(doorRoomLeftMostCorner))

func addBoxElement(item):
	var boxToAddTo = get_node("BoxBarrierItems/BoxKeys")
	#fill and expand
	boxToAddTo.set_h_size_flags(3)
	match item.itemType:
		GlobalVariables.ITEMTYPE.KEY:
			boxToAddTo = get_node("BoxBarrierItems/BoxKeys")
		GlobalVariables.ITEMTYPE.WEAPON:
			boxToAddTo = get_node("BoxBarrierItems/BoxWeapons")
		GlobalVariables.ITEMTYPE.PUZZLESWITCH:
			boxToAddTo = get_node("BoxBarrierItems/BoxPuzzle")
	var addVBoxTextureLabel = VBoxContainer.new()
	addVBoxTextureLabel.set_h_size_flags(3)
	addVBoxTextureLabel.set_v_size_flags(3)
	var addTextureRect = TextureRect.new()
	addTextureRect.set_h_size_flags(3)
	addTextureRect.set_v_size_flags(3)
	addTextureRect.set_expand(true)
	#set keep aspect and center
	addTextureRect.set_stretch_mode(6)
	addTextureRect.set_texture(item.get_node("Sprite").get_texture())
	addTextureRect.set_modulate(item.modulation)
	var addLabel = Label.new()
	addLabel.add_color_override("font_color", Color(0,0,0,1))
	addLabel.set_text(str(item.keyValue))
	addLabel.set_align(1)

	addVBoxTextureLabel.add_child(addTextureRect)
	
	addVBoxTextureLabel.add_child(addLabel)
	
	boxToAddTo.add_child(addVBoxTextureLabel)
	
func delete_Box_item(item):
	#todo: delete element from box if used 
	pass
	
	
	
