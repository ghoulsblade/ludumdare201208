-- ludumdare 2012-08 ghoulsblade generogue
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
DUNGEON_TUNNEL_MINW = 2
DUNGEON_TUNNEL_MAXW = 2
DUNGEON_ROOM_MINR = 2
DUNGEON_ROOM_MAXR = 4
DUNGEON_GRID_SIZE = 3+2*DUNGEON_ROOM_MAXR
DEBUG_CHEATS_ON = false
if (arg and arg[2] == "-cheat") then DEBUG_CHEATS_ON = true end
--~ DEBUG_CHEATS_ON = true

VALUE_ICON_SWORD_1 = 1
VALUE_ICON_SWORD_2 = 3*VALUE_ICON_SWORD_1
VALUE_ICON_SWORD_3 = 3*VALUE_ICON_SWORD_2
VALUE_ICON_SWORD_4 = 3*VALUE_ICON_SWORD_3
VALUE_ICON_SHIELD_h = 1
VALUE_ICON_SHIELD_1 = 2
VALUE_ICON_SHIELD_2 = 3*VALUE_ICON_SHIELD_1
VALUE_ICON_SHIELD_3 = 3*VALUE_ICON_SHIELD_2
VALUE_ICON_SHIELD_4 = 3*VALUE_ICON_SHIELD_3

local ts = 15

OVERWORLD_TX_SAND			= -2
OVERWORLD_TX_GRASS			= 1*25 + 2
OVERWORLD_TX_DJUNGLE		= 2*25 + 2
OVERWORLD_TX_END_DUNGEONS	= 4*25 + 2
OVERWORLD_TX_KING			= OVERWORLD_TX_END_DUNGEONS + 15
OVERWORLD_TX_END_ABYSS		= OVERWORLD_TX_KING + ts*7
OVERWORLD_TX_END_DECO		= OVERWORLD_TX_END_ABYSS
OVERWORLD_ABYSS_DAMAGE		= 10

gEndText = {
	[OVERWORLD_TX_KING + ts*1] = "The End."  ,
	[OVERWORLD_TX_KING + ts*2] = "Really, that was it.",
	[OVERWORLD_TX_KING + ts*3] = "...",
	[OVERWORLD_TX_KING + ts*4] = "Ende. Fin. Final. Fine.",
	[OVERWORLD_TX_KING + ts*5] = "...",
	[OVERWORLD_TX_KING + ts*6] = "you asked for it, go ahead...",
}

OVERWORLD_NUM_DECO = 200
DUNGEON_NUM_DECO_PER_ROOM = 5
DUNGEON_NUM_DECO_MAX = 500

gMusic = true
gSound = true
VOLUME_MUSIC = 0.5
VOLUME_SOUND = 1

gCamX = 0
gCamY = 0
gCamTargetX = 0
gCamTargetY = 0

gCarried_Blue 	= 0
gCarried_Red  	= 0
gEgg_Blue 		= 0
gEgg_Red  		= 0
gEgg_TX			= 0
gEgg_TY			= 6
if (DEBUG_CHEATS_ON) then 
	gEgg_Blue 		= 3
	gEgg_Red  		= 5
end

gPause = false

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

function GfxSetPixelArtFilter (gfx,bLinear) if (not bLinear) then gfx:setFilter("nearest","nearest") end return gfx end




-- ***** ***** ***** ***** ***** love.load

