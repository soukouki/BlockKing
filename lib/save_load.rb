
require "json"
require "fileutils"

class Hash
	def to_convertable_to_json(opt)
		if keys.all?{|k|k.is_a?(String)}
			self.map{|k,v|[k.to_convertable_to_json(opt), v.to_convertable_to_json(opt)]}.to_h
		else
			{
				"*save_load" => "Hash",
				"*values" => self.to_a.to_convertable_to_json(opt),
			}
		end
	end
	def self.from_convertable_to_json(hash, opt)
		case
		when hash["*save_load"]
			klass = Module.const_get(hash["*save_load"])
			obj = if klass == Hash
				Array.from_convertable_to_json(hash["*values"], opt).to_h
			else
				klass.from_convertable_to_json(hash, opt)
			end
			opt[:objects][hash["*object_id"]] = obj
			obj
		when hash["*reference"]
			opt[:objects][hash["*reference"]]
		else
			hash.map{|key,value|[key, value.class.from_convertable_to_json(value, opt)]}.to_h
		end
	end
end
class Array
	def to_convertable_to_json(opt)
		map{|i|i.to_convertable_to_json(opt)}
	end
	def self.from_convertable_to_json(array, opt)
		array.map{|i|i.class.from_convertable_to_json(i, opt)}
	end
end
module ConvertableToJsonSimpleValue
	def to_convertable_to_json(opt)
		self
	end
	def self.included(klass)
		klass.extend ClassMethods
	end
	module ClassMethods
		def from_convertable_to_json(obj, opt)
			obj
		end
	end
end
class Integer
	include ConvertableToJsonSimpleValue
end
class Float
	include ConvertableToJsonSimpleValue
end
class String
	include ConvertableToJsonSimpleValue
end
class TrueClass
	include ConvertableToJsonSimpleValue
end
class FalseClass
	include ConvertableToJsonSimpleValue
end
class NilClass
	include ConvertableToJsonSimpleValue
end
class Object
	def to_convertable_to_json(opt)
		klass = self.class.name
		if opt[:objects][object_id]
			{
				"*reference" => object_id,
			}
		else
			opt[:objects][object_id] = true
			{"*save_load" => klass, "*object_id" => object_id}
				.merge(
					instance_variables
						.map{|name|[name.to_s, instance_variable_get(name).to_convertable_to_json(opt)]}
						.to_h
				)
		end
	end
	def self.from_convertable_to_json(hash, opt)
		obj = self.allocate
		hash
			.select{|name,val|name.start_with?("@")}
			.each{|name,val|obj.instance_variable_set(name.to_sym, val.class.from_convertable_to_json(val, opt))}
		obj
	end
end
class Struct
	def to_convertable_to_json(opt)
		klass = self.class.name
		raise "名前がついていないStruct #{self}" if klass.nil?
		{
			"*save_load" => klass,
			"values" => values.to_convertable_to_json(opt),
		}
	end
	def self.from_convertable_to_json(hash, opt)
		new(*Array.from_convertable_to_json(hash["values"], opt))
	end
end
class Class
	def to_convertable_to_json(opt)
		{
			"*save_load" => "Class",
			"*name" => name
		}
	end
	def self.from_convertable_to_json(hash, opt)
		Module.const_get(hash["*name"])
	end
end
class Symbol
	def to_convertable_to_json(opt)
		{
			"*save_load" => "Symbol",
			"*str" => self.to_s,
		}
	end
	def self.from_convertable_to_json(hash, opt)
		hash["*str"].to_sym
	end
end
class Thread
	def self.from_convertable_to_json(hash, opt)
		Thread.new{}
	end
end
class Proc
	def self.from_convertable_to_json(hash, opt)
		Proc.new{|*args|}
	end
end
# ~~selfの情報を取得できないから、Procと同じ扱いにする~~
# レシーバーで取得できる。あとでやる
class Method
	def to_convertable_to_json(opt)
		@receiver = receiver
		@name = name.to_s
		super
	end
	def self.from_convertable_to_json(hash, opt)
		Hash.from_convertable_to_json(hash["@receiver"], opt).method(hash["@name"].to_sym)
	end
end
class UnboundMethod
	def to_convertable_to_json(opt)
		@owner = owner
		@name = name.to_s
		super
	end
	def self.from_convertable_to_json(hash, opt)
		Class.from_convertable_to_json(hash["@owner"], opt).instance_method(hash["@name"].to_sym)
	end
end



class SaveLoad
	attr_reader :value
	attr_accessor :path
	def initialize(path, default_proc)
		@path = path
		@value = if File.exist?(main_file_path)
			load()
		else
			default_proc.call()
		end
	end
	
	def save()
		FileUtils.mkdir_p(@path)
		json = @value.to_convertable_to_json({objects: {}}).to_json
		open(main_file_path, "w") do |file|
			file.puts json
		end
	end
	
	private
	
	def load()
		ha = JSON.parse(File.open(main_file_path, "r"){|f|f.read})
		@value = ha.class.from_convertable_to_json(ha, {objects: {}})
	end
	
	def main_file_path
		@path+"/main.json"
	end
end
