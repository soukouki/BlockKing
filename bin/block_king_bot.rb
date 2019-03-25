
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
			現在、メンテナンス中です。終了時刻は19時30分頃予定です。しばらくお待ち下さい。
		EOS
	end
	user = event.user
	old_ui = uis[user.id]
	if user.bot_account?
		return <<~EOS
			現在、BOTはプレイできません。
			いつか開発するBOT対戦機能をご期待下さい！
		EOS
	end
	
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
		game_table.turn()
		if Time.now.min%15 == 0
			puts "定時保存"
			save_load.save
		end
	end
ensure
	puts "エラー時終了処理"
	save_load.save
end
