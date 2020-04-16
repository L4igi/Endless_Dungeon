extends TileMap

enum objectTyped { EMPTY, PLAYER, WALL, ENEMY, PUZZLEPIECE, ITEM, DOOR}

var Enemy = preload("res://GameObjects/Enemy/Enemy.tscn")

var Wall = preload("res://GameObjects/Wall/Wall.tscn")

var Door = preload("res://GameObjects/Door/Door.tscn")

var roomDimensions = 5

var evenOddModifier = 0 

func match_Enum(var index):
	match index:
		0:
			return "PLAYER"
		1:
			return "WALL"
		2:
			return "ENEMY"
		3:
			return "PUZZLEPIECE"
		4:
			return "ITEM"
		5:
			return "DOOR"
		-1:
			return "EMPTY"
		_:
			return "NULL"
			

func set_enum_index(var enumName, var setTo):
	match enumName:
		"PLAYER":
			objectTyped.PLAYER=setTo
		"WALL":
			objectTyped.WALL=setTo
		"ENEMY":
			objectTyped.ENEMY=setTo
		"PUZZLEPIECE":
			objectTyped.PUZZLEPIECE=setTo
		"ITEM":
			objectTyped.ITEM=setTo
		"DOOR":
			objectTyped.DOOR=setTo
		"EMPTY":
			objectTyped.EMPTY=-1
		_:
			pass
			

func _ready():
	for child in get_children():
		set_cellv(world_to_map(child.position), get_tileset().find_tile_by_name(match_Enum(child.type)))
	for element in objectTyped:
		set_enum_index(element, get_tileset().find_tile_by_name(element))
		#print(get_tileset().find_tile_by_name(element))
	if(roomDimensions%2 == 0):
		evenOddModifier = 1
	create_starting_room(true)
		

func get_cell_pawn(coordinates):
	for node in get_children():
		if world_to_map(node.position) == coordinates:
			return(node)
			
			
func request_move(pawn, direction):
	var cell_start = world_to_map(pawn.position)
	
	var cell_target = cell_start + direction
	var cell_target_type = get_cellv(cell_target)
	
#	cell_target_type = get_tileset().find_tile_by_name(matchEnum(cell_target_type))
#	print(get_tileset().find_tile_by_name(matchEnum(cell_target_type)))
		#print("Got Cell V: " + str(cell_target_type))
	match cell_target_type:
		objectTyped.EMPTY:
			#print("EMPTY")
			#print("Player Position " + str(cell_target))
			return update_pawn_position(pawn, cell_start, cell_target)
		objectTyped.ENEMY:
			var object_pawn = get_cell_pawn(cell_target)
			object_pawn.queue_free()
			#print("ENEMY")
			return update_pawn_position(pawn, cell_start, cell_target)
		objectTyped.WALL:
			print("WALL")
		objectTyped.DOOR:
			if(pawn.name == "Player"):
				var object_pawn = get_cell_pawn(cell_target)
				object_pawn.unlock_Door()
				return update_pawn_position(pawn, cell_start, cell_target)
			



func update_pawn_position(pawn, cell_start, cell_target):
	set_cellv(cell_target, get_tileset().find_tile_by_name(match_Enum(pawn.type)))
	set_cellv(cell_start, objectTyped.EMPTY)
	return map_to_world(cell_target) + cell_size / 2
	

func _spawn_enemy_after_move(player):
	randomize()
	#print("player pos "+ str(player.position))
	var spawn_pos = player.position
	while(player.position == spawn_pos):
		var posx = randi()%11+1
		var posy = randi()%11+1
		spawn_pos = map_to_world(Vector2(posx, posy))-Vector2(16,16)
	#spawn_pos=Vector2(16,16)
	var spawn_pos_type = get_cellv(world_to_map(spawn_pos))
	print("Enemy Spawn Position Type " + str(spawn_pos_type))
	match spawn_pos_type:
		objectTyped.EMPTY:
			var newEnemy = Enemy.instance()
			newEnemy.position = spawn_pos
			add_child(newEnemy)
			set_cellv(world_to_map(newEnemy.position), get_tileset().find_tile_by_name(match_Enum(newEnemy.type)))
			print(newEnemy.name)
			#setEnumIndex(newEnemy.type, get_tileset().find_tile_by_name(matchEnum(newEnemy.type)))
		objectTyped.PLAYER:
			print("Cell is Player")
		objectTyped.WALL:
			print("Wall hit")
		_:
			print("Cell not available")


