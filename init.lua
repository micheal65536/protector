-- get minetest.conf settings
protector = {}
protector.use_privileges = minetest.setting_getbool("protector_use_privileges") or false
protector.radius = tonumber(minetest.setting_get("protector_radius")) or 5
protector.spawn = tonumber(minetest.setting_get("protector_spawn")) or 0
protector.protect_by_default = minetest.setting_getbool("protector_protect_by_default") or false
protector.hurt = tonumber(minetest.setting_get("protector_hurt")) or 0
protector.flip = minetest.setting_getbool("protector_flip") or false
protector.allow_owner_change = minetest.setting_getbool("protector_allow_owner_change") or false
protector.guest_show_area = minetest.setting_getbool("protector_guest_show_area") or false
protector.guest_show_members = minetest.setting_getbool("protector_guest_show_members") or false
protector.pvp = minetest.setting_getbool("protector_pvp") or false
protector.night_pvp = minetest.setting_getbool("protector_night_pvp") or false
protector.tool_prevent_floating = minetest.setting_getbool("protector_tool_prevent_floating") or false
protector.tool_prevent_underground = minetest.setting_getbool("protector_tool_prevent_underground") or false

-- register privileges
if protector.use_privileges then
	minetest.register_privilege("protection_place", "Can place protector blocks")
	minetest.register_privilege("protection_transfer", "Can transfer ownership of their protector blocks to other players")
end

-- prepare intllib
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

-- check if position is inside protected spawn area
protector.inside_spawn = function(pos, radius)
	if protector.spawn <= 0 then
		return false
	end

	local spawn = minetest.setting_get_pos("static_spawnpoint") or {x = 0, y = 2, z = 0}
	local check_radius = protector.spawn + radius
	if pos.x < spawn.x + check_radius and pos.x > spawn.x - check_radius and pos.y < spawn.y + check_radius and pos.y > spawn.y - check_radius and pos.z < spawn.z + check_radius and pos.z > spawn.z - check_radius then
		return true
	else
		return false
	end
end

-- load additional files
local path = minetest.get_modpath("protector")
dofile(path .. "/protector.lua")
dofile(path .. "/doors.lua")
dofile(path .. "/chest.lua")
dofile(path .. "/pvp.lua")
dofile(path .. "/commands.lua")
dofile(path .. "/tool.lua")
dofile(path .. "/lucky_block.lua")

-- stop mesecon pistons from pushing protectors
if minetest.get_modpath("mesecons_mvps") then
	mesecon.register_mvps_stopper("protector:protect")
	mesecon.register_mvps_stopper("protector:protect2")
	mesecon.register_mvps_stopper("protector:chest")
end
