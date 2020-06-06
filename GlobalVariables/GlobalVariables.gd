extends Node

var roomDimensions = 10

var maxNumberRooms = 15

enum BARRIERTYPE {DOOR = 0, ENEMY = 1, PUZZLE = 2}

enum CURRENTPHASE {PLAYER = 0, ENEMY = 1, PLAYERPROJECTILE = 2, ENEMYPROJECTILE=3 , BLOCK = 4, PUZZLEPROJECTILE=5}

enum ENEMYTYPE{BARRIERENEMY=0, MAGEENEMY=1, WARRIROENEMY=2, NINJAENEMY=3}

enum CELL_TYPES{EMPTY =-1, PLAYER=0, WALL=1, ENEMY=2, PUZZLEPIECE=3, ITEM=4, DOOR=5, UNLOCKEDDOOR=6, MAGICPROJECTILE=7, BLOCK=8, FLOOR = 9}

enum DIRECTION{LEFT=0, RIGHT=1, UP=2, DOWN=3, MIDDLE=4, RIGHTDOWN = 5, RIGHTUP = 6, LEFTDOWN = 7, LEFTUP = 8}

enum ATTACKTYPE{SWORD = 1, MAGIC = 2, NINJA=3, BLOCK = 4, HAND = 5}

enum ROOM_TYPE{ENEMYROOM = 0, PUZZLEROOM = 1, EMPTYTREASUREROOM = 2}

enum PROJECTILETYPE{PLAYER = 0, ENEMY = 1, POWERBLOCK = 2, TICKERPROJECTILE = 3}

enum COLOR {RED = 0, GREEN = 1, BLUE = 2, YELLOW = 3} 

enum ITEMTYPE{POTION = 0, KEY = 1, WEAPON = 2, HEARTCONTAINER = 3, FLASKCONTAINER = 4, PUZZLESWITCH=5, EXIT = 6}

enum MOVEMENTATTACKCALCMODE {PREVIEW = 0, ACTION = 1}

var moveAllEnemiesAtOnce = true

var moveAllProjectilesAtOnce = true

var tileOffset = Vector2(16,16)

var tileSize = 32

var isometricFactor = 2

