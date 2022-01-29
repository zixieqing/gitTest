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
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')

local stepAllInfos = CommonUtils.GetConfigAllMess('combatStep', 'guide')
------------ import ------------

------------ define ------------
-- 战斗单步引导类型
ConfigBattleGuideStepType = {
	BASE 					= 0, -- 默认
	ONLY_TEXT 				= 1, -- 纯文本
	NEED_TOUCH 				= 2  -- 需要点击
}

-- 战斗单步引导触发类型
ConfigBattleGuideStepTriggerType = {
	BASE 					= 0, -- 默认
	TIME_AXIS 				= 1, -- 时间点
	CAST_SKILL 				= 2, -- 施法
	CONTINUE 				= 3, -- 接上一步
	CHANT 					= 4, -- 读条
	CAN_CAST_SKILL 			= 5  -- 满足施法条件
}

-- 战斗单步引导结束类型
ConfigBattleGuideStepEndType = {
	BASE 					= 0, -- 默认
	TOUCH_ANYWHERE 			= 1, -- 点击任意位置
	TOUCH_APPOINTED 		= 2, -- 点击特定位置
	CLEAR_QTE_ICE 			= 3, -- 清除所有卡牌的qte冰块
	CLEAR_QTE_BECKON 		= 4, -- 清除场上所有的qte召唤物
	CLEAR_WEAK_POINT 		= 5  -- 点掉指定弱点
}

-- 战斗单步引导位置类型
ConfigBattleGuideStepHighlightType = {
	NONE 					= 0, -- 没有高亮区域
	UI 						= 1, -- ui死坐标
	BATTLE_ROOT 			= 2, -- 战场死坐标
	OBJECT_ALL 				= 3, -- 战斗物体整体
	OBJECT_HP_BAR 			= 4, -- 战斗物体血条
	OBJECT_WEAK_POINT 		= 5, -- 战斗物体弱点
	OBJECT_EXPRESSION 		= 6  -- 战斗物体表情
}

-- 战斗单步引导ui系id
ConfigBattleGuideStepUIId = {
	BASE 					= 0, -- 基础
	PAUSE_BTN 				= 1, -- 暂停按钮
	PLAYER_SKILL_ALL 		= 2, -- 主角技全部区域
	PLAYER_SKILL_ENERGY 	= 3, -- 主角技能量
	PLAYER_SKILL_ICON 		= 4, -- 主角技图标
	ACCELERATE_BTN 			= 5, -- 加速按钮
	CONNECT_SKILL_ICON 		= 6, -- 连携技图标
	WAVE_ICON 				= 7, -- 回合数
	TIME_ICON 				= 8, -- 时间
	WEATHER_ICON 			= 9  -- 天气
}

-- 战斗单步引导战场系id
ConfigBattleGuideStepBattleRootId = {
	BASE 					= 0, -- 基础
	FRIEND_ALL 				= 1, -- 高亮所有友方
	ENEMY_ALL 				= 2, -- 高亮所有敌方
	QTE_ALL 				= 3  -- 高亮所有qte单位
}

-- 战斗单步引导素材类型
ConfigBattleGuideStepGodType = {
	BASE 					= 0, -- 基础
	TEACHER 				= 1, -- 小笼包老师
	FINGER 					= 2, -- 手指
}

-- 战斗单步引导高亮形状类型
ConfigBattleGuideStepHighlightShapeType = {
	BASE 					= 0, -- 基础
	ICE 					= 1, -- 冰块
	CIRCLE					= 2, -- 圆
	SQUARE					= 3  -- 方块
}

local OFFSETY = 150
local OFFSETBOTTOM = 60
local WIDTH = 20
local positionInfos = {
    ['1'] = {ap = display.LEFT_TOP, po = cc.p(0, display.height - OFFSETY)},
    ['2'] = {ap = display.LEFT_CENTER, po = cc.p(0, display.cy)},
    ['3'] = {ap = display.LEFT_BOTTOM, po = cc.p(0, OFFSETBOTTOM)},
    ['4'] = {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height - OFFSETY)},
    ['5'] = {ap = display.CENTER, po = cc.p(display.cx, display.cy)},
    ['6'] = {ap = display.CENTER_BOTTOM, po = cc.p(display.cx, OFFSETBOTTOM)},
    ['7'] = {ap = display.RIGHT_TOP, po = cc.p(display.width, display.height - OFFSETY)},
    ['8'] = {ap = display.RIGHT_CENTER, po = cc.p(display.width, display.cy)},
    ['9'] = {ap = display.RIGHT_BOTTOM, po = cc.p(display.width, OFFSETBOTTOM)},
}
------------ define ------------

--[[
constructor
--]]
function BaseGuideDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)
	local args = unpack({...})

	self.guideModuleId = args.guideModuleId

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

	------------ 引导层viewnode ------------
	-- 引导层root节点
	self.guideRootNode = nil
	-- 引导层全屏裁剪节点
	self.guideClipNode = nil
	-- 引导层遮罩节点
	self.guideCoverNode = nil
	-- 引导精灵
	self.guideGodTeacher = nil
	-- 引导手指
	self.guideGodFinger = nil
	-- 引导手指说明文字底版
	self.guideGodFingerDescrBg = nil
	-- 卡牌高亮衬底遮罩
	self.guideObjHighlightNode = nil
	------------ 引导层viewnode ------------

	self.touchListener_ = nil

 	-- 初始化引导数据结构
	self:InitBattleGuide()
	-- 初始化引导高亮区域映射
	self:InitHighlightNodeMap()
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
--[[
初始化高亮节点映射
--]]
function BaseGuideDriver:InitHighlightNodeMap()
	local m = {
		[ConfigBattleGuideStepHighlightType.UI] = {
			[ConfigBattleGuideStepUIId.PAUSE_BTN] 				= BMediator:GetViewComponent().viewData.pauseButton,
			[ConfigBattleGuideStepUIId.PLAYER_SKILL_ALL] 		= BMediator:GetViewComponent().viewData.playerSkillBg,
			[ConfigBattleGuideStepUIId.PLAYER_SKILL_ENERGY] 	= BMediator:GetViewComponent().viewData.playerEnergyBar,
			[ConfigBattleGuideStepUIId.PLAYER_SKILL_ICON] 		= BMediator:GetViewComponent().viewData.playerSkillIcons,
			[ConfigBattleGuideStepUIId.ACCELERATE_BTN] 			= BMediator:GetViewComponent().viewData.accelerateButton,
			[ConfigBattleGuideStepUIId.CONNECT_SKILL_ICON] 		= nil,
			[ConfigBattleGuideStepUIId.WAVE_ICON] 				= BMediator:GetViewComponent().viewData.waveLabel,
			[ConfigBattleGuideStepUIId.TIME_ICON] 				= BMediator:GetViewComponent().viewData.battleTimeLabel,
			[ConfigBattleGuideStepUIId.WEATHER_ICON] 			= BMediator:GetViewComponent().viewData.weatherIcons
		},
		[ConfigBattleGuideStepHighlightType.BATTLE_ROOT] = {
			[ConfigBattleGuideStepBattleRootId.FRIEND_ALL] 		= self:CalcFriendFormationRect(),
			[ConfigBattleGuideStepBattleRootId.ENEMY_ALL] 		= self:CalcEnemyFormationRect(),
			[ConfigBattleGuideStepBattleRootId.QTE_ALL] 		= self:CalcBeckonFormationRect()
		}
	}

	self.highlightMap = m
