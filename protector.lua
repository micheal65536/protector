local S = protector.intllib

-- return list of members as a table
protector.get_member_list = function(meta)
	return meta:get_string("members"):split(" ")
end

-- write member list table in protector meta as string
protector.set_member_list = function(meta, list)
	meta:set_string("members", table.concat(list, " "))
end

-- check if player name is owner
protector.is_owner = function(meta, name)
	return name == meta:get_string("owner")
end

-- check if player name is a member
protector.is_member = function (meta, name)
	for _, n in pairs(protector.get_member_list(meta)) do
		if n == name then
			return true
		end
	end
	return false
end

-- add player name to table as member
protector.add_member = function(meta, name)
	if protector.is_owner(meta, name) or protector.is_member(meta, name) then
		return
	end

	local list = protector.get_member_list(meta)
	table.insert(list, name)
	protector.set_member_list(meta, list)
end

-- remove player name from table
protector.del_member = function(meta, name)
	local list = protector.get_member_list(meta)
	for i, n in pairs(list) do
		if n == name then
			table.remove(list, i)
			break
		end
	end
	protector.set_member_list(meta, list)
end

-- check if a protection node placed at a particular position would overlap a conflicting protected area
protector.check_overlap = function(pos, player)
	-- make sure protector doesn't overlap into protected spawn area
	if protector.inside_spawn(pos, protector.radius) then
		minetest.chat_send_player(player:get_player_name(), S("Spawn has been protected up to a @1 block radius.", protector.spawn))
		return true
	end

	-- make sure protector doesn't overlap any other player's area
	local nodes = minetest.find_nodes_in_area(
		{x = pos.x - protector.radius * 2, y = pos.y - protector.radius * 2, z = pos.z - protector.radius * 2},
		{x = pos.x + protector.radius * 2, y = pos.y + protector.radius * 2, z = pos.z + protector.radius * 2},
		{"protector:protect", "protector:protect2"})
	local overlaps = false
	local owner = ""
	for _, protector_pos in ipairs(nodes) do
		local meta = minetest.get_meta(protector_pos)
		if not protector.is_owner(meta, player:get_player_name()) then
			overlaps = true
			owner = meta:get_string("owner")
		end
	end
	if overlaps == true then
		minetest.chat_send_player(player:get_player_name(), S("Overlaps into @1's protected area.", owner))
		return true
	end

	return false
end

-- override minetest.is_protected to enforce protection
local real_is_protected = minetest.is_protected
function minetest.is_protected(pos, playername)
	playername = playername or ""	-- nil check

	-- protection_bypass privileged users can override protection
	if minetest.check_player_privs(playername, {protection_bypass = true}) then
		return real_is_protected(pos, playername)
	end

	local protected = false

	-- check for spawn area protection
	if protector.inside_spawn(pos, 0) then
		minetest.chat_send_player(playername, S("Spawn has been protected up to a @1 block radius.", protector.spawn))
		protected = true
	end

	-- find protectors
	local nodes = minetest.find_nodes_in_area(
		{x = pos.x - protector.radius, y = pos.y - protector.radius, z = pos.z - protector.radius},
		{x = pos.x + protector.radius, y = pos.y + protector.radius, z = pos.z + protector.radius},
		{"protector:protect", "protector:protect2"})
	for _, protector_pos in ipairs(nodes) do
		local meta = minetest.get_meta(protector_pos)
		if not protector.is_owner(meta, playername) and not protector.is_member(meta, playername) and meta:get_int("disabled") == 0 then
			minetest.chat_send_player(playername, S("This area is owned by @1.", meta:get_string("owner")))
			protected = true
			break
		end
	end

	-- check for unprotected area
	if protector.protect_by_default and protected == false and #nodes == 0 then
		-- allow placing protector blocks in unprotected areas
		-- FIXME: this is a hack to allow some items through protection without allowing others, and it probably contains vulnerabilities
		local player = minetest.get_player_by_name(playername)
		local item_name
		if player and player:is_player() then
			item_name = player:get_wielded_item():get_name()
		end
		if item_name ~= "protector:protect" and item_name ~= "protector:protect2" and item_name ~= "protector:tool" then
			minetest.chat_send_player(playername, S("Building in unprotected areas is prohibited."))
			protected = true
		end
	end

	-- is area protected against player?
	if protected == true then
		local player = minetest.get_player_by_name(playername)
		if player and player:is_player() then
			if protector.hurt > 0 and player:get_hp() > 0 then
				-- hurt player if protection violated
				player:set_hp(player:get_hp() - protector.hurt)
			end

			if protector.flip then
				-- flip player when protection violated
				-- yaw + 180°
				local yaw = player:get_look_yaw() + math.pi
				if yaw > 2 * math.pi then
					yaw = yaw - 2 * math.pi
				end
				player:set_look_yaw(yaw)

				-- invert pitch
				player:set_look_pitch(-player:get_look_pitch())

				-- if digging below player, move up to avoid falling through hole
				local player_pos = player:getpos()
				if pos.y < player_pos.y then
					player:setpos({x = player_pos.x, y = player_pos.y + 0.8, z = player_pos.z
					})
				end
			end
		end

		return true
	end

	-- pass through to next protection function
	return real_is_protected(pos, playername)
