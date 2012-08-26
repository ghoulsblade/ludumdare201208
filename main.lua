-- ludumdare 2012-08 ghoulsblade generogue

love.filesystem.load("lib.oop.lua")()

kTileSize = 64
SPEED_PLAYER = 200 -- pixels per second
SPEED_ENEMY = SPEED_PLAYER*0.5 -- pixels per second
STOPDIST_PLAYER_MOUSE = 20 -- pixels
STOPDIST_ENEMY_TARGET = 20 -- pixels
ENEMY_SPREAD_DIST = kTileSize*1.0 -- pixels, enemies try to keep distance from each other
DT_MAX = 0.1 -- avoid jumps when lag
ENEMY_ATTACK_RANGE = kTileSize*1.0

gKeyPressed = {}
gTitleScreen = true
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
	
	img_part_face_grr	= myimg("data/part-face-grr.png"	)
	img_part_face_oh	= myimg("data/part-face-oh.png"		)
	img_part_legs_st	= myimg("data/part-legs-st.png"		)
	img_part_legs_w1	= myimg("data/part-legs-w1.png"		)
	img_part_legs_w2	= myimg("data/part-legs-w2.png"		)
	img_part_shield		= myimg("data/part-shield.png"		)
	img_part_sword2		= myimg("data/part-sword2.png"		)
	img_part_sword		= myimg("data/part-sword.png"		)
	
	
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
	local ox,oy = kTileSize/2, kTileSize/2
	local tx,ty=4,4 cMobEnemy:New(img_mob_att, e*tx+ox,e*ty+oy)
	local tx,ty=6,4 cMobEnemy:New(img_mob_def, e*tx+ox,e*ty+oy)
	local tx,ty=7,1 cMobEnemy:New(img_mob_def, e*tx+ox,e*ty+oy)
	local tx,ty=4,6 gPlayer = cMobPlayer:New(img_mob_player, e*tx+ox,e*ty+oy)
	
end

function love.mousereleased(x,y,btn)
	if (btn == "l") then gMouseDownL = false end
	--~ print("mousereleased",x,y,btn)
end
function love.mousepressed(x,y,btn)
	if (btn == "l") then gMouseDownL = true end
	
	if (gTitleScreen) then return StartGame() end
	--~ print("mousepressed",x,y,btn)
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
	if (dt > DT_MAX) then dt = DT_MAX end
	local t = love.timer.getTime()
	gSecondsSinceLastFrame = gCurTime and min(0.1,t-gCurTime) or 0
	gCurTime = t
	if (gTitleScreen) then return end
	
	
	--[[
	local ax,ay = 0,0
	if (gKeyPressed["a"] or gKeyPressed["left"]) then ax = -s end
	if (gKeyPressed["d"] or gKeyPressed["right"]) then ax = s end
	if (gKeyPressed["w"] or gKeyPressed["up"]) then ay = -s end
	if (gKeyPressed["s"] or gKeyPressed["down"]) then ay = s end
	]]--
	
	local x, y = love.mouse.getPosition()
	gPlayer:WalkToPos(x,y,SPEED_PLAYER,STOPDIST_PLAYER_MOUSE,dt)
	
	gPlayer.hitting = gKeyPressed[" "] or  gMouseDownL
	
	for mob,_ in pairs(gMobiles) do mob:Step(dt) end
	
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

-- dur in seconds
function GetHoverDY (dur,t) return math.sin((t or gCurTime)/dur*2*math.pi) end



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
	
	local hover_dy = GetHoverDY(2)
	
	-- spawn/nest
	local e = kTileSize
	local tx,ty=5,8 love.graphics.draw(img_tile_nestegg, e*tx,e*ty)
	local tx,ty=6,5 love.graphics.draw(img_shadow, e*tx,e*ty) love.graphics.draw(img_genes_red, e*tx,floor(e*ty + 4*hover_dy))
	local tx,ty=7,6 love.graphics.draw(img_shadow, e*tx,e*ty) love.graphics.draw(img_genes_blue, e*tx,floor(e*ty + 4*hover_dy))
	
	local tx,ty=7,2 love.graphics.draw(img_tile_cave, e*tx,e*ty)
	
	for mob,_ in pairs(gMobiles) do mob:Draw() end
	
end


-- ***** ***** ***** ***** ***** utils


-- fdur : frame duration, seconds
function anim_frame (t,arr,fdur) 
	local fnum = #arr
	return arr[1+math.fmod(floor(t/fdur),fnum)]
end