end
--[[
注销触摸监听
--]]
function BaseGuideDriver:UnregistTouchListener()
	if nil ~= self.touchListener_ and nil ~= self.guideRootNode then
		self.guideRootNode:getEventDispatcher():removeEventListener(self.touchListener_)
		self.touchListener_ = nil
	end
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
	-- 暂停游戏
	BMediator:PauseTimer()
	BMediator:PauseNormalCIScene()
	BMediator:PauseBattleObjs()
	BMediator:SetBattleTouchEnable(false)

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

	-- 移除高亮obj
	self:RemoveAllHighlightObj(currentGuideStepData.highlightType, currentGuideStepData.highlightId)

	-- 更新触发器
	self:UpdateActionTrigger(ConfigBattleGuideStepTriggerType.CONTINUE, self:GetCurrentGuideStepId())
	self:SetCurrentGuideStepId(nil)

	-- 引导结束
	self:SetIsInGuide(false)
	self:SetIsGuideStart(false)

	if not self:GetNextFrameGuideStep() then
		-- 隐藏节点
		self:HideAllGuideCover()

		-- 继续游戏
		BMediator:ResumeTimer()
		BMediator:ResumeNormalCIScene()
		BMediator:ResumeBattleObjs()
		BMediator:SetBattleTouchEnable(true)
	end

	-- 发送一次事件
	if ConfigBattleGuideStepEndType.TOUCH_APPOINTED == currentGuideStepData.endType then

		-- 由于暂停逻辑和屏蔽触摸的原因这里手动发送一次事件
		self:SendTouchForHighlightArea(currentGuideStepId)

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

	if nil == self.guideRootNode then
		local coverOpacity = 150

		-- root 节点
		local guideRootNode = display.newLayer(0, 0, {size = display.size})
		-- guideRootNode:setBackgroundColor(cc.c4b(0, 0, 0, 150))
		BMediator:GetViewComponent():addChild(guideRootNode, BATTLE_E_ZORDER.GUIDE)

		self.guideRootNode = guideRootNode

		------------ 初始化触摸 ------------
		self.touchListener_ = cc.EventListenerTouchOneByOne:create()
		self.touchListener_:setSwallowTouches(false)
		self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
	    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
	    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
	    self.touchListener_:registerScriptHandler(handler(self, self.onTouchCanceled_), cc.Handler.EVENT_TOUCH_CANCELLED)
	    self.guideRootNode:getEventDispatcher():addEventListenerWithFixedPriority(self.touchListener_, -1)
		------------ 初始化触摸 ------------

		-- -- debug --
		-- local rect = self.ttt[ConfigBattleGuideStepHighlightType.BATTLE_ROOT][ConfigBattleGuideStepBattleRootId.QTE_ALL]
		-- dump(rect)
		-- local layer = display.newLayer(rect.x, rect.y, {size = cc.size(rect.width, rect.height)})
		-- layer:setBackgroundColor(cc.c4b(255, 128, 0, 100))
		-- BMediator:GetBattleRoot():addChild(layer, 11111)
		-- -- debug -- 

		-- 裁剪节点
		local guideClipNode = cc.ClippingNode:create()
		guideClipNode:setAnchorPoint(cc.p(0, 0))
		guideClipNode:setPosition(cc.p(0, 0))
		guideRootNode:addChild(guideClipNode)

		self.guideClipNode = guideClipNode

		local tmpStencilNode = cc.Node:create()
		guideClipNode:setAlphaThreshold(0.1)
		guideClipNode:setInverted(true)
		guideClipNode:setStencil(tmpStencilNode)

		-- 遮罩层
		local guideCoverNode = display.newLayer(0, 0, {size = display.size, color = '#000000'})
		-- guideCoverNode:setBackgroundColor(cc.c4b(0, 0, 0, coverOpacity))
		guideCoverNode:setOpacity(coverOpacity)
		guideClipNode:addChild(guideCoverNode)

		self.guideCoverNode = guideCoverNode

		-- 创建卡牌高亮衬底
		local battleRootNode = BMediator:GetBattleRoot()
		local guideObjHighlightNode = CColorView:create(cc.c4b(0, 0, 0, coverOpacity))
		guideObjHighlightNode:setContentSize(display.size)
		guideObjHighlightNode:setAnchorPoint(cc.p(0.5, 0.5))
		guideObjHighlightNode:setPosition(utils.getLocalCenter(battleRootNode))
		battleRootNode:addChild(guideObjHighlightNode, BATTLE_E_ZORDER.SPECIAL_EFFECT)
		-- guideObjHighlightNode:setVisible(false)

		self.guideObjHighlightNode = guideObjHighlightNode

	else

		self.guideRootNode:setVisible(true)

	end

	-- 创建高亮区域
	self:AddGuideHighlight(
		guideStepData.highlightType,
		guideStepData.highlightId,
		guideStepData.highlightIndex,
		guideStepData.highlightSize,
		guideStepData.highlightShapeType
	)

	-- 创建guide god
	self:AddGuideGod(
		guideStepData.guideStepType,
		guideStepData.guideContent,
		guideStepData.guideGodType,
		guideStepData.guideGodLocationId
	)

end
--[[
创建高亮区域
@params highlightType ConfigBattleGuideStepHighlightType 高亮类型
@params highlightId ... 高亮主体id
@params highlightIndex list 高亮主体序号
@params highlightSize cc.size 高亮主体大小
@params highlightShapeType ConfigBattleGuideStepHighlightShapeType 高亮形状
--]]
function BaseGuideDriver:AddGuideHighlight(highlightType, highlightId, highlightIndex, highlightSize, highlightShapeType)
	if nil == self.guideClipNode then return end

	if ConfigBattleGuideStepHighlightType.BATTLE_ROOT == highlightType or
		ConfigBattleGuideStepHighlightType.OBJECT_ALL == highlightType then

		-- 这两种类型是高亮战斗物体 特殊处理
		self:AddGuideObjHighlight(highlightType, highlightId)
		return

	else

		-- 设置裁剪层可见
		self.guideClipNode:setVisible(true)
		self.guideObjHighlightNode:setVisible(false)

	end

	local fixedHighlightRect = self:GetFixedHighlightRect(highlightType, highlightId, highlightIndex)
	local padding = 15

	local path = string.format('ui/guide/guide_ico_shape_%d.png', highlightShapeType)
	local stencilNode = nil

	if ConfigBattleGuideStepHighlightShapeType.SQUARE == highlightShapeType then

		-- 矩形 九缩会导致移动端坐标错位 这里使用强拉
		stencilNode = display.newImageView(_res(path), 0, 0)
		local oriSize = stencilNode:getContentSize()
		stencilNode:setScaleX((fixedHighlightRect.width + padding) / oriSize.width)
		stencilNode:setScaleY((fixedHighlightRect.height + padding) / oriSize.height)

		stencilNode:setAnchorPoint(cc.p(0.5, 0.5))
		stencilNode:setPosition(cc.p(fixedHighlightRect.x + fixedHighlightRect.width * 0.5, fixedHighlightRect.y + fixedHighlightRect.height * 0.5))

	elseif ConfigBattleGuideStepHighlightShapeType.CIRCLE == highlightShapeType then

		-- 圆形 强拉 但保持圆形
		stencilNode = display.newImageView(_res(path), 0, 0)
		stencilNode:setScale(((fixedHighlightRect.width + fixedHighlightRect.height) * 0.5 + padding) / stencilNode:getContentSize().width)

		stencilNode:setAnchorPoint(cc.p(0.5, 0.5))
		stencilNode:setPosition(cc.p(fixedHighlightRect.x + fixedHighlightRect.width * 0.5, fixedHighlightRect.y + fixedHighlightRect.height * 0.5))

	elseif ConfigBattleGuideStepHighlightShapeType.ICE == highlightShapeType then

		-- 冰块型 不缩放
		stencilNode = display.newImageView(_res(path), 0, 0)

		stencilNode:setAnchorPoint(cc.p(0.5, 0))
		stencilNode:setPosition(cc.p(fixedHighlightRect.x + fixedHighlightRect.width * 0.5, fixedHighlightRect.y))

	end

	self.guideClipNode:setStencil(stencilNode)
