
require_relative "../lib/block_king"
require_relative "../lib/ui/ui_base"
require_relative "../lib/block_king_ui"

BlockKingUI.direction_of_castle(AbPos.new(0,0)).test("")
BlockKingUI.direction_of_castle(AbPos.new(0,1)).test(/南(?![東西])/)
BlockKingUI.direction_of_castle(AbPos.new(1,1)).test(/南西/)
BlockKingUI.direction_of_castle(AbPos.new(1,0)).test(/(?<!南北)西/)
BlockKingUI.direction_of_castle(AbPos.new(1,-1)).test(/北西/)
BlockKingUI.direction_of_castle(AbPos.new(0,-1)).test(/北(?![東西])/)
BlockKingUI.direction_of_castle(AbPos.new(-1,-1)).test(/北東/)
BlockKingUI.direction_of_castle(AbPos.new(-1,0)).test(/(?<!南北)東/)
BlockKingUI.direction_of_castle(AbPos.new(-1,1)).test(/南東/)
BlockKingUI.direction_of_castle(AbPos.new(30,10)).test("王城は西の方向。")

$logger = Object.new
def $logger.info(text) end
def $logger.error(text) end

class TestUI < UIBase
	attr_accessor :smq, :ssmq, :wrq
	
	def initialize() # なぜかこう書かないと動かなかった。なぜ？
	end
	def initialize()
		@smq = Thread::Queue.new
		@ssmq = Thread::Queue.new
		@wrq = Thread::Queue.new
	end
	def send_message(text)
		@smq << text
	end
	def send_slow_message(text)
		@ssmq << text
	end
	def wait_respons(&block)
		block.call(@wrq.pop)
	end
end
srand(0)
gt = GameTable.new
tui = TestUI.new
bui = BlockKingUI.new(
	ui: tui,
	game_table: gt,
	group_id: 123,
	group_name: "TestUser"
)
Thread.new{bui.start()}
tui.ssmq.pop.test(String) # ストーリー
tui.smq.pop.test(/チュートリアル/).test(/TestUser/)
tui.wrq << "i"
tui.smq.pop.test(/兵士 : 6/).test(/現在アイテムは持っていません。/)
tui.smq.pop # なぜかこれを入れないと動かない
tui.wrq << "X"
tui.smq.pop.test(/残念ながら負けてしまいました/)
tui.wrq << "x"
tui.smq.pop.test(/ここのアイテムはたくさんあります！/)
gt.turn()
tui.wrq << "i"
tui.smq.pop.test(/兵士 : 8/).test(/木材 : 10/)
tui.smq.pop # なぜかこれを入れないと動かない
gt.turn()
gt.turn()
gt.turn()
gt.turn()
tui.wrq << "d"
tui.smq.pop
tui.wrq << "x"
tui.smq.pop
tui.wrq << "s"
tui.smq.pop
tui.wrq << "x"
tui.smq.pop
gt.turn()
gt.turn()
gt.turn()
gt.turn()
tui.wrq << "a"
tui.smq.pop
tui.wrq << "x"
tui.smq.pop
tui.wrq << "a"
tui.smq.pop
tui.wrq << "x"
tui.smq.pop
tui.wrq << "w"
tui.smq.pop
tui.wrq << "x"
tui.smq.pop
gt.turn()
gt.turn()
tui.wrq << "w"
tui.smq.pop
tui.wrq << "x"
tui.smq.pop
tui.wrq << "c"
tui.smq.pop
tui.wrq << "1"
tui.smq.pop.test(/下炉/)
tui.wrq << "u"
tui.smq.pop
tui.wrq << "1"
tui.smq.pop
tui.wrq << "1"
tui.smq.pop
gt.group(123).instance_variable_set(:@time_crafting_started, Time.now - 60) # あっ
tui.wrq << "a"
tui.smq.pop.test(/銅の剣/)
gt.group(123).instance_variable_set(:@soldier, 1000)
gt.group(123).pos = AbPos.new(0, 0)
tui.wrq << "x"
tui.ssmq.pop.test(String) # ストーリー
tui.smq.pop.test(/ゲームがクリアされました！/).test(/現在このブロックを支配しています。/)
oui = TestUI.new
BlockKingUI.new(
	ui: oui,
	game_table: gt,
	group_id: 456,
	group_name: "OtherTestUser"
)
gt.group(456).instance_variable_set(:@soldier, 1000)
gt.turn
tui.wrq << "a"
tui.smq.pop.test(/天変地異/).test(/下位の炉を建てていたため/)
