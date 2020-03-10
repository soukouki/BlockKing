



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
