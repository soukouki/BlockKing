
# 絶対ポス
# absolute position
AbPos = Struct.new(:x, :y) do
	def to_s
		"#{x}, #{y}"
	end
	def diff_to_ab_pos(diff_x, diff_y)
		AbPos.new(x+diff_x, y+diff_y)
	end
end
AbPos::CENTER = AbPos.new(0, 0)

Item = Struct.new(:name) do
	def to_s
		name
	end
	
	# どこに置くか悩んでる
	def self.count_by_items_hash_to_s(hash, join_str: "、", inline_code_count: true)
		cc = (inline_code_count)? "`" : ""
		hash.map{|item,count|"#{item}を#{cc}#{count}#{cc}"}.join(join_str)
	end
end
