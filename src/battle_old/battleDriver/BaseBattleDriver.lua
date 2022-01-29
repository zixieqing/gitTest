--[[
战斗控制器 组件逻辑基类
--]]
local BaseBattleDriver = class('BaseBattleDriver')
--[[
constructor
--]]
function BaseBattleDriver:ctor( ... )
	local args = unpack({...})
	self.owner = args.owner
	self.driverType = BattleDriverType.BASE
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化逻辑
--]]
function BaseBattleDriver:Init()

end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
是否能进行逻辑
--]]
function BaseBattleDriver:CanDoLogic()
	
end
--[[
逻辑开始
--]]
function BaseBattleDriver:OnLogicEnter()

end
--[[
逻辑进行中
--]]
function BaseBattleDriver:OnLogicUpdate(dt)
	
end
--[[
逻辑结束
--]]
function BaseBattleDriver:OnLogicExit()

end
--[[
逻辑被打断
--]]
function BaseBattleDriver:OnLogicBreak()

end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取战斗物体
--]]
function BaseBattleDriver:GetOwner()
	return self.owner
end
--[[
获取驱动类型
--]]
function BaseBattleDriver:GetDriverType()
	return self.driverType
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseBattleDriver
