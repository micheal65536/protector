Protector Redo mod [protect]

Protector redo for minetest is a mod that protects a players builds by placing
a block that stops other players from digging or placing blocks in that area.

based on glomie's mod, remade by Zeg9 and rewritten by TenPlus1.

https://forum.minetest.net/viewtopic.php?f=11&t=9376

Change log:

0.1 - Initial release
0.2 - Texture update
0.3 - Added Protection Logo to blend in with player builds
0.4 - Code tweak for 0.4.10+
0.5 - Added protector.radius variable in init.lua (default: 5)
0.6 - Added Protected Doors (wood and steel) and Protected Chest
0.7 - Protected Chests now have "To Chest" and "To Inventory" buttons to copy
      contents across, also chests can be named
0.8 - Updated to work with Minetest 0.4.12, simplified textures
0.9 - Tweaked code
1.0 - Only owner can remove protector
1.1 - Set 'protector_pvp = true' in minetest.conf to disable pvp in protected
      areas except your own, also setting protector_pvp_spawn higher than 0 will
      disable pvp around spawn area with the radius you entered
1.2 - Shift and click support added with Minetest 0.4.13 to quickly copy stacks
      to and from protected chest
1.3 - Moved protector on_place into node itself, protector zone display changed
      from 10 to 5 seconds, general code tidy
1.4 - Changed protector recipes to give single item instead of 4, added + button
      to interface, tweaked and tidied code, added admin command /delprot to remove
      protectors in bulk from banned/old players
1.5 - Added much requested protected trapdoor
1.6 - Added protector_drop (true or false) and protector_hurt (hurt by this num)
      variables to minetest.conf settings to stop players breaking protected
      areas by dropping tools and hurting player.
1.7 - Included an edited version of WTFPL doors mod since protected doors didn't
      work with the doors mod in the latest daily build... Now it's fine :)
      added support for "protection_bypass" privelage.
1.8 - Added 'protector_flip' setting to stop players using lag to grief into
      another players house, it flips them around to stop them digging.
1.9 - Renamed 'protector_pvp_spawn' setting to 'protector_spawn' which protects
      an area around static spawnpoint and disables pvp if active.
      (note: previous name can still be used)
2.0 - Added protector placement tool (thanks to Shara) so that players can easily
      stand on a protector, face in a direction and it places a new one at a set
      distance to cover protection radius.  Added /protector_show command (thanks agaran)
      Protectors and chest cannot be moved by mesecon pistons or machines.
2.1 - Added 'protector_night_pvp' setting so night-time becomes a free for all and
      players can hurt one another even inside protected areas (not spawn protected)
2.2 - Updated protector tool so that player only needs to stand nearby (2 block radius)
      It can also place vertically (up and down) as well.  New protector recipe added.

Lucky Blocks: 10


Usage:

show protected areas of your nearby protectors (max of 5)
	/protector_show


The following lines can be added to your minetest.conf file to configure specific features of the mod:

protector_use_privileges = false
- When true then the "protection_place" privilege is required to place protector blocks and the "protection_transfer" privilege is required to transfer ownership of protector blocks.

protector_radius = 5
- Sets the size of the protected area around each protection node.

protector_spawn = 0
- Sets an area around the world spawn point that is protected, or 0 (the default) to disable spawn protection.

protector_protect_by_default = false
- When true then unprotected areas will behave as if they are protected (players cannot dig or build there). Players must protect an area before they can dig or build.

protector_hurt = 0
- When set to above 0, players violating protected areas will be hurt by the corresponding number of health points.

protector_flip = false
- When true players who violate a protected area will flipped around to stop them using lag to glitch into someone else's build.

protector_allow_owner_change = false
- When true protector owners can change the ownership of a protector to another player (players with the protection_bypass privilege can always change the owner of a protector)

protector_guest_show_area = false
- When true players who are not the owner or a member of a protector can punch the protector to see the protected area.

protector_guest_show_members = false
- When true players who are not the owner or a member of a protector can right-click on the protector to see the protector's members.

protector_pvp = false
- When enabled PvP will be prohibited inside protected areas for all players apart from those listed on the protector node.

protector_night_pvp = false
- when enabled alongside protector_pvp, PvP will be allowed inside protected areas during the night.

protector_tool_prevent_floating = false
- When true the protector placer tool cannot place protectors in the air or on top of nodes that other nodes cannot normally be placed on.

protector_tool_prevent_underground = false
- When true the protector placer tool cannot place protectors where a node already exists, except for nodes that can normally be replaced by another node.
