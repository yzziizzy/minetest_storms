

local on_strike = {}


storms = {
}



local perlins = {}


local sounds = {
	thunder = {
		"storms_thunder_01_ccby_hantorio",
		"storms_thunder_01_ccby_hantorio",
--		"storms_thunder_02_PD",
		"storms_thunder_03_PD",
	},
}



local function color_lerp(a, b, x)
	local x1 = 1.0 - x
	
	return {
		r = a.r * x1 + b.r * x,
		g = a.g * x1 + b.g * x,
		b = a.b * x1 + b.b * x,
-- 		a = a.a * x1 + b.a * x,
	}
end


storms.register_on_lightning_strike = function(fn) 
	table.insert(on_strike, fn)
end


local on = false
local storm_players = {}


local good_biomes = {}
for _,def in pairs(minetest.registered_biomes) do
	if def.y_max >= 10 and def.y_min <= 10 then
		table.insert(good_biomes, def)
	end
end

local function get_noise(pos) 
	return heat_noise:get2d({x=pos.x, y=pos.z}), humidity_noise:get2d({x=pos.x, y=pos.z})
end


local function find_biome(he, hu)
	local smallest = 99999999999
	local tmp = nil
	
	for _,def in pairs(good_biomes) do
			local a = he - def.heat_point
			local b = hu - def.humidity_point
			local c = math.sqrt(a*a + b*b)
			if c < smallest then
				smallest = c
				tmp = def
			end
	end
	
	return tmp.name
end

local function get_biome(pos)
	local he, hu = get_noise(pos)
	if storms.biome_offset then
		local oe, ou = storms.biome_offset(pos)
		he = he + oe
		hu = hu + ou
	end
	
	return find_biome(he, hu)
end


minetest.after(0, function()
	local noise = minetest.get_mapgen_setting_noiseparams("mg_biome_np_heat")
	heat_noise = minetest.get_perlin(noise)
	
	noise = minetest.get_mapgen_setting_noiseparams("mg_biome_np_humidity")
	humidity_noise = minetest.get_perlin(noise)
end)





local function randompos(center, dist)
	return {
		x = center.x + math.random(-dist, dist),
		y = center.y,
		z = center.z + math.random(-dist, dist),
	}
end

local function pcopy(p)
	return {x=p.x, y=p.y, z=p.z}
end

