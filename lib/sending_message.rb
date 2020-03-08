
require "json"

# 送信エラー等は拾わない。
# setting.yamlに
class SendingMessage
	# 大きい数にして、botにイベントが送られてこないようにする
	NUM_SHARDS = 10000
	def initialize(token:)
		@token = token
		start_bot()
	end
	def send_message(channel_id, message)
		object = {
			channel_id: channel_id,
			message: message,
		}
		begin
			@io_stream.puts JSON.generate(object)
		rescue Errno::EPIPE # エラーが発生してbotが落ちたときの復帰処理
			@io_stream.close
			start_bot
			retry
		end
	end
	
	private
		
	def start_bot()
		@io_stream = IO.popen("ruby bin/block_king/sending_bot.rb #{@token} #{NUM_SHARDS}", "r+")
	end
end