function love.load()
	local function myimg (path,bLinear) return GfxSetPixelArtFilter(love.graphics.newImage(path),bLinear) end
	img_genes_blue		= myimg("data/genes-blue.png"		)
	img_genes_red		= myimg("data/genes-red.png"		)
	img_tile_nest		= myimg("data/tile-nest.png"		)
	img_tile_nestegg	= myimg("data/tile-nestegg.png"		)
	
	img_dark			= myimg("data/dark.png"				,true)
	
	img_mob_att			= myimg("data/mob-att.png"			)
	img_mob_def			= myimg("data/mob-def.png"			)
	img_mob_player		= myimg("data/mob-player.png"		)
	cMobHumanoidRed.img_default = img_mob_att
	cMobHumanoidBlue.img_default = img_mob_def
	cMobKing.img_default = img_mob_def
	
	img_part_face_grr	= myimg("data/part-face-grr.png"	)
	img_part_face_oh	= myimg("data/part-face-oh.png"		)
	img_crown			= myimg("data/crown.png"			)
	img_part_legs_l_st	= myimg("data/part-legs-l-st.png"	)
	img_part_legs_l_w1	= myimg("data/part-legs-l-w1.png"	)
	img_part_legs_l_w2	= myimg("data/part-legs-l-w2.png"	)
	img_part_legs_r_st	= myimg("data/part-legs-r-st.png"	)
	img_part_legs_r_w1	= myimg("data/part-legs-r-w1.png"	)
	img_part_legs_r_w2	= myimg("data/part-legs-r-w2.png"	)
	img_part_shield		= myimg("data/part-shield.png"		)
	img_part_sword2		= myimg("data/part-sword2.png"		)
	img_part_sword		= myimg("data/part-sword.png"		)
	img_part_shield_r	= myimg("data/part-shield-r.png"		)
	img_part_sword2_r	= myimg("data/part-sword2-r.png"		)
	img_part_sword_r	= myimg("data/part-sword-r.png"		)
	
	img_icon_shield_half= myimg("data/icon-shield-half.png"	)
	img_icon_shield		= myimg("data/icon-shield.png"		)
	img_icon_shield2	= myimg("data/icon-shield2.png"		)
	img_icon_shield3	= myimg("data/icon-shield3.png"		)
	img_icon_shield4	= myimg("data/icon-shield4.png"		)
	img_icon_sword		= myimg("data/icon-sword.png"		)
	img_icon_sword2		= myimg("data/icon-sword2.png"		)
	img_icon_sword3		= myimg("data/icon-sword3.png"		)
	img_icon_sword4		= myimg("data/icon-sword4.png"		)

	img_shadow			= myimg("data/shadow.png"			)
	
	img_tile_cave		= myimg("data/tile-cave.png"		)
	img_tile_cave_sand	= myimg("data/tile-cave-sand.png"		)
	img_tile_cave_exit	= myimg("data/tile-cave-exit.png"	)
	img_tile_cave_floor	= myimg("data/tile-cave-floor.png"	)
	img_tile_cave_wall	= myimg("data/tile-cave-wall.png"	)
	img_tile_black		= myimg("data/tile-black.png"		)
	
	img_tile_water		= myimg("data/tile-water.png"		)
	img_tile_sand_water	= myimg("data/tile-sand-water.png"	)
	img_tile_sand		= myimg("data/tile-sand.png"		)
	img_tile_grass		= myimg("data/tile-grass.png"		)
	img_tile_djungle	= myimg("data/tile-djungle.png"		)
	
	img_cave_border_h	= myimg("data/cave-border-h.png"	)
	img_cave_border_v	= myimg("data/cave-border-v.png"	)
	
	img_screen_title	= myimg("data/screen-title.jpg"		)
	
	local e = 16
	cMobSpider.img_w		= myimg("data/enemy/enemy-spider-w.png")
	cMobSpider.img_st		= myimg("data/enemy/enemy-spider-st.png")
	cMobSpider.img_att		= myimg("data/enemy/enemy-spider-att.png")
	cMobSpiderBlack.img_w	= myimg("data/enemy/enemy-spider-black-w.png")
	cMobSpiderBlack.img_st	= myimg("data/enemy/enemy-spider-black-st.png")
	cMobSpiderBlack.img_att	= myimg("data/enemy/enemy-spider-black-att.png")
	
	cMobSpider.shadow_off = e
	cMobSpiderBlack.shadow_off = e
	
	cMobBatHell.flying		= true
	cMobBatHell.img_up		= myimg("data/enemy/enemy-bat-hell-up.png")
	cMobBatHell.img_dn		= myimg("data/enemy/enemy-bat-hell-dn.png")
	
	cMobBat.flying			= true
	cMobBat.img_up			= myimg("data/enemy/enemy-bat-up.png")
	cMobBat.img_dn			= myimg("data/enemy/enemy-bat-dn.png")
	
	cMobCrab.img_w			= myimg("data/enemy/enemy-crab-w.png")
	cMobCrab.img_st			= myimg("data/enemy/enemy-crab-st.png")
	cMobCrab.img_att		= myimg("data/enemy/enemy-crab-att.png")
	cMobCrabBlack.img_w		= myimg("data/enemy/enemy-crab-black-w.png")
	cMobCrabBlack.img_st	= myimg("data/enemy/enemy-crab-black-st.png")
	cMobCrabBlack.img_att	= myimg("data/enemy/enemy-crab-black-att.png")
	

	cMobCrab.shadow_off = e
	cMobCrabBlack.shadow_off = e
	
	gRoomCrew = {
		{min_level=  1 , max_level =  4 , crew = {cMobCrab,cMobCrabBlack}},
		{min_level=  3 , max_level = 99 , crew = {cMobBatHell,cMobBat}},
		{min_level=  6 , max_level = 99 , crew = {cMobSpiderBlack,cMobSpider}},
		{min_level= 10 , max_level = 99 , crew = {cMobSpiderBlack,cMobSpider}},
		{min_level= 15 , max_level = 99 , crew = {cMobHumanoidRed,cMobHumanoidBlue}},
		{min_level= 20 , max_level = 99 , crew = {cMobHumanoidRed,cMobHumanoidBlue}},
	}
	
	function GetLevelAttDef_Red  (level) return 2*ceil(level/2),1*level end
	function GetLevelAttDef_Blue (level) return 1*ceil(level/2),2*level end
	function SpawnOverworldMobs (area)
		gScreenH = max(gScreenH,5) -- just to make sure webplayer doesnt mess this up
		for k,o in ipairs(gRoomCrew) do 
			local level =  o.min_level
			local tx = level * 5 + 1
			local eclass_red,eclass_blue = unpack(o.crew)
			local num = 2
			if (level > 5) then num = 3 end
			if (level > 10) then num = 4 end
			if (level > 15) then num = 5 end
			for i=1,num do 
				if (eclass_red ) then eclass_red:New( area,nil, tx+randirange(0,5),randirange(1,gScreenH / kTileSize - 2), GetLevelAttDef_Red(level)) end
				if (eclass_blue) then eclass_blue:New(area,nil, tx+randirange(0,5),randirange(1,gScreenH / kTileSize - 2), GetLevelAttDef_Blue(level)) end
			end
		end
		
		local level = 50
		local tx = OVERWORLD_TX_KING
		cMobKing:New(area,nil, tx+randirange(0,5),randirange(1,gScreenH / kTileSize - 2), GetLevelAttDef_Blue(level))
	end
	
	function GetRandomEnemyClassForLevel (level) 
		local arr = {}
		-- maxlevel 2012-08-28 = 20
		for k,o in ipairs(gRoomCrew) do 
			if (level >= o.min_level and level <= o.max_level) then table.insert(arr,o.crew) end
		end
		return unpack(randarr(arr))
	end
	
	-- test 
	--~ function ClassName (c) for k,v in pairs(_G or {}) do if (v == c) then return k end end end
	--~ for level = 1,20 do
	--~ for i = 1,10 do 
		--~ local a,b = GetRandomEnemyClassForLevel(level)	
		--~ print("level",level,ClassName(a),ClassName(b)) 
	--~ end
	--~ print("---")
	--~ end
		
	
	imgarr_deco_cave = {
		myimg("data/deco/deco_cave1.png"),
		myimg("data/deco/deco_cave2.png"),
		myimg("data/deco/deco_cave3.png"),
		myimg("data/deco/deco_cave4.png"),
		myimg("data/deco/deco_cave5.png"),
		myimg("data/deco/deco_cave6.png"),
		myimg("data/deco/deco_cave7.png"),
		myimg("data/deco/deco_cave8.png"),
	}
	imgarr_deco_djungle = {
		myimg("data/deco/deco_djungle1.png"),
		myimg("data/deco/deco_djungle2.png"),
		myimg("data/deco/deco_djungle3.png"),
	}
	imgarr_deco_grass = {
		myimg("data/deco/deco_grass1.png"),
		myimg("data/deco/deco_grass2.png"),
		myimg("data/deco/deco_grass3.png"),
		myimg("data/deco/deco_grass4.png"),
	}
	imgarr_deco_sand = {
		myimg("data/deco/deco_sand1.png"),
		myimg("data/deco/deco_sand2.png"),
	}
	
	
	if (gSound) then 
		snds = {}
		local function mysnd (path) 
			local snd = {}
			if (gSound) then 
				snd.src = love.audio.newSource(path,"static") 
				snd.src:setVolume(VOLUME_SOUND) 
			end
			function snd:play ()
				if (self.next_play_t > gCurTime) then return end
				self.next_play_t = gCurTime + self.play_interval
				if (gSound) then 
					--~ love.audio.play(self.src)
					self.src:stop()
					self.src:rewind()
					self.src:play() -- Starts playing the Source.
				end
				--~ print("snd:play()",self.path)
			end
			snd.path = path 
			snd.next_play_t = 0
			snd.play_interval = 0.1 -- seconds
			table.insert(snds,snd) 
			return snd 
		end
		snd_hit			= mysnd("data/hit.wav")
		snd_death		= mysnd("data/death.wav")
		snd_ouch		= mysnd("data/ouch.wav")
		snd_powerup		= mysnd("data/powerup.wav")
		snd_swing		= mysnd("data/swing.wav")
	end


	
	if (gMusic) then
		local musicpath = "data/backloop.ogg"
		gMusicSrc = love.audio.newSource(musicpath)
		gMusicSrc:setLooping(true)
		gMusicSrc:setVolume(VOLUME_MUSIC)
		gMusicSrc:play()
	end

	
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
    if (key == "f1") then print("player pos",floor(gPlayer.x/kTileSize),floor(gPlayer.y/kTileSize)) end
    if (key == "p" and DEBUG_CHEATS_ON) then gPause = not gPause end
    if (key == "l" and DEBUG_CHEATS_ON) then gPlayer.x = OVERWORLD_TX_KING * kTileSize end
    if (key == "n" and DEBUG_CHEATS_ON) then gPlayer.x = (OVERWORLD_TX_END_ABYSS - 5) * kTileSize end
    if (key == "m" and gMusicSrc) then 
		gMusicSrc:setVolume(0)
		gMusicSrc:stop()
		gMusicSrc:rewind()
		gMusicSrc:setLooping(false)
	end
	
	if (DEBUG_CHEATS_ON) then 
		if (key == "u") then gPlayer.att = gPlayer.att + 1 end
		if (key == "i") then gPlayer.def = gPlayer.def + 1 end
	end
	
	if (snds) then 
		if (key == "1" or 
			key == "2" or 
			key == "3" or 
			key == "4" or 
			key == "5" or 
			key == "6" or 
			key == "7" or 
			key == "8" or 
			key == "9" ) then 
			local snd = snds[tonumber(key) or 0]
			if (snd) then snd:play() print("snd-test",snd.path) end
		end
	end
