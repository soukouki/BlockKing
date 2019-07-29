
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
	BLAZE_SWORD = Item.new("炎の剣")
	TREE_CRYSTAL = Item.new("樹の結晶")
	TREE_SWORD = Item.new("樹の剣")
	
	LIGHT_SWORD = Item.new("光の剣")
	DARK_SWORD = Item.new("闇の剣")
	
	
	# 攻撃力順に並べる！
	SWORD_ATTACK_POWER_HASH = {
		COPPER_SWORD => 1.5,
		IRON_SWORD => 2.5,
		HIGH_IRON_SWORD => 5,
		FIRE_SWORD => 12,
		WOOD_SWORD => 60,
		INFERIOR_LIGHT_SWORD => 300,
		INFERIOR_DARK_SWORD => 500,
		BLAZE_SWORD => 3_000,
		TREE_SWORD => 10_000,
	}
	
	SORT_ORDER = [
		WOOD, LIME, CLAY, COAL,
		GOLD_ORE, SILVER_ORE, COPPER_ORE, IRON_ORE,
		GOLD, SILVER, COPPER, IRON,
		BRICK, FIRE_BRICK,
		INFERIOR_MAGIC_CRYSTAL, FIRE_CRYSTAL, WOOD_CRYSTAL, INFERIOR_LIGHT_CRYSTAL, INFERIOR_DARK_CRYSTAL,
		MAGIC_CRYSTAL, BLAZE_CRYSTAL, TREE_CRYSTAL,
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
		Recipe.new(FIRE_FURNACE, [], {FIRE_CRYSTAL => 200}, {INFERIOR_MAGIC_CRYSTAL => 10}, 150),
		Recipe.new(WOOD_REFINERY, [], {WOOD => 2_500}, {WOOD_CRYSTAL => 100}, 150),
		Recipe.new(WOOD_REFINERY, [], {WOOD_CRYSTAL => 40}, {INFERIOR_MAGIC_CRYSTAL => 10}, 150),
		#  木の剣
		Recipe.new(INFERIOR_MAGIC_WORKBENCH, [], {INFERIOR_MAGIC_CRYSTAL => 25, WOOD_CRYSTAL => 300}, {WOOD_SWORD => 5}, 800),
		#    明の剣準備
		Recipe.new(LARGE_FURNACE, [], {GOLD_ORE => 1_200, COAL => 600}, {GOLD => 400}, 250), # 1 : 1/2 : 1/3
		Recipe.new(LARGE_FURNACE, [], {SILVER_ORE => 3_600, COAL => 2_800}, {SILVER => 1_200}, 250), # 1 : 4/5 : 1/3
		Recipe.new(LARGE_FURNACE, [], {COPPER_ORE => 6_000, COAL => 6_000}, {COPPER => 2_000}, 250), # 1 : 1 : 1/3
		Recipe.new(LARGE_FURNACE, [], {IRON_ORE => 9_000, COAL => 9_000, LIME => 4500}, {IRON => 3_000}, 250), # 1 : 1 : 1/2 : 1/3
		Recipe.new(METAL_REFINERY, [],
			{INFERIOR_MAGIC_CRYSTAL => 200, GOLD => 400, SILVER => 1_200, COPPER => 2_000, IRON => 3_000, FIRE_CRYSTAL => 2_000},
			{INFERIOR_LIGHT_CRYSTAL => 20}, 500),
		#  明の剣
		Recipe.new(INFERIOR_MAGIC_WORKBENCH, [], {INFERIOR_MAGIC_CRYSTAL => 50, INFERIOR_LIGHT_CRYSTAL => 20}, {INFERIOR_LIGHT_SWORD => 5}, 1000),
		#    暗の剣準備
		Recipe.new(ANCIENT_REFINERY, [], {INFERIOR_MAGIC_CRYSTAL => 250, COAL => 25_000, LIME => 25_000}, {INFERIOR_DARK_CRYSTAL => 10}, 1500),
		#  暗の剣
		Recipe.new(INFERIOR_MAGIC_WORKBENCH, [], {INFERIOR_MAGIC_CRYSTAL => 100, INFERIOR_DARK_CRYSTAL => 20}, {INFERIOR_DARK_SWORD => 5}, 2000),
		
		# 中級魔法剣
		# =====
		# 魔法結晶
		Recipe.new(INFERIOR_MAGIC_WORKBENCH, [FIRE_FURNACE, WOOD_REFINERY, METAL_REFINERY, ANCIENT_REFINERY],
			{INFERIOR_MAGIC_CRYSTAL => 2_000, FIRE_CRYSTAL => 20_000, WOOD_CRYSTAL => 8_000, INFERIOR_LIGHT_CRYSTAL => 40, INFERIOR_DARK_CRYSTAL => 40},
			{MAGIC_CRYSTAL => 20}, 3000),
		#   魔法結晶量産
		Recipe.new(FIRE_FURNACE, [MAGIC_WORKBENCH], {FIRE_CRYSTAL => 200_000}, {MAGIC_CRYSTAL => 10}, 1500),
		Recipe.new(WOOD_REFINERY, [MAGIC_WORKBENCH], {WOOD_CRYSTAL => 32_000}, {MAGIC_CRYSTAL => 10}, 1500),
		Recipe.new(METAL_REFINERY, [MAGIC_WORKBENCH, LARGE_FURNACE],
			{GOLD_ORE => 2_000, SILVER_ORE => 6_000, COPPER_ORE => 10_000, IRON_ORE => 16_000, COAL => 40_000, LIME => 8_000, FIRE_CRYSTAL => 20_000},
			{MAGIC_CRYSTAL => 10}, 1500),
		Recipe.new(ANCIENT_REFINERY, [MAGIC_WORKBENCH], {COAL => 120_000, LIME => 120_000}, {MAGIC_CRYSTAL => 10}, 1500),
		#   炎の結晶
		Recipe.new(MAGIC_WORKBENCH, [WOOD_REFINERY],
			{MAGIC_CRYSTAL => 2, FIRE_CRYSTAL => 20_000, WOOD_CRYSTAL => 5_000},
			{BLAZE_CRYSTAL => 1}, 1000),
		# 炎の剣
		Recipe.new(MAGIC_WORKBENCH, [FIRE_FURNACE],
			{MAGIC_CRYSTAL => 6, BLAZE_CRYSTAL => 3, FIRE_SWORD => 1_000},
			{BLAZE_SWORD => 5}, 3000),
		#   樹の剣準備
		Recipe.new(WOOD_REFINERY, [MAGIC_WORKBENCH, FIRE_FURNACE],
			{MAGIC_CRYSTAL => 5, BLAZE_CRYSTAL => 1, WOOD_CRYSTAL => 10_000},
			{TREE_CRYSTAL => 1}, 2500),
		# 樹の剣
		Recipe.new(MAGIC_WORKBENCH, [WOOD_REFINERY],
			{TREE_CRYSTAL => 3, WOOD_SWORD => 500},
			{TREE_SWORD => 5}, 5000),
	]
	
end
