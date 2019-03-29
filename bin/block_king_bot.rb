
require_relative "../lib/block_king"
require_relative "../lib/discord_ui"
require_relative "../lib/save_load"

token = ARGV[0]
is_maintenance = false

bot = Discordrb::Commands::CommandBot.new(token: token, prefix: "B")

unless is_maintenance
	save_load = SaveLoad.new("data", ->{GameTable.new})
	game_table = save_load.value
end

# ハッシュの中にハッシュが入ってる
uis = {}
bot.command(:k) do |event|
	if is_maintenance
		event.respond <<~EOS
			現在、メンテナンス中です。終了時刻は3時45分頃予定です。しばらくお待ち下さい。
		EOS
	end
	user = event.user
	if user.bot_account?
		return <<~EOS
			現在、BOTはプレイできません。
			いつか開発するBOT対戦機能をご期待下さい！
		EOS
	end
	old_ui = uis[user.id]
	
	if old_ui.nil?
		ui = uis[user.id] = UI.new(bot: bot, channel: event.channel, user: user)
		ui.start(game_table)
	elsif old_ui.channel == event.channel
		old_ui.stop_waiting()
		old_ui.start(game_table)
	else
		old_ui.stop_waiting()
		ui = uis[user.id] = UI.new(bot: bot, channel: event.channel, user: user)
		ui.start(game_table)
	end
end
bot.command(:rank) do |event|
	event.respond(
		"ランキング\n"+
		game_table
			.groups
			.values
			.sort_by{|g|g.force}
			.reverse
			.take(10)
			.map
			.with_index(1){|g, i|"第#{i}位 : `#{g.name}`"}
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
bot.command(:help) do |event|
	event.respond <<~EOS
		コマンドの一覧です。
		`Bk` : **ゲームをスタートします。**
		`Brank` : ランキングが見れます。
		`Bhelp` : このコマンドです。
		`Bhis` : 過去の王が見れます。
		`Bexit` : コマンドに反応しないようになります。
		
		プログラム : @sou7#0094
		テストプレイ : ねこらんさん、uuuさん、その他
		
		このbotでは、ユーザーネームが公開されます。
		公衆良俗に反するようなユーザーネームの場合、削除することがあります。
		プログラムの更新等により、セーブデータに影響が出ないよう努力しますが、場合によっては影響が出る場合があります。
		
		https://discordapp.com/oauth2/authorize?client_id=555753809834409987&permissions=2048&scope=bot
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
		.select{|ui|ui.latest_msg_time > Time.now-120}
		.each{|ui|ui.msg("再起動を行います。30秒ほど待った後、`Bk`でスタートしてください。")}
	s = Time.now
	puts "臨時保存開始 #{s}"
	save_load&.save
	puts "臨時保存終了 #{Time.now-s}"
	exit
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
		puts "定期処理 #{Time.now}"
		game_table&.turn()
		if Time.now.min%15 == 0
			s = Time.now
			puts "定時保存"
			save_load&.save
			puts "定時保存完了 #{Time.now-s}"
		end
	end
ensure
	puts "例外保存"
	save_load.save
	puts "例外保存終了"
	puts "例外終了"
end
