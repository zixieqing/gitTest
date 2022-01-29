--[[
语音播放驱动基类
@params table {
	owner BaseObject 挂载的战斗物体
	voiceModuleId int 语音模块id
}
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BaseVoiceDriver = class('BaseVoiceDriver', BaseActionDriver)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseVoiceDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)
	local args = unpack({...})

	self.voiceModuleId = args.voiceModuleId

	self:Init()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function BaseVoiceDriver:Init()
	BaseActionDriver.Init(self)

	-- 初始化触发器
	self.actionTrigger = {
		[ActionTriggerType.CD] = {}
	}

	-- 语音数据
	self.voices = {}

	self:InitValue()
end
--[[
@override
初始化数据
--]]
function BaseVoiceDriver:InitValue()
	-- 根据语音模块id初始化语音数据
	self.voices = {
		['1'] = {id = 1, cardId = 200020, appearTime = 0.5, isEnemy = true, voiceId = 10, time = 0, text = __('狂欢才刚刚开始!')},
		['2'] = {id = 2, cardId = 200037, appearTime = 3.5, isEnemy = false, voiceId = 10, time = 2, text = __('可以安静点吗!')},
		['3'] = {id = 3, cardId = 200004, appearTime = 6, isEnemy = false, voiceId = 15, time = 0, text = __('可恶!')},
		['4'] = {id = 4, cardId = 200048, appearTime = 8, isEnemy = false, voiceId = 15, time = 0, text = __('……还没有……')},
		['5'] = {id = 5, cardId = 200024, appearTime = 11, isEnemy = false, voiceId = 12, time = 0, text = __('不，现在还不能倒下。')},
	}

	-- 为触发器插入语音cd时间
	for k,v in pairs(self.voices) do
		self.actionTrigger[ActionTriggerType.CD][tostring(v.id)] = v.appearTime
	end
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
--]]
function BaseVoiceDriver:CanDoAction()

end
--[[
@override
进入动作
--]]
function BaseVoiceDriver:OnActionEnter()

end
--[[
@override
结束动作
--]]
function BaseVoiceDriver:OnActionExit()

end
--[[
@override
动作进行中
@params dt number delta time
--]]
function BaseVoiceDriver:OnActionUpdate(dt)

end
--[[
@override
动作被打断
--]]
function BaseVoiceDriver:OnActionBreak()
	
end
--[[
@override
消耗做出行为需要的资源
--]]
function BaseVoiceDriver:CostActionResources()

end
--[[
@override
刷新触发器
@params actionTriggerType ActionTriggerType 技能触发类型
@params delta number 变化量
--]]
function BaseVoiceDriver:UpdateActionTrigger(actionTriggerType, delta)
	if ActionTriggerType.CD == actionTriggerType then
		for id, countdown in pairs(self.actionTrigger[ActionTriggerType.CD]) do
			self.actionTrigger[ActionTriggerType.CD][id] = math.max(0, countdown - delta)
			if 0 >= self.actionTrigger[ActionTriggerType.CD][id] then
				-- 从数据中移除
				self.actionTrigger[ActionTriggerType.CD][id] = nil

				-- 播放语音 显示对话气泡
				self:PlayVoice(checkint(id))
			end
		end
	end
end
--[[
@override
重置所有触发器
--]]
function BaseVoiceDriver:ResetActionTrigger()

end
--[[
@override
操作触发器
--]]
function BaseVoiceDriver:GetActionTrigger()

end
function BaseVoiceDriver:SetActionTrigger()
	
end
--[[
根据 语音id 播放语音
@params id int 语音id
--]]
function BaseVoiceDriver:PlayVoice(id)
	local voiceData = self.voices[tostring(id)]

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'PlayeVoice',
		voiceData
	)
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据配置信息获取语音数据
@params voiceConfig table 语音配置信息
--]]
function BaseVoiceDriver:ConvertVoiceDataByConfig(voiceConfig)

end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseVoiceDriver
