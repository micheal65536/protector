-- show protection areas of nearby protectors owned by you (thanks agaran)
minetest.register_chatcommand("protector_show", {
	params = "",
	description = "Show protected areas of your nearby protectors",
	privs = {},
	func = function(name, param)

		local player = minetest.get_player_by_name(name)
		local pos = player:getpos()
		local r = protector.radius -- max protector range.

		-- find the protector nodes
		local pos = minetest.find_nodes_in_area(
			{x = pos.x - r, y = pos.y - r, z = pos.z - r},
			{x = pos.x + r, y = pos.y + r, z = pos.z + r},
			{"protector:protect", "protector:protect2"})

		local meta, owner

		-- show a maximum of 5 protected areas only
		for n = 1, math.min(#pos, 5) do

			meta = minetest.get_meta(pos[n])
			owner = meta:get_string("owner") or ""

			if owner == name then
				minetest.add_entity(pos[n], "protector:display")
			end
		end
	end
})
