extends Node2D

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.ITEM

onready var Grid = get_parent()

var keyTexture = preload ("res://GameObjects/Item/Key_Item.png")
var potionTexture = preload ("res://GameObjects/Enemy/Magic_Flask_Item.png")
var swordTexture = preload ("res://GameObjects/Item/Sword_Color.png")
var heartContainerTexture = preload ("res://GameObjects/Item/Heart_Item.png")
var flaskContainerTexture = preload ("res://GameObjects/Item/Flask_Item.png")

var keyValue 

var itemType

var modulation 

func _ready():
	pass # Replace with function body.

func setTexture(textureType):
	match textureType:
		"POTION":
			get_node("Sprite").set_texture(potionTexture)
			itemType = "POTION"
		"KEY":
			get_node("Sprite").set_texture(keyTexture)
			itemType = "KEY"
		"WEAPON":
			get_node("Sprite").set_texture(swordTexture)
			itemType = "WEAPON"
		"HEARTCONTAINER":
			get_node("Sprite").set_texture(heartContainerTexture)
			itemType = "HEARTCONTAINER"
		"FLASKCONTAINER":
			get_node("Sprite").set_texture(flaskContainerTexture)
			itemType = "FLASKCONTAINER"
