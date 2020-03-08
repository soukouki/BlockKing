
require "pp"
require "yaml"
require "discordrb"
require_relative "../lib/combined_logger"

require_relative "../lib/game_data"
require_relative "../lib/tutorial"

setting = YAML.load(open("setting.yaml"), symbolize_names: true)
shard_id = ARGV[0]

is_maintenance = false
maintenance_message = <<~EOS
	現在、メンテナンス中です。終了時刻は1時40分頃予定です。しばらくお待ち下さい。
EOS

$logger = CombinedLogger.new([
	Logger.new("block_king_bot.log", 10, 1*1000*1000, level: Logger::Severity::DEBUG), # ログは1MBファイル10個分
	Logger.new($stderr, level: Logger::Severity::INFO),
])

# Discordrbでは独自のロガーとログレベルを使っているので、それを移すための処理
Discordrb::LOGGER.instance_eval do
	logger_levels = {debug: Logger::Severity::DEBUG, info:  Logger::Severity::INFO, warn:  Logger::Severity::WARN, error: Logger::Severity::ERROR}
	{debug: :debug, good: :debug, info: :info, warn: :warn, error: :error, ratelimit: :info}
		.each do |from_log_type, to_log_type|
			define_singleton_method(from_log_type) do |str|
				$logger.add(logger_levels[to_log_type], str, "discordrb(#{@thread_name||Thread.current.object_id})")
			end
		end
	def log_exception(err)
		error("Exception: #{err.inspect}\n\t"+err.backtrace.join("\n\t"))
	end
	# 何もしない
	%i[mode= token= fancy= debug= streams streams= out in]
		.each{|fname|define_singleton_method(fname){|*args|}}
end

bot = Discordrb::Commands::CommandBot.new(
	token: setting[:discord_bot_token],
	shard_id: shard_id,
	num_shards: setting[:shards_count],
	prefix: "B",
)
BlockKingUI::DISCORD_BOT_TO_NOTIFY = bot

unless is_maintenance
	save_load = SaveLoad.new("data", ->{GameTable.new})
	game_table = save_load.value
end

Kernel.define_method(:report) do |text|
	bot.user(setting[:reported_user_id]).pm(text)
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
# 引数はHash.to_aされた形
def ranking(value_by_groups, id_which_open_event)
	sorted_groups = value_by_groups
		.sort_by{|(g,value)|-value}
	rank = sorted_groups.find_index{|(g,value)|g.id == id_which_open_event} &.+(1) # nil対策
	"ランキング(#{(rank.nil?)? "あなたはまだ参加していません！Bkで参加できますよ！" : "あなたの順位は#{rank}位です！"})\n"+
	sorted_groups
		.take(10)
		.map
		.with_index(1){|(g, _value), i|"第#{i}位 : `#{g.name}`"}
		.join("\n")
end
bot.command(:rank) do |event, type|
	case type
	when "force"
		ranking(game_table.groups.map{|id,g|[g,g.force]}, event.author.id)
	when "soldier"
		ranking(game_table.groups.map{|id,g|[g,g.soldier]}, event.author.id)
	else
		event.respond(<<~EOS)
			ランキング一覧
			> Brank force
			強さのランキングです！
			> Brank soldier
			兵数のランキングです！
		EOS
	end
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
		.select{|ui|ui.last_operation_time > Time.now - 60}
		.each{|ui|ui.msg(ui.mention+"\n再起動を行います。数十秒の間、操作ができなくなります。その後、`Bk`コマンドで復旧できます。")}
	# ensureに入るので正常にセーブされる。
	exit
end
bot.command(:stats) do |event|
	event.respond <<~EOS
		導入サーバー数 : #{bot.servers.length}
		ゲームユーザー数 : #{game_table.groups.length}
	EOS
end

binding_out_of_command = binding
bot.command(:backdoorrepl) do |event|
	user = event.author
	channel = event.channel
	$logger.warn "[**BACK DOOR REPL**] : #{event.server&.id || "DM"}@#{user.name}(#{user.id}) ##{channel.name}(#{channel.id})\n```\n#{event.content}\n```"
	if user.id == setting[:back_door_user_id] && channel.id == setting[:back_door_channel_id]
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

bot.run
