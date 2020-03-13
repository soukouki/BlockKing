
require "json"
require "discordrb"

require_relative "../../lib/using_different_process/logger_of_bots"

token = ARGV[0]
num_shards = ARGV[1].to_i
shard_id = ARGV[2].to_i
game = ARGV[3]

bot = Discordrb::Bot.new(token: token, num_shards: num_shards, shard_id: shard_id)

# もっと制限を加えることはできるけど、今回はしない。
registered_bars_by_user_id = Hash.new{[]}
mutex_for_registered_bars_by_user_id = Thread::Mutex.new

def check(channel_id_of_bar, regex_of_bar, channel_id_of_event, content_of_event)
	return false if channel_id_of_bar && channel_id_of_bar != channel_id_of_event
	regex_of_bar.nil? || regex_of_bar.match?(content_of_event)
end

bot.message do |event|
	user = event.user
	user_id = user.id
	channel_id = event.channel.id
	content = event.message.content
	checking_bars = mutex_for_registered_bars_by_user_id.synchronize do
		registered_bars_by_user_id[nil] + registered_bars_by_user_id[user_id]
	end
	cleared_bars = checking_bars.select{|bar|check(bar[:channel_id], bar[:regex], channel_id, content)}
	cleared_bars.each do |bar|
		obj = {
			id: bar[:id],
			user_id: user_id,
			user_name: user.name,
			is_user_bot: user.bot_account?,
			channel_id: channel_id,
			message: content,
		}
		$stdout.puts JSON.generate(obj)
		$stdout.flush
		$logger.info("Bot picking up message sended")
		$logger.debug(obj) # 一応プライバシーも考えて通常時は見ないdebugで
	end
end

bot.ready do
	bot.game = game
end

bot.run true

begin
	loop do
		obj = JSON.parse($stdin.readline, symbolize_names: true)
		$logger.info("Bot picking up message received")
		$logger.info(obj) # 実行頻度が少ないからinfoで
		case obj[:type]
		when "register"
			user_id = obj[:user_id]
			mutex_for_registered_bars_by_user_id.synchronize do
				registered_bars_by_user_id[user_id] = registered_bars_by_user_id[user_id] # 一回代入しないとハッシュ内に情報が入らなかったから
				registered_bars_by_user_id[user_id] << {
					id: obj[:id],
					regex: obj[:regex_text] && Regexp.compile(obj[:regex_text]),
					user_id: user_id,
					channel_id: obj[:channel_id],
				}
			end
		when "cancel"
			id = obj[:id]
			mutex_for_registered_bars_by_user_id.synchronize do
				registered_bars_by_user_id.each do |_user_id, bars|
					break if bars.reject!{|bar|bar[:id] == id}
				end
			end
		end
	end
rescue => e
	$logger.error e
	raise
end
