
require "twemoji"

module Discordrb::Events
  # Generic superclass for event handlers pertaining to adding and removing reactions
  class ReactionEventHandler < EventHandler
    # プルリクエスト時EevntContenerのreaction_addのコメント変え忘れないように！
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? ReactionEvent
      
      [
        matches_all(@attributes[:emoji], event.emoji) do |a, e|
          if a.is_a? Integer
            e.id == a
          elsif a.is_a? String
            e.name == a || e.name == a.delete(':') || e.id == a.resolve_id
          else
            e == a
          end
        end,
        # It is not DRY. The reason is that the same thing is written in MessageEventHandler.
        # DRYでない
        matches_all(@attributes[:in], event.channel) do |a, e|
          if a.is_a? String
            # Make sure to remove the "#" from channel names in case it was specified
            a.delete('#') == e.name
          elsif a.is_a? Integer
            a == e.id
          else
            a == e
          end
        end,
        # from: :bot の機能消した。プルリクエスト時注意！
        matches_all(@attributes[:from], event.user) do |a, e|
          if a.is_a? String
            a == e.name
          elsif a.is_a? Integer
            a == e.id
          else
            a == e
          end
        end,
        matches_all(@attributes[:message], event.message) do |a, e|
          if a.is_a? Integer
            a == e.id
          else
            a == e
          end
        end,
      ].reduce(true, &:&)
    end
  end
end

module Discordrb
  class Emoji
    def ==(other)
      return Discordrb.id_compare(@id, other) if @id
      return false unless other.kind_of? Emoji
      name == other.name
    end
    alias_method :eql?, :==
  end
end

module DiscordEmojiSolver
	module_function
	def e(str)
		code = Twemoji.find_by_text(
			if str[0]==":" && str[-1]==":"
				str
			else
				":#{str}:"
			end
		)
		code.to_i(16).chr(Encoding::UTF_8)
	end
end

class DiscordUIBase
	include DiscordEmojiSolver
	
	# ==で評価するのは違和感を感じるけど、===でやったら動かないからしょうがない・・・
	Message = Struct.new(:event) do
		# String#===用
		def to_str
			event.message.content
		end
		def == pair
			event.message == pair || self.to_str == pair
		end
	end
	Reaction = Struct.new(:event) do
		# String#===用
		def to_str
			event.emoji.name
		end
		def == pair
			event.emoji == pair || self.to_str == pair || self.to_str == DiscordEmojiSolver.e(pair)
		end
	end
	
	def initialize(bot: ,channel: ,user:)
		@bot = bot
		@channel = channel
		@user = user
		@wait_respons_threads = []
	end
	
	# このプログラム一番の複雑なところ！マルチスレッド注意！
	def wait_respons(message=nil, &block)
		queue = Thread::Queue.new
		is_now_exec_block = false
		message_handler = @bot.message(in: @channel, from: @user) do |event|
			queue.push Message.new(event) unless is_now_exec_block
		end
		reaction_handler = @bot.reaction_add(in: @channel, from: @user, message:message) do |event|
			queue.push Reaction.new(event) unless is_now_exec_block
		end
		
		begin
			@wait_respons_threads << Thread.current
			result = loop do
				pop = queue.pop
				is_now_exec_block = true
				ret = yield(pop)
				is_now_exec_block = false
				break ret if ret
			end
			
			result
		ensure
			# 後片付け
			@wait_respons_threads -= [Thread.current]
			@bot.remove_handler(message_handler)
			@bot.remove_handler(reaction_handler)
		end
	end
	
	def stop_waiting()
		@wait_respons_threads.each{|t|t.kill}
		@wait_respons_threads = []
	end
	
	def send_reactions(msg, args)
		# よくレートリミットで止まるので
		Thread.new do
			args
				.map{|arg|e(arg)}
				.each{|emoji|msg.create_reaction(emoji)}
		end
	end
	
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
	
	def slow_message(text)
		text
			.lines
			.map(&:chomp)
			.each{|line|sleep 1; line.empty? || msg(line)}
	end
	
end