end
--[[
添加战斗物体高亮
@params highlightType ConfigBattleGuideStepHighlightType 高亮类型
@params highlightId ... 高亮主体id
--]]
function BaseGuideDriver:AddGuideObjHighlight(highlightType, highlightId)
	self.guideObjHighlightNode:setVisible(true)
	self.guideClipNode:setVisible(false)

	if ConfigBattleGuideStepHighlightType.BATTLE_ROOT == highlightType then

		local targets = nil
		if ConfigBattleGuideStepBattleRootId.FRIEND_ALL == highlightId then

			-- 高亮所有友方物体
			targets = BMediator:GetBData().sortBattleObjs.friend

		elseif ConfigBattleGuideStepBattleRootId.ENEMY_ALL == highlightId then

			-- 高亮所有敌方物体
			targets = BMediator:GetBData().sortBattleObjs.enemy

		elseif ConfigBattleGuideStepBattleRootId.QTE_ALL == highlightId then

			-- 高亮所有qte召唤物物体
			targets = BMediator:GetBData().sortBattleObjs.beckonObj

		end

		local obj = nil
		for i = #targets, 1, -1 do
			obj = targets[i]
			self:AddAHighlightObj(obj:getOTag())
		end

	elseif ConfigBattleGuideStepHighlightType.OBJECT_ALL == highlightType then

		-- 高亮单个obj
		local cardId = highlightId
		local obj = BMediator:IsObjAliveByCardId(cardId)
		if nil ~= obj then
			self:AddAHighlightObj(obj:getOTag())
		end

	end

end
--[[
根据tag将一个战斗物体高亮
@params tag int tag
--]]
function BaseGuideDriver:AddAHighlightObj(tag)
	local obj = BMediator:IsObjAliveByTag(tag)
	if nil ~= obj then
		obj:setHighlight(true)
		obj:updateLocation()
	end
end
--[[
创建guide god
@params guideStepType ConfigBattleGuideStepType 引导类型
@params guideContent string 引导提示文字
@params guideGodType ConfigBattleGuideStepGodType 引导主体类型
@params guideGodLocationId int 引导主体位置
--]]
function BaseGuideDriver:AddGuideGod(guideStepType, guideContent, guideGodType, guideGodLocationId)
	if ConfigBattleGuideStepGodType.TEACHER == guideGodType then

		self:AddGuideGodTeacher(guideContent, guideGodLocationId)

		if nil ~= self.guideGodFinger then
			self.guideGodFinger:setVisible(false)
			self.guideGodFingerDescrBg:setVisible(false)
		end

	elseif ConfigBattleGuideStepGodType.FINGER == guideGodType then

		self:AddGuideGodFinger(guideContent, guideGodLocationId)

		if nil ~= self.guideGodTeacher then
			self.guideGodTeacher:setVisible(false)
		end

	end
end
--[[
刷新小笼包老师
@params guideContent string 引导提示文字
@params guideGodLocationId int 引导主体位置
--]]
function BaseGuideDriver:AddGuideGodTeacher(guideContent, guideGodLocationId)
	if nil == self.guideRootNode then return end

	local parentNode = self.guideRootNode
	local locationInfo = self:GetFixedGuideGodLocationInfo(guideGodLocationId)

	local contentWidth = 348
	local fontSize = 24
	local contentHight = 100
	local contentLength = string.utf8len(tostring(guideContent))
	if contentLength > 0 then
		local lines = math.floor(contentLength / 16) + 1
		local height = lines * fontSize + (lines - 1) * 8
		contentHight = math.max(contentHight, height)
	end
	local richLabelC = self.GetFixedGuideStr(guideContent)

	if nil == self.guideGodTeacher then
		-- 基础layer
		local godLayer = display.newLayer(0, 0, {size = locationInfo.frameSize})
		-- godLayer:setBackgroundColor(cc.c4b(64, 128, 255, 100))
		-- display.commonUIParams(godLayer, locationInfo.frameLocation)
		parentNode:addChild(godLayer, 10)

		-- 小笼包老师
		local teacherNode = display.newNSprite(_res('ui/guide/guide_ico_pet.png'), 0, 0)
		godLayer:addChild(teacherNode, 10)
		teacherNode:setTag(3)

		-- 文字描述
		local descrBg = display.newImageView(_res('ui/guide/guide_bg_text.png'), 0, 0, {scale9 = true, size = cc.size(contentWidth, contentHight + 30)})
		godLayer:addChild(descrBg)
		descrBg:setTag(5)

		-- 文字
		local descrLabel = nil
		if BattleConfigUtils:UseElexLocalize() then
			descrLabel = display.newLabel(0, 0, fontWithColor("15", {w = 300, fontSize = 24, text = ''}))
		else
			descrLabel = display.newRichLabel(0, 0, {w = 27})
		end
		descrBg:addChild(descrLabel)
		descrLabel:setTag(3)

		-- 箭头
		local arrow = display.newNSprite(_res('ui/guide/guide_ico_text'), 0, 0)
		descrBg:addChild(arrow)
		arrow:setTag(5)

		self.guideGodTeacher = godLayer
	else

		self.guideGodTeacher:setVisible(true)

	end

	-- 刷新内容
	display.commonUIParams(self.guideGodTeacher, locationInfo.frameLocation)

	local teacherNode = self.guideGodTeacher:getChildByTag(3)
	teacherNode:setFlippedX(locationInfo.godScale.x == -1)
	teacherNode:setFlippedY(locationInfo.godScale.y == -1)
	display.commonUIParams(teacherNode, locationInfo.godLocation)

	local descrBg = self.guideGodTeacher:getChildByTag(5)
	descrBg:setContentSize(cc.size(contentWidth, contentHight + 30))
	display.commonUIParams(descrBg, locationInfo.descrBgLocation)

	local descrLabel = descrBg:getChildByTag(3)
	if BattleConfigUtils:UseElexLocalize() then
		descrLabel:setString(richLabelC)

	    local lheight = display.getLabelContentSize(descrLabel).height
	    local twidth = descrBg:getContentSize().width
	    descrBg:setContentSize(cc.size(twidth, lheight + 50))
	    display.commonUIParams(descrLabel, {ap = cc.p(0, 1), po = cc.p(16, descrBg:getContentSize().height - 14)})
	else
		display.commonUIParams(descrLabel, {ap = cc.p(0, 1), po = cc.p(16, descrBg:getContentSize().height - 14)})
		display.reloadRichLabel(descrLabel, {c = richLabelC})
	end
	
	local arrow = descrBg:getChildByTag(5)
	arrow:setFlippedX(locationInfo.arrowScale.x == -1)
	arrow:setFlippedY(locationInfo.arrowScale.y == -1)
	display.commonUIParams(arrow, locationInfo.arrowLocation)

