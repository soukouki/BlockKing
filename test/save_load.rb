
require_relative "../lib/save_load"

S1 = Struct.new(:v)
class C1
	attr_accessor :v
	S2 = Struct.new(:v)
	def initialize(v)
		@v = v
	end
	class C2
	end
end
S3 = Struct.new(:v1, :v2)
class C3
	attr_accessor :v1, :v2
	def initialize(v1, v2)
		@v1 = v1
		@v2 = v2
	end
end

path = File.expand_path(File.dirname(__FILE__))+"/test_db"
if File.exist?(path+"/main.json")
	File.delete(path+"/main.json")
	Dir.delete(path)
end

def ファイル関連()
	path = File.expand_path(File.dirname(__FILE__))+"/test_db"
	sl1 = SaveLoad.new(path, ->{S1.new(1)})
	s1 = sl1.value
	s1.v.test(1) # default
	s1.v = 2
	s1.v.test(2)
	s2 = sl1.value
	# 同じ値を指していることを確認
	s2.v.test(2)
	s2.v = 3
	File.exist?(path+"/main.json").test(false)
	sl1.save
	File.exist?(path+"/main.json").test(true)
	
	sl2 = SaveLoad.new(path, ->{S1.new(1)})
	s3 = sl2.value
	s3.v.test(3) # 引き継いでいることを確認
	s3.v = 4
	s1.v.test(3) # 同じ値を指していないことを確認
	
	File.delete(path+"/main.json")
	Dir.delete(path)
end
ファイル関連()

def クラス関連()
	path = File.expand_path(File.dirname(__FILE__))+"/test_db"
	
	sl1 = SaveLoad.new(path, lambda do
		C1.new([S1.new(:foo), C1::S2.new(:bar), C1::C2.new])
	end)
	sl1.save
	
	sl2 = SaveLoad.new(path, ->{ここは来ないはず})
	File.delete(path+"/main.json")
	sl2.save
	
	sl3 = SaveLoad.new(path, ->{ここは来ないはず})
	v3 = sl3.value
	
	v3.v[0].test(S1.new(:foo))
	
	File.delete(path+"/main.json")
	Dir.delete(path)
end
クラス関連()

def 基本的な値関連()
	path = File.expand_path(File.dirname(__FILE__))+"/test_db"
	
	ha1 = [
		"a",
		{
			"b" => 111,
			{"c" => "d"} => 222,
		},
		"e"
	]
	
	sl1 = SaveLoad.new(path, ->{ha1})
	sl1.save
	
	sl2 = SaveLoad.new(path, ->{ここは来ないはず})
	v2 = sl2.value
	v2.test(ha1)
	
	File.delete(path+"/main.json")
	Dir.delete(path)
end
基本的な値関連()

