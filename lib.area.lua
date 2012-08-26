
-- ***** ***** ***** ***** ***** cAreaBase
cAreaBase = CreateClass()

function cAreaBase:Init ()
	self.mobiles = {}
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
end

function cAreaOverworld:Draw (vw,vh)

	-- background
	local e = kTileSize
	local txmin = floor((gCamX)/kTileSize)
	local txmax = ceil((gCamX+vw)/kTileSize)
	local tymin = floor((gCamY)/kTileSize)
	local tymax = ceil((gCamY+vh)/kTileSize)
	for tx = txmin,txmax do 
	for ty = tymin,tymax do 
		local tile = img_tile_sand
		if (tx <  3) then tile = img_tile_water end
		if (tx == 3) then tile = img_tile_sand_water end
		love.graphics.draw(tile, e*tx-gCamX,e*ty-gCamY)
	end
	end
end

function cAreaOverworld:Update (dt)
	local vw = love.graphics.getWidth()
	local vh = love.graphics.getHeight()
	CamSetTarget(gPlayer.x-vw/2,0)
end

-- ***** ***** ***** ***** ***** cAreaDungeon
cAreaDungeon = CreateClass(cAreaBase)


function cAreaDungeon:Init ()
	cAreaBase.Init(self)
end

function cAreaDungeon:OnEnter ()
	if (self.walls) then return end
	-- generate dungeon on first enter
	
	-- mobs 
	cMobEnemy:New(self,img_mob_att, 4,4, 2,1)
	cMobEnemy:New(self,img_mob_def, 6,4, 1,2)
	cMobEnemy:New(self,img_mob_def, 7,1, 1,2)
	
	-- walls
	self.walls = {}
	for ty = 0,vh/kTileSize do 
	for tx = 0,vw/kTileSize do 
		if (math.random(10) == 1) then self.walls[tx..","..ty] = true end 
	end
	end
end

function cAreaDungeon:Update (dt)
	local vw = love.graphics.getWidth()
	local vh = love.graphics.getHeight()
	CamSetTarget(gPlayer.x-vw/2,gPlayer.y-vh/2)
end

function cAreaDungeon:Draw (vw,vh)
	-- background
	local e = kTileSize
	for ty = 0,vh/kTileSize do 
	for tx = 0,vw/kTileSize do 
		local tile = img_tile_cave_floor
		if (self.walls[tx..","..ty]) then tile = img_tile_cave_wall end
		love.graphics.draw(tile, e*tx-gCamX,e*ty-gCamY)
	end
	end
end

-- ***** ***** ***** ***** ***** rest
