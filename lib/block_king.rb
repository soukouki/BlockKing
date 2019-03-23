
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
		GameData::GET_TURN_ITEMS_HASH[name] || {}
	end
	def creation_items
		GameData::CREATION_ITEMS_HASH[name] || {}
	end
end

require_relative "game_data"
