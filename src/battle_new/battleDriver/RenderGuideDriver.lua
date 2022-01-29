--[[
战斗资源加载驱动
--]]
local BaseBattleDriver = __Require('battle.battleDriver.BaseBattleDriver')
local RenderGuideDriver = class('RenderGuideDriver', BaseBattleDriver)

------------ import ------------
------------ import ------------

------------ define ------------
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
function RenderGuideDriver:ctor( ... )
	BaseBattleDriver.ctor(self, ...)

	self.driverType = BattleDriverType.GUIDE_DRIVER

	self:Init()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function RenderGuideDriver:Init()
	self:InitValue()
	self:InitHighlightNodeMap()
end
--[[
初始化数据
--]]
function RenderGuideDriver:InitValue()
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

	-- 当前正在运行的引导信息
	self.currentGuideStepData = nil

	self.touchListener_ = nil

	-- 引导是否开始 不算延迟
	self.isGuideStart = false
end
--[[
初始化高亮节点映射
--]]
function RenderGuideDriver:InitHighlightNodeMap()
	local m = {
		[ConfigBattleGuideStepHighlightType.UI] = {
			[ConfigBattleGuideStepUIId.PAUSE_BTN] 				= G_BattleRenderMgr:GetBattleScene().viewData.pauseButton,
			[ConfigBattleGuideStepUIId.PLAYER_SKILL_ALL] 		= G_BattleRenderMgr:GetBattleScene().viewData.playerSkillBg,
			[ConfigBattleGuideStepUIId.PLAYER_SKILL_ENERGY] 	= G_BattleRenderMgr:GetBattleScene().viewData.playerEnergyBar,
			[ConfigBattleGuideStepUIId.PLAYER_SKILL_ICON] 		= G_BattleRenderMgr:GetBattleScene().viewData.playerSkillIcons,
			[ConfigBattleGuideStepUIId.ACCELERATE_BTN] 			= G_BattleRenderMgr:GetBattleScene().viewData.accelerateButton,
			[ConfigBattleGuideStepUIId.CONNECT_SKILL_ICON] 		= nil,
			[ConfigBattleGuideStepUIId.WAVE_ICON] 				= G_BattleRenderMgr:GetBattleScene().viewData.waveLabel,
			[ConfigBattleGuideStepUIId.TIME_ICON] 				= G_BattleRenderMgr:GetBattleScene().viewData.battleTimeLabel,
			[ConfigBattleGuideStepUIId.WEATHER_ICON] 			= G_BattleRenderMgr:GetBattleScene().viewData.weatherIcons
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
function RenderGuideDriver:UnregistTouchListener()
	if nil ~= self.touchListener_ and nil ~= self.guideRootNode then
		self.guideRootNode:getEventDispatcher():removeEventListener(self.touchListener_)
		self.touchListener_ = nil
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
逻辑开始
@params guideStepData BattleGuideStepStruct 战斗单步引导信息
--]]
function RenderGuideDriver:OnLogicEnter(guideStepData)
	if self:GetIsGuideStart() then return end

	-- 屏蔽触摸
	G_BattleRenderMgr:SetBattleTouchEnable(false)
	-- 设置当前的引导信息
	self:SetCurrentGuideStepData(guideStepData)
	-- 设置当前引导开始
	self:SetIsGuideStart(true)
	self:CreateGuideView(guideStepData)
end
--[[
@override
逻辑进行中
--]]
function RenderGuideDriver:OnLogicUpdate(dt)
	
end
--[[
@override
逻辑结束
--]]
function RenderGuideDriver:OnLogicExit()
	local currentGuideStepData = self:GetCurrentGuideStepData()

	-- 移除高亮物体
	self:RemoveAllHighlightObj(currentGuideStepData.highlightType, currentGuideStepData.highlightId)

	-- 引导结束 清空一些缓存
	self:SetIsGuideStart(false)
	self:SetCurrentGuideStepData(nil)

	-- 恢复触摸
	G_BattleRenderMgr:SetBattleTouchEnable(true)

	-- 通知逻辑层引导结束
	--###---------- 玩家手操记录 ----------###--
	G_BattleRenderMgr:AddPlayerOperate(
		'G_BattleLogicMgr',
		'RenderGuideOverHandler'
	)
	--###---------- 玩家手操记录 ----------###--

	-- 发送一次模拟的点击事件
	self:SendTouchEvent(currentGuideStepData)
