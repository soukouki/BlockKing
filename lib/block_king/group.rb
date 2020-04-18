
class GroupBase
	def force; raise NotImplementedError; end
	def weaken_at_win(sync_log, enemy); raise NotImplementedError; end
	def weaken_at_lose(sync_log, enemy); raise NotImplementedError; end
	def ambiguous_force
		force * rand(0.9..1.1)*rand(0.9..1.1)
	end
	def turn() # 何もしない
	end
	def add_item(sync, cause, item, count) # 何もしない
	end
	def state=(args) # 何もしない
	end
	def add_log(text_to_notify:, text:) # 何もしない
	end
end

class Group < GroupBase
	attr_reader :id, :soldier, :items, :crafting_recipe_and_count
	attr_accessor :name, :state, :pos, :tutorial_level
	def ui_related_data
		@ui_related_data ||= UIRelatedData.new
	end
	
	def initialize(id, game_table)
		@id = id
		@name = ""
		@soldier = 6
		@items = {}
		@pos = game_table.initial_pos(@soldier)
		@state = :starting_game
		@log = LogBasket.new
		@tutorial_level = 0
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
		# ルーラーが空いたときは必ずblock_enemyを設定する
		game_table.set_ruler(@pos, game_table.block(@pos).block_enemy) if game_table.ruler(@pos) == self
		@pos = @pos.diff_to_ab_pos(m_x, m_y)
	end
	
	# 既に建物が建っている・支配できていない・建設できないブロック、のチェックはHandler側で行っているので、省略する
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
	
	# もし変な値が入っていたときに処理する部分、強制終了時など
	# 正常時trueを返す
	def check_crafting_value()
		@crafting_mutex ||= Mutex.new
		@crafting_mutex.synchronize do
			if @state == :crafting && @time_crafting_started.nil? || @crafting_recipe_and_count.nil?
				@state = nil
				@time_crafting_started = nil
				@crafting_recipe_and_count = nil
				false
			else
				true
			end
		end
	end
	# チェック(そのブロックで作れるのか、そのアイテムで作れるのか、など)はHandlerにて行う
	def start_crafting(recipe_and_count)
		@crafting_mutex ||= Mutex.new
		@crafting_mutex.synchronize do
			return "「あれ、作業班はもうなにか作っているみたいです」" if @state == :crafting
			@time_crafting_started = Time.now
			@crafting_recipe_and_count = recipe_and_count
			@state = :crafting
			nil
		end
	end
	def check_crafting_and_finish()
		@crafting_mutex ||= Mutex.new
		@crafting_mutex.synchronize do
			unless @state == :crafting && @time_crafting_started && @crafting_recipe_and_count
				@state = nil
				@time_crafting_started = nil
				@crafting_recipe_and_count = nil
				@log.add_text(self, nil, "エラーが発生したため、クラフトを打ち切りました。")
				return
			end
			
			# まだできてない
			return if Time.now - @time_crafting_started < @crafting_recipe_and_count.craft_time
			
			recipe_and_count = @crafting_recipe_and_count
			@state = nil
			@time_crafting_started = nil
			@crafting_recipe_and_count = nil
			
			recipe_and_count.need_items.each{|item,count|@items[item] -= count}
			recipe_and_count.products_times_count.each{|item,count|add_item(true, "クラフトで", item, count)}
			@log.add_text(self, "「アイテムを作り終えました！」", "「アイテムを作り終えました！」")
		end
	end
	def cancel_crafting()
		@crafting_mutex ||= Mutex.new
		@crafting_mutex.synchronize do
			return unless @state == :crafting
			@state = nil
			@time_crafting_started = nil
			@crafting_recipe_and_count = nil
		end
	end
	def remaining_craft_time
		@time_crafting_started + @crafting_recipe_and_count.craft_time - Time.now
	end
	
	def weaken_at_win(sync_log, enemy)
		# rateの範囲は、敵が強いほど0に、弱いほど大きくなる
		rate = 1.0 * force / enemy.force
		ave = (@soldier ** (1/4.0)) / (rate ** 1.5) * 3
		count = (ave*rand(1/1.5..1.5)*rand(1/1.5..1.5)*rand(1/1.5..1.5)).ceil
		if count != 0
			@soldier += count
			@log.add_text(self, !sync_log && "「戦闘に勝利しました！」", "戦闘に勝利し、`#{count}`人が加わりました！")
		end
	end
	MIN_SOLDIER = 6
	def weaken_at_lose(sync_log, enemy)
		count = rand(0..@soldier/(@soldier**0.3 + 1)).to_i
		if @soldier-count < MIN_SOLDIER # MIN_SOLDIER人以下にならないようにする
			count = @soldier-MIN_SOLDIER
		end
		if count != 0
			@soldier -= count
			@log.add_text(self, !sync_log && "「残念ながら、戦闘に敗北してしまいました・・・」", "戦闘に敗北し、残念ながら`#{count}`人が去っていきました・・・")
		end
	end
	
	def add_item(sync, cause, item, count)
		@items[item] ||= 0
		@items[item] += count
		@log.add_item(self, sync, cause, item, count)
	end
	# text_to_notifyがnilのときは通知をしない
	def add_log(text_to_notify: nil, text:)
		@log.add_text(self, text_to_notify, text)
	end
	def get_log
		@log.to_s
	end
	def clear_log
		@log.clear
	end
end

=begin
2020年1月9日ごろのバージョンとの互換性
@force
=> soldierを受け取って、そのまま格納していた
=end
class NPCEnemy < GroupBase
	def force
		@soldier ||= @max_soldier ||= @force # 一時的な措置
		@soldier
	end
	def initialize(soldier)
		#@force = soldier
		@soldier = @max_soldier = soldier
	end
	
	def weaken_at_win(sync_log, enemy)
		@soldier ||= @max_soldier ||= @force # 一時的な措置
		@soldier -= 1
	end
	def weaken_at_lose(sync_log, enemy)
		@soldier ||= @max_soldier ||= @force # 一時的な措置
		@soldier = (@soldier * 0.6).round
	end
	def turn()
		@soldier ||= @max_soldier ||= @force # 一時的な措置
		@soldier += ((@max_soldier - @soldier) * 0.1).ceil unless @soldier == @max_soldier
	end
end
