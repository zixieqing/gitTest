--[[
主角物体的基类
--]]
local BaseObjectModel = __Require('battle.object.logicModel.objectModel.BaseObjectModel')
local EnemyPlayerObjectModel = class('EnemyPlayerObjectModel', BaseObjectModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function EnemyPlayerObjectModel:ctor( ... )
	BaseObjectModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化展示层模型
--]]
function EnemyPlayerObjectModel:InitViewModel()
	-- 敌方主角没有渲染内容
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
刷新一些计时器
--]]
function EnemyPlayerObjectModel:UpdateCountdown(dt)
	-- 刷新计时器
	for k,v in pairs(self.countdowns) do
		self.countdowns[k] = math.max(v - dt, 0)
	end

	------------ 检测计时器带来的变化 ------------
	if 0 >= self.countdowns.energy then
		-- 能量计时器 
		self.countdowns.energy = 1
		self:AddEnergy(self:GetEnergyRecoverRatePerS())
	end
	------------ 检测计时器带来的变化 ------------
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- energy logic begin --
---------------------------------------------------
--[[
@override
增加能量
@params delta number 变化的能量
--]]
function EnemyPlayerObjectModel:AddEnergy(delta)
	BaseObjectModel.AddEnergy(self, delta)
end
--[[
@override
获取能量秒回值
--]]
function EnemyPlayerObjectModel:GetEnergyRecoverRatePerS()
	return PLAYER_ENERGY_PER_S + self:GetEnergyRecoverRate()
end
---------------------------------------------------
-- energy logic end --
---------------------------------------------------

return EnemyPlayerObjectModel
