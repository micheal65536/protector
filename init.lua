-- get minetest.conf settings
protector = {}
protector.mod = "redo"
protector.radius = tonumber(minetest.setting_get("protector_radius")) or 5
protector.flip = minetest.setting_getbool("protector_flip") or false
protector.hurt = tonumber(minetest.setting_get("protector_hurt")) or 0
protector.spawn = tonumber(minetest.setting_get("protector_spawn")
	or minetest.setting_get("protector_pvp_spawn")) or 0


-- get static spawn position
local statspawn = minetest.setting_get_pos("static_spawnpoint") or {x = 0, y = 2, z = 0}


-- Intllib
local S
if minetest.get_modpath("intllib") then
	S = intllib.Getter()
else
	S = function(s, a, ...) a = {a, ...}
		return s:gsub("@(%d+)", function(n)
			return a[tonumber(n)]
		end)
	end

end
protector.intllib = S


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


-- protector interface
protector.generate_formspec = function(meta, player_name)

	local formspec = "size[8,7]"
		.. default.gui_bg
		.. default.gui_bg_img
		.. default.gui_slots
		.. "label[2.5,0;" .. S("-- Protector interface --") .. "]"
		.. "label[0,1;" .. S("Punch node to show protected area or use for area check") .. "]"
		.. "label[0,2;" .. S("Members:") .. "]"
		.. "button_exit[2.5,6.2;3,0.5;close_me;" .. S("Close") .. "]"

	local members = protector.get_member_list(meta)
	local npp = 12 -- max users added to protector list
	local i = 0

	for n = 1, #members do
		if i < npp then
			if members[n] ~= player_name then	-- don't allow players to remove themselves
				-- show username
				formspec = formspec .. "button[" .. (i % 4 * 2)
				.. "," .. math.floor(i / 4 + 3)
				.. ";1.5,.5;protector_member;" .. members[n] .. "]"

				-- username remove button
				.. "button[" .. (i % 4 * 2 + 1.25) .. ","
				.. math.floor(i / 4 + 3)
				.. ";.75,.5;protector_del_member_" .. members[n] .. ";X]"
			else
				-- show username without remove button
				formspec = formspec .. "button[" .. (i % 4 * 2)
				.. "," .. math.floor(i / 4 + 3)
				.. ";2,.5;protector_member;" .. members[n] .. "]"
			end
		end

		i = i + 1
	end
	
	if i < npp then
		-- user name entry field
		formspec = formspec .. "field[" .. (i % 4 * 2 + 1 / 3) .. ","
		.. (math.floor(i / 4 + 3) + 1 / 3)
		.. ";1.433,.5;protector_add_member;;]"

		-- username add button
		.."button[" .. (i % 4 * 2 + 1.25) .. ","
		.. math.floor(i / 4 + 3) .. ";.75,.5;protector_submit;+]"
	end

	if protector.is_owner(meta, player_name) then
		-- allow other players to change configuration checkbox
		formspec = formspec .. "checkbox[0,5;protector_members_can_change;" .. S("Other members can change configuration") .. ";" .. tostring(meta:get_int("members_can_change") == 1) .. "]"
	end

	return formspec
end


-- check if pos is inside a protected spawn area
local function inside_spawn(pos, radius)

	if protector.spawn <= 0 then
		return false
	end

	if pos.x < statspawn.x + radius
	and pos.x > statspawn.x - radius
	and pos.y < statspawn.y + radius
	and pos.y > statspawn.y - radius
	and pos.z < statspawn.z + radius
	and pos.z > statspawn.z - radius then

		return true
	end

	return false
end

