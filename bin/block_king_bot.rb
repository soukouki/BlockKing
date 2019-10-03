
require "fileutils"
require "stringio"
require "pp"

require_relative "../lib/block_king"
require_relative "../lib/game_data"
require_relative "../lib/discord_ui"
require_relative "../lib/save_load"

token = ARGV[0]
back_door_channel_id = ARGV[1]&.to_i
back_door_user_id = ARGV[2]&.to_i

is_maintenance = false
maintenance_message = <<~EOS
	現在、メンテナンス中です。終了時刻は1時40分頃予定です。しばらくお待ち下さい。
EOS

bot = Discordrb::Commands::CommandBot.new(token: token, prefix: "B")

unless is_maintenance
	save_load = SaveLoad.new("data", ->{GameTable.new})
	game_table = save_load.value
end

# ハッシュの中にハッシュが入ってる
uis = {}
mutexes = {}
bot.command(:k) do |event|
	if is_maintenance
		event.respond maintenance_message
		next
	end
	user = event.user
	if user.bot_account?
		<<~EOS
			現在、BOTはプレイできません。
			いつか開発するBOT対戦機能をご期待下さい！
		EOS
		next
	end
	old_ui = uis[user.id]
	mutex = mutexes[user.id] ||= Mutex.new
	
	# この部分Mutexつけるべき
	if old_ui.nil?
		mutex.synchronize do
			event.respond <<~EOS
				`Bhelp`にてコマンド一覧・禁止事項・招待URLが見れます！
			EOS
			ui = uis[user.id] = BlockKingUI.new(bot: bot, channel: event.channel, user: user)
			ui.start(game_table)
		end
	else
		old_ui.stop_waiting()
		mutex.synchronize do
			ui = uis[user.id] = BlockKingUI.new(bot: bot, channel: event.channel, user: user)
			ui.start(game_table)
		end
	end
end
bot.command(:rank) do |event|
	sorted_groups = game_table
		.groups
		.sort_by{|id, g|g.force}
		.reverse
	rank = sorted_groups.find_index{|id,g|id == event.user.id}&.+(1)
	event.respond(
		"ランキング(#{(rank.nil?)? "あなたはまだ参加していません！Bkで参加できますよ！" : "あなたの順位は#{rank}位です！"})\n"+
		sorted_groups
			.take(10)
			.map
			.with_index(1){|(id, g), i|"第#{i}位 : `#{g.name}`"}
			.join("\n")
	)
end
bot.command(:his) do |event|
	event.respond(
		"歴代王の記録\n"+
		game_table
			.kings_history
			.map
			.with_index(1){|k,i|"第#{i}代 : `#{k.name}`"}
			.join("\n")
	)
end
bot.command(:bots) do |event|
	event.respond(<<~EOS)
		兄弟bot一覧！
		__Greetingbot__
			挨拶botです！挨拶に関してはかなりのものだと思ってます！
				導入url : <https://discordapp.com/oauth2/authorize?client_id=394876010438328321&scope=bot&permissions=2048>
				prefix : `n.`
		__M-putit__
			気象・地震・津波情報関連のbotです！気象庁が発表する色んな情報をチャンネルに流せます！(設定に時間がかかります。ご了承ください)
				導入url <https://discordapp.com/oauth2/authorize?scope=bot&client_id=505357370306592788&permissions=2048>
				prefix : `m.`
		__BlockKing__
			:crossed_swords: **アイテムを集めてクラフトし、強力な剣で王座を狙うゲームです！** :fire:
				導入url : <https://discordapp.com/oauth2/authorize?client_id=555753809834409987&permissions=2048&scope=bot>
				公式サーバー(プレイもできる) : <https://discord.gg/nJ5QVJu>
				prefix : `B`
	EOS