end
--[[
刷新手指
@params guideContent string 引导提示文字
@params guideGodLocationId int 引导主体位置
--]]
function BaseGuideDriver:AddGuideGodFinger(guideContent, guideGodLocationId)
	if nil == self.guideRootNode then return end

	local locationInfo = self:GetFixedGuideFingerLocationInfo(guideGodLocationId)

	local richLabelC = self.GetFixedGuideStr(guideContent, 23)

	if nil == self.guideGodFinger then

		-- 手指
		local guideGodFinger = sp.SkeletonAnimation:create('ui/guide/guide_ico_hand.json', 'ui/guide/guide_ico_hand.atlas', 1)
		guideGodFinger:setAnimation(0, 'idle', true)
		self.guideRootNode:addChild(guideGodFinger, 10)
		guideGodFinger:setPosition(display.center)

		self.guideGodFinger = guideGodFinger

		-- 文字底版
		local descrBg = display.newImageView(_res('ui/guide/common_bg_tips'), 0, 0, {scale9 = true, size = locationInfo.descrBgSize})
		self.guideRootNode:addChild(descrBg, 9)
		self.guideGodFingerDescrBg = descrBg

		-- 文字
		local descrLabel = nil
		if BattleConfigUtils:UseElexLocalize() then
			descrLabel = display.newLabel(0, 0, fontWithColor("15", {w = 300, fontSize = 24, text = ''}))
		else
			descrLabel = display.newRichLabel(0, 0, {w = 30})
		end
		descrBg:addChild(descrLabel)
		descrLabel:setTag(3)

	else

		self.guideGodFinger:setVisible(true)
		self.guideGodFingerDescrBg:setVisible(true)

	end


	self.guideGodFinger:setScaleX(locationInfo.fingerScale.x)
	self.guideGodFinger:setScaleY(locationInfo.fingerScale.y)
	display.commonUIParams(self.guideGodFinger, locationInfo.fingerLocation)

	display.commonUIParams(self.guideGodFingerDescrBg, locationInfo.descrBgLocation)

	local descrLabel = self.guideGodFingerDescrBg:getChildByTag(3)
	display.commonUIParams(descrLabel, {ap = display.LEFT_TOP, po = cc.p(16, 100)})
	if BattleConfigUtils:UseElexLocalize() then
		descrLabel:setString(richLabelC)
	else
		display.reloadRichLabel(descrLabel, {c = richLabelC})
	end
end
--[[
隐藏所有引导遮罩节点
--]]
function BaseGuideDriver:HideAllGuideCover()
	self.guideRootNode:setVisible(false)
	self.guideObjHighlightNode:setVisible(false)
end
--[[
移除所有obj高亮
@params highlightType ConfigBattleGuideStepHighlightType 高亮类型
@params highlightId ... 高亮主体id
--]]
function BaseGuideDriver:RemoveAllHighlightObj(highlightType, highlightId)
	if ConfigBattleGuideStepHighlightType.BATTLE_ROOT == highlightType then

		local targets = nil
		if ConfigBattleGuideStepBattleRootId.FRIEND_ALL == highlightId then

			-- 高亮所有友方物体
			targets = BMediator:GetBData().sortBattleObjs.friend

		elseif ConfigBattleGuideStepBattleRootId.ENEMY_ALL == highlightId then

			-- 高亮所有敌方物体
			targets = BMediator:GetBData().sortBattleObjs.enemy

		elseif ConfigBattleGuideStepBattleRootId.QTE_ALL == highlightId then

			-- 高亮所有qte召唤物物体
			targets = BMediator:GetBData().sortBattleObjs.beckonObj

		end

		local obj = nil
		for i = #targets, 1, -1 do
			obj = targets[i]
			self:RemoveAHighlightObj(obj:getOTag())
		end

	elseif ConfigBattleGuideStepHighlightType.OBJECT_ALL == highlightType then

		-- 高亮单个obj
		local cardId = highlightId
		local obj = BMediator:IsObjAliveByCardId(cardId)
		if nil ~= obj then
			self:RemoveAHighlightObj(obj:getOTag())
		end

	end
end
--[[
根据tag移除一个obj高亮
@params tag int 战斗物体tag
--]]
function BaseGuideDriver:RemoveAHighlightObj(tag)
	local obj = BMediator:IsObjAliveByTag(tag)
	if nil ~= obj then
		obj:setHighlight(false)
		obj:updateLocation()
	end
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
-- touch handler begin --
---------------------------------------------------
function BaseGuideDriver:onTouchBegan_(touch, event)

	-- 如果游戏结束直接跳过逻辑
	local gameState = BMediator:GetGState()
	if GState.TRANSITION == gameState or
		GState.OVER == gameState or 
		GState.SUCCESS == gameState or
		GState.FAIL == gameState  then

		return false

	end

	local needEnd = self:TouchHandler(touch)

	local canEndGuide = self:CanEndGuide(touch)
	if canEndGuide then
		self:OnActionExit()
	end

	return needEnd
end
function BaseGuideDriver:onTouchMoved_(touch, event)

end
function BaseGuideDriver:onTouchEnded_(touch, event)
	-- 屏蔽触摸
	if self:GetIsInGuide() and self:GetIsGuideStart() then
		BMediator:SetBattleTouchEnable(false)
	end
end
function BaseGuideDriver:onTouchCanceled_(touch, event)
	print('here touch canceled by some unknown reason')
end
--[[
点击事件处理
@params touch 触摸
@return _ bool 是否需要走touch end逻辑
--]]
function BaseGuideDriver:TouchHandler(touch)
	local currentGuideStepId = self:GetCurrentGuideStepId()

	if nil == currentGuideStepId then return false end

	local currentGuideStepData = self:GetGuideStepDataById(currentGuideStepId)

	if ConfigBattleGuideStepEndType.CLEAR_QTE_ICE == currentGuideStepData.endType then

		if self:TouchedHighlightArea(touch) then
			-- 允许一次触摸
			BMediator:SetBattleTouchEnable(true)
			return true
		end

	elseif ConfigBattleGuideStepEndType.CLEAR_QTE_BECKON == currentGuideStepData.endType then

		if self:TouchedHighlightArea(touch) then
			-- 允许一次触摸
			BMediator:SetBattleTouchEnable(true)
			return true
		end

	elseif ConfigBattleGuideStepEndType.CLEAR_WEAK_POINT == currentGuideStepData.endType then

		if self:TouchedHighlightArea(touch) then
			-- 允许一次触摸
			BMediator:SetBattleTouchEnable(true)
			return true
		end

	end

	return false