local function do_lightning(cloudh, pos)
	
	local h = cloudh - 10
	
	while h > -15 do
		minetest.add_particle({
			pos = {x=pos.x, y=h, z=pos.z},
			velocity = {x=0, y=0, z=0},
			acceleration = {x=0, y=0, z=0},
			expirationtime = .1,
			size = 300,
			collisiondetection = false,
			vertical = true,
			texture = "storms_lightning.png",
			playername = "singleplayer"
		})
	
		h = h - 30
	end
	
	local p = {x=pos.x, y=cloudh, z=pos.z}
	while p.y >= -1 do
		local n = minetest.get_node(p)
		if n.name ~= "air" and n.name ~= "ignore" then
		
			-- node callbacks
			local def = minetest.registered_nodes[n.name]
			if def.on_lightning_strike then
				def.on_lightning_strike(pcopy(p))
			end
			
			-- global callbacks
			for _,fn in pairs(on_strike) do
				fn(pcopy(p), n)
			end
			
			break
		end
		
		p.y = p.y - 1
	end
	
	minetest.sound_play(sounds.thunder[math.random(#sounds.thunder)], {
		pos = p,
		max_hear_distance = 100,
		gain = 5.0,
	})
	
end




local function spawn_blizzard(pos, vel, sz)
	local ht = 7

	minetest.add_particlespawner({
		amount = 4000,
		time = 5,
		minpos = vector.add({x=pos.x-sz, y=pos.y-ht, z=pos.z-sz}, vector.multiply(vel, -.95)),
		maxpos = vector.add({x=pos.x+sz, y=pos.y+ht, z=pos.z+sz}, vector.multiply(vel, -.95)),
		minvel = vector.add(vel, {x=-1, y=0, z=-1}),
		maxvel = vector.add(vel, {x=5,  y=0.5,  z=5}),
		minacc = {x=-01.1, y=0.1, z=-01.1},
		maxacc = {x=01.1, y=01.3, z=01.1},
		minexptime = 1.5,
		maxexptime = 2.5,
		collisiondetection = true,
		collision_removal = true,
		minsize = 40,
		maxsize = 45,
		texture = "storms_snow.png",
	})
end

local function spawn_sandstorm(pos, vel, sz, lvl)
	local ht = 7

	minetest.add_particlespawner({
		amount = lvl * 5000,
		time = 5,
		minpos = vector.add({x=pos.x-sz, y=pos.y-ht, z=pos.z-sz}, vector.multiply(vel, -.95)),
		maxpos = vector.add({x=pos.x+sz, y=pos.y+ht, z=pos.z+sz}, vector.multiply(vel, -.95)),
		minvel = vector.add(vel, {x=-1, y=0, z=-1}),
		maxvel = vector.add(vel, {x=5,  y=0.5,  z=5}),
		minacc = {x=-01.1, y=0.1, z=-01.1},
		maxacc = {x=01.1, y=01.3, z=01.1},
		minexptime = 1.5,
		maxexptime = 2.5,
		collisiondetection = true,
		collision_removal = true,
		minsize = 40,
		maxsize = 45,
		texture = "storms_dust.png",
	})
end


local function spawn_rainclouds(pos, vel, sz, lvl)
	local offht = 60
	local ht = 10

	minetest.add_particlespawner({
		amount = lvl * 5000,
		time = 5,
		minpos = {x=pos.x-sz, y=pos.y+offht, z=pos.z-sz},
		maxpos = {x=pos.x+sz, y=pos.y+offht+ht, z=pos.z+sz},
		minvel = vector.add(vel, {x=-1, y=0, z=-1}),
		maxvel = vector.add(vel, {x=5,  y=0.5,  z=5}),
		minacc = {x=-0.1, y=0.1, z=-0.1},
		maxacc = {x=0.1, y=0.3, z=0.1},
		minexptime = 2,
		maxexptime = 7,
		minsize = 300,
		maxsize = 400,
		texture = "storms_cloud.png^[colorize:black:120",
	})
end

local function spawn_rain(pos, vel, sz, lvl)
	local offht = 10
	local ht = 10
	
	minetest.add_particlespawner({
		amount = lvl * 1000,
		time = 5,
		minpos = {x=pos.x-sz, y=pos.y+offht, z=pos.z-sz},
		maxpos = {x=pos.x+sz, y=pos.y+offht+ht, z=pos.z+sz},
		minvel = {x=vel.x, y=-40, z=vel.z},
		maxvel = {x=vel.x, y=-40, z=vel.z},
		minacc = {x=-0.1, y=0.1, z=-0.1},
		maxacc = {x=0.1, y=0.3, z=0.1},
		collisiondetection = true,
		collision_removal = true,
		minexptime = 2,
		maxexptime = 7,
		minsize = 10,
		maxsize = 15,
		texture = "storms_raindrop.png",
	})
end


local function spawn_lightning(pos, amount, sz)
	local offht = 60
	for i = 1,math.random(amount) do
		minetest.after(math.random(5), function()
			do_lightning(pos.y+60, randompos(pos, sz))
		end)
	end
end


local biome_skies = {
	["tundra"] = {color = {r=255, g=255, b=255}, clouds = false},
	["taiga"] = {color = {r=255, g=255, b=255}, clouds = false},
	["snowy_grassland"] = {color = {r=255, g=255, b=255}, clouds = false},
	["cold_desert"] = {color = {r=255, g=255, b=255}, clouds = false},
	
	["desert"] = {color = {r=130, g=105, b=25}, clouds = false},
	["sandstone_desert"] = {color = {r=130, g=105, b=25}, clouds = false},
	
	["grassland"] = {color = {r=20, g=20, b=30}, clouds = false},
	["deciduous_forest"] = {color = {r=20, g=20, b=30}, clouds = false},
	["coniferous_forest"] = {color = {r=20, g=20, b=30}, clouds = false},
	["savanna"] = {color = {r=20, g=20, b=30}, clouds = false},
	["rainforest"] = {color = {r=20, g=20, b=30}, clouds = false},
}


local biome_spawners = {}


biome_spawners.tundra = function(pos, dir, lvl)
	spawn_blizzard(pos, dir, 15, lvl)
end

biome_spawners.taiga = function(pos, dir, lvl)
	spawn_blizzard(pos, dir, 15, lvl)
end

biome_spawners.grassland = function(pos, dir, lvl)
	spawn_rainclouds(pos, dir, 20, lvl)
	spawn_rain(pos, {x=0, y=0, z=0}, 20, lvl)
	spawn_lightning(pos, 15 * lvl, 60)
end

biome_spawners.snowy_grassland = function(pos, dir, lvl)
	spawn_blizzard(pos, dir, 15, lvl)
end

biome_spawners.savanna = function(pos, dir, lvl)
	spawn_rainclouds(pos, dir, 20, lvl)
-- 	spawn_rain(pos, {x=0, y=0, z=0}, 10)
	spawn_lightning(pos, 30 * lvl, 70)
end

biome_spawners.deciduous_forest = function(pos, dir, lvl)
	spawn_rainclouds(pos, dir, 20, lvl)
	spawn_rain(pos, {x=0, y=0, z=0}, 20, lvl)
end

biome_spawners.rainforest = function(pos, dir, lvl)
	spawn_rainclouds(pos, dir, 200, lvl)
	spawn_rain(pos, {x=0, y=0, z=0}, 20, lvl)
end

biome_spawners.coniferous_forest = function(pos, dir, lvl)
	spawn_rainclouds(pos, dir, 200, lvl)
	spawn_rain(pos, {x=0, y=0, z=0}, 20, lvl)
end

biome_spawners.cold_desert = function(pos, dir, lvl)
	spawn_blizzard(pos, dir, 15, lvl)
end

biome_spawners.desert = function(pos, dir, lvl)
	spawn_sandstorm(pos, dir, 15, lvl)
end

biome_spawners.sandstone_desert = function(pos, dir, lvl)
	spawn_sandstorm(pos, dir, 15, lvl)
end


local function set_biome_storm_sky(pinfo, b1, b2, n_biome, n_normal)
	local sky1 = biome_skies[b1]
	local sky2 = biome_skies[b2]
	if not sky1 then
		print("missing biome: ".. b1)
		return
	end
	if not sky2 then
		print("missing biome: ".. b2)
		return
	end
	
	local color = color_lerp(sky1.color, sky2.color, n_biome)
	color = color_lerp(color, pinfo.default_sky.color, n_normal)
	
	local sky
	if n_normal > .75 then
		sky = pinfo.default_sky
	elseif n_biome > .5 then
		sky = sky2
	else
		sky = sky1
	end
	
	pinfo.player:set_sky(color, sky.type or "plain", sky.tex, sky.clouds or false)
end






minetest.register_craftitem("storms:rainstick", {
	description = "Magic Rainstick",
	inventory_image = "default_stick.png^[colorize:gold:80",
	stack_max = 1,
	on_use = function(itemstack, player, pointed_thing)
		
		
		if sky_defaults == nil then
			sky_defaults = {}
			sky_defaults.col, sky_defaults.tp, sky_defaults.tex, sky_defaults.cl = player:get_sky()
		end
		
		
		if on then
			on = false
			player:set_sky(sky_defaults.col, sky_defaults.tp, sky_defaults.tex, sky_defaults.cl)
		else
			on = true
			
			
			
			local function spawn_storm()
				local pos = player:get_pos()
				local biome = get_biome(pos)
				
				
				local fn = biome_spawners[biome]
				
				if not fn then
					print("missing spawner biome: "..biome)
				end
				fn(pos)
				
-- 				set_biome_storm_sky(player, biome)
				
				if on then
					minetest.after(5, function() 
						spawn_storm()
					end)
				end
				
			end
			
			spawn_storm()
			
			player:set_sky({r=20, g=20, b=30}, "plain", nil, false)
		end
		
		
	end,
})


storms.register_on_lightning_strike(function(pos) 
	pos.y = pos.y + 1
	minetest.set_node(pos, {name="fire:basic_flame"})
	
end)


local function get_player_sky(player)
	local sky = {}
	sky.color, sky.type, sky.tex, sky.clouds = player:get_sky()
	return sky
end




minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	storm_players[name] = {
		a = nil,
		b = nil,
		fill = 1,
		player = player,
		default_sky = get_player_sky(player),
	}
	
	print(dump(storm_players[name].default_sky))
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	storm_players[name] = nil
end)


