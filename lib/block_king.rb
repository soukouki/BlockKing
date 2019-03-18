
require "discordrb"
require "twemoji"


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


class GameTable
	attr_reader :groups
	def initialize()
		@block_table = {}
		@block_table_mutex = Mutex.new
		@ruler_table = {}
		@ruler_table_mutex = Mutex.new
		@groups = {}
	end
	
	def group(id)
		@groups[id]
	end
	def add_group(group)
		@groups[group.id] = group
	end
	
	def block(pos)
		@block_table_mutex.synchronize do
			@block_table[pos] ||= select_object(pos)
		end
	end
	
	def ruler(pos)
		@ruler_table_mutex.synchronize do
			@ruler_table[pos] ||= initial_ruler(pos)
		end
	end
	def set_ruler(pos, new_ruler)
		@ruler_table_mutex.synchronize do
			@ruler_table[pos] = new_ruler
		end
	end
	
	def turn()
		# アイテム処理
		@ruler_table_mutex.synchronize do
			@ruler_table
				.each do |pos, ruler|
					next if ruler.nil?
					geted_items = block(pos).get_turn_items()
					geted_items.each do |item, count|
						ruler.add_item(item, count)
					end
				end
		end
	end
	
	def war(group)
		pos = group.pos
		enemy = ruler(pos)
		case (enemy.force * rand(0.95..1.05)) <=> (group.force * rand(0.95..1.05))
		when 1, 0 # enemyの勝利
			enemy.weaken_at_win
			group.weaken_at_lose
			:lose
		when -1   # groupの勝利
			enemy.weaken_at_lose
			group.weaken_at_win
			set_ruler(pos, group)
			if pos==AbPos::CENTER
				group.state = :ending
			end
			:win
		end
	end
	
	def is_there_a_group_other_than_myself?(group, pos)
		not @groups.values.reject{|l|l == group}.select{|l|l.pos == pos}.empty?
	end
	
	private
	
	def select_object(pos)
		case pos
		when AbPos::CENTER
			Block::CASTLE
		else
			if rand() > 0.5
				[Block::FARM, Block::IRON_MINE, Block::FOREST].sample
			else
				Block::EMPTY
			end
		end
	end
	
	def initial_ruler(pos)
		case pos
		when AbPos::CENTER
			NPCEnemy.new(140)
		else
			force = (
				(120 / Math.log(Math.sqrt((pos.x).abs+(pos.y).abs)+2, 1.1)) * rand(0.7..(1/0.7))
			).to_i
			NPCEnemy.new(force)
		end
	end
end

class Group
	attr_reader :id, :pos, :log, :items
	attr_accessor :state
	def initialize(id, name)
		@id = id
		@name = name
		@pos = initial_pos
		@soldier = 6
		@state = :first_story
		@items = {Item::FOOD => 20}
		@log = LogBasket.new
	end
	
	class LogBasket
		include Enumerable
		attr_reader :log
		def initialize
			@log = []
		end
		def callback(&block)
			@callback = block
		end
		def add(log)
			@log << ("#{Time.now.strftime("[%d日%H時%M分]")}"+log)
			@callback.call(log)
		end
		def clear()
			@log.clear
		end
		def each(*args)
			@log.each(*args)
		end
	end
	
	def force
		@soldier
	end
	
	def make_map(game_table)
		l = lambda do |x, y|
			game_table.is_there_a_group_other_than_myself?(self, @pos.diff_to_ab_pos(x, y))? "L" : " "
		end
		o = lambda do |x, y|
			game_table.block(@pos.diff_to_ab_pos(x, y))
		end
		<<~EOS
			```
			   :    :    :    :
			...+----+----+----+...
			   |  #{l[-1,1]} |  #{l[0,1]} |  #{l[1,1]} |
			   |#{o[-1,1]}|#{o[0,1]}|#{o[1,1]}|
			...+----+----+----+...
			   |  #{l[-1,0]} | Y#{l[0,0]} |  #{l[1,0]} |
			   |#{o[-1,0]}|#{o[0,0]}|#{o[1,0]}|
			...+----+----+----+...
			   |  #{l[-1,-1]} |  #{l[0,-1]} |  #{l[1,-1]} |
			   |#{o[-1,-1]}|#{o[0,-1]}|#{o[1,-1]}|
			...+----+----+----+...
			   :    :    :    :
			```
			Y...あなたのいる位置
			L...他のリーダー
		EOS
	end
	
	def move(game_table, m_x, m_y)
		game_table.set_ruler(@pos, nil)
		use_food = if game_table.ruler(@pos) == self
			0
		else
			@soldier
		end
		food_count = @items[Item::FOOD] || 0
		if use_food > food_count
			@log.add("食料が足りず、行動に失敗しました。\n	使用数`#{use_food}`/現在`#{food_count}`")
		else
			@items[Item::FOOD] -= use_food
		end
		@pos = @pos.diff_to_ab_pos(m_x, m_y)
	end
	
	def weaken_at_win
		count = rand(0..1.0*@soldier/6).round
		if count != 0
			@soldier += count
			@log.add("#{count}人がグループに加わりました！")
		end
	end
	def weaken_at_lose
		count = rand(0..1.0*@soldier/4).to_i
		if count != 0
			@soldier -= count
			@log.add("残念ながら、#{count}人がグループから去っていきました・・・")
		end
	end
	
	def compare_force(enemy)
		# インフレしたらいろいろ入れてみたい
		case 1.0 * enemy.force / force
		when 0..0.5
			"余裕で勝てる"
		when 0..0.7
			"ほぼ確実に勝てる"
		when 0..0.9
			"おそらく勝てる"
		when 0..(1/0.9)
			"勝つか負けるかわからない"
		when 0..(1/0.7)
			"おそらく負ける"
		when 0..2
			"ほぼ確実に負ける"
		else
			"余裕で負ける"
		end
	end
	
	def add_item(item, count)
		@items[item] ||= 0
		@items[item] += count
		@log.add("#{item}を#{count}個入手しました。")
	end
	
	private
	
	def initial_pos
		r = rand(0..Math::PI*2)
		AbPos.new(*[Math.cos(r), Math.sin(r)].map{|x|(x*10).round})
	end
end

class NPCEnemy
	attr_reader :force
	def initialize(soldier)
		@force = soldier
	end
	
	def weaken_at_win
		@force -= 1
	end
	# 次にこれが試合をすることはないから
	def weaken_at_lose
	end
	
	# とりあえず
	def add_item(item, count)
	end
end

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
