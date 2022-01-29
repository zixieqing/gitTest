--[[
敌方主角建模
--]]
local PlayerObject = __Require('battle.object.PlayerObject')
local EnemyPlayerObject = class('EnemyPlayerObject', PlayerObject)

------------ import ------------
------------ import ------------

--[[
@override
constructor
--]]
function EnemyPlayerObject:ctor( ... )
	PlayerObject.ctor(self, ...)
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化外貌
--]]
function EnemyPlayerObject:initView()
	-- 敌方主角没有view
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------

---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- update begin --
---------------------------------------------------
--[[
@override
主循环
--]]
function EnemyPlayerObject:update(dt)
	if self:isPause() then return end

	-- 自动回能量
	self.countdowns.energy = math.max(0, self.countdowns.energy - dt)
	if 0 >= self.countdowns.energy then
		self.countdowns.energy = 1
		self:addEnergy(self:getEnergyRecoverRatePerS())
	end

	-- 刷新技能触发器
	self.castDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)

	------------ skill effect ------------
	for i = #self.halos.idx, 1, -1 do
		self.halos.idx[i]:OnBuffUpdateEnter(dt)
	end
	for i = #self.buffs.idx, 1, -1 do
		self.buffs.idx[i]:OnBuffUpdateEnter(dt)
	end
	------------ skill effect ------------
end
---------------------------------------------------
-- update end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
@override
刷新能量条
@params all bool(nil) true时更新最大能量
--]]
function EnemyPlayerObject:updateEnergyBar(all)

end
---------------------------------------------------
-- view control end --
---------------------------------------------------

return EnemyPlayerObject
