
class Battle
	def initialize(game_table:, ruler:, challenger:)
		@game_table = game_table
		@ruler = ruler
		@challenger = challenger
	end
	def battle
		case settle
		when :lose
			@ruler.weaken_at_win(false, @challenger)
			@challenger.weaken_at_lose(true, @ruler)
			:lose
		when :win
			@ruler.weaken_at_lose(false, @challenger)
			@challenger.weaken_at_win(true, @ruler)
			@game_table.set_ruler(@challenger.pos, @challenger)
			:win
		end
	end
	
	private
	
	def settle
		case (rulers_force * rand(0.9..1.1)*rand(0.9..1.1)) <=> (challengers_force * rand(0.9..1.1)*rand(0.9..1.1))
		when 1, 0 # rulerの勝利
			:lose
		when -1   # challengerの勝利
			:win
		end
	end
	def rulers_force
		@ruler.force
	end
	def challengers_force
		@challenger.force
	end
	
end

class BattleForTheKing < Battle
	def battle
		result = super()
		case result
		when :win
			@challenger.state = :winning_the_king
			@ruler.state = :being_deprived_of_king
			@ruler.log.add_text(@ruler, "「大変です！王城に・・・！」",<<~EOS)
				残念ながら、#{@challenger.name}に王城を攻撃され、負けてしまいました。
			EOS
			@game_table.game_clear(@challenger)
		when :lose
			@ruler.log.add_text(@ruler, nil,<<~EOS)
				王城に#{@challenger.name}が攻めてきましたが、なんとか撃退することができました！
			EOS
		end
		result
	end
	
	private
	
	def rulers_force
		[@ruler.force, @game_table.game_level].max
	end
	
end
