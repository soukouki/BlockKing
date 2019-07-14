
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
	DEBUG = Item.new("**このレシピは利用できません**")
	
	INFERIOR_MAGIC_CRYSTAL = Item.new("劣化魔法結晶")
	FIRE_CRYSTAL = Item.new("火の結晶")
	FIRE_BRICK = Item.new("火のレンガ")
	FIRE_SWORD = Item.new("火の剣")
	WOOD_CRYSTAL = Item.new("木の結晶")
	WOOD_SWORD = Item.new("木の剣")
	INFERIOR_LIGHT_CRYSTAL = Item.new("明の結晶") # 新しい英語訳が見つからないので、とりあえずはこのままで
	INFERIOR_LIGHT_SWORD = Item.new("明の剣")
	INFERIOR_DARK_CRYSTAL = Item.new("暗の結晶")
	INFERIOR_DARK_SWORD = Item.new("暗の剣")
	
	MAGIC_CRYSTAL = Item.new("魔法結晶")
	
	BLAZE_CRYSTAL = Item.new("炎の結晶")
	BLAZE_BRICK = Item.new("炎のレンガ")
	BLAZE_SWORD = Item.new("炎の剣")
	TREE_CRYSTAL = Item.new("樹の結晶")
	LIGHT_CRYSTAL = Item.new("光の結晶")
	DARK_CRYSTAL = Item.new("闇の結晶")
	
	
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
		MAGIC_CRYSTAL, BLAZE_CRYSTAL, TREE_CRYSTAL, DARK_CRYSTAL, LIGHT_CRYSTAL,
		*SWORD_ATTACK_POWER_HASH.keys,
	]
	
	
	EMPTY = Nature.new_type("更地") do |c|
		c.defi(:map_name){"    "}
		c.defi(:empty?){true}
	end
	CASTLE = Nature.new_type("王城") do |c|
	end
	GOLD_MINE = Nature.new_type("金鉱") do |c|
		c.defi(:get_items_when_turning){GOLD_ORE}
	end
	SILVER_MINE = Nature.new_type("銀鉱") do |c|
		c.defi(:get_items_when_turning){SILVER_ORE}
	end
	COPPER_MINE = Nature.new_type("銅鉱") do |c|
		c.defi(:get_items_when_turning){COPPER_ORE}
	end
	IRON_MINE = Nature.new_type("鉄鉱") do |c|
		c.defi(:get_items_when_turning){IRON_ORE}
	end
	FOREST = Nature.new_type("森林") do |c|
		c.defi(:get_items_when_turning){WOOD}
	end
	MARSH = Nature.new_type("沼") do |c|
		c.defi(:map_name){" 沼 "}
		c.defi(:get_items_when_turning){CLAY}
	end
	LIME_MINE = Nature.new_type("石灰鉱山") do |c|
		c.defi(:map_name){"石灰"}
		c.defi(:get_items_when_turning){LIME}
	end
	COAL_MINE = Nature.new_type("石炭鉱山") do |c|
		c.defi(:map_name){"石炭"}
		c.defi(:get_items_when_turning){COAL}
	end
	FIRE_CRYSTAL_MINE = Nature.new_type("火晶") do |c|
		c.defi(:get_items_when_turning){FIRE_CRYSTAL}
	end
	
	LOW_LEVEL_FURNACE = Building.new_type("下位の炉") do |c|
		c.defi(:map_name){"下炉"}
	end
	MEDIUM_LEVEL_FURNACE = Building.new_type("中位の炉") do |c|
		c.defi(:map_name){"中炉"}
	end
	LARGE_FURNACE = Building.new_type("大型の炉") do |c|
		c.defi(:map_name){"大炉"}
	end
	FIRE_FURNACE = Building.new_type("火の炉") do |c|
		c.defi(:map_name){"火炉"}
	end
	INFERIOR_MAGIC_WORKBENCH = Building.new_type("劣・魔法作業台") do |c|
		c.defi(:map_name){"劣魔"}
	end
	WOOD_REFINERY = Building.new_type("木の精錬台") do |c|
		c.defi(:map_name){"木錬"}
	end
	METAL_REFINERY = Building.new_type("金属の精錬台") do |c|
		c.defi(:map_name){"金錬"}
	end
	ANCIENT_REFINERY = Building.new_type("古の精錬台") do |c|
		c.defi(:map_name){"古錬"}
	end
	MAGIC_WORKBENCH = Building.new_type("魔法作業台") do |c|
		c.defi(:map_name){"普魔"}
	end
	
	CAN_BUILD_LIST = {
		LOW_LEVEL_FURNACE => {WOOD => 40},
		MEDIUM_LEVEL_FURNACE => {BRICK => 40, WOOD => 10},
		FIRE_FURNACE => {FIRE_BRICK => 60, BRICK => 40, WOOD => 20},
		INFERIOR_MAGIC_WORKBENCH => {INFERIOR_MAGIC_CRYSTAL => 30, GOLD => 5, SILVER => 20},
		WOOD_REFINERY => {INFERIOR_MAGIC_CRYSTAL => 100, GOLD => 5, SILVER => 20},
		LARGE_FURNACE => {FIRE_BRICK => 1000, WOOD => 2000},
		METAL_REFINERY => {INFERIOR_MAGIC_CRYSTAL => 200, IRON => 100},
		ANCIENT_REFINERY => {INFERIOR_MAGIC_CRYSTAL => 500, FIRE_CRYSTAL => 5000, FIRE_BRICK => 2000},
		MAGIC_WORKBENCH => {INFERIOR_MAGIC_CRYSTAL => 2000, MAGIC_CRYSTAL => 50},
	}
	
	RECIPES = [
		
		# 非魔法剣
		# =====
		#  銅の剣
		Recipe.new(LOW_LEVEL_FURNACE, [], {COPPER_ORE => 10, WOOD => 30}, {COPPER_SWORD => 5}, 150),
		#    鉄の剣準備
		Recipe.new(LOW_LEVEL_FURNACE, [], {CLAY => 20, WOOD => 40}, {BRICK => 20}, 50),
		Recipe.new(LOW_LEVEL_FURNACE, [], {GOLD_ORE => 15, WOOD => 30}, {GOLD => 5}, 100),
		#  鉄の剣
		Recipe.new(MEDIUM_LEVEL_FURNACE, [], {IRON_ORE => 15, WOOD => 40}, {IRON_SWORD => 5}, 150),
		Recipe.new(MEDIUM_LEVEL_FURNACE, [], {IRON_ORE => 30, WOOD => 100}, {HIGH_IRON_SWORD => 5}, 200),
		# 低級魔法剣
		# =====
		#    火の剣準備
		Recipe.new(MEDIUM_LEVEL_FURNACE, [], {FIRE_CRYSTAL => 20, BRICK => 40}, {FIRE_BRICK => 20}, 100),
		Recipe.new(MEDIUM_LEVEL_FURNACE, [], {SILVER_ORE => 30, WOOD => 120}, {SILVER => 10}, 150),
		Recipe.new(FIRE_FURNACE, [], {FIRE_CRYSTAL => 30, CLAY => 40}, {FIRE_BRICK => 20}, 40),
		#  火の剣
		Recipe.new(FIRE_FURNACE, [], {FIRE_CRYSTAL => 20, IRON_ORE => 50}, {FIRE_SWORD => 5}, 300),
		#    木の剣準備
		Recipe.new(FIRE_FURNACE, [], {FIRE_CRYSTAL => 200}, {INFERIOR_MAGIC_CRYSTAL => 10}, 200),
		Recipe.new(FIRE_FURNACE, [INFERIOR_MAGIC_WORKBENCH], {FIRE_CRYSTAL => 4000}, {INFERIOR_MAGIC_CRYSTAL => 200}, 2_000),
		Recipe.new(WOOD_REFINERY, [], {WOOD => 2_500}, {WOOD_CRYSTAL => 100}, 100),
		Recipe.new(WOOD_REFINERY, [], {WOOD_CRYSTAL => 40}, {INFERIOR_MAGIC_CRYSTAL => 10}, 200),
		Recipe.new(WOOD_REFINERY, [INFERIOR_MAGIC_WORKBENCH], {WOOD => 50_000}, {WOOD_CRYSTAL => 2_000}, 2_000),
		Recipe.new(WOOD_REFINERY, [INFERIOR_MAGIC_WORKBENCH], {WOOD_CRYSTAL => 800}, {INFERIOR_MAGIC_CRYSTAL => 200}, 2_000),
		#  木の剣
		Recipe.new(INFERIOR_MAGIC_WORKBENCH, [], {INFERIOR_MAGIC_CRYSTAL => 25, WOOD_CRYSTAL => 300}, {WOOD_SWORD => 5}, 500),
		#    明の剣準備
		Recipe.new(LARGE_FURNACE, [], {GOLD_ORE => 1_200, COAL => 600}, {GOLD => 400}, 500), # 1 : 1/2 : 1/3
		Recipe.new(LARGE_FURNACE, [], {SILVER_ORE => 3_600, COAL => 2_800}, {SILVER => 1_200}, 500), # 1 : 4/5 : 1/3
		Recipe.new(LARGE_FURNACE, [], {COPPER_ORE => 6_000, COAL => 6_000}, {COPPER => 2_000}, 500), # 1 : 1 : 1/3
		Recipe.new(LARGE_FURNACE, [], {IRON_ORE => 9_000, COAL => 9_000, LIME => 4500}, {IRON => 3_000}, 500), # 1 : 1 : 1/2 : 1/3
		Recipe.new(METAL_REFINERY, [],
			{INFERIOR_MAGIC_CRYSTAL => 200, GOLD => 400, SILVER => 1_200, COPPER => 2_000, IRON => 3_000, FIRE_CRYSTAL => 2_000},
			{INFERIOR_LIGHT_CRYSTAL => 20}, 1500),
		#  明の剣
		Recipe.new(INFERIOR_MAGIC_WORKBENCH, [], {INFERIOR_MAGIC_CRYSTAL => 50, INFERIOR_LIGHT_CRYSTAL => 20}, {INFERIOR_LIGHT_SWORD => 5}, 1000),
		#    暗の剣準備
		Recipe.new(ANCIENT_REFINERY, [], {INFERIOR_MAGIC_CRYSTAL => 250, COAL => 25_000, LIME => 25_000}, {INFERIOR_DARK_CRYSTAL => 10}, 2000),
		#  暗の剣
		Recipe.new(INFERIOR_MAGIC_WORKBENCH, [], {INFERIOR_MAGIC_CRYSTAL => 100, INFERIOR_DARK_CRYSTAL => 20}, {INFERIOR_DARK_SWORD => 5}, 2000),
		# 魔法結晶レシピ
		# =====
		#   最初の魔法結晶
	]
	
	CREATION_ITEMS_HASH = [
		# 普通魔法
		# =====
		#   魔法結晶レシピ
		[[INFERIOR_MAGIC_WORKBENCH, FIRE_FURNACE, WOOD_REFINERY, METAL_REFINERY, ANCIENT_REFINERY], {
			{INFERIOR_MAGIC_CRYSTAL => 10000, FIRE_CRYSTAL => 10_0000, WOOD_CRYSTAL => 40000, INFERIOR_LIGHT_CRYSTAL => 200, INFERIOR_DARK_CRYSTAL => 200} =>
				{MAGIC_CRYSTAL => 100},
		}],
		[[MAGIC_WORKBENCH, FIRE_FURNACE], {
			{FIRE_CRYSTAL => 20_0000} => {MAGIC_CRYSTAL => 10},
		}],
		[[MAGIC_WORKBENCH, WOOD_REFINERY], {
			{WOOD => 80_0000} => {MAGIC_CRYSTAL => 10},
		}],
		[[MAGIC_WORKBENCH, METAL_REFINERY], {
			{GOLD_ORE => 2000, SILVER_ORE => 6000, COPPER_ORE => 10000, IRON_ORE => 16000, COAL => 40000, LIME => 8000, FIRE_CRYSTAL => 20000} =>
				{MAGIC_CRYSTAL => 10},
		}],
		[[MAGIC_WORKBENCH, ANCIENT_REFINERY], {
			{COAL => 12_0000, LIME => 12_0000} => {MAGIC_CRYSTAL => 10},
		}],
		#   炎の結晶
		[[MAGIC_WORKBENCH, WOOD_REFINERY], {
			{MAGIC_CRYSTAL => 20, FIRE_CRYSTAL => 5_0000, WOOD_CRYSTAL => 20_0000} => {BLAZE_CRYSTAL => 10},
			{MAGIC_CRYSTAL => 400, FIRE_CRYSTAL => 100_0000, WOOD_CRYSTAL => 400_0000} => {BLAZE_CRYSTAL => 200},
		}],
		#   低級魔法剣大量生産レシピ
		[[FIRE_FURNACE, MAGIC_WORKBENCH, LARGE_FURNACE], {
			{FIRE_CRYSTAL => 1000, IRON => 500} => {FIRE_SWORD => 200},
		}],
		[[WOOD_REFINERY, MAGIC_WORKBENCH], {
			{WOOD => 800_0000} => {WOOD_CRYSTAL => 32_0000},
			{WOOD_CRYSTAL => 32_0000} => {INFERIOR_MAGIC_CRYSTAL => 8_0000},
			{BLAZE_CRYSTAL => 1, INFERIOR_MAGIC_CRYSTAL => 400, WOOD_CRYSTAL => 12000} => {WOOD_SWORD => 200},
		}],
		[[METAL_REFINERY, MAGIC_WORKBENCH, LARGE_FURNACE], {
			{
				BLAZE_CRYSTAL => 3, WOOD_CRYSTAL => 4000, INFERIOR_MAGIC_CRYSTAL => 1500,
				GOLD_ORE => 24000, SILVER_ORE => 72000, COPPER_ORE => 12_0000, IRON_ORE => 18_0000, LIME => 9_0000, COAL => 40_0000,
			} => {INFERIOR_LIGHT_CRYSTAL => 400},
			{BLAZE_CRYSTAL => 4, WOOD_CRYSTAL => 2000, INFERIOR_MAGIC_CRYSTAL => 1500, INFERIOR_LIGHT_CRYSTAL => 800} => {INFERIOR_LIGHT_SWORD => 200},
		}],
		[[ANCIENT_REFINERY], {
			{BLAZE_CRYSTAL => 3, INFERIOR_MAGIC_CRYSTAL => 10000, COAL => 1000000, LIME => 1000000} => {INFERIOR_DARK_CRYSTAL => 400},
			{BLAZE_CRYSTAL => 4, INFERIOR_MAGIC_CRYSTAL => 4000, INFERIOR_DARK_CRYSTAL => 800} => {INFERIOR_DARK_SWORD => 200},
		}],
	]
	
end
