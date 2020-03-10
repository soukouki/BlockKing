
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
