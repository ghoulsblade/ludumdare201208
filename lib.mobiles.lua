

-- ***** ***** ***** ***** ***** cMobBase
cMobBase = CreateClass()

function cMobBase:Init (area,img,tx,ty,att,def) 
	local e = kTileSize
	local ox,oy = kTileSize/2, kTileSize/2
	local x,y = e*tx+ox,e*ty+oy
	
	self.area = area
	if (area) then area.mobiles[self] = true end
	
	self.img = img
	self.att = att or 1
	self.def = def or 1
	self.x = x
	self.y = y
	self.start_x = x
	self.start_y = y
	self.vx = 0
	self.vy = 0
	self.next_attack = 0
	self.attack_interval = MOBILE_ATTACK_INTERVAL
	self.attack_anim_until = 0
	self.attack_anim_dur = MOBILE_ATTACK_ANIM_DUR
	self.img_face = (math.random() < 0.3) and img_part_face_oh or img_part_face_grr
	self.anim_random_addt = math.random() -- seconds
	self.walking = false
	self.breathe_dt = 3 + 2*math.random() -- seconds
end 

function cMobBase:DistToMob (mob) return self:DistToPos(mob.x,mob.y) end
function cMobBase:DistToPos (x,y) 
	local dx,dy = x - self.x , y - self.y
	return math.sqrt(dx*dx+dy*dy)
end

function cMobBase:WalkAwayFromMob (mob,speed,stopdist,dt) 
	local x,y = mob.x,mob.y
	if (x == self.x and y == self.y) then 
		x = x + math.random()*2-1
		y = y + math.random()*2-1
	end
	return self:WalkToPos_Aux(x,y,speed,stopdist,dt,-1) 
end

function cMobBase:WalkToMob (mob,speed,stopdist,dt) return self:WalkToPos(mob.x,mob.y,speed,stopdist,dt) end

function cMobBase:WalkToPos (x,y,speed,stopdist,dt) return self:WalkToPos_Aux(x,y,speed,stopdist,dt) end

function cMobBase:WalkToPos_Aux (x,y,speed,stopdist,dt,dirmod) 
	local ax,ay = 0,0
	local s = speed*dt
	self.walking = false
	
	local mind = 5
	if (x < self.x - mind) then self.left = true end
	if (x > self.x + mind) then self.left = false end

	local d = self:DistToPos(x,y)
	dirmod = dirmod or 1
	if ((dirmod < 0 and d < stopdist) or d > stopdist) then 
		ax = dirmod * (x - self.x) * s / d
		ay = dirmod * (y - self.y) * s / d
		self:SetNewPos(self.x + ax,self.y + ay)
		self.walking = (ax ~= 0) or (ay ~= 0)
		return true
	else
		return false
	end
end

function cMobBase:SetNewPos (nx,ny) 
	local area = self.area or gCurArea
	if (not area:PositionIsValid(nx,ny)) then 
			if (area:PositionIsValid(nx,self.y)) then ny = self.y
		elseif (area:PositionIsValid(self.x,ny)) then nx = self.x
		else nx = self.x ny = self.y end -- blocked
	end
	self.x = nx
	self.y = ny
end
	
function cMobBase:AddHitVel (dx,dy) 
	local d = math.sqrt(dx*dx+dy*dy)
	if (d <= 0) then return end
	self.vx = self.vx + VEL_HIT*dx/d
	self.vy = self.vy + VEL_HIT*dy/d
end

function cMobBase:VelStep (dt) 
	self:SetNewPos(self.x + dt*self.vx,self.y + dt*self.vy)
	self.vx = self.vx * VEL_DAMP
	self.vy = self.vy * VEL_DAMP
end

function cMobBase:Step (dt) 
	self:VelStep(dt)
end

function cMobBase:VectorToMob (mob) return mob.x-self.x,mob.y-self.y end

function cMobBase:Attack (mob) 
	if (self.dead) then return end
	if (self.next_attack > gCurTime) then return end
	
	snd_swing:play()
	self.next_attack = gCurTime + self.attack_interval
	self.attack_anim_until = gCurTime + self.attack_anim_dur
	if (mob) then 
		mob:AddHitVel(self:VectorToMob(mob))
		mob:TakeDamage(self.att,self)
	end
	-- TODO : sound
end

-- environment, e.g. water
function cMobBase:EnvDamage (dmg,dx,dy) 
	self:AddHitVel(dx,dy)
	self:TakeDamage(dmg,self)
end

function cMobBase:TakeDamage (dmg,attacker) 
	self.def = self.def - dmg
	if (self.def <= 0) then
		self:Die(self)
	else
		if (self.is_player) then
			snd_ouch:play()
		else
			snd_hit:play()
		end
	end
end

function cMobBase:NotifyDeath (attacker)  end

function cMobBase:Die (attacker) 
	self.dead = true -- die
	self:NotifyDeath(attacker)
	snd_death:play()
