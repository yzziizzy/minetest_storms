

local on_strike = {}


storms = {
}


storms.register_on_lightning_strike = function(fn) 
	table.insert(on_strike, fn)
end


local on = false

local sky_defaults = nil

local heat_noise = nil
local humidity_nois = nil
local storm_players = {}


minetest.after(1, function()
	local noise = minetest.get_mapgen_setting_noiseparams("mg_biome_np_heat")
	heat_noise = minetest.get_perlin_map(noise, {x=1, y=1, z=1})
	
	noise = minetest.get_mapgen_setting_noiseparams("mg_biome_np_humidity")
	humidity_noise = minetest.get_perlin_map(noise, {x=1, y=1, z=1})
end)


local function get_noise(pos) 
	return heat_noise:get2dMap(pos), humidity_noise:get2dMap(pos)
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
	
	while h > -16 do
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
			
			local function spawn_clouds()
				local pos = player:get_pos()
				pos.y = pos.y + 55
				
				local sz = 300
				local ht = 10
				
				local vel = {x=5, y = 0, z=1}
				
				-- clouds
				minetest.add_particlespawner({
					amount = 5000,
					time = 5,
					minpos = {x=pos.x-sz, y=pos.y, z=pos.z-sz},
					maxpos = {x=pos.x+sz, y=pos.y+ht, z=pos.z+sz},
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
				
				-- rain
				minetest.add_particlespawner({
					amount = 1000,
					time = 5,
					minpos = {x=pos.x-20, y=pos.y, z=pos.z-20},
					maxpos = {x=pos.x+20, y=pos.y+ht, z=pos.z+20},
					minvel = {x=0, y=-40, z=0},
					maxvel = {x=0, y=-40,  z=0},
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
				
				for i = 1,math.random(18) do
					minetest.after(math.random(5), function()
						do_lightning(pos.y, randompos(pos, 40))
					end)
				end
				
				if on then
					minetest.after(5, function() 
						spawn_clouds()
					end)
				end
				
			end
			
			spawn_clouds()
			
			player:set_sky({r=20, g=20, b=30}, "plain", nil, false)
		end
		
		
	end,
})


storms.register_on_lightning_strike(function(pos) 
	pos.y = pos.y + 1
	minetest.set_node(pos, {name="fire:basic_flame"})
	
end)