end
--[[
发送一次模拟的点击事件
@params currentGuideStepData BattleGuideStepStruct 引导信息
--]]
function RenderGuideDriver:SendTouchEvent(currentGuideStepData)
	if nil == currentGuideStepData then return end

	if ConfigBattleGuideStepEndType.TOUCH_APPOINTED == currentGuideStepData.endType then

		local highlightType = currentGuideStepData.highlightType
		local highlightId = currentGuideStepData.highlightId
		local highlightIndex = currentGuideStepData.highlightIndex

		if ConfigBattleGuideStepUIId.PLAYER_SKILL_ICON == highlightId then

			local targetNodes = self.highlightMap[highlightType][highlightId]
			local index = nil
			local targetNode = nil

			for i,v in ipairs(highlightIndex) do
				index = checkint(v)
				targetNode = targetNodes[index].playerSkillButton

				if nil ~= targetNode then
					targetNode:PlayerSkillButtonClickHandler(targetNode)
				end
			end


		elseif ConfigBattleGuideStepUIId.CONNECT_SKILL_ICON == highlightId then

			-- 模拟一次点击事件
			local index = nil
			local targetNode = nil

			for i,v in ipairs(highlightIndex) do
				index = checkint(v)
				targetNode = G_BattleRenderMgr:GetConnectButtonByIndex(index)

				if nil ~= targetNode then
					targetNode:ClickCallback(targetNode.viewData.skillIconBg)
				end
			end

		end

	end
end
--[[
销毁时的回调
--]]
function RenderGuideDriver:OnDestroy()
	-- 注销触摸
	self:UnregistTouchListener()
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- guide view begin --
---------------------------------------------------
--[[
创建引导层
@params guideStepData BattleGuideStepStruct 战斗单步引导信息
--]]
function RenderGuideDriver:CreateGuideView(guideStepData)
	if nil == self.guideRootNode then
		local coverOpacity = 150

		-- root 节点
		local guideRootNode = display.newLayer(0, 0, {size = display.size})
		-- guideRootNode:setBackgroundColor(cc.c4b(0, 0, 0, 150))
		G_BattleRenderMgr:GetBattleScene():addChild(guideRootNode, BATTLE_E_ZORDER.GUIDE)

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
		local battleRootNode = G_BattleRenderMgr:GetBattleRoot()
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
function RenderGuideDriver:AddGuideHighlight(highlightType, highlightId, highlightIndex, highlightSize, highlightShapeType)
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
创建guide god
@params guideStepType ConfigBattleGuideStepType 引导类型
@params guideContent string 引导提示文字
@params guideGodType ConfigBattleGuideStepGodType 引导主体类型
@params guideGodLocationId int 引导主体位置
--]]
function RenderGuideDriver:AddGuideGod(guideStepType, guideContent, guideGodType, guideGodLocationId)
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
添加战斗物体高亮
@params highlightType ConfigBattleGuideStepHighlightType 高亮类型
@params highlightId ... 高亮主体id
--]]
function RenderGuideDriver:AddGuideObjHighlight(highlightType, highlightId)
	self.guideObjHighlightNode:setVisible(true)
	self.guideClipNode:setVisible(false)

	if ConfigBattleGuideStepHighlightType.BATTLE_ROOT == highlightType then

		local targets = nil
		if ConfigBattleGuideStepBattleRootId.FRIEND_ALL == highlightId then

			-- 高亮所有友方物体
			targets = G_BattleLogicMgr:GetAliveBattleObjs(false)

		elseif ConfigBattleGuideStepBattleRootId.ENEMY_ALL == highlightId then

			-- 高亮所有敌方物体
			targets = G_BattleLogicMgr:GetAliveBattleObjs(true)

		elseif ConfigBattleGuideStepBattleRootId.QTE_ALL == highlightId then

			-- 高亮所有qte召唤物物体
			targets = G_BattleLogicMgr:GetAliveBeckonObjs()

		end

		local obj = nil
		for i = #targets, 1, -1 do
			obj = targets[i]
			self:SetAObjHighlight(obj:GetOTag(), true)
		end

	elseif ConfigBattleGuideStepHighlightType.OBJECT_ALL == highlightType then

		-- 高亮单个obj
		local cardId = highlightId
		local obj = G_BattleLogicMgr:IsObjAliveByCardId(cardId)
		if nil ~= obj then
			self:SetAObjHighlight(obj:GetOTag(), true)
		end

	end

