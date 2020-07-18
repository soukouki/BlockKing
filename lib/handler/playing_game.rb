
require "timeout"
require "forwardable"

require_relative "../game_data/items_and_blocks"
require_relative "../game_data/texts"

module Handler

class PlayingGame
	extend Forwardable
	def_delegators :@ui, :kill_waiting_respons, :send_mention
	def_delegators :@group, :ui_related_data
	
	MACRO_CONFIRMATION_THRESHOLD_VALUE = 600
	
	def initialize(ui:, game_table:, group_id:, group_name:)
		@ui = ui
		@game_table = game_table
		@last_operation_time = Time.now
		@last_one_hour_act_number = 0
		# initializeで登録とかを済ませるのは少し気持ち悪い
		@group = game_table.group(group_id) || (
			g = Group.new(group_id, game_table)
			game_table.add_group(g)
			g
		)
		@group.name = group_name
		@add_msg = ""
	end
	
	def start()
		main_loop()
	end
	
	def msg(text)
		@ui.send_message(text)
	end
	
	def recently_operating?
		@last_operation_time > Time.now - 60
	end
	
	private

	def player_chooses(**choosing_pattern)
		choosing_items = @ui.choosing_items_class.new(
			**choosing_pattern, 
			Bexit: lambda do
				throw(:exit_main_loop)
			end
		)
		@ui.choose(choosing_items, callback: lambda do |message|
			# last_operation_timeは更新されてしまうので、必要
			@last_operation_elapsed_time = Time.now - @last_operation_time
			if @last_operation_time.hour != Time.now.hour || @last_operation_time.day != Time.now.day # 時が変わったら
				if @last_one_hour_act_number >= MACRO_CONFIRMATION_THRESHOLD_VALUE
					report(<<~EOS)
						__マクロ確認__
						#{@last_operation_time.month}月#{@last_operation_time.day}日#{@last_operation_time.hour}時台に`#{@group.name}`(#{@group.id})が#{@last_one_hour_act_number}回の操作を行いました。
					EOS
				end
				@last_one_hour_act_number = 0
			end
			@last_one_hour_act_number += 1
			@last_operation_time = Time.now
			$logger.info "@#{@group.name}(#{@group.id}) : #{message}"
			$logger.info "@#{@group.name}(#{@group.id}) : #{@last_operation_elapsed_time}s"
		end)
	end
	
	def main_loop()
		catch(:exit_main_loop) do
			loop do
				case @group.state
				when :starting_game
					@group.state = nil
					GameData::Story::STARTING_GAME.pass_text_to(@ui)
				when :winning_the_king
					@group.state = nil
					GameData::Story::WINNING_THE_KING.pass_text_to(@ui)
				when :being_deprived_of_king
					@group.state = nil
					GameData::Story::BEING_DEPRIVED_OF_KING.pass_text_to(@ui)
				when :crafting
					craft_view()
				else
					map()
				end
			end
		end
	end
	
	def pos
		@group.pos
	end
	def block
		@game_table.block(pos)
	end
	def ruler
		@game_table.ruler(pos)
	end
	def items
		@group.items
	end
	def adjacent_buildings
		x = pos.x
		y = pos.y
		p = ->(x,y){@game_table.block(AbPos.new(x,y)).class}
		[p[x+1,y],p[x-1,y],p[x,y+1],p[x,y-1]].uniq
	end
	
	def map()
		constant_text = <<~EOS
			#{PlayingGame.make_map(@group, @game_table)}
			現在の位置は(#{pos})、#{PlayingGame.direction_of_castle(pos)}
			移動は(`w`/`a`/`s`/`d`)
			アイテム・その他情報は(`i`)
		EOS
		block_text = if ruler == @group
			building = if block.empty?
				"施設を建設するには(`c`)"
			elsif block.is_a?(Building)
				<<~EOS
					アイテムをクラフトするには(`u`)
					施設を撤去するには(`v`)
				EOS
			else
				""
			end
			building+"\n"+<<~EOS
				現在このブロックを支配しています。
				移動した際は、支配は解除されます。
			EOS
		else
			<<~EOS
				このブロックを支配するには(`x`)
				#{PlayingGame.compare_force(@group.force, ruler.ambiguous_force)}相手でしょう。
			EOS
		end + if block.get_items_when_turning.nil?
			""
		else
			"ここのアイテムは"+block.remaining_items_text+"\n"
		end + if @game_table.groups_by_pos(pos).length == 1 # 自分を含めて
			""
		else
			"ここには"+(@game_table.groups_by_pos(pos)-[@group]).map{|g|"`#{g.name}`"}.join("、")+"がいます。\n"
		end
		
		application_tutorial(GameData::Tutorial.before_displaying_screen(@group))
		
		log_text = @add_msg + @group.get_log
		@add_msg = ""
		@group.clear_log()
		
		msg(constant_text+block_text+tips+log_text)

		loop do
			result = catch(:return_no_map) do
				player_chooses(
					w: ->{move(0, 1)},
					a: ->{move(-1, 0)},
					s: ->{move(0, -1)},
					d: ->{move(1, 0)},
					i: ->{items_view(); throw(:return_no_map)},
					x: ->{war()},
					c: ->{build_building()},
					v: ->{remove_building()},
					u: ->{craft_using_building()},
				)
				break true
			end
			break if result
		end
		
	end
	
	def tips
		return "" unless @last_operation_elapsed_time.nil? || @last_operation_elapsed_time > 60
		if rand(2)==0 # 50%
			"> <TIPS>\n"+
			GameData::TIPS_LIST
				.select{|text,level|level.include?(@group.tutorial_level)}
				.keys
				.sample
				.lines
				.map{|l|"> "+l}
				.join("")+
			"\n"
		else
			""
		end
	end
	
	def move(x, y)
		result = @group.move(@game_table, x, y)
		
		application_tutorial(GameData::Tutorial.after_moving(@group))
	end
	
	def items_view()
		text = if items.empty?
			"現在アイテムは持っていません。"
		else
			items.sort_by{|i,c|GameData::SORT_ORDER.find_index(i) || 0}.map{|i,c|"#{i} : #{c}"}.join("\n")
		end
		msg("```javascript\n兵士 : #{@group.soldier}\n"+text+"\n```")
	end
	
	def war()
		enemy = ruler
		if enemy == @group
			msg(<<~EOS)
				リーダー？もうここは支配済みですよ？
			EOS
			throw :return_no_map
		end
		
		result = @game_table.battle(@group)
		case result
		when :win
			@add_msg << "やった！勝ちました！\n"
			application_tutorial(GameData::Tutorial.after_winning(@group, block))
		when :lose
			@add_msg << "残念ながら負けてしまいました・・・\n"
		end
	end
	
	# チェックの一部はGroup#buildにて行っているので、いじるときはそっちも確認するように
	def build_building()
		unless block.empty?
			msg(<<~EOS)
				既に建物が立っていて、土地がありません・・・
			EOS
			throw :return_no_map
		end
		if ruler != @group
			msg(<<~EOS)
				ここを支配しているグループに邪魔されてしまいました・・・
			EOS
			throw :return_no_map
		end
		
		select_block = GameData::CAN_BUILD_LIST
			.map
			.with_index(1){|b, i|[i, b]}
			.to_h
		select_text = select_block
			.map do |index, (block_class, need_items)|
				can_build = need_items.all?{|item,count|(items[item]||0) >= count}
				block = block_class.new(@group, @game_table.calc_level(pos))
				"`#{index}` : "+(
					if can_build
						"**#{block.name}**(#{Item.count_by_items_hash_to_s(need_items, join_str:"、")}使う)"
					else
						"~~#{block.name}~~(#{not_enough_item_text(need_items)}必要)"
					end
				)
			end
			.join("\n")
		msg(<<~EOS)
			建物リスト
			#{select_text}
			`quit` `q` : 前の画面に戻る
		EOS
		player_chooses(
			quit: ->{},
			q:    ->{},
			process_checking_index: ->(index){select_block[index]},
			process_of_index: lambda do |index|
				catch(:return_inner_wait) do
					result_tuple(@group.build(@game_table, select_block[index][0].new(@group, @game_table.calc_level(pos))), :return_inner_wait)
				end
			end,
		)
	end
	
	def remove_building()
		result_tuple(@group.remove(@game_table))
	end
	
	def craft_using_building()
		if ruler != @group
			msg("「ここを支配してる奴らに邪魔されて出来ませんよ！」")
			throw :return_no_map
		end
		creatable_items = block
			.creatable_items
			.map
			.with_index(1) do |recipe, i|
				cc = recipe.can_craft?(block.class, adjacent_buildings, items)
				{index_or_underbar: (cc)? i : "_", recipe:recipe, can_craft:cc}
			end
		if creatable_items.empty?
			msg("「#{block}では何も作れないですよ？」")
			throw :return_no_map
		end
		creatable_items_text = creatable_items
			.map do |hash|
				recipe = hash[:recipe]
				can_craft = hash[:can_craft]
				"`#{hash[:index_or_underbar]}` : "+(
					finished_item_name = recipe
						.products_hash
						.map do |item,count|
							if can_craft
								"**#{item.name}**を`#{count}`"
							else
								"~~#{item.name}を`#{count}`~~"
							end
						end
						.join("、")
					not_enough_building = (recipe.auxiliary_buildings-adjacent_buildings).map(&:type_name).join("、")
					case [recipe.enough_items?(items), recipe.enough_adjacent_buildings?(adjacent_buildings)]
					when [true, true]
						"#{finished_item_name}「#{recipe.materials_to_s}使います！」"
					when [true, false]
						"#{finished_item_name}「隣のブロックに#{not_enough_building}が必要です！」"
					when [false, true]
						"#{finished_item_name}「あと#{not_enough_item_text(recipe.materials_hash)}必要です！」"
					when [false, false]
						"#{finished_item_name}「隣のブロックに#{not_enough_building}と、あと#{not_enough_item_text(recipe.materials_hash)}必要です！」"
					end
				)
			end
			.join("\n")
		msg(<<~EOS)
			レシピリスト
			#{creatable_items_text}
			`quit` `q` : 前の画面に戻る
		EOS
		
		player_chooses(
			quit: ->{},
			q:    ->{},
			_: ->{@add_msg << "「それを作るには、なにか足りないものがあるみたいですよ？」"},
			process_checking_index: lambda do |index|
				creatable_items.any?{|hash|hash[:index_or_underbar] == index}
			end,
			process_of_index: lambda do |index|
				recipe = creatable_items.select{|hash|hash[:index_or_underbar] == index}.first[:recipe]

				max_can_craft_count = recipe.materials_hash.map{|i,c|items[i] / c}.min
				msg(<<~EOS)
					「#{recipe.products_hash.map{|i,c|"#{i.name}を`#{c}`"}.join("、")}を何回作りますか・・？」
					1回あたり必要アイテム数
						#{recipe.materials_to_s(join_str:"\n\t")}
					`0` - `#{max_can_craft_count}` の中から選んでください。
				EOS
				
				player_chooses(
					quit: ->{},
					q:    ->{},
					process_checking_index: ->(i){i >= 0 && i <= max_can_craft_count},
					process_of_index: lambda do |count|
						if count == 0
							@add_msg << "「あれ、やっぱ何も作らないんですか？」"
							next
						end
						recipe_and_count = RecipeAndCount.new(recipe, count, @group)
						text_or_nil = @group.start_crafting(recipe_and_count)
						msg(text_or_nil) unless text_or_nil.nil?
					end
				)
			end,
		)
	end
	
	# 名前が気に入らない・・・
	def result_tuple(arr, throw_symbol = :return_no_map)
		result, text = arr
		if result
			@add_msg << text
		else
			msg(text)
			throw throw_symbol
		end
	end
	
	def not_enough_item_text(need_items)
		need_items
			.map{|i,c|[i,c,items[i]||0]}
			.select{|(i,c,hc)|c>hc}
			.map{|(i,c,hc)|"#{i}があと`#{c-hc}`"}
			.join("、")
	end
	
	def craft_view()
		return unless @group.check_crafting_value()
		remaining_time = @group.remaining_craft_time
		
		if remaining_time.positive?
			begin
				Timeout.timeout(remaining_time) do
					crafting_recipe_and_count = @group.crafting_recipe_and_count
					progress = remaining_time / crafting_recipe_and_count.craft_time
					
					msg(<<~EOS)
						```
						#{crafting_recipe_and_count.products_to_s(inline_code_count: false)}
						
						素材 :  #{crafting_recipe_and_count.materials_to_s(inline_code_count: false)}
						必要時間 : #{crafting_recipe_and_count.craft_time.to_i}秒(残り#{remaining_time.to_i}秒)
						
						完成予想 : #{(Time.now + remaining_time).strftime("%m月%d日%H時%M分")}頃
						進捗 : |#{"*"*((1-progress)*20).to_i}#{"-"*(progress*20).to_i}|
						```
						
						アイテム・その他情報は(`i`)
						クラフト中止は(`c`)
					EOS
					
					player_chooses(
						i: ->{items_view()},
						c: lambda do
							@group.cancel_crafting()
							@add_msg << "クラフトをキャンセルしました。"
						end,
					)
				end
			rescue Timeout::Error
				# 時間になりました。
			end
		end
		
		@group.check_crafting_and_finish()
	end
	
	def application_tutorial(tutorial_levels_and_texts)
		return if tutorial_levels_and_texts.empty?
		tutorial_levels_and_texts.each do |item|
			@group.tutorial_level = item.level
			@add_msg << item.text.lines.map{|l|"> "+l}.join("")
		end
	end
	
	class << self
		def make_map(group, game_table)
			pos = group.pos
			l = lambda do |x, y|
				ypos = (x==0 && y==0)? "Y" : " "
				game_table.is_there_a_group_other_than_myself?(group, pos.diff_to_ab_pos(x, y))? " #{ypos}G " : " #{ypos}  "
			end
			ll = lambda do |y|
				"   |"+
				5.times
					.map{|i|l[i-2, y]}
					.join("|")+"|"
			end
			o = lambda do |x, y|
				game_table.block(pos.diff_to_ab_pos(x, y)).map_name
			end
			ol = lambda do |y|
				fullwidth_count = 0
				"   |"+
				5.times
					.map{|i|i-2}
					.map{|x|[x, o[x, y]]}
					.map do |(x, s)|
						fullwidth_count += s.length - s.count(" 0-9a-zA-Z")
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
				Y:現在地, G:他のグループ
			EOS
		end
		
		def compare_force(group_force, enemy_force)
			# インフレしたらいろいろ入れてみたい
			case 1.0 * enemy_force / group_force
			when 0..0.001
				"敵は噂を聞いただけで逃げていく"
			when 0..0.01
				"敵が裸足で逃げていく"
			when 0..0.1
				"敵が逃げていく"
			when 0..0.3
				"敵は余裕で勝てる"
			when 0..0.5
				"敵はほぼ確実に勝てる"
			when 0..0.7
				"敵はおそらく勝てる"
			when 0..0.9
				"敵はもしかしたら勝てる"
			when 0..(1/0.9)
				"敵は勝つか負けるかわからない"
			when 0..(1/0.7)
				"敵はもしかしたら負ける"
			when 0..(1/0.5)
				"敵はおそらく負ける"
			when 0..(1/0.3)
				"敵はほぼ確実に負ける"
			when 0..(1/0.1)
				"敵は余裕で負ける"
			when 0..(1/0.01)
				"敵は逃げたくなるような"
			when 0..(1/0.001)
				"敵は裸足で逃げたくなるような"
			else
				"敵は噂だけで逃げたくなるような"
			end
		end
		
		def direction_of_castle(pos)
			x, y = [pos.x, pos.y]
			return "" if pos == AbPos::CENTER
			l = Math.sqrt(x*x+y*y)
			ac_ang = Math.acos(x/l)*180/Math::PI
			ang = (y<0)? 360-ac_ang : ac_ang
			piece = 360.0/(8*2)
			str = ["西", "南西", "南", "南東", "東", "北東", "北", "北西"][((ang/piece)/2).round % 8]
			"王城は"+str+"の方向。"
		end
	end
end
 
class << Handler
	def notify(group, text)
		self::FUNCTION_TO_NOTIFY.call(group.ui_related_data, text)
	end
end

end # module
