extends PopupPanel

onready var Grid = get_parent()

var isPoppedUp = false

var currentPlayerPosition
# Called when the node enters the scene tree for the first time.
func _ready():
	set_exclusive(true)


func _process(delta):
	var openInventory = open_close_Inventory()
	if openInventory:
		if isPoppedUp:
			isPoppedUp = false
			get_tree().paused = false
			self.set_visible(false)
		else:
			isPoppedUp = true
			print(self.rect_position)
			print(get_parent().position)
			get_tree().paused = true
			self.popup()
			self.rect_position = get_parent().position
	
func open_close_Inventory():
	if Input.is_action_just_pressed("open_inventory"):
		return true
	return false
