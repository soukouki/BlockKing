
require "json"

class ControllingShardsOfBot
	COMMAND_BOOTING_BOT = "ruby bin/block_king/shard_of_bot.rb"
	INNORING_TEXT = [
		"libsodium not available! You can continue to use discordrb as normal but voice support won't work.\n",
		"        Read https://github.com/meew0/discordrb/wiki/Installing-libsodium for more details.\n",
	]

	ReceivedMessage = Struct.new(:id, :user_id, :user_name, :is_user_bot, :channel_id, :message, keyword_init: true)
	ReceivedServers = Struct.new(:shard_id, :id_of_servers, keyword_init: true)
	
	def initialize(token:, shards_count: 1, logger: nil)
		@token = token
		@shards_count = shards_count
		@mutex_for_callbacks = Mutex.new
		@callbacks = []
		@logger = logger
		start_bot()
		start_receiving_message()
	end

	def add_callback(callback)
		@mutex_for_callbacks.synchronize do
			@callbacks << callback
		end
	end
	
	# idは32ビット符号なし整数で、被りがないように登録する
	# どのチャンネルやユーザーでもいい場合はnilを入れる
	def register(id:, regex_text: nil, user_id: nil, channel_id: nil)
		raise RangeError, "Id must be between 0 and 2^32-1." unless (0..(1<<32)-1).include? id
		send_signal(
			{
				type: "register",
				id: id,
				regex_text: regex_text,
				user_id: user_id,
				channel_id: channel_id,
			}
		)
	end
	def cancel(id:)
		send_signal(
			{
				type: "cancel",
				id: id
			}
		)
	end
	def get_servers
		send_signal(
			{
				type: "get_servers",
			}
		)
	end
	def set_game(game)
		send_signal(
			{
				type: "set_game",
				game: game
			}
		)
	end
	
	private
	
	def start_receiving_message()
		@streams
			.each do |stream|
				Thread.new do
					begin
						loop do
							text = stream.readline.force_encoding("UTF-8")
							redo if INNORING_TEXT.include?(text)
							obj = separate_received_object(JSON.parse(text, symbolize_names: true))
							@mutex_for_callbacks.synchronize do
								@callbacks.each do |cb|
									cb.call(obj)
								end
							end
						end
					rescue EOFError => e
						@logger && @logger.info(e) # redoしても意味ない
					rescue => e
						@logger && @logger.warn(e)
						redo
					end
				end
			end
	end

	def separate_received_object(object)
		type = object[:type]
		object.delete(:type)
		case type
		when "message"
			ReceivedMessage.new(object)
		when "servers"
			ReceivedServers.new(object)
		end
	end
	
	# そのまま起動させると、bot側に登録したデータが消えてしまうので、いっそのことエラーを出して落とす
	def send_signal(object)
		@streams.each do |stream|
			stream.puts JSON.generate(object)
			stream.flush
		end
		@logger && @logger.info("class ControllingShardsOfBot send command type:#{object[:type]}, id:#{object[:id]||"none"}")
		@logger && @logger.debug(object)
	end
	
	def start_bot()
		@streams = @shards_count.times.map do |shard_id|
			IO.popen("#{COMMAND_BOOTING_BOT} #{@token} #{@shards_count} #{shard_id}", "r+")
		end
	end
end
