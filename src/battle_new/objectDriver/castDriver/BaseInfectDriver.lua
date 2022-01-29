--[[
传染驱动基类
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BaseInfectDriver = class('BaseInfectDriver', BaseActionDriver)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseInfectDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)

	self:Init()
end

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function BaseInfectDriver:Init()
	self:InitInnateValue()
	self:InitUnitValue()
end
--[[
初始化固有属性
--]]
function BaseInfectDriver:InitInnateValue()
	-- 初始化触发器
	self.actionTrigger = {
		[ActionTriggerType.CD] = {}
	}

	-- 传染的信息
	self.infectInfos = {}
end
--[[
初始化独有属性
--]]
function BaseInfectDriver:InitUnitValue()
	
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
是否能进行动作
--]]
function BaseInfectDriver:CanDoAction()

end
--[[
进入动作
@params infectInfo InfectTransmitStruct
--]]
function BaseInfectDriver:OnActionEnter(infectInfo)
	local skill = __Require('battle.skill.InfectSkill').new(infectInfo)
	local params = ObjectCastParameterStruct.New(
		1,
		1,
		nil,
		cc.p(0, 0),
		false,
		false
	)
	skill:CastBegin(params)
end
--[[
结束动作
--]]
function BaseInfectDriver:OnActionExit()

end
--[[
动作进行中
@params dt number delta time
--]]
function BaseInfectDriver:OnActionUpdate(dt)

end
--[[
动作被打断
--]]
function BaseInfectDriver:OnActionBreak()
	
end
--[[
消耗做出行为需要的资源
--]]
function BaseInfectDriver:CostActionResources()

end
--[[
刷新触发器
@params actionTriggerType ActionTriggerType 触发器类型
@params delta number 差值
--]]
function BaseInfectDriver:UpdateActionTrigger(actionTriggerType, delta)
	local infectData = nil 

	for i = #self.actionTrigger[actionTriggerType], 1, -1 do
		infectData = self.actionTrigger[actionTriggerType][i]

		infectData.value = math.max(0, infectData.value - delta)

		if 0 >= infectData.value then
			local skillId = infectData.skillId
			local infectInfo = self:GetInfectInfoBySkillId(skillId)
			if nil ~= infectInfo then
				self:OnActionEnter(infectInfo)
			end

			-- 移除相关数据
			table.remove(self.actionTrigger[actionTriggerType], i)
		end
	end
end
--[[
重置所有触发器
--]]
function BaseInfectDriver:ResetActionTrigger()

end
--[[
操作触发器
--]]
function BaseInfectDriver:GetActionTrigger()

end
function BaseInfectDriver:SetActionTrigger()
	
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- infect logic begin --
---------------------------------------------------
--[[
添加一个传染数据
@params infectInfo InfectTransmitStruct
--]]
function BaseInfectDriver:AddAInfectInfo(infectInfo)
	local infectSkillId = infectInfo:GetSkillId()
	local infectTime = infectInfo.infectTime

	self.infectInfos[tostring(infectSkillId)] = infectInfo
	table.insert(self.actionTrigger[ActionTriggerType.CD], 1, {skillId = infectSkillId, value = infectTime})
end
--[[
根据技能id移除一个传染信息
@params skillId int 技能id
--]]
function BaseInfectDriver:RemoveAInfectInfoBySkillId(skillId)
	-- 移除计时器
	for i = #self.actionTrigger[ActionTriggerType.CD], 1, -1 do
		if skillId == self.actionTrigger[ActionTriggerType.CD][i].skillId then
			table.remove(self.actionTrigger[ActionTriggerType.CD], i)
		end
	end

	-- 移除传染信息
	self.infectInfos[tostring(skillId)] = nil
end
---------------------------------------------------
-- infect logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据技能id获取传染信息
@params skillId int 技能id
@return _ InfectTransmitStruct
--]]
function BaseInfectDriver:GetInfectInfoBySkillId(skillId)
	return self.infectInfos[tostring(skillId)]
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseInfectDriver
