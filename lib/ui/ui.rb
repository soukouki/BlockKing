
module UI
	
	# テストの際にはこれを継承したほうがわかりやすいかなと
	class UIBase
		def send_message(text); raise NotImplementedError; end
		def send_mention; raise NotImplementedError; end
		def send_slow_message(text); raise NotImplementedError; end
		def choose(choosing_items); raise NotImplementedError; end
		def kill_waiting_respons(); raise NotImplementedError; end
	end

	class ChoosingItemsBase
		def initialize(process_checking_index:, process_of_index:, **args)
			@processes_by_commands = args.transform_keys(&:to_s)
			@process_checking_index = process_checking_index
			@process_of_index = process_of_index
		end
		def pick(message)
			if @process_checking_index && message.match? /^\d+$/ && @process_checking_index.call(message.to_i)
				return ->{@process_of_index.call(message.to_i)}
			end
			@processes_by_commands[message.downcase]
		end
	end
end