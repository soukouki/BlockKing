
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
	
	def add_item(item, count)
		@items[item] ||= 0
		@items[item] += count
		@log.add("#{item}を#{count}個入手しました。")
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
	
	def self.direction_of_castle(pos)
		x, y = [pos.x, pos.y]
		return "" if pos == AbPos::CENTER
		l = Math.sqrt(x*x+y*y)
		ac_ang = Math.acos(x/l)*180/Math::PI
		ang = (y<0)? 360-ac_ang : ac_ang
		piece = 360.0/(8*2)
		str = ["西", "南西", "南", "南東", "東", "北東", "北", "北西"][((ang/piece)/2).round % 8]
		"王都は"+str+"の方向。"
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