end

-- protector interface
local function generate_formspec(meta, player_name)
	local show_owner_options = protector.is_owner(meta, player_name) or minetest.check_player_privs(player_name, {protection_bypass = true})
	local show_member_options = meta:get_int("members_can_change") == 1 and protector.is_member(meta, player_name)

	local formspec = "size[8,6.5]"
		.. default.gui_bg
		.. default.gui_bg_img
		.. default.gui_slots
		.. "label[0,0;" .. S("Owner: @1", meta:get_string("owner")) .. "]"
		.. "label[0,1;" .. S("Members:") .. "]"
		.. "button_exit[2.5,6;3,0.5;protector_close;" .. S("Close") .. "]"

	if show_owner_options or show_member_options or protector.is_member(meta, player_name) or protector.guest_show_area then
		formspec = formspec .. "label[0,0.5;" .. S("Punch node to show protected area") .. "]"
	end

	if (protector.allow_owner_change and show_owner_options and (not protector.use_privileges or minetest.check_player_privs(player_name, {protection_transfer = true}))) or minetest.check_player_privs(player_name, {protection_bypass = true}) then
		-- owner change button
		formspec = formspec .. "button[6,0;2,0.5;protector_change_owner;" .. S("Change Owner") .. "]"
	end

	local members = protector.get_member_list(meta)
	local npp = 12 -- max users added to protector list
	local i = 0

	for n = 1, #members do
		if i < npp then
			local allow_remove = show_owner_options or show_member_options
			-- don't allow players to remove themselves
			if members[n] == player_name then
				allow_remove = false
			end
			-- players with protection_bypass can always remove any player
			if minetest.check_player_privs(player_name, {protection_bypass = true}) then
				allow_remove = true
			end

			if allow_remove == true then
				-- show username
				formspec = formspec .. "button[" .. (i % 4 * 2) .. "," .. math.floor(i / 4 + 2) .. ";1.5,.5;protector_member;" .. members[n] .. "]"

				-- username remove button
				.. "button[" .. (i % 4 * 2 + 1.25) .. "," .. math.floor(i / 4 + 2) .. ";.75,.5;protector_del_member_" .. members[n] .. ";X]"
			else
				-- show username without remove button
				formspec = formspec .. "button[" .. (i % 4 * 2) .. "," .. math.floor(i / 4 + 2) .. ";2,.5;protector_member;" .. members[n] .. "]"
			end
		end
		i = i + 1
	end

	if show_owner_options or show_member_options then
		if i < npp then
			-- username entry field
			formspec = formspec .. "field[" .. (i % 4 * 2 + 1 / 3) .. "," .. (math.floor(i / 4 + 2) + 1 / 3) .. ";1.433,.5;protector_add_member;;]"

			-- username add button
			.."button[" .. (i % 4 * 2 + 1.25) .. "," .. math.floor(i / 4 + 2) .. ";.75,.5;protector_submit;+]"
		end
	end

	if show_owner_options or show_member_options then
		-- disable protection checkbox
		formspec = formspec .. "checkbox[0,4.5;protector_disabled;" .. S("Disable protection") .. ";" .. tostring(meta:get_int("disabled") == 1) .. "]"
	end

	if show_owner_options then
		-- allow other players to change configuration checkbox
		formspec = formspec .. "checkbox[0,5;protector_members_can_change;" .. S("Other members can change configuration") .. ";" .. tostring(meta:get_int("members_can_change") == 1) .. "]"
	end

	return formspec
