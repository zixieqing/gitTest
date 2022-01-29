--[[
情景技能
--]]
local BaseSkill = __Require('battle.skill.BaseSkill')
local SceneSkill = class('SceneSkill', BaseSkill)

--[[
@override
开始释放技能 直接对全局buff物体挂载一些buff
@params params ObjectCastParameterStruct 外部传参
--]]
function SceneSkill:CastBegin(params)
	self:Cast(params)
end
--[[
@override
释放该技能
@params params ObjectCastParameterStruct 外部传参
--]]
function SceneSkill:Cast(params)
	local buffType_ = nil
	local buffInfo_ = nil

	local target = BMediator:GetBData():GetGlobalEffectObj()
	local tTag = target:getOTag()

	---------- func -> convertBuffTargetData ----------
	local t = {}
	local tmpTargetTagIdx = {}

	for i = #self.buffInfos, 1, -1 do
		buffInfo_ = self.buffInfos[i]
		buffType_ = buffInfo_.btype

		local buffInfo = clone(buffInfo_)
		buffInfo.ownerTag = tTag

		---------- 修正buff实际值 ----------
		self:ConvertConfigValue2RealValue(target, target, buffInfo_.value, buffInfo, 1, 1)
		---------- 修正buff实际值 ----------

		if nil == tmpTargetTagIdx[tostring(tTag)] then
			table.insert(t, {tag = tTag, buffs = {}, needRevive = (ConfigBuffType.REVIVE == buffType_)})
			tmpTargetTagIdx[tostring(tTag)] = #t
		end
		table.insert(t[tmpTargetTagIdx[tostring(tTag)]].buffs, buffInfo)
	end
	---------- func -> convertBuffTargetData ----------

	---------- func -> cast ----------
	local buffs = t[tmpTargetTagIdx[tostring(tTag)]].buffs
	for i, buffInfo__ in ipairs(buffs) do
		local buffInfo = clone(buffInfo__)
		target:beCasted(buffInfo)
	end
	---------- func -> cast ----------	

end

return SceneSkill
