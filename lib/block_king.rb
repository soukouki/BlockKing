
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

class Item
	attr_reader :name
	def initialize(name)
		@name = name
	end
	
	COPPER_ORE = Item.new("銅鉱石")
	COPPER = Item.new("銅")
	COPPER_SWORD = Item.new("銅の剣")
	IRON_ORE = Item.new("鉄鉱石")
	IRON = Item.new("鉄")
	IRON_SWORD = Item.new("銅の剣")
	WOOD = Item.new("木材")
	CLAY = Item.new("粘土")
	BRICK = Item.new("レンガ")
	
	def ==(pair)
		name == pair.name
	end
	
	def to_s
		@name
	end
end


Block = Struct.new(:name, :get_turn_items, :creation_items) do
	def ==(pair)
		name == pair.name
	end
	def to_s
		name
	end
end
Block::EMPTY = Block.new("    ", {}, [])
Block::CASTLE = Block.new("王城", {}, [])
Block::COPPER_MINE = Block.new("銅鉱", {Item::COPPER_ORE => 20}, [])
Block::IRON_MINE = Block.new("鉄鉱", {Item::IRON_ORE => 20}, [])
Block::FOREST = Block.new("森林", {Item::WOOD => 20}, [])
Block::LOW_LEVEL_FURNACE = Block.new("下炉", {}, {
	{Item::COPPER_ORE => 10, Item::WOOD => 20} => {Item::COPPER_SWORD => 5},
	{Item::CLAY => 20, Item::WOOD => 20} => {Item::BRICK => 20},
})
Block::MEDIUM_LEVEL_FURNACE = Block.new("中炉", {}, {
	{Item::IRON_ORE => 10, Item::WOOD => 30} => {Item::IRON_SWORD => 5},
})

Block::CAN_BUILD_LIST = {
	Block::LOW_LEVEL_FURNACE => {Item::WOOD => 40},
	Block::MEDIUM_LEVEL_FURNACE => {Item::BRICK => 40, Item::WOOD => 10},
}
