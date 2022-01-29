--[[
变色驱动器基类
@params table {
	owner BaseObject 挂载的战斗物体
}
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BaseTintDriver = class('BaseTintDriver', BaseActionDriver)

------------ define ------------
local TintColorPattern = {
	[BattleObjTintPattern.BOTP_BASE] 		= {color = cc.c3b(255, 255, 255), time = 0, tintType = BattleObjTintType.BOTT_BASE},
	[BattleObjTintPattern.BOTP_BLOOD] 		= {color = cc.c3b(255, 255, 255), time = 0.15, tintType = BattleObjTintType.BOTT_INSTANT},
	[BattleObjTintPattern.BOTP_DARK]		= {color = cc.c3b(25, 25, 25), time = 0, tintType = BattleObjTintType.BOTT_COVER} 
}
------------ define ------------

--[[
constructor
--]]
function BaseTintDriver:ctor( ... )
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
function BaseTintDriver:Init()
	-- 当前变色状态
	self.currentTintType = BattleObjTintType.BOTT_BASE
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@override
是否能进行动作
@params tintType BattleObjTintType 变色类型
@return result bool 是否可以执行动作
--]]
function BaseTintDriver:CanDoAction(tintType)
	local result = true
	if BattleObjTintType.BOTT_INSTANT == tintType and BattleObjTintType.BOTT_COVER == self.currentTintType then
		result = false
	end
	return result
end
--[[
@override
进入动作
@params tintPattern BattleObjTintPattern 变色样式
--]]
function BaseTintDriver:OnActionEnter(tintPattern)
	local tintData = self:GetTintDataByPattern(tintPattern)

	-- 可行性判断
	if not self:CanDoAction(tintData.tintType) then return end

	if BattleObjTintType.BOTT_INSTANT == tintData.tintType then		
		self:OnInstantTintEnter(tintPattern)
	elseif BattleObjTintType.BOTT_COVER == tintData.tintType then
		self:OnCoverKeepTintEnter(tintPattern)
	end
end
--[[
@override
结束动作
--]]
function BaseTintDriver:OnActionExit()
	self.currentTintType = BattleObjTintType.BOTT_BASE
	self:GetOwnerAvatar():setColor(self:GetTintDataByPattern(BattleObjTintPattern.BOTP_BASE).color)
end
--[[
@override
动作进行中
@params dt number delta time
--]]
function BaseTintDriver:OnActionUpdate(dt)

end
--[[
@override
动作被打断
--]]
function BaseTintDriver:OnActionBreak()
	---------- 杀掉之前的tint ----------
	local preTintAction = self:GetOwnerAvatar():getActionByTag(BattleObjActionTag.BOAT_TINT)
	if preTintAction then
		self:GetOwnerAvatar():stopAction(preTintAction)
	end
	---------- 杀掉之前的tint ----------

	self:OnActionExit()
end
--[[
@override
刷新触发器
--]]
function BaseTintDriver:UpdateActionTrigger()

end
--[[
@override
消耗做出行为需要的资源
--]]
function BaseTintDriver:CostActionResources()

end
--[[
@override
重置所有触发器
--]]
function BaseTintDriver:ResetActionTrigger()

end
--[[
@override
操作触发器
--]]
function BaseTintDriver:GetActionTrigger()

end
function BaseTintDriver:SetActionTrigger()
	
end
--[[
瞬时变色逻辑 开始
@params tintPattern BattleObjTintPattern 样式
--]]
function BaseTintDriver:OnInstantTintEnter(tintPattern)
	self.currentTintType = BattleObjTintType.BOTT_INSTANT

	---------- 杀掉之前的tint ----------
	local preTintAction = self:GetOwnerAvatar():getActionByTag(BattleObjActionTag.BOAT_TINT)
	if preTintAction then
		self:GetOwnerAvatar():stopAction(preTintAction)
	end
	---------- 杀掉之前的tint ----------

	---------- 开始一个新的tint ----------
	local tintData = self:GetTintDataByPattern(tintPattern)
	local tintActionSeq = cc.Sequence:create(
		cc.TintTo:create(0, tintData.color),
		cc.DelayTime:create(tintData.time),
		cc.CallFunc:create(function ()
			self:OnInstantTintExit()
		end))
	tintActionSeq:setTag(BattleObjActionTag.BOAT_TINT)
	self:GetOwnerAvatar():runAction(tintActionSeq)
	---------- 开始一个新的tint ----------
end
--[[
瞬时变色逻辑 结束
--]]
function BaseTintDriver:OnInstantTintExit()
	self:OnActionExit()
end
--[[
全覆盖持续变色逻辑 开始
@params tintPattern BattleObjTintPattern 变色样式
--]]
function BaseTintDriver:OnCoverKeepTintEnter(tintPattern)
	self.currentTintType = BattleObjTintType.BOTT_COVER

	---------- 杀掉之前的tint ----------
	local preTintAction = self:GetOwnerAvatar():getActionByTag(BattleObjActionTag.BOAT_TINT)
	if preTintAction then
		self:GetOwnerAvatar():stopAction(preTintAction)
	end
	---------- 杀掉之前的tint ----------

	---------- 持续变色 ----------
	local tintData = self:GetTintDataByPattern(tintPattern)
	self:GetOwnerAvatar():setColor(tintData.color)
	---------- 持续变色 ----------
end
--[[
全覆盖持续变色逻辑 结束
--]]
function BaseTintDriver:OnCoverKeepTintExit()
	self:OnActionExit()
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据tint样式获取tint信息
@params tintPattern BattleObjTintPattern 变色样式
--]]
function BaseTintDriver:GetTintDataByPattern(tintPattern)
	return TintColorPattern[tintPattern]
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseTintDriver
