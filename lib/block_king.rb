
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
	def initialize(name)
		@name = name
	end
	
	COPPER_ORE = Item.new("銅鉱石")
	COPPER = Item.new("銅")
	IRON_ORE = Item.new("鉄鉱石")
	IRON = Item.new("鉄")
	WOOD = Item.new("木材")
	
	def ==(pair)
		@name == pair.instance_variable_get(:@name)
	end
	
	def to_s
		@name
	end
end


Block = Struct.new(:name, :get_turn_items) do
	def ==(pair)
		name == pair.name
	end
	def to_s
		name
	end
end
Block::EMPTY = Block.new("    ", [])
Block::CASTLE = Block.new("王城", [])
Block::COPPER_MINE = Block.new("銅鉱", {Item::COPPER_ORE => 20})
Block::IRON_MINE = Block.new("鉄鉱", {Item::IRON_ORE => 20})
Block::FOREST = Block.new("森林", {Item::WOOD => 20})
Block::LOW_LEVEL_FURNACE = Block.new("下炉", {})

Block::CAN_BUILD_LIST = {
	Block::LOW_LEVEL_FURNACE => {Item::WOOD => 40},
}