end

function cMobBase:AutoAttack () -- swing wildly and always, even if not in range, used by player when holding down key
	if (self.dead) then return end
	self:Attack(nil)
end

function cMobBase:Draw (camx,camy) 
	if (self.dead) then return end
	local ox,oy = -kTileSize/2, -kTileSize/2
	local x,y = floor(self.x+ox-camx),floor(self.y+oy-camy)
	love.graphics.draw(img_shadow,x,y)
	local t = gCurTime + self.anim_random_addt -- seconds
	local fdur = 0.1 -- frame duration, seconds
	
	if (self.walking) then 
		if (self.left) then
			love.graphics.draw(anim_frame(t,{img_part_legs_l_w1,img_part_legs_l_st,img_part_legs_l_w2,img_part_legs_l_st},fdur),x,y)
		else
			love.graphics.draw(anim_frame(t,{img_part_legs_r_w1,img_part_legs_r_st,img_part_legs_r_w2,img_part_legs_r_st},fdur),x,y)
		end
	else
		if (self.left) then
			love.graphics.draw(img_part_legs_l_st,x,y)
		else
			love.graphics.draw(img_part_legs_r_st,x,y)
		end
	end
	
	local breathe_y1 = floor(y + 1.5 * GetHoverDY(self.breathe_dt,t))
	local breathe_y  = floor(y + 3   * GetHoverDY(self.breathe_dt,t))
	local sword_ox = -5*8
	
	love.graphics.draw(self.img,x,breathe_y1)
	love.graphics.draw(self.img_face,x,breathe_y1)
	
	
	if (self.left) then
		love.graphics.draw(img_part_shield,x,breathe_y)
	else
		love.graphics.draw(img_part_shield_r,x,breathe_y)
	end
	
	local sword_r_offx = 80
	if (self.attack_anim_until > gCurTime) then 
		if (self.left) then
			love.graphics.draw(img_part_sword2   ,x+sword_ox,breathe_y)
		else
			love.graphics.draw(img_part_sword2_r ,x+sword_ox+sword_r_offx,breathe_y)
		end
	else
		if (self.left) then
			love.graphics.draw(img_part_sword ,x+sword_ox,breathe_y)
		else
			love.graphics.draw(img_part_sword_r,x+sword_ox+sword_r_offx,breathe_y)
		end
	end
	
	-- healtbar
	local ix,iy = x,y-kIconSize
	for i=1,self.att do 
		love.graphics.draw(img_icon_sword,ix,iy)
		ix = ix + kIconSize/2
	end
	for i=1,self.def do
		if (math.fmod(i-1,2) == 0) then
			love.graphics.draw((self.def > i) and img_icon_shield or img_icon_shield_half,ix,iy)
			ix = ix + kIconSize
		end
	end	
end

-- ***** ***** ***** ***** ***** cMobEnemy
cMobEnemy = CreateClass(cMobBase)
function cMobEnemy:Init (...) cMobBase.Init(self,...) self.is_enemy = true end

function cMobEnemy:Step (dt)
	self:VelStep(dt)
	if (self.dead) then return end
	self.walking = false
	if (gPlayer.dead) then return end
	local bCanStillWalk = true 
	
	local other,d = self.area:GetNearestEnemyToPos(self.x,self.y,self)
	if (other and d < ENEMY_SPREAD_DIST) then self:WalkAwayFromMob(other,SPEED_ENEMY,9999,dt) bCanStillWalk = false end
	
	if (bCanStillWalk) then
		local dp = self:DistToMob(gPlayer)
		if (dp < HUNTDIST_ENEMY_TARGET) then 
			self:WalkToMob(gPlayer,SPEED_ENEMY,STOPDIST_ENEMY_TARGET,dt)
		else
			self:WalkToPos(self.start_x,self.start_y,SPEED_ENEMY,STOPDIST_ENEMY_TARGET,dt)
		end
	end
	
	if (self:DistToMob(gPlayer) < ENEMY_ATTACK_RANGE) then self:Attack(gPlayer) end
end

-- ***** ***** ***** ***** ***** cMobPlayer
cMobPlayer = CreateClass(cMobBase)
function cMobPlayer:Init (...) 
	cMobBase.Init(self,...)
	self.attack_interval = PLAYER_ATTACK_INTERVAL
	self.is_player = true
end

function cMobPlayer:AutoAttack () -- swing wildly and always, even if not in range, used by player when holding down key
	if (self.dead) then return end
	local mob,d = gCurArea:GetNearestEnemyToPos(self.x,self.y,self)
	if (mob and d > PLAYER_ATTACK_RANGE) then mob = nil end
	self:Attack(mob)
end

function cMobPlayer:NotifyDeath (attacker) gRepawnTime = gCurTime + PLAYER_RESPAWN_DELAY  end

