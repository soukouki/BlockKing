# recipe_stats の改良版

require_relative "../lib/block_king"
require_relative "../lib/game_data/items_and_blocks.rb"

# 一個あたりの個数に整形
recipes_by_one = GameData::RECIPES
	.map{|r|c = r.products_hash.values.first; [r.products_hash.keys.first, r.materials_hash.transform_values{|v|1.0*v / c}]}
	.group_by{|(result, materials)|result}
	.transform_values{|rs|rs.map{|(_result, materials)|materials}}

# 鉱山などから産出するアイテム
natural_materials = (recipes_by_one.flat_map{|_result,rs|rs.flat_map{|r|r.keys}} - recipes_by_one.keys).uniq

# レシピの組み合わせを計算
dp = {} # key: result, value: [レシピ] => {material => count}

# レシピは上から作りやすい順に並んでいるので、それを上から順に使っていけば良い
recipes_by_one.each do |result, recipes|
	recipes.each do |recipe|

		# すべての材料が自然素材なら
		if (recipe.keys - natural_materials).empty?
			dp[result] = {recipe => recipe}
			next
		end

		recipe.each do |material, count|
			pp result
			exit
		end
	end
end


=begin

AとBは自然素材

レシピ
C=>{A:10,B:2}
C=>{A:10,B:10}
D=>{A:10,C:10}

dp[C] = {{C => {A:10,B:2}} => {A:10,B:2}}
dp[C] = {{C => {A:10,B:2}} => {A:10,B:2},
         {C => {A:10,B:10}} => {A:10,B:10}}
dp[D] = {{D => {A:10,C:10}, C => {A:10,B:2}} => {A:110,B:20},
				 {D => {A:10,C:10}, C => {A:10,B:10}} => {A:110,B:100}}

=end
