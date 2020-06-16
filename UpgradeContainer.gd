extends Node2D

var wandTexture = preload ("res://GameObjects/Item/WandItem.png")
var swordTexture = preload ("res://GameObjects/Item/Sword_Color.png")
var heartContainerTexture = preload ("res://GameObjects/Item/Heart_Item.png")
var flaskContainerTexture = preload ("res://GameObjects/Item/Flask_Item.png")
var powerBlockTexture = preload ("res://GameObjects/Item/Bomb.png")
var actionUpTexture = preload ("res://GameObjects/Item/TurnUp.png")
var fillUpFlaskTexture = preload("res://GameObjects/Item/FillUpFlask.png")
var fillUpHeartTexture = preload("res://GameObjects/Item/FillUpHealth.png")
#var fillHealthTexture = preload()

onready var upgradeCost = $Sprite/UpgradeCost
onready var upgradeItem = $Sprite/UpgradeItem

var upradePrice = 1
var upgradeType = GlobalVariables.UPGRADETYPE.SWORD

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func set_upgrade_container(containerType):
	match containerType:
		GlobalVariables.UPGRADETYPE.ACTIONSUP:
			get_node("Sprite/UpgradeItem").set_texture(actionUpTexture)
			upgradeType = GlobalVariables.UPGRADETYPE.ACTIONSUP
		GlobalVariables.UPGRADETYPE.FILLFLASK:
			get_node("Sprite/UpgradeItem").set_texture(fillUpFlaskTexture)
			upgradeType = GlobalVariables.UPGRADETYPE.FILLFLASK
		GlobalVariables.UPGRADETYPE.FILLHEART:
			get_node("Sprite/UpgradeItem").set_texture(fillUpHeartTexture)
			upgradeType = GlobalVariables.UPGRADETYPE.FILLHEART
		GlobalVariables.UPGRADETYPE.BOMB:
			get_node("Sprite/UpgradeItem").set_texture(powerBlockTexture)
			upgradeType = GlobalVariables.UPGRADETYPE.BOMB
		GlobalVariables.UPGRADETYPE.FLASK:
			get_node("Sprite/UpgradeItem").set_texture(flaskContainerTexture)
			upgradeType = GlobalVariables.UPGRADETYPE.FLASK
		GlobalVariables.UPGRADETYPE.HEART:
			get_node("Sprite/UpgradeItem").set_texture(heartContainerTexture)
			upgradeType = GlobalVariables.UPGRADETYPE.HEART
		GlobalVariables.UPGRADETYPE.MAGIC:
			get_node("Sprite/UpgradeItem").set_texture(wandTexture)
			upgradeType = GlobalVariables.UPGRADETYPE.MAGIC
		GlobalVariables.UPGRADETYPE.SWORD:
			get_node("Sprite/UpgradeItem").set_texture(swordTexture)
			upgradeType = GlobalVariables.UPGRADETYPE.SWORD
			
func updatePrice():
	upgradeCost.set_text(str(int(ceil(GlobalVariables.upgradeCosts[upgradeType-1]))))
	
func do_upgrade(player):
	if player.coinCount >= int(upgradeCost.get_text()):
		$AnimationPlayer.play("ActivateUpgrade", -1, 1.5)
		player.on_upgradeContainer_interaction(upgradeType, GlobalVariables.upgradeAmount[upgradeType-1],int(upgradeCost.get_text()))
		match upgradeType:
			GlobalVariables.UPGRADETYPE.ACTIONSUP:
				GlobalVariables.upgradeCosts[upgradeType-1]*=1.5
			GlobalVariables.UPGRADETYPE.FILLFLASK:
				GlobalVariables.upgradeCosts[upgradeType-1]*=1.5
			GlobalVariables.UPGRADETYPE.FILLHEART:
				GlobalVariables.upgradeCosts[upgradeType-1]*=1.5
			GlobalVariables.UPGRADETYPE.BOMB:
				GlobalVariables.upgradeCosts[upgradeType-1]*=1.5
			GlobalVariables.UPGRADETYPE.FLASK:
				GlobalVariables.upgradeCosts[upgradeType-1]*=1.5
			GlobalVariables.UPGRADETYPE.HEART:
				GlobalVariables.upgradeCosts[upgradeType-1]*=1.5
			GlobalVariables.UPGRADETYPE.MAGIC:
				GlobalVariables.upgradeCosts[upgradeType-1]*=1.5
			GlobalVariables.UPGRADETYPE.SWORD:
				GlobalVariables.upgradeCosts[upgradeType-1]*=1.5
		updatePrice()
	else:
		$AnimationPlayer.play("NotEnoughMoney", -1, 1.0)
