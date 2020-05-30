extends TextureRect

var itemBoxes = []

var solvedTexture = preload("res://GameObjects/Door/roomMapSolved.png")

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
	itemBoxes.append(item)
	var boxToAddTo = get_node("BoxBarrierItems/BoxKeys")
	#fill and expand
	boxToAddTo.set_h_size_flags(3)
	var newName = "key"
	match item.itemType:
		GlobalVariables.ITEMTYPE.KEY:
			boxToAddTo = get_node("BoxBarrierItems/BoxKeys")
			newName = "key"
		GlobalVariables.ITEMTYPE.WEAPON:
			boxToAddTo = get_node("BoxBarrierItems/BoxWeapons")
			newName = "weapon"
		GlobalVariables.ITEMTYPE.PUZZLESWITCH:
			boxToAddTo = get_node("BoxBarrierItems/BoxPuzzle")
			newName = "puzzleswitch"
	var addVBoxTextureLabel = VBoxContainer.new()
	addVBoxTextureLabel.set_name(newName + str(item.keyValue))
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
	print("In Map deleting Barrier item from map")
	var boxToDelete = null
	var nameToDel = "key"
	match item.itemType:
		GlobalVariables.ITEMTYPE.KEY:
			boxToDelete = get_node("BoxBarrierItems/BoxKeys")
			nameToDel = "key"
		GlobalVariables.ITEMTYPE.WEAPON:
			boxToDelete = get_node("BoxBarrierItems/BoxWeapons")
			nameToDel = "weapon"
		GlobalVariables.ITEMTYPE.PUZZLESWITCH:
			boxToDelete = get_node("BoxBarrierItems/BoxPuzzle")
			nameToDel = "puzzleswitch"
			
	for child in boxToDelete.get_children():
		print(child.get_name())
		if child.get_name() == nameToDel+str(item.keyValue):
			child.queue_free()
			break
	
func toggleBox():
	if !self.is_visible():
		self.set_visible(true)
	else:
		self.set_visible(false)
	
func setSolvedTexture():
	self.set_texture(solvedTexture)
	