func create_starting_room(startingRoom=false):
	create_walls(null, startingRoom, true)



func create_walls (door = null, startingRoom = false, createDoors = false):
	#todo:calculate actual position of leftmost corner wall tile of the room
	randomize()
	var leftmostCorner = Vector2.ZERO
	var roomSizeHorizontal = roomDimensions
	var roomSizeVertical = roomDimensions
	var disableDown = false
	var disableUp = false
	var disableLeft = false
	var disableRight = false
	var disableLong = false
	var disableBig = false
	if(startingRoom):
		leftmostCorner = Vector2(16,16)
	else:
		var minRoomSize = roomSizeHorizontal

		match door.doorDirection:
			"LEFT":
				#see if there are any cross section and diasble this option to keep tiles from intersecting
				leftmostCorner=world_to_map(door.position-map_to_world(Vector2(minRoomSize, minRoomSize/2-evenOddModifier)))
				print("LEFT LEftMost Corner " + str(leftmostCorner) + " door position " + str(world_to_map(door.position)))
				#check for wall up for room to be created 
				print("LEFT Up Modifier : " + str(leftmostCorner-Vector2(0,1)) + " " + str(get_cellv(leftmostCorner-Vector2(0,1))))
				if(get_cellv(leftmostCorner-Vector2(0,1)) == objectTyped.WALL):
					disableUp = true
				#check for wall down for room to be created 
				print("LEFT Down modifier : " + str(leftmostCorner+Vector2(0,minRoomSize)) + " " + str(get_cellv(leftmostCorner+Vector2(0,minRoomSize))))
				if(get_cellv(leftmostCorner+Vector2(0,minRoomSize)) == objectTyped.WALL):
					disableDown = true
				#check for wall long for room to be created 
				if(get_cellv(leftmostCorner-Vector2(1,0)) == objectTyped.WALL):
					disableLong = true
				print("LEFT LONG modifier : " + str(leftmostCorner-Vector2(1,0))+ " " + str(get_cellv(leftmostCorner-Vector2(1,0))))
				#randomize and create different room sizes and layout types
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == objectTyped.WALL):
					disableBig = true
				print("Corner Location: " + str(leftmostCorner+Vector2(minRoomSize, minRoomSize)) + " LEFT disableBig " + str(disableBig))
				
				var horizontalRandom = randi()%2+1
				var verticalRandom = randi()%2+1
				var randUpDown = randi()%2+1
				
				if(disableBig == true && horizontalRandom == 2 && horizontalRandom == 2):
					if(randi()%2+1 == 1):
						verticalRandom = 1 
						horizontalRandom = 2
					else:
						verticalRandom = 2
						horizontalRandom = 1
						
				if(disableUp == true && disableDown == true && disableLong == true):
					horizontalRandom = 1 
					verticalRandom = 1
				if(disableUp == true && disableDown == true):
					verticalRandom = 1
				if(disableUp == true):
					randUpDown = 2
				if(disableDown == true):
					randUpDown = 1
				if (disableLong == true):
					horizontalRandom = 1
					
				roomSizeHorizontal = roomSizeHorizontal * horizontalRandom
				roomSizeVertical = roomSizeVertical* verticalRandom
					
				print(str(disableUp) +  " disableup " + str(disableDown) + " disableDown " + str(disableLong) + " disablelong ")
				if(horizontalRandom == 2 && verticalRandom == 2):
					if(randUpDown==1):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal, roomSizeVertical - roomSizeVertical/4 - 1))
						#print(str(ceil(roomSizeVertical/4)))
					else:
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal, roomSizeVertical/4 - evenOddModifier))
				elif(horizontalRandom == 1 &&  verticalRandom == 2):
					if(randUpDown==1):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal, roomSizeVertical - roomSizeVertical/4 - 1))
					else:
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal, roomSizeVertical/4 - evenOddModifier))
						
				elif(horizontalRandom == 2 &&  verticalRandom == 1):
					leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal, roomSizeVertical/2 - evenOddModifier))
						
				else:
					leftmostCorner=door.position-map_to_world(Vector2(minRoomSize, minRoomSize/2-evenOddModifier))
				#print("LEFT LEftMost Corner "+ str(world_to_map(leftmostCorner)))
				
				#set room size and door leftmost corner in door connecting to room to be used for further room creation
				door.doorRoomLeftMostCorner = leftmostCorner
				door.doorLocationDirection = "LEFT"
				door.roomSizeMultiplier = Vector2(horizontalRandom, verticalRandom)
				door.roomSize = Vector2(roomSizeHorizontal, roomSizeVertical)
			"RIGHT":
				#see if there are any cross section and diasble this option to keep tiles from intersecting
				leftmostCorner=world_to_map(door.position+map_to_world(Vector2(1,0)-Vector2(0, minRoomSize/2 - evenOddModifier)))
				print("RIGHT LEftMost Corner " + str(leftmostCorner))
				#check for wall up for room to be created 
				if(get_cellv(leftmostCorner-Vector2(0,1)) == objectTyped.WALL):
					disableUp = true
				print("RIGHT Up Modifier : " + str(leftmostCorner-Vector2(0,1)) + " " + str(get_cellv(leftmostCorner-Vector2(0,1))))
				#check for wall down for room to be created 
				if(get_cellv(leftmostCorner+Vector2(0,minRoomSize)) == objectTyped.WALL):
					disableDown = true
				print("RIGHT Down modifier : " + str(leftmostCorner+Vector2(0,minRoomSize)) + " " + str(get_cellv(leftmostCorner+Vector2(0,minRoomSize))))
				#check for wall long for room to be created 
				if(get_cellv(leftmostCorner+Vector2(minRoomSize,0)) == objectTyped.WALL):
					disableLong = true
				print("RIGHT LONG modifier : " + str(leftmostCorner+Vector2(minRoomSize,0))+ " " + str(get_cellv(leftmostCorner+Vector2(minRoomSize,0))))
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == objectTyped.WALL):
					disableBig = true
				print("Corner Location: " + str(leftmostCorner+Vector2(minRoomSize, minRoomSize)) + " RIGHT disableBig " + str(disableBig))
				
				var horizontalRandom = randi()%2+1
				var verticalRandom = randi()%2+1
				var randUpDown = randi()%2+1
				
				if(disableBig == true && horizontalRandom == 2 && horizontalRandom == 2):
					if(randi()%2+1 == 1):
						verticalRandom = 1 
						horizontalRandom = 2
					else:
						verticalRandom = 2
						horizontalRandom = 1
						
				if(disableUp == true && disableDown == true && disableLong == true):
					horizontalRandom = 1 
					verticalRandom = 1
				if(disableUp == true && disableDown == true):
					verticalRandom = 1
				if(disableUp == true):
					randUpDown = 2
				if(disableDown == true):
					randUpDown = 1
				if (disableLong == true):
					horizontalRandom = 1

				roomSizeHorizontal = roomSizeHorizontal * horizontalRandom
				roomSizeVertical = roomSizeVertical* verticalRandom
				
				print(str(disableUp) +  " disableup " + str(disableDown) + " disableDown " + str(disableLong) + " disablelong ")
				
				if(horizontalRandom == 2 && verticalRandom == 2):
					#move block up 
					if(randUpDown==1):
						leftmostCorner=door.position+map_to_world(Vector2(1,0)-Vector2(0, roomSizeVertical-roomSizeVertical/4 - 1))
					else:
						leftmostCorner=door.position+map_to_world(Vector2(1,0)-Vector2(0, roomSizeVertical/4 - evenOddModifier))
				elif(horizontalRandom == 1 &&  verticalRandom == 2):
					if(randUpDown==1):
						leftmostCorner=door.position+map_to_world(Vector2(1,0)-Vector2(0, roomSizeVertical-roomSizeVertical/4 - 1))
					else:
						leftmostCorner=door.position+map_to_world(Vector2(1,0)-Vector2(0, roomSizeVertical/4 - evenOddModifier))
						
				elif(horizontalRandom == 2 &&  verticalRandom == 1):
					leftmostCorner=door.position+map_to_world(Vector2(1,0)-Vector2(0, roomSizeVertical/2 - evenOddModifier))
						
				else:
					leftmostCorner=door.position+map_to_world(Vector2(1,0)-Vector2(0, minRoomSize/2 - evenOddModifier))
				#set room size and door leftmost corner in door connecting to room to be used for further room creation
				door.doorRoomLeftMostCorner = leftmostCorner
				door.doorLocationDirection = "RIGHT"
				door.roomSizeMultiplier = Vector2(horizontalRandom, verticalRandom)
				door.roomSize = Vector2(roomSizeHorizontal, roomSizeVertical)
			"UP":
				#see if there are any cross section and diasble this option to keep tiles from intersecting
				leftmostCorner=world_to_map(door.position-map_to_world(Vector2(minRoomSize/2  - evenOddModifier, minRoomSize)))
				print("UP LEftMost Corner " + str(leftmostCorner))	
				#check left top corner of minimum size minus 1 y tile 
				if(get_cellv(leftmostCorner-Vector2(1,0)) == objectTyped.WALL):
					disableLeft = true
				print("UP Left Modifier : " + str(leftmostCorner-Vector2(1,0)) + " " + str(get_cellv(leftmostCorner-Vector2(1,0))))
				#check left bottom corner of minimum size plus 1 y tile 
				if(get_cellv(leftmostCorner+Vector2(minRoomSize,0)) == objectTyped.WALL):
					disableRight = true
				print("UP Right modifier : " + str(leftmostCorner+Vector2(minRoomSize,0)) + " " + str(get_cellv(leftmostCorner+Vector2(minRoomSize,0))))
				#randomize and create different room sizes and layout types 
				if(get_cellv(leftmostCorner-Vector2(0,1)) == objectTyped.WALL):
					disableLong = true
				print("UP LONG modifier : " + str(leftmostCorner-Vector2(0,1))+ " " + str(get_cellv(leftmostCorner-Vector2(0,1))))
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == objectTyped.WALL):
					disableBig = true
				print("Corner Location: " + str(leftmostCorner+Vector2(minRoomSize, minRoomSize)) + " UP disableBig " + str(disableBig))
				
				var horizontalRandom = randi()%2+1
				var verticalRandom = randi()%2+1
				var randLeftRight = randi()%2+1
				
				if(disableBig == true && horizontalRandom == 2 && horizontalRandom == 2):
					if(randi()%2+1 == 1):
						verticalRandom = 1 
						horizontalRandom = 2
					else:
						verticalRandom = 2
						horizontalRandom = 1
						
				if(disableLeft == true && disableRight == true && disableLong == true):
					horizontalRandom = 1 
					verticalRandom = 1
				if(disableLeft == true && disableRight == true):
					horizontalRandom = 1
				if(disableLeft == true):
					randLeftRight = 2
				if(disableRight == true):
					randLeftRight = 1
				if (disableLong == true):
					verticalRandom = 1

				roomSizeHorizontal = roomSizeHorizontal * horizontalRandom
				roomSizeVertical = roomSizeVertical* verticalRandom

				print(str(disableRight) +  " disableRight " + str(disableLeft) + " disableLeft " + str(disableLong) + " disablelong ")
				
				if(horizontalRandom == 2 && verticalRandom == 2):
					#move block up 
					if(randLeftRight==1):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal-roomSizeHorizontal/4 - 1, roomSizeVertical))
					else:
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal/4 - evenOddModifier, roomSizeVertical))
						
				elif(horizontalRandom == 1 &&  verticalRandom == 2):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal/2 - evenOddModifier, roomSizeVertical))		
				elif(horizontalRandom == 2 &&  verticalRandom == 1):
					if(randLeftRight==1):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal-roomSizeHorizontal/4 - 1, roomSizeVertical))
					else:
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal/4 - evenOddModifier, roomSizeVertical))
				else:
					leftmostCorner=door.position-map_to_world(Vector2(minRoomSize/2  - evenOddModifier, minRoomSize))
				#print("LEFT LEftMost Corner "+ str(world_to_map(leftmostCorner)))
				#set room size and door leftmost corner in door connecting to room to be used for further room creation
				door.doorRoomLeftMostCorner = leftmostCorner
				door.doorLocationDirection = "UP"
				door.roomSizeMultiplier = Vector2(horizontalRandom, verticalRandom)
				door.roomSize = Vector2(roomSizeHorizontal, roomSizeVertical)
			"DOWN":
				#see if there are any cross section and diasble this option to keep tiles from intersecting
				leftmostCorner=world_to_map(door.position-map_to_world(Vector2(minRoomSize/2 - evenOddModifier, -1)))

				#check left top corner of minimum size minus 1 y tile 
				if(get_cellv(leftmostCorner-Vector2(1,0)) == objectTyped.WALL):
					disableLeft = true
				print("DOWN Left Modifier : " + str(leftmostCorner-Vector2(1,0)) + " " + str(get_cellv(leftmostCorner-Vector2(1,0))))
				#check left bottom corner of minimum size plus 1 y tile 
				if(get_cellv(leftmostCorner+Vector2(minRoomSize,0)) == objectTyped.WALL):
					disableRight = true
				print("DOWN Right modifier : " + str(leftmostCorner+Vector2(minRoomSize,0)) + " " + str(get_cellv(leftmostCorner+Vector2(minRoomSize,0))))
				#randomize and create different room sizes and layout types 
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize-1)) == objectTyped.WALL || get_cellv(leftmostCorner+Vector2(minRoomSize-1, minRoomSize-1)) == objectTyped.WALL):
					disableLong = true
				print("DOWN LONG modifier : "  + str(leftmostCorner+Vector2(0,minRoomSize))+ " " + str(get_cellv(leftmostCorner+Vector2(0,minRoomSize))))
				if(get_cellv(leftmostCorner+Vector2(minRoomSize, minRoomSize)) == objectTyped.WALL):
					disableBig = true
				print("Corner Location: " + str(leftmostCorner+Vector2(minRoomSize, minRoomSize)) + " DOWN disableBig " + str(disableBig))
				
				var horizontalRandom = randi()%2+1
				var verticalRandom = randi()%2+1
				var randLeftRight = randi()%2+1
				
				if(disableBig == true && horizontalRandom == 2 && horizontalRandom == 2):
					if(randi()%2+1 == 1):
						verticalRandom = 1 
						horizontalRandom = 2
					else:
						verticalRandom = 2
						horizontalRandom = 1
				
				if(disableLeft == true && disableRight == true && disableDown == true):
					horizontalRandom = 1 
					verticalRandom = 1
				if(disableLeft == true && disableRight == true):
					horizontalRandom = 1
				if(disableLeft == true):
					randLeftRight = 2
				if(disableRight == true):
					randLeftRight = 1
				if (disableLong == true):
					verticalRandom = 1
					
				
					
					 
				roomSizeHorizontal = roomSizeHorizontal * horizontalRandom
				roomSizeVertical = roomSizeVertical* verticalRandom

				print(str(disableRight) +  " disableRight " + str(disableLeft) + " disableLeft " + str(disableLong) + " disablelong ")
				print("hor "+str(horizontalRandom) + " vert " + str(verticalRandom) + " randleftright " + str(randLeftRight))
				if(horizontalRandom == 2 && verticalRandom == 2):
					#move block up 
					if(randLeftRight==1):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal-roomSizeHorizontal/4 -1, -1))
					else:
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal/4 - evenOddModifier, -1))
				elif(horizontalRandom == 1 &&  verticalRandom == 2):
					leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal/2 - evenOddModifier, -1))
				elif(horizontalRandom == 2 &&  verticalRandom == 1):
					if(randLeftRight==1):
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal-roomSizeHorizontal/4 - 1, -1))
					else:
						leftmostCorner=door.position-map_to_world(Vector2(roomSizeHorizontal/4  - evenOddModifier, -1))
				else:
					leftmostCorner=(door.position-map_to_world(Vector2(int(minRoomSize/2)-evenOddModifier, -1)))
					print("in last else wehe nicht...")
				print("DOWN LEftMost Corner " + str(world_to_map(leftmostCorner)))	
				print(str(world_to_map((door.position-map_to_world(Vector2(int(minRoomSize/2)-evenOddModifier, -1))))))
				print("Door location " + str(world_to_map(door.position)) + " modificator " + str(Vector2(int(minRoomSize/2)-evenOddModifier, -1)))
				#set room size and door leftmost corner in door connecting to room to be used for further room creation
				door.doorRoomLeftMostCorner = leftmostCorner
				door.doorLocationDirection = "DOWN"
				door.roomSizeMultiplier = Vector2(horizontalRandom, verticalRandom)
				door.roomSize = Vector2(roomSizeHorizontal, roomSizeVertical)

	var verticalAddcount = 0
	while verticalAddcount < roomSizeVertical:
		var horizontalAddcount = 0
		while horizontalAddcount < roomSizeHorizontal:
			var spawn_pos = leftmostCorner + Vector2(horizontalAddcount*32,verticalAddcount*32)
			var newWallPiece = Wall.instance()
			add_child(newWallPiece)
			newWallPiece.position = spawn_pos
			set_cellv(world_to_map(newWallPiece.position), get_tileset().find_tile_by_name(match_Enum(newWallPiece.type)))
			#print("VerticalAddAcc " + str(verticalAddcount) + " horaddacc " + str(horizontalAddcount))
			if(verticalAddcount==0 || verticalAddcount==roomSizeVertical-1 || horizontalAddcount==roomSizeHorizontal-1):
				horizontalAddcount+=1
			else:
				horizontalAddcount=roomSizeHorizontal-1
		verticalAddcount+=1
		
	if(startingRoom == false):
		var object_pawn = null
		match door.doorDirection:
			"LEFT":
				set_cellv(world_to_map(door.position) - Vector2(1,0), get_tileset().find_tile_by_name(match_Enum(objectTyped.EMPTY)))
				object_pawn = get_cell_pawn(world_to_map(door.position) - Vector2(1,0))
			"RIGHT":
				set_cellv(world_to_map(door.position) + Vector2(1,0), get_tileset().find_tile_by_name(match_Enum(objectTyped.EMPTY)))
				object_pawn = get_cell_pawn(world_to_map(door.position) + Vector2(1,0))
			"UP":
				set_cellv(world_to_map(door.position) - Vector2(0,1), get_tileset().find_tile_by_name(match_Enum(objectTyped.EMPTY)))
				object_pawn = get_cell_pawn(world_to_map(door.position) - Vector2(0,1))
			"DOWN":
				set_cellv(world_to_map(door.position) + Vector2(0,1), get_tileset().find_tile_by_name(match_Enum(objectTyped.EMPTY)))
				object_pawn = get_cell_pawn(world_to_map(door.position) + Vector2(0,1))
		if(object_pawn != null):
			object_pawn.queue_free()
		
	if(createDoors == true):
		create_doors(leftmostCorner, startingRoom, roomSizeHorizontal, roomSizeVertical)


