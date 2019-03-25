
module GameData
	
	GOLD_ORE = Item.new("金鉱石")
	GOLD = Item.new("金")
	SILVER_ORE = Item.new("銀鉱石")
	SILVER = Item.new("銀")
	COPPER_ORE = Item.new("銅鉱石")
	COPPER = Item.new("銅")
	COPPER_SWORD = Item.new("銅の剣")
	IRON_ORE = Item.new("鉄鉱石")
	IRON = Item.new("鉄")
	IRON_SWORD = Item.new("鉄の剣")
	WOOD = Item.new("木材")
	LIME = Item.new("石灰")
	COAL = Item.new("石炭")
	CLAY = Item.new("粘土")
	BRICK = Item.new("レンガ")
	HIGH_IRON_SWORD = Item.new("上・鉄の剣")
	
	INFERIOR_MAGIC_CRYSTAL = Item.new("劣化マジッククリスタル")
	FIRE_CRYSTAL = Item.new("火の結晶")
	FIRE_BRICK = Item.new("火のレンガ")
	FIRE_SWORD = Item.new("火の剣")
	WOOD_CRYSTAL = Item.new("木の結晶")
	BLAZE_CRYSTAL = Item.new("炎の結晶")
	BLAZE_BRICK = Item.new("炎のレンガ")
	BLAZE_SWORD = Item.new("炎の剣")
	
	class EMPTY < Nature
		def name; "更地" end
		def map_name; "    " end
		def empty?
			true
		end
	end
	class CASTLE < Nature
		def name; "王城" end
	end
	class GOLD_MINE < Nature
		def name; "金鉱" end
		def get_items_when_turning; GOLD_ORE end
	end
	class SILVER_MINE < Nature
		def name; "銀鉱" end
		def get_items_when_turning; SILVER_ORE end
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
		def name; "沼" end
		def map_name; " 沼 " end
		def get_items_when_turning; CLAY end
	end
	class LIME_MINE < Nature
		def name; "石灰" end
		def get_items_when_turning; LIME end
	end
	class COAL_MINE < Nature
		def name; "石炭" end
		def get_items_when_turning; COAL end
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
		def name; "火の炉" end
		def map_name; "火炉" end
	end
	class INFERIOR_MAGIC_WORKBENCH < Building
		def name; "劣・魔法作業台" end
		def map_name; "劣魔" end
	end
	class WOOD_SMELTER < Building
		def name; "木の精錬台" end
		def map_name; "木錬" end
	end
	
	
	SWORD_ATTACK_POWER_HASH = {
		COPPER_SWORD => 1.5,
		IRON_SWORD => 2.5,
		HIGH_IRON_SWORD => 5,
		FIRE_SWORD => 12,
		BLAZE_SWORD => 30,
	}
	CREATION_ITEMS_HASH = {
		LOW_LEVEL_FURNACE => {
			{COPPER_ORE => 10, WOOD => 30} => {COPPER_SWORD => 5},
			{CLAY => 20, WOOD => 40} => {BRICK => 20},
		},
		MEDIUM_LEVEL_FURNACE => {
			{IRON_ORE => 15, WOOD => 40} => {IRON_SWORD => 5},
			{IRON_ORE => 30, WOOD => 100} => {HIGH_IRON_SWORD => 5},
			{FIRE_CRYSTAL => 20, BRICK => 40} => {FIRE_BRICK => 20},
		},
		FIRE_FURNACE => {
			{FIRE_CRYSTAL => 20, IRON_ORE => 50} => {FIRE_SWORD => 5},
			{FIRE_CRYSTAL => 200} => {INFERIOR_MAGIC_CRYSTAL => 10},
		},
		INFERIOR_MAGIC_WORKBENCH => {
			{INFERIOR_MAGIC_CRYSTAL => 10, FIRE_CRYSTAL => 10, WOOD_CRYSTAL => 20} => {BLAZE_CRYSTAL => 10},
			{INFERIOR_MAGIC_CRYSTAL => 10, BLAZE_CRYSTAL => 20, IRON_ORE => 10} => {BLAZE_SWORD => 5},
		},
		WOOD_SMELTER => {
			{WOOD => 500} => {WOOD_CRYSTAL => 10},
		},
	}
	CAN_BUILD_LIST = {
		LOW_LEVEL_FURNACE => {WOOD => 40},
		MEDIUM_LEVEL_FURNACE => {BRICK => 40, WOOD => 10},
		FIRE_FURNACE => {FIRE_BRICK => 60, BRICK => 40, WOOD => 20},
		INFERIOR_MAGIC_WORKBENCH => {INFERIOR_MAGIC_CRYSTAL => 30, GOLD => 5, SILVER => 20},
		WOOD_SMELTER => {INFERIOR_MAGIC_CRYSTAL => 30, GOLD => 5, SILVER => 20}
	}
	
end
