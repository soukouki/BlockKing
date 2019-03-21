
require_relative "block_king/game_table"
require_relative "block_king/group"

# 絶対ポス
# absolute position
AbPos = Struct.new(:x, :y) do
	def to_s
		"#{x}, #{y}"
	end
	def diff_to_ab_pos(diff_x, diff_y)
		AbPos.new(x+diff_x, y+diff_y)
	end
end
AbPos::CENTER = AbPos.new(0, 0)

Item = Struct.new(:name) do
	def to_s
		name
	end
end
Block = Struct.new(:name) do
	def to_s
		name
	end
	def get_turn_items
		Block::GET_TURN_ITEMS_HASH[self] || {}
	end
	def creation_items
		Block::CREATION_ITEMS_HASH[self] || {}
	end
end


class Item
	COPPER_ORE = Item.new("銅鉱石")
	COPPER = Item.new("銅")
	COPPER_SWORD = Item.new("銅の剣")
	IRON_ORE = Item.new("鉄鉱石")
	IRON = Item.new("鉄")
	IRON_SWORD = Item.new("銅の剣")
	WOOD = Item.new("木材")
	CLAY = Item.new("粘土")
	BRICK = Item.new("レンガ")
	
	SWORD_ATTACK_POWER_HASH = {
		Item::COPPER_SWORD => 2,
		Item::IRON_SWORD => 4,
	}
end
class Block
	EMPTY = Block.new("    ")
	CASTLE = Block.new("王城")
	COPPER_MINE = Block.new("銅鉱")
	IRON_MINE = Block.new("鉄鉱")
	FOREST = Block.new("森林")
	MARSH = Block.new(" 沼 ")
	LOW_LEVEL_FURNACE = Block.new("下炉")
	MEDIUM_LEVEL_FURNACE = Block.new("中炉")
	
	GET_TURN_ITEMS_HASH = {
		COPPER_MINE => {Item::COPPER_ORE => 20},
		IRON_MINE => {Item::IRON_ORE => 20},
		FOREST => {Item::WOOD => 20},
		MARSH => {Item::CLAY => 20},
	}
	CREATION_ITEMS_HASH = {
		LOW_LEVEL_FURNACE => {
			{Item::COPPER_ORE => 10, Item::WOOD => 20} => {Item::COPPER_SWORD => 5},
			{Item::CLAY => 20, Item::WOOD => 20} => {Item::BRICK => 20},
		},
		MEDIUM_LEVEL_FURNACE => {
			{Item::IRON_ORE => 10, Item::WOOD => 30} => {Item::IRON_SWORD => 5},
		},
	}
	
	CAN_BUILD_LIST = {
		LOW_LEVEL_FURNACE => {Item::WOOD => 40},
		MEDIUM_LEVEL_FURNACE => {Item::BRICK => 40, Item::WOOD => 10},
	}
end