end
--[[
刷新小笼包老师
@params guideContent string 引导提示文字
@params guideGodLocationId int 引导主体位置
--]]
function RenderGuideDriver:AddGuideGodTeacher(guideContent, guideGodLocationId)
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
function RenderGuideDriver:AddGuideGodFinger(guideContent, guideGodLocationId)
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
			descrLabel = display.newRichLabel(0, 0, {w = 27})
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
根据tag将一个战斗物体高亮
@params tag int tag
@params highlight bool 是否高亮
--]]
function RenderGuideDriver:SetAObjHighlight(tag, highlight)
	local objectView = self:GetObjectViewByLogicTag(tag)
	if nil ~= objectView then
		objectView:SetObjectHighlightInGuide(highlight)
	end
end
--[[
移除所有obj高亮
@params highlightType ConfigBattleGuideStepHighlightType 高亮类型
@params highlightId ... 高亮主体id
--]]
function RenderGuideDriver:RemoveAllHighlightObj(highlightType, highlightId)
	if ConfigBattleGuideStepHighlightType.BATTLE_ROOT == highlightType then

		local targets = nil
		if ConfigBattleGuideStepBattleRootId.FRIEND_ALL == highlightId then

			-- 高亮所有友方物体
			targets = G_BattleLogicMgr:GetAliveBattleObjs(false)

		elseif ConfigBattleGuideStepBattleRootId.ENEMY_ALL == highlightId then

			-- 高亮所有敌方物体
			targets = G_BattleLogicMgr:GetAliveBattleObjs(true)

		elseif ConfigBattleGuideStepBattleRootId.QTE_ALL == highlightId then

			-- 高亮所有qte召唤物物体
			targets = G_BattleLogicMgr:GetAliveBeckonObjs()

		end

		local obj = nil
		for i = #targets, 1, -1 do
			obj = targets[i]
			self:SetAObjHighlight(obj:GetOTag(), false)
		end

	elseif ConfigBattleGuideStepHighlightType.OBJECT_ALL == highlightType then

		-- 高亮单个obj
		local cardId = highlightId
		local obj = G_BattleLogicMgr:IsObjAliveByCardId(cardId)
		if nil ~= obj then
			self:SetAObjHighlight(obj:GetOTag(), false)
		end

	end
end
--[[
隐藏所有引导层
--]]
function RenderGuideDriver:HideAllGuideCover()
	self.guideRootNode:setVisible(false)
	self.guideObjHighlightNode:setVisible(false)
end
---------------------------------------------------
-- guide view end --
---------------------------------------------------

---------------------------------------------------
-- touch handler begin --
---------------------------------------------------
function RenderGuideDriver:onTouchBegan_(touch, event)
	local gameState = G_BattleLogicMgr:GetGState()
	if GState.TRANSITION == gameState or
		GState.OVER == gameState or 
		GState.SUCCESS == gameState or
		GState.FAIL == gameState  then

		return false

	end

	local needEnd = self:TouchHandler(touch)

	local canEndGuide = self:CanEndGuide(touch)
	if canEndGuide then
		self:OnLogicExit()
	end

	return needEnd
end
function RenderGuideDriver:onTouchMoved_(touch, event)

end
function RenderGuideDriver:onTouchEnded_(touch, event)
	-- 屏蔽触摸
	if self:GetIsGuideStart() then
		G_BattleRenderMgr:SetBattleTouchEnable(false)
	end
end
function RenderGuideDriver:onTouchCanceled_(touch, event)
	print('here touch canceled by some unknown reason')
