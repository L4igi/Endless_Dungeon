extends PopupPanel

var isPoppedUp = false

onready var mainPlayer = get_parent().get_parent()

onready var window_size = OS.get_window_size()

onready var yesButton = $HBoxContainer/VBoxContainer/ButtonYes
onready var noButton = $HBoxContainer/VBoxContainer/ButtonNo
onready var restartButton = $HBoxContainer/ButtonQuickR

# Called when the node enters the scene tree for the first time.
func _ready():
	set_exclusive(true)

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
				self.rect_position = Vector2(50,50)
				yesButton.grab_focus()
	if isPoppedUp && noButton.is_pressed():
		isPoppedUp = false
		self.set_visible(false)
		mainPlayer.inInventory = false
	elif isPoppedUp && yesButton.is_pressed():
		return_to_menu()
	elif isPoppedUp && restartButton.is_pressed():
		quick_restart()
	
func open_close_Inventory():
	if Input.is_action_just_pressed("open_pauseMenu"):
		return true
	return false
	
func return_to_menu():
	mainPlayer.resetStats()
	mainPlayer.get_parent().save_game()
	GlobalVariables.globalAudioPlayer.inMenu = true
	GlobalVariables.globalAudioPlayer.stream = load("res://GlobalVariables/GameLoop-Menu.ogg")
	GlobalVariables.globalAudioPlayer.play()
	get_tree().change_scene("res://StartScreen/StartScreen.tscn")
	
func quick_restart():
	mainPlayer.resetStats()
	mainPlayer.get_parent().save_game()
	get_tree().change_scene("res://World/World.tscn")
