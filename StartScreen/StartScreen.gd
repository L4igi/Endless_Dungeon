extends Control

var roomSizeMin = 8
var roomSizeMax = 12
var currentRoomSize = 8

var roomsToGenerateMin = 1
var currentRoomsToGenerate = 10

var currentDifficulty = GlobalVariables.DIFFICULTYLEVELS.AUTO

var optionPoppedUp = false

var newGameStarted = false

onready var optionsButton = $Menu/CenterRow/VBoxContainer/OptionsButton
onready var roomSizeLabel = $Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup/HBoxContainer/ItemList/VBoxContainer/roomSizeLabel/value
onready var roomCountLabel = $Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup/HBoxContainer/ItemList/VBoxContainer/roomCountLabel/value
onready var roomDifficultyLabel = $Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup/HBoxContainer/ItemList/VBoxContainer/difficultyLabel/value
onready var optionsItemList = $Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup/HBoxContainer/ItemList

onready var newGameButton = $Menu/CenterRow/VBoxContainer/NewGameButton
# Called when the node enters the scene tree for the first time.
func _ready():
	optionsButton.grab_focus()
	roomSizeLabel.set_text(str(GlobalVariables.roomDimensions))
	roomCountLabel.set_text(str(GlobalVariables.maxNumberRooms))
	roomDifficultyLabel.set_text(str("Auto"))
	


func _process(delta):
	if optionsButton.is_pressed():
		$Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup.popup_centered()
		optionPoppedUp = true
		
	changeOptionValue()
	
	start_new_game()


func changeOptionValue():
	if Input.is_action_just_pressed("Mode_Sword"):	
		if optionsItemList.is_selected(0):
			if currentRoomSize > roomSizeMin:
				currentRoomSize -= 1
				roomSizeLabel.set_text(str(currentRoomSize))
				GlobalVariables.roomDimensions = currentRoomSize
		elif optionsItemList.is_selected(1):
			if currentRoomsToGenerate > roomsToGenerateMin:
				currentRoomsToGenerate -= 1
				roomCountLabel.set_text(str(currentRoomsToGenerate))
				GlobalVariables.maxNumberRooms= currentRoomsToGenerate
		elif optionsItemList.is_selected(2):
			if currentDifficulty > 0:
				currentDifficulty-=1
				var setString = match_difficulty_enum(currentDifficulty)
				roomDifficultyLabel.set_text(str(setString))
				GlobalVariables.chosenDifficulty = currentDifficulty
			
	elif Input.is_action_just_pressed("Mode_Block"):
		if optionsItemList.is_selected(0):
			if currentRoomSize < roomSizeMax:
				currentRoomSize += 1
				roomSizeLabel.set_text(str(currentRoomSize))
				GlobalVariables.roomDimensions = currentRoomSize
		elif optionsItemList.is_selected(1):
			currentRoomsToGenerate += 1
			roomCountLabel.set_text(str(currentRoomsToGenerate))
			GlobalVariables.maxNumberRooms= currentRoomsToGenerate
		elif optionsItemList.is_selected(2):
			if currentDifficulty < GlobalVariables.DIFFICULTYLEVELS.size()-1:
				currentDifficulty+=1
				var setString = match_difficulty_enum(currentDifficulty)
				roomDifficultyLabel.set_text(str(setString))
				GlobalVariables.chosenDifficulty = currentDifficulty

func match_difficulty_enum(value):
	match value:
		GlobalVariables.DIFFICULTYLEVELS.AUTO:
			GlobalVariables.globalDifficultyMultiplier = 1.0
			return "Auto"
		GlobalVariables.DIFFICULTYLEVELS.EASY:
			GlobalVariables.globalDifficultyMultiplier = 0.5
			return "Easy"
		GlobalVariables.DIFFICULTYLEVELS.NORMAL:
			GlobalVariables.globalDifficultyMultiplier = 1.0
			return "Norm"
		GlobalVariables.DIFFICULTYLEVELS.HARD:
			GlobalVariables.globalDifficultyMultiplier = 1.5
			return "Hard"
			
func start_new_game():
	if newGameButton.is_pressed() && !newGameStarted:
		newGameStarted = true
		print("NEWGAME")
		get_tree().change_scene("res://World/World.tscn")