end
--[[
点击事件处理
@params touch 触摸
@return _ bool 是否需要走touch end逻辑
--]]
function RenderGuideDriver:TouchHandler(touch)
	local currentGuideStepData = self:GetCurrentGuideStepData()
	if nil == currentGuideStepData then return false end

	local guideEndType = currentGuideStepData.endType

	if ConfigBattleGuideStepEndType.CLEAR_QTE_ICE == guideEndType then

		if self:TouchedHighlightArea(touch) then
			-- 允许一次触摸
			G_BattleRenderMgr:SetBattleTouchEnable(true)
			return true
		end

	elseif ConfigBattleGuideStepEndType.CLEAR_QTE_BECKON == guideEndType then

		if self:TouchedHighlightArea(touch) then
			-- 允许一次触摸
			G_BattleRenderMgr:SetBattleTouchEnable(true)
			return true
		end

	elseif ConfigBattleGuideStepEndType.CLEAR_WEAK_POINT == guideEndType then

		if self:TouchedHighlightArea(touch) then
			-- 允许一次触摸
			G_BattleRenderMgr:SetBattleTouchEnable(true)
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
function RenderGuideDriver:TouchedHighlightArea(touch)
	if not self:GetIsGuideStart() then return false end

	local p = touch:getLocation()

	local currentGuideStepData = self:GetCurrentGuideStepData()

	if nil == currentGuideStepData then return false end

	local highlightId = currentGuideStepData.highlightId
	local highlightType = currentGuideStepData.highlightType

	if ConfigBattleGuideStepHighlightType.OBJECT_ALL == highlightType then

		-- 高亮类型是单个obj 处理一次obj的碰撞判定
		local cardId = highlightId
		local obj = G_BattleLogicMgr:IsObjAliveByCardId(cardId)
		if nil ~= obj then
			return self:TouchedHighlightObj(obj:GetOTag(), touch)
		else
			return false
		end

	elseif ConfigBattleGuideStepHighlightType.BATTLE_ROOT == highlightType then

		-- 高亮类型是战场位置 判断一次所有物体碰撞
		local targets = nil
		if ConfigBattleGuideStepBattleRootId.FRIEND_ALL == highlightId then

			-- 高亮所有友方物体
			targets = G_BattleLogicMgr:GetAliveBattleObjs(false)

		elseif ConfigBattleGuideStepBattleRootId.ENEMY_ALL == highlightId then

			-- 高亮所有敌方物体
			targets = G_BattleLogicMgr:GetAliveBattleObjs(true)

		elseif ConfigBattleGuideStepBattleRootId.QTE_ALL == highlightId then

			-- 高亮所有qte召唤物物体
			targets = G_BattleLogicMgr:GetAliveBeckonObjs()

		end

		local obj = nil
		for i = #targets, 1, -1 do
			obj = targets[i]
			if true == self:TouchedHighlightObj(obj:GetOTag(), touch) then
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
function RenderGuideDriver:TouchedHighlightObj(tag, touch)
	local objectView = self:GetObjectViewByLogicTag(tag)
	if nil ~= objectView then
		local p = touch:getLocation()
		local objViewBox = objectView:GetAvatarStaticCollisionBox()

		local fixedP = objectView:convertToNodeSpace(p)

		return cc.rectContainsPoint(objViewBox, fixedP)

	else
		return false
	end
end
--[[
检查是否可以结束引导
@params touch 触摸
@return _ bool 是否可以结束引导
--]]
function RenderGuideDriver:CanEndGuide(touch)
	if not self:GetIsGuideStart() then return false end

	local p = touch:getLocation()
	local currentGuideStepData = self:GetCurrentGuideStepData()

	if nil == currentGuideStepData then return false end

	local guideEndType = currentGuideStepData.endType

	if ConfigBattleGuideStepEndType.TOUCH_ANYWHERE == guideEndType then

		return true

	elseif ConfigBattleGuideStepEndType.TOUCH_APPOINTED == guideEndType or
		ConfigBattleGuideStepEndType.CLEAR_WEAK_POINT == guideEndType then

		return self:TouchedHighlightArea(touch)

	elseif ConfigBattleGuideStepEndType.CLEAR_QTE_ICE == guideEndType then

		local objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
		local obj = nil
		for i = #objs, 1, -1 do
			obj = objs[i]
			if obj:HasQTE() then
				return false
			end
		end

		return true

	elseif ConfigBattleGuideStepEndType.CLEAR_QTE_BECKON == currentGuideStepData.endType then

		-- 判断召唤物是否被全部清除
		if 0 >= #G_BattleLogicMgr:GetAliveBeckonObjs() then
			return true
		end

	end

	return false