local real_is_protected = minetest.is_protected
-- check for protected area, return true if protected and player isn't on list
function minetest.is_protected(pos, playername)
	playername = playername or "" -- nil check

	-- protector_bypass privileged users can override protection
	if minetest.check_player_privs(playername, {protection_bypass = true}) then
		return real_is_protected(pos, playername)
	end

	local protected = false

	-- is spawn area protected ?
	if inside_spawn(pos, protector.spawn) then
		minetest.chat_send_player(playername, S("Spawn @1 has been protected up to a @2 block radius.", minetest.pos_to_string(statspawn), protector.spawn))
		protected = true
	end

	-- find the protector nodes
	local nodes = minetest.find_nodes_in_area(
		{x = pos.x - protector.radius, y = pos.y - protector.radius, z = pos.z - protector.radius},
		{x = pos.x + protector.radius, y = pos.y + protector.radius, z = pos.z + protector.radius},
		{"protector:protect", "protector:protect2"})
	for _, protector_pos in ipairs(nodes) do
		local meta = minetest.get_meta(protector_pos)
		if not protector.is_owner(meta, playername) and not protector.is_member(meta, playername) then
			minetest.chat_send_player(playername, S("This area is owned by @1.", meta:get_string("owner")))
			protected = true
			break
		end
	end

	-- is area protected against player?
	if protected == true then
		local player = minetest.get_player_by_name(playername)
		if player and player:is_player() then
			-- hurt player if protection violated
			if protector.hurt > 0 and player:get_hp() > 0 then
				player:set_hp(player:get_hp() - protector.hurt)
			end

			-- flip player when protection violated
			if protector.flip then
				-- yaw + 180°
				local yaw = player:get_look_yaw() + math.pi
				if yaw > 2 * math.pi then
					yaw = yaw - 2 * math.pi
				end
				player:set_look_yaw(yaw)

				-- invert pitch
				player:set_look_pitch(-player:get_look_pitch())

				-- if digging below player, move up to avoid falling through hole
				local pla_pos = player:getpos()
				if pos.y < pla_pos.y then
					player:setpos({
						x = pla_pos.x,
						y = pla_pos.y + 0.8,
						z = pla_pos.z
					})
				end
			end
		end

		return true
	end

	-- otherwise can dig or place
	return real_is_protected(pos, playername)
end


-- make sure protection block doesn't overlap another protector's area
function protector.check_overlap(pos, player)
	-- make sure protector doesn't overlap onto protected spawn area
	if inside_spawn(pos, protector.spawn + protector.radius) then
		minetest.chat_send_player(player:get_player_name(), S("Spawn @1 has been protected up to a @2 block radius.", minetest.pos_to_string(statspawn), protector.spawn))
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


-- protection node
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
				minetest.chat_send_player(user:get_player_name(), S("Protection located at: @1", minetest.pos_to_string(protector_pos)))

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
			minetest.chat_send_player(user:get_player_name(), S("This area is not protected."))
			minetest.chat_send_player(user:get_player_name(), S("You can build here."))
		end
	end,

	on_rightclick = function(pos, node, clicker, itemstack)
		local meta = minetest.get_meta(pos)

		if meta and (protector.is_owner(meta, clicker:get_player_name()) or (meta:get_int("members_can_change") == 1 and protector.is_member(meta, clicker:get_player_name()))) then
			minetest.show_formspec(clicker:get_player_name(), 
			"protector:node_" .. minetest.pos_to_string(pos), protector.generate_formspec(meta, clicker:get_player_name()))
		end
	end,

	on_punch = function(pos, node, puncher)
		local meta = minetest.get_meta(pos)
		if protector.is_owner(meta, puncher:get_player_name()) or protector.is_member(meta, puncher:get_player_name()) then
			minetest.add_entity(pos, "protector:display")
		end
	end,

	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		return player and meta and (protector.is_owner(meta, player:get_player_name()) or minetest.check_player_privs(player:get_player_name(), {protection_bypass = true}))
	end,

	on_blast = function() end,
})

