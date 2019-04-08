
require "discordrb"
require_relative "../lib/discord_ui_base"

class UI < DiscordUIBase
	attr_reader :latest_msg_time
	attr_accessor :channel
	
	def initialize(*args)
		@latest_msg_time = Time.now
		super
	end
	
	def msg(text)
		server = @channel.server
		print "#{Time.now} : #{server&.name}(#{server&.id})##{@channel.name}(#{@channel.id})@#{@user.name}(#{@user.id}) : #{text.lines.first.chomp}\r"
		@latest_msg_time = Time.now
		characters_count_or_less_text(2000, text).each do |p_text|
			@channel.send_message(p_text)
		end
	end
	
	def start(game_table)
		@game_table = game_table
		@group = game_table.group(@user.id) || (
			l = Group.new(@user.id, game_table)
			game_table.add_group(l)
			l
		)
		@group.name = @user.name
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
				@group.state = nil
				first_story()
			when :ending
				@group.state = :ending2
				ending_story1()
				break
			when :ending2
				@group.state = nil
				ending_story2()
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
		slow_message(<<~EOS)
			・・・・・・・・・・
			
			戦いばかりが続くこの国。
			王の力は弱まり、いくつもの兵を持った集団が治めるこの国。
			その中のある村で・・・・・
			
			この青年は夢を持っている。
			他の集団を倒し、王を倒し、この国の新たな王として君臨する夢を。
			この小さな村から始まる、壮大な道。
			
			「リーダー！そんなのんびりしてたら、おいてっちゃいますよー！？」
		EOS
	end
	
	def ending_story1()
		slow_message(<<~EOS)
			・・・・・・・・・・
			
			
			戦いばかりが続いていたこの国。
			その後王は倒され、新たな王が誕生したこの国。
			その中心の城の中・・・・・
			
			この青年は夢を叶えた。
			他の集団を倒し、王を倒し、この国の新たな王として君臨する夢を。
			この大きな城で終わる、壮大な道。
			
			「リーダー...ここまで、長かったですね...
			また、新しい夢を作って、叶えていきましょう！」
			
			<ゲームクリアです！>
			(`Bk`で続きます。)
		EOS
		sleep 5
	end
	
	def ending_story2()
		slow_message(<<~EOS)
			・・・・・・・・・・
			
			数年がたったある日、突如それは起こった。
			部下の一人が、兵士を伴って反乱を起こしたのだ。
			通路で応戦し、
			反乱に加わらなかった兵士と合流し・・・
			
			なんとか隠し通路から逃げ切ることは出来た。
			だが、
			王の権力は乗っ取られ、
			兵士も半分になり、
			武器は兵士が持っていた分のみ。
			
			果たして、この青年は王座を奪還することができるのだろうか・・・？
			
			「減ったとしても、貴方を信頼してついてきてくれた仲間がいるんです！
			諦めずに行かないと！」
		EOS
	end
	
	def map()
		constant_text = <<~EOS
			#{@group.make_map(@game_table)}
			現在の位置は(#{pos})、#{Group.direction_of_castle(pos)}
			移動は(`w`/`a`/`s`/`d`)
			アイテム・その他情報は(`i`)
		EOS
		block_text = if ruler == @group
			building = if block.empty?
				"施設を建設するには(`c`)"
			elsif block.is_a?(Building)
				<<~EOS
					施設を使用するには(`u`)
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
				#{@group.compare_force(ruler)}相手でしょう。
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
		if @group.tutorial_level == 0
			@group.tutorial_level = 1
			@add_msg << <<~EOS
				<チュートリアル>
				リーダー！はじめまして！
				移動の仕方は、この画面から
					上(北)には`w`
					左(西)には`a`
					右(東)には`d`
					下(南)には`s` です！
			EOS
		end
		
		log_text = @add_msg + @group.log.to_s
		@add_msg = ""
		@group.log.clear()
		
		msg(constant_text+(block_text||"")+"\n"+log_text) # よくわからないけど、eachをつけないとうまく動かなかった
		wait_respons do |res|
			catch(:return_no_map) do
				case res
				when "w", "W"
					move(0, 1)
				when "a", "A"
					move(-1, 0)
				when "s", "S"
					move(0, -1)
				when "d", "D"
					move(1, 0)
				when "i", "I"
					text = if items.empty?
						"現在アイテムは持っていません。"
					else
						items.sort_by{|i,c|GameData::SORT_ORDER.find_index(i) || 0}.map{|i,c|"#{i} : `#{c}`"}.join("\n")
					end
					msg("兵士 : `#{@group.soldier}`\n"+text)
					throw :return_no_map
				when "x", "X"
					war()
				when "c", "C"
					build_building()
				when "v", "V"
					remove_building()
				when "u", "U"
					craft_using_building()
				end
			end
		end
	end
	
	def move(x, y)
		if @group.tutorial_level == 1
			@group.tutorial_level = 2
			@add_msg << <<~EOS
				<チュートリアル>
				無事に移動できました！
				敵は王城から離れるほど弱くなります！自分たちにあった強さの敵を選びましょう！
			EOS
		end
		result = @group.move(@game_table, x, y)
	end
	
	def war()
		enemy = ruler
		if enemy == @group
			msg(<<~EOS)
				リーダー？もうここは支配済みですよ？
			EOS
			throw :return_no_map
		end
		result = @game_table.war(@group)
		case result
		when :win
			@add_msg << "やった！勝ちました！\n"
			if @group.tutorial_level == 2 || @group.tutorial_level == 3 and block.empty?
				@group.tutorial_level = 4
				@add_msg << <<~EOS
					<チュートリアル>
					リーダー！ここにはなにか建物を建てられそうですよ！
					炉を作り、銅の剣を作りましょう！
					とりあえず、炉を作るには木材が必要ですね！
				EOS
			end
			if @group.tutorial_level == 2 && !block.empty?
				@group.tutorial_level = 3
				@add_msg << <<~EOS
					<チュートリアル>
					上手く支配できましたね！それにしてもここは資源が採れそうです、ここで1分くらい待ってくださいね！私が資源を採っておきます。
					ちなみに、あっちの方には更地があって、なにか建てられそうですよ？帰ってきたら支配してみましょうよ！
				EOS
			end
			true
		when :lose
			@add_msg << "残念ながら負けてしまいました・・・\n"
		end
	end
	
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
			.with_index{|b, i|[(i+?a.ord).chr, b]}
			.to_h
		select_text = select_block
			.map do |char, (block_class, need_items)|
				can_build = need_items.all?{|item,count|(items[item]||0) >= count}
				block = block_class.new(@group, @game_table.calc_level(pos))
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
			sel = select_block[res.to_str.downcase]
			catch(:return_inner_wait) do
				unless sel.nil?
					result_tuple(@group.build(@game_table, sel[0].new(@group, @game_table.calc_level(pos))), :return_inner_wait)
				end
			end
		end
		true
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
			recipe = creation_items[res.to_str.downcase]
			catch(:return_inner_wait) do
				unless recipe.nil?
					result_tuple(@group.craft_using_building(@game_table, recipe), :return_inner_wait)
				end
			end
		end
		if @group.tutorial_level == 4 && (items[GameData::COPPER_SWORD] || 0) > 0
			@group.tutorial_level = 5
			@add_msg << <<~EOS
				<チュートリアル>
				銅の剣ができました！この調子で鉄の剣も作っていきましょう！
				ちなみに、敵が強いほどいっぱいアイテムが手に入るそうですよ？
			EOS
		end
		true
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
