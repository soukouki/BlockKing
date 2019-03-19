
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
			case rand(2)
			when 1
				[Block::IRON_MINE, Block::FOREST].sample
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
