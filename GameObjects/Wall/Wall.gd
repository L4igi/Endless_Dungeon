extends Node2D

enum CELL_TYPES{PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5}
export(CELL_TYPES) var type = CELL_TYPES.WALL

func _ready():
	pass

func _process(delta):
	pass
