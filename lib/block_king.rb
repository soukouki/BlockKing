
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


class GameTable
	attr_reader :leaders
	def initialize()
		@block_table = {}
		@block_table_mutex = Mutex.new
		@ruler_table = {}
		@ruler_table_mutex = Mutex.new
		@leaders = {}
	end
	
	def leader(id)
		@leaders[id]
	end
	def add_leader(leader)
		@leaders[leader.id] = leader
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
	
	def war(leader)
		pos = leader.pos
		enemy = ruler(pos)
		case enemy.force <=> leader.force
		when 1, 0 # enemyの勝利
			enemy.weaken_at_win
			leader.weaken_at_lose
			:lose
		when -1   # leaderの勝利
			enemy.weaken_at_lose
			leader.weaken_at_win
			set_ruler(pos, leader)
			:win
		end
	end
	
	def is_there_a_leader_other_than_myself?(leader, pos)
		not @leaders.values.reject{|l|l == leader}.select{|l|l.pos == pos}.empty?
	end
	
	private
	
	def select_object(pos)
		case pos
		when AbPos.new(0, 0)
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
		when AbPos.new(0, 0)
			NPCEnemy.new(100)
		else
			NPCEnemy.new(rand(5..15))
		end
	end
end

class Leader
	attr_reader :id, :pos, :log, :items
	attr_accessor :state
	def initialize(id, name)
		@id = id
		@name = name
		@pos = initial_pos
		@soldier = 10
		@state = :first_story
		@items = {}
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
			@log << log
			@callback.call(log)
		end
		def clear()
			@log.clear
		end
		def each(*args)
			@log.each(*args)
		end
	end
	GetItemLog = Struct.new(:item, :count, :time) do
		def to_s
			"#{time}に#{item}を#{count}個入手しました。"
		end
	end
	
	def force
		@soldier
	end
	
	def make_map(game_table)
		l = lambda do |x, y|
			game_table.is_there_a_leader_other_than_myself?(self, @pos.diff_to_ab_pos(x, y))? "L" : " "
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
		@pos = @pos.diff_to_ab_pos(m_x, m_y)
	end
	
	def weaken_at_win
		# まだ実装していない
	end
	def weaken_at_lose
		# まだ実装していない
	end
	
	def compare_force(enemy)
		enemy_apparent_force = enemy.force # 誤差とか入れたい
		# インフレしたらいろいろ入れてみたい
		case enemy_apparent_force / force
		when 0..0.7
			"ほぼ確実に勝てる"
		when 0..0.9
			"おそらく勝てる"
		when 0..(0.9/1)
			"勝つか負けるかわからない"
		when 0..(0.7/1)
			"おそらく負ける"
		else
			"ほぼ確実に負ける"
		end
	end
	
	def add_item(item, count)
		@items[item] ||= 0
		@items[item] += count
		@log.add(GetItemLog.new(item, count, Time.now))
	end
	
	private
	
	def initial_pos
		pos = AbPos.new(rand(-2..2), rand(-2..-2))
		if pos == AbPos.new(0, 0)
			initial_pos
		else
			pos
		end
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
	
	GOLD = Item.new("金")
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
	CASTLE = Block.new("王城", {Item::GOLD => 1000})
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
