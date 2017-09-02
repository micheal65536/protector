local S = protector.intllib

local function register_door(name, def)
	-- register door
	doors.register(name, def)

	-- override door
	-- note that overriding door _a seems to override _b as well
	local real_rightclick_a = minetest.registered_nodes[name .. "_a"].on_rightclick
	minetest.override_item(name .. "_a", {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if not minetest.is_protected(pos, clicker:get_player_name()) then
				return real_rightclick_a(pos, node, clicker, itemstack, pointed_thing)
			else
				return itemstack
			end
		end,
	})
	--[[local real_rightclick_b = minetest.registered_nodes[name .. "_b"].on_rightclick
	minetest.override_item(name .. "_b", {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			return real_rightclick_b(pos, node, clicker, itemstack, pointed_thing)
			--if not minetest.is_protected(pos, clicker:get_player_name()) then
			--	return real_rightclick(pos, node, clicker, itemstack, pointed_thing)
			--else
			--	return itemstack
			--end
		end,
	})]]--
end

register_door("protector:door_wood", {
	tiles = {{ name = "[combine:38x32:0,0=doors_door_wood.png:0,16=protector_logo.png:16,16=protector_logo.png", backface_culling = true }},
	description = S("Protected Wooden Door"),
	inventory_image = "doors_item_wood.png^protector_logo.png",
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	recipe = {
		{"group:wood", "group:wood"},
		{"group:wood", "default:copper_ingot"},
		{"group:wood", "group:wood"}
	}
})
minetest.register_craft({
	output = "protector:door_wood",
	recipe = {
		{"doors:door_wood", "default:copper_ingot"}
	}
})

register_door("protector:door_steel", {
	tiles = {{ name = "[combine:38x32:0,0=doors_door_steel.png:0,16=protector_logo.png:16,16=protector_logo.png", backface_culling = true }},
	description = S("Protected Steel Door"),
	inventory_image = "doors_item_steel.png^protector_logo.png",
	groups = {cracky = 1, level = 2},
	sounds = default.node_sound_metal_defaults(),
	sound_open = "doors_steel_door_open",
	sound_close = "doors_steel_door_close",
	recipe = {
		{"default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "default:copper_ingot"},
		{"default:steel_ingot", "default:steel_ingot"}
	}
})
minetest.register_craft({
	output = "protector:door_steel",
	recipe = {
		{"doors:door_steel", "default:copper_ingot"}
	}
})

local function register_trapdoor(name, def)
	-- register trapdoor
	doors.register_trapdoor(name, def)

	-- override trapdoor
	local real_rightclick = minetest.registered_nodes[name].on_rightclick
	minetest.override_item(name, {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if not minetest.is_protected(pos, clicker:get_player_name()) then
				return real_rightclick(pos, node, clicker, itemstack, pointed_thing)
			else
				return itemstack
			end
		end,
	})
	local real_rightclick_open = minetest.registered_nodes[name .. "_open"].on_rightclick
	minetest.override_item(name .. "_open", {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if not minetest.is_protected(pos, clicker:get_player_name()) then
				return real_rightclick_open(pos, node, clicker, itemstack, pointed_thing)
			else
				return itemstack
			end
		end,
	})
end

register_trapdoor("protector:trapdoor", {
	description = S("Protected Trapdoor"),
	inventory_image = "doors_trapdoor.png^protector_logo.png",
	wield_image = "doors_trapdoor.png^protector_logo.png",
	tile_front = "doors_trapdoor.png^protector_logo.png",
	tile_side = "doors_trapdoor_side.png",
	groups = {choppy = 2, oddly_breakable_by_hand = 2, door = 1},
})
minetest.register_craft({
	output = "protector:trapdoor 2",
	recipe = {
		{"group:wood", "default:copper_ingot", "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
		{"", "", ""},
	}
})
minetest.register_craft({
	output = "protector:trapdoor",
	recipe = {
		{"doors:trapdoor", "default:copper_ingot"}
	}
})

register_trapdoor("protector:trapdoor_steel", {
	description = S("Protected Steel Trapdoor"),
	inventory_image = "doors_trapdoor_steel.png^protector_logo.png",
	wield_image = "doors_trapdoor_steel.png^protector_logo.png",
	tile_front = "doors_trapdoor_steel.png^protector_logo.png",
	tile_side = "doors_trapdoor_steel_side.png",
	sounds = default.node_sound_metal_defaults(),
	sound_open = "doors_steel_door_open",
	sound_close = "doors_steel_door_close",
	groups = {cracky = 1, level = 2, door = 1},
})
minetest.register_craft({
	output = "protector:trapdoor_steel",
	recipe = {
		{"default:copper_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot"},
	}
})
minetest.register_craft({
	output = "protector:trapdoor_steel",
	recipe = {
		{"doors:trapdoor_steel", "default:copper_ingot"}
	}
})
