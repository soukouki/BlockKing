
require "discordrb"
require "twemoji"

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
	
	FOOD = Item.new("食料")
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


class Block
	attr_reader :get_turn_items
	def initialize(name, get_turn_items)
		@name = name
		@get_turn_items = get_turn_items
	end
	
	EMPTY = Block.new("    ", [])
	CASTLE = Block.new("王城", [])
	FARM = Block.new(" 畑 ", {Item::FOOD => 20}) # これ人数にもよるんじゃ・・？
	IRON_MINE = Block.new("鉄鉱", {Item::IRON_ORE => 20})
	FOREST = Block.new("森林", {Item::WOOD => 20})
	
	def ==(pair)
		@name == pair.instance_variable_get(:@name)
	end
	
	def to_s
		@name
	end
end
