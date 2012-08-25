-- ludumdare 2012-08 ghoulsblade generogue
gKeyPressed = {}
gTitleScreen = true

function GfxSetPixelArtFilter (gfx) gfx:setFilter("nearest","nearest") return gfx end

function love.load()
	local function myimg (path) return GfxSetPixelArtFilter(love.graphics.newImage(path)) end
	img_genes_blue		= myimg("data/genes-blue.png"		)
	img_genes_red		= myimg("data/genes-red.png"		)
	img_mob_att			= myimg("data/mob-att.png"			)
	img_mob_def			= myimg("data/mob-def.png"			)
	img_mob_player		= myimg("data/mob-player.png"		)
	img_shadow			= myimg("data/shadow.png"			)
	img_tile_cave_floor	= myimg("data/tile-cave-floor.png"	)
	img_tile_cave		= myimg("data/tile-cave.png"		)
	img_tile_cave_wall	= myimg("data/tile-cave-wall.png"	)
	img_tile_djungle	= myimg("data/tile-djungle.png"		)
	img_tile_grass		= myimg("data/tile-grass.png"		)
	img_tile_nestegg	= myimg("data/tile-nestegg.png"		)
	img_tile_nest		= myimg("data/tile-nest.png"		)
	img_tile_sand		= myimg("data/tile-sand.png"		)
	img_tile_water		= myimg("data/tile-water.png"		)
	img_titelscreen		= myimg("data/titelscreen.jpg"		)
end

function StartGame ()
	gTitleScreen = false
end

function love.mousepressed(x,y,btn)
	if (gTitleScreen) then StartGame() end
end

function love.keypressed( key, unicode )
    gKeyPressed[key] = true
    if (key == "escape") then os.exit(0) end
	if (gTitleScreen) then StartGame() end
end
function love.keyreleased( key )
    gKeyPressed[key] = nil
end

function love.update( dt )
	if (gTitleScreen) then return end
end

function love.draw()
	if (gTitleScreen) then love.graphics.draw(img_titelscreen, 0,0, 0, 1,1) return end
end
