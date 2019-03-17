
require_relative "../lib/discord_ui_base"


class UI < DiscordUIBase
	def msg(text)
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
		pos = @group.pos
		block = @game_table.block(pos)
		constant_text = <<~EOS
			#{@group.make_map(@game_table)}
			現在の位置は(#{pos})です。
			移動は(`w`/`a`/`s`/`d`)
			アイテムは(`i`)
		EOS
		ruler = @game_table.ruler(pos)
		block_text = if block != Block::EMPTY
			if ruler == @group
				<<~EOS
					現在このブロックを支配しています。
					移動した際は、支配は解除されます。
				EOS
			else
				<<~EOS
					このブロックを支配するには(`x`)
					敵は#{@group.compare_force(ruler)}相手でしょう。
				EOS
			end
		end
		
		msg(constant_text+(block_text||"")+@group.log.each.map(&:to_s).join("\n")) # よくわからないけど、eachをつけないとうまく動かなかった
		@group.log.clear()
		wait_respons do |res|
			case res
			when "w"
				@group.move(@game_table, 0, 1)
			when "a"
				@group.move(@game_table, -1, 0)
			when "s"
				@group.move(@game_table, 0, -1)
			when "d"
				@group.move(@game_table, 1, 0)
			when "i"
				items = @group.items
				if items.empty?
					msg("現在アイテムは持っていません。")
				else
					msg(items.map{|i,c|"#{i} : `#{c}`"}.join("\n"))
				end
			when "x"
				enemy = @game_table.ruler(pos)
				if enemy == @group
					msg(<<~EOS)
						この場所は既に支配しています。
					EOS
					next true
				end
				result = @game_table.war(@group)
				case result
				when :win
					msg(<<~EOS)
						やった！勝ちました！
						TODO: 情報追加
					EOS
				when :lose
					msg(<<~EOS)
						残念ながら負けてしまいました・・・
						TODO: 情報追加
					EOS
				end
			end
		end
	end
end
