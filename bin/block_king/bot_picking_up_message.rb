
require "json"
require "discordrb"

require_relative "../../lib/logger_of_bots"

token = ARGV[0]
num_shards = ARGV[1].to_i
shard_id = ARGV[2].to_i

bot = Discordrb::Bot.new(token: token, num_shards: num_shards, shard_id: shard_id)

# もっと制限を加えることはできるけど、今回はしない。
registered_bars_by_user_id = Hash.new{[]}
mutex_for_registered_bars_by_user_id = Thread::Mutex.new

def check(channel_id_of_bar, regex_of_bar, channel_id_of_event, content_of_event)
	return false if channel_id_of_bar && channel_id_of_bar != channel_id_of_event
	regex_of_bar.nil? || regex_of_bar.match?(content_of_event)
end

bot.message do |event|
	user_id = event.user.id
	channel_id = event.channel.id
	content = event.message.content
	cleared_bar = mutex_for_registered_bars_by_user_id.synchronize do
		cleared_bar = registered_bars_by_user_id[nil].find{|bar|check(bar[:channel_id], bar[:regex], channel_id, content)}
		break cleared_bar if cleared_bar
		break nil unless registered_bars_by_user_id.has_key?(user_id)
		registered_bars_by_user_id[user_id].find{|bar|check(bar[:channel_id], bar[:regex], channel_id, content)}
	end
	next if cleared_bar.nil?
	obj = {
		id: cleared_bar[:id],
		user_id: user_id,
		user_name: event.user.name,
		channel_id: channel_id,
		message: content,
	}
	$stdout.puts JSON.generate(obj)
	$stdout.flush
	$logger.debug("Bot picking up message sended #{obj}")
end

bot.run true

begin
	loop do
		obj = JSON.parse($stdin.readline, symbolize_names: true)
		$logger.debug("Bot picking up message received #{obj}")
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