end
--[[
检查是否可以结束引导
@params touch 触摸
@return _ bool 是否可以结束引导
--]]
function BaseGuideDriver:CanEndGuide(touch)
	if not self:GetIsGuideStart() then return false end

	local p = touch:getLocation()
	local currentGuideStepId = self:GetCurrentGuideStepId()

	if nil == currentGuideStepId then return false end

	local currentGuideStepData = self:GetGuideStepDataById(currentGuideStepId)

	if ConfigBattleGuideStepEndType.TOUCH_ANYWHERE == currentGuideStepData.endType then

		return true

	elseif ConfigBattleGuideStepEndType.TOUCH_APPOINTED == currentGuideStepData.endType or
		ConfigBattleGuideStepEndType.CLEAR_WEAK_POINT == currentGuideStepData.endType then

		return self:TouchedHighlightArea(touch)

	elseif ConfigBattleGuideStepEndType.CLEAR_QTE_ICE == currentGuideStepData.endType then

		------------ new all ice ------------
		-- 判断所有友军卡牌的冰块是否被移除
		local targets = BMediator:GetBData().sortBattleObjs.friend
		local obj = nil

		for i = #targets, 1, -1 do
			obj = targets[i]
			if obj:hasQTE() then
				return false
			end
		end

		return true
		------------ new all ice ------------

		------------ old single ice ------------
		-- -- 判断高亮物体的冰块是否被移除
		-- local cardId = currentGuideStepData.highlightId
		-- local obj = BMediator:IsObjAliveByCardId(cardId)
		-- if nil ~= obj and not obj:hasQTE() then
		-- 	return true
		-- end
		------------ old single ice ------------

	elseif ConfigBattleGuideStepEndType.CLEAR_QTE_BECKON == currentGuideStepData.endType then

		-- 判断召唤物是否被全部清除
		if 0 >= #BMediator:GetBData().sortBattleObjs.beckonObj then
			return true
		end

	end

	return false
end
--[[
是否触摸到了高亮区域
@params touch 触摸
@return _ bool 
--]]
function BaseGuideDriver:TouchedHighlightArea(touch)
	if not self:GetIsGuideStart() then return false end

	local p = touch:getLocation()

	local currentGuideStepData = self:GetGuideStepDataById(self:GetCurrentGuideStepId())

	if ConfigBattleGuideStepHighlightType.OBJECT_ALL == currentGuideStepData.highlightType then

		-- 高亮类型是单个obj 处理一次obj的碰撞判定
		local cardId = currentGuideStepData.highlightId
		local obj = BMediator:IsObjAliveByCardId(cardId)
		if nil ~= obj then
			return self:TouchedHighlightObj(obj:getOTag(), touch)
		else
			return false
		end

	elseif ConfigBattleGuideStepHighlightType.BATTLE_ROOT == currentGuideStepData.highlightType then

		-- 高亮类型是战场位置 判断一次所有物体碰撞
		local targets = nil
		if ConfigBattleGuideStepBattleRootId.FRIEND_ALL == currentGuideStepData.highlightId then

			-- 高亮所有友方物体
			targets = BMediator:GetBData().sortBattleObjs.friend

		elseif ConfigBattleGuideStepBattleRootId.ENEMY_ALL == currentGuideStepData.highlightId then

			-- 高亮所有敌方物体
			targets = BMediator:GetBData().sortBattleObjs.enemy

		elseif ConfigBattleGuideStepBattleRootId.QTE_ALL == currentGuideStepData.highlightId then

			-- 高亮所有qte召唤物物体
			targets = BMediator:GetBData().sortBattleObjs.beckonObj

		end

		local obj = nil
		for i = #targets, 1, -1 do
			obj = targets[i]
			if true == self:TouchedHighlightObj(obj:getOTag(), touch) then
				return true
			end
		end

		return false

	else

		-- 正常裁剪类型
		local highlightRect = self:GetHighlightArea()
		local currentHighlightShape = self:GetHighlightShape()

		if ConfigBattleGuideStepHighlightShapeType.CIRCLE == currentHighlightShape then

			local c = cc.p(
				highlightRect.x + highlightRect.width * 0.5,
				highlightRect.y + highlightRect.height * 0.5
			)
			local deltaP = cc.pSub(p, c)
			local dis = deltaP.x * deltaP.x + deltaP.y * deltaP.y
			if dis <= highlightRect.width * highlightRect.width * 0.25 then
				return true
			else
				return false
			end

		else

			return cc.rectContainsPoint(highlightRect, p)

		end

		return false

	end

end
--[[
根据tag和touch判断是否触摸到了obj
@params tag int obj tag
@params touch 触摸
@return _ bool 是否触摸到了高亮物体
--]]
function BaseGuideDriver:TouchedHighlightObj(tag, touch)
	local obj = BMediator:IsObjAliveByTag(tag)
	if nil ~= obj then
		local p = touch:getLocation()
		local objViewBox = obj.view.viewComponent:getAvatarStaticViewBox()

		local fixedP = obj.view.viewComponent:convertToNodeSpace(p)

		return cc.rectContainsPoint(objViewBox, fixedP)

	else
		return false
	end
end
--[[
为高亮按钮模拟一次触摸逻辑
@params currentGuideStepId int 需要触发的引导步骤id
--]]
function BaseGuideDriver:SendTouchForHighlightArea(currentGuideStepId)
	if nil == currentGuideStepId then return end
	local guideStepData = self:GetGuideStepDataById(currentGuideStepId)
	local highlightType = guideStepData.highlightType
	local highlightId = guideStepData.highlightId
	local highlightIndex = guideStepData.highlightIndex

	if ConfigBattleGuideStepUIId.PLAYER_SKILL_ICON == highlightId then

		local targetNodes = self.highlightMap[highlightType][highlightId]
		local index = nil
		local targetNode = nil
		local playerObj = BMediator:GetPlayerObj(false)

		for i,v in ipairs(highlightIndex) do
			index = checkint(v)
			targetNode = targetNodes[index].playerSkillButton

			if nil ~= targetNode and nil ~= playerObj then
				playerObj:playerSkillButtonClickHandler(targetNode)
			end
		end


	elseif ConfigBattleGuideStepUIId.CONNECT_SKILL_ICON == highlightId then

		local index = nil
		local targetNode = nil

		for i,v in ipairs(highlightIndex) do
			index = checkint(v)
			targetNode = BMediator:GetConnectButtonByIndex(index)

			if nil ~= targetNode then
				targetNode:ClickCallback(targetNode.viewData.skillIconBg)
			end
		end

	end
end
---------------------------------------------------
-- touch handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据id获取引导配置
@params guideModuleId int 引导模块id
--]]
function BaseGuideDriver:GetGuideStepsConfig(guideModuleId)
	return stepAllInfos[tostring(guideModuleId)]
