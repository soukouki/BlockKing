
require_relative "../lib/block_king"
require_relative "../lib/discord_ui"
require_relative "../lib/save_load"

token = ARGV[0]

bot = Discordrb::Commands::CommandBot.new(token: token, prefix: "B")

save_load = SaveLoad.new("data", ->{GameTable.new})
game_table = save_load.value

uis = {}
bot.command(:k) do |event|
	user = event.user
	old_ui = uis[user.id]
	
	if old_ui.nil?
		ui = uis[user.id] = UI.new(bot: bot, channel: event.channel, user: user)
		ui.start(game_table)
	else
		old_ui = uis[user.id]
		old_ui.stop_waiting()
		old_ui.start(game_table)
	end
end

bot.run :async

begin
	loop do
		sleep(60 - Time.now.sec)
		puts "定期処理 #{Time.now}"
		game_table.turn()
		if Time.now.min%5 == 0
			puts "定時保存"
			save_load.save
		end
	end
ensure
	puts "エラー時終了処理"
	save_load.save
end
