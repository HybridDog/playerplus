--[[
	walking on ice makes player walk faster,
	stepping through snow or water slows player down,
	touching a cactus hurts player,
	and being stuck inside a solid node suffocates player.

	PlayerPlus by TenPlus1
]]

playerplus = {}

-- get node but use fallback for nil or unknown
local function node_ok(pos, fallback)

	fallback = fallback or "air"

	local node = minetest.get_node_or_nil(pos)

	if not node then
		return fallback
	end

	if minetest.registered_nodes[node.name] then
		return node.name
	end

	return fallback
end

local armor_mod = minetest.get_modpath("3d_armor")
local def = {}

local function on_step()
	-- check players
	for _,player in pairs(minetest.get_connected_players()) do

		-- who am I?
		local name = player:get_player_name()

		-- where am I?
		local pos = player:getpos()

		-- what is around me?
		pos.y = pos.y - 0.1 -- standing on
		playerplus[name].nod_stand = node_ok(pos)

		pos.y = pos.y + 1.5 -- head level
		playerplus[name].nod_head = node_ok(pos)

		pos.y = pos.y - 1.2 -- feet level
		playerplus[name].nod_feet = node_ok(pos)

		pos.y = pos.y - 0.2 -- reset pos

		-- set defaults
		def.speed = 1
		def.jump = 1
		def.gravity = 1

		-- is 3d_armor mod active? if so make armor physics default
		if armor_mod and armor and armor.def then
			-- get player physics from armor
			def.speed = armor.def[name].speed or 1
			def.jump = armor.def[name].jump or 1
			def.gravity = armor.def[name].gravity or 1
		end

		-- standing on ice? if so walk faster
		if playerplus[name].nod_stand == "default:ice" then
			def.speed = def.speed + 0.4
		end

		-- standing on snow? if so walk slower
		if playerplus[name].nod_stand == "default:snow"
		or playerplus[name].nod_stand == "default:snowblock"
		-- wading in water? if so walk slower
		or minetest.registered_nodes[ playerplus[name].nod_feet ].groups.water then
			def.speed = def.speed - 0.4
		end

		-- set player physics
		player:set_physics_override(def.speed, def.jump, def.gravity)
		--print ("Speed:", def.speed, "Jump:", def.jump, "Gravity:", def.gravity)

		-- is player suffocating inside node? (only solid "normal" type nodes)
		if minetest.registered_nodes[ playerplus[name].nod_head ].walkable
		and minetest.registered_nodes[ playerplus[name].nod_head ].drawtype == "normal"
		and not minetest.check_player_privs(name, {noclip = true}) then

			if player:get_hp() > 0 then
				player:set_hp(player:get_hp() - 2)
			end
		end

		-- am I near a cactus?
		local near = minetest.find_node_near(pos, 1, "default:cactus")

		if near then

			-- am I touching the cactus? if so it hurts
			for _,object in pairs(minetest.get_objects_inside_radius(near, 1.1)) do

				if object:get_hp() > 0 then
					object:set_hp(object:get_hp() - 2)
				end
			end

		end

	end
end

local function step()
	on_step()

	-- approximately avoid executing more than 30 times a second
	minetest.after(0.05, function()

		-- if it's lagging, wait, but not longer than 2 seconds
		minetest.delay_function(2, step)
	end)
end
step()

-- set to blank on join (for 3rd party mods)
minetest.register_on_joinplayer(function(player)

	local name = player:get_player_name()

	playerplus[name] = {}
	playerplus[name].nod_head = ""
	playerplus[name].nod_feet = ""
	playerplus[name].nod_stand = ""
end)
