extends Control

var roomSizeMin = 8
var roomSizeMax = 12
var currentRoomSize = 8

var roomsToGenerateMin = 1
var currentRoomsToGenerate = 10

var optionPoppedUp = false

onready var optionsButton = $Menu/CenterRow/VBoxContainer/OptionsButton
onready var roomSizeLabel = $Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup/HBoxContainer/ItemList/VBoxContainer/roomSizeLabel/value
onready var roomCountLabel = $Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup/HBoxContainer/ItemList/VBoxContainer/roomCountLabel/value
onready var roomDifficultyLabel = $Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup/HBoxContainer/ItemList/VBoxContainer/difficultyLabel/value
onready var optionsItemList = $Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup/HBoxContainer/ItemList
# Called when the node enters the scene tree for the first time.
func _ready():
	optionsButton.grab_focus()
	roomSizeLabel.set_text(str(currentRoomSize))
	roomCountLabel.set_text(str(currentRoomsToGenerate))
	


func _process(delta):
	if optionsButton.is_pressed():
		$Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup.popup_centered()
		optionPoppedUp = true
		
	changeOptionValue()


func changeOptionValue():
	if Input.is_action_just_pressed("Mode_Sword"):	
		if optionsItemList.is_selected(0):
			if currentRoomSize > roomSizeMin:
				currentRoomSize -= 1
				roomSizeLabel.set_text(str(currentRoomSize))
			
	elif Input.is_action_just_pressed("Mode_Block"):
		if optionsItemList.is_selected(0):
			if currentRoomSize < roomSizeMax:
				currentRoomSize += 1
				roomSizeLabel.set_text(str(currentRoomSize))
