
	
-- ***** ***** ***** ***** ***** cAreaBase
cAreaBase = CreateClass()

function cAreaBase:Init ()
	self.mobiles = {}
	self.items = {}
end

function cAreaBase:OnEnter () end
function cAreaBase:Update (dt) end

function cAreaBase:GetNearestEnemyToPos (x,y,skip)
	local found_dist
	local found_o
	for o,_ in pairs(self.mobiles) do 
		if (o ~= skip and o.is_enemy and (not o.dead)) then 
			local cur_dist = o:DistToPos(x,y)
			if ((not found_dist) or cur_dist < found_dist) then found_dist = cur_dist found_o = o end
		end
	end
	return found_o,found_dist
end

-- ***** ***** ***** ***** ***** cAreaOverworld
cAreaOverworld = CreateClass(cAreaBase)

function cAreaOverworld:Init ()
	cAreaBase.Init(self)
	
	-- generate a "few"
	for tx=1,100 do
		if (math.fmod(tx-2,10) == 0) then cItemCave:New(self,tx,2) end
		if (math.fmod(tx-2,10) == 5) then cItemCave:New(self,tx,8) end
		if (math.fmod(tx-2,20) == 0) then cItemNest:New(self,tx,8) end
	end
end


function cAreaOverworld:Draw ()
	local vw = gScreenW
	local vh = gScreenH
	-- background
	local e = kTileSize
	local txmin = floor((gCamX)/kTileSize)
	local txmax = ceil( (gCamX+vw)/kTileSize)
	local tymin = floor((gCamY)/kTileSize)
	local tymax = ceil( (gCamY+vh)/kTileSize)
	for tx = txmin,txmax do 
		local tile = img_tile_water
		if (tx == OVERWORLD_TX_SAND) then tile = img_tile_sand_water end
		if (tx  > OVERWORLD_TX_SAND) then tile = img_tile_sand end
		if (tx  > OVERWORLD_TX_GRASS) then tile = img_tile_grass end
		if (tx  > OVERWORLD_TX_DJUNGLE) then tile = img_tile_djungle end
		for ty = tymin,tymax do 
			love.graphics.draw(tile, e*tx-gCamX,e*ty-gCamY)
		end
	end
end

function cAreaOverworld:Update (dt)
	local vw = gScreenW
	local vh = gScreenH
	if (not gPlayer.dead) then CamSetTarget(gPlayer.x-vw/2,0) end
	if (gPlayer.x < (OVERWORLD_TX_SAND-2)*kTileSize) then gPlayer:EnvDamage(1,1,0) end
end

-- ***** ***** ***** ***** ***** cAreaDungeon
cAreaDungeon = CreateClass(cAreaBase)


function cAreaDungeon:Init ()
	cAreaBase.Init(self)
	self.is_dungeon = true
end

function cAreaDungeon:OnEnter ()
	gPlayer.x = 0
	gPlayer.y = 0
	local vw = gScreenW
	local vh = gScreenH
	CamSetTarget(gPlayer.x-vw/2,gPlayer.y-vh/2,true)

	if (self.init_done) then return end
	-- generate dungeon on first enter
	self.init_done = true
	
	-- mobs 
	cMobEnemy:New(self,img_mob_att, 4,4, 2,1)
	cMobEnemy:New(self,img_mob_def, 6,4, 1,2)
	cMobEnemy:New(self,img_mob_def, 7,1, 1,2)
	
	-- items
	self.exit = cItemCaveExit:New(self,0,0)
	cItemGeneRed:New(self,6,5)
	cItemGeneBlue:New(self,7,6)
	
	-- walls
	self.walls = {}
	local vw = gScreenW
	local vh = gScreenH
	for ty = 0,vh/kTileSize do 
	for tx = 0,vw/kTileSize do 
		if (math.random(10) == 1) then self.walls[tx..","..ty] = true end 
	end
	end
end

function cAreaDungeon:Update (dt)
	local vw = gScreenW
	local vh = gScreenH
	
	if (not gPlayer.dead) then CamSetTarget(gPlayer.x-vw/2,gPlayer.y-vh/2) end
end

function cAreaDungeon:Draw ()
	local vw = gScreenW
	local vh = gScreenH
	-- background
	local e = kTileSize
	local txmin = floor((gCamX)/kTileSize)
	local txmax = ceil( (gCamX+vw)/kTileSize)
	local tymin = floor((gCamY)/kTileSize)
	local tymax = ceil( (gCamY+vh)/kTileSize)
	for tx = txmin,txmax do 
	for ty = tymin,tymax do 
		local tile = img_tile_cave_floor
		if (self.walls[tx..","..ty]) then tile = img_tile_cave_wall end
		love.graphics.draw(tile, e*tx-gCamX,e*ty-gCamY)
	end
	end
end

-- ***** ***** ***** ***** ***** rest