end

local function generate_owner_change_formspec(meta, player_name)
	local formspec = "size[4,1.5]"
		.. default.gui_bg
		.. default.gui_bg_img
		.. default.gui_slots
		.. "button_exit[1,1;2,0.5;protector_change_owner;" .. S("Change Owner") .. "]"

	if (protector.allow_owner_change and protector.is_owner(meta, player_name)) or minetest.check_player_privs(player_name, {protection_bypass = true}) then
		formspec = formspec .. "field[0.333,0.333;4,0.5;protector_owner;;" .. meta:get_string("owner") .. "]"
	end

	return formspec
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if string.sub(formname, 0, string.len("protector:node_")) == "protector:node_" then
		-- protector formspec found
		local pos = minetest.string_to_pos(string.sub(formname, string.len("protector:node_") + 1))
		local meta = minetest.get_meta(pos)

		-- prevent non-members from modifying the protector
		if not protector.is_owner(meta, player:get_player_name()) and not protector.is_member(meta, player:get_player_name()) and not minetest.check_player_privs(player:get_player_name(), {protection_bypass = true}) then
			return
		end

		-- only the owner is allowed to modify the protector, unless the protector is configured to allow other members to change it
		if not (meta:get_int("members_can_change") == 1) and not protector.is_owner(meta, player:get_player_name()) and not minetest.check_player_privs(player:get_player_name(), {protection_bypass = true}) then
			return
		end

		-- owner change button
		if fields.protector_change_owner and ((protector.allow_owner_change and protector.is_owner(meta, player:get_player_name())) or minetest.check_player_privs(player:get_player_name(), {protection_bypass = true})) then
			minetest.show_formspec(player:get_player_name(), "protector:owner_change_" .. minetest.pos_to_string(pos), generate_owner_change_formspec(meta, player:get_player_name()))
		end

		-- add member [+]
		if fields.protector_add_member then
			for _, i in pairs(fields.protector_add_member:split(" ")) do
				protector.add_member(meta, i)
			end
		end

		-- remove member [x]
		for field, value in pairs(fields) do
			if string.sub(field, 0, string.len("protector_del_member_")) == "protector_del_member_" then
				local member = string.sub(field,string.len("protector_del_member_") + 1)
				if member ~= player:get_player_name() or minetest.check_player_privs(player:get_player_name(), {protection_bypass = true}) then
					protector.del_member(meta, member)
				end
			end
		end

		-- disable protection
		if fields.protector_disabled then
			if fields.protector_disabled == "true" then
				meta:set_int("disabled", 1)
			else
				meta:set_int("disabled", 0)
			end
		end

		-- allow other players to change configuration
		if fields.protector_members_can_change and (protector.is_owner(meta, player:get_player_name()) or minetest.check_player_privs(player:get_player_name(), {protection_bypass = true})) then	-- only the owner is allowed to change this setting
			if fields.protector_members_can_change == "true" then
				meta:set_int("members_can_change", 1)
			else
				meta:set_int("members_can_change", 0)
			end
		end

		-- reset formspec until close button pressed
		if not fields.quit and not fields.protector_change_owner then	-- don't show the normal formspec again if the owner change formspec is supposed to be shown
			minetest.show_formspec(player:get_player_name(), formname, generate_formspec(meta, player:get_player_name()))
		end
	elseif string.sub(formname, 0, string.len("protector:owner_change_")) == "protector:owner_change_" then
		-- protector owner change formspec found
		local pos = minetest.string_to_pos(string.sub(formname, string.len("protector:owner_change_") + 1))
		local meta = minetest.get_meta(pos)

		-- only the owner and players with protection_bypass are allowed to change the protector owner
		if fields.protector_owner and ((protector.allow_owner_change and protector.is_owner(meta, player:get_player_name()) and (not protector.use_privileges or minetest.check_player_privs(player:get_player_name(), {protection_transfer = true}))) or minetest.check_player_privs(player:get_player_name(), {protection_bypass = true})) then
			local current_owner = meta:get_string("owner")

			if fields.protector_owner ~= current_owner then
				-- check for overlap with other protectors
				local nodes = minetest.find_nodes_in_area(
					{x = pos.x - protector.radius * 2, y = pos.y - protector.radius * 2, z = pos.z - protector.radius * 2},
					{x = pos.x + protector.radius * 2, y = pos.y + protector.radius * 2, z = pos.z + protector.radius * 2},
					{"protector:protect", "protector:protect2"})
				-- we don't actually care about the owners of the other protectors, because:
				-- * the other protector's owner is the same as this protector's current owner, which will make this protector invalid once its owner is changed
				-- * the other protector's owner is the same as this protector's new owner, in which case this protector is currently invalid so this cannot happen
				-- * the other protector's owner doesn't match either this protector's current owner or its new owner, in which case this protector is currently invalid so this cannot happen
				-- so whatever the other protector's owner is, the situation is or will become invalid, so no protectors at all can overlap with this one in order for the owner to change
				if #nodes > 1 then	-- 1, not 0, because this protector itself will always be found by minetest.find_nodes_in_area
					minetest.chat_send_player(player:get_player_name(), S("Overlaps into another protected area."))
				else
					-- remove new owner from member list if present
					if protector.is_member(meta, fields.protector_owner) then
						protector.del_member(meta, fields.protector_owner)
					end

					-- change owner
					meta:set_string("owner", fields.protector_owner)
					meta:set_string("infotext", S("Protection (owned by @1)", meta:get_string("owner")))
				end
			end
		end
	end
