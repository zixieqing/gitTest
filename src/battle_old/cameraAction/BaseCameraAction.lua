--[[
镜头特效基类
@params table {
	cameraActionInfo CameraActionStruct 镜头特效数据
}
--]]
local BaseCameraAction = class('BaseCameraAction')

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseCameraAction:ctor( ... )
	local args = unpack({...})

	self.cameraActionInfo = args.cameraActionInfo

	self:Init()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化逻辑
--]]
function BaseCameraAction:Init()
	self.actionOver = false
	self.delayTime = self:GetCameraActionInfo().delayTime
	self.needStopGameAccelerate = self:GetCameraActionInfo().accelerate

	self.actionTrigger = {
		[ActionTriggerType.CD] = self.delayTime
	}
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
function BaseCameraAction:CanDoAction()
	return 0 >= self:GetActionTrigger(ActionTriggerType.CD)
end
--[[
进行动作
--]]
function BaseCameraAction:OnActionEnter()
	-- 设置触摸
	BMediator:SetBattleTouchEnable(false)

	self:OnActionExit()
end
--[[
动作进行中
@params dt number delta time
--]]
function BaseCameraAction:OnActionUpdate(dt)

end
--[[
结束动作
--]]
function BaseCameraAction:OnActionExit()
	-- 恢复游戏加速
	if self.needStopGameAccelerate then
		cc.Director:getInstance():getScheduler():setTimeScale(BMediator:GetTimeScale())
	end

	-- 设置触摸
	BMediator:SetBattleTouchEnable(true)

	self:SetActionOver(true)
end
--[[
打断动作
--]]
function BaseCameraAction:OnActionBreak()

end
--[[
刷新触发器
@params actionTriggerType ActionTriggerType 行为触发类型
@params delta number 变化量
--]]
function BaseCameraAction:UpdateActionTrigger(actionTriggerType, delta)
	self.actionTrigger[actionTriggerType] = math.max(0, self.actionTrigger[actionTriggerType] + delta)
end
--[[
操作触发器
--]]
function BaseCameraAction:GetActionTrigger(actionTriggerType)
	return self.actionTrigger[actionTriggerType]
end
function BaseCameraAction:SetActionTrigger()
	
end
--[[
动作被清除
--]]
function BaseCameraAction:OnActionClear()
	print('>>>>>>here camera action run finish and remove from cache<<<<<<')
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取镜头特效数据
--]]
function BaseCameraAction:GetCameraActionInfo()
	return self.cameraActionInfo
end
--[[
动作是否完成
--]]
function BaseCameraAction:IsActionOver()
	return self.actionOver
end
function BaseCameraAction:SetActionOver(b)
	self.actionOver = true
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseCameraAction
