
require "json"
require "discordrb"

require_relative "../../lib/using_different_process/logger_of_bots"

token = ARGV[0]
num_shards = ARGV[1].to_i

bot = Discordrb::Bot.new(token: token, num_shards: num_shards, shard_id: 0)
bot.run true

begin
	loop do
		obj = JSON.parse($stdin.readline, symbolize_names: true)
		$logger.debug("Bot picking up message received #{obj}")
		if obj[:channel_id]
			bot.send_message(obj[:channel_id], obj[:message])
		elsif obj[:user_id]
			bot.send_message(bot.private_channel(obj[:user_id]), obj[:message])
		else
			raise "Cannot send message because cannot get channel."
		end
	end
rescue => e
	$logger.error e
	raise # 落ちないことよりも、落ちても復旧できることを重視する
end