end
--[[
根据引导步骤id获取引导信息
@params guideStepId int 引导步骤id
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
计算表示友方的大圈
@return _ cc.rect 表示友方范围的大圈
--]]
function BaseGuideDriver:CalcFriendFormationRect()
	local avatarSize = cc.size(150, 250)

	local lb = cc.p(display.width, display.height)
	local rt = cc.p(0, 0)

	local p = nil
	for i,v in ipairs(BattleFormation) do
		p = BMediator:GetCellPosByRC(v.r, v.c)
		lb.x = math.min(p.cx, lb.x)
		lb.y = math.min(p.cy, lb.y)
		rt.x = math.max(p.cx, rt.x)
		rt.y = math.max(p.cy, rt.y)
	end

	return cc.rect(
		lb.x - avatarSize.width * 0.5,
		lb.y,
		rt.x - lb.x + avatarSize.width,
		(rt.y + avatarSize.height) - lb.y
	)
end
--[[
计算表示敌方的大圈
@return _ cc.rect 表示友方范围的大圈
--]]
function BaseGuideDriver:CalcEnemyFormationRect()
	local friendFormatRect = self:CalcFriendFormationRect()
	local battleArea = BMediator:GetBConf().BATTLE_AREA
	local battleMiddleX = battleArea.x + battleArea.width * 0.5
	local fixedX = battleMiddleX + (battleMiddleX - (friendFormatRect.x + friendFormatRect.width))

	return cc.rect(
		fixedX,
		friendFormatRect.y,
		friendFormatRect.width,
		friendFormatRect.height
	)
end
--[[
计算表示qte的大圈
--]]
function BaseGuideDriver:CalcBeckonFormationRect()
	local battleArea = BMediator:GetBConf().BATTLE_AREA

	return cc.rect(
		battleArea.x + battleArea.width - 150,
		battleArea.y,
		100,
		battleArea.height + 100
	)
end
--[[
获取高亮区域的中心点修正rect
@params highlightType ConfigBattleGuideStepHighlightType 高亮类型
@params highlightId ... 高亮主体id
@params highlightIndex list 高亮主体序号
@return rect cc.rect 修正rect
--]]
function BaseGuideDriver:GetFixedHighlightRect(highlightType, highlightId, highlightIndex)

	if ConfigBattleGuideStepHighlightType.UI == highlightType then
		
		return self:GetHighlightUI(highlightType, highlightId, highlightIndex)

	elseif ConfigBattleGuideStepHighlightType.BATTLE_ROOT == highlightType then

		return self:GetHighlightBattle(highlightType, highlightId, highlightIndex)

	else

		return self:GetHighlightCard(highlightType, highlightId, highlightIndex)
		
	end

end
--[[
获取ui层的高亮修正
@params highlightType ConfigBattleGuideStepHighlightType 高亮类型
@params highlightId ... 高亮主体id
@params highlightIndex list 高亮主体序号
@return rect cc.rect 修正rect
--]]
function BaseGuideDriver:GetHighlightUI(highlightType, highlightId, highlightIndex)

	if ConfigBattleGuideStepUIId.PLAYER_SKILL_ICON == highlightId then

		local lb = cc.p(display.width, display.height)
		local rt = cc.p(0, 0)
		local targetNodes = self.highlightMap[highlightType][highlightId]
		local index = nil
		local targetNode = nil

		for i,v in ipairs(highlightIndex) do
			index = checkint(v)
			targetNode = targetNodes[index].playerSkillIconFrame

			local rect = self:GetTargetNodeRect(targetNode)
			lb.x = math.min(rect.x, lb.x)
			lb.y = math.min(rect.y, lb.y)
			rt.x = math.max(rect.x + rect.width, rt.x)
			rt.y = math.max(rect.y + rect.height, rt.y)
		end

		local rect = cc.rect(lb.x, lb.y, rt.x - lb.x, rt.y - lb.y)
		local fixedPos = self.guideClipNode:convertToNodeSpace(targetNode:getParent():convertToWorldSpace(cc.p(rect.x, rect.y)))
		return cc.rect(
			fixedPos.x,
			fixedPos.y,
			rect.width,
			rect.height
		)

	elseif ConfigBattleGuideStepUIId.CONNECT_SKILL_ICON == highlightId then

		local lb = cc.p(display.width, display.height)
		local rt = cc.p(0, 0)
		local index = nil
		local targetNode = nil
		local parentNode = nil

		for i,v in ipairs(highlightIndex) do
			index = checkint(v)
			targetNode = BMediator:GetConnectButtonByIndex(index)
			if nil ~= targetNode then
				local rect = self:GetTargetNodeRect(targetNode)
				lb.x = math.min(rect.x, lb.x)
				lb.y = math.min(rect.y, lb.y)
				rt.x = math.max(rect.x + rect.width, rt.x)
				rt.y = math.max(rect.y + rect.height, rt.y)

				if nil == parentNode then
					parentNode = targetNode:getParent()
				end
			end
		end

		local rect = cc.rect(lb.x, lb.y, rt.x - lb.x, rt.y - lb.y)
		if nil ~= parentNode then
			local fixedPos = self.guideClipNode:convertToNodeSpace(parentNode:convertToWorldSpace(cc.p(rect.x, rect.y)))
			return cc.rect(
				fixedPos.x,
				fixedPos.y,
				rect.width,
				rect.height
			)
		else
			return rect
		end

	elseif ConfigBattleGuideStepUIId.WEATHER_ICON == highlightId then

		local lb = cc.p(display.width, display.height)
		local rt = cc.p(0, 0)
		local index = nil
		local targetNode = nil
		local parentNode = nil

		local targetNodes = BMediator:GetViewComponent().viewData.weatherIcons

		for i,v in ipairs(highlightIndex) do
			index = checkint(v)
			targetNode = targetNodes[index]

			if nil ~= targetNode then
				local rect = self:GetTargetNodeRect(targetNode)
				lb.x = math.min(rect.x, lb.x)
				lb.y = math.min(rect.y, lb.y)
				rt.x = math.max(rect.x + rect.width, rt.x)
				rt.y = math.max(rect.y + rect.height, rt.y)

				if nil == parentNode then
					parentNode = targetNode:getParent()
				end
			end
		end

		local rect = cc.rect(lb.x, lb.y, rt.x - lb.x, rt.y - lb.y)

		if nil ~= parentNode then
			local fixedPos = self.guideClipNode:convertToNodeSpace(parentNode:convertToWorldSpace(cc.p(rect.x, rect.y)))
			return cc.rect(
				fixedPos.x,
				fixedPos.y,
				rect.width,
				rect.height
			)
		else
			return rect
		end

	else

		-- 其他类型不会圈多个目标节点
		local targetNode = self.highlightMap[highlightType][highlightId]
		local rect = self:GetTargetNodeRect(targetNode)
		local fixedPos = self.guideClipNode:convertToNodeSpace(targetNode:getParent():convertToWorldSpace(cc.p(rect.x, rect.y)))
		return cc.rect(
			fixedPos.x,
			fixedPos.y,
			rect.width,
			rect.height
		)

	end
