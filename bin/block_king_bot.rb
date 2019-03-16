
require_relative "../lib/block_king"
require_relative "../lib/discord_ui"

token = ARGV[0]

bot = Discordrb::Commands::CommandBot.new(token: token, prefix: "B")

game_table = GameTable.new

mutexes = {}
bot.command(:k) do |event|
	user = event.user
	(mutexes[user.id] ||= Mutex.new)
		.synchronize{UI.new(bot: bot, channel: event.channel, user: user).start(game_table)}
end

bot.run
