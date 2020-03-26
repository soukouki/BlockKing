
require_relative "ui"

module UI
	
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
		def send_mention
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
		
		def choosing_items_class
			DiscordChoosingItems
		end
		def choose(choosing_items, callback: nil)
			bar_id = nil
			queue = Thread::Queue.new
			@waiting_for_message.register(
				regex_text: choosing_items.regex_text,
				user_id: @user_id,
				channel_id: @channel_id,
				callback_giving_id: lambda do |id|
					@mutex_for_bar_ids.synchronize do
						bar_id = id
						@bar_ids << id
					end
				end
			) do |rm|
				queue.push rm
			end
			# やっぱりこの部分は1スレッドのほうが処理しやすい
			result = loop do
				rm = queue.pop
				callback&.call(rm.message)
				result = choosing_items.pick(rm.message)
				next if result.nil?
				@waiting_for_message.cancel_waiting(id: bar_id)
				@mutex_for_bar_ids.synchronize do
					@bar_ids.delete(bar_id)
				end
				break result
			end
			result.call()
		end
		
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

	class DiscordChoosingItems < ChoosingItemsBase

		# コマンドもindexもない場合はうまく動かないけれど、そのケースはないと考える
		def regex_text
			commands_regex = @processes_by_commands.keys.map{|k|Regexp.escape(k)}.join("|")
			indexes_regex = (@process_checking_index.nil?)? "" : '\d+'
			"^("+[*commands_regex, *indexes_regex].join("|")+")$"
		end

		def pick(message)
			if @process_checking_index && message.match?(/^\d+$/) && @process_checking_index.call(message.to_i)
				return ->{@process_of_index.call(message.to_i)}
			end
			@processes_by_commands[message.downcase]
		end

	end
end