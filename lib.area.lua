
	
-- ***** ***** ***** ***** ***** cAreaBase
cAreaBase = CreateClass()

function cAreaBase:Init ()
	self.mobiles = {}
	self.items = {}
	self.deco = {}
end

function cAreaBase:AddDeco (img,x,y) table.insert(self.deco,{x,y,img}) end

function cAreaBase:DrawDeco () 
	-- deco
	local camx = floor(gCamX)
	local camy = floor(gCamY)
	local xmin,xmax,ymin,ymax = self:GetImgDrawArea()
	for k,v in ipairs(self.deco) do 
		local x,y,img = unpack(v)
		if (x >= xmin and x <= xmax and y >= ymin and y <= ymax) then love.graphics.draw(img,x-camx,y-camy) end
	end
end



function cAreaBase:Draw_Back () end
function cAreaBase:Draw_Fore () end
function cAreaBase:DrawAfterEffect () end  -- img_dark
function cAreaBase:OnEnter () end
function cAreaBase:Update (dt) end
function cAreaBase:PositionIsValid	(x,y) return true end
function cAreaBase:IsWalkable		(tx,ty) return true end

function cAreaBase:GetImgDrawArea ()
	local border = 128
	local xmin = gCamX - border
	local xmax = gCamX + border +gScreenW
	local ymin = gCamY - border
	local ymax = gCamY + border +gScreenH
	return xmin,xmax,ymin,ymax
end
function cAreaBase:GetScreenArea ()
	local txmin = floor((gCamX)/kTileSize)
	local txmax = ceil( (gCamX+gScreenW)/kTileSize)
	local tymin = floor((gCamY)/kTileSize)
	local tymax = ceil( (gCamY+gScreenH)/kTileSize)
	return txmin,txmax,tymin,tymax
end

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
	for tx=0,OVERWORLD_TX_END do
		local i = tx
		if (i >= 0) then
			local level = floor(i/5)
			if (math.fmod(i,10) == 0 and i > 0) then cItemCave:New(self,tx,2,level) end
			if (math.fmod(i,10) == 5) then cItemCave:New(self,tx,8,level) end
			if (math.fmod(i,20) == 0) then cItemNest:New(self,tx,8) end
		end
	end
	
	-- deco
	local e = kTileSize
	for i=1,OVERWORLD_NUM_DECO do 
		local x = randirange(0,e*OVERWORLD_TX_END + 25*e)
		local y = randirange(0,gScreenH)
		local img
			if (x >= e*OVERWORLD_TX_DJUNGLE	) then	img = randarr(imgarr_deco_djungle) 
		elseif (x >= e*OVERWORLD_TX_GRASS	) then	img = randarr(imgarr_deco_grass) 
		else										img = randarr(imgarr_deco_sand) 
		end
		self:AddDeco(img,x,y)
	end
end


function cAreaOverworld:Draw_Back ()
	-- background
	local e = kTileSize
	local camx = floor(gCamX)
	local camy = floor(gCamY)
	local txmin,txmax,tymin,tymax = self:GetScreenArea()
	for tx = txmin,txmax do 
		local tile = img_tile_water
		if (tx >= OVERWORLD_TX_SAND) then tile = img_tile_sand end
		if (tx >= OVERWORLD_TX_GRASS) then tile = img_tile_grass end
		if (tx >= OVERWORLD_TX_DJUNGLE) then tile = img_tile_djungle end
		for ty = tymin,tymax do 
			love.graphics.draw(tile, e*tx-camx,e*ty-camy)
		end
	end
	
	-- deco
	self:DrawDeco()
	
	-- rolling waves
	local tx_water = OVERWORLD_TX_SAND
	if (tx_water > txmin - 3) then 
		local dur = 3
		local ay = 5*math.sin((t or gCurTime)/dur*2*math.pi)
		local dur = 4
		local t = gCurTime/dur - floor(gCurTime/dur)
		local ax = t * kTileSize
		for tx = txmin-1,tx_water do 
			local tile = img_tile_water
			if (tx == tx_water) then 
				tile = img_tile_sand_water 
				love.graphics.setColor(255,255,255,255-255*t)
			end
			for ty = tymin-1,tymax+1 do 
				love.graphics.draw(tile, e*tx-camx+ax,e*ty-camy+ay)
			end
			if (tx == tx_water) then 
				love.graphics.setColor(255,255,255,255)
			end
		end
	end
end

function cAreaOverworld:MoveCamToPlayer (bForceReset)
	CamSetTarget(gPlayer.x-gScreenW/2,0,bForceReset)
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
	
	self.tile_floor		= img_tile_cave_floor
	self.tile_wall		= img_tile_cave_wall
	self.img_border_h	= img_cave_border_h
	self.img_border_v	= img_cave_border_v
	
	self.txmin = 0
	self.txmax = 0
	self.tymin = 0
	self.tymax = 0
	self.tiles_back = {}
	self.tiles_fore = {}
	self.img_back = {}
	self.img_fore = {}
	self.walkable = {}
end

function cAreaDungeon:AddImgBack (img,x,y) table.insert(self.img_back,{x,y,img}) end
function cAreaDungeon:AddImgFore (img,x,y) table.insert(self.img_fore,{x,y,img}) end

function cAreaDungeon:AddBorderBack (img,x,y) self:AddImgBack(img,x-32,y-32) end
function cAreaDungeon:AddBorderFore (img,x,y) self:AddImgFore(img,x-32,y-32) end

function cAreaDungeon:OnEnter ()
	if (self.init_done) then return end
	-- generate dungeon on first enter
	self.init_done = true
	self.exit = cItemCaveExit:New(self,0,0)
	self:GenerateDungeonRooms()
end

