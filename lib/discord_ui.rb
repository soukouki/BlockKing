
require_relative "../lib/discord_ui_base"


class UI < DiscordUIBase
	def msg(text)
		server = @channel.server
		puts "#{Time.now} : #{server&.name}(#{server&.id})##{@channel.name}(#{@channel.id})@#{@user.name}(#{@user.id}) : #{text.lines.first}"
		@channel.send_message(text)
	end
	
	def start(game_table)
		@game_table = game_table
		@leader = game_table.leader(@user.id) || (
			l = Leader.new(@user.id, @user.name)
			game_table.add_leader(l)
			l
		)
		@exists_log = false
		@leader.log.callback do |log|
			unless @exists_log
				@exists_log = true
				msg("現在、ログがあります。確認するには(`Bk`)")
			end
		end
		loop do
			case @leader.state
			when :first_story
				#first_story()
				@leader.state = nil
			else
				map()
			end
		end
	end
	
	def first_story()
		text = <<~EOS
			・・・・・・・・・・
			戦いばかりが続くこの国。
			王の力は弱まり、いくつもの兵を持った集団が収めるこの国。
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
	
	def map()
		pos = @leader.pos
		block = @game_table.block(pos)
		constant_text = <<~EOS
			#{@leader.make_map(@game_table)}
			現在の位置は(#{pos})です。
			移動は(`w`/`a`/`s`/`d`)
			アイテムは(`i`)
		EOS
		ruler = @game_table.ruler(pos)
		block_text = if block != Block::EMPTY
			if ruler == @leader
				<<~EOS
					現在このブロックを支配しています。
					移動した際は、支配は解除されます。
				EOS
			else
				<<~EOS
					このブロックを支配するには(`x`)
					敵は#{@leader.compare_force(ruler)}相手でしょう。
				EOS
			end
		end
		
		msg(constant_text+(block_text||"")+@leader.log.each.map(&:to_s).join("\n")) # よくわからないけど、eachをつけないとうまく動かなかった
		@leader.log.clear()
		wait_respons do |res|
			case res
			when "w"
				@leader.move(@game_table, 0, 1)
			when "a"
				@leader.move(@game_table, -1, 0)
			when "s"
				@leader.move(@game_table, 0, -1)
			when "d"
				@leader.move(@game_table, 1, 0)
			when "i"
				items = @leader.items
				if items.empty?
					msg("現在アイテムは持っていません。")
				else
					msg(items.map{|i,c|"#{i} : `#{c}`"}.join("\n"))
				end
			when "x"
				result = @game_table.war(@leader)
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
