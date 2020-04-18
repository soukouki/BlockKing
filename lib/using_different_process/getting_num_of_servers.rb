
# bot.serversはサーバーを取得したりするとそれもカウントしちゃうみたいだから、念の為IDをすべて取得する
class GettingNumOfServers
	def initialize(controlling_shards_of_bot:, num_of_shards:)
		@controlling_shards_of_bot = controlling_shards_of_bot
		@num_of_shards = num_of_shards
		@mutex_for_prevent_concurrent_access = Mutex.new
		@queue_of_received_servers = Thread::Queue.new
	end

	def receive_callback
		lambda do |obj|
			receive_servers(obj) if obj.is_a? ControllingShardsOfBot::ReceivedServers
		end
	end
	
	def get_num_of_servers
		@mutex_for_prevent_concurrent_access.synchronize do
			@controlling_shards_of_bot.get_servers()
			result = []
			@num_of_shards.times do
				result << @queue_of_received_servers.pop
			end
			result.flat_map(&:id_of_servers).uniq.count
		end
	end

	private

	def receive_servers(rs)
		@queue_of_received_servers << rs
	end
end