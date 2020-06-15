
require_relative "../lib/block_king"
require_relative "../lib/ui/discord_ui"
require_relative "../lib/handler/playing_game"

pg = Handler::PlayingGame
pg.direction_of_castle(AbPos.new(0,0)).test("")
pg.direction_of_castle(AbPos.new(0,1)).test(/南(?![東西])/)
pg.direction_of_castle(AbPos.new(1,1)).test(/南西/)
pg.direction_of_castle(AbPos.new(1,0)).test(/(?<!南北)西/)
pg.direction_of_castle(AbPos.new(1,-1)).test(/北西/)
pg.direction_of_castle(AbPos.new(0,-1)).test(/北(?![東西])/)
pg.direction_of_castle(AbPos.new(-1,-1)).test(/北東/)
pg.direction_of_castle(AbPos.new(-1,0)).test(/(?<!南北)東/)
pg.direction_of_castle(AbPos.new(-1,1)).test(/南東/)
pg.direction_of_castle(AbPos.new(30,10)).test("王城は西の方向。")

$logger = Object.new
def $logger.info(text) end
def $logger.error(text) end

class TestUI < UI::UIBase
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
	def choosing_items_class()
		UI::DiscordChoosingItems
	end
	def choose(choosing_items_base, callback: nil)
		choosing_items_base.pick(@wrq.pop).call()
	end
end
srand(0)
gt = GameTable.new
tui = TestUI.new
thandler = pg.new(
	ui: tui,
	game_table: gt,
	group_id: 123,
	group_name: "TestUser"
)
Thread.new{thandler.start()}
tui.ssmq.pop.test(String) # ストーリー
tui.smq.pop.test(/チュートリアル/).test(/TestUser/)
tui.wrq << "i"
tui.smq.pop.test(/兵士 : 6/).test(/現在アイテムは持っていません。/)
tui.wrq << "X"
tui.smq.pop.test(/残念ながら負けてしまいました/)
tui.wrq << "x"
tui.smq.pop.test(/ここのアイテムはたくさんあります！/)
gt.turn()
tui.wrq << "i"
tui.smq.pop.test(/兵士 : 12/).test(/木材 : 10/)
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
tui.smq.pop.test(/銅の剣を5/)
gt.group(123).instance_variable_set(:@soldier, 1000)
gt.group(123).instance_variable_set(:@time_crafting_started, Time.now - 100) # あっ

# Timeoutになるまで止まっちゃうから、新しいHandlerを作る。上のTimeoutが経っちゃうと変になるかもしれないけど、まぁ60秒あれば終わるでしょ
tui = TestUI.new
thandler = pg.new(
	ui: tui,
	game_table: gt,
	group_id: 123,
	group_name: "TestUser"
)
Thread.new{thandler.start()}
tui.smq.pop.test(/銅の剣/)
gt.group(123).pos = AbPos.new(0, 0)
oui = TestUI.new
ohandler = pg.new(
	ui: oui,
	game_table: gt,
	group_id: 456,
	group_name: "OtherTestUser"
)
Thread.new{ohandler.start()}
oui.smq.pop.test(/OtherTestUser/)
tui.wrq << "x"
tui.ssmq.pop.test(String) # ストーリー
tui.smq.pop.test(/ゲームがクリアされました！/).test(/現在このブロックを支配しています。/)
Thread.new{ohandler.start()}
oui.smq.pop.test(/ゲームがクリアされました！/)
gt.group(456).instance_variable_set(:@soldier, 1000)
gt.turn
tui.wrq << "a"
tui.smq.pop.test(/天変地異/).test(/下位の炉を建てていたため/)
