
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
		delimiter = (inline_code_count)? "`" : ""
		hash.map{|item,count|"#{item}を#{delimiter}#{count.with_comma}#{delimiter}"}.join(join_str)
	end
end

module IntegerWithComma
	def with_comma
		origin = self.to_s
		return origin if origin.length <= 4
		parts = []
		until origin.length < 4
			parts << origin[-3..-1]
			origin[-3..-1] = ""
		end
		parts << origin
		return parts.reverse.join(",")
	end
end
class Integer
	include IntegerWithComma
end
