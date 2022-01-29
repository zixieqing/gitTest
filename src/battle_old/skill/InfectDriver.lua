--[[
传染驱动器 搭载在 obj 身上的传染驱动器
传染直接传染整个技能 传染有自身的索敌规则
@params table {
	infectInfo InfectTransmitStruct 传染信息
}
--]]
local InfectDriver = class('InfectDriver')

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
contructor
--]]
function InfectDriver:ctor( ... )
	local args = unpack({...})

	------------ 初始化传染数据结构 ------------
	self.infectInfo = args.infectInfo
	self.infectCounter = self.infectInfo.infectTime
	self.alive = true
	------------ 初始化传染数据结构 ------------

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
update logic
--]]
function InfectDriver:Update(dt)
	if self.infectCounter <= 0 and self.alive then
		self:InfectSelf()
		self.alive = false
	end

	local _dt = dt
	self.infectCounter = math.max(self.infectCounter - _dt, 0)
end
--[[
传染自身
--]]
function InfectDriver:InfectSelf()
	local skill = __Require('battle.skill.InfectSkill').new(self.infectInfo)
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
杀死自己
--]]
function InfectDriver:Kill()
	local owner = BMediator:IsObjAliveByTag(self.infectInfo.infectSourceTag)
	if nil ~= owner then
		owner:removeInfectDriver(self:GetSkillId())
	end
	self:Destroy()
end
--[[
销毁
--]]
function InfectDriver:Destroy()
	self.infectInfo = nil
	self.infectCounter = nil
	self.alive = nil
end
--[[
获取对应的技能id
--]]
function InfectDriver:GetSkillId()
	return self.infectInfo.skillId
end
---------------------------------------------------
-- control end --
---------------------------------------------------

return InfectDriver
