
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
		@ruler_table = {}
		@leaders = {}
	end
	
	def leader(id)
		@leaders[id]
	end
	def add_leader(leader)
		@leaders[leader.id] = leader
	end
	
	def block(pos)
		@block_table[pos] ||= select_object(pos)
	end
	
	def ruler(pos)
		@ruler_table[pos] ||= initial_ruler(pos)
	end
	def set_ruler(pos, new_ruler)
		@ruler_table[pos] = new_ruler
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
			NPCEnemy.new(rand(5..20))
		end
	end
end

class Leader
	attr_reader :id, :pos
	attr_accessor :state
	def initialize(id, name)
		@id = id
		@name = name
		@pos = initial_pos
		@soldier = 10
		@state = :first_story
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
end

class Block
	def initialize(name)
		@name = name
	end
	
	def ==(pair)
		@name == pair.instance_variable_get(:@name)
	end
	
	EMPTY = Block.new("    ")
	CASTLE = Block.new("王城")
	FARM = Block.new(" 畑 ")
	IRON_MINE = Block.new("鉄鉱")
	FOREST = Block.new("森林")
	
	def to_s
		@name
	end
end