local function activate_storm(player ) 
	local pos = player:get_pos()
	local biome = get_biome(pos)
	
	
	local fn = biome_spawners[biome]
	
	if not fn then
		print("missing spawner biome: "..biome)
	end
	fn(pos)
	
-- 	set_biome_storm_sky(player, biome)
	
end

local function clamp(min, max, n) 
	if n < min then return min end
	if n > max then return max end
	return n
end

local function storm_loop()
	local time = minetest.get_gametime()
	
	for name,pinfo in pairs(storm_players) do
		local pos = pinfo.player:get_pos()
		
		local t = math.sin(time / (5 * 2 * math.pi))
		local t2 = math.cos(time  / (7 * 2 * math.pi))

		
		local p1 = {
			x = ((t * 20 + t2 * 30 + pos.x + time) % 65536) - 32768,
			y = 0,
			z = ((t * 20 + t2 * 30 + pos.z + time) % 65536) - 32768,
		}
		
		local dx = perlins.dx:get2dMap_flat(p1)[1]
		local dz = perlins.dz:get2dMap_flat(p1)[1]
		
		local tscale = .1
		
		local t3 = time % 32768
		local t4 = time % 32768
		
		local p2 = {
			x = ((t3 * (dx/10) + pos.x ) % 65536) - 32768,
			y = 0,
			z = ((t4 * (dx/10) + pos.z) % 65536) - 32768,
		}
		
		local f1 = perlins.freq1:get2dMap_flat(p1)[1]
		local f2 = perlins.freq2:get2dMap_flat(p1)[1]
		
		print("p2: "..p2.x..", ".. p2.z)
		print("perlin: ".. dx.. ", "..dz.. ", "..f1.. ", "..f2)
		
		local f = (f1 + f2) - .5
		
		local biome = get_biome(pos)
		
		print("storm intensity: ".. f .. " ("..f1..", "..f2..")")
		if f > 0 then
			
			local dir = {x = dx, y = 0, z = dz}
			
			
			
			local fn = biome_spawners[biome]
			
			if not fn then
				print("missing spawner biome: "..biome)
			end
			fn(pos, dir, 1, f)
			
		end
		
		
		
		
		set_biome_storm_sky(pinfo, biome, biome, 1, clamp(0, 1, 1-f))
	end
	
	
	minetest.after(5, storm_loop)
