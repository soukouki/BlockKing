
require_relative "game_data/texts"


class WatchingStoryHandler
	def initialize(ui:, game_table:, group_id:)
		@ui = ui
		@game_table = game_table
		@group = game_table.group(group_id)
	end
	
	def start
		stories = stories()
		if @group.nil?
			@ui.send_message("あなたはゲームに参加していないので、どのストーリーも見ることはできません。\n`Bk`コマンドでゲームに参加できます！")
			return
		end
		@ui.send_message(
			"どのストーリーを見ますか？\n"+
			stories.map.with_index(1){|story, index|"`#{index}` : #{story.brief}"}.join("\n")+
			"\n`quit` : やめる"
		)
		@ui.wait_respons() do |res|
			index = res.to_i
			if res.downcase == "quit"
				return true
			end
			unless (1..stories.length).include? index
				return false
			end
			@ui.send_message("・・・・・・・・・・")
			stories[index-1].pass_text_to(@ui)
			@ui.send_message("・・・・・・・・・・")
		end
		true
	end
	
	private
	def stories
		[
			*(@group)?
				[GameData::Story::STARTING_GAME] : [],
			*(@game_table.kings_history.include? @group)?
				[GameData::Story::WINNING_THE_KING] : [],
			*(@game_table.kings_history[0..-2].include? @group)?
				[GameData::Story::BEING_DEPRIVED_OF_KING] : [],
		]
	end
end