end)

-- protection block
minetest.register_node("protector:protect", {
	description = S("Protection Block"),
	drawtype = "nodebox",
	tiles = {
		"moreblocks_circle_stone_bricks.png",
		"moreblocks_circle_stone_bricks.png",
		"moreblocks_circle_stone_bricks.png^protector_logo.png"
	},
	sounds = default.node_sound_stone_defaults(),
	groups = {dig_immediate = 2, unbreakable = 1},
	is_ground_content = false,
	paramtype = "light",
	light_source = 4,

	node_box = {
		type = "fixed",
		fixed = {
			{-0.5 ,-0.5, -0.5, 0.5, 0.5, 0.5},
		}
	},

	on_place = function(itemstack, placer, pointed_thing)
		if protector.use_privileges and not minetest.check_player_privs(placer:get_player_name(), {protection_place = true}) then
			return itemstack
		end
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		if protector.check_overlap(pointed_thing.above, placer) then
			return itemstack
		else
			return minetest.item_place(itemstack, placer, pointed_thing)
		end
	end,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name() or "")
		meta:set_string("infotext", S("Protection (owned by @1)", meta:get_string("owner")))
		meta:set_string("members", "")
		meta:set_int("members_can_change", 0)
		meta:set_int("disabled", 0)
	end,

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		local pos = pointed_thing.under
		local nodes = minetest.find_nodes_in_area(
			{x = pos.x - protector.radius, y = pos.y - protector.radius, z = pos.z - protector.radius},
			{x = pos.x + protector.radius, y = pos.y + protector.radius, z = pos.z + protector.radius},
			{"protector:protect", "protector:protect2"})

		if #nodes > 0 then
			local can_build = true

			minetest.chat_send_player(user:get_player_name(), S("This area is owned by @1.", minetest.get_meta(nodes[1]):get_string("owner")))
			for _, protector_pos in ipairs(nodes) do
				local meta = minetest.get_meta(protector_pos)
				minetest.chat_send_player(user:get_player_name(), S("Protection located at @1.", minetest.pos_to_string(protector_pos)))

				if not protector.is_owner(meta, user:get_player_name()) and not protector.is_member(meta, user:get_player_name()) then
					can_build = false
				end
			end

			if can_build == true then
				minetest.chat_send_player(user:get_player_name(), S("You can build here."))
			else
				minetest.chat_send_player(user:get_player_name(), S("You cannot build here."))
			end
		else
			if protector.inside_spawn(pos, 0) then
				minetest.chat_send_player(user:get_player_name(), S("Spawn has been protected up to a @1 block radius.", protector.spawn))
				minetest.chat_send_player(user:get_player_name(), S("You cannot build here."))
			else
				minetest.chat_send_player(user:get_player_name(), S("This area is not protected."))
				if protector.protect_by_default then
					minetest.chat_send_player(user:get_player_name(), S("You cannot build here."))
				else
					minetest.chat_send_player(user:get_player_name(), S("You can build here."))
				end
			end
		end
	end,

	on_rightclick = function(pos, node, clicker, itemstack)
		local meta = minetest.get_meta(pos)
		if meta and (protector.is_owner(meta, clicker:get_player_name()) or (meta:get_int("members_can_change") == 1 and protector.is_member(meta, clicker:get_player_name())) or protector.guest_show_members or minetest.check_player_privs(clicker:get_player_name(), {protection_bypass = true})) then
			minetest.show_formspec(clicker:get_player_name(), "protector:node_" .. minetest.pos_to_string(pos), generate_formspec(meta, clicker:get_player_name()))
		end
	end,

	on_punch = function(pos, node, puncher)
		local meta = minetest.get_meta(pos)
		if protector.is_owner(meta, puncher:get_player_name()) or protector.is_member(meta, puncher:get_player_name()) or protector.guest_show_area or minetest.check_player_privs(puncher:get_player_name(), {protection_bypass = true}) then
			minetest.add_entity(pos, "protector:display")
		end
	end,

	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		return player and meta and (protector.is_owner(meta, player:get_player_name()) or minetest.check_player_privs(player:get_player_name(), {protection_bypass = true}))
	end,

	on_blast = function() end,
})