def 値関連()
	path = File.expand_path(File.dirname(__FILE__))+"/test_db"
	
	sl1 = SaveLoad.new(path, lambda do
		[
			Thread.new{},
			Mutex.new{},
			Proc.new{},
			->(a){a},
			C1,
			C1.instance_method(:v),
			C1.new(1).method(:v),
		]
	end)
	sl1.save
	
	sl2 = SaveLoad.new(path, ->{ここは来ないはず})
	v2 = sl2.value
	v2[0].class.test(Thread)
	v2[1].synchronize{}
	v2_2 = v2[2]
	v2_2.call()
	v2_2.arity.test(-1)
	v2[3].call(:foo).test(nil) # 結果は常にnilになる
	v2[4].test(C1)
	v2[5].test(C1.instance_method(:v))
	v2[6].call.test(1) # 呼べる
	
	File.delete(path+"/main.json")
	Dir.delete(path)
	
	sl3 = SaveLoad.new(path, lambda do
		{
			"a" => "a",
			:b => "b",
			1 => "c",
			1.0 => "d",
			C1 => "e",
			S1.new("f") => "f",
			C1.new("g") => "g",
			["h"] => "h",
			{"i" => "iv"} => "i",
		}
	end)
	sl3.save
	
	sl4 = SaveLoad.new(path, ->{ここは来ないはず})
	v4 = sl4.value
	v4["a"].test("a")
	v4[:b].test("b")
	v4[1].test("c")
	v4[1.0].test("d")
	v4[C1].test("e")
	v4[S1.new("f")].test("f")
	v4[S1.new("_")].test(nil)
	v4[["h"]].test("h")
	v4[["_"]].test(nil)
	v4[{"i"=>"iv"}].test("i")
	v4[{"_"=>"iv"}].test(nil)
	v4[{"i"=>"_"}].test(nil)
	
	File.delete(path+"/main.json")
	Dir.delete(path)
	
	sl5 = SaveLoad.new(path, lambda do
		[
			{S1.new({1 => 2}) => S1.new({3 => 4})},
			{C1.new({1 => 2}) => C1.new({3 => 4})},
		]
	end)
	sl5.save
	
	sl6 = SaveLoad.new(path, ->{ここは来ないはず})
	v6 = sl6.value
	v6[0].test({S1.new({1 => 2}) => S1.new({3 => 4})})
	v6[1].keys[0].v.test({1 => 2})
	v6[1].values[0].v.test({3 => 4})
	
	File.delete(path+"/main.json")
	Dir.delete(path)
	
	sl7 = SaveLoad.new(path, lambda do
		C1.new(C1.new({"foo" => :bar}))
	end)
	sl7.save
	
	sl8 = SaveLoad.new(path, ->{ここは来ないはず})
	v8 = sl8.value
	v8.v.v["foo"].test(:bar)
	
	File.delete(path+"/main.json")
	Dir.delete(path)
	
	sl9 = SaveLoad.new(path, lambda do
		[Time.new(2019,7,11,1,2,3,3600*9), Time.new(2019,7,11,1,2,3.123456789,3600*9)]
	end)
	sl9.save
	
	sl10 = SaveLoad.new(path, ->{ここは来ないはず})
	v10 = sl10.value
	v10[0].test(Time.new(2019,7,11,1,2,3,3600*9))
	v10_t1 = Time.new(2019,7,11,1,2,3.123456789,3600*9)
	# 浮動少数あたりの関係でほんのちょっとだけ誤差が出る
	(v10_t1<v10[1]+0.0000000000000001).test(true)
	(v10[1]<v10_t1).test(true)
	
	File.delete(path+"/main.json")
	Dir.delete(path)
end
値関連()

def 参照について
	path = File.expand_path(File.dirname(__FILE__))+"/test_db"
	
	c1 = C1.new(1)
	
	sl1 = SaveLoad.new(path, ->{[c1, {c1 => C1.new(c1)}]})
	sl1.save
	
	sl2 = SaveLoad.new(path, ->{ここは来ないはず})
	v2 = sl2.value
	v2c1 = v2[0]
	v2[0].test(v2c1)
	v2[1].keys[0].test(v2c1)
	v2[1][v2c1].v.test(v2c1)
	
	File.delete(path+"/main.json")
	Dir.delete(path)
	
	c3 = S1.new(1)
	
	sl3 = SaveLoad.new(path, ->{[c3, {c3 => S1.new(c3)}]})
	sl3.save
	
	sl4 = SaveLoad.new(path, ->{ここは来ないはず})
	v4 = sl4.value
	v4c3 = v4[0]
	v4[0].test(v4c3)
	v4[1].keys[0].test(v4c3)
	v4[1][v4c3].v.test(v4c3)
	
	File.delete(path+"/main.json")
	Dir.delete(path)
	
	c5 = C1.new(123)
	c5.v = S1.new(c5)
	sl5 = SaveLoad.new(path, lambda do
		C3.new({a:c5}, S1.new(c5))
	end)
	sl5.save
	
	sl6 = SaveLoad.new(path, ->{ここは来ないはず})
	v6 = sl6.value
	# 読み込めることを確認
	
	File.delete(path+"/main.json")
	Dir.delete(path)
end
参照について()

def オブジェクトについて()
	path = File.expand_path(File.dirname(__FILE__))+"/test_db"
	
	sl1 = SaveLoad.new(path, ->{C1.new(:foo)})
	sl1.save
	
	sl2 = SaveLoad.new(path, ->{ここは来ないはず})
	v2 = sl2.value
	v2.to_s.test(/^#<C1:/)
	
	File.delete(path+"/main.json")
	Dir.delete(path)
end
オブジェクトについて()
