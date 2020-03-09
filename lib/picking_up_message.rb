
require "json"

class PickingUpMessage
	INNORING_TEXT = [
		"libsodium not available! You can continue to use discordrb as normal but voice support won't work.\n",
		"        Read https://github.com/meew0/discordrb/wiki/Installing-libsodium for more details.\n",
	]
	attr_accessor :callback
	
	def initialize(token:, shards_count:)
		@token = token
		@shards_count = shards_count
		@callback = ->(id:, user_id:, user_name:, channel_id:, message:){}
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
							@callback.call(*obj)
						end
					rescue => e
						# 本当はきっちりログを出すべきだけど、loggerへの依存もできないから、sstderrに出力してredoするだけにした
						warn e
						redo
					end
				end
			end
	end
	
	def send_signal(object)
		@streams.each do |stream|
			begin
				stream.puts JSON.generate(object)
				stream.flush
			rescue Errno::EPIPE # エラーが発生してbotが落ちたときの復帰処理
				start_bot()
				retry
			end
		end
	end
	
	def start_bot()
		@streams = @shards_count.times.map do |shard_id|
			IO.popen("ruby bin/block_king/bot_picking_up_message.rb #{@token} #{@shards_count} #{shard_id}", "r+")
		end
	end
end