-- protection logo
minetest.register_node("protector:protect2", {
	description = S("Protection Logo"),
	tiles = {"protector_logo.png"},
	wield_image = "protector_logo.png",
	inventory_image = "protector_logo.png",
	sounds = default.node_sound_stone_defaults(),
	groups = {dig_immediate = 2, unbreakable = 1},
	paramtype = 'light',
	paramtype2 = "wallmounted",
	legacy_wallmounted = true,
	light_source = 4,
	drawtype = "nodebox",
	sunlight_propagates = true,
	walkable = true,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.375, 0.4375, -0.5, 0.375, 0.5, 0.5},
		wall_bottom = {-0.375, -0.5, -0.5, 0.375, -0.4375, 0.5},
		wall_side   = {-0.5, -0.5, -0.375, -0.4375, 0.5, 0.375},
	},
	selection_box = {type = "wallmounted"},

	on_place = function(itemstack, placer, pointed_thing)
		if protector.use_privileges and not minetest.check_player_privs(placer:get_player_name(), {protection_place = true}) then
			return itemstack
		end
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		if protector.check_overlap(pointed_thing.above, placer) then
			return itemstack
		else
			return minetest.item_place(itemstack, placer, pointed_thing)
		end
	end,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name() or "")
		meta:set_string("infotext", S("Protection (owned by @1)", meta:get_string("owner")))
		meta:set_string("members", "")
		meta:set_int("members_can_change", 0)
		meta:set_int("disabled", 0)
	end,

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		local pos = pointed_thing.under
		local nodes = minetest.find_nodes_in_area(
			{x = pos.x - protector.radius, y = pos.y - protector.radius, z = pos.z - protector.radius},
			{x = pos.x + protector.radius, y = pos.y + protector.radius, z = pos.z + protector.radius},
			{"protector:protect", "protector:protect2"})

		if #nodes > 0 then
			local can_build = true

			minetest.chat_send_player(user:get_player_name(), S("This area is owned by @1.", minetest.get_meta(nodes[1]):get_string("owner")))
			for _, protector_pos in ipairs(nodes) do
				local meta = minetest.get_meta(protector_pos)
				minetest.chat_send_player(user:get_player_name(), S("Protection located at @1.", minetest.pos_to_string(protector_pos)))

				if not protector.is_owner(meta, user:get_player_name()) and not protector.is_member(meta, user:get_player_name()) then
					can_build = false
				end
			end

			if can_build == true then
				minetest.chat_send_player(user:get_player_name(), S("You can build here."))
			else
				minetest.chat_send_player(user:get_player_name(), S("You cannot build here."))
			end
		else
			if protector.inside_spawn(pos, 0) then
				minetest.chat_send_player(user:get_player_name(), S("Spawn has been protected up to a @1 block radius.", protector.spawn))
				minetest.chat_send_player(user:get_player_name(), S("You cannot build here."))
			else
				minetest.chat_send_player(user:get_player_name(), S("This area is not protected."))
				if protector.protect_by_default then
					minetest.chat_send_player(user:get_player_name(), S("You cannot build here."))
				else
					minetest.chat_send_player(user:get_player_name(), S("You can build here."))
				end
			end
		end
	end,

	on_rightclick = function(pos, node, clicker, itemstack)
		local meta = minetest.get_meta(pos)
		if meta and (protector.is_owner(meta, clicker:get_player_name()) or (meta:get_int("members_can_change") == 1 and protector.is_member(meta, clicker:get_player_name())) or protector.guest_show_members or minetest.check_player_privs(clicker:get_player_name(), {protection_bypass = true})) then
			minetest.show_formspec(clicker:get_player_name(), "protector:node_" .. minetest.pos_to_string(pos), generate_formspec(meta, clicker:get_player_name()))
		end
	end,

	on_punch = function(pos, node, puncher)
		local meta = minetest.get_meta(pos)
		if protector.is_owner(meta, puncher:get_player_name()) or protector.is_member(meta, puncher:get_player_name()) or protector.guest_show_area or minetest.check_player_privs(puncher:get_player_name(), {protection_bypass = true}) then
			minetest.add_entity(pos, "protector:display")
		end
	end,

	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		return player and meta and (protector.is_owner(meta, player:get_player_name()) or minetest.check_player_privs(player:get_player_name(), {protection_bypass = true}))
	end,

	on_blast = function() end,
})

