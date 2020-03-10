
require_relative "ui_base"

class DiscordUI
	def initialize(sending_message:, waiting_for_message:, user_id:, channel_id:)
		@sending_message = sending_message
		@picking_up_message = picking_up_message
		super(user_id: user_id, channel_id: channel_id)
	end
	
	def send_message(text)
		characters_count_or_less_text(2000, text).each do |p_text|
			@sending_message.send_message(@channel_id, p_text)
		end
	end
	def wait_respons(regex_text, &block)
	end
	def kill_waiting_respons()
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
