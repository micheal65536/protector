local S = protector.intllib

-- get static spawn position
local statspawn = minetest.setting_get_pos("static_spawnpoint") or {x = 0, y = 2, z = 0}

if minetest.setting_getbool("enable_pvp") and protector.pvp then
	if minetest.register_on_punchplayer then
		minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
			if not hitter:is_player() then
				return false
			end

			-- no pvp at spawn
			if protector.inside_spawn(player:getpos(), 0) then
				return true
			end

			if protector.night_pvp then
				-- allow pvp at night
				local time = minetest.get_timeofday() or 0
				if time < 0.2 or time > 0.8 then
					return false
				end
			end

			-- check if player is inside protected area
			if minetest.is_protected(player:getpos(), hitter:get_player_name()) then
				return true
			end

			return false
		end)
	end
end
