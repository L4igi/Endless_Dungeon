#sets sprites for wall pieces and rotates them 
extends Node2D

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8}
export(CELL_TYPES) var type = CELL_TYPES.WALL

var corner = preload ("res://GameObjects/Wall/Corner.png")

func _ready():
	pass

func set_Texture(piece, rotation):
	if piece == "corner":
		get_node("Sprite").set_texture(corner)
		get_node("Sprite").rotation_degrees = rotation
	else:
		get_node("Sprite").rotation_degrees = rotation
