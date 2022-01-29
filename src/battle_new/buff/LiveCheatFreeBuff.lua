--[[
免费买活buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local LiveCheatFreeBuff = class('LiveCheatFreeBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
造成效果
@return result number 造成效果以后的结果
--]]
function LiveCheatFreeBuff:CauseEffect()
	-- 增加免费买活次数
	self:SetFreeCheatLiveTimes(math.max(0, self:GetFreeCheatLiveTimes() - 1))

	if 0 >= self:GetFreeCheatLiveTimes() then
		self:OnRecoverEffectEnter()
	end

	return 0
end
--[[
@override
恢复效果
@params casterTag int 施法者tag
@return result number 恢复效果以后的结果
--]]
function LiveCheatFreeBuff:OnRecoverEffectEnter(casterTag)
	local owner = G_BattleLogicMgr:GetGlobalEffectObj()
	if nil ~= owner then
		owner:RemoveBuff(self)
	end
	return 0
end
--[[
@override
主逻辑更新
--]]
function LiveCheatFreeBuff:OnBuffUpdateEnter(dt)

end
--[[
@override
刷新buff
@params buffInfo ObjectBuffConstructorStruct buff数据
--]]
function LiveCheatFreeBuff:OnRefreshBuffEnter(buffInfo)
	
end
--[[
@override
添加buff对应的展示
--]]
function LiveCheatFreeBuff:AddView()
	
end
--[[
@override
移除buff对应的展示
--]]
function LiveCheatFreeBuff:RemoveView()
	
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取免费买活次数
--]]
function LiveCheatFreeBuff:GetFreeCheatLiveTimes()
	return self.p.countdown
end
function LiveCheatFreeBuff:SetFreeCheatLiveTimes(times)
	self.p.countdown = times
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return LiveCheatFreeBuff
