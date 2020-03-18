
class Battle
	def initialize(game_table:, ruler:, challenger:)
		@game_table = game_table
		@ruler = ruler
		@challenger = challenger
	end
	def battle
		case (@ruler.force * rand(0.95..1.05)) <=> (@challenger.force * rand(0.95..1.05))
		when 1, 0 # rulerの勝利
			@ruler.weaken_at_win(false)
			@challenger.weaken_at_lose(true)
			:lose
		when -1   # challengerの勝利
			@ruler.weaken_at_lose(false)
			@challenger.weaken_at_win(true)
			@game_table.set_ruler(@challenger.pos, @challenger)
			:win
		end
	end
	
end

class BattleForTheKing < Battle
	def battle
		result = super()
		if result == :win
			@challenger.state = :ending
			@game_table.game_clear(@challenger)
		end
	end
	
end
