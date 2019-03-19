
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
	end
	
	def wait_respons(message=nil, &block)
		queue = Thread::Queue.new
		message_handler = @bot.message(in: @channel, from: @user) do |event|
			queue.push Message.new(event)
		end
		reaction_handler = @bot.reaction_add(in: @channel, from: @user, message:message) do |event|
			queue.push Reaction.new(event)
		end
		
		begin
			@wait_respons_thread = Thread.current
			result = loop do
				ret = yield(queue.pop)
				break ret if ret
			end
			
			result
		ensure
			@wait_respons_thread = nil
			@bot.remove_handler(message_handler)
			@bot.remove_handler(reaction_handler)
		end
	end
	
	def stop_waiting()
		if @wait_respons_thread
			@wait_respons_thread.kill
			@wait_respons_thread = nil
		end
	end
	
	def send_reactions(msg, args)
		# よくレートリミットで止まるので
		Thread.new do
			args
				.map{|arg|e(arg)}
				.each{|emoji|msg.create_reaction(emoji)}
		end
	end
end