func create_doors(roomLeftMostCorner, startingRoom=false, roomSizeHorizontal = 13, roomSizeVertical = 13, roomsizeMultiplyer = Vector2(1,1), doorLocationDirection = "LEFT"):
	randomize()
	roomSizeHorizontal = roomSizeHorizontal-1
	roomSizeVertical = roomSizeVertical-1
	var doorLocationDirectionsArray = ["LEFT", "RIGHT", "UP", "DOWN"]
	var doorLocationArray = []
	var doorArray = []
	var doorCount = 1
	var canCreateDoor = true
	var doorEvenOddModifier = 0
			
	if(evenOddModifier == 0):
		doorEvenOddModifier = 1
	#todo: include remaning doors numbers
	if(!startingRoom):
		remove_opposite_doorlocation(doorLocationDirectionsArray, doorLocationDirection)
		doorCount = 3

	while doorCount > 0: 
		var doorLocation = randi()%doorLocationDirectionsArray.size()-1
		#var doorLocation = 3
		doorLocationArray.append(doorLocationDirectionsArray[doorLocation])
		doorLocationDirectionsArray.erase(doorLocationDirectionsArray[doorLocation])
		doorCount-=1
	for element in doorLocationArray:
		var locationToSpawnModifier = Vector2.ZERO
		var newDoor = Door.instance()
		var alternateSpawnLocation = false
		if(randi()%2+1 == 1):
			alternateSpawnLocation = true
		match element:
			"LEFT":
				match roomsizeMultiplyer:
					Vector2(1,1):
						locationToSpawnModifier = Vector2(0, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
					Vector2(2,1):
						locationToSpawnModifier = Vector2(0, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
					Vector2(1,2):
						locationToSpawnModifier = Vector2(0, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(0, int(3*roomSizeVertical/(2*roomsizeMultiplyer.y)+doorEvenOddModifier))
					Vector2(2,2):
						locationToSpawnModifier = Vector2(0, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(0, int(3*roomSizeVertical/(2*roomsizeMultiplyer.y)+doorEvenOddModifier))
				newDoor.doorDirection = "LEFT"
			"RIGHT":
				match roomsizeMultiplyer:
					Vector2(1,1):
						locationToSpawnModifier = Vector2(roomSizeHorizontal, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
					Vector2(2,1):
						locationToSpawnModifier = Vector2(roomSizeHorizontal, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
					Vector2(1,2):
						locationToSpawnModifier = Vector2(roomSizeHorizontal, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(roomSizeHorizontal, int(3*roomSizeVertical/(2*roomsizeMultiplyer.y)+doorEvenOddModifier))
					Vector2(2,2):
						locationToSpawnModifier = Vector2(roomSizeHorizontal, int(roomSizeVertical/(2*roomsizeMultiplyer.y)))
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(roomSizeHorizontal, int(3*roomSizeVertical/(2*roomsizeMultiplyer.y)+doorEvenOddModifier))
				newDoor.doorDirection = "RIGHT"
			"UP":
				match roomsizeMultiplyer:
					Vector2(1,1):
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), 0)
					Vector2(2,1):
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), 0)
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(int(3*roomSizeHorizontal/(2*roomsizeMultiplyer.x))+doorEvenOddModifier, 0)
					Vector2(1,2):
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), 0)
					Vector2(2,2):
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(int(3*roomSizeHorizontal/(2*roomsizeMultiplyer.x))+doorEvenOddModifier, 0)
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), 0)
				newDoor.doorDirection = "UP"
			"DOWN":
				match roomsizeMultiplyer:
					Vector2(1,1):
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), roomSizeVertical)
					Vector2(2,1):
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), roomSizeVertical)
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(int(3*roomSizeHorizontal/(2*roomsizeMultiplyer.x)+doorEvenOddModifier), roomSizeVertical)
					Vector2(1,2):
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), roomSizeVertical)
					Vector2(2,2):
						locationToSpawnModifier = Vector2(int(roomSizeHorizontal/(2*roomsizeMultiplyer.x)), roomSizeVertical)
						if(alternateSpawnLocation):
							locationToSpawnModifier = Vector2(int(3*roomSizeHorizontal/(2*roomsizeMultiplyer.x)+doorEvenOddModifier), roomSizeVertical)
				newDoor.doorDirection = "DOWN"
		
				
		#print("LocationDir " + str(element) + " LocationSpawnModifier " + str(locationToSpawnModifier))
		newDoor.position = roomLeftMostCorner + map_to_world(locationToSpawnModifier)
		#print("NewDoor leftmost Position " + str(world_to_map(roomLeftMostCorner)))
		#print("Newdoor position" + str(world_to_map(newDoor.position))+ " roomsizemult " + str(roomsizeMultiplyer))
		
		match element:
			"LEFT":
				if (get_cellv(world_to_map(newDoor.position)-Vector2(1,0)) == objectTyped.WALL):
					canCreateDoor = false
			"RIGHT":
				if (get_cellv(world_to_map(newDoor.position)+Vector2(1,0)) == objectTyped.WALL):
					canCreateDoor = false
			"UP":
				if (get_cellv(world_to_map(newDoor.position)-Vector2(0,1)) == objectTyped.WALL):
					canCreateDoor = false
			"DOWN":
				if (get_cellv(world_to_map(newDoor.position)+Vector2(0,1)) == objectTyped.WALL):
					canCreateDoor = false

		if(canCreateDoor == true):
			add_child(newDoor)
			#delete the wall piece before creating the door
			var object_pawn = get_cell_pawn(world_to_map(newDoor.position))
			object_pawn.queue_free()
			set_cellv(world_to_map(newDoor.position), get_tileset().find_tile_by_name(match_Enum(newDoor.type)))
			doorArray.append(newDoor)
			
		else:
			print(str(element) + " cant create door because path is blocked ")
		canCreateDoor = true
		
	for door in doorArray:
		create_walls(door, false, false)
		#print(str(newDoor.position) + " element "+ str(element))

func remove_opposite_doorlocation(doorLocationDirectionsArray, direction):
	match direction:
		"LEFT":
			doorLocationDirectionsArray.erase("RIGHT")
		"RIGHT":
			doorLocationDirectionsArray.erase("LEFT")
		"UP":
			doorLocationDirectionsArray.erase("DOWN")
		"DOWN":
			doorLocationDirectionsArray.erase("UP")
		_:
			pass
	return doorLocationDirectionsArray
