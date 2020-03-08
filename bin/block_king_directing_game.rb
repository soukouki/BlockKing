

IO.popen(%!ruby -e '$stderr.puts "e1"; $stdout.puts $stdin.gets.to_i*2; $stderr.puts "e2"'!, "r+") do |io|
	io.puts 3
	p io.gets
end

require "fileutils"

require_relative "../lib/save_load"
require_relative "../lib/combined_logger"

require_relative "../lib/block_king_ui" # reportメソッドに依存がある
require_relative "../lib/game_data"
require_relative "../lib/tutorial"

setting = YAML.load(open("setting.yaml"), symbolize_names: true)

begin
	loop do
		sleep(60 - Time.now.sec)
		
		next if game_table.nil?
		
		$logger.info "定期処理 #{Time.now}"
		game_table.turn()
		
		start_time = Time.now
		
		if start_time.min%5 == 0
			$logger.info "定時保存開始"
			save_load.save
			$logger.info "定時保存完了 #{Time.now-start_time}"
		end
		
		if start_time.min == 0
			$logger.info "毎時バックアップ"
			sl = save_load.clone
			rm_and_save = lambda do |path|
				FileUtils.remove_entry_secure(path) if Dir.exist?(path)
				sl.path = path
				sl.save()
			end
			
			rm_and_save["data/hourly-backup/#{start_time.hour}"]
			
			if start_time.hour == 0
				$logger.info "毎日バックアップ"
				rm_and_save["data/daily-backup/#{start_time.day}"]
				
				if start_time.day == 1
					$logger.info "毎月バックアップ"
					rm_and_save["data/monthly-backup/#{start_time.year}-#{start_time.month}"]
				end
			end
		end
		
		$logger.info "定期処理終了"
	end
ensure # Bend時はこの部分を実行する
	$logger.error $!.full_message
	$logger.info "例外保存開始"
	save_load&.save
	$logger.info "例外保存終了"
	$logger.info "例外終了"
end
