
class Group
	attr_reader :id, :pos, :log, :soldier, :items
	attr_accessor :state
	def initialize(id, name)
		@id = id
		@name = name
		@pos = initial_pos
		@soldier = 6
		@state = :first_story
		@log = LogBasket.new
		@items = {}
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
		sword_hash = {
			Item::COPPER_SWORD => 2,
			Item::IRON_SWORD => 4,
		}
		re, fo = sword_hash
			.to_a
			.sort_by{|i,atk|atk}
			.map{|sword,atk|[atk, @items[sword]||0]}
			.reduce([@soldier, 0]) do |(remaining_soldier, force), (attack_power, having_count)|
				m = [remaining_soldier, having_count].min
				[remaining_soldier-m, force+m*attack_power]
			end
		fo + re
	end
	
	def make_map(game_table)
		l = lambda do |x, y|
			ypos = (x==0 && y==0)? "Y" : " "
			game_table.is_there_a_group_other_than_myself?(self, @pos.diff_to_ab_pos(x, y))? " #{ypos}L " : " #{ypos}  "
		end
		ll = lambda do |y|
			"   |"+
			5.times
				.map{|i|l[i-2, y]}
				.join("|")+"|"
		end
		o = lambda do |x, y|
			game_table.block(@pos.diff_to_ab_pos(x, y)).to_s
		end
		ol = lambda do |y|
			fullwidth_count = 0
			"   |"+
			5.times
				.map{|i|i-2}
				.map{|x|[x, o[x, y]]}
				.map do |(x, s)|
					fullwidth_count += s.length - s.count(" ")
					if fullwidth_count>=4 && x<2
						fullwidth_count -= 4
						s+" "
					else
						s
					end
				end
				.join("|")+"|"
		end
		al = "   :#{"    :"*5}"
		bl = "...+#{"----+"*5}..."
		<<~EOS
			```
			#{al}
			#{bl}
			#{5.times.reverse_each.map{|y|ll[y-2]+"\n"+ol[y-2]+"\n"+bl}.join("\n")}
			#{al}
			```
			Y...あなたのいる位置
			L...他のリーダー
		EOS
	end
	
	def move(game_table, m_x, m_y)
		game_table.set_ruler(@pos, nil)
		@pos = @pos.diff_to_ab_pos(m_x, m_y)
	end
	
	# 既に建物が建っている・支配できていない・建設できないブロック、のチェックはUI側で行っているので、省略する
	def build(game_table, block)
		need_items = Block::CAN_BUILD_LIST[block]
		need_items
			.each do |item,count|
				i = @items[item] || 0
				return [false, "#{item}が#{count-i}足りません。"] if i < count
			end
		need_items.each{|item,count|@items[item] -= count}
		game_table.set_block(@pos, block)
		[true, <<~EOS]
			#{block}が完成しました！
			「リーダー！夢に向かって、また一歩前進ですね！」
		EOS
	end
	
	def remove(game_table)
		block = game_table.block(@pos)
		ruler = game_table.ruler(@pos)
		need_items = Block::CAN_BUILD_LIST[block]
		if block==Block::EMPTY
			return [false, "「そもそも更地をどう解体するんですか・・？馬鹿なんですか・・？」"]
		end
		unless need_items
			return [false, "「#{block}を解体？いやですよー。」"]
		end
		if ruler!=self
			return [false, "「ここを支配してるグループが邪魔すぎて、仕事にならないですよー。」"]
		end
		game_table.set_block(@pos, Block::EMPTY)
		need_items.each{|item, count|add_item(item, count)}
		return [true, <<~EOS]
			無事に解体できました。
			#{need_items.map{|i,c|"#{i}を#{c}"}.join("、")}
			を手に入れました
		EOS
	end
	
	# 支配できていない・このレシピが作れうかどうか、のチェックはUI側で行っているので、省略する
	def craft_using_building(game_table, recipe)
		need_items, finished_items = recipe
		need_items
			.each do |item,count|
				i = @items[item] || 0
				return [false, "#{item}が#{count-i}足りません。"] if i < count
			end
		need_items.each{|item,count|@items[item] -= count}
		finished_items.each{|item,count|add_item(item, count)}
		[true, <<~EOS]
			無事に作成できたときのメッセージ。
			これまた作れたアイテムのテキスト用意しないといけない・・？
		EOS
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