end
bot.command(:help) do |event|
	event.respond <<~EOS
		コマンドの一覧です。
		`Bk` : **ゲームをスタートします。**
		`Brank` : ランキングが見れます。
		`Bhelp` : このコマンドです。
		`Bhis` : 過去の王が見れます。
		`Bexit` : コマンドに反応しないようになります。
		`Bstats` : このbotに関する情報がﾁｮｯﾄﾀﾞｹ見れます。
		`Bbots` : 兄弟botを紹介します！ぜひ導入してみてください！
		
		**禁止事項**
		- bot、外部ツール等を使ってのプレイ。
		- 1人が複数アカウントを使用し、ゲーム内で協力して他プレイヤーより有利にゲームを進める行為。
		- その他過度に他プレイヤーを妨害する行為。
		
		**留意事項**
		- このbotでは、ユーザーネームが公開されます。
		- 公衆良俗に反するようなユーザーネームの場合、削除することがあります。
		- プログラムの更新等により、セーブデータに影響が出ないよう努力しますが、場合によっては影響が出る場合があります。
		
		
		招待URL : <https://discordapp.com/oauth2/authorize?client_id=555753809834409987&permissions=2048&scope=bot>
		(BlockKingが入っていないサーバーでもこのゲームを遊びたいときは、上のURLをサーバーの管理者権限を持っている人に開かせてください！きっといいことが起こります！)
		公式サーバー : https://discord.gg/nJ5QVJu
		製作者 : @sou7#0094 その他テストプレイに参加してくださった方々
	EOS
end
bot.command(:exit) do |event|
	ui = uis[event.user.id]
	ui&.stop_waiting()
	"反応しないようになりました。"
end
bot.command(:end) do |event|
	next unless event.user==bot.bot_app.owner
	uis
		.values
		.select{|ui|ui.last_operation_time > Time.now - 3600*24*2}
		.each{|ui|ui.msg(ui.mention+"\n再起動を行います。クラフト完了、残りアイテム減少時のメンションによるお知らせが途切れます。`Bk`コマンドで復旧できます。")}
	# ensureに入る
	exit
end
bot.command(:stats) do |event|
	event.respond <<~EOS
		導入サーバー数 : #{bot.servers.length}
		ゲームユーザー数 : #{game_table.groups.length}
	EOS
end

binding_out_of_command = binding
binding_out_of_command.local_variable_set(:token, "*****")
bot.command(:backdoorrepl) do |event|
	user = event.author
	channel = event.channel
	puts "#{Time.now} : [**BACK DOOR REPL**] : #{event.server&.id || "DM"}@#{user.name}(#{user.id}) ##{channel.name}(#{channel.id})\n```\n#{event.content}\n```"
	if user.id == back_door_user_id && channel.id == back_door_channel_id
		event.respond "#{binding_out_of_command.local_variables}"
		code = event.content.gsub(/^Bbackdoorrepl\s*/){""}
		event.respond (code.empty?)? "`code is none.`" : "`#{code}`"
		begin
			value = eval(code, binding_out_of_command)
		rescue Exception => error
			error_text = ""
			PP.pp(error, error_text)
			event.respond "`#{error_text}`"
			raise
		ensure
			result_text = ""
			PP.pp(value, result_text)
			event.respond (result_text.length > 1998)? "result text is over 1998 characters." : "`#{result_text}`"
		end
	end
	nil
end

bot.ready do
	bot.game = if is_maintenance
		"現在メンテ中"
	else
		"ゲームスタートはBk(Bは大文字)"
	end
end

bot.run :async

begin
	loop do
		sleep(60 - Time.now.sec)
		
		next if game_table.nil?
		
		puts "定期処理 #{Time.now}"
		game_table.turn()
		
		start_time = Time.now
		
		if start_time.min%5 == 0
			puts "定時保存"
			save_load.save
			puts "定時保存完了 #{Time.now-start_time}"
		end
		
		if start_time.min == 0
			puts "毎時バックアップ"
			sl = save_load.clone
			rm_and_save = lambda do |path|
				FileUtils.remove_entry_secure(path) if Dir.exist?(path)
				sl.path = path
				sl.save()
			end
			
			rm_and_save["data/hourly-backup/#{start_time.hour}"]
			
			if start_time.hour == 0
				puts "毎日バックアップ"
				rm_and_save["data/daily-backup/#{start_time.day}"]
				
				if start_time.day == 1
					puts "毎月バックアップ"
					rm_and_save["data/monthly-backup/#{start_time.year}-#{start_time.month}"]
				end
			end
		end
		
		puts "定期処理終了"
	end
ensure # Bend時はこの部分を実行する
	puts "例外保存"
	save_load&.save
	puts "例外保存終了"
	puts "例外終了"
end
