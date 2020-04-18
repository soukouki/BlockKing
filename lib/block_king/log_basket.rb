
# 命名としてはちょっと微妙だけど、仕組み上クラス名を変えられないのでこのままで

class Group < GroupBase
	class LogBasket
		def initialize
			@causes = {}
			@text_logs = []
		end
		def add_item(group, sync, cause, item, count)
			causes_empty = @causes.empty?
			@causes[cause] ||= {}
			@causes[cause][item] ||= 0
			@causes[cause][item] += count
			notify(group, "「アイテムが手に入りました！確認してみてください！」") if !sync && causes_empty
		end
		def add_text(group, text_to_notify, text)
			@text_logs << Time.now.strftime("[%m月%d日%H時%M分]")+text
			notify(group, "<@#{group.id}>\n#{text_to_notify}") if text_to_notify
		end
		def clear()
			@causes = {}
			@text_logs = []
		end
		def to_s
			@text_logs.join("\n")+(
				text = @causes
					.map do |cause, hash|
						"#{cause}、#{hash.reject{|i,c|c==0}.map{|i,c|"#{i}を`#{c}`"}.join("、")}"
					end
					.join("\n")
				(text == "")? "" : text+"、手に入れました！"
			)
		end
		private
		def notify(group, text)
			begin
				Handler.notify(group, text)
			rescue => err
				# loggerに疎結合にするため
				$logger && (
					$logger.error err.full_message
					$logger.info "エラーは無視します。"
				)
			end
		end
	end
end

