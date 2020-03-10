
# テストの際にはこれを継承したほうがわかりやすいかなと
class UIBase
	def initialize(channel_id:, user_id:)
		@channel_id = channel_id
		@user_id = user_id
	end
	def send_message(text); raise NotImplementedError; end
	def send_slow_message(text); raise NotImplementedError; end
	def wait_respons(&block); raise NotImplementedError; end
	def kill_waiting_respons(); raise NotImplementedError; end
end
