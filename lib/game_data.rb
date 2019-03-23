
module GameData
	
	COPPER_ORE = Item.new("銅鉱石")
	COPPER = Item.new("銅")
	COPPER_SWORD = Item.new("銅の剣")
	IRON_ORE = Item.new("鉄鉱石")
	IRON = Item.new("鉄")
	IRON_SWORD = Item.new("鉄の剣")
	WOOD = Item.new("木材")
	CLAY = Item.new("粘土")
	BRICK = Item.new("レンガ")
	
	EMPTY = Block.new("    ")
	CASTLE = Block.new("王城")
	COPPER_MINE = Block.new("銅鉱")
	IRON_MINE = Block.new("鉄鉱")
	FOREST = Block.new("森林")
	MARSH = Block.new(" 沼 ")
	LOW_LEVEL_FURNACE = Block.new("下炉")
	MEDIUM_LEVEL_FURNACE = Block.new("中炉")
	
	SWORD_ATTACK_POWER_HASH = {
		COPPER_SWORD => 2,
		IRON_SWORD => 4,
	}
	
	GET_TURN_ITEMS_HASH = {
		"銅鉱" => {COPPER_ORE => 20},
		"鉄鉱" => {IRON_ORE => 20},
		"森林" => {WOOD => 20},
		" 沼 " => {CLAY => 20},
	}
	CREATION_ITEMS_HASH = {
		"下炉" => {
			{COPPER_ORE => 10, WOOD => 20} => {COPPER_SWORD => 5},
			{CLAY => 20, WOOD => 20} => {BRICK => 20},
		},
		"中炉" => {
			{IRON_ORE => 10, WOOD => 30} => {IRON_SWORD => 5},
		},
	}
	
	CAN_BUILD_LIST = {
		LOW_LEVEL_FURNACE => {WOOD => 40},
		MEDIUM_LEVEL_FURNACE => {BRICK => 40, WOOD => 10},
	}
	
end
