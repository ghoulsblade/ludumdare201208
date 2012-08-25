-- ludumdare 2012-08 ghoulsblade generogue
gKeyPressed = {}
gTitleScreen = true
kTileSize = 64
gOverWorldActive = true

function GfxSetPixelArtFilter (gfx) gfx:setFilter("nearest","nearest") return gfx end

function love.load()
	local function myimg (path) return GfxSetPixelArtFilter(love.graphics.newImage(path)) end
	img_genes_blue		= myimg("data/genes-blue.png"		)
	img_genes_red		= myimg("data/genes-red.png"		)
	img_mob_att			= myimg("data/mob-att.png"			)
	img_mob_def			= myimg("data/mob-def.png"			)
	img_mob_player		= myimg("data/mob-player.png"		)
	img_shadow			= myimg("data/shadow.png"			)
	img_tile_cave		= myimg("data/tile-cave.png"		)
	img_tile_cave_floor	= myimg("data/tile-cave-floor.png"	)
	img_tile_cave_wall	= myimg("data/tile-cave-wall.png"	)
	img_tile_djungle	= myimg("data/tile-djungle.png"		)
	img_tile_grass		= myimg("data/tile-grass.png"		)
	img_tile_nestegg	= myimg("data/tile-nestegg.png"		)
	img_tile_nest		= myimg("data/tile-nest.png"		)
	img_tile_sand		= myimg("data/tile-sand.png"		)
	img_tile_water		= myimg("data/tile-water.png"		)
	img_tile_sand_water	= myimg("data/tile-sand-water.png"	)
	img_titelscreen		= myimg("data/titelscreen.jpg"		)
end

function StartGame ()
	gTitleScreen = false
end

function love.mousepressed(x,y,btn)
	if (gTitleScreen) then return StartGame() end
	gOverWorldActive = not gOverWorldActive
end

function love.keypressed( key, unicode )
    gKeyPressed[key] = true
    if (key == "escape") then os.exit(0) end
	if (gTitleScreen) then return StartGame() end
	gOverWorldActive = not gOverWorldActive
end
function love.keyreleased( key )
    gKeyPressed[key] = nil
end

function love.update( dt )
	if (gTitleScreen) then return end
end

function Draw_OverWorld (vw,vh)
	-- background
	local e = kTileSize
	for ty = 0,vh/kTileSize do 
	for tx = 0,vw/kTileSize do 
		local tile = img_tile_sand
		if (tx <  3) then tile = img_tile_water end
		if (tx == 3) then tile = img_tile_sand_water end
		love.graphics.draw(tile, e*tx,e*ty)
	end
	end
end

function Draw_Mobiles ()
	-- spawn/nest
	local e = kTileSize
	local tx,ty=5,8 love.graphics.draw(img_tile_nestegg, e*tx,e*ty)
	local tx,ty=4,6 love.graphics.draw(img_shadow, e*tx,e*ty) love.graphics.draw(img_mob_player, e*tx,e*ty)
	local tx,ty=6,5 love.graphics.draw(img_shadow, e*tx,e*ty) love.graphics.draw(img_genes_red, e*tx,e*ty)
	local tx,ty=7,6 love.graphics.draw(img_shadow, e*tx,e*ty) love.graphics.draw(img_genes_blue, e*tx,e*ty)
	
	local tx,ty=4,4 love.graphics.draw(img_shadow, e*tx,e*ty) love.graphics.draw(img_mob_att, e*tx,e*ty)
	local tx,ty=6,4 love.graphics.draw(img_shadow, e*tx,e*ty) love.graphics.draw(img_mob_def, e*tx,e*ty)
	local tx,ty=7,3 love.graphics.draw(img_shadow, e*tx,e*ty) love.graphics.draw(img_mob_def, e*tx,e*ty)
	local tx,ty=7,2 love.graphics.draw(img_tile_cave, e*tx,e*ty)
	
end


function Draw_Dungeon (vw,vh) 
	if (not gDungeonWall) then 
		gDungeonWall = {}
		for ty = 0,vh/kTileSize do 
		for tx = 0,vw/kTileSize do 
			if (math.random(10) == 1) then gDungeonWall[tx..","..ty] = true end 
		end
		end
	end

	-- background
	local e = kTileSize
	for ty = 0,vh/kTileSize do 
	for tx = 0,vw/kTileSize do 
		local tile = img_tile_cave_floor
		if (gDungeonWall[tx..","..ty]) then tile = img_tile_cave_wall end
		love.graphics.draw(tile, e*tx,e*ty)
	end
	end
end

function love.draw()
	if (gTitleScreen) then love.graphics.draw(img_titelscreen, 0,0) return end
	
	local vw = love.graphics.getWidth()
	local vh = love.graphics.getHeight()
	
	if (gOverWorldActive) then
		Draw_OverWorld(vw,vh)
	else
		Draw_Dungeon(vw,vh)
	end
	Draw_Mobiles()
end
