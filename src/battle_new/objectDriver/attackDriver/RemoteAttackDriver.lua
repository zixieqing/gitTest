--[[
远程攻击行为驱动
--]]
local BaseAttackDriver = __Require('battle.objectDriver.attackDriver.BaseAttackDriver')
local RemoteAttackDriver = class('RemoteAttackDriver', BaseAttackDriver)

---------------------------------------------------
-- override begin --
---------------------------------------------------
--[[
是否能进行动作
@return result bool 是否可以攻击
--]]
function RemoteAttackDriver:CanDoAction()
	local result = false

	if 0 >= self:GetActionTrigger() then
		-- 攻击间隔满足 返回
		result = true
	end
	
	return result
end
--[[
@override
是否可以攻击 距离判定
@params targetTag int 攻击对象tag
@return _ bool 距离上是否满足攻击条件
--]]
function RemoteAttackDriver:CanAttackByDistance(targetTag)
	local target = G_BattleLogicMgr:IsObjAliveByTag(targetTag)

	if nil == target then return false end

	local deltaC = math.abs(self:GetOwner():GetLocation().rc.c - target:GetLocation().rc.c) - target:GetStaticCollisionBox().width * 0.5

	return deltaC <= self:GetOwner():GetMainProperty().p.attackRange
end
---------------------------------------------------
-- override end --
---------------------------------------------------

return RemoteAttackDriver