end


minetest.after(2, function()
	
	perlins.dx = minetest.get_perlin_map({
		flags = {eased = false}, 
		lacunarity = 4,
		octaves = 4, 
		offset = 0, 
		persistence = 0.65, 
		seed = 35363,
		scale = 10, 
		spread = {x=1000, y=1000, z=1000}
	}, {x=1,y=1,z=1})
	
	perlins.dz = minetest.get_perlin_map({
		flags = {eased = false}, 
		lacunarity = 4,
		octaves = 4, 
		offset = 0, 
		persistence = 0.65, 
		seed = 678786,
		scale = 10, 
		spread = {x=1000, y=1000, z=1000}
	}, {x=1,y=1,z=1})
	
	perlins.freq1 = minetest.get_perlin_map({
		flags = {eased = false}, 
		lacunarity = 2,
		octaves = 3, 
		offset = 0, 
		persistence = 0.25,
		seed = 79932,
		scale = 1, 
		spread = {x=2000, y=2000, z=2000}
	}, {x=1,y=1,z=1})
	
	perlins.freq2 = minetest.get_perlin_map({
		flags = {eased = false}, 
		lacunarity = 2,
		octaves = 1, 
		offset = 0, 
		persistence = 0.25, 
		seed = 6445,
		scale = 1, 
		spread = {x=2000, y=2000, z=2000}
	}, {x=1,y=1,z=1})
	
	
	storm_loop()
end)

