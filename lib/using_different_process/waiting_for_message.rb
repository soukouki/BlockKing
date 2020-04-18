
class WaitingForMessage
	def initialize(controlling_shards_of_bot:, logger: nil)
		@controlling_shards_of_bot = controlling_shards_of_bot
		@logger = logger
		@id_count = 0
		@mutex_for_id_count = Thread::Mutex.new
		@waiting_processes_by_id = {}
		@mutex_for_waiting_processes_by_id = Thread::Mutex.new
	end

	def receive_callback
		self.method(:receive_message)
	end
	
	# callback_giving_idは必ずblockよりも前に呼ばれる
	def register(regex_text: nil, user_id: nil, channel_id: nil, callback_giving_id: nil, &block)
		id = create_id()
		callback_giving_id && callback_giving_id.call(id)
		@mutex_for_waiting_processes_by_id.synchronize do
			@waiting_processes_by_id[id] = lambda do |received_message|
				Thread.new do
					block.call(received_message) rescue @logger && @logger.error($!)
				end
			end
		end
		@controlling_shards_of_bot.register(id: id, regex_text: regex_text, user_id: user_id, channel_id: channel_id)
	end
	def cancel_waiting(id:)
		@controlling_shards_of_bot.cancel(id: id)
		@mutex_for_waiting_processes_by_id.synchronize do
			@waiting_processes_by_id.delete(id)
		end
	end
	
	private
	
	def create_id()
		@mutex_for_id_count.synchronize do
			@id_count += 1
		end
	end
	
	def receive_message(rm)
		@mutex_for_waiting_processes_by_id.synchronize do
			@waiting_processes_by_id[rm.id].call(rm)
		end
	end
end
