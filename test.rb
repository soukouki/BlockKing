
require "pp"

require_relative "lib/block_king"
require_relative "lib/block_king_ui"

public def test(x)
	if (x==self || x===self)
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

require_relative "test/block_king"
require_relative "test/save_load"

print("\n")
