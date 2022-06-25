
Recipe = Struct.new(:main_building, :auxiliary_buildings, :materials_hash, :products_hash, :production_time) do
	def can_craft?(now_location_building, adjacent_buildings, owns_items)
		main_building == now_location_building && enough_adjacent_buildings?(adjacent_buildings) && enough_items?(owns_items)
	end
	
	def enough_adjacent_buildings?(adjacent_buildings)
		auxiliary_buildings.all?{|b|adjacent_buildings.include? b}
	end
	def enough_items?(owns_items)
		materials_hash.all?{|item,count|(owns_items[item]||0) >= count}
	end
	
	def materials_to_s(**args)
		Item.count_by_items_hash_to_s(materials_hash, **args)
	end
	def products_to_s(**args)
		Item.count_by_items_hash_to_s(products_hash, **args)
	end
end

RecipeAndCount = Struct.new(:recipe, :count, :group) do
	def need_items
		recipe.materials_hash.transform_values{|c|c*count}
	end
	def products_times_count
		recipe.products_hash.transform_values{|c|c*count}
	end
	def craft_time
		(recipe.production_time * count) / Math.log(group.soldier, 3) / (Math.log(count, 7) + 1)
	end
	
	def materials_to_s(**args)
		Item.count_by_items_hash_to_s(recipe.materials_hash.transform_values{|c|c*count}, **args)
	end
	def products_to_s(**args)
		Item.count_by_items_hash_to_s(recipe.products_hash.transform_values{|c|c*count}, **args)
	end
end