minetest.register_craft({
	output = "protector:protect",
	recipe = {
		{"default:stone", "default:stone", "default:stone"},
		{"default:stone", "default:gold_ingot", "default:stone"},
		{"default:stone", "default:stone", "default:stone"},
	}
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
				minetest.chat_send_player(user:get_player_name(), S("Protection located at: @1", minetest.pos_to_string(protector_pos)))

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
			minetest.chat_send_player(user:get_player_name(), S("This area is not protected."))
			minetest.chat_send_player(user:get_player_name(), S("You can build here."))
		end
	end,

	on_rightclick = function(pos, node, clicker, itemstack)
		local meta = minetest.get_meta(pos)

		if meta and (protector.is_owner(meta, clicker:get_player_name()) or (meta:get_int("members_can_change") == 1 and protector.is_member(meta, clicker:get_player_name()))) then
			minetest.show_formspec(clicker:get_player_name(), 
			"protector:node_" .. minetest.pos_to_string(pos), protector.generate_formspec(meta, clicker:get_player_name()))
		end
	end,

	on_punch = function(pos, node, puncher)
		local meta = minetest.get_meta(pos)
		if protector.is_owner(meta, puncher:get_player_name()) or protector.is_member(meta, puncher:get_player_name()) then
			minetest.add_entity(pos, "protector:display")
		end
	end,

	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		return player and meta and (protector.is_owner(meta, player:get_player_name()) or minetest.check_player_privs(player:get_player_name(), {protection_bypass = true}))
	end,

	on_blast = function() end,
})
--[[
minetest.register_craft({
	output = "protector:protect2",
	recipe = {
		{"default:stone", "default:stone", "default:stone"},
		{"default:stone", "default:copper_ingot", "default:stone"},
		{"default:stone", "default:stone", "default:stone"},
	}
})
]]

-- check formspec buttons or when name entered
minetest.register_on_player_receive_fields(function(player, formname, fields)
	-- protector formspec found
	if string.sub(formname, 0, string.len("protector:node_")) == "protector:node_" then
		local meta = minetest.get_meta(minetest.string_to_pos(string.sub(formname, string.len("protector:node_") + 1)))

		-- prevent non-members from modifying the protector
		if not protector.is_owner(meta, player:get_player_name()) and not protector.is_member(meta, player:get_player_name()) then
			return
		end

		-- only the owner is allowed to modify the protector, unless the protector is configured to allow other members to change it
		if not (meta:get_int("members_can_change") == 1) and not protector.is_owner(meta, player:get_player_name()) then
			return
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
				if member ~= player:get_player_name() then
					protector.del_member(meta, member)
				end
			end
		end

		-- allow other players to change configuration
		if fields.protector_members_can_change and protector.is_owner(meta, player:get_player_name()) then	-- only the owner is allowed to change this setting
			if fields.protector_members_can_change == "true" then
				meta:set_int("members_can_change", 1)
			else
				meta:set_int("members_can_change", 0)
			end
		end

		-- reset formspec until close button pressed
		if not fields.close_me then
			minetest.show_formspec(player:get_player_name(), formname, protector.generate_formspec(meta, player:get_player_name()))
		end
	end
end)


-- display entity shown when protector node is punched
minetest.register_entity("protector:display", {
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "wielditem",
	-- wielditem seems to be scaled to 1.5 times original node size
	visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},
	textures = {"protector:display_node"},
	timer = 0,

	on_step = function(self, dtime)

		self.timer = self.timer + dtime

		-- remove after 5 seconds
		if self.timer > 5 then
			self.object:remove()
		end
	end,
})


-- Display-zone node, Do NOT place the display as a node,
-- it is made to be used as an entity (see above)

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


local path = minetest.get_modpath("protector")

dofile(path .. "/doors_chest.lua")
dofile(path .. "/pvp.lua")
dofile(path .. "/admin.lua")
dofile(path .. "/tool.lua")
dofile(path .. "/lucky_block.lua")


-- stop mesecon pistons from pushing protectors
if minetest.get_modpath("mesecons_mvps") then
	mesecon.register_mvps_stopper("protector:protect")
	mesecon.register_mvps_stopper("protector:protect2")
	mesecon.register_mvps_stopper("protector:chest")
end


print (S("[MOD] Protector Redo loaded"))
