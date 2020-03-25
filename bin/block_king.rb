
require "yaml"
require "fileutils"
require "pp"

require_relative "../lib/save_load"
require_relative "../lib/combined_logger"
require_relative "../lib/using_different_process/waiting_for_message"
require_relative "../lib/using_different_process/sending_message"

# 将来的にデータの管理をするクラスに仕事を任せるべきな気がする
require_relative "../lib/block_king"

require_relative "../lib/ui/discord_ui"
require_relative "../lib/handler"
require_relative "../lib/watching_story_handler"

setting = YAML.load(open("setting.yaml"), symbolize_names: true)

$logger = CombinedLogger.new([
	Logger.new("block_king.log", level: Logger::Severity::DEBUG),
	Logger.new($stderr, level: Logger::Severity::INFO),
])

waiting_for_message = WaitingForMessage.new(
	token: setting[:discord_bot_token],
	shards_count: setting[:shards_count],
	game: "ゲームスタートはBk(Bは大文字)",
	logger: $logger,
)
sending_message = SendingMessage.new(
	token: setting[:discord_bot_token]
)

Kernel.define_method(:report) do |text|
	setting[:reported_user_ids].each do |id|
		sending_message.send_dm(id, text)
	end
end

Handler::FUNCTION_TO_NOTIFY = lambda do |channel_id, text|
	sending_message.send_message(channel_id, text)
end

save_load = SaveLoad.new("data", ->{GameTable.new})
game_table = save_load.value

command = lambda do |command_name, &block|
	waiting_for_message.register(regex_text: "^B#{command_name}(\\s|$)", &block)
end

# -----Handlerにふれる処理-----

ui_by_user_id = Hash.new
mutex_for_ui_by_user_id = Mutex.new
command["k"] do |rm|
	user_id = rm.user_id
	user_name = rm.user_name
	is_user_bot = rm.is_user_bot
	channel_id = rm.channel_id
	
	if is_user_bot
		sending_message.send_message(channel_id, <<~EOS)
			現在、BOTはプレイできません。
			いつか開発するBOT対戦機能にご期待下さい！
		EOS
		next
	end
	
	ui = mutex_for_ui_by_user_id.synchronize do
		old_ui = ui_by_user_id[user_id]
		if old_ui.nil?
			sending_message.send_message(channel_id, "`Bhelp`にてコマンド一覧・禁止事項・招待URLが見れます！")
		else
			old_ui.kill_waiting_respons()
		end
		ui_by_user_id[user_id] = Handler.new(
			ui: UI::DiscordUI.new(
				sending_message: sending_message,
				waiting_for_message: waiting_for_message,
				user_id: user_id,
				channel_id: channel_id,
				logger: $logger,
			),
			game_table: game_table,
			group_id: user_id,
			group_name: user_name,
		)
	end
	ui.ui_related_data.channel_id_to_notify = channel_id
	ui.start()
end
command["exit"] do |rm|
	user_id = rm.user_id
	mutex_for_ui_by_user_id.synchronize do
		ui_by_user_id[user_id]&.kill_waiting_respons()
		ui_by_user_id.delete(user_id)
	end
	sending_message.send_message(rm.channel_id, "反応しないようになりました。")
end
command["story"] do |rm|
	user_id = rm.user_id
	channel_id = rm.channel_id
	WatchingStoryHandler.new(
		ui: UI::DiscordUI.new(
			sending_message: sending_message,
			waiting_for_message: waiting_for_message,
			user_id: user_id,
			channel_id: channel_id,
			logger: $logger,
		),
		game_table: game_table,
		group_id: user_id,
	).start
end
command["end"] do |rm|
	user_id = rm.user_id
	next unless setting[:owner_user_ids].include?(user_id)
	mutex_for_ui_by_user_id.synchronize do
		ui_by_user_id
			.values
			.select(&:recently_operating?)
			.each(&:send_mention)
			.each{|ui|ui.msg("再起動を行います。しばらくの間、操作ができなくなります。その後、`Bk`コマンドで復旧できます。")}
	end
	# ensureに入るので正常にセーブされる。
	exit
end

# -----Handlerに触れない処理-----

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
command["rank"] do |rm|
	type = rm.message.split(/\s+/)[1]
	text = case type
	when "force"
		ranking(game_table.groups.map{|id,g|[g,g.force]}, rm.user_id)
	when "soldier"
		ranking(game_table.groups.map{|id,g|[g,g.soldier]}, rm.user_id)
	else
		<<~EOS
			ランキング一覧
			> Brank force
			強さのランキングです！
			> Brank soldier
			兵数のランキングです！
		EOS
	end
	sending_message.send_message(rm.channel_id, text)
