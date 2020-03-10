
require "yaml"
require "fileutils"

require_relative "../lib/save_load"
require_relative "../lib/combined_logger"
require_relative "../lib/using_different_process/waiting_for_message"
require_relative "../lib/using_different_process/sending_message"

#require_relative "../lib/block_king_ui"
require_relative "../lib/block_king"
require_relative "../lib/game_data"

setting = YAML.load(open("setting.yaml"), symbolize_names: true)

$logger = CombinedLogger.new([
	Logger.new("block_king_bot.log", 10, 1*1000*1000, level: Logger::Severity::DEBUG), # ログは1MBファイル10個分
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

#BlockKingUI::FUNCTION_TO_NOTIFY = lambda do |channel_id, text|
#end

save_load = SaveLoad.new("data", ->{GameTable.new})
game_table = save_load.value


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
waiting_for_message.collect_messages(regex_text:'^Brank(\s|$)') do |rm|
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

waiting_for_message.collect_messages(regex_text:'^Bhis(\s|$)') do |rm|
	text = "歴代王の記録\n"+
		game_table
			.kings_history
			.map
			.with_index(1){|k,i|"第#{i}代 : `#{k.name}`"}
			.join("\n")
	sending_message.send_message(rm.channel_id, text)
end

waiting_for_message.collect_messages(regex_text:'^Bbots(\s|$)') do |rm|
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
waiting_for_message.collect_messages(regex_text:'^Bhelp(\s|$)') do |rm|
	sending_message.send_message(rm.channel_id, <<~EOS)
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
# TODO: サーバー数は諦めきれない
waiting_for_message.collect_messages(regex_text:'^Bstats(\s|$)') do |rm|
	sending_message.send_message(rm.channel_id, <<~EOS)
		ゲームユーザー数 : #{game_table.groups.length}
		メッセージ受け取り部シェード数 : #{setting[:shards_count]}
	EOS
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
