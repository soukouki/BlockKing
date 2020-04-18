
class GameTable
	attr_reader :groups, :kings_history, :game_level
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
		if pos == AbPos::CENTER && !@kings_history.empty?
			return @kings_history.last
		end
		@ruler_table_mutex.synchronize do
			@ruler_table[pos] ||= block(pos).block_enemy ||= initial_ruler(pos)
		end
	end
	def set_ruler(pos, new_ruler)
		@ruler_table_mutex.synchronize do
			@ruler_table[pos] = new_ruler
		end
	end
	
	def turn()
		collect_item_in_turn()
		check_crafting_in_turn()
		update_game_level()
	end
	
	def battle(group)
		battling_class = if group.pos == AbPos::CENTER
			BattleForTheKing
		else
			Battle
		end
		battling = battling_class.new(game_table: self, ruler: ruler(group.pos), challenger: group)
		battling.battle
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
	
	def game_clear(cleared_group)
		@ruler_table_mutex.synchronize do
			
			cleared_group.add_log(
				text: "`#{cleared_group.name}`によって王城が攻略され、ゲームがクリアされました！"
			)
		end
		@kings_history.last&.add_item(false, "王城からアイテムを持ち出せ", GameData::KINGS_MEMORIAL_ITEMS.sample, 1)
		@kings_history << cleared_group
	end
	
	private
	
	def collect_item_in_turn()
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
						ruler.add_text(
							text_to_notify: "「今支配してるブロックの残りアイテムがだいぶ少なくなってきました。そろそろ移動してもいい頃じゃないですか？」",
							text: "支配しているブロックの残りアイテムが少なくなってきました。",
						)
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
	end
	def check_crafting_in_turn()
		@groups
			.values
			.select{|group|group.state == :crafting}
			.each do |group|
				group.check_crafting_and_finish()
			end
	end
	NUMBER_OF_LANKERS_TO_COUNT_FOR_UPDATE_GAME_LEVEL = 4 # 5位まで入れる
	def update_game_level()
		_first, *other_ranker = @groups
			.values
			.map(&:force)
			.sort
			.reverse
			.take(NUMBER_OF_LANKERS_TO_COUNT_FOR_UPDATE_GAME_LEVEL+1)
		number_of_weight = (NUMBER_OF_LANKERS_TO_COUNT_FOR_UPDATE_GAME_LEVEL-1).times.map{|i|i**2}.sum
		sum_of_force = other_ranker
			.map.with_index(2) do |force,rank|
				# 2位は4*4=16、3位は3*3=9、4位は2*2=4、5位は1*1=1の重さつきの平均
				force * (NUMBER_OF_LANKERS_TO_COUNT_FOR_UPDATE_GAME_LEVEL - rank + 1)**2
			end
			.sum
		groups_level = sum_of_force / number_of_weight
		if groups_level > @game_level * 3
			$logger.info "グループの兵力が規定を超えたため、ゲームレベルの更新とブロックとルーラーの初期化を行います"
			clear_blocks_and_rulers(groups_level)
		end
	end
	def clear_blocks_and_rulers(new_game_level)
		@block_table_mutex.synchronize do
			@ruler_table_mutex.synchronize do
				# 後始末
				@block_table
					.select{|pos,block|block.is_a?(Building)}
					.each do |pos, block|
						block.need_items.each do |item, count|
							builder = block.builder
							builder.add_item(false, "#{block}を建てていたため", item, count)
						end
					end
				# ゲームレベルの変更と初期化とメッセージ
				@game_level = new_game_level
				@ruler_table = {} # ルーラー初期化！
				@block_table = {} # ブロック初期化！
				@groups.each do |id, group|
					group.pos = initial_pos(group.force)
					group.add_log(
						text_to_notify: "「あっ、何かが起きたようですよ！」",
						text: "天変地異によって、グループは見知らぬ土地へ運ばれてしまいました！",
					)
				end
			end
		end
	end
	
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
	
end