end

command["his"] do |rm|
	text = "歴代王の記録\n"+
		game_table
			.kings_history
			.map
			.with_index(1){|k,i|"第#{i}代 : `#{k.name}`"}
			.join("\n")
	sending_message.send_message(rm.channel_id, text)
end

command["bots"] do |rm|
	sending_message.send_message(rm.channel_id, <<~EOS)
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
command["help"] do |rm|
	sending_message.send_message(rm.channel_id, <<~EOS)
		コマンドの一覧です。
		`Bhelp` : このコマンドです。
		`Bk` : **ゲームをスタートします。**
		`Bexit` : コマンドに反応しないようになります。
		`Bstory` : 過去に見たストーリーが見れます。
		`Brank` : ランキングが見れます。
		`Bhis` : 過去の王が見れます。
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
		製作者 : @sou7#0094 ストーリーを手伝ってくれたわょわぉさん その他テストプレイに参加してくださった方々
	EOS
end
# TODO: サーバー数は諦めきれない
command["stats"] do |rm|
	program_details = (
		(Dir.glob("bin/**/*.rb") + Dir.glob("lib/**/*.rb"))
			.map do |f|
				File.open(f, "r") do |io|
					s=io.read.force_encoding("UTF-8")
					{
						lines:s.count("\n"),
						words: s.gsub(/\w+/).to_a.length,
						chars:s.length,
					}
				end
			end
	)
	sending_message.send_message(rm.channel_id, <<~EOS)
		ゲームユーザー数 : #{game_table.groups.length}
		メッセージ受け取り部シェード数 : #{setting[:shards_count]}
		プログラムファイル数 : #{program_details.count}
		プログラム行数 : #{program_details.map{|h|h[:lines]}.sum}
		プログラム単語数 : #{program_details.map{|h|h[:words]}.sum}
		プログラム文字数 : #{program_details.map{|h|h[:chars]}.sum}
	EOS
end

binding_out_of_command = binding
# ユーザー、チャンネルは複数だから、後で処理する
command["backdoorrepl"] do |rm|
	user_id = rm.user_id
	user_name = rm.user_name
	channel_id = rm.channel_id
	message = rm.message
	$logger.warn "[**BACK DOOR REPL**] : @#{user_name}(#{user_id}) #(#{channel_id})\n```\n#{message}\n```"
	if setting[:back_door_user_ids].include?(user_id) && setting[:back_door_channel_ids].include?(channel_id)
		code = message.gsub(/^Bbackdoorrepl\s*/){""}
		sending_message.send_message(channel_id, <<~EOS)
			#{binding_out_of_command.local_variables}
			#{(code.empty?)? "Code was empty." : "```ruby\n#{code}\n```"}
		EOS
		begin
			value = eval(code, binding_out_of_command)
		rescue Exception => error
			error_text = ""
			PP.pp(error, error_text)
			sending_message.send_message(channel_id, "`#{error_text}`")
			raise
		ensure
			result_text = ""
			if value.is_a?(String)
				result_text << value
			else
				PP.pp(value, result_text)
			end
			sending_message.send_message(channel_id, (result_text.length > 1998)? "result text is over 1998 characters." : "`#{result_text}`")
		end
	end
end

begin
	loop do
		sleep(60 - Time.now.sec)
		
		next if game_table.nil?
		
		$logger.info "定期処理 #{Time.now}"
		game_table.turn()
		
		start_time = Time.now
		
		if start_time.min%5 == 0
			$logger.info "定時保存開始"
			save_load.save
			$logger.info "定時保存完了 #{Time.now-start_time}"
		end
		
		if start_time.min == 0
			$logger.info "毎時バックアップ"
			sl = save_load.clone
			rm_and_save = lambda do |path|
				FileUtils.remove_entry_secure(path) if Dir.exist?(path)
				sl.path = path
				sl.save()
			end
			
			rm_and_save["data/hourly-backup/#{start_time.hour}"]
			
			if start_time.hour == 0
				$logger.info "毎日バックアップ"
				rm_and_save["data/daily-backup/#{start_time.day}"]
				
				if start_time.day == 1
					$logger.info "毎月バックアップ"
					rm_and_save["data/monthly-backup/#{start_time.year}-#{start_time.month}"]
				end
			end
		end
		
		$logger.info "定期処理終了"
	end
ensure # Bend時はこの部分を実行する
	$logger.error $!.full_message
	$logger.info "例外保存開始"
	save_load&.save
	$logger.info "例外保存終了"
	$logger.info "例外終了"
end
