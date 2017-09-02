-- show protected areas of protectors covering the player's current position (original code by agaran)
minetest.register_chatcommand("protector_show", {
	params = "",
	description = "Show protected areas of your nearby protectors",
	privs = {},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local pos = player:getpos()
		local radius = protector.radius

		local nodes = minetest.find_nodes_in_area(
			{x = pos.x - radius, y = pos.y - radius, z = pos.z - radius},
			{x = pos.x + radius, y = pos.y + radius, z = pos.z + radius},
			{"protector:protect", "protector:protect2"})
		local count = 0
		for _, protector_pos in ipairs(nodes) do
			local meta = minetest.get_meta(protector_pos)
			if protector.is_owner(meta, name) then
				minetest.add_entity(pos[n], "protector:display")
				count = count + 1
			end

			-- show a maximum of 5 protected areas
			if count == 5 then
				break
			end
		end
	end
})
