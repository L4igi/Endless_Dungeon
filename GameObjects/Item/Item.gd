extends Node2D

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR = 6, MAGICPROJECTILE=7}
export(CELL_TYPES) var type = CELL_TYPES.ITEM

onready var Grid = get_parent()

var potionTexture = preload ("res://GameObjects/Enemy/Magic_Flask_Item.png")

var keyValue 

var itemType

func _ready():
	pass # Replace with function body.

func setTexture(textureType):
	match textureType:
		"POTION":
			get_node("Sprite").set_texture(potionTexture)
			itemType = "POTION"
		"KEY":
			itemType = "KEY"
		"WEAPON":
			itemType = "WEAPON"
