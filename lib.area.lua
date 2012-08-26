
	
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


-- returns num_red,num_blue
function cAreaDungeon:RandomEnemyNum ()
	local emin = floor(self.level / 5)
	local emax = 2+ceil(self.level / 4)
	local r = randirange(emin,emax) 
	local b = max(0,randirange(emin-r,emax-r))
	return r,b
end

function cAreaDungeon:GenerateDungeonRooms()
	self.room_list = {}
	self:MakeRoom(0,0,DUNGEON_ROOM_MAXR, 0,0,nil)
	
	for i=1,4 do self:AppendRandomRoom((random(10) == 1) and cItemGeneBlue) end
	self:AppendRandomRoom(cItemGeneRed) -- at the end, or at least somewhere deeeep in ;)
end

function cAreaDungeon:AppendRandomRoom(itemclass)
	if (#self.room_list <= 0) then return end
	for i=1,10 do -- 10 tries
		-- pick random start room
		local startroom = self.room_list[random(#self.room_list)]
		if (not startroom) then return end
		local tx0,ty0 = unpack(startroom)
	
		-- pick random direction
		local dx,dy = 0,0
		local e = DUNGEON_GRID_SIZE
		if (random(2) == 1) then 
			dx = (random(2) == 1) and e or -e 
		else
			dy = (random(2) == 1) and e or -e 
		end
		--~ local dx = randirange(-1,1)*e
		--~ local dy = randirange(-1,1)*e
		local tx,ty = tx0+dx,ty0+dy
		
		-- check if no room there already
		if (not self:IsWalkable(tx,ty)) then 
			local r,b = self:RandomEnemyNum() 
			self:MakeTunnel(tx0,ty0,tx,ty,randirange(DUNGEON_TUNNEL_MINW,DUNGEON_TUNNEL_MAXW))
			self:MakeRoom(tx,ty,randirange(DUNGEON_ROOM_MINR,DUNGEON_ROOM_MAXR), r,b,itemclass)
			return
		end
	end
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
function cAreaDungeon:MakeTunnel (tx0,ty0,tx1,ty1,w)
	--~ print("make tunnel",tx0,ty0,tx1,ty1,w)
	local dx = tx1-tx0
	local dy = ty1-ty0
	if (dx == 0 and dy == 0) then return end
	local step = 1/max(abs(dx),abs(dy))
	if (abs(dx) > abs(dy)) then  -- bHorizontal
		for tx = min(tx0,tx1),max(tx0,tx1) do
			local f = (tx - tx0) / (tx1 - tx0)
			local ty = floor(ty0 + f*dy)
			for a=1,w do self:SetFloor(tx,ty+a-floor(w/2)) end
		end
	else
		for ty = min(ty0,ty1),max(ty0,ty1) do
			local f = (ty - ty0) / (ty1 - ty0)
			local tx = floor(tx0 + f*dx)
			for a=1,w do self:SetFloor(tx+a-floor(w/2),ty) end
		end
	end
end

-- itemclass = cItemGeneRed or cItemGeneBlue
function cAreaDungeon:MakeRoom (tx0,ty0,r, mobs_red,mobs_blue,itemclass)
	--~ print("make room",tx0,ty0,r)
	table.insert(self.room_list,{tx0,ty0})
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
