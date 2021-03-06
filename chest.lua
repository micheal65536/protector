local S = protector.intllib

local function get_chest_formspec(pos)	-- modified from default/nodes.lua
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z
	local formspec =
		"size[8,10]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"field[0.28,0.65;4,0.5;name;" .. S("Name") .. ";" .. minetest.get_meta(pos):get_string("name") .. "]" ..
		"button[4,0.317;2,0.5;change_name;" .. S("Change Name") .. "]" ..
		"list[nodemeta:" .. spos .. ";main;0,1.3;8,4;]" ..
		"list[current_player;main;0,5.85;8,1;]" ..
		"list[current_player;main;0,7.08;8,3;8]" ..
		"listring[nodemeta:" .. spos .. ";main]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0,5.85)
	return formspec
end

local function chest_lid_obstructed(pos)	-- copied from default/nodes.lua
	local above = { x = pos.x, y = pos.y + 1, z = pos.z }
	local def = minetest.registered_nodes[minetest.get_node(above).name]
	-- allow ladders, signs, wallmounted things and torches to not obstruct
	if def.drawtype == "airlike" or
			def.drawtype == "signlike" or
			def.drawtype == "torchlike" or
			(def.drawtype == "nodebox" and def.paramtype2 == "wallmounted") then
		return false
	end
	return true
end

local open_chests = {}	-- copied from default/nodes.lua

minetest.register_on_player_receive_fields(function(player, formname, fields)	-- modified from default/nodes.lua
	if formname ~= "protector:chest" then
		return
	end
	if not player then
		return
	end
	local pn = player:get_player_name()
	if not open_chests[pn] then
		return
	end
	local pos = open_chests[pn].pos

	if fields.name then
		local name = fields.name
		local meta = minetest.get_meta(pos)
		meta:set_string("name", name)
		if name ~= "" then
			meta:set_string("infotext", S("Protected Chest (@1)", name))
		else
			meta:set_string("infotext", S("Protected Chest"))
		end
	end

	if not fields.quit then
		return
	end
	local sound = open_chests[pn].sound
	local swap = open_chests[pn].swap
	local node = minetest.get_node(pos)
	open_chests[pn] = nil
	for k, v in pairs(open_chests) do
		if v.pos.x == pos.x and v.pos.y == pos.y and v.pos.z == pos.z then
			return true
		end
	end
	minetest.after(0.2, minetest.swap_node, pos, { name = swap, param2 = node.param2 })
	minetest.sound_play(sound, {gain = 0.3, pos = pos, max_hear_distance = 10})
	return true
end)

local function register_chest(name, d)	-- modified from default/nodes.lua
	local def = table.copy(d)
	def.drawtype = "mesh"
	def.visual = "mesh"
	def.paramtype = "light"
	def.paramtype2 = "facedir"
	def.legacy_facedir_simple = true
	def.is_ground_content = false

	def.on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("Protected Chest"))
		meta:set_string("name", "")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end
	def.can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end
	def.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			minetest.record_protection_violation(pos, player:get_player_name())
			return 0
		end
		return count
	end
	def.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			minetest.record_protection_violation(pos, player:get_player_name())
			return 0
		end
		return stack:get_count()
	end
	def.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			minetest.record_protection_violation(pos, player:get_player_name())
			return 0
		end
		return stack:get_count()
	end
	def.on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		minetest.log("action", player:get_player_name() .. " moves stuff in protected chest at " .. minetest.pos_to_string(pos))
	end
	def.on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name() .. " moves " .. stack:get_name() .. " to protected chest at " .. minetest.pos_to_string(pos))
	end
	def.on_metadata_inventory_take = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name() .. " takes " .. stack:get_name() .. " from protected chest at " .. minetest.pos_to_string(pos))
	end
	def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if minetest.is_protected(pos, clicker:get_player_name()) then
			minetest.record_protection_violation(pos, clicker:get_player_name())
			return itemstack
		end

		minetest.sound_play(def.sound_open, {gain = 0.3, pos = pos, max_hear_distance = 10})
		if not chest_lid_obstructed(pos) then
			minetest.swap_node(pos, { name = name .. "_open", param2 = node.param2 })
		end
		minetest.after(0.2, minetest.show_formspec, clicker:get_player_name(), "protector:chest", get_chest_formspec(pos))
		open_chests[clicker:get_player_name()] = { pos = pos, sound = def.sound_close, swap = name }
	end
	def.on_blast = function() end

	local def_opened = table.copy(def)
	local def_closed = table.copy(def)

	def_opened.mesh = "chest_open.obj"
	def_opened.drop = name
	def_opened.groups.not_in_creative_inventory = 1
	def_opened.selection_box = {
		type = "fixed",
		fixed = { -1/2, -1/2, -1/2, 1/2, 3/16, 1/2 },
		}
	def_opened.can_dig = function()
		return false
	end

	def_closed.mesh = nil
	def_closed.drawtype = nil
	def_closed.tiles[6] = def.tiles[5] -- swap textures around for "normal"
	def_closed.tiles[5] = def.tiles[3] -- drawtype to make them match the mesh
	def_closed.tiles[3] = def.tiles[3].."^[transformFX"

	minetest.register_node(name, def_closed)
	minetest.register_node(name .. "_open", def_opened)
end

register_chest("protector:chest", {
	description = S("Protected Chest"),
	tiles = {
		"default_chest_top.png",
		"default_chest_top.png",
		"default_chest_side.png",
		"default_chest_side.png",
		"default_chest_front.png^protector_logo.png",
		"default_chest_inside.png"
	},
	sounds = default.node_sound_wood_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
})
minetest.register_craft({
	output = "protector:chest",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:wood", "default:copper_ingot", "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
	}
})
minetest.register_craft({
	output = "protector:chest",
	recipe = {
		{"default:chest", "default:copper_ingot"},
	}
})
