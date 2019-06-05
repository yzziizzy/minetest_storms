

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
			
			function spawn_clouds()
				local pos = player:get_pos()
				pos.y = pos.y + 55
				
				local sz = 300
				local ht = 10
				
				local vel = {x=5, y = 0, z=1}
				
				minetest.add_particlespawner({
					amount = 5000,
					time = 5,
					minpos = {x=pos.x-sz, y=pos.y, z=pos.z-sz},
					maxpos = {x=pos.x+sz, y=pos.y+ht, z=pos.z+sz},
					minvel = vector.add(vel, {x=-1, y=0, z=-1}),
					maxvel = vector.add(vel, {x=5,  y=0.5,  z=5}),
					minacc = {x=-0.1, y=0.1, z=-0.1},
					maxacc = {x=0.1, y=0.3, z=0.1},
					minexptime = 5,
					maxexptime = 10,
					minsize = 300,
					maxsize = 400,
					texture = "storms_cloud.png^[colorize:black:120",
				})
				
				--[[
				minetest.add_particlespawner({
					amount = 350,
					time = 15,
					minpos = {x=pos.x-sz, y=pos.y, z=pos.z-sz},
					maxpos = {x=pos.x+sz, y=pos.y+ht, z=pos.z+sz},
					minvel = {x=0, y=-89, z=0},
					maxvel = {x=5, y=-89, z=0},
					minacc = {x=0, y=0, z=0},
					maxacc = {x=0, y=0, z=0},
					minexptime = 2,
					maxexptime = 2,
					minsize = 100,
					maxsize = 100,
					texture = "biometest_rain.png^[colorize:red:0",
				})
				]]
				
				if on then
					minetest.after(10, function() 
						spawn_clouds()
					end)
				end
				
			end
			
			spawn_clouds()
			
			player:set_sky({r=20, g=20, b=30}, "plain", nil, false)
		end
		
		
	end,
})


