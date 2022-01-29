--[[
ob物体的基类
--]]
local BaseObjectModel = __Require('battle.object.logicModel.objectModel.BaseObjectModel')
local OBObjectModel = class('OBObjectModel', BaseObjectModel)

------------ import ------------
------------ import ------------

------------ define ------------
local CCCountdownMin = 5
local CCCountdownMax = 10
------------ define ------------

--[[
constructor
--]]
function OBObjectModel:ctor( ... )
	BaseObjectModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化
--]]
function OBObjectModel:Init()
	BaseObjectModel.Init(self)

	------------ 初始化物体监听事件 ------------
	self:RegisterObjectEventHandler()
	------------ 初始化物体监听事件 ------------
end
--[[
初始化驱动组件
--]]
function OBObjectModel:InitDrivers()
	-- 初始化cc驱动器
	self.ccDriver = __Require('battle.objectDriver.ccDriver.BaseCCDriver').new({
		owner = self
	})

	-- 初始化镜头特效驱动器
	self.cameraDriver = __Require('battle.objectDriver.performanceDriver.CameraControlDriver').new({
		owner = self
	})

	-- 初始化引导驱动器
	local guideModuleId = G_BattleLogicMgr:GetGuideModuleId()
	if nil ~= guideModuleId then
		-- 引导精灵只拥有一个引导驱动
		self.guideDriver = __Require('battle.objectDriver.performanceDriver.BaseGuideDriver').new({
			owner = self,
			guideModuleId = guideModuleId
		})
	end

	if QuestBattleType.PERFORMANCE == G_BattleLogicMgr:GetQuestBattleType() then
		-- 初始化语音节点驱动
		self.voiceDriver = __Require('battle.objectDriver.performanceDriver.BaseVoiceDriver').new({
			owner = self
		})
	end
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
主循环逻辑
--]]
function OBObjectModel:Update(dt)
	-- 刷新驱动器
	self:UpdateDrivers(dt)
end
--[[
刷新驱动器
--]]
function OBObjectModel:UpdateDrivers(dt)
	-- 刷新cc驱动器
	self.ccDriver:UpdateActionTrigger(dt)

	------------ 刷新voice驱动 ------------
	if nil ~= self.voiceDriver then
		self.voiceDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)
	end
	------------ 刷新voice驱动 ------------

	------------ 刷新引导驱动 ------------
	if nil ~= self.guideDriver then

		local gameState = G_BattleLogicMgr:GetGState()
		if GState.READY == gameState or GState.START == gameState then

			if GState.START == gameState then
				-- 只在游戏进行时更新时间触发器
				self.guideDriver:UpdateActionTrigger(ConfigBattleGuideStepTriggerType.TIME_AXIS, dt)
			end

			if self.guideDriver:GetIsInGuide() then
				self.guideDriver:OnActionUpdate(dt)
			else
				-- 判断是否能进行下一步引导
				local nextGuideStepId = self.guideDriver:CanDoAction()
				if nil ~= nextGuideStepId then
					-- 可以执行下一步引导
					self.guideDriver:OnActionEnter(nextGuideStepId)
				end
			end

		end
	end
	------------ 刷新引导驱动 ------------
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- camera control begin --
---------------------------------------------------
--[[
结束一个镜头特效
@params cameraActionTag int 镜头特效tag
--]]
function OBObjectModel:CameraActionOverHandler(cameraActionTag)
	self.cameraDriver:OnActionExit(cameraActionTag)
end
---------------------------------------------------
-- camera control end --
---------------------------------------------------

---------------------------------------------------
-- guide begin --
---------------------------------------------------
--[[
引导结束
--]]
function OBObjectModel:GuideOver()
	if nil ~= self.guideDriver then
		self.guideDriver:OnActionExit()
	end
end
---------------------------------------------------
-- guide end --
---------------------------------------------------

---------------------------------------------------
-- event handler begin --
---------------------------------------------------
--[[
注册物体监听事件
--]]
function OBObjectModel:RegisterObjectEventHandler()
	local eventHandlerInfo = {
		{member = 'objCastEventHandler_', 			eventType = ObjectEvent.OBJECT_CAST_ENTER, 	handler = handler(self, self.ObjectEventCastHandler)},
		{member = 'objPhaseChangeEventHandler_', 	eventType = ObjectEvent.OBJECT_PHASE_CHANGE,handler = handler(self, self.ObjectEventPhaseChangeHandler)},
		{member = 'objChantEventHandler_', 			eventType = ObjectEvent.OBJECT_CHANT_ENTER,	handler = handler(self, self.ObjectEventChantHandler)}
	}

	for _,v in ipairs(eventHandlerInfo) do
		if nil == self[v.member] then
			self[v.member] = v.handler
		end
		G_BattleLogicMgr:AddObjEvent(v.eventType, self, self[v.member])
	end
end
--[[
注销物体监听事件
--]]
function OBObjectModel:UnregistObjectEventHandler()
	local eventHandlerInfo = {
		{member = 'objCastEventHandler_', 			eventType = ObjectEvent.OBJECT_CAST_ENTER, 	handler = handler(self, self.ObjectEventCastHandler)},
		{member = 'objPhaseChangeEventHandler_', 	eventType = ObjectEvent.OBJECT_PHASE_CHANGE,handler = handler(self, self.ObjectEventPhaseChangeHandler)},
		{member = 'objChantEventHandler_', 			eventType = ObjectEvent.OBJECT_CHANT_ENTER,	handler = handler(self, self.ObjectEventChantHandler)}
	}

	for _,v in ipairs(eventHandlerInfo) do
		G_BattleLogicMgr:RemoveObjEvent(v.eventType, self)
	end
end
--[[
物体施法事件回调
@params ... 
	args table passed args
--]]
function OBObjectModel:ObjectEventCastHandler( ... )
	local args = unpack({...})
	local otag = args.tag
	local obj = G_BattleLogicMgr:IsObjAliveByTag(otag)

	if nil ~= self.guideDriver then
		self.guideDriver:UpdateActionTrigger(ConfigBattleGuideStepTriggerType.CAST_SKILL, args.skillId)
	end

	if nil ~= obj then

		local cardId = obj:GetObjectConfigId()
		local isEnemy = args.isEnemy
		local skillId = args.skillId

		local params = {
			cardId = cardId,
			isEnemy = isEnemy,
			skillId = skillId
		}

		-- 直接判断是否能触发
		self.cameraDriver:CanDoAction(ConfigCameraTriggerType.OBJ_SKILL, params)

	end
end
--[[
物体读条事件回调
@params ... 
	args table passed args
--]]
function OBObjectModel:ObjectEventChantHandler( ... )
	local args = unpack({...})
	if nil ~= self.guideDriver then
		self.guideDriver:UpdateActionTrigger(ConfigBattleGuideStepTriggerType.CHANT, args.skillId)
	end
end
--[[
物体阶段转换事件回调
@params ...
	args table passed args
--]]
function OBObjectModel:ObjectEventPhaseChangeHandler( ... )
	local args = unpack({...})
	
	local params = {
		tag = args.triggerPhaseNpcTag,
		phaseId = args.phaseId
	}

	self.cameraDriver:CanDoAction(ConfigCameraTriggerType.PHASE_CHANGE, params)
end
---------------------------------------------------
-- event handler end --
---------------------------------------------------

return OBObjectModel
