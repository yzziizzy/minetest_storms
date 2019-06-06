

local on_strike = {}


storms = {
}


storms.register_on_lightning_strike = function(fn) 
	table.insert(on_strike, fn)
end


local on = false
local sky_defaults = nil
local storm_players = {}


local good_biomes = {}
for _,def in pairs(minetest.registered_biomes) do
	if def.y_max >= 10 and def.y_min <= 10 then
		table.insert(good_biomes, def)
	end
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
	


minetest.after(0, function()
	local noise = minetest.get_mapgen_setting_noiseparams("mg_biome_np_heat")
	heat_noise = minetest.get_perlin(noise)
	
	noise = minetest.get_mapgen_setting_noiseparams("mg_biome_np_humidity")
	humidity_noise = minetest.get_perlin(noise)
end)


local function get_noise(pos) 
	return heat_noise:get2d({x=pos.x, y=pos.z}), humidity_noise:get2d({x=pos.x, y=pos.z})
end

local function get_biome(pos)
	local he, hu = get_noise(pos)
	return find_biome(he, hu)
end


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

local function spawn_sandstorm(pos, vel, sz)
	local ht = 7

	minetest.add_particlespawner({
		amount = 5000,
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


local function spawn_rainclouds(pos, vel, sz)
	local offht = 60
	local ht = 10

	minetest.add_particlespawner({
		amount = 5000,
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

local function spawn_rain(pos, vel, sz)
	local offht = 10
	local ht = 10
	
	minetest.add_particlespawner({
		amount = 1000,
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


biome_spawners.tundra = function(pos)
	spawn_blizzard(pos, {x= 10, y=0, z=10}, 15)
end

biome_spawners.taiga = function(pos)
	spawn_blizzard(pos, {x= 10, y=0, z=10}, 15)
end

biome_spawners.grassland = function(pos)
	spawn_rainclouds(pos, {x= 10, y=0, z=10}, 200)
	spawn_rain(pos, {x=0, y=0, z=0}, 20)
	spawn_lightning(pos, 10, 50)
end

biome_spawners.snowy_grassland = function(pos)
	spawn_blizzard(pos, {x= 10, y=0, z=10}, 15)
end

biome_spawners.savanna = function(pos)
	spawn_rainclouds(pos, {x= 10, y=0, z=10}, 200)
-- 	spawn_rain(pos, {x=0, y=0, z=0}, 10)
	spawn_lightning(pos, 30, 50)
end

biome_spawners.deciduous_forest = function(pos)
	spawn_rainclouds(pos, {x= 10, y=0, z=10}, 200)
	spawn_rain(pos, {x=0, y=0, z=0}, 20)
end

biome_spawners.rainforest = function(pos)
	spawn_rainclouds(pos, {x= 10, y=0, z=10}, 200)
	spawn_rain(pos, {x=0, y=0, z=0}, 20)
end

biome_spawners.coniferous_forest = function(pos)
	spawn_rainclouds(pos, {x= 10, y=0, z=10}, 200)
	spawn_rain(pos, {x=0, y=0, z=0}, 20)
end

biome_spawners.cold_desert = function(pos)
	spawn_blizzard(pos, {x= 10, y=0, z=10}, 15)
end

biome_spawners.desert = function(pos)
	spawn_sandstorm(pos, {x= 10, y=0, z=10}, 15)
end

biome_spawners.sandstone_desert = function(pos)
	spawn_sandstorm(pos, {x= 10, y=0, z=10}, 15)
end


local function set_biome_storm_sky(player, biome)
	local sky = biome_skies[biome]
	if not sky then
		print("missing biome: ".. biome)
		return
	end
	player:set_sky(sky.color, sky.type or "plain", sky.textures, sky.clouds or false)
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
				
				set_biome_storm_sky(player, biome)
				
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
