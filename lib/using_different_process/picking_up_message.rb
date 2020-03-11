
require "json"

class PickingUpMessage
	ReceivedMessage = Struct.new(:id, :user_id, :user_name, :is_user_bot, :channel_id, :message, keyword_init: true)
	INNORING_TEXT = [
		"libsodium not available! You can continue to use discordrb as normal but voice support won't work.\n",
		"        Read https://github.com/meew0/discordrb/wiki/Installing-libsodium for more details.\n",
	]
	
	# callbackの引数は(id:, user_id:, user_name:, channel_id:, message:)
	def initialize(token:, shards_count: 1, game: "", callback:)
		@token = token
		@game = game
		@shards_count = shards_count
		@callback = callback
		start_bot()
		start_receiving_message()
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
	
	private
	
	def start_receiving_message()
		@streams
			.each do |stream|
				Thread.new do
					begin
						loop do
							text = stream.readline
							redo if INNORING_TEXT.include?(text)
							obj = JSON.parse(text, symbolize_names: true)
							@callback.call(ReceivedMessage.new(obj))
						end
					rescue EOFError => e
						warn e # redoしても意味ない
					rescue => e
						# 本当はきっちりログを出すべきだけど、loggerへの依存もできないから、stderrに出力してredoするだけにした
						warn e
						redo
					end
				end
			end
	end
	
	# そのまま起動させると、bot側に登録したデータが消えてしまうので、いっそのことエラーを出して落とす
	def send_signal(object)
		@streams.each do |stream|
			stream.puts JSON.generate(object)
			stream.flush
		end
	end
	
	def start_bot()
		@streams = @shards_count.times.map do |shard_id|
			IO.popen("ruby bin/block_king/bot_picking_up_message.rb #{@token} #{@shards_count} #{shard_id} \"#{@game}\"", "r+")
		end
	end
end
