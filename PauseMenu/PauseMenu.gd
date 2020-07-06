#pausemenu to return to title scrren or quickly restart game 
#pauses rest of the game while in menu
extends PopupPanel

var isPoppedUp = false

onready var mainPlayer = get_parent().get_parent()

onready var window_size = OS.get_window_size()

onready var yesButton = $HBoxContainer/VBoxContainer/ButtonYes
onready var noButton = $HBoxContainer/VBoxContainer/ButtonNo
onready var restartButton = $HBoxContainer/ButtonQuickR

func _ready():
	set_exclusive(true)

func _process(delta):
	var openInventory = open_close_Inventory()
	if openInventory:
		open_inventory_interaction()
	if isPoppedUp:
		popup_interactions()
	
func open_close_Inventory():
	if Input.is_action_just_pressed("open_pauseMenu"):
		return true
	return false
	
func open_inventory_interaction():
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
			self.popup()
			self.rect_position = Vector2(50,50)
			yesButton.grab_focus()
	
func popup_interactions():
	if noButton.is_pressed():
		isPoppedUp = false
		self.set_visible(false)
		mainPlayer.inInventory = false
	elif yesButton.is_pressed():
		return_to_menu()
	elif restartButton.is_pressed():
		quick_restart()
	
func return_to_menu():
	GlobalVariables.firstCall = true
	mainPlayer.resetStats()
	mainPlayer.get_parent().save_game()
	GlobalVariables.globalAudioPlayer.inMenu = true
	GlobalVariables.globalAudioPlayer.stream = load("res://GlobalVariables/GameLoop-Menu.ogg")
	GlobalVariables.globalAudioPlayer.play()
	get_tree().change_scene("res://StartScreen/StartScreen.tscn")
	
func quick_restart():
	GlobalVariables.firstCall = true
	mainPlayer.resetStats()
	mainPlayer.get_parent().save_game()
	get_tree().change_scene("res://World/World.tscn")
