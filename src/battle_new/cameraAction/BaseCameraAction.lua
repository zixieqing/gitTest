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
	self.ownerTag = nil

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
	-- 屏蔽触摸
	self:SetGameTouchEnable(false)

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
	if self:NeedStopGameAccelerate() then
		G_BattleLogicMgr:RenderRecoverTempTimeScaleHandler()
	end

	-- 恢复触摸
	self:SetGameTouchEnable(true)

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
获取镜头特效的id
--]]
function BaseCameraAction:GetCameraActionId()
	return self:GetCameraActionInfo().id
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
--[[
是否需要恢复游戏加速
--]]
function BaseCameraAction:NeedStopGameAccelerate()
	return self.needStopGameAccelerate
end
--[[
设置游戏是否可以触摸
@params enable bool 是否可以触摸
--]]
function BaseCameraAction:SetGameTouchEnable(enable)
	-- 设置触摸
	G_BattleLogicMgr:SetBattleTouchEnable(enable)

	--***---------- 刷新渲染层 ----------***--
	self:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetBattleTouchEnable',
		enable
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
ownerTag
--]]
function BaseCameraAction:GetOwnerTag()
	return self.ownerTag
end
function BaseCameraAction:SetOwnerTag(ownerTag)
	self.ownerTag = ownerTag
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseCameraAction
