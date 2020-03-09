
require "json"

# 送信エラー等は拾わない。
class SendingMessage
	# 大きい数にして、botにイベントが送られてこないようにする
	NUM_SHARDS = 10000
	
	def initialize(token:)
		@token = token
		start_bot()
	end
	
	def send_message(channel_id, message)
		send_signal(
			{
				channel_id: channel_id,
				message: message,
			}
		)
	end
	def send_dm(user_id, message)
		send_signal(
			{
				user_id: user_id,
				message: message,
			}
		)
	end
	
	private
	
	def send_signal(object)
		begin
			@stream.puts JSON.generate(object)
			@stream.flush
		rescue Errno::EPIPE # エラーが発生してbotが落ちたときの復帰処理
			@stream.close
			start_bot
			retry
		end
	end
		
	def start_bot()
		@stream = IO.popen("ruby bin/block_king/sending_bot.rb #{@token} #{NUM_SHARDS}", "r+")
	end
end
