
require_relative "../combined_logger"

$logger = CombinedLogger.new([
	Logger.new("block_king.log", level: Logger::Severity::DEBUG),
	Logger.new($stderr, level: Logger::Severity::INFO),
])

# Discordrbでは独自のロガーとログレベルを使っているので、それを移すための処理
Discordrb::LOGGER.instance_eval do
	logger_levels = {debug: Logger::Severity::DEBUG, info:  Logger::Severity::INFO, warn:  Logger::Severity::WARN, error: Logger::Severity::ERROR}
	{info: :info, warn: :warn, error: :error, ratelimit: :info} # debugの表示がとても長いので、ログとして流さないことにした。
		.each do |from_log_type, to_log_type|
			define_singleton_method(from_log_type) do |str|
				$logger.add(logger_levels[to_log_type], str, "discordrb(#{@thread_name||Thread.current.object_id})")
			end
		end
	def log_exception(err)
		error("Exception: #{err.inspect}\n\t"+err.backtrace.join("\n\t"))
	end
	# 何もしない
	%i[mode= token= fancy= debug= streams streams= out in debug good]
		.each{|fname|define_singleton_method(fname){|*args|}}
end
