--[[
天气物体的基类
--]]
local BaseObjectModel = __Require('battle.object.logicModel.objectModel.BaseObjectModel')
local WeahterObjectModel = class('WeahterObjectModel', BaseObjectModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function WeahterObjectModel:ctor( ... )
	BaseObjectModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化驱动组件
--]]
function WeahterObjectModel:InitDrivers()
	local weatherConfig = self:GetObjectConfig()

	-- 施法驱动
	self.castDriver = __Require('battle.objectDriver.castDriver.WeatherCastDriver').new({
		owner = self,
		weatherId = self:GetObjectWeahterId(),
		skillIds = weatherConfig.skillId
	})
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
主循环逻辑
--]]
function WeahterObjectModel:Update(dt)
	-- 暂停直接返回
	if self:IsPause() then return end

	-- 刷新驱动器
	self:UpdateDrivers(dt)

	-- 自动行为逻辑
	self:AutoController(dt)
end
--[[
刷新驱动器
--]]
function WeahterObjectModel:UpdateDrivers(dt)
	-- 施法驱动器
	self.castDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)
end
--[[
自动行为逻辑
--]]
function WeahterObjectModel:AutoController(dt)
	---------- 是否可以施放技能 ----------
	local canCastingSkillId = self.castDriver:CanDoAction(ActionTriggerType.CD)
	if nil ~= canCastingSkillId then
		self.castDriver:OnActionEnter(canCastingSkillId)
	end
	---------- 是否可以施放技能 ----------
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- cast logic begin --
---------------------------------------------------
--[[
@override
刷一次物体的光环数据
--]]
function WeahterObjectModel:CastAllHalos()
	--[[
	new logic todo

	刷新光环时需要把老的光环buff数据移除
	--]]
	self.castDriver:CastAllHalos()
end
---------------------------------------------------
-- cast logic end --
---------------------------------------------------

---------------------------------------------------
-- base info get set begin --
---------------------------------------------------
--[[
@override
获取物体config id
@return _ int
--]]
function WeahterObjectModel:GetObjectConfigId()
	return ConfigSpecialCardId.WEATHER
end
--[[
获取逻辑层物体与配表关联的id -> 天气id
@return _ int
--]]
function WeahterObjectModel:GetObjectWeahterId()
	return BaseObjectModel.GetObjectConfigId(self)
end
--[[
@override
获取逻辑层物体关联的配表信息
@return _ table
--]]
function WeahterObjectModel:GetObjectConfig()
	return CommonUtils.GetConfig('quest', 'weather', self:GetObjectWeahterId())
end
---------------------------------------------------
-- base info get set end --
---------------------------------------------------

return WeahterObjectModel