end
---------------------------------------------------
-- touch handler end --
---------------------------------------------------

---------------------------------------------------
-- calc begin --
---------------------------------------------------
--[[
获取高亮区域的中心点修正rect
@params highlightType ConfigBattleGuideStepHighlightType 高亮类型
@params highlightId ... 高亮主体id
@params highlightIndex list 高亮主体序号
@return rect cc.rect 修正rect
--]]
function RenderGuideDriver:GetFixedHighlightRect(highlightType, highlightId, highlightIndex)

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
function RenderGuideDriver:GetHighlightUI(highlightType, highlightId, highlightIndex)

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
			targetNode = G_BattleRenderMgr:GetConnectButtonByIndex(index)
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

		local targetNodes = G_BattleRenderMgr:GetBattleScene().viewData.weatherIcons

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
function RenderGuideDriver:GetHighlightBattle(highlightType, highlightId, highlightIndex)
	local rect = self.highlightMap[highlightType][highlightId]
	local fixedPos = self.guideClipNode:convertToNodeSpace(G_BattleRenderMgr:GetBattleRoot():convertToWorldSpace(cc.p(rect.x, rect.y)))
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
function RenderGuideDriver:GetHighlightCard(highlightType, highlightId, highlightIndex)
	local targetObject = G_BattleLogicMgr:IsObjAliveByCardId(checkint(highlightId), CardUtils.IsMonsterCard(highlightId))
	if nil == targetObject then return cc.rect(0, 0, 0, 0) end
	local objectView = G_BattleRenderMgr:GetAObjectView(targetObject:GetViewModelTag())
	if nil == objectView then return cc.rect(0, 0, 0, 0) end

	local targetTag = targetObject:GetOTag()

	if ConfigBattleGuideStepHighlightType.OBJECT_ALL == highlightType then

		-- 整个物体
		local rect = objectView:GetAvatarStaticViewBox()
		local fixedPos = self.guideClipNode:convertToNodeSpace(objectView:convertToWorldSpace(cc.p(rect.x, rect.y)))
		return cc.rect(
			fixedPos.x,
			fixedPos.y,
			rect.width,
			rect.height + 65
		)

	elseif ConfigBattleGuideStepHighlightType.OBJECT_HP_BAR == highlightType then

		-- 血条
		local targetNode = objectView.viewData.hpBar
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
		local bossWeakScene = G_BattleRenderMgr:GetCISceneByOwnerTag(targetTag)
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
			targetNode = objectView:getChildByTag(v)
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
function RenderGuideDriver:GetFixedGuideGodLocationInfo(locationId)
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
根据字符串获取修正后占位符后的字符串
@params str string 源字符串
@params fontSize int 字体大小
@params result table rich table用的list
--]]
function RenderGuideDriver.GetFixedGuideStr(str, fontSize)
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
--[[
根据位置id获取引导手指位置
@params locationId int 手指位置id
@return result table {
	fingerScale cc.p 手指朝向
	fingerLocation table 手指位置
	descrBgLocation table 描述底板位置
}
--]]
function RenderGuideDriver:GetFixedGuideFingerLocationInfo(locationId)
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
function RenderGuideDriver:GetHighlightArea()
	local currentGuideStepData = self:GetCurrentGuideStepData()
	if nil == currentGuideStepData then return cc.rect(0, 0, 0, 0) end

	if ConfigBattleGuideStepHighlightType.OBJECT_ALL == currentGuideStepData.highlightType then

		-- 高亮类型是单个obj 只获取obj自己的viewBox
		local cardId = currentGuideStepData.highlightId
		local obj = G_BattleLogicMgr:IsObjAliveByCardId(cardId)
		if nil ~= obj then
			local objectView = G_BattleRenderMgr:GetAObjectView(obj:GetViewModelTag())
			if nil ~= objectView then
				local viewBox = objectView:GetAvatarStaticViewBox()
				local fixedP = self.guideRootNode:convertToNodeSpace(objectView:convertToWorldSpace(cc.p(viewBox.x, viewBox.y)))

				return cc.rect(fixedP.x, fixedP.y, viewBox.width, viewBox.height)
			end
			return cc.rect(0, 0, 0, 0)
		else
			return cc.rect(0, 0, 0, 0)
		end

	elseif ConfigBattleGuideStepHighlightType.BATTLE_ROOT == currentGuideStepData.highlightType then

		local targets = nil
		if ConfigBattleGuideStepBattleRootId.FRIEND_ALL == currentGuideStepData.highlightId then

			-- 高亮所有友方物体
			targets = G_BattleLogicMgr:GetAliveBattleObjs(false)

		elseif ConfigBattleGuideStepBattleRootId.ENEMY_ALL == currentGuideStepData.highlightId then

			-- 高亮所有敌方物体
			targets = G_BattleLogicMgr:GetAliveBattleObjs(true)

		elseif ConfigBattleGuideStepBattleRootId.QTE_ALL == currentGuideStepData.highlightId then

			-- 高亮所有qte召唤物物体
			targets = G_BattleLogicMgr:GetAliveBeckonObjs()

		end

		local lb = cc.p(display.width * 10, display.height * 10)
		local rt = cc.p(0, 0)

		local obj = nil
		local parentNode = nil
		for i = #targets, 1, -1 do
			obj = targets[i]
			local objectView = G_BattleRenderMgr:GetAObjectView(obj:GetViewModelTag())
			if nil ~= objectView then
				local viewBox = objectView:GetAvatarStaticViewBox()
				local fixedP = self.guideRootNode:convertToNodeSpace(objectView:convertToWorldSpace(cc.p(viewBox.x, viewBox.y)))
				lb.x = math.min(lb.x, fixedP.x)
				lb.y = math.min(lb.y, fixedP.y)
				rt.x = math.max(rt.x, fixedP.x + viewBox.width)
				rt.y = math.max(rt.y, fixedP.y + viewBox.height)
			end
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
function RenderGuideDriver:GetHighlightShape()
	local currentGuideStepData = self:GetCurrentGuideStepData()
	return currentGuideStepData.highlightShapeType