function cAreaDungeon:Update (dt)
	if (not gPlayer.dead) then self:MoveCamToPlayer() end
end

function cAreaDungeon:MoveCamToPlayer (bForceReset)
	CamSetTarget(gPlayer.x-gScreenW/2,gPlayer.y-gScreenH/2,bForceReset)
end

function cAreaDungeon:ResetThemeColor ()
	love.graphics.setColor(255,255,255,255)
end
function cAreaDungeon:SetThemeColor ()
	if (self.theme_col) then 
		local r,g,b = unpack(self.theme_col)
		love.graphics.setColor(r,g,b,255)
	end
end

function cAreaDungeon:Draw_Back ()
	self:SetThemeColor()
	
	-- background
	local e = kTileSize
	local camx = floor(gCamX)
	local camy = floor(gCamY)
	local txmin,txmax,tymin,tymax = self:GetScreenArea()
	for tx = txmin,txmax do 
	for ty = tymin,tymax do 
		local tile = self:GetTile_Back(tx,ty)
		if (tile) then love.graphics.draw(tile, e*tx-camx,e*ty-camy) end
	end
	end
	
	-- deco
	self:DrawDeco()
	
	-- borders
	local xmin,xmax,ymin,ymax = self:GetImgDrawArea()
	for k,v in ipairs(self.img_back) do 
		local x,y,img = unpack(v)
		if (x >= xmin and x <= xmax and y >= ymin and y <= ymax) then love.graphics.draw(img,x-camx,y-camy) end
	end
	
	self:ResetThemeColor()
end

function cAreaDungeon:Draw_Fore ()
	self:SetThemeColor()
	
	-- foreground
	local e = kTileSize
	local camx = floor(gCamX)
	local camy = floor(gCamY)
	local txmin,txmax,tymin,tymax = self:GetScreenArea()
	for tx = txmin,txmax do 
	for ty = tymin,tymax do 
		local tile = self:GetTile_Fore(tx,ty)
		if (tile) then love.graphics.draw(tile, e*tx-camx,e*ty-camy) end
	end
	end
	local xmin,xmax,ymin,ymax = self:GetImgDrawArea()
	for k,v in ipairs(self.img_fore) do 
		local x,y,img = unpack(v)
		if (x >= xmin and x <= xmax and y >= ymin and y <= ymax) then love.graphics.draw(img,x-camx,y-camy) end
	end
	
	self:ResetThemeColor()
end

function cAreaDungeon:DrawAfterEffect () 
	love.graphics.draw(img_dark,0,0, 0, gScreenW/32, gScreenH/32)
end  -- img_dark

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
	
	local num_rooms = 1+self.level
	
	-- make a bunch of rooms
	for i=1,num_rooms-1 do self:AppendRandomRoom((random(10) == 1) and cItemGeneBlue) end
	-- make final room with red gene
	self:AppendRandomRoom(cItemGeneRed) -- at the end, or at least somewhere deeeep in ;)
	
	-- generate tiles, walls etc
	--~ print("gen-tile-bounds",self.txmin,self.txmax,self.tymin,self.tymax)
	local e = kTileSize
	for tx = self.txmin,self.txmax do
	for ty = self.tymin,self.tymax do
		if (self:IsWalkable(tx,ty)) then
			if (not self:IsWalkable(tx,ty+1)) then
				self:SetTile_Fore(tx,ty+1,img_tile_black)
				self:SetTile_Fore(tx,ty+2,img_tile_black)
				self:AddBorderFore(self.img_border_h,(tx)*e,(ty+1)*e)
			end
			if (not self:IsWalkable(tx,ty-1)) then
				self:SetTile_Back(tx,ty-1,self.tile_wall)
				self:SetTile_Back(tx,ty-2,self.tile_wall)
				self:AddBorderBack(self.img_border_h,(tx)*e,(ty-2)*e)
			end
		end
	end
	end
	
	-- generate deco 
	
	-- deco
	local e = kTileSize
	local numdeco_target = min(DUNGEON_NUM_DECO_MAX,num_rooms*DUNGEON_NUM_DECO_PER_ROOM)
	local xmin,xmax = self.txmin*e,self.txmax*e
	local ymin,ymax = self.tymin*e,self.tymax*e
	
	local numdeco_real = 0
	for i=1,numdeco_target do 
		for i=1,10 do -- 10 tries to find valid pos
			local x = randirange(xmin,xmax)
			local y = randirange(ymin,ymax)
			if (self:PositionIsValid(x,y)) then 
				self:AddDeco(randarr(imgarr_deco_cave),x,y)
				numdeco_real = numdeco_real + 1
				break
			end
		end
	end
	print("cave num_rooms=",num_rooms,"deco=",numdeco_real.."/"..numdeco_target)
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
function cAreaDungeon:IsWalkable (tx,ty) return self.walkable[tx..","..ty] end
function cAreaDungeon:GetTile_Back (tx,ty) return self.tiles_back[tx..","..ty] end -- returns tile
function cAreaDungeon:SetTile_Back (tx,ty,tile) self.tiles_back[tx..","..ty] = tile end
function cAreaDungeon:GetTile_Fore (tx,ty) return self.tiles_fore[tx..","..ty] end -- returns tile
function cAreaDungeon:SetTile_Fore (tx,ty,tile) self.tiles_fore[tx..","..ty] = tile end
function cAreaDungeon:SetFloor (tx,ty) 
	self.walkable[tx..","..ty] = true 
	self:SetTile_Back(tx,ty,self.tile_floor)
	self.txmin = min(self.txmin,tx)
	self.txmax = max(self.txmax,tx)
	self.tymin = min(self.tymin,ty)
	self.tymax = max(self.tymax,ty)
end

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
