
class Group
	attr_reader :id, :log, :soldier, :items
	attr_accessor :name, :state, :pos, :tutorial_level
	def initialize(id, game_table)
		@id = id
		@name = ""
		@soldier = 6
		@items = {}
		@pos = game_table.initial_pos(@soldier)
		@state = :first_story
		@log = LogBasket.new
		@tutorial_level = 0
	end
	
	class LogBasket
		attr_writer :callback
		def initialize
			@causes = {}
			@text_logs = []
			@callback = ->{}
		end
		def add_item(sync, cause, item, count)
			causes_empty = @causes.empty?
			@causes[cause] ||= {}
			@causes[cause][item] ||= 0
			@causes[cause][item] += count
			@callback.call("「アイテムが手に入りました！確認してみてください！」") if !sync && causes_empty
		end
		# short_text_or_nilがnilのときは通知をしない
		def add_text(group, short_text_or_nil, text)
			@text_logs << Time.now.strftime("[%m月%d日%H時%M分]")+text
			@callback.call("<@#{group.id}>\n#{short_text_or_nil}") if short_text_or_nil
		end
		def clear()
			@causes = {}
			@text_logs = []
		end
		def to_s
			@text_logs.join("\n")+(
				text = @causes
					.map do |cause, hash|
						"#{cause}、#{hash.reject{|i,c|c==0}.map{|i,c|"#{i}を`#{c}`"}.join("、")}"
					end
					.join("\n")
				(text == "")? "" : text+"、手に入れました！"
			)
		end
	end
	
	def weapon_allocation
		remaining_soldier, weapon_allocation = GameData::SWORD_ATTACK_POWER_HASH
			.to_a
			.reverse
			.map{|sword,atk|[sword, @items[sword]||0]}
			.reduce([@soldier, {}]) do |(remaining_soldier, weapon_allocation), (sword, having_count)|
				m = [remaining_soldier, having_count].min
				weapon_allocation[sword] = m unless m == 0
				[remaining_soldier-m, weapon_allocation]
			end
		weapon_allocation
	end
	
	def force
		allocation = weapon_allocation
		@soldier-allocation.values.sum + # 素手兵士
		allocation.map{|sword,count|GameData::SWORD_ATTACK_POWER_HASH[sword] * count}.sum
	end
	
	def move(game_table, m_x, m_y)
		game_table.set_ruler(@pos, nil) if game_table.ruler(@pos) == self
		@pos = @pos.diff_to_ab_pos(m_x, m_y)
	end
	
	# 既に建物が建っている・支配できていない・建設できないブロック、のチェックはBlockKingUI側で行っているので、省略する
	def build(game_table, block)
		need_items = block.need_items
		need_items
			.each do |item,count|
				i = @items[item] || 0
				return [false, "#{item}が#{count-i}足りません。"] if i < count
			end
		need_items.each{|item,count|@items[item] -= count}
		game_table.set_block(@pos, block)
		[true, <<~EOS]
			#{block}が完成しました！
		EOS
	end
	
	def remove(game_table)
		block = game_table.block(@pos)
		ruler = game_table.ruler(@pos)
		if block.empty?
			return [false, "「そもそも更地をどう解体するんですか・・？馬鹿なんですか・・？」"]
		end
		unless block.is_a?(Building)
			return [false, "「#{block}を解体？いやですよー。」"]
		end
		need_items = block.need_items
		if ruler!=self
			return [false, "「ここを支配してるグループが邪魔すぎて、仕事にならないですよー。」"]
		end
		game_table.set_block(@pos, GameData::EMPTY.new(game_table.calc_level(pos)))
		need_items
			.map{|item, count|[item, rand((count/2)..count)]}
			.each{|(item, count)|add_item(true, "#{block}の解体で", item, count)}
		return [true, <<~EOS]
			無事に解体できました！
		EOS
	end

	# チェック(そのブロックで作れるのか、そのアイテムで作れるのか、など)はBlockKingUIにて行う
	def start_crafting(recipe_and_count)
		@crafting_mutex ||= Mutex.new
		@crafting_mutex.synchronize do
			if @status == :crafting || @craft_start_time || @crafting_recipe_and_count
				p [@status, @craft_start_time, @crafting_recipe_and_count]
				if @status.nil?
					@craft_start_time = nil
					@crafting_recipe_and_count = nil
					return "「あれ、作業班が変なの作ってます。止めてきますね」"
				else
					return "「あれ、作業班はもうなにか作っているみたいです」"
				end
			end
			@craft_start_time = Time.now
			@crafting_recipe_and_count = recipe_and_count
			@status = :crafting
			nil
		end
	end
	def check_crafting_and_finish(sync_log)
		@crafting_mutex ||= Mutex.new
		@crafting_mutex.synchronize do
			unless @status == :crafting && @craft_start_time && @crafting_recipe_and_count
				@status = nil
				@craft_start_time = nil
				@crafting_recipe_and_count = nil
				@log.add_text(self, !sync_log && "エラーが発生したため、クラフトを打ち切りました。", "エラーが発生したため、クラフトを打ち切りました。")
				return
			end
			
			# まだできてない
			return if Time.now - @craft_start_time > @crafting_recipe_and_count.craft_time
			
			recipe_and_count = @crafting_recipe_and_count
			@status = nil
			@craft_start_time = nil
			@crafting_recipe_and_count = nil
			
			recipe_and_count.need_items.each{|item,count|@items[item] -= count}
			@log.add_text(self, !sync_log && "「クラフトが終わりました！」", "「アイテムを作り終えました！」")
			recipe_and_count.products_times_count.each{|item,count|add_item(true, "クラフトで", item, count)}
		end
	end
	
	def weaken_at_win(sync_log)
		count = rand(0..Math.log(@soldier, 2)).round
		if count != 0
			@soldier += count
			@log.add_text(self, !sync_log && "「戦闘に勝利しました！」", "戦闘に勝利し、`#{count}`人が加わりました！")
		end
	end
	def weaken_at_lose(sync_log)
		count = rand(0..1.0*@soldier/4).to_i
		if count != 0
			@soldier -= count
			@log.add_text(self, !sync_log && "「残念ながら、戦闘に敗北してしまいました・・・」", "戦闘に敗北し、残念ながら`#{count}`人が去っていきました・・・")
		end
	end
	
	def rebellion_occurred()
		@items = weapon_allocation
			.map{|sword, count|[sword, count/2]} # 半分(切り捨て)
			.to_h
		@soldier = [@soldier/2, 6].max # 最小6
	end
	
	def add_item(sync, cause, item, count)
		@items[item] ||= 0
		@items[item] += count
		@log.add_item(sync, cause, item, count)
	end
end

class NPCEnemy
	attr_reader :force
	def initialize(soldier)
		@force = soldier
	end
	
	def weaken_at_win(sync_log)
		@force -= 1
	end
	# 次にこれが試合をすることはないから
	def weaken_at_lose(sync_log)
	end
	
	def add_item(sync, cause, item, count)
	end
end
