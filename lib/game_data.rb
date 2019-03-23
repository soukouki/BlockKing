
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
	HIGH_IRON_SWORD = Item.new("上・鉄の剣")
	FIRE_CRYSTAL = Item.new("火の結晶")
	FIRE_BRICK = Item.new("炎のレンガ")
	FIRE_SWORD = Item.new("炎の剣")
	
	class EMPTY < Nature
		def name; "    " end
		def empty?
			true
		end
	end
	class CASTLE < Nature
		def name; "王城" end
	end
	class COPPER_MINE < Nature
		def name; "銅鉱" end
		def get_items_when_turning; COPPER_ORE end
	end
	class IRON_MINE < Nature
		def name; "鉄鉱" end
		def get_items_when_turning; IRON_ORE end
	end
	class FOREST < Nature
		def name; "森林" end
		def get_items_when_turning; WOOD end
	end
	class MARSH < Nature
		def name; " 沼 " end
		def get_items_when_turning; CLAY end
	end
	class FIRE_CRYSTAL_MINE < Nature
		def name; "火晶" end
		def get_items_when_turning; FIRE_CRYSTAL end
	end
	class LOW_LEVEL_FURNACE < Building
		def name; "下炉" end
	end
	class MEDIUM_LEVEL_FURNACE < Building
		def name; "中炉" end
	end
	class FIRE_FURNACE < Building
		def name; "炎炉" end
	end
	
	SWORD_ATTACK_POWER_HASH = {
		COPPER_SWORD => 1.5,
		IRON_SWORD => 2.5,
		HIGH_IRON_SWORD => 5,
		FIRE_SWORD => 12,
	}
	CREATION_ITEMS_HASH = {
		"下炉" => {
			{COPPER_ORE => 10, WOOD => 20} => {COPPER_SWORD => 5},
			{CLAY => 20, WOOD => 30} => {BRICK => 20},
		},
		"中炉" => {
			{IRON_ORE => 15, WOOD => 30} => {IRON_SWORD => 5},
			{IRON_ORE => 30, WOOD => 80} => {HIGH_IRON_SWORD => 5},
			{FIRE_CRYSTAL => 20, BRICK => 40} => {FIRE_BRICK => 20},
		},
		"炎炉" => {
			{FIRE_CRYSTAL => 20, IRON_ORE => 50} => {FIRE_SWORD => 5},
		}
	}
	CAN_BUILD_LIST = {
		LOW_LEVEL_FURNACE => {WOOD => 40},
		MEDIUM_LEVEL_FURNACE => {BRICK => 40, WOOD => 10},
		FIRE_FURNACE => {FIRE_BRICK => 60, BRICK => 40, WOOD => 20},
	}
	
end
