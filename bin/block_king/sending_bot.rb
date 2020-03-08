
require "json"
require "discordrb"

require_relative "../../lib/combined_logger"

token = ARGV[0]
num_shards = ARGV[1].to_i

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

bot = Discordrb::Bot.new(token: token, num_shards: num_shards, shard_id: 0)
bot.run true

loop do
	object = JSON.parse($stdin.readline, symbolize_names: true)
	bot.send_message(object[:channel_id], object[:message])
end
