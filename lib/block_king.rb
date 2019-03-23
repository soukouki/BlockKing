
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
class Block
	attr_reader :builder, :level
	def initialize(level)
		@builder = nil
		@level = level
	end
	def eql?(o)
		name.eql?(o.name) && level.eql?(o.level)
	end
	def hash
		name.hash ^ level.hash
	end
	def to_s
		name
	end
	def empty?
		false
	end
	def get_turn_items
		GameData::GET_TURN_ITEMS_HASH[name] || {}
	end
	def creation_items
		GameData::CREATION_ITEMS_HASH[name] || {}
	end
end
class Building < Block
	def initialize(builder, level)
		@builder = builder
		@level = level
	end
	def == o
		self == o && o.builder == @builder
	end
	def need_items
		GameData::CAN_BUILD_LIST[self.class]
	end
end

require_relative "game_data"
