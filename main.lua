-- ludumdare 2012-08 ghoulsblade generogue

love.filesystem.load("lib.oop.lua")()

PLAYER_SPEED = 200 -- pixels per second

gKeyPressed = {}
gTitleScreen = true
kTileSize = 64
gOverWorldActive = true
gCurTime = love.timer.getTime()
gSecondsSinceLastFrame = 0

floor = math.floor
ceil = math.ceil
max = math.max
min = math.min
abs = math.abs
sin = math.sin
cos = math.cos

function GfxSetPixelArtFilter (gfx) gfx:setFilter("nearest","nearest") return gfx end

gMobiles = {}



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
	img_screen_title	= myimg("data/screen-title.jpg"		)
end

function StartGame ()
	gTitleScreen = false
	
	local e = kTileSize
	local tx,ty=4,4 cMobEnemy:New(img_mob_att, e*tx,e*ty)
	local tx,ty=6,4 cMobEnemy:New(img_mob_def, e*tx,e*ty)
	local tx,ty=7,3 cMobEnemy:New(img_mob_def, e*tx,e*ty)
	local tx,ty=4,6 gPlayer = cMobPlayer:New(img_mob_player, e*tx,e*ty)
	
end

function love.mousepressed(x,y,btn)
	if (gTitleScreen) then return StartGame() end
end

function love.keypressed( key, unicode )
	--~ print("keypressed",key)
    gKeyPressed[key] = true
    if (key == "escape") then os.exit(0) end
	if (gTitleScreen) then return StartGame() end
end
function love.keyreleased( key )
    gKeyPressed[key] = nil
end

function love.update( dt )
	local t = love.timer.getTime()
	gSecondsSinceLastFrame = gCurTime and min(0.1,t-gCurTime) or 0
	gCurTime = t
	if (gTitleScreen) then return end
	
	local ax,ay = 0,0
	local s = PLAYER_SPEED*dt
	if (gKeyPressed["a"] or gKeyPressed["left"]) then ax = -s end
	if (gKeyPressed["d"] or gKeyPressed["right"]) then ax = s end
	if (gKeyPressed["w"] or gKeyPressed["up"]) then ay = -s end
	if (gKeyPressed["s"] or gKeyPressed["down"]) then ay = s end
	gPlayer.x = gPlayer.x + ax
	gPlayer.y = gPlayer.y + ay
	
	--~ gOverWorldActive = not gOverWorldActive
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
	local hover_dy = math.sin(gCurTime/2*2*math.pi)
	
	-- spawn/nest
	local e = kTileSize
	local tx,ty=5,8 love.graphics.draw(img_tile_nestegg, e*tx,e*ty)
	local tx,ty=6,5 love.graphics.draw(img_shadow, e*tx,e*ty) love.graphics.draw(img_genes_red, e*tx,floor(e*ty + 4*hover_dy))
	local tx,ty=7,6 love.graphics.draw(img_shadow, e*tx,e*ty) love.graphics.draw(img_genes_blue, e*tx,floor(e*ty + 4*hover_dy))
	
	local tx,ty=7,2 love.graphics.draw(img_tile_cave, e*tx,e*ty)
	
	for mob,_ in pairs(gMobiles) do mob:Draw() end
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
	gCurTime = love.timer.getTime()
	if (gTitleScreen) then love.graphics.draw(img_screen_title, 0,0) return end
	
	local vw = love.graphics.getWidth()
	local vh = love.graphics.getHeight()
	
	if (gOverWorldActive) then
		Draw_OverWorld(vw,vh)
	else
		Draw_Dungeon(vw,vh)
	end
	Draw_Mobiles()
end


-- ***** ***** ***** ***** ***** cMobBase
cMobBase = CreateClass()

function cMobBase:Draw () 
	local x,y = self.x,self.y
	love.graphics.draw(img_shadow,x,y)
	love.graphics.draw(self.img,x,y)
end

-- ***** ***** ***** ***** ***** cMobEnemy
cMobEnemy = CreateClass(cMobBase)

function cMobEnemy:Init (img,x,y) 
	self.img = img
	self.x = x
	self.y = y
	gMobiles[self] = true
end

-- ***** ***** ***** ***** ***** cMobPlayer
cMobPlayer = CreateClass(cMobBase)

function cMobPlayer:Init (img,x,y) 
	self.img = img
	self.x = x
	self.y = y
	gMobiles[self] = true
end

-- ***** ***** ***** ***** ***** rest
