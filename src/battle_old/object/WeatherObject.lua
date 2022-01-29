--[[
天气模型
@params table {
	tag int obj tag
	oname string obj name
	battleElementType BattleElementType 战斗物体大类型 
	objInfo ObjectConstructorStruct 战斗物体构造函数
}
--]]
local BaseObject = __Require('battle.object.BaseObject')
local WeatherObject = class('WeatherObject', BaseObject)

--[[
@override
constructor
--]]
function WeatherObject:ctor( ... )
	local args = unpack({...})

	------------ 初始化id信息 ------------
	self.idInfo = {
		tag = args.tag,
		oname = args.oname,
		battleElementType = args.battleElementType
	}
	------------ 初始化id信息 ------------

	------------ 初始化卡牌基本信息 ------------
	self.objInfo = args.objInfo
	------------ 初始化卡牌基本信息 ------------

	------------ 初始化ui信息 ------------
	self.view = {
		viewComponent = nil,
		avatar = nil,
		animationsData = nil,
		hpBar = nil,
		energyBar = nil,
	}
	------------ 初始化ui信息 ------------

	self:init()

end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function WeatherObject:init()
	self:initValue()
	self:initDrivers()
end
--[[
@override
初始化行为驱动器
--]]
function WeatherObject:initDrivers()
	-- 天气模型包含一个施法行为
	local weatherConf = self:getObjectConfig()
	self.castDriver = __Require('battle.objectDriver.WeatherCastDriver').new({
		owner = self,
		weatherId = self:getOWeatherId(),
		skillIds = weatherConf.skillId
	})
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
update
@params dt number delta time
--]]
function WeatherObject:update(dt)
	if self:isPause() then return end
	self.castDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)
	self:autoController(dt)
end
--[[
控制器逻辑
@params dt number delta time
--]]
function WeatherObject:autoController(dt)
	---------- 是否可以施放技能 ----------
	local canCastingSkillId = self.castDriver:CanDoAction(ActionTriggerType.CD)
	if nil ~= canCastingSkillId then
		self.castingSkillId = canCastingSkillId
		self.castDriver:OnActionEnter(self.castingSkillId)
	end
	---------- 是否可以施放技能 ----------
end
--[[
施放所有光环效果
--]]
function WeatherObject:castAllHalos()
	self.castDriver:CastAllHalos()
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取天气配表id
@return _ int 天气配表id
--]]
function WeatherObject:getOWeatherId()
	return self.objInfo.cardId
end
--[[
@override
获取战斗物体外部配置
@return _ table
--]]
function WeatherObject:getObjectConfig()
	return CommonUtils.GetConfig('quest', 'weather', self:getOWeatherId())
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return WeatherObject
