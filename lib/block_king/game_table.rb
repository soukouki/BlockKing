
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
					next if ruler.nil? || !ruler.is_a?(Group)
					block = block(pos)
					get_item, count = block.turn_items(ruler)
					next if get_item.nil?
					block.remaining_items -= count
					ruler.add_item(false, "#{block}を支配し", get_item, count)
				end
		end
	end
	
	def war(group)
		pos = group.pos
		enemy = ruler(pos)
		case (enemy.force * rand(0.95..1.05)) <=> (group.force * rand(0.95..1.05))
		when 1, 0 # enemyの勝利
			enemy.weaken_at_win(false)
			group.weaken_at_lose(true)
			:lose
		when -1   # groupの勝利
			enemy.weaken_at_lose(false)
			group.weaken_at_win(true)
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
	
	def initial_pos(force)
		r = rand(0..Math::PI*2)
		AbPos.new(*[Math.cos(r), Math.sin(r)].map{|x|(x*((@game_level/force)+1)).ceil})
	end
	
	def calc_level(pos)
		(
			1.0 *
			@game_level /
			Math.sqrt((pos.x ** 2).abs+(pos.y ** 2).abs+1) *
			rand(0.7..(1/0.7))
		).ceil # 取れるアイテム数の関係
	end
	
	private
	
	def select_object(pos)
		case pos
		when AbPos::CENTER
			GameData::CASTLE
		else
			case rand(5)
			when 0
				case rand(10)
				when 0, 1, 2
					GameData::IRON_MINE
				when 3, 4, 5
					GameData::COPPER_MINE
				when 6, 7, 8
					GameData::MARSH
				else # 9
					GameData::FIRE_CRYSTAL_MINE
				end
			when 1, 2
				GameData::FOREST
			else # 3, 4
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
				@block_table.each do |pos, block|
					if block.is_a?(Building)
						block.need_items do |item, count|
							block.builder.add_item(false, "#{block}を建て", item, count)
						end
					end
				end
				@block_table = {} # ブロック初期化！
				@ruler_table = {} # ルーラー初期化！
				@game_level = [@game_level*2, cleared_group.force].max
				@groups.each do |id, group|
					group.pos = initial_pos(group.force)
					group.log.add_text(false, <<~EOS)
						`#{group.name}`によって王城が攻略され、ゲームがクリアされました！
						それによって、ブロック・位置などが初期化され、すべての敵が強くなりました！
					EOS
				end
				@kings_history << cleared_group
				cleared_group.initial_soldier_and_items()
			end
		end
	end
end