function GetNearestEnemyToPos (x,y,skip)
	local found_dist
	local found_o
	for o,_ in pairs(gMobiles) do 
		if (o ~= skip and o.is_enemy) then 
			local cur_dist = o:DistToPos(x,y)
			if ((not found_dist) or cur_dist < found_dist) then found_dist = cur_dist found_o = o end
		end
	end
	return found_o,found_dist
end

-- ***** ***** ***** ***** ***** cMobBase
cMobBase = CreateClass()

function cMobBase:Init (img,x,y) 
	self.img = img
	self.x = x
	self.y = y
	gMobiles[self] = true
	self.img_face = (math.random() < 0.3) and img_part_face_oh or img_part_face_grr
	self.anim_random_addt = math.random() -- seconds
	self.hitting = false
	self.walking = false
	self.breathe_dt = 3 + 2*math.random() -- seconds
end 

function cMobBase:DistToMob (mob) return self:DistToPos(mob.x,mob.y) end
function cMobBase:DistToPos (x,y) 
	local dx,dy = x - self.x , y - self.y
	return math.sqrt(dx*dx+dy*dy)
end

function cMobBase:WalkAwayFromMob (mob,speed,stopdist,dt) self:WalkToPos_Aux(mob.x,mob.y,speed,stopdist,dt,-1) end

function cMobBase:WalkToMob (mob,speed,stopdist,dt) self:WalkToPos(mob.x,mob.y,speed,stopdist,dt) end

function cMobBase:WalkToPos (x,y,speed,stopdist,dt) self:WalkToPos_Aux(x,y,speed,stopdist,dt) end

function cMobBase:WalkToPos_Aux (x,y,speed,stopdist,dt,dirmod) 
	local ax,ay = 0,0
	local s = speed*dt

	local d = self:DistToPos(x,y)
	dirmod = dirmod or 1
	if ((dirmod < 0 and d < stopdist) or d > stopdist) then 
		ax = dirmod * (x - self.x) * s / d
		ay = dirmod * (y - self.y) * s / d
	end
	self.x = self.x + ax
	self.y = self.y + ay
	self.walking = (ax ~= 0) or (ay ~= 0)
end
	
function cMobBase:Step (dt) 
end

function cMobBase:Draw () 
	local ox,oy = -kTileSize/2, -kTileSize/2
	local x,y = self.x+ox,self.y+oy
	love.graphics.draw(img_shadow,x,y)
	local t = gCurTime + self.anim_random_addt -- seconds
	local fdur = 0.1 -- frame duration, seconds
	
	if (self.walking) then 
		love.graphics.draw(anim_frame(t,{img_part_legs_w1,img_part_legs_st,img_part_legs_w2,img_part_legs_st},fdur),x,y)
	else
		love.graphics.draw(img_part_legs_st,x,y)
	end
	
	local breathe_y1 = floor(y + 1.5 * GetHoverDY(self.breathe_dt,t))
	local breathe_y  = floor(y + 3   * GetHoverDY(self.breathe_dt,t))
	local sword_ox = -5*8
	
	love.graphics.draw(self.img,x,breathe_y1)
	love.graphics.draw(self.img_face,x,breathe_y1)
	
	
	love.graphics.draw(img_part_shield,x,breathe_y)
	if (self.hitting) then 
		love.graphics.draw(anim_frame(t,{img_part_sword,img_part_sword2},fdur),x+sword_ox,breathe_y)
	else
		love.graphics.draw(img_part_sword,x+sword_ox,breathe_y)
	end
end

-- ***** ***** ***** ***** ***** cMobEnemy
cMobEnemy = CreateClass(cMobBase)
function cMobEnemy:Init (...) cMobBase.Init(self,...) self.is_enemy = true end

function cMobEnemy:Step (dt)
	local bWalkToPlayer = true 
	
	local other,d = GetNearestEnemyToPos(self.x,self.y,self)
	if (d < ENEMY_SPREAD_DIST) then self:WalkAwayFromMob(other,SPEED_ENEMY,9999,dt) bWalkToPlayer = false end
	
	if (bWalkToPlayer) then self:WalkToMob(gPlayer,SPEED_ENEMY,STOPDIST_ENEMY_TARGET,dt) end
	
	local bAttack = self:DistToMob(gPlayer) < ENEMY_ATTACK_RANGE
	self.hitting = bAttack
end

-- ***** ***** ***** ***** ***** cMobPlayer
cMobPlayer = CreateClass(cMobBase)
function cMobPlayer:Init (...) cMobBase.Init(self,...) end

-- ***** ***** ***** ***** ***** rest