-- crafting recipes
minetest.register_craft({
	output = "protector:protect",
	recipe = {
		{"default:stone", "default:stone", "default:stone"},
		{"default:stone", "default:gold_ingot", "default:stone"},
		{"default:stone", "default:stone", "default:stone"},
	}
})

minetest.register_craft({
	type = "shapeless",
	output = "protector:protect",
	recipe = {"protector:protect2"}
})

minetest.register_craft({
	type = "shapeless",
	output = "protector:protect2",
	recipe = {"protector:protect"}
})

-- entity shown when protector node is punched
minetest.register_entity("protector:display", {
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "wielditem",
	visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},	-- wielditem seems to be scaled to 1.5 times original node size
	textures = {"protector:display_node"},
	timer = 0,

	on_step = function(self, dtime)
		-- remove after 5 seconds
		self.timer = self.timer + dtime
		if self.timer > 5 then
			self.object:remove()
		end
	end,
})

-- node to show protected area
-- do NOT place the display as a node, it is made to be used as an entity (see above)
local x = protector.radius
minetest.register_node("protector:display_node", {
	tiles = {"protector_display.png"},
	use_texture_alpha = true,
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			-- sides
			{-(x+.55), -(x+.55), -(x+.55), -(x+.45), (x+.55), (x+.55)},
			{-(x+.55), -(x+.55), (x+.45), (x+.55), (x+.55), (x+.55)},
			{(x+.45), -(x+.55), -(x+.55), (x+.55), (x+.55), (x+.55)},
			{-(x+.55), -(x+.55), -(x+.55), (x+.55), (x+.55), -(x+.45)},
			-- top
			{-(x+.55), (x+.45), -(x+.55), (x+.55), (x+.55), (x+.55)},
			-- bottom
			{-(x+.55), -(x+.55), -(x+.55), (x+.55), -(x+.45), (x+.55)},
			-- middle (surround protector)
			{-.55,-.55,-.55, .55,.55,.55},
		},
	},
	selection_box = {
		type = "regular",
	},
	paramtype = "light",
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	drop = "",
})
