--[[
战斗引导驱动器
@params table {
	owner BaseObject 挂载的战斗物体
	guideModuleId int 引导模块id
}
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BaseGuideDriver = class('BaseGuideDriver', BaseActionDriver)

------------ import ------------
local StepAllInfos = CommonUtils.GetConfigAllMess('combatStep', 'guide')
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseGuideDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)
	local args = unpack({...})
	self.guideModuleId = args.guideModuleId
	print('here check fuck guide module id<<<<<<<<<<<<<<<<<<<<', self.guideModuleId)

	self:Init()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function BaseGuideDriver:Init()
	-- 引导触发器
	self.actionTrigger = {
		[ConfigBattleGuideStepTriggerType.TIME_AXIS] = {},
		[ConfigBattleGuideStepTriggerType.CAST_SKILL] = {},
		[ConfigBattleGuideStepTriggerType.CONTINUE] = {},
		[ConfigBattleGuideStepTriggerType.CHANT] = {},
	}

	-- 引导
	self.guideSteps = {}

	-- 触发的引导队列 待运行
	self.awaitGuideSteps = {} -- 只保存id

	-- 当前正在进行的引导
	self.currentGuideStepId = nil

	-- 是否在进行引导 算上延迟
	self.isInGuide = false
	-- 引导是否开始 不算延迟
	self.isGuideStart = false

	-- 引导延迟的倒计时
	self.guideCountdown = 0

 	-- 初始化引导数据结构
	self:InitBattleGuide()
end
--[[
初始化引导的数据结构
--]]
function BaseGuideDriver:InitBattleGuide()
	local guideStepsConfig = self:GetGuideStepsConfig(self.guideModuleId)

	if nil == guideStepsConfig then return end

	for k, guideStepConfig in pairs(guideStepsConfig) do

		local guideStepId = checkint(guideStepConfig.id)
		-- 初始化引导数据结构
		local guideStepStruct = BattleGuideStepStruct.New(
			------------ 触发时机 ------------
			checkint(guideStepConfig.id),
			checkint(guideStepConfig.type),
			checkint(guideStepConfig.triggerCondition[1]),
			checkint(guideStepConfig.triggerCondition[2]),
			checkint(guideStepConfig.endCondition),
			checknumber(guideStepConfig.delay),
			------------ 引导主体 ------------
			guideStepConfig.content,
			checkint(guideStepConfig.location[1]),
			checkint(guideStepConfig.location[2]),
			------------ 引导高亮 ------------
			checkint(guideStepConfig.highlightLocation[1][1]),
			checkint(guideStepConfig.highlightLocation[2][1]),
			guideStepConfig.highlightLocation[3],
			guideStepConfig.highlightLocation[4][1],
			checkint(guideStepConfig.highlightLocation[5][1])
		)

		if ConfigBattleGuideStepTriggerType.CONTINUE == guideStepStruct.triggerType then

			-- 接下一步的触发器
			self.actionTrigger[guideStepStruct.triggerType][tostring(guideStepStruct.triggerValue)] = guideStepId

		elseif ConfigBattleGuideStepTriggerType.CAST_SKILL == guideStepStruct.triggerType then

			-- 接技能的触发器
			if nil == self.actionTrigger[guideStepStruct.triggerType][tostring(guideStepStruct.triggerValue)] then
				self.actionTrigger[guideStepStruct.triggerType][tostring(guideStepStruct.triggerValue)] = {}
			end

			table.insert(self.actionTrigger[guideStepStruct.triggerType][tostring(guideStepStruct.triggerValue)], 1, guideStepId)

		elseif ConfigBattleGuideStepTriggerType.CHANT == guideStepStruct.triggerType then

			-- 接读条的触发器
			if nil == self.actionTrigger[guideStepStruct.triggerType][tostring(guideStepStruct.triggerValue)] then
				self.actionTrigger[guideStepStruct.triggerType][tostring(guideStepStruct.triggerValue)] = {}
			end

			table.insert(self.actionTrigger[guideStepStruct.triggerType][tostring(guideStepStruct.triggerValue)], 1, guideStepId)

		elseif ConfigBattleGuideStepTriggerType.TIME_AXIS == guideStepStruct.triggerType then

			-- 接时间点的触发器
			table.insert(self.actionTrigger[guideStepStruct.triggerType], 1, {guideStepId = guideStepId, counter = guideStepStruct.triggerValue})

		end

		self.guideSteps[tostring(guideStepId)] = guideStepStruct

	end

	-- dump(self.guideSteps)
	-- dump(self.actionTrigger)
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- guide control begin --
---------------------------------------------------
--[[
@override
是否能进行动作
@return _ int 单步引导id
--]]
function BaseGuideDriver:CanDoAction()
	local awaitGuideAmount = #self.awaitGuideSteps
	if not self:GetIsInGuide() and 0 < awaitGuideAmount then
		return self.awaitGuideSteps[awaitGuideAmount]
	end
	return nil
end
--[[
@override
进入动作
@params guideStepId int 单步引导id
--]]
function BaseGuideDriver:OnActionEnter(guideStepId)
	print('****************\n-> here start guide : ' .. guideStepId .. '\n****************')

	-- 引导消耗
	self:CostActionResources(guideStepId)
	-- 引导中
	self:SetIsInGuide(true)
	-- 设置当前引导
	self:SetCurrentGuideStepId(guideStepId)

	local guideData = self:GetGuideStepDataById(guideStepId)
	if 0 < guideData.delayTime then
		-- 为当前步引导设置一个延迟
		self.guideCountdown = guideData.delayTime
	else
		-- 无延迟 直接进入引导
		self:OnGuideEnter(guideStepId)
	end

end
--[[
@override
结束动作
--]]
function BaseGuideDriver:OnActionExit()
	self:OnGuideExit()
end
--[[
@override
动作进行中
@params dt number delta time
--]]
function BaseGuideDriver:OnActionUpdate(dt)
	if 0 < self.guideCountdown then
		self.guideCountdown = math.max(0, self.guideCountdown - dt)
		if 0 >= self.guideCountdown then
			-- 可以执行当前延迟的引导
			self:OnGuideEnter(self:GetCurrentGuideStepId())
		end
	end
end
--[[
@override
动作被打断
--]]
function BaseGuideDriver:OnActionBreak()
	
end
--[[
根据引导id执行引导
@params guideStepId int 引导id
--]]
function BaseGuideDriver:OnGuideEnter(guideStepId)
	-- 屏蔽触摸
	G_BattleLogicMgr:CIScenePauseGame()

	-- 引导真正开始
	self:SetIsGuideStart(true)

	-- 创建引导层
	local guideData = self:GetGuideStepDataById(guideStepId)
	self:CreateGuideView(guideData)
end
--[[
引导结束
--]]
function BaseGuideDriver:OnGuideExit()
	local currentGuideStepId = self:GetCurrentGuideStepId()
	local currentGuideStepData = self:GetGuideStepDataById(currentGuideStepId)

	-- 更新触发器
	self:UpdateActionTrigger(ConfigBattleGuideStepTriggerType.CONTINUE, self:GetCurrentGuideStepId())
	self:SetCurrentGuideStepId(nil)

	-- 引导结束
	self:SetIsInGuide(false)
	self:SetIsGuideStart(false)

	if not self:HasNextFrameGuideStep() then
		-- 隐藏节点
		self:HideAllGuideCover()

		-- 继续游戏
		G_BattleLogicMgr:CISceneResumeGame()
	end
end
--[[
@override
消耗做出行为需要的资源
@params guideStepId int 引导id
--]]
function BaseGuideDriver:CostActionResources(guideStepId)
	-- 将该引导步骤从等待队列中移除
	for i = #self.awaitGuideSteps, 1, -1 do
		if guideStepId == self.awaitGuideSteps[i] then
			table.remove(self.awaitGuideSteps, i)
		end
	end
end
---------------------------------------------------
-- guide control end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
创建引导层
@params guideStepData BattleGuideStepStruct 战斗单步引导信息
--]]
function BaseGuideDriver:CreateGuideView(guideStepData)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'CreateGuideView',
		guideStepData
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
隐藏所有引导遮罩节点
--]]
function BaseGuideDriver:HideAllGuideCover()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'HideAllGuideCover'
	)
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- trigger control begin --
---------------------------------------------------
--[[
@override
刷新触发器
@params triggerType ConfigBattleGuideStepTriggerType 触发类型
@params delta number 变化量
--]]
function BaseGuideDriver:UpdateActionTrigger(triggerType, delta)
	if ConfigBattleGuideStepTriggerType.TIME_AXIS == triggerType then

		-- 时间触发类型
		for i = #self.actionTrigger[triggerType], 1, -1 do
			local newCounter = math.max(0, self.actionTrigger[triggerType][i].counter - delta)
			self.actionTrigger[triggerType][i].counter = newCounter

			-- 是否可以触发
			if 0 >= newCounter then
				-- 插入待机队列
				self:AddAwaitGuideStep(self.actionTrigger[triggerType][i].guideStepId)
				-- 移除触发器
				table.remove(self.actionTrigger[triggerType], i)
			end
		end

	elseif ConfigBattleGuideStepTriggerType.CAST_SKILL == triggerType then
		-- 技能触发类型
		local skillId = delta
		if nil ~= self.actionTrigger[triggerType][tostring(skillId)] then
			for i = #self.actionTrigger[triggerType][tostring(skillId)], 1, -1 do
				-- 触发该引导
				-- 插入待机队列
				self:AddAwaitGuideStep(self.actionTrigger[triggerType][tostring(skillId)][i])
				-- 移除触发器
				table.remove(self.actionTrigger[triggerType][tostring(skillId)], i)
			end
		end

	elseif ConfigBattleGuideStepTriggerType.CHANT == triggerType then

		-- 技能触发类型
		local skillId = delta
		if nil ~= self.actionTrigger[triggerType][tostring(skillId)] then
			for i = #self.actionTrigger[triggerType][tostring(skillId)], 1, -1 do
				-- 触发该引导
				-- 插入待机队列
				self:AddAwaitGuideStep(self.actionTrigger[triggerType][tostring(skillId)][i])
				-- 移除触发器
				table.remove(self.actionTrigger[triggerType][tostring(skillId)], i)
			end
		end

	elseif ConfigBattleGuideStepTriggerType.CONTINUE == triggerType then

		-- 引导触发类型
		local endGuideStepId = delta
		if nil ~= self.actionTrigger[triggerType][tostring(endGuideStepId)] then
			-- 插入待机队列
			self:AddAwaitGuideStep(self.actionTrigger[triggerType][tostring(endGuideStepId)])
			-- 移除触发器
			self.actionTrigger[triggerType][tostring(endGuideStepId)] = nil
		end

	end
