-- ludumdare 2012-08 ghoulsblade generogue

love.filesystem.load("lib.oop.lua")()
love.filesystem.load("lib.mobiles.lua")()
love.filesystem.load("lib.items.lua")()
love.filesystem.load("lib.area.lua")()

kTileSize = 64
kIconSize = 16
SPEED_PLAYER = 200 -- pixels per second
SPEED_ENEMY = SPEED_PLAYER*0.5 -- pixels per second
STOPDIST_PLAYER_MOUSE = 20 -- pixels
STOPDIST_ENEMY_TARGET = 20 -- pixels
HUNTDIST_ENEMY_TARGET = 200 -- pixels
ENEMY_SPREAD_DIST = kTileSize*1.0 -- pixels, enemies try to keep distance from each other
DT_MAX = 0.1 -- avoid jumps when lag
ENEMY_ATTACK_RANGE = kTileSize*1.0
PLAYER_ATTACK_RANGE = ENEMY_ATTACK_RANGE*1.5 -- enemy reacts faster so give a little bonus
VEL_HIT = SPEED_PLAYER * 2 -- velocity added/set when someone is hit
VEL_DAMP = 0.95
PLAYER_ATTACK_INTERVAL = 0.2 -- seconds
MOBILE_ATTACK_INTERVAL = 0.2 -- seconds
MOBILE_ATTACK_ANIM_DUR = 0.1 -- seconds
PLAYER_START_ATT = 1
PLAYER_START_DEF = 5
CAM_DAMP = 0.9
ITEM_TOUCH_DIST = kTileSize
PLAYER_RESPAWN_DELAY = 2 -- seconds

OVERWORLD_TX_SAND = 1
OVERWORLD_TX_GRASS = 1*15
OVERWORLD_TX_DJUNGLE = 2*15


gCamX = 0
gCamY = 0
gCamTargetX = 0
gCamTargetY = 0

gCarried_Blue 	= 0
gCarried_Red  	= 0
gEgg_Blue 		= 0
gEgg_Red  		= 0
gEgg_TX			= 4
gEgg_TY			= 6

gKeyPressed = {}
gTitleScreen = true
gCurTime = love.timer.getTime()
gSecondsSinceLastFrame = 0

floor = math.floor
ceil = math.ceil
max = math.max
min = math.min
abs = math.abs
sin = math.sin
cos = math.cos
random = math.random

function GfxSetPixelArtFilter (gfx) gfx:setFilter("nearest","nearest") return gfx end




-- ***** ***** ***** ***** ***** love.load

function love.load()
	local function myimg (path) return GfxSetPixelArtFilter(love.graphics.newImage(path)) end
	img_genes_blue		= myimg("data/genes-blue.png"		)
	img_genes_red		= myimg("data/genes-red.png"		)
	img_tile_nest		= myimg("data/tile-nest.png"		)
	img_tile_nestegg	= myimg("data/tile-nestegg.png"		)
	
	img_mob_att			= myimg("data/mob-att.png"			)
	img_mob_def			= myimg("data/mob-def.png"			)
	img_mob_player		= myimg("data/mob-player.png"		)
	
	img_part_face_grr	= myimg("data/part-face-grr.png"	)
	img_part_face_oh	= myimg("data/part-face-oh.png"		)
	img_part_legs_st	= myimg("data/part-legs-st.png"		)
	img_part_legs_w1	= myimg("data/part-legs-w1.png"		)
	img_part_legs_w2	= myimg("data/part-legs-w2.png"		)
	img_part_shield		= myimg("data/part-shield.png"		)
	img_part_sword2		= myimg("data/part-sword2.png"		)
	img_part_sword		= myimg("data/part-sword.png"		)
	
	img_icon_shield_half= myimg("data/icon-shield-half.png"	)
	img_icon_shield		= myimg("data/icon-shield.png"		)
	img_icon_sword		= myimg("data/icon-sword.png"		)

	img_shadow			= myimg("data/shadow.png"			)
	
	img_tile_cave		= myimg("data/tile-cave.png"		)
	img_tile_cave_exit	= myimg("data/tile-cave-exit.png"	)
	img_tile_cave_floor	= myimg("data/tile-cave-floor.png"	)
	img_tile_cave_wall	= myimg("data/tile-cave-wall.png"	)
	
	img_tile_water		= myimg("data/tile-water.png"		)
	img_tile_sand_water	= myimg("data/tile-sand-water.png"	)
	img_tile_sand		= myimg("data/tile-sand.png"		)
	img_tile_grass		= myimg("data/tile-grass.png"		)
	img_tile_djungle	= myimg("data/tile-djungle.png"		)
	
	img_screen_title	= myimg("data/screen-title.jpg"		)
	
	if (love.web) then 
		fontimg = myimg("data/imgfont.png")
		imgfont = love.graphics.newImageFont(fontimg," abcdefghijklmnopqrstuvwxyz0123456789.!'-:·")
		love.graphics.setFont(imgfont)
		gFontScale = 5
	else
		love.graphics.setFont(love.graphics.newFont(40))
		gFontScale = 1
	end
	
	UpdateScreenSize()
end

function UpdateScreenSize ()
	if (gScreenW and gScreenW > 0) then return end -- only once
	gScreenW = love.graphics.getWidth()
	gScreenH = love.graphics.getHeight()
end

-- ***** ***** ***** ***** ***** key and mouse

function love.mousereleased(x,y,btn)
	--~ print("mousereleased",x,y,btn)
	if (btn == "l") then gMouseDownL = false end
end
function love.mousepressed(x,y,btn)
	--~ print("mousepressed",x,y,btn)
	if (btn == "l") then gMouseDownL = true end
	
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

-- ***** ***** ***** ***** ***** love.update

function love.update( dt )
	UpdateScreenSize()
	
	if (dt > DT_MAX) then dt = DT_MAX end
	local t = love.timer.getTime()
	gSecondsSinceLastFrame = gCurTime and min(0.1,t-gCurTime) or 0
	gCurTime = t
	if (gTitleScreen) then return end
	
	if (gRepawnTime and gRepawnTime < gCurTime) then 
		gRepawnTime = nil
		PlayerRespawn()
	end
	
	if (not gPlayer.dead) then 
		--[[
		local ax,ay = 0,0
		if (gKeyPressed["a"] or gKeyPressed["left"]) then ax = -s end
		if (gKeyPressed["d"] or gKeyPressed["right"]) then ax = s end
		if (gKeyPressed["w"] or gKeyPressed["up"]) then ay = -s end
		if (gKeyPressed["s"] or gKeyPressed["down"]) then ay = s end
		]]--
	
		local x, y = love.mouse.getPosition()
		gPlayer:WalkToPos(x+gCamX,y+gCamY,SPEED_PLAYER,STOPDIST_PLAYER_MOUSE,dt)
	
		if (gKeyPressed[" "] or gMouseDownL) then gPlayer:AutoAttack() end
	end
	
	for o,_ in pairs(gCurArea.items) do o:Step(dt) end
	for o,_ in pairs(gCurArea.mobiles) do o:Step(dt) end
	gPlayer:Step(dt)
	gCurArea:Update(dt)
	
	CamStep()
end

-- ***** ***** ***** ***** ***** love.draw

function love.draw()
	gCurTime = love.timer.getTime()
	if (gTitleScreen) then love.graphics.draw(img_screen_title, 0,0) return end
	
	gCurArea:Draw()
	
	for o,_ in pairs(gCurArea.items) do o:Draw(gCamX,gCamY) end
	for o,_ in pairs(gCurArea.mobiles) do o:Draw(gCamX,gCamY) end
	gPlayer:Draw(gCamX,gCamY)
	
	
	local ox = 10
	local oy = 2
	local e = kTileSize
	local b = kTileSize*2
	local s = gFontScale
	local col_red = {255,0,0,255}
	local col_blue = {0,128,255,255}
	
	
	love.graphics.draw(img_genes_red	,ox+0*b  ,oy)
	love.graphics.draw(img_genes_blue	,ox+1*b  ,oy)
	love.graphics.draw(img_tile_nestegg	,ox+2*b  ,oy) 
	
	
	love.graphics.setColor(unpack(col_red))
	love.graphics.print(gCarried_Red	,ox+0*b+e,oy,0,s,s)
	love.graphics.print(gEgg_Red		,ox+2*b+e  ,oy,0,s,s)
	love.graphics.setColor(unpack(col_blue))
	love.graphics.print(gCarried_Blue	,ox+1*b+e,oy,0,s,s)
	love.graphics.print(gEgg_Blue		,ox+2*b+e+e,oy,0,s,s)
	love.graphics.setColor(255,255,255,255)
	
end



-- ***** ***** ***** ***** ***** gamestart

function StartGame ()
	gTitleScreen = false
	gAreaOverworld = cAreaOverworld:New()
	ChangeToArea(gAreaOverworld)
 
	PlayerRespawn()
end

function ChangeToArea (area)
	gCurArea = area
	gCurArea:OnEnter()
end

function PlayerRespawn()
	gCarried_Blue 	= gEgg_Blue
	gCarried_Red  	= gEgg_Red
	ChangeToArea(gAreaOverworld)
	gPlayer = cMobPlayer:New(nil,img_mob_player, gEgg_TX,gEgg_TY)
	gPlayer.att = PLAYER_START_ATT + gEgg_Red
	gPlayer.def = PLAYER_START_DEF + gEgg_Blue * 2
	gAreaOverworld:MoveCamToPlayer(true)
end

-- ***** ***** ***** ***** ***** cam

function CamSetTarget (x,y,bHardReset)
	gCamTargetX = x
	gCamTargetY = y
	if (bHardReset) then 
		gCamX = x
		gCamY = y
	end
end

function CamStep ()
	local f = CAM_DAMP
	local fi = 1-CAM_DAMP
	gCamX = f*gCamX + fi*gCamTargetX
	gCamY = f*gCamY + fi*gCamTargetY
end

-- ***** ***** ***** ***** ***** utils

function dist2 (ax,ay,bx,by) return hypot(ax-bx,ay-by) end
function hypot (dx,dy) return math.sqrt(dx*dx+dy*dy) end

-- dur in seconds
function GetHoverDY (dur,t) return math.sin((t or gCurTime)/dur*2*math.pi) end


-- fdur : frame duration, seconds
function anim_frame (t,arr,fdur) 
	local fnum = #arr
	return arr[1+math.fmod(floor(t/fdur),fnum)]
end


-- ***** ***** ***** ***** ***** rest
