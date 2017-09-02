-- protector placement tool (original idea and code by Shara)
local S = protector.intllib

minetest.register_craftitem("protector:tool", {
	description = S("Protector Placer Tool (stand near protector, face direction and use)"),
	inventory_image = "protector_display.png^protector_logo.png",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		-- require permissions if permissions are enabled
		if protector.use_privileges and not minetest.check_player_privs(user:get_player_name(), {protection_place = true}) then
			return
		end

		-- check for protector near player (2 block radius)
		local player_pos = user:getpos()
		local protectors = minetest.find_nodes_in_area(vector.subtract(player_pos, 2), vector.add(player_pos, 2), {"protector:protect", "protector:protect2"})
		local pos
		for _, protector_pos in ipairs(protectors) do
			local meta = minetest.get_meta(protector_pos)
			if protector.is_owner(meta, user:get_player_name()) then
				pos = protector_pos
				break
			end
		end
		if not pos then
			minetest.chat_send_player(user:get_player_name(), S("No protector found."))
			return
		end

		-- get direction player is facing
		local player_direction = minetest.dir_to_facedir(user:get_look_dir())
		local player_pitch =  user:get_look_pitch()
		local protector_gap = (protector.radius * 2) + 1
		local protector_offset = {x = 0, y = 0, z = 0}

		-- set placement coords
		if player_pitch > 1.2 then	-- up
			protector_offset.y = protector_gap
		elseif player_pitch < -1.2 then	-- down
			protector_offset.y = -protector_gap
		elseif player_direction == 0 then	-- north
			protector_offset.z = protector_gap
		elseif player_direction == 1 then	-- east
			protector_offset.x = protector_gap
		elseif player_direction == 2 then	-- south
			protector_offset.z = -protector_gap
		elseif player_direction == 3 then	-- west
			protector_offset.x = -protector_gap
		end

		-- new position
		local new_pos = {x = pos.x + protector_offset.x, y = pos.y + protector_offset.y, z = pos.z + protector_offset.z}

		-- check if placing a protector overlaps existing area or the new location is protected against this player
		if protector.check_overlap(new_pos, user) or minetest.is_protected(new_pos, user:get_player_name()) then
			return
		end

		-- check if a protector already exists
		local existing_name = minetest.get_node(new_pos).name
		if existing_name == "protector:protect" or existing_name == "protector:protect2" then
			minetest.chat_send_player(user:get_player_name(), S("Protector already in place."))
			return
		end

		if protector.tool_prevent_floating and not minetest.check_player_privs(user:get_player_name(), {protection_bypass = true}) then
			-- check if protector is on the ground
			local below_name = minetest.get_node({x = new_pos.x, y = new_pos.y - 1, z = new_pos.z}).name
			if below_name == "ignore" or minetest.registered_nodes[below_name].buildable_to then
				minetest.chat_send_player(user:get_player_name(), S("Cannot place protector in the air at @1.", minetest.pos_to_string(new_pos)))
				return
			end
		end

		if protector.tool_prevent_underground and not minetest.check_player_privs(user:get_player_name(), {protection_bypass = true}) then
			-- check if protector location is already occupied
			local existing_name = minetest.get_node(new_pos).name
			if existing_name == "ignore" or not minetest.registered_nodes[existing_name].buildable_to then
				minetest.chat_send_player(user:get_player_name(), S("Cannot place protector underground at @1.", minetest.pos_to_string(new_pos)))
				return
			end
		end

		-- take protector (block first then logo)
		local inv = user:get_inventory()
		local protector_node_name
		if inv:contains_item("main", "protector:protect") then
			inv:remove_item("main", "protector:protect")
			protector_node_name = "protector:protect"
		elseif inv:contains_item("main", "protector:protect2") then
			inv:remove_item("main", "protector:protect2")
			protector_node_name = "protector:protect2"
		else
			minetest.chat_send_player(user:get_player_name(), S("No protectors available to place."))
			return
		end

		-- place protector
		minetest.set_node(new_pos, {name = protector_node_name, param2 = 1})

		-- call node callbacks
		minetest.registered_nodes[protector_node_name].after_place_node(new_pos, user)

		-- copy configuration if holding sneak when using tool
		if user:get_player_control().sneak then
			local existing_meta = minetest.get_meta(pos)
			local new_meta = minetest.get_meta(new_pos)
			if existing_meta and new_meta then
				protector.set_member_list(new_meta, protector.get_member_list(existing_meta))
				new_meta:set_int("members_can_change", existing_meta:get_int("members_can_change"))
			end
		end

		minetest.chat_send_player(user:get_player_name(), S("Protector placed at @1.", minetest.pos_to_string(new_pos)))
	end,
})

minetest.register_craft({
	output = "protector:tool",
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "protector:protect", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	}
})
