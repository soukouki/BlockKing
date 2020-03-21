
require_relative "ui_base"

class DiscordUI
	def initialize(sending_message:, waiting_for_message:, user_id:, channel_id:, logger:)
		@sending_message = sending_message
		@waiting_for_message = waiting_for_message
		@channel_id = channel_id
		@user_id = user_id
		@logger = logger
		@bar_ids = []
		@mutex_for_bar_ids = Thread::Mutex.new
	end
	
	def send_message(text)
		characters_count_or_less_text(2000, text).each do |p_text|
			@sending_message.send_message(@channel_id, p_text)
		end
	end
	def mention
		send_message("<@#{@user_id}>")
	end
	def send_slow_message(text)
		text
			.lines
			.map(&:chomp)
			.each do |line|
				sleep 3
				line.empty? || send_message(line)
			end
		sleep 4
	end
	# ブロックの戻り値がfalse(nil)のときはループし続ける
	def wait_respons(regex_text: nil, &block)
		bar_id = nil
		queue = Thread::Queue.new
		@waiting_for_message.register(
			regex_text: regex_text,
			user_id: @user_id,
			channel_id: @channel_id,
			callback_giving_id: lambda do |id|
				bar_id = id
				@mutex_for_bar_ids.synchronize do
					@bar_ids << id
				end
			end,
		) do |rm|
			queue.push rm
		end
		loop do
			rm = queue.pop
			result = block.call(rm.message)
			next unless result
			@logger.info "#<#{rm.channel_id}>@#{rm.user_name}(#{rm.user_id}) : command : `#{rm.message}`"
			@waiting_for_message.cancel_waiting(id: bar_id)
			@mutex_for_bar_ids.synchronize do
				@bar_ids.delete(bar_id)
			end
			break
		end
	end
	# 正確にはsynchronizeしたあとに新たなwaitingを追加する処理があった場合、うまく殺せない
	# だけどその可能性は実行されるタイミングを考えるとかなり低いので、今回は考えない
	def kill_waiting_respons()
		@mutex_for_bar_ids.synchronize do
			@bar_ids.each do |id|
				@waiting_for_message.cancel_waiting(id: id)
			end
			@bar_ids = []
		end
	end
	
	private
	
	# 結果の配列のテキストの最後の改行は、origin_textによる
	# n文字以上改行がないテキストも受け入れるから少し長い
	def characters_count_or_less_text(n, origin_text)
		origin_text
			.lines
			.inject([]) do |arr,part_s| # なんか汚い
				new_parts = (part_s.chomp.length/n.to_f)
					.ceil
					.times
					.map.with_index do |i|
						part_s[i*n..(i+1)*n]
					end
				
				new_parts.inject(arr) do |arr, part|
					if (arr.last||"").length+part.length >= n
						arr+[part]
					else
						arr[0..-2]+[(arr[-1]||"")+part]
					end
				end
			end
	end
end
