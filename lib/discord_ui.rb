
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
		@exists_log = false
		@group.log.callback do |log|
			unless @exists_log
				@exists_log = true
				msg("現在、ログがあります。確認するには(`Bk`)")
			end
		end
		loop do
			case @group.state
			when :first_story
				#first_story()
				@group.state = nil
			when :ending
				ending_story()
				@group = nil
				break
			else
				map()
			end
		end
	end
	
	private
	
	def pos
		@group.pos
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
			
			
			(END)
			(テストプレイ終了です。DMください)
		EOS
		text
			.lines
			.map(&:chomp)
			.each{|line|sleep 1; line.empty? || msg(line)}
	end
	
	def map()
		block = @game_table.block(pos)
		constant_text = <<~EOS
			#{@group.make_map(@game_table)}
			現在の位置は(#{pos})です。#{Group.direction_of_castle(pos)}
			移動は(`w`/`a`/`s`/`d`)
			アイテム一覧は(`i`)
		EOS
		ruler = @game_table.ruler(pos)
		block_text = if ruler == @group
			building = if block==Block::EMPTY
				"施設を建設するには(`c`)"
			else
				"施設を撤去するには(`v`)"
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
		
		msg(constant_text+(block_text||"")+@group.log.each.to_a.join("\n")) # よくわからないけど、eachをつけないとうまく動かなかった
		@group.log.clear()
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
					items = @group.items
					if items.empty?
						msg("現在アイテムは持っていません。")
					else
						msg(items.map{|i,c|"#{i} : `#{c}`"}.join("\n"))
					end
					throw :return_no_map
				when "x"
					war()
				when "c"
					build_building()
				when "v"
					remove_building()
				end
			end
		end
	end
	
	def move(x, y)
		result = @group.move(@game_table, x, y)
	end
	
	def war()
		enemy = @game_table.ruler(pos)
		if enemy == @group
			msg(<<~EOS)
				この場所は既に支配しています。
			EOS
			throw :return_no_map
		end
		result = @game_table.war(@group)
		case result
		when :win
			msg(<<~EOS)
				やった！勝ちました！
			EOS
		when :lose
			msg(<<~EOS)
				残念ながら負けてしまいました・・・
			EOS
		end
	end
	
	def build_building()
		block = @game_table.block(pos)
		ruler = @game_table.ruler(pos)
		if block != Block::EMPTY
			msg(<<~EOS)
				既に建物が立っていて、土地がありません・・・
			EOS
			throw :return_no_map
		end
		if ruler != @group
			msg(<<~EOS)
				ここを支配しているグループに建設を邪魔されました・・・
			EOS
			throw :return_no_map
		end
		
		select_block = Block::CAN_BUILD_LIST
			.map
			.with_index{|b, i|[(i+?a.ord).chr, b]}
			.to_h
		select_text = select_block
			.map do |char, (block, need_items)|
				group_items = @group.items
				can_build = need_items.all?{|item,count|(group_items[item]||0) >= count}
				"`#{char}` : "+(
					if can_build
						"#{block.name}(#{need_items.map{|item,count|"#{item}を#{count}"}.join("、")}使う)"
					else
						"#{"■"*block.name.length}(#{need_items.map{|item,count|"#{item}があと#{count-(group_items[item]||0)}"}.join("、")}必要)"
					end
				)
			end
			.join("\n")
		msg(<<~EOS)
			建物リスト
			#{select_text}
			`ret` : 前の画面に戻る
		EOS
		select = wait_respons do |res|
			if res == "ret"
				return true
			end
			sel = select_block[res.to_str]
			(sel.nil?)? nil : sel
		end
		result, text = @group.build(@game_table, select[0])
		msg(text)
		throw :return_no_map unless result
		return true
	end
	
	def remove_building()
		msg(<<~EOS)
			施設の撤去
		EOS
	end
end
