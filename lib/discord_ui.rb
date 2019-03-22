
require "discordrb"
require_relative "../lib/discord_ui_base"

class UI < DiscordUIBase
	private def msg(text)
		server = @channel.server
		puts "#{Time.now} : #{server&.name}(#{server&.id})##{@channel.name}(#{@channel.id})@#{@user.name}(#{@user.id}) : #{text.lines.first}"
		@channel.send_message(text)
	end
	
	def start(game_table)
		@game_table = game_table
		@group = game_table.group(@user.id) || (
			l = Group.new(@user.id, @user.name)
			game_table.add_group(l)
			l
		)
		@add_msg = ""
		@exists_log = false
		@group.log.callback = lambda do |sync|
			if !@exists_log && !sync
				@exists_log = true
				msg("現在、ログがあります。確認するには(`Bk`)")
			end
		end
		loop do
			case @group.state
			when :first_story
				first_story()
				@group.state = nil
			when :ending
				ending_story()
				@group.state = nil
			else
				map()
			end
		end
	end
	
	private
	
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
	
	def first_story()
		text = <<~EOS
			・・・・・・・・・・
			
			戦いばかりが続くこの国。
			王の力は弱まり、いくつもの兵を持った集団が治めるこの国。
			その中のある村で・・・・・
			
			この青年は夢を持っている。
			他の集団を倒し、王を倒し、この国の新たな王として君臨する夢を。
			この小さな村から始まる、壮大な道。
			
			「リーダー！そんなのんびりしてたら、おいてっちゃいますよー！？」
		EOS
		text
			.lines
			.map(&:chomp)
			.each{|line|sleep 1; line.empty? || msg(line)}
	end
	
	def ending_story()
		text = <<~EOS
			・・・・・・・・・・
			
			
			戦いばかりが続いていたこの国。
			その後王は倒され、新たな王が誕生したこの国。
			その中心の城の中・・・・・
			
			この青年は夢を叶えた。
			他の集団を倒し、王を倒し、この国の新たな王として君臨する夢を。
			この大きな城で終わる、壮大な道。
			
			「リーダー...ここまで、長かったですね...
			また、新しい夢を作って、叶えていきましょう！」
		EOS
		text
			.lines
			.map(&:chomp)
			.each{|line|sleep 1; line.empty? || msg(line)}
		sleep 5
	end
	
	def map()
		constant_text = <<~EOS
			#{@group.make_map(@game_table)}
			現在の位置は(#{pos})です。#{Group.direction_of_castle(pos)}
			移動は(`w`/`a`/`s`/`d`)
			アイテム・その他情報は(`i`)
		EOS
		block_text = if ruler == @group
			building = if block==Block::EMPTY
				"施設を建設するには(`c`)"
			else
				if Block::CAN_BUILD_LIST[block]
					<<~EOS
						施設を使用するには(`u`)
						施設を撤去するには(`v`)
					EOS
				else
					""
				end
			end
			building+"\n"+<<~EOS
				現在このブロックを支配しています。
				移動した際は、支配は解除されます。
			EOS
		else
			<<~EOS
				このブロックを支配するには(`x`)
				敵は#{@group.compare_force(ruler)}相手でしょう。
			EOS
		end
		
		log_text = @add_msg + @group.log.to_s
		@add_msg = ""
		@group.log.clear()
		
		msg(constant_text+(block_text||"")+"\n"+log_text) # よくわからないけど、eachをつけないとうまく動かなかった
		wait_respons do |res|
			catch(:return_no_map) do
				case res
				when "w"
					move(0, 1)
				when "a"
					move(-1, 0)
				when "s"
					move(0, -1)
				when "d"
					move(1, 0)
				when "i"
					text = if items.empty?
						"現在アイテムは持っていません。"
					else
						items.map{|i,c|"#{i} : `#{c}`"}.join("\n")
					end
					msg(text+"\n兵士 : `#{@group.soldier}`")
					throw :return_no_map
				when "x"
					war()
				when "c"
					build_building()
				when "v"
					remove_building()
				when "u"
					craft_using_building()
				end
			end
		end
	end
	
	def move(x, y)
		result = @group.move(@game_table, x, y)
	end
	
	def war()
		enemy = ruler
		if enemy == @group
			msg(<<~EOS)
				この場所は既に支配しています。
			EOS
			throw :return_no_map
		end
		result = @game_table.war(@group)
		case result
		when :win
			@add_msg << "やった！勝ちました！\n"
		when :lose
			@add_msg << "残念ながら負けてしまいました・・・\n"
		end
	end
	
	def build_building()
		if block != Block::EMPTY
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
		
		select_block = Block::CAN_BUILD_LIST
			.map
			.with_index{|b, i|[(i+?a.ord).chr, b]}
			.to_h
		select_text = select_block
			.map do |char, (block, need_items)|
				can_build = need_items.all?{|item,count|(items[item]||0) >= count}
				"`#{char}` : "+(
					if can_build
						"#{block.name}(#{need_items.map{|item,count|"#{item}を`#{count}`"}.join("、")}使う)"
					else
						"#{"■"*block.name.length}(#{not_enough_item_text(need_items)}必要)"
					end
				)
			end
			.join("\n")
		msg(<<~EOS)
			建物リスト
			#{select_text}
			`ret` : 前の画面に戻る
		EOS
		wait_respons() do |res|
			if res == "ret"
				return true
			end
			sel = select_block[res.to_str]
			catch(:return_inner_wait) do
				unless sel.nil?
					result_tuple(@group.build(@game_table, sel[0]), :return_inner_wait)
				end
			end
		end
	end
	
	def remove_building()
		result_tuple(@group.remove(@game_table))
	end
	
	def craft_using_building()
		if ruler != @group
			msg("「ここを支配してる奴らに邪魔されて出来ませんよ！」")
			throw :return_no_map
		end
		creation_items = block
			.creation_items
			.map
			.with_index{|recipe, i|[(i+(?a.ord)).chr, recipe]}
			.to_h
		if creation_items.empty?
			msg("「#{block}では何も作れないですよ？」")
			throw :return_no_map
		end
		creation_items_text = creation_items
			.map do |char, (need_items, finished_items)|
				can_build = need_items.all?{|item,count|(items[item]||0) >= count}
				"`#{char}` : "+(
					finished_item_name = finished_items.map{|item,count|"#{(can_build)? item.name : "■"*item.name.length}を`#{count}`"}.join("、")
					if can_build
						"#{finished_item_name}(#{need_items.map{|item,count|"#{item}を`#{count}`"}.join("、")}使う)"
					else
						"#{finished_item_name}(#{not_enough_item_text(need_items)}必要)"
					end
				)
			end
			.join("\n")
		msg(<<~EOS)
			レシピリスト
			#{creation_items_text}
			`ret` : 前の画面に戻る
		EOS
		recipe = wait_respons() do |res|
			if res == "ret"
				return true
			end
			recipe = creation_items[res.to_str]
			catch(:return_inner_wait) do
				unless recipe.nil?
					result_tuple(@group.craft_using_building(@game_table, recipe), :return_inner_wait)
				end
			end
		end
	end
	
	# 名前が気に入らない・・・
	def result_tuple(arr, throw_symbol = :return_no_map)
		result, text = arr
		if result
			@add_msg << text
			true
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
end