end
--[[
获取战场层的高亮修正
@params highlightType ConfigBattleGuideStepHighlightType 高亮类型
@params highlightId ... 高亮主体id
@params highlightIndex list 高亮主体序号
@return rect cc.rect 修正rect
--]]
function BaseGuideDriver:GetHighlightBattle(highlightType, highlightId, highlightIndex)
	local rect = self.highlightMap[highlightType][highlightId]
	local fixedPos = self.guideClipNode:convertToNodeSpace(BMediator:GetBattleRoot():convertToWorldSpace(cc.p(rect.x, rect.y)))
	return cc.rect(
		fixedPos.x,
		fixedPos.y,
		rect.width,
		rect.height
	)
end
--[[
获取战场层卡牌系的高亮修正
@params highlightType ConfigBattleGuideStepHighlightType 高亮类型
@params highlightId ... 高亮主体id
@params highlightIndex list 高亮主体序号
@return rect cc.rect 修正rect
--]]
function BaseGuideDriver:GetHighlightCard(highlightType, highlightId, highlightIndex)
	local targetObject = BMediator:IsObjAliveByCardId(checkint(highlightId), CardUtils.IsMonsterCard(highlightId))
	if nil == targetObject then return cc.rect(0, 0, 0, 0) end

	if ConfigBattleGuideStepHighlightType.OBJECT_ALL == highlightType then

		-- 整个物体
		local rect = targetObject.view.viewComponent:getAvatarStaticViewBox()
		local fixedPos = self.guideClipNode:convertToNodeSpace(targetObject.view.viewComponent:convertToWorldSpace(cc.p(rect.x, rect.y)))
		return cc.rect(
			fixedPos.x,
			fixedPos.y,
			rect.width,
			rect.height + 65
		)

	elseif ConfigBattleGuideStepHighlightType.OBJECT_HP_BAR == highlightType then

		-- 血条
		local targetNode = targetObject.view.viewComponent.viewData.hpBar
		local parentNode = targetNode:getParent()

		local rect = self:GetTargetNodeRect(targetNode)
		local fixedPos = self.guideClipNode:convertToNodeSpace(parentNode:convertToWorldSpace(cc.p(rect.x, rect.y)))

		return cc.rect(
			fixedPos.x,
			fixedPos.y,
			rect.width,
			rect.height
		)

	elseif ConfigBattleGuideStepHighlightType.OBJECT_WEAK_POINT == highlightType then

		-- 弱点 可以圈多个
		local bossWeakScene = targetObject.ciScene
		if nil == bossWeakScene then return cc.rect(0, 0, 0, 0) end

		local lb = cc.p(display.width, display.height)
		local rt = cc.p(0, 0)
		local targetNode = nil
		local parentNode = nil

		for i,v in ipairs(highlightIndex) do
			touchItem = bossWeakScene:getTouchItem(checkint(v))
			if nil ~= touchItem then

				targetNode = touchItem.node
				local rect = self:GetTargetNodeRect(targetNode)
				lb.x = math.min(rect.x, lb.x)
				lb.y = math.min(rect.y, lb.y)
				rt.x = math.max(rect.x + rect.width, rt.x)
				rt.y = math.max(rect.y + rect.height, rt.y)

				if nil == parentNode then
					parentNode = targetNode:getParent()
				end

			end
		end

		local rect = cc.rect(lb.x, lb.y, rt.x - lb.x, rt.y - lb.y)
		local fixedPos = self.guideClipNode:convertToNodeSpace(parentNode:convertToWorldSpace(cc.p(rect.x, rect.y)))
		return cc.rect(
			fixedPos.x - 30,
			fixedPos.y - 30,
			rect.width + 60,
			rect.height + 60
		)

	elseif ConfigBattleGuideStepHighlightType.OBJECT_EXPRESSION == highlightType then

		-- 表情
		local tags = {357, 358}
		local lb = cc.p(display.width, display.height)
		local rt = cc.p(0, 0)
		local targetNode = nil
		local parentNode = nil

		for i,v in ipairs(tags) do
			targetNode = targetObject.view.viewComponent:getChildByTag(v)
			if nil ~= targetNode then
				local rect = self:GetTargetNodeRect(targetNode)
				lb.x = math.min(rect.x, lb.x)
				lb.y = math.min(rect.y, lb.y)
				rt.x = math.max(rect.x + rect.width, rt.x)
				rt.y = math.max(rect.y + rect.height, rt.y)

				if nil == parentNode then
					parentNode = targetNode:getParent()
				end
			end
		end

		local rect = cc.rect(lb.x, lb.y, rt.x - lb.x, rt.y - lb.y)
		local fixedPos = parentNode and self.guideClipNode:convertToNodeSpace(parentNode:convertToWorldSpace(cc.p(rect.x, rect.y))) or cc.p(0,0)

		return cc.rect(
			fixedPos.x,
			fixedPos.y,
			rect.width,
			rect.height
		)

	end
end
--[[
获取targetNode未修正的rect
@params targetNode cc.Node 目标节点
@return _ cc.rect 目标未修正的rect
--]]
function BaseGuideDriver:GetTargetNodeRect(targetNode)
	local size = nil
	if 'ccw.CLabel' == tolua.type(targetNode) then
		size = display.getLabelContentSize(targetNode)
	else
		local scale = targetNode:getScale()
		size = cc.size(targetNode:getContentSize().width * scale, targetNode:getContentSize().height * scale)
	end

	local anchorPoint = targetNode:getAnchorPoint()
	local lfpos = cc.p(
		targetNode:getPositionX() - (anchorPoint.x) * size.width,
		targetNode:getPositionY() - (anchorPoint.y) * size.height
	)

	return cc.rect(
		lfpos.x,
		lfpos.y,
		size.width,
		size.height
	)
end
--[[
根据位置id获取引导精灵位置信息
@params locationId int 位置id
@return result table {
	frameSize cc.size 描述框大小
	frameLocation table 位置信息
	godScale cc.p 引导精灵缩放
	godLocation table 引导精灵位置信息
	descrBgLocation table 引导文字背景位置信息
	descrLocation table 引导文字信息
}
--]]
function BaseGuideDriver:GetFixedGuideGodLocationInfo(locationId)
	local result = {
		frameSize = cc.size(638, 280),
		frameLocation = positionInfos[tostring(locationId)],
		godScale = cc.p(1, 1),
		godLocation = nil,
		descrBgLocation = nil,
		arrowScale = cc.p(1, 1),
		arrowLocation = nil
	}

	if locationId == 1 then

		result.godLocation = {ap = cc.p(0, 0), po = cc.p(0, 0)}

		result.descrBgLocation = {
			ap = cc.p(1, 1),
			po = cc.p(result.frameSize.width, result.frameSize.height)
		}

		result.arrowLocation = {ap = cc.p(0.5, 1), po = cc.p(80, 10)}

	else

		result.godScale.x = -1
		result.godLocation = {ap = cc.p(1, 0), po = cc.p(result.frameSize.width, 0)}

		result.descrBgLocation = {
			ap = cc.p(0, 1),
			po = cc.p(0, result.frameSize.height)
		}

		result.arrowScale.x = -1
		result.arrowLocation = {ap = cc.p(0.5, 1), po = cc.p(260, 10)}

	end

	return result