end

function love.keyreleased( key )
    gKeyPressed[key] = nil
end

-- ***** ***** ***** ***** ***** sound

function Sound_PlayBySrc (o,name,looptimeadd) 
	local snd = gSoundById[name]
	if (snd) then snd:Play(o) end
	if (looptimeadd) then o.snd_loop_nextt = gCurTime + looptimeadd end
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
	
	if (not gPause) then 
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
	end
	
	CamStep()
end

-- ***** ***** ***** ***** ***** love.draw

function love.draw()
	gCurTime = love.timer.getTime()
	if (gTitleScreen) then love.graphics.draw(img_screen_title, 0,0) return end
	
	gCurArea:Draw_Back()
	
	local camx = floor(gCamX)
	local camy = floor(gCamY)
	for o,_ in pairs(gCurArea.items) do o:Draw(camx,camy) end
	for o,_ in pairs(gCurArea.mobiles) do o:Draw(camx,camy) end
	gPlayer:Draw(gCamX,gCamY)
	
	gCurArea:Draw_Fore()
	
	gCurArea:DrawAfterEffect() -- img_dark
	
	
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

function randarr (arr) return (#arr > 0) and arr[random(#arr)] end -- random array element
function randirange (vmin,vmax) return min(vmax,vmin + random(vmax-vmin+1) - 1) end
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
