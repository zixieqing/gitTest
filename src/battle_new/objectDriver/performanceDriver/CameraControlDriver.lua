--[[
战斗镜头控制驱动器
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local CameraControlDriver = class('CameraControlDriver', BaseActionDriver)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
@override
constructor
--]]
function CameraControlDriver:ctor( ... )
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
function CameraControlDriver:Init()
	self:InitCameraActions()
end
--[[
初始化镜头效果
--]]
function CameraControlDriver:InitCameraActions()
	-- 所有的镜头动画数据
	self.cameraActionsInfo = {
		id = {},
		[ConfigCameraTriggerType.PHASE_CHANGE] = {},
		[ConfigCameraTriggerType.OBJ_SKILL] = {},
	}
	-- 准备触发的镜头动画
	self.cameraActions = {}
	-- 正在触发的镜头动画
	self.runningCameraActions = {}

	local stageId = G_BattleLogicMgr:GetCurStageId()

	if nil == stageId then return end

	local stageConfig = CommonUtils.GetQuestConf(stageId)

	if stageConfig and stageConfig.cameraAction then
		for i,v in ipairs(stageConfig.cameraAction) do
			local cameraActionInfo = BattleUtils.GetCameraActionStructById(checkint(v))
			if nil ~= cameraActionInfo then
				self.cameraActionsInfo.id[tostring(v)] = cameraActionInfo
				table.insert(self.cameraActionsInfo[cameraActionInfo.triggerType], cameraActionInfo)
			end
		end
	end

	-- dump(self.cameraActionsInfo)

	-- debug --
	-- self:OnTriggerCameraAction(1)
	-- debug --
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@override
根据触发类型和外部参数检查是否有镜头特效满足触发条件
@params triggerType ConfigCameraTriggerType 触发类型
@params params table 外部参数
--]]
function CameraControlDriver:CanDoAction(triggerType, params)
	if ConfigCameraTriggerType.OBJ_SKILL == triggerType then
		self:CanDoActionByObjSkill(params)
	elseif ConfigCameraTriggerType.PHASE_CHANGE == triggerType then
		self:CanDoActionByPhaseChange(params)
	end
end
--[[
@override
进入动作
--]]
function CameraControlDriver:OnActionEnter()

end
--[[
结束动作
@params cameraActionTag int 镜头特效tag
--]]
function CameraControlDriver:OnActionExit(cameraActionTag)
	local cameraAction = self:GetRunningCameraActionByTag(cameraActionTag)
	if nil ~= cameraAction then
		cameraAction:OnActionExit()
	end
end
--[[
@override
动作进行中
@params dt number delta time
--]]
function CameraControlDriver:OnActionUpdate(dt)
	self:UpdateActionTrigger(ActionTriggerType.CD, -dt)

	-- 刷新一次正在进行的镜头动画
	local cameraAction = nil
	for i = #self.runningCameraActions, 1, -1 do
		cameraAction = self.runningCameraActions[i]
		cameraAction:OnActionUpdate(dt)
		if cameraAction:IsActionOver() then
			cameraAction:OnActionClear()
			table.remove(self.runningCameraActions, i)
		end
	end
end
--[[
@override
动作被打断
--]]
function CameraControlDriver:OnActionBreak()
	
end
--[[
@override
消耗做出行为需要的资源
@params id int 镜头特效id
--]]
function CameraControlDriver:CostActionResources(id)
	
end
--[[
@override
刷新触发器
@params actionTriggerType ActionTriggerType 行为触发类型
@params delta number 变化量
--]]
function CameraControlDriver:UpdateActionTrigger(actionTriggerType, delta)
	if ActionTriggerType.CD == actionTriggerType then
		-- cd
		for i = #self.cameraActions, 1, -1 do
			local cameraAction = self.cameraActions[i]
			cameraAction:UpdateActionTrigger(ActionTriggerType.CD, delta)
			if cameraAction:CanDoAction() then
				-- 开始做镜头动画
				cameraAction:OnActionEnter()
				-- 从缓存中移除该动画
				table.remove(self.cameraActions, i)
				-- 加入正在触发的镜头动画
				table.insert(self.runningCameraActions, 1, cameraAction)
			end
		end
	end
end
--[[
@override
重置所有触发器
--]]
function CameraControlDriver:ResetActionTrigger()

end
--[[
@override
操作触发器
--]]
function CameraControlDriver:GetActionTrigger()

end
--[[
@override
设置触发器
@params id int 镜头特效id
@params data table 数据
--]]
function CameraControlDriver:SetActionTrigger(id, data)
	
end
--[[
根据外部参数判断由物体触发的镜头特效
@params params table {
	cardId int 卡牌id
	isEnemy int 敌友性
	skillId int 技能id
}
--]]
function CameraControlDriver:CanDoActionByObjSkill(params)
	local cardId = checkint(params.cardId)
	local isEnemy = params.isEnemy
	local skillId = checkint(params.skillId)

	for i,v in ipairs(self.cameraActionsInfo[ConfigCameraTriggerType.OBJ_SKILL]) do
		if cardId == v.triggerTarget and 
			isEnemy == (ConfigCampType.ENEMY == v.triggerTargetCampType and true or false) and
			skillId == v.triggerValue then

			self:OnTriggerCameraAction(v.id)

		end
	end
end
--[[
根据外部参数判断由物体触发的镜头特效
@params table {
	phaseId int 转阶段id
}
--]]
function CameraControlDriver:CanDoActionByPhaseChange(params)
	local phaseId = checkint(params.phaseId)
	for i,v in ipairs(self.cameraActionsInfo[ConfigCameraTriggerType.PHASE_CHANGE]) do
		if phaseId == v.triggerValue then

			self:OnTriggerCameraAction(v.id)

		end
	end
end
--[[
满足外部条件触发镜头特效
@params id int 镜头特效id
--]]
function CameraControlDriver:OnTriggerCameraAction(id)
	-- 创建一个镜头特效action
	local cameraActionInfo = self:GetCameraActionInfoById(id)
	if nil ~= cameraActionInfo then
		local cameraActionClassName = 'battle.cameraAction.BaseCameraAction'
		if ConfigCameraActionType.SHAKE_ZOOM == cameraActionInfo.cameraActionType then

			cameraActionClassName = 'battle.cameraAction.ShakeAndZoomAction'

		end

		local cameraAction = __Require(cameraActionClassName).new({
			cameraActionInfo = cameraActionInfo
		})
		cameraAction:SetOwnerTag(self:GetOwner():GetOTag())
		table.insert(self.cameraActions, 1, cameraAction)
	end
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------

---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据id获取镜头效果数据
@params id int id
@return _ CameraActionStruct 镜头特效数据
--]]
function CameraControlDriver:GetCameraActionInfoById(id)
	return self.cameraActionsInfo.id[tostring(id)]
end
--[[
在正在运行的镜头特效中根据id获取镜头特效
@params cameraActionTag int tag 
--]]
function CameraControlDriver:GetRunningCameraActionByTag(cameraActionTag)
	local cameraAction = nil

	for i = #self.runningCameraActions, 1, -1 do
		cameraAction = self.runningCameraActions[i]
		if cameraActionTag == cameraAction:GetCameraActionId() then
			return cameraAction
		end
	end

	return nil
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return CameraControlDriver
