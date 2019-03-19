
require "pp"

require_relative "lib/block_king"

public def test(x)
	if x===self
		print("o")
	else
		puts "\n"+
			"not ok (#{self.class})\n"+
			"#{(self.kind_of? String)? self : to_readable_string(self)} !== (#{x.class})\n"+
			"#{to_readable_string(x)}"+
			"#{caller().join("\n")}"
	end
end
def to_readable_string o
	case o
	when Regexp
		o.to_s
	else
		PP.pp(o, "", 120)
	end
end

Group.direction_of_castle(AbPos.new(0,0)).test("")
Group.direction_of_castle(AbPos.new(0,1)).test(/南(?![東西])/)
Group.direction_of_castle(AbPos.new(1,1)).test(/南西/)
Group.direction_of_castle(AbPos.new(1,0)).test(/(?<!南北)西/)
Group.direction_of_castle(AbPos.new(1,-1)).test(/北西/)
Group.direction_of_castle(AbPos.new(0,-1)).test(/北(?![東西])/)
Group.direction_of_castle(AbPos.new(-1,-1)).test(/北東/)
Group.direction_of_castle(AbPos.new(-1,0)).test(/(?<!南北)東/)
Group.direction_of_castle(AbPos.new(-1,1)).test(/南東/)
Group.direction_of_castle(AbPos.new(30,10)).test("王都は西の方向。")
