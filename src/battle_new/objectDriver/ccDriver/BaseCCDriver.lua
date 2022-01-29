--[[
cc驱动基类
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BaseCCDriver = class('BaseCCDriver', BaseActionDriver)

------------ import ------------
------------ import ------------

------------ define ------------
local CCCountdownMin = 5
local CCCountdownMax = 10
------------ define ------------

--[[
constructor
--]]
function BaseCCDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)

	self:Init()
end

---------------------------------------------------
-- init logic end --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function BaseCCDriver:Init()
	self.cccountdown = 0
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
记录一次所有物体的属性
--]]
function BaseCCDriver:RecordAllFriendObjPStr()
	if nil ~= G_BattleLogicMgr and nil ~= G_BattleLogicMgr:GetBData() then

		local frameIndex = G_BattleLogicMgr:GetBData():GetLogicFrameIndex()
		if frameIndex % 60 == 0 then

			local pstr = G_BattleLogicMgr:GetBData():ConvertAllFriendObjPStr()
			print('ccp [new battle] ----------->>>>>>>', frameIndex, '\n', pstr)
			G_BattleLogicMgr:GetBData():AddObjPStr(pstr)

		end

	end
end
---------------------------------------------------
-- control end --
---------------------------------------------------

---------------------------------------------------
-- update logic begin --
---------------------------------------------------
--[[
main update
@params dt number delta time
--]]
function BaseCCDriver:UpdateActionTrigger(dt)
	-- record
	self:RecordAllFriendObjPStr()

	-- 主逻辑
	local countdown = math.max(0, self:GetCCCountdown() - dt)
	if 0 >= countdown then
		self:ResetCCCountdown()
	else
		self:SetCCCountdown(countdown)
	end
end
---------------------------------------------------
-- update logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
倒计时
--]]
function BaseCCDriver:GetCCCountdown()
	return self.cccountdown
end
function BaseCCDriver:SetCCCountdown(countdown)
	self.cccountdown = countdown
end
--[[
重置倒计时
--]]
function BaseCCDriver:ResetCCCountdown()
	self:SetCCCountdown(math.random(CCCountdownMin, CCCountdownMax))
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseCCDriver
