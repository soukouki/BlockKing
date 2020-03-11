
require "logger"
class CombinedLogger
	def initialize(loggers)
		@loggers = loggers
	end
	
	(Logger.instance_methods - self.instance_methods).each do |method_name|
		define_method(method_name) do |*args|
			@loggers.each{|logger|logger.send(method_name, *args)}
		end
	end
end