end
--[[
根据位置id获取引导手指位置
@params locationId int 手指位置id
@return result table {
	fingerScale cc.p 手指朝向
	fingerLocation table 手指位置
	descrBgLocation table 描述底板位置
}
--]]
function BaseGuideDriver:GetFixedGuideFingerLocationInfo(locationId)
	local result = {
		fingerScale = cc.p(1, 1),
		fingerLocation = nil,
		descrBgSize = cc.size(374, 120),
		descrBgLocation = nil
	}

	-- 当前高亮位置
	local highlightRect = self:GetHighlightArea()
	local padding = cc.p(highlightRect.width * 0.1, highlightRect.height * 0.1)
	if ConfigBattleGuideStepHighlightShapeType.CIRCLE == self:GetHighlightShape() then
		padding = cc.p(highlightRect.width * 0.2, highlightRect.height * 0.2)
	end

	if locationId == 1 then

		-- 处于高亮区域左上角
		result.fingerScale.x = -1
		result.fingerScale.y = -1

		local fpos = cc.p(
			highlightRect.x + padding.x,
			highlightRect.y + highlightRect.height - padding.y
		)
		result.fingerLocation = {po = fpos}

		result.descrBgLocation = {po = cc.p(
			fpos.x - 100, fpos.y + 180 
		)}

	elseif locationId == 2 then

		-- 处于高亮区域右上角
		result.fingerScale.y = -1

		local fpos = cc.p(
			highlightRect.x + highlightRect.width - padding.x,
			highlightRect.y + highlightRect.height - padding.y
		)
		result.fingerLocation = {po = fpos}

		result.descrBgLocation = {po = cc.p(
			fpos.x + 80, fpos.y + 180
		)}

	elseif locationId == 3 then

		-- 处于高亮区域左上角
		result.fingerScale.x = -1

		local fpos = cc.p(
			highlightRect.x + padding.x,
			highlightRect.y + padding.y
		)
		result.fingerLocation = {po = fpos}

		result.descrBgLocation = {po = cc.p(
			fpos.x - 80, fpos.y - 180
		)}

	elseif locationId == 4 then

		-- 处于高亮区域右下角
		local fpos = cc.p(
			highlightRect.x + highlightRect.width - padding.x,
			highlightRect.y + padding.y
		)
		result.fingerLocation = {po = fpos}


		result.descrBgLocation = {po = cc.p(
			fpos.x + 80, fpos.y - 180
		)}
	end

	return result
end
--[[
获取当前高亮区域位置信息
@return _ cc.rect 目标未修正的rect
--]]
function BaseGuideDriver:GetHighlightArea()
	local currentGuideStepData = self:GetGuideStepDataById(self:GetCurrentGuideStepId())

	if ConfigBattleGuideStepHighlightType.OBJECT_ALL == currentGuideStepData.highlightType then

		-- 高亮类型是单个obj 只获取obj自己的viewBox
		local cardId = currentGuideStepData.highlightId
		local obj = BMediator:IsObjAliveByCardId(cardId)
		if nil ~= obj then
			local viewBox = obj.view.viewComponent:getAvatarStaticViewBox()
			local fixedP = self.guideRootNode:convertToNodeSpace(obj.view.viewComponent:convertToWorldSpace(cc.p(viewBox.x, viewBox.y)))

			return cc.rect(fixedP.x, fixedP.y, viewBox.width, viewBox.height)
		else
			return cc.rect(0, 0, 0, 0)
		end

	elseif ConfigBattleGuideStepHighlightType.BATTLE_ROOT == currentGuideStepData.highlightType then

		local targets = nil
		if ConfigBattleGuideStepBattleRootId.FRIEND_ALL == currentGuideStepData.highlightId then

			-- 高亮所有友方物体
			targets = BMediator:GetBData().sortBattleObjs.friend

		elseif ConfigBattleGuideStepBattleRootId.ENEMY_ALL == currentGuideStepData.highlightId then

			-- 高亮所有敌方物体
			targets = BMediator:GetBData().sortBattleObjs.enemy

		elseif ConfigBattleGuideStepBattleRootId.QTE_ALL == currentGuideStepData.highlightId then

			-- 高亮所有qte召唤物物体
			targets = BMediator:GetBData().sortBattleObjs.beckonObj

		end

		local lb = cc.p(display.width * 10, display.height * 10)
		local rt = cc.p(0, 0)

		local obj = nil
		local parentNode = nil
		for i = #targets, 1, -1 do
			obj = targets[i]
			local viewBox = obj.view.viewComponent:getAvatarStaticViewBox()
			local fixedP = self.guideRootNode:convertToNodeSpace(obj.view.viewComponent:convertToWorldSpace(cc.p(viewBox.x, viewBox.y)))
			lb.x = math.min(lb.x, fixedP.x)
			lb.y = math.min(lb.y, fixedP.y)
			rt.x = math.max(rt.x, fixedP.x + viewBox.width)
			rt.y = math.max(rt.y, fixedP.y + viewBox.height)
		end

		return cc.rect(lb.x, lb.y, rt.x - lb.x, rt.y - lb.y)

	else

		-- 正常裁剪类型
		if nil == self.guideClipNode then return cc.rect(0, 0, 0, 0) end
		local targetNode = self.guideClipNode:getStencil()
		if nil == targetNode then
			return cc.rect(0, 0, 0, 0)
		else
			return self:GetTargetNodeRect(targetNode)
		end

	end

	
end
--[[
获取当前高亮形状
@return _ ConfigBattleGuideStepHighlightShapeType 高亮形状
--]]
function BaseGuideDriver:GetHighlightShape()
	local currentGuideStepData = self:GetGuideStepDataById(self:GetCurrentGuideStepId())
	return currentGuideStepData.highlightShapeType
end
--[[
判断下一帧是否存在需要进行的引导
@return _ bool 
--]]
function BaseGuideDriver:GetNextFrameGuideStep()
	local nextGuideStepId = self:CanDoAction()
	if nextGuideStepId then
		local nextGuideStepData = self:GetGuideStepDataById(nextGuideStepId)
		if 0 >= checkint(nextGuideStepData.delayTime) then
			return true
		end
	end
	return false
end
--[[
根据字符串获取修正后占位符后的字符串
@params str string 源字符串
@params fontSize int 字体大小
@params result table rich table用的list
--]]
function BaseGuideDriver.GetFixedGuideStr(str, fontSize)
	local labelparser = require('Game.labelparser')
	local parsedtable = labelparser.parse(tostring(str))

	local result = nil

	if BattleConfigUtils:UseElexLocalize() then
		result = ''
		for name, val in ipairs(parsedtable) do
			result = result .. val.content
		end
	else
		result = {}
		for name, val in ipairs(parsedtable) do
			if val.labelname == 'red' then
	            table.insert(result, {text = val.content , fontSize = fontSize or 24, color = '#f3600f',descr = val.labelname})
	        else
	            table.insert(result, {text = val.content , fontSize = fontSize or 24, color = '#5c5c5c',descr = val.labelname})
	        end
		end
	end
	
	return result
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
