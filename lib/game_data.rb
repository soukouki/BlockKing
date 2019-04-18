
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
	
	INFERIOR_MAGIC_CRYSTAL = Item.new("劣化魔法結晶")
	FIRE_CRYSTAL = Item.new("火の結晶")
	FIRE_BRICK = Item.new("火のレンガ")
	FIRE_SWORD = Item.new("火の剣")
	WOOD_CRYSTAL = Item.new("木の結晶")
	WOOD_SWORD = Item.new("木の剣")
	# 新しい英語訳が見つからないので、とりあえずはこのままで
	INFERIOR_LIGHT_CRYSTAL = Item.new("明の結晶")
	INFERIOR_LIGHT_SWORD = Item.new("明の剣")
	INFERIOR_DARK_CRYSTAL = Item.new("暗の結晶")
	INFERIOR_DARK_SWORD = Item.new("暗の剣")
	LIGHT_CRYSTAL = Item.new("光の結晶")
	DARK_CRYSTAL = Item.new("闇の結晶")
	
	BLAZE_CRYSTAL = Item.new("炎の結晶")
	BLAZE_BRICK = Item.new("炎のレンガ")
	BLAZE_SWORD = Item.new("炎の剣")
	
	
	# 攻撃力順に並べる！
	SWORD_ATTACK_POWER_HASH = {
		COPPER_SWORD => 1.5,
		IRON_SWORD => 2.5,
		HIGH_IRON_SWORD => 5,
		FIRE_SWORD => 12,
		WOOD_SWORD => 60,
		INFERIOR_LIGHT_SWORD => 300,
		INFERIOR_DARK_SWORD => 500,
	}
	
	SORT_ORDER = [
		WOOD, LIME, CLAY, COAL,
		GOLD_ORE, SILVER_ORE, COPPER_ORE, IRON_ORE,
		GOLD, SILVER, COPPER, IRON,
		BRICK, FIRE_BRICK, BLAZE_BRICK,
		INFERIOR_MAGIC_CRYSTAL, FIRE_CRYSTAL, WOOD_CRYSTAL, INFERIOR_LIGHT_CRYSTAL, INFERIOR_DARK_CRYSTAL,
		DARK_CRYSTAL, LIGHT_CRYSTAL,
		*SWORD_ATTACK_POWER_HASH.keys,
	]
	
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
		def name; "石灰鉱山" end
		def map_name; "石灰" end
		def get_items_when_turning; LIME end
	end
	class COAL_MINE < Nature
		def name; "石炭鉱山" end
		def map_name; "石炭" end
		def get_items_when_turning; COAL end
	end
	class FIRE_CRYSTAL_MINE < Nature
		def name; "火晶" end
		def get_items_when_turning; FIRE_CRYSTAL end
	end
	class LOW_LEVEL_FURNACE < Building
		def name; "下位の炉" end
		def map_name; "下炉" end
	end
	class MEDIUM_LEVEL_FURNACE < Building
		def name; "中位の炉" end
		def map_name; "中炉" end
	end
	class LARGE_FURNACE < Building
		def name; "大型の炉" end
		def map_name; "大炉" end
	end
	class FIRE_FURNACE < Building
		def name; "火の炉" end
		def map_name; "火炉" end
	end
	class INFERIOR_MAGIC_WORKBENCH < Building
		def name; "劣・魔法作業台" end
		def map_name; "劣魔" end
	end
	class WOOD_REFINERY < Building
		def name; "木の精錬台" end
		def map_name; "木錬" end
	end
	class METAL_REFINERY < Building
		def name; "金属の精錬台" end
		def map_name; "金錬" end
	end
	class ANCIENT_REFINERY < Building
		def name; "古の精錬台" end
		def map_name; "古錬" end
	end
	class NORMAK_MAGIC_WORKBENCH < Building
		def name; "魔法作業台" end
		def map_name; "普魔" end
	end
	
	CREATION_ITEMS_HASH = {
		LOW_LEVEL_FURNACE => {
			{COPPER_ORE => 10, WOOD => 30} => {COPPER_SWORD => 5},
			{CLAY => 20, WOOD => 40} => {BRICK => 20},
			{GOLD_ORE => 30, WOOD => 60} => {GOLD => 10},
		},
		MEDIUM_LEVEL_FURNACE => {
			{IRON_ORE => 15, WOOD => 40} => {IRON_SWORD => 5},
			{IRON_ORE => 30, WOOD => 100} => {HIGH_IRON_SWORD => 5},
			{FIRE_CRYSTAL => 20, BRICK => 40} => {FIRE_BRICK => 20},
			{SILVER_ORE => 30, WOOD => 120} => {SILVER => 10},
		},
		FIRE_FURNACE => {
			{FIRE_CRYSTAL => 20, IRON_ORE => 50} => {FIRE_SWORD => 5},
			{FIRE_CRYSTAL => 200} => {INFERIOR_MAGIC_CRYSTAL => 10},
			{FIRE_CRYSTAL => 4000} => {INFERIOR_MAGIC_CRYSTAL => 200},
			{FIRE_CRYSTAL => 600, CLAY => 800} => {FIRE_BRICK => 400},
		},
		INFERIOR_MAGIC_WORKBENCH => {
			{INFERIOR_MAGIC_CRYSTAL => 50, WOOD_CRYSTAL => 600} => {WOOD_SWORD => 10},
			{INFERIOR_MAGIC_CRYSTAL => 100, INFERIOR_LIGHT_CRYSTAL => 40} => {INFERIOR_LIGHT_SWORD => 10},
			{INFERIOR_MAGIC_CRYSTAL => 400, INFERIOR_DARK_CRYSTAL => 80} => {INFERIOR_DARK_SWORD => 20},
		},
		WOOD_REFINERY => {
			{WOOD => 20000} => {WOOD_CRYSTAL => 800},
			{WOOD_CRYSTAL => 800} => {INFERIOR_MAGIC_CRYSTAL => 200},
		},
		LARGE_FURNACE => {
			{GOLD_ORE => 1200, COAL => 600} => {GOLD => 400}, # 1 : 1/2 : 3/1
			{SILVER_ORE => 3600, COAL => 2800} => {SILVER => 1200}, # 1 : 4/5 : 3/1
			{COPPER_ORE => 6000, COAL => 6000} => {COPPER => 2000}, # 1 :  1  : 3/1
			{IRON_ORE => 9000, COAL => 9000, LIME => 4500} => {IRON => 3000}, # 1 : 1 : 2/1 : 3/1
		},
		METAL_REFINERY => {
			{INFERIOR_MAGIC_CRYSTAL => 200, GOLD => 400, SILVER => 1200, COPPER => 2000, IRON => 3000, FIRE_CRYSTAL => 2000} => {INFERIOR_LIGHT_CRYSTAL => 20},
		},
		ANCIENT_REFINERY => {
			{INFERIOR_MAGIC_CRYSTAL => 1000, COAL => 100000, LIME => 100000} => {INFERIOR_DARK_CRYSTAL => 40},
		},
	}
	CAN_BUILD_LIST = {
		LOW_LEVEL_FURNACE => {WOOD => 40},
		MEDIUM_LEVEL_FURNACE => {BRICK => 40, WOOD => 10},
		FIRE_FURNACE => {FIRE_BRICK => 60, BRICK => 40, WOOD => 20},
		INFERIOR_MAGIC_WORKBENCH => {INFERIOR_MAGIC_CRYSTAL => 30, GOLD => 5, SILVER => 20},
		WOOD_REFINERY => {INFERIOR_MAGIC_CRYSTAL => 100, GOLD => 5, SILVER => 20},
		LARGE_FURNACE => {FIRE_BRICK => 1000, WOOD => 2000},
		METAL_REFINERY => {INFERIOR_MAGIC_CRYSTAL => 200, IRON => 100},
		ANCIENT_REFINERY => {INFERIOR_MAGIC_CRYSTAL => 500, FIRE_CRYSTAL => 5000, FIRE_BRICK => 2000},
	}
	
end