end
--[[
获取targetNode未修正的rect
@params targetNode cc.Node 目标节点
@return _ cc.rect 目标未修正的rect
--]]
function RenderGuideDriver:GetTargetNodeRect(targetNode)
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
计算表示友方的大圈
@return _ cc.rect 表示友方范围的大圈
--]]
function RenderGuideDriver:CalcFriendFormationRect()
	local avatarSize = cc.size(150, 250)

	local lb = cc.p(display.width, display.height)
	local rt = cc.p(0, 0)

	local p = nil
	for i,v in ipairs(BattleFormation) do
		p = G_BattleLogicMgr:GetCellPosByRC(v.r, v.c)
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
function RenderGuideDriver:CalcEnemyFormationRect()
	local friendFormatRect = self:CalcFriendFormationRect()
	local battleArea = G_BattleLogicMgr:GetBConf().BATTLE_AREA
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
function RenderGuideDriver:CalcBeckonFormationRect()
	local battleArea = G_BattleLogicMgr:GetBConf().BATTLE_AREA

	return cc.rect(
		battleArea.x + battleArea.width - 150,
		battleArea.y,
		100,
		battleArea.height + 100
	)
end
---------------------------------------------------
-- calc end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取当前引导信息
@return _ BattleGuideStepStruct 引导信息
--]]
function RenderGuideDriver:GetCurrentGuideStepData()
	return self.currentGuideStepData
end
function RenderGuideDriver:SetCurrentGuideStepData(guideStepData)
	self.currentGuideStepData = guideStepData
end
--[[
判断引导是否开始
--]]
function RenderGuideDriver:GetIsGuideStart()
	return self.isGuideStart
end
function RenderGuideDriver:SetIsGuideStart(b)
	self.isGuideStart = b
end
--[[
根据物体tag获取物体的渲染层模型
@params tag int 逻辑层tag
@return _ BaseObjectView 渲染层模型
--]]
function RenderGuideDriver:GetObjectViewByLogicTag(tag)
	local obj = G_BattleLogicMgr:IsObjAliveByTag(tag)
	if nil == obj then return nil end
	local viewModelTag = obj:GetViewModelTag()
	return G_BattleRenderMgr:GetAObjectView(viewModelTag)
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return RenderGuideDriver
