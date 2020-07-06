#Inventory System to show Key Items 
#scales to windows size to be readable even if camera zoomed out

extends PopupPanel

var isPoppedUp = false

onready var mainPlayer = get_parent().get_parent()

onready var window_size = OS.get_window_size()

func _process(delta):
	var openInventory = open_close_Inventory()
	if openInventory:
		if isPoppedUp:
			isPoppedUp = false
			self.set_visible(false)
			mainPlayer.inInventory = false
		else:
			var otherMenuPoppedUp = false
			for child in get_parent().get_children():
				if child is PopupPanel && child != self:
					if child.isPoppedUp:
						otherMenuPoppedUp = true
			if mainPlayer.movedThroughDoorDirection == Vector2.ZERO && !otherMenuPoppedUp:
				mainPlayer.inInventory = true
				isPoppedUp = true
				#print(self.rect_position)
				#print(get_parent().position)
				self.popup()
				self.rect_position = Vector2(33,90)
	
	if isPoppedUp:
		change_tab_move_list()
	
func open_close_Inventory():
	if Input.is_action_just_pressed("open_inventory"):
		if get_node("Tabs").get_current_tab() == 1:
			get_node("Tabs").set_current_tab(0)
		return true
	return false

func change_tab_move_list():
	if Input.is_action_just_pressed("toggle_danger_area_previous"):
		if get_node("Tabs").get_current_tab() == 1:
			get_node("Tabs").set_current_tab(0)
	elif Input.is_action_just_pressed("toggle_danger_area_next"):
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
