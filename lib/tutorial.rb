
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
				リーダー！はじめまして！
				移動の仕方は、この画面から
					上(北)には`w`
					左(西)には`a`
					右(東)には`d`
					下(南)には`s` です！
			EOS
		end
		
		# クラフト完了のイベントが追えなくなったのでここに
		items = group.items
		if group.tutorial_level == 4 && (items[GameData::COPPER_SWORD] || 0) > 0
			arr << Tutorial::TutorialLevelAndText.new(5, <<~EOS)
				銅の剣ができました！みんな使ってみてます！
				この調子で鉄の剣も作っていきましょう！
				ちなみに、敵が強いほどいっぱいアイテムが手に入るそうですよ？
			EOS
		end
		if group.tutorial_level == 5 && (items[GameData::FIRE_SWORD] || 0) > 0
			arr << Tutorial::TutorialLevelAndText.new(6, <<~EOS)
				おお！ついに火の剣ができました！
				これから先は魔法との付き合いが重要になりますね！
			EOS
		end
		if group.tutorial_level == 6 && (items[GameData::MAGIC_CRYSTAL] || 0) > 0
			arr << Tutorial::TutorialLevelAndText.new(7, <<~EOS)
				つ、ついに劣化してない魔法結晶が作れました！
				これを使って更に先の世界を目指しましょう！
			EOS
		end
		arr
	end
	
	def after_moving(group)
		arr = []
		if group.tutorial_level == 1
			arr << Tutorial::TutorialLevelAndText.new(2, <<~EOS)
				無事に移動できました！
				次は戦闘です！
				敵は王城から離れるほど弱くなります！自分たちにあった強さの敵を選びましょう！
			EOS
		end
		arr
	end
	
	def after_winning(group, block)
		arr = []
		if group.tutorial_level == 2 || group.tutorial_level == 3 and block.empty?
			arr << Tutorial::TutorialLevelAndText.new(4, <<~EOS)
				リーダー！ここにはなにか建物を建てられそうですよ！
				炉を作り、銅の剣を作りましょう！
				とりあえず、炉を作るには木材が必要ですね！
			EOS
		end
		if group.tutorial_level == 2 && !block.empty?
			arr << Tutorial::TutorialLevelAndText.new(3, <<~EOS)
				上手く支配できましたね！それにしてもここは資源が採れそうです、ここで1分くらい待ってくださいね！私が資源を採っておきます。
				あと、あっちの方には更地があって、なにか建てられそうですよ？銅と木材を手に入れたら、支配してみましょうよ！
			EOS
		end
		arr
	end
end
