

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

function cItemBase:Step (dt) end

function cItemBase:Draw (camx,camy) 
	local e = kTileSize
	local ox,oy = -kTileSize/2, -kTileSize/2
	local x,y = floor(self.x+ox-camx),floor(self.y+oy-camy)
	if (self.hover_h) then y = floor(y + GetHoverDY(2)*self.hover_h) end
	
	if (self.shadow) then love.graphics.draw(img_shadow, x,y) end
	love.graphics.draw(self.img, x,y)
end

-- ***** ***** ***** ***** ***** items
cItemNest = CreateClass(cItemBase)
cItemCave = CreateClass(cItemBase)
cItemGeneRed = CreateClass(cItemBase)
cItemGeneBlue = CreateClass(cItemBase)

function cItemNest:Init (...) cItemBase.Init(self,...) self.img = img_tile_nestegg end
function cItemCave:Init (...) cItemBase.Init(self,...) self.img = img_tile_cave end
function cItemGeneRed:Init (...) cItemBase.Init(self,...) self.img = img_genes_red self.hover_h = 4 self.shadow = true end
function cItemGeneBlue:Init (...) cItemBase.Init(self,...) self.img = img_genes_blue self.hover_h = 4 self.shadow = true end
