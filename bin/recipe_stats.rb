require_relative "../lib/block_king"

puts "前提として、複数の生産物が出ない状態を扱う"



# 一個あたりの個数に整形
recipes_by_result = GameData::CREATION_ITEMS_HASH
	.flat_map{|facility,recipes|recipes}
	.inject({}, &:merge)
	.map{|materials,results|c = results.values.first; [results.keys.first, materials.transform_values{|v|1.0*v / c}]}
	.group_by{|(result, materials)|result}
	.transform_values{|rs|rs.map{|(_result, materials)|materials}}

natural_materials = (recipes_by_result.flat_map{|_result,rs|rs.flat_map{|r|r.keys}} - recipes_by_result.keys).uniq
known_recipes = []
known_parts_recipes = []

# 上から順に作り安い順にアイテムが並んでないとバグる
loop do
	# 通常のレシピについて
	target, target_materials = recipes_by_result.find{|result,rs|!(known_recipes.include?(result)) && (rs.flat_map{|r|r.keys} - natural_materials).empty?}
	known_recipes << target if target
	
	# ループするレシピについて・・・
	if target.nil?
		
		target, _target_material = recipes_by_result
			.reject{|result,_rs|known_recipes.include? result}
			.flat_map{|result,rs|rs.map{|recipe|[result, recipe]}}
			.reject{|(result,recipe)|known_parts_recipes.include? [result, recipe]}
			.find{|(result,recipe)|(recipe.keys - natural_materials).empty?}
		
		break if target.nil?
		
		target_materials = recipes_by_result[target]
			.reject{|recipe|known_parts_recipes.include? [target, recipe]}
			.select{|recipe|(recipe.keys - natural_materials).empty?}
		known_parts_recipes += target_materials.map{|tm|[target, tm]}
		
		puts "↓ループ"
	end
	
	break if target.nil?
	
	puts "**#{target.name}**"
	
	# ターゲットのアイテムが含まれるレシピに埋め込んでいく
	recipes_by_result.transform_values! do |recipes|
		recipes
			.flat_map do |recipe|
				count = recipe[target]
				if count
					recipe[target] = nil
					recipe.compact!
					target_materials.map{|target_material|recipe.merge(target_material.transform_values{|v|v*count}){|_k,a,b|a+b}}
				else
					[recipe]
				end
			end
			.uniq
	end
end

item = (GameData::SORT_ORDER - natural_materials)
	.each.with_index{|item, idx|puts "#{idx}:#{item.name}"}
	.tap{||puts "どのアイテムを表示しますか？(すべての場合は最後の数字の次の値を)"}[gets.to_i]

puts "上書き保存する先のファイル名(保存しない場合はそのまま)"
file_name = gets.chomp
output = if file_name.empty?
	STDOUT
else
	File.open(file_name, "w")
end

((item.nil?)? recipes_by_result : recipes_by_result.select{|r,_|r == item})
	.each do |result,recipes|
		output.puts result.name
		recipes
			.each.with_index(1) do |recipe, idx|
				output.puts idx
				output.puts "\t"+(
					recipe
						.sort_by{|m,_c|GameData::SORT_ORDER.index(m) || -1}
						.reverse
						.map{|materials,count|"#{materials.name} : #{count}"}
						.join("\n\t")
				)
			end
	end


=begin
BとCは判明
A=>{B:10,C:2}
D=>{A:10,B:100}

A=>{B:10,C:2}はすべて判明してるから展開

Aは別のリストに移動
A=>{B:10,C:2}
D=>{B:200,C:20} こう！
=end
