
class GameTable
	attr_reader :groups, :kings_history
	def initialize()
		@block_table = {}
		@block_table_mutex = Mutex.new
		@ruler_table = {}
		@ruler_table_mutex = Mutex.new
		@groups = {}
		@game_level = 100
		@kings_history = []
	end
	
	def group(id)
		@groups[id]
	end
	def groups_by_pos(pos)
		@groups.values.select{|g|g.pos == pos}
	end
	def add_group(group)
		@groups[group.id] = group
	end
	
	def block(pos)
		@block_table_mutex.synchronize do
			@block_table[pos] ||= select_object(pos)
		end
	end
	def set_block(pos, new_block)
		@block_table_mutex.synchronize do
			@block_table[pos] = new_block
		end
	end
	
	def ruler(pos)
		@ruler_table_mutex.synchronize do
			@ruler_table[pos] ||= @block_table[pos].block_enemy ||= initial_ruler(pos)
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
					# 2020年1月9日ごろのバージョンとの互換性
					# rulerはnilの可能性がある
					next if ruler.nil? || !ruler.is_a?(Group) # 一時的な措置
					# これから先の処理はGameTableでやるべきではないかもしれない
					block = block(pos)
					get_item, count = block.turn_items(ruler)
					next if get_item.nil?
					is_few_remaining_item = block.few_remaining_item?
					block.remaining_items -= count
					ruler.add_item(false, "#{block}を支配し", get_item, count)
					if !is_few_remaining_item && block.few_remaining_item?
						ruler.log.add_text(ruler, "「今支配してるブロックの残りアイテムがだいぶ少なくなってきました。そろそろ移動してもいい頃じゃないですか？」",
							"支配しているブロックの残りアイテムが少なくなってきました。")
					end
				end
				.each do |pos, ruler|
					# ユーザーグループが移動するときにはblock_enemyを設定してあるので、ruler_tableを見るだけで良い
					# ruler_tableにいないblock_enemyは、敵がいて回復できない設定
					# 2020年1月9日ごろのバージョンとの互換性
					# rulerはnilの可能性がある
					next if ruler.nil?# 一時的な措置
					ruler.turn()
				end
		end
		
		@groups
			.values
			.select{|group|group.state == :crafting}
			.each do |group|
				group.check_crafting_and_finish()
			end
	end
	
	def war(group)
		pos = group.pos
		enemy = ruler(pos)
		enemy_rate = rand(0.9..1.1)*rand(0.9..1.1)*rand(0.9..1.1)
		group_rate = rand(0.9..1.1)*rand(0.9..1.1)*rand(0.9..1.1)
		case (enemy.force * enemy_rate) <=> (group.force * group_rate)
		when 1, 0 # enemyの勝利
			enemy.weaken_at_win(false, group)
			group.weaken_at_lose(true, enemy)
			:lose
		when -1   # groupの勝利
			enemy.weaken_at_lose(false, group)
			group.weaken_at_win(true, enemy)
			set_ruler(pos, group)
			if pos==AbPos::CENTER
				group.state = :ending
				game_clear(group)
			end
			:win
		end
	end
	
	def is_there_a_group_other_than_myself?(group, pos)
		not @groups.values.reject{|l|l == group}.select{|l|l.pos == pos}.empty?
	end
	
	# 10進むごとに3倍の戦力、マンハッタン距離を使用
	GO_DISTANCE = 10
	UP_MAGNIFICATION = 3
	def initial_pos(force)
		p_or_m = ->{rand(2)*2-1}
		len = GO_DISTANCE*Math.log(1.0*@game_level/force, UP_MAGNIFICATION)
		return AbPos.new(0, 0) if len < 0
		x_l = rand(0..len).round
		y_l = (len-x_l).round
		AbPos.new(x_l*p_or_m[], y_l*p_or_m[])
	end
	def calc_level(pos)
		len = pos.x.abs + pos.y.abs
		return @game_level if len == 0
		(
			1.0 *
			@game_level /
			UP_MAGNIFICATION**(1.0*len/GO_DISTANCE) *
			rand(0.7..(1/0.7))
		).ceil # 取れるアイテム数の関係
	end
	
	private
	
	def select_object(pos)
		case pos
		when AbPos::CENTER
			GameData::CASTLE
		else
			case rand(10)
			when 0, 1, 2
				case rand(14)
				when 0, 1, 2
					GameData::IRON_MINE
				when 3, 4, 5
					GameData::COPPER_MINE
				when 6, 7, 8
					GameData::MARSH
				when 9
					GameData::LIME_MINE
				when 10, 11
					GameData::COAL_MINE
				when 12
					GameData::FIRE_CRYSTAL_MINE
				else
					if rand(4) == 0
						GameData::GOLD_MINE
					else
						GameData::SILVER_MINE
					end
				end
			when 3, 4, 5
				GameData::FOREST
			else # 6, 7, 8, 9
				GameData::EMPTY
			end
		end.new(calc_level(pos))
	end
	
	def initial_ruler(pos)
		case pos
		when AbPos::CENTER
			NPCEnemy.new(@game_level)
		else
			NPCEnemy.new(calc_level(pos))
		end
	end
	
	def game_clear(cleared_group)
		@block_table_mutex.synchronize do
			@ruler_table_mutex.synchronize do
				@block_table
					.select{|pos,block|block.is_a?(Building)}
					.each do |pos, block|
						block.need_items.each do |item, count|
							builder = block.builder
							builder.add_item(false, "#{block}を建てていたため", item, count)
						end
					end
				@ruler_table = {} # ルーラー初期化！
				@block_table = {} # ブロック初期化！
				@game_level = [[@game_level*2, cleared_group.force].max, @game_level*10].min # 最低x2, 最高x10
				@groups.each do |id, group|
					group.pos = initial_pos(group.force)
					group.log.add_text(group, nil, <<~EOS)
						`#{cleared_group.name}`によって王城が攻略され、ゲームがクリアされました！
						それによって、ブロック・位置などが初期化され、敵が強くなりました！
					EOS
				end
				@kings_history << cleared_group
				cleared_group.rebellion_occurred()
			end
		end
	end
end
