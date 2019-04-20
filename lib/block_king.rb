
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
	Recipe = Struct.new(:buildings, :items, :result) do
		def can_craft?(adjacent_buildings, owns_items)
			enough_adjacent_buildings?(adjacent_buildings) && enough_items?(owns_items)
		end
		
		def enough_adjacent_buildings?(adjacent_buildings)
			buildings.all?{|b|adjacent_buildings.include? b}
		end
		def enough_items?(owns_items)
			items.all?{|item,count|(owns_items[item]||0) >= count}
		end
	end
	
	attr_reader :level
	def initialize()
		ここは来ないはずです・・
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
	def creation_items
		GameData::CREATION_ITEMS_HASH
			.select{|k,v|k[0] == self.class}
			.map{|b,v|v.map{|(i,r)|Recipe.new(b,i,r)}}
			.flatten || {}
	end
	def map_name
		name
	end
end
class Nature < Block
	attr_accessor :remaining_items
	def initialize(level)
		@level = level
		@remaining_items = level * 10
		@maximum_items = @remaining_items
	end
	def turn_items(group)
		item = get_items_when_turning
		if item && @remaining_items > 0
			count = if @remaining_items > @maximum_items/2
				level*2
			else
				(level*2.0 * @remaining_items*1.0 / @maximum_items).ceil
			end
			[item, [count, ((group.soldier*1.5 + 15) * rand(0.7..1)).to_i].min]
		else
			[]
		end
	end
	def remaining_items_text
		case 1.0 * @remaining_items / @maximum_items
		when 0.9..Float::INFINITY
			"たくさんあります！"
		when 0.7..1
			"まだまだあります！"
		when 0.5..1
			"だいぶ減ってきました。"
		when 0.3..1
			"残り少なくなりました。移ったほうがいいかもしれません。"
		when 0.1..1
			"もう少ししか残っていません。移ったほうがいいかもしれません。"
		else
			"殆ど残ってなさそうです。移ったほうがいいでしょう。"
		end
	end
	def get_items_when_turning; nil end
end
class Building < Block
	attr_reader :builder
	def initialize(builder, level)
		@builder = builder
		@level = level
	end
	def == o
		self == o && o.builder == @builder
	end
	def turn_items(group); [] end
	def get_items_when_turning; nil end
	def need_items
		GameData::CAN_BUILD_LIST[self.class]
	end
end

def Block.new_type(type_name, &block)
	Class.new(self) do # ここのselfはNatureとかになる
		define_method(:name) do
			type_name
		end
		define_singleton_method(:type_name) do
			type_name
		end
		define_singleton_method(:defi) do |key, &defi_block|
			define_method(key){defi_block.call}
		end
		block.call(self)
	end
end

require_relative "game_data"