end
---------------------------------------------------
-- trigger control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据id获取引导配置
@params guideModuleId int 引导模块id
--]]
function BaseGuideDriver:GetGuideStepsConfig(guideModuleId)
	return StepAllInfos[tostring(guideModuleId)]
end
--[[
根据引导步骤id获取引导信息
@params guideStepId int 引导步骤id
@return _ BattleGuideStepStruct 引导数据
--]]
function BaseGuideDriver:GetGuideStepDataById(guideStepId)
	return self.guideSteps[tostring(guideStepId)]
end
--[[
向待机队列添加一步引导
@params guideStepId int 引导单步id
--]]
function BaseGuideDriver:AddAwaitGuideStep(guideStepId)
	table.insert(self.awaitGuideSteps, 1, guideStepId)
end











--[[
判断下一帧是否存在需要进行的引导
@return _ bool 
--]]
function BaseGuideDriver:HasNextFrameGuideStep()
	local nextGuideStepId = self:CanDoAction()
	if nextGuideStepId then
		local nextGuideStepData = self:GetGuideStepDataById(nextGuideStepId)
		if 0 >= checkint(nextGuideStepData.delayTime) then
			return true
		end
	end
	return false
end


------------ 是否在引导中 ------------
function BaseGuideDriver:GetIsInGuide()
	return self.isInGuide
end
function BaseGuideDriver:SetIsInGuide(b)
	self.isInGuide = b
end
function BaseGuideDriver:GetIsGuideStart()
	return self.isGuideStart
end
function BaseGuideDriver:SetIsGuideStart(b)
	self.isGuideStart = b
end

------------ 当前步引导 ------------
function BaseGuideDriver:GetCurrentGuideStepId()
	return self.currentGuideStepId
end
function BaseGuideDriver:SetCurrentGuideStepId(id)
	self.currentGuideStepId = id
end

---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseGuideDriver
