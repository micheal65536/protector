local S = protector.intllib

-- doors
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

-- trapdoors
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
	output = 'protector:trapdoor 2',
	recipe = {
		{'group:wood', 'default:copper_ingot', 'group:wood'},
		{'group:wood', 'group:wood', 'group:wood'},
		{'', '', ''},
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
	output = 'protector:trapdoor_steel',
	recipe = {
		{'default:copper_ingot', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot'},
	}
})
minetest.register_craft({
	output = "protector:trapdoor_steel",
	recipe = {
		{"doors:trapdoor_steel", "default:copper_ingot"}
	}
})

-- Protected Chest

minetest.register_node("protector:chest", {
	description = S("Protected Chest"),
	tiles = {
		"default_chest_top.png", "default_chest_top.png",
		"default_chest_side.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_front.png^protector_logo.png"
	},
	paramtype2 = "facedir",
	groups = {choppy = 2, oddly_breakable_by_hand = 2, unbreakable = 1},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),

	on_construct = function(pos)

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		meta:set_string("infotext", S("Protected Chest"))
		meta:set_string("name", "")
		inv:set_size("main", 8 * 4)
	end,

	can_dig = function(pos,player)

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		if inv:is_empty("main") then

			if not minetest.is_protected(pos, player:get_player_name()) then
				return true
			end
		end
	end,

	on_metadata_inventory_put = function(pos, listname, index, stack, player)

		minetest.log("action", S("@1 moves stuff to protected chest at @2",
			player:get_player_name(), minetest.pos_to_string(pos)))
	end,

	on_metadata_inventory_take = function(pos, listname, index, stack, player)

		minetest.log("action", S("@1 takes stuff from protected chest at @2",
			player:get_player_name(), minetest.pos_to_string(pos)))
	end,

	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)

		minetest.log("action", S("@1 moves stuff inside protected chest at @2",
			player:get_player_name(), minetest.pos_to_string(pos)))
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)

		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end

		return stack:get_count()
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)

		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end

		return stack:get_count()
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)

		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end

		return count
	end,

	on_rightclick = function(pos, node, clicker)

		if minetest.is_protected(pos, clicker:get_player_name()) then
			return
		end

		local meta = minetest.get_meta(pos)

		if not meta then
			return
		end

		local spos = pos.x .. "," .. pos.y .. "," ..pos.z
		local formspec = "size[8,9]"
			.. default.gui_bg
			.. default.gui_bg_img
			.. default.gui_slots
			.. "list[nodemeta:".. spos .. ";main;0,0.3;8,4;]"
			.. "button[0,4.5;2,0.25;toup;" .. S("To Chest") .. "]"
			.. "field[2.3,4.8;4,0.25;chestname;;"
			.. meta:get_string("name") .. "]"
			.. "button[6,4.5;2,0.25;todn;" .. S("To Inventory") .. "]"
			.. "list[current_player;main;0,5;8,1;]"
			.. "list[current_player;main;0,6.08;8,3;8]"
			.. "listring[nodemeta:" .. spos .. ";main]"
			.. "listring[current_player;main]"

			minetest.show_formspec(
				clicker:get_player_name(),
				"protector:chest_" .. minetest.pos_to_string(pos),
				formspec)
	end,

	on_blast = function() end,
})

-- Protected Chest formspec buttons

minetest.register_on_player_receive_fields(function(player, formname, fields)

	if string.sub(formname, 0, string.len("protector:chest_")) ~= "protector:chest_" then
		return
	end

	local pos_s = string.sub(formname,string.len("protector:chest_") + 1)
	local pos = minetest.string_to_pos(pos_s)

	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end

	local meta = minetest.get_meta(pos) ; if not meta then return end
	local chest_inv = meta:get_inventory() ; if not chest_inv then return end
	local player_inv = player:get_inventory()
	local leftover

	if fields.toup then

		-- copy contents of players inventory to chest
		for i, v in ipairs(player_inv:get_list("main") or {}) do

			if chest_inv:room_for_item("main", v) then

				leftover = chest_inv:add_item("main", v)

				player_inv:remove_item("main", v)

				if leftover
				and not leftover:is_empty() then
					player_inv:add_item("main", v)
				end
			end
		end
	
	elseif fields.todn then

		-- copy contents of chest to players inventory
		for i, v in ipairs(chest_inv:get_list("main") or {}) do

			if player_inv:room_for_item("main", v) then

				leftover = player_inv:add_item("main", v)

				chest_inv:remove_item("main", v)

				if leftover
				and not leftover:is_empty() then
					chest_inv:add_item("main", v)
				end
			end
		end

	elseif fields.chestname then

		-- change chest infotext to display name
		if fields.chestname ~= "" then

			meta:set_string("name", fields.chestname)
			meta:set_string("infotext",
				S("Protected Chest (@1)", fields.chestname))
		else
			meta:set_string("infotext", S("Protected Chest"))
		end

	end
end)

-- Protected Chest recipes

minetest.register_craft({
	output = 'protector:chest',
	recipe = {
		{'group:wood', 'group:wood', 'group:wood'},
		{'group:wood', 'default:copper_ingot', 'group:wood'},
		{'group:wood', 'group:wood', 'group:wood'},
	}
})

minetest.register_craft({
	output = 'protector:chest',
	recipe = {
		{'default:chest', 'default:copper_ingot', ''},
	}
})
