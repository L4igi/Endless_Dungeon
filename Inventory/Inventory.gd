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
			self.set_visible(false)
			get_parent().inInventory = false
		else:
			if get_parent().movedThroughDoorDirection == Vector2.ZERO:
				get_parent().inInventory = true
				isPoppedUp = true
				print(self.rect_position)
				print(get_parent().position)
				self.popup()
				self.rect_position = get_parent().position
	
	if isPoppedUp:
		change_tab_move_list()
	
func open_close_Inventory():
	if Input.is_action_just_pressed("open_inventory"):
		return true
	return false

func change_tab_move_list():
	if Input.is_action_just_pressed("player_left"):
		if get_node("Tabs").get_current_tab() == 1:
			get_node("Tabs").set_current_tab(0)
	elif Input.is_action_just_pressed("player_right"):
		if get_node("Tabs").get_current_tab() == 0:
			get_node("Tabs").set_current_tab(1)
	if Input.is_action_pressed("player_up"):
		if get_node("Tabs").get_current_tab() == 0:
			if get_node("Tabs/Key/KeyList").get_child_count()>2:
				get_node("Tabs/Key").scroll_vertical-=2
		elif get_node("Tabs").get_current_tab() == 1:
			if get_node("Tabs/Weapon/WeaponList").get_child_count()>2:
				get_node("Tabs/Weapon").scroll_vertical-=2
	elif Input.is_action_pressed("player_down"):
		if get_node("Tabs").get_current_tab() == 0:
			if get_node("Tabs/Key/KeyList").get_child_count()>2:
				get_node("Tabs/Key").scroll_vertical+=2
		elif get_node("Tabs").get_current_tab() == 1:
			if get_node("Tabs/Weapon/WeaponList").get_child_count()>2:
				get_node("Tabs/Weapon").scroll_vertical+=2
			
func move_list_up_down():
	if Input.is_action_just_pressed("player_down"):
		return GlobalVariables.DIRECTION.DOWN
	elif Input.is_action_just_pressed("player_up"):
		return GlobalVariables.DIRECTION.UP
