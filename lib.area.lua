
	
-- ***** ***** ***** ***** ***** cAreaBase
cAreaBase = CreateClass()

function cAreaBase:Init ()
	self.mobiles = {}
	self.items = {}
end

function cAreaBase:OnEnter () end
function cAreaBase:Update (dt) end
function cAreaBase:PositionIsValid	(x,y) return true end
function cAreaBase:IsWalkable		(tx,ty) return true end

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
		local i = tx - 2
		if (i >= 0) then
			local level = 1+floor(i/5)
			if (math.fmod(i,10) == 0) then cItemCave:New(self,tx,2,level) end
			if (math.fmod(i,10) == 5) then cItemCave:New(self,tx,8,level) end
			if (math.fmod(i,20) == 0) then cItemNest:New(self,tx,8) end
		end
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

function cAreaOverworld:MoveCamToPlayer (bForceReset)
	local vw = gScreenW
	local vh = gScreenH
	CamSetTarget(gPlayer.x-vw/2,0,bForceReset)
end

function cAreaOverworld:Update (dt)
	if (not gPlayer.dead) then self:MoveCamToPlayer() end
	if (gPlayer.x < (OVERWORLD_TX_SAND-2)*kTileSize) then gPlayer:EnvDamage(1,1,0) end
end

-- ***** ***** ***** ***** ***** cAreaDungeon
cAreaDungeon = CreateClass(cAreaBase)


function cAreaDungeon:Init (entrance,level)
	cAreaBase.Init(self)
	self.is_dungeon = true
	self.entrance = entrance
	self.level = level
end



function cAreaDungeon:OnEnter ()
	if (self.init_done) then return end
	-- generate dungeon on first enter
	self.init_done = true
	
	-- items
	self.exit = cItemCaveExit:New(self,0,0)
	
	-- floor
	self.floor = {}
	self:GenerateDungeonRooms()
end

function cAreaDungeon:Update (dt)
	if (not gPlayer.dead) then self:MoveCamToPlayer() end
end

function cAreaDungeon:MoveCamToPlayer (bForceReset)
	local vw = gScreenW
	local vh = gScreenH
	CamSetTarget(gPlayer.x-vw/2,gPlayer.y-vh/2,bForceReset)
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
		local tile = nil
		if (self.floor[tx..","..ty]) then tile = img_tile_cave_floor end
		if (tile) then love.graphics.draw(tile, e*tx-gCamX,e*ty-gCamY) end
	end
	end
end

-- ***** ***** ***** ***** ***** dungeon rooms


function cAreaDungeon:GenerateDungeonRooms()
	local emin = floor(self.level / 5)
	local emax = 1+ceil(self.level / 5)
	local e = DUNGEON_GRID_SIZE
	
	-- returns num_red,num_blue   randomized
	local function enum () local r = randirange(emin,emax) return r,max(0,randirange(emin-r,emax-r)) end
	
	
	self:MakeRoom(0*e,0*e,DUNGEON_ROOM_MAXR, 0,0,nil)
	local r,b = enum() 
	local tx,ty = 1,0
	self:MakeTunnel(0*e,0*e,tx*e,ty*e,randirange(DUNGEON_TUNNEL_MINW,DUNGEON_TUNNEL_MAXW))
	self:MakeRoom(tx*e,ty*e,DUNGEON_ROOM_MAXR, r,b,(random(2) == 1) and cItemGeneRed or cItemGeneBlue)
end

function cAreaDungeon:PositionIsValid (x,y) return self:IsWalkable(floor(x/kTileSize),floor(y/kTileSize)) end
function cAreaDungeon:IsWalkable (tx,ty) return self.floor[tx..","..ty] end
function cAreaDungeon:SetFloor (tx,ty) self.floor[tx..","..ty] = true end

-- returns tx,ty
function cAreaDungeon:GetRandomWalkablePos (tx0,ty0,r) 
	for i=1,100 do 
		local tx = floor(tx0-r+2*r*random())
		local ty = floor(ty0-r+2*r*random())
		if (self:IsWalkable(tx,ty)) then return tx,ty end
	end
end

-- line with thickness r
function cAreaDungeon:MakeTunnel (tx0,ty0,tx1,ty1,r)
	local dx = tx1-tx0
	local dy = ty1-ty0
	if (dx == 0 and dy == 0) then return end
	local step = 1/max(abs(dx),abs(dy))
	local bHorizontal = abs(dx) > abs(dy)
	for f = 0,1,step do
		local tx = tx0 + f*dx
		local ty = ty0 + f*dy
		if (bHorizontal) then 
			for a=-r,r do self:SetFloor(tx,ty+a) end
		else
			for a=-r,r do self:SetFloor(tx+a,ty) end
		end
	end
end

-- itemclass = cItemGeneRed or cItemGeneBlue
function cAreaDungeon:MakeRoom (tx0,ty0,r, mobs_red,mobs_blue,itemclass)
	-- floor
	for ty=ty0-r,ty0+r do
	for tx=tx0-r,tx0+r do
		if (dist2(tx,ty,tx0,ty0) <= r) then 
			self:SetFloor(tx,ty)
		end
	end
	end
	
	--~ print("make room of level",level)
	local level = self.level
	-- mobs and items
	for i=1,mobs_red or 0 do
		local tx,ty = self:GetRandomWalkablePos(tx0,ty0,r)
		if (tx) then cMobEnemy:New(self,img_mob_att, tx,ty, 2*ceil(level/2),1*level) end
	end
	for i=1,mobs_blue or 0 do
		local tx,ty = self:GetRandomWalkablePos(tx0,ty0,r)
		if (tx) then cMobEnemy:New(self,img_mob_def, tx,ty, 1*ceil(level/2),2*level) end
	end
	if (itemclass) then 
		local tx,ty = self:GetRandomWalkablePos(tx0,ty0,r)
		if (tx) then itemclass:New(self,tx,ty) end
	end
end

-- ***** ***** ***** ***** ***** rest
