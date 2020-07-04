extends Control

var roomSizeMin = 8
var roomSizeMax = 12
var currentRoomSize = GlobalVariables.roomDimensions

var roomsToGenerateMin = 1
var currentRoomsToGenerate = GlobalVariables.maxNumberRooms

var currentDifficulty = GlobalVariables.chosenDifficulty

var currentRoomLayout = GlobalVariables.globaleRoomLayout

var optionPoppedUp = false

var newGameStarted = false

onready var optionsButton = $Menu/CenterRow/VBoxContainer/OptionsButton
onready var roomSizeLabel = $Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup/HBoxContainer/ItemList/VBoxContainer/roomSizeLabel/value
onready var roomCountLabel = $Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup/HBoxContainer/ItemList/VBoxContainer/roomCountLabel/value
onready var roomDifficultyLabel = $Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup/HBoxContainer/ItemList/VBoxContainer/difficultyLabel/value
onready var roomLayoutLabel = $Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup/HBoxContainer/ItemList/VBoxContainer/roomLayoutLabel/value
onready var optionsItemList = $Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup/HBoxContainer/ItemList
onready var exitGameButton = $Menu/CenterRow/VBoxContainer/ExitGame

onready var newGameButton = $Menu/CenterRow/VBoxContainer/NewGameButton
# Called when the node enters the scene tree for the first time.
func _ready():
	newGameButton.grab_focus()
	roomSizeLabel.set_text(str(GlobalVariables.roomDimensions))
	roomCountLabel.set_text(str(GlobalVariables.maxNumberRooms))
	roomDifficultyLabel.set_text(str(match_difficulty_enum(GlobalVariables.chosenDifficulty)))
	roomLayoutLabel.set_text(str(match_layout_enum(GlobalVariables.globaleRoomLayout)))
	currentDifficulty = GlobalVariables.chosenDifficulty
	if GlobalVariables.globalAudioPlayer.inMenu:
		GlobalVariables.globalAudioPlayer.stream = load("res://GlobalVariables/GameLoop-Menu.ogg")
		GlobalVariables.globalAudioPlayer.play()
	else:
		GlobalVariables.globalAudioPlayer.stream = load("res://GlobalVariables/GameLoop-Menu_Boot.ogg")
		GlobalVariables.globalAudioPlayer.play()
	GlobalVariables.globalAudioPlayer.inMenu = true


func _process(delta):
	if optionsButton.is_pressed():
		$Menu/CenterRow/VBoxContainer/OptionsButton/OptionsPopup.popup_centered()
		optionPoppedUp = true
		
	changeOptionValue()
	
	start_new_game()
	
	exit_game()


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
		elif optionsItemList.is_selected(3):
			if currentRoomLayout > 0:
				currentRoomLayout -=1
				var setString = match_layout_enum(currentRoomLayout)
				roomLayoutLabel.set_text(str(setString))
				GlobalVariables.globaleRoomLayout = currentRoomLayout
				
			
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
		elif optionsItemList.is_selected(3):
			if currentRoomLayout < GlobalVariables.ROOMLAYOUT.size()-1:
				currentRoomLayout +=1
				var setString = match_layout_enum(currentRoomLayout)
				roomLayoutLabel.set_text(str(setString))
				GlobalVariables.globaleRoomLayout = currentRoomLayout

func match_difficulty_enum(value):
	match value:
		GlobalVariables.DIFFICULTYLEVELS.AUTO:
			GlobalVariables.globalDifficultyMultiplier = 1.0
			adjust_global_difficulty(2)
			return "Auto"
		GlobalVariables.DIFFICULTYLEVELS.EASY:
			GlobalVariables.globalDifficultyMultiplier = 0.5
			adjust_global_difficulty(1)
			return "Easy"
		GlobalVariables.DIFFICULTYLEVELS.NORMAL:
			GlobalVariables.globalDifficultyMultiplier = 1.0
			adjust_global_difficulty(2)
			return "Norm"
		GlobalVariables.DIFFICULTYLEVELS.HARD:
			GlobalVariables.globalDifficultyMultiplier = 1.5
			adjust_global_difficulty(3)
			return "Hard"

func match_layout_enum(value):
	match value: 
		GlobalVariables.ROOMLAYOUT.MIXED:
			return "Mixed"
		GlobalVariables.ROOMLAYOUT.SMALL:
			return "Small"
		GlobalVariables.ROOMLAYOUT.BIG:
			return "Big"
		GlobalVariables.ROOMLAYOUT.LONG:
			return "Long"
		GlobalVariables.ROOMLAYOUT.BIGLONG:
			return "BLong"
		GlobalVariables.ROOMLAYOUT.BIGSMALL:
			return "BSmall"
		GlobalVariables.ROOMLAYOUT.SMALLLONG:
			return "SLong"
		
func adjust_global_difficulty(multiplier):
	GlobalVariables.enemyWarriorDifficulty = multiplier
	GlobalVariables.enemyNinjaDifficulty = multiplier
	GlobalVariables.enemyBarrierDifficulty = multiplier
	GlobalVariables.enemyMageDifficulty = multiplier
	
func start_new_game():
	if newGameButton.is_pressed() && !newGameStarted:
		newGameStarted = true
		#print("NEWGAME")
		get_tree().change_scene("res://World/World.tscn")
		GlobalVariables.globalAudioPlayer.inMenu = false

func exit_game():
	if exitGameButton.is_pressed():
		get_tree().quit()
