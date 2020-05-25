extends Node2D

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.ITEM

onready var Grid = get_parent()

var keyTexture = preload ("res://GameObjects/Item/Key_Item.png")
var potionTexture = preload ("res://GameObjects/Enemy/Magic_Flask_Item.png")
var swordTexture = preload ("res://GameObjects/Item/Sword_Color.png")
var heartContainerTexture = preload ("res://GameObjects/Item/Heart_Item.png")
var flaskContainerTexture = preload ("res://GameObjects/Item/Flask_Item.png")
var puzzleSwitch = preload("res://GameObjects/Item/PuzzleSwitch.png")

var keyValue 

var itemType

var modulation 

func _ready():
	pass # Replace with function body.

func setTexture(textureType):
	match textureType:
		GlobalVariables.ITEMTYPE.POTION:
			get_node("Sprite").set_texture(potionTexture)
			itemType = GlobalVariables.ITEMTYPE.POTION
		GlobalVariables.ITEMTYPE.KEY:
			get_node("Sprite").set_texture(keyTexture)
			itemType = GlobalVariables.ITEMTYPE.KEY
		GlobalVariables.ITEMTYPE.WEAPON:
			get_node("Sprite").set_texture(swordTexture)
			itemType = GlobalVariables.ITEMTYPE.WEAPON
		GlobalVariables.ITEMTYPE.HEARTCONTAINER:
			get_node("Sprite").set_texture(heartContainerTexture)
			itemType = GlobalVariables.ITEMTYPE.HEARTCONTAINER
		GlobalVariables.ITEMTYPE.FLASKCONTAINER:
			get_node("Sprite").set_texture(flaskContainerTexture)
			itemType = GlobalVariables.ITEMTYPE.FLASKCONTAINER
		GlobalVariables.ITEMTYPE.PUZZLESWITCH:
			get_node("Sprite").set_texture(puzzleSwitch)
			itemType = GlobalVariables.ITEMTYPE.PUZZLESWITCH
