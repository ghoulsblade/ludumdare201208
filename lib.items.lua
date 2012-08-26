

-- ***** ***** ***** ***** ***** cItemBase
cItemBase = CreateClass()

function cItemBase:Init (area,tx,ty) 
	local e = kTileSize
	local ox,oy = kTileSize/2, kTileSize/2
	local x,y = e*tx+ox,e*ty+oy

	self.area = area
	if (area) then area.items[self] = true end
	
	self.img = img
	self.x = x
	self.y = y
	self.shadow = false
	self.hover_h = false
end

function cItemBase:OnTouch () end
function cItemBase:Step (dt) 
	if (gPlayer.dead) then return end
	if (gPlayer:DistToPos(self.x,self.y) < ITEM_TOUCH_DIST) then self:OnTouch() else self.touched = false end
end

function cItemBase:Draw (camx,camy) 
	local e = kTileSize
	local ox,oy = -kTileSize/2, -kTileSize/2
	local x,y = floor(self.x+ox-camx),floor(self.y+oy-camy)
	
	if (self.shadow) then love.graphics.draw(img_shadow, x,y) end
	if (self.hover_h) then y = floor(y + GetHoverDY(2)*self.hover_h) end
	love.graphics.draw(self.img, x,y)
end

-- ***** ***** ***** ***** ***** items
cItemNest = CreateClass(cItemBase)
cItemCave = CreateClass(cItemBase)
cItemCaveExit = CreateClass(cItemBase)
cItemGeneRed = CreateClass(cItemBase)
cItemGeneBlue = CreateClass(cItemBase)

-- img_tile_nest img_tile_nestegg
function cItemNest:Init (...) cItemBase.Init(self,...) self.img = img_tile_nest end
function cItemCave:Init (...)
	cItemBase.Init(self,...)
	self.img = img_tile_cave
	
	self.dungeon = cAreaDungeon:New()
	self.dungeon.entrance = self
end
function cItemCaveExit:Init (...) cItemBase.Init(self,...) self.img = img_tile_cave_exit end
function cItemGeneRed:Init (...) cItemBase.Init(self,...) self.img = img_genes_red self.hover_h = 4 self.shadow = true end
function cItemGeneBlue:Init (...) cItemBase.Init(self,...) self.img = img_genes_blue self.hover_h = 4 self.shadow = true end

function cItemNest:OnTouch () self.img = img_tile_nestegg end

function cItemCaveExit:OnTouch ()
	if (self.touched) then return end -- initial touch-block
	ChangeToArea(gAreaOverworld)
	self.area.entrance.touched = true
	gPlayer.x = self.area.entrance.x
	gPlayer.y = self.area.entrance.y
	gAreaOverworld:MoveCamToPlayer(true)
end

function cItemCave:OnTouch ()
	if (self.touched) then return end -- initial touch-block
	ChangeToArea(self.dungeon)
	self.dungeon.exit.touched = true
	gPlayer.x = 0
	gPlayer.y = 0
	self.dungeon:MoveCamToPlayer(true)
end

