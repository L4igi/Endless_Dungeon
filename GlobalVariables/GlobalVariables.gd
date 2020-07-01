extends Node

var roomDimensions = 8

var maxNumberRooms = 2

enum BARRIERTYPE {DOOR = 0, ENEMY = 1, PUZZLE = 2}

enum CURRENTPHASE {PLAYER = 0, ENEMY = 1, PLAYERPROJECTILE = 2, ENEMYPROJECTILE=3 , ENEMYATTACK = 4, PUZZLEPROJECTILE=5, PLAYERDEFEAT=6, ROOMCLEARED = 7}

enum ENEMYTYPE{BARRIERENEMY=0, MAGEENEMY=1, WARRIROENEMY=2, NINJAENEMY=3}

enum CELL_TYPES{EMPTY =-1, PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8, FLOOR = 9, UPGRADECONTAINER = 10, COUNTINGBLOCK = 11}

enum DIRECTION{LEFT=0, RIGHT=1, UP=2, DOWN=3, MIDDLE=4, RIGHTDOWN = 5, RIGHTUP = 6, LEFTDOWN = 7, LEFTUP = 8}

enum ATTACKTYPE{SWORD = 1, MAGIC = 2, NINJA=3, BLOCK = 4, HAND = 5, SAVED=6}

enum UPGRADETYPE {SWORD = 1, MAGIC = 2, HEART = 3, FLASK = 4, FILLHEART=5, FILLFLASK=6, ACTIONSUP=7, BOMB=8}

enum ROOM_TYPE{ENEMYROOM = 0, PUZZLEROOM = 1, EMPTYTREASUREROOM = 2}

enum PROJECTILETYPE{PLAYER = 0, ENEMY = 1, POWERBLOCK = 2, TICKERPROJECTILE = 3}

enum COLOR {RED = 0, GREEN = 1, BLUE = 2, YELLOW = 3} 

enum ITEMTYPE{POTION = 0, KEY = 1, WEAPON = 2, HEARTCONTAINER = 3, FLASKCONTAINER = 4, PUZZLESWITCH=5, EXIT = 6, COIN=7, FILLUPHEART = 8, FILLUPHALFHEART=9}

enum MOVEMENTATTACKCALCMODE {PREVIEW = 0, ACTION = 1}

enum DIFFICULTYLEVELS {AUTO=0, EASY=1, NORMAL=2, HARD=3}

var chosenDifficulty = DIFFICULTYLEVELS.AUTO

var upgradeCosts = [3,3,4,6,1,2,6,2]

var upgradeAmount = [0.25,0.15,2,1,2,1,1,0.3]

var moveAllEnemiesAtOnce = true

var moveAllProjectilesAtOnce = true

var tileOffset = Vector2(16,16)

var tileSize = 32

var isometricFactor = 2

var turnController = preload("res://TurnController.gd").new()

var firstCall = true

var globalDifficultyMultiplier = 1.0

var minDifficulty = 0.5 

var maxDifficulty = 1.5

var enemyWarriorDifficulty = 1
var enemyNinjaDifficulty = 1
var enemyBarrierDifficulty = 1
var enemyMageDifficulty = 1

var hitByWarrior = 0
var hitByNinja = 0
var hitByMage = 0
var hitByBarrier = 0

var timesActivatedPuzzleWrong = 0
var countPuzzleRoomsCleared = 0

var turnsTakenInEnemyRoom = 0
var turnsTakenInPuzzleRoom = 0 

var puzzleBonusLootDropped = 0
var enemyBonusLootDropped = 0

var enemyRoomChance = 65
var puzzleRoomChance = 20
var emptyTreasureRoomChance = 15

var currentFloor = 0

var globalAudioPlayerScene = preload("res://GlobalVariables/GlobalAudioPlayer.tscn")

var globalAudioPlayer = null

func _ready():
	globalAudioPlayer = globalAudioPlayerScene.instance()
	add_child(globalAudioPlayer)
	globalAudioPlayer.stream = load("res://GlobalVariables/GameLoop.ogg")
	globalAudioPlayer.play()
