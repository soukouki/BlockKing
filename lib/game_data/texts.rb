
module GameData
	
	# 1 舞い降りた
	# 2 移動できた
	# 3 支配できた
	# 4 更地を支配できた
	# 5 銅の剣ができた
	# 6 火の剣ができた
	# 7 魔法結晶ができた
	TIPS_LIST = {
		<<~EOS => 1..4,
			「BlockKingは、資源を支配してアイテムを集め、更地に施設を建てて剣を作るゲームです！
			さぁ、まずは銅の剣を作りましょう！木材と銅、そして下位の炉が必要です！」
		EOS
		<<~EOS => 1..4,
			「アイテムは、ブロックを支配した状態で1分くらい待つと手に入ります。
			私達は仕事が速いんです……！」
		EOS
		<<~EOS => 2..4,
			「剣を作るには、素材を集め、更地を支配し、施設を建てないといけません！
			面倒ですね！」
		EOS
		<<~EOS => 2..5,
			「リストの下の方にある建物では、もっと強い剣を作れるらしいです。
			兵士にはできるだけ強い武器をもたせてあげたいですね！」
		EOS
		<<~EOS => 2..5,
			「剣は作って持っていれば勝手に使ってくれるそうです！
			でも、兵士の数を超えたら扱い切れなさそうですね……」
		EOS
		<<~EOS => 3..6,
			「強い武器はどれか・・？
			いつもアイテム一覧では下の方に強い武器を並べてるので、それを見ればわかります！」
		EOS
		<<~EOS => 3..6,
			「王都に近づくと、敵が強くなります。敵が強くなると、アイテムがいっぱい手に入ります。
			つまり、王都に近づくと、アイテムがいっぱい・・？」
		EOS
		<<~EOS => 5..6,
			「建物を隣接させることによって、新たに使えるようになるレシピがあるみたいです。
			いい空き地を見つけてみましょう！」
		EOS
		<<~EOS => 5..6,
			「建物を隣接させるときは、東西南北の4マスだけです！斜めには使えません！」
		EOS
		<<~EOS => 5..7,
			「兵士がいっぱいいると、作業のスピードも上がってアイテムが集めやすくなります！
			いっぱいアイテムを集めるときは、いっぱい戦闘をして兵士を集めましょう！」
		EOS
		<<~EOS => 5..7,
			「ちなみに、施設は壊し合ったり、共有したりできるそうです。
			他のグループと一緒に攻略するのも面白そうですね！」
		EOS
		<<~EOS => 6..8,
			「アイテムの収集やクラフトは、みんなでやったほうが早いですよね！
			兵士が多くなれば、一瞬で終わるかもしれないですね！」
		EOS
		<<~EOS => 6..8,
			「ずーっと同じクラフトを続けてると、だんだんと慣れて早く作れるようになります！
			いろんなのをバラバラに作るよりも、楽に早くできますね！」
		EOS
	}
	
	
	module Tutorial
		TutorialLevelAndText = Struct.new(:level, :text) do
			def text
				"<チュートリアル>\n"+self[:text]
			end
		end
	end
	class << Tutorial
		
		def before_displaying_screen(group)
			arr = []
			if group.tutorial_level == 0 || group.tutorial_level == 0
				arr << Tutorial::TutorialLevelAndText.new(1, <<~EOS)
					「#{group.name}さん！はじめまして！
					移動の仕方は、この画面から
						上(北)には`w`
						左(西)には`a`
						右(東)には`d`
						下(南)には`s` です！」
				EOS
			end
			
			# クラフト完了のイベントが追えなくなったのでここに
			items = group.items
			if group.tutorial_level == 4 && (items[GameData::COPPER_SWORD] || 0) > 0
				arr << Tutorial::TutorialLevelAndText.new(5, <<~EOS)
					「銅の剣ができました！みんな使ってみてます！
					この調子で鉄の剣も作っていきましょう！
					ちなみに、敵が強いほどいっぱいアイテムが手に入るそうですよ？」
				EOS
			end
			if group.tutorial_level == 5 && (items[GameData::FIRE_SWORD] || 0) > 0
				arr << Tutorial::TutorialLevelAndText.new(6, <<~EOS)
					「おお！ついに火の剣ができました！
					これから先は魔法との付き合いが重要になりますね！」
				EOS
			end
			if group.tutorial_level == 6 && (items[GameData::MAGIC_CRYSTAL] || 0) > 0
				arr << Tutorial::TutorialLevelAndText.new(7, <<~EOS)
					「つ、ついに劣化してない魔法結晶が作れました！
					これを使って更に先の世界を目指しましょう！」
				EOS
			end
			arr
		end
		
		def after_moving(group)
			arr = []
			if group.tutorial_level == 1
				arr << Tutorial::TutorialLevelAndText.new(2, <<~EOS)
					「無事に移動できました！
					次は戦闘です！
					敵は王城から離れるほど弱くなります！自分たちにあった強さの敵を選びましょう！」
				EOS
			end
			arr
		end
		
		def after_winning(group, block)
			arr = []
			if group.tutorial_level == 2 || group.tutorial_level == 3 and block.empty?
				arr << Tutorial::TutorialLevelAndText.new(4, <<~EOS)
					「#{group.name}さん！ここにはなにか建物を建てられそうですよ！
					炉を作り、銅の剣を作りましょう！
					とりあえず、炉を作るには木材が必要ですね！」
				EOS
			end
			if group.tutorial_level == 2 && !block.empty?
				arr << Tutorial::TutorialLevelAndText.new(3, <<~EOS)
					「上手く支配できましたね！それにしてもここは資源が採れそうです、ここで1分くらい待ってくださいね！私が資源を採っておきます。
					あと、あっちの方には更地があって、なにか建てられそうですよ？銅と木材を手に入れたら、支配してみましょうよ！」
				EOS
			end
			arr
		end
	end
	
	
	class Story
		def initialize(text)
			@text = text
		end
		def pass_text_to(ui, group)
			ui.send_slow_message(@text)
		end
		
		STARTING_GAME = Story.new(<<~EOS)
			戦火が平穏を焼き払い、力のみが意味を成すこの王国。その果ての村では───
			青年は、剣を握る。
			偉大なる父の、遺志を果たす為に。
			遥か過去にて奪われた玉座を、取り戻す為に。
			王の血を継ぐ青年が、果ての村から先の見えない道を進む。
			「大丈夫だ。この道は、玉座へと続いている」
		EOS
		WINNING_THE_KING = Story.new(<<~EOS)
			戦火は鎮まり、力など意味を成さなくなったこの王国。その中心の王城にて───
			青年は、血に塗れた冠を被る。
			亡き父の遺志通り、玉座を奪還し、新たなる王が誕生したことを民に示す為に。
			空席となった玉座へ、踏みしめて来た道の終着点へ青年は腰を下ろす。
			｢父さん。これが、貴方の見たかった景色か？｣
		EOS
		BEING_DEPRIVED_OF_KING = Story.new(<<~EOS)
			青年が窮屈なばかりの生活から抜け出し、各地を転々とし始めてから、数年。
			久しく戻った王国では、青年の玉座は奪われ、またも力が全てを飲み込む時代へと変わり果てようとしていた。
			そんな中、反逆者として命を狙われた青年はかつての戦友達に協力を仰ぎ、命からがら逃亡した。
			振り出しに戻った果てなき道。しかし青年には、自分と志を共にする戦友がいる。青年が折れることはない。
			「その冠を、返してもらおうか」
		EOS
	end
	
end
