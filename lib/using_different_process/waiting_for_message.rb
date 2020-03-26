
require_relative "picking_up_message"

class WaitingForMessage
	def initialize(token:, shards_count: 1, game: "", logger: nil)
		@picking_up_message = PickingUpMessage.new(
			token: token,
			shards_count: shards_count,
			game: game,
			callback: ->(rm){receive_message(rm)},
			logger: logger
		)
		@logger = logger
		@id_count = 0
		@mutex_for_id_count = Thread::Mutex.new
		@waiting_processes_by_id = {}
		@mutex_for_waiting_processes_by_id = Thread::Mutex.new
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
		@picking_up_message.register(id: id, regex_text: regex_text, user_id: user_id, channel_id: channel_id)
	end
	def cancel_waiting(id:)
		@picking_up_message.cancel(id: id)
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
