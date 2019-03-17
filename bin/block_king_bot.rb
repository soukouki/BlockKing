
require_relative "../lib/block_king"
require_relative "../lib/discord_ui"

token = ARGV[0]

bot = Discordrb::Commands::CommandBot.new(token: token, prefix: "B")

game_table = GameTable.new

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

loop do
	sleep(60 - Time.now.sec)
	game_table.turn()
end
