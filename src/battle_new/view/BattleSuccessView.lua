--[[
新战斗结算 胜利
@params table {
	viewType ConfigBattleResultType 结算界面类型
	cleanCondition table 需要展示的三星特殊条件
	showMessage bool 是否显示给对手的留言
	canRepeatChallenge bool 是否可以重打
	teamData table 阵容信息
	trophyData table 战斗奖励信息
}
--]]
local BattleSuccessView = class('BattleSuccessView', function ()
	local node = CLayout:create(display.size)
	node.name = 'battle.view.BattleSuccessView'
	node:enableNodeEvents()
	print('BattleSuccessView', ID(node))
	return node
end)

------------ import ------------
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance('AppFacade'):GetManager("CardManager")
------------ import ------------

--[[
constructor
--]]
function BattleSuccessView:ctor( ... )
	local args = unpack({...})

	cc.Director:getInstance():getScheduler():setTimeScale(1)

	self.viewType = args.viewType
	self.cleanCondition = args.cleanCondition
	self.showMessage = args.showMessage
	self.canRepeatChallenge = args.canRepeatChallenge or false 
	self.teamData = args.teamData
	self.trophyData = args.trophyData

	------------ 动画配置 ------------
	self.fps = 30
	self.layers = {}
	self.curLayer = nil
	------------ 动画配置 ------------

	self.canTouch = false

	self.rewardsParentNode = nil
	self.rewardsBg = nil
	self.rewardNodes = {}
	self.backBtn = nil
	self.repeatBtn = nil
	self.drawNode = nil

	self.messageLabel = nil
	self.messageListView = nil
	self.messageListViewBg = nil
	self.selectedMessageIndex = nil

	self.canTouchBackBtn = true

	-- 向外传参 延迟的升级奖励信息
	self.delayUpgradeLevelData = {}

	-- /***********************************************************************************************************************************\
	--  * 此处的两次操作会导致玩家的本地卡牌数据被偷换!!!
	-- \***********************************************************************************************************************************/
	-- 计算一次卡牌id
	local cardData = nil
	for i,v in ipairs(self.teamData) do
		cardData = gameMgr:GetCardDataByCardId(v.cardId)
		if cardData then
			v.id = checkint(cardData.id)
		end
	end

	-- 转换数据结构
	if not self.trophyData.cardExp then 
		self.trophyData.cardExp = {}
		for i,v in ipairs(self.teamData) do
			self.trophyData.cardExp[tostring(v.id)] = {
				exp = v.exp,
				level = v.level
			}
		end
	end

	self:InitUI()
	self:UpdateLocalData()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function BattleSuccessView:InitUI()
	local commonLayer = self:InitCommonLayer()
	table.insert(self.layers, commonLayer)

	if ConfigBattleResultType.NO_EXP ~= self.viewType then
		local expLayer = self:InitExpLayer()
		table.insert(self.layers, expLayer)
	end

	self:RegistBtnClickHandler()
end
--[[
初始化公有层 公有层只包含立绘和结果
--]]
function BattleSuccessView:InitCommonLayer()
	local layerSize = cc.size(display.SAFE_RECT.width, display.SAFE_RECT.height)

	local animationConf = {
		bgMaskFadeInTime = 8,
		drawAppearDelayTime = 30,
		drawAppearTime = 20,
		drawMoveY = 43,
		showStarLayerDelayTime = 36,
		firstFireDelayTime = 37,
		fireDelayTime = 6,
		conditionBgMoveX = 118,
		conditionBgMoveTime = 5,
		firstConditionBgDelayTime = 40,
		conditionBgDelayTime = 5,
		hideMoveTime = 15,
		hideMoveY = 85
	}

	-- 遮罩
	local bgMask = display.newImageView(_res('ui/common/common_bg_mask_2.png'), utils.getLocalCenter(self).x, utils.getLocalCenter(self).y,
		{enable = true, animate = false, scale9 = true, size = display.size,
	cb = function (sender)
		if self.canTouch then
			for i,v in ipairs(self.teamData) do
				local cardId = checkint(v.cardId)
				if cardId > 0 then
					CommonUtils.PlayCardSoundByCardId(cardId, SoundType.TYPE_BATTLE_SUCCESS, SoundChannel.BATTLE_RESULT, not BattleConfigUtils:UseJapanLocalize())
					break
				end
			end
			
			self:ShowNextLayer()
		end
	end})
	self:addChild(bgMask)

	-- 通用层节点
	local commonLayer = display.newLayer(display.SAFE_L + layerSize.width * 0.5, layerSize.height * 0.5,
		{size = layerSize, ap = cc.p(0.5, 0.5)})
	self:addChild(commonLayer, 1)

	local commonCenterTopLayer = display.newLayer(display.SAFE_L + layerSize.width * 0.5, layerSize.height * 0.5,
		{size = layerSize, ap = cc.p(0.5, 0.5)})
	self:addChild(commonCenterTopLayer, 3)

	-- 大spine节点
	local mainSpineNode = nil
	if BattleConfigUtils:UseElexLocalize() then
		mainSpineNode = sp.SkeletonAnimation:create(
			_res('battle/effect/battle_result.json'),
			_res('battle/effect/battle_result.atlas'),
			1
		)
	else
		mainSpineNode = sp.SkeletonAnimation:create(
			'battle/effect/battle_result.json',
			'battle/effect/battle_result.atlas',
			1
		)
	end
	mainSpineNode:update(0)
	mainSpineNode:setPosition(cc.p(layerSize.width * 0.5, layerSize.height * 0.5))
	commonLayer:addChild(mainSpineNode, 1)

	-- 立绘
	local leaderData = self.teamData[1]
	local drawNode = require('common.CardSkinDrawNode').new({
		skinId = checkint(leaderData.skinId),
		coordinateType = COORDINATE_TYPE_CAPSULE
	})
	self:addChild(drawNode, 2)
	self.drawNode = drawNode
	if cardMgr.GetFavorabilityMax(leaderData.favorLevel) then
		local designSize = cc.size(1334, 750)
        local winSize = display.size
		local deltaHeight = (winSize.height - designSize.height) * 0.5
		
		local particleSpine = sp.SkeletonAnimation:create(
              'effects/marry/fly.json',
              'effects/marry/fly.atlas',
              1)
        -- particleSpine:setTimeScale(2.0 / 3.0)
        particleSpine:setPosition(cc.p(display.SAFE_L + 300,deltaHeight))
        self:addChild(particleSpine, 2)
        particleSpine:setAnimation(0, 'idle2', true)
        particleSpine:update(0)
        particleSpine:setToSetupPose()
		particleSpine:setVisible(false)
		
		self.particleSpine = particleSpine
	end

	local cleanConditionNodes = nil
	local allCleanIds = nil
	local cleanedIds = nil

	local messageBg = nil
	local messageTitleLabel = nil

	------------ 显示通用层下附加的信息 ------------
	if self.showMessage then

		local zorder = mainSpineNode:getLocalZOrder() + 1

		-- 显示给对手的留言
		-- 标题
		messageTitleLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('给对手留言:')}))
		display.commonUIParams(messageTitleLabel, {ap = cc.p(1, 0.5), po = cc.p(layerSize.width * 0.5 + 275 - 5, layerSize.height * 0.5 - 150)})
		commonLayer:addChild(messageTitleLabel, zorder)

		-- 信息展示
		messageBg = display.newButton(0, 0, {n = _res('ui/battle/battleresult/settlement_bg_input.png'), animate = false, cb = function (sender)
			if nil ~= self.messageListView then
				self:ShowSelectMessage(not self.messageListView:isVisible())
			end
		end})
		display.commonUIParams(messageBg, {ap = cc.p(0, 0.5), po = cc.p(layerSize.width * 0.5 + 275 + 5, layerSize.height * 0.5 - 150)})
		commonLayer:addChild(messageBg, zorder)

		local messageLabel = display.newLabel(0, 0, fontWithColor('8', {text = ''}))
		display.commonUIParams(messageLabel, {ap = cc.p(0, 0.5), po = cc.p(10, utils.getLocalCenter(messageBg).y)})
		messageBg:addChild(messageLabel)

		self.messageLabel = messageLabel

		local arrow = display.newNSprite(_res('ui/battle/battleresult/settlement_ico_arrow.png'), 0, 0)
		display.commonUIParams(arrow, {po = cc.p(messageBg:getContentSize().width - 20, utils.getLocalCenter(messageBg).y)})
		messageBg:addChild(arrow)

		-- 列表
		local listBg = display.newImageView(_res('ui/battle/battleresult/settlement_words_bg.png'), 0, 0)
		display.commonUIParams(listBg, {po = cc.p(
			messageBg:getPositionX() + messageBg:getContentSize().width * 0.5,
			messageBg:getPositionY() + messageBg:getContentSize().height * 0.5 + listBg:getContentSize().height * 0.5
		)})
		commonLayer:addChild(listBg, zorder)

		self.messageListViewBg = listBg

		local listViewSize = cc.size(listBg:getContentSize().width - 8, listBg:getContentSize().height - 12)
		local cellSize = cc.size(listViewSize.width, 68)

		local listView = CListView:create(listViewSize)
		listView:setBounceable(false)
		listView:setDirection(eScrollViewDirectionVertical)
		listView:setPosition(cc.p(
			listBg:getPositionX(),
			listBg:getPositionY() + 2
		))
		commonLayer:addChild(listView, zorder)
		-- listView:setBackgroundColor(cc.c4b(255, 128, 64, 100))

		self.messageListView = listView

		local messageConfigs = CommonUtils.GetConfigAllMess('robberyRidicule', 'takeaway')
		local messageAmount = table.nums(messageConfigs)

		local messageId = nil
		local messageConfig = nil

		for i = 1, messageAmount + 1 do

			messageId = i
			messageConfig = messageConfigs[tostring(messageId)]

			local view = display.newLayer(0, 0, {size = cellSize})
			view:setTag(messageId)

			local cellBgPath = 'ui/battle/battleresult/settlement_words_bg_1.png'
			if 0 == i % 2 then
				cellBgPath = 'ui/battle/battleresult/settlement_words_bg_2.png'
			end

			local cellBg = display.newImageView(_res(cellBgPath), 0, 0, {enable = true, animate = false, cb = handler(self, self.MessageClickCallback)})
			display.commonUIParams(cellBg, {po = cc.p(cellSize.width * 0.5, cellSize.height * 0.5)})
			view:addChild(cellBg)
			cellBg:setTag(i)

			local messageStr = ''
			if messageAmount < i then
				messageStr = __('(不留言)')
			else
				messageStr = messageConfig.descr
			end

			local messageCellLabel = display.newLabel(0, 0, fontWithColor('8', {text = messageStr}))
			display.commonUIParams(messageCellLabel, {ap = cc.p(0, 0.5), po = cc.p(6, cellSize.height * 0.5)})
			view:addChild(messageCellLabel)

			local selectedMark = display.newNSprite(_res('ui/battle/battleresult/raid_bg_talk_select.png'), 0, 0)
			display.commonUIParams(selectedMark, {po = cc.p(cellSize.width * 0.5, cellSize.height * 0.5)})
			view:addChild(selectedMark, 10)

			selectedMark:setTag(9867)
			selectedMark:setVisible(false)

			listView:insertNodeAtLast(view)

		end

		listView:reloadData()

		-- 初始化状态
		self:ShowSelectMessage(false)
		self:RefreshMessageByIndex(1)

		------------ 初始化动画状态 ------------
		messageTitleLabel:setVisible(false)
		messageTitleLabel:setOpacity(0)

		messageBg:setVisible(false)
		messageBg:setOpacity(0)
		------------ 初始化动画状态 ------------

	elseif self.cleanCondition and self.trophyData.gradeConditionIds then

		cleanConditionNodes = {}
		allCleanIds = {}
		cleanedIds = {}
		
		------------ 满星奖励 ------------
		-- 处理数据
	
		for i,v in ipairs(self.trophyData.gradeConditionIds) do
			if nil ~= self.cleanCondition[tostring(v)] then
				-- 插入数据
				table.insert(allCleanIds, checkint(v))
				cleanedIds[tostring(v)] = v
			end
		end

		for k,v in pairs(self.cleanCondition) do
			if nil == cleanedIds[tostring(k)] then
				table.insert(allCleanIds, checkint(k))
			end
		end

		-- 创建火的动画
		local animation  = cc.Animation:create()
		for i = 1, 6 do
			animation:addSpriteFrameWithFile(_res(string.format('arts/effects/hero_baoyin_huo_%02d.png', i)))
		end
		animation:setDelayPerUnit(0.08)
		animation:setRestoreOriginalFrame(true)

		local cleanId = nil
		local cleanConditionConfig = nil
		local pos = cc.p(0, 0)

		for i = 1, #allCleanIds do
			cleanId = allCleanIds[i]
			pos.x = layerSize.width * 0.675 - (i - 1) * 50
			pos.y = layerSize.height * 0.375 - (i - 1) * 85

			-- 满星条件底
			local conditionBg = display.newImageView(_res('ui/battle/battleresult/settlement_bg_pass_condition.png'), 0, 0)
			display.commonUIParams(conditionBg, {po = cc.p(
				pos.x + conditionBg:getContentSize().width * 0.5,
				pos.y
			)})
			commonCenterTopLayer:addChild(conditionBg, mainSpineNode:getLocalZOrder() + 1)

			-- 满星条件文字
			local cleanConditionText = ''
			cleanConditionConfig = CommonUtils.GetConfig('quest', 'starCondition', cleanId)
			if nil ~= cleanConditionConfig then
				cleanConditionText = CommonUtils.GetFixedClearDesc(cleanConditionConfig, self.cleanCondition[tostring(cleanId)])
			end

			local conditionLabel = display.newLabel(0, 0, fontWithColor('9', {
				text = cleanConditionText,
				ap = cc.p(0, 0.5)
			}))
			display.commonUIParams(conditionLabel, {po = cc.p(
				conditionBg:getPositionX() + 40 - conditionBg:getContentSize().width * 0.5,
				conditionBg:getPositionY() + 2
			)})
			commonCenterTopLayer:addChild(conditionLabel, conditionBg:getLocalZOrder() + 1)

			-- 创建火
			local fire = display.newNSprite(_res('arts/effects/hero_baoyin_huo_00.png'),
				pos.x,
				pos.y + 35)
			display.commonUIParams(fire, {ap = cc.p(0.5, 0.4)})
			commonCenterTopLayer:addChild(fire, 5)
			fire:runAction(cc.RepeatForever:create(cc.Animate:create(animation)))

			if nil ~= cleanedIds[tostring(cleanId)] then
				conditionLabel:setColor(cc.c3b(255, 218, 68))
			else
				fire:setVisible(false)
				fire:stopAllActions()
			end

			-- 初始化动画状态
			conditionBg:setVisible(false)
			conditionBg:setOpacity(0)
			conditionBg:setPositionX(conditionBg:getPositionX() - animationConf.conditionBgMoveX)
			conditionLabel:setVisible(false)
			conditionLabel:setOpacity(0)
			fire:setScale(0)

			cleanConditionNodes[i] = {
				conditionBg = conditionBg,
				conditionLabel = conditionLabel,
				fire = fire
			}
		end
		------------ 满星奖励 ------------

	end
	------------ 显示通用层下附加的信息 ------------

	-- 添加底部信息
	local commonBottomLayer = self:AddCommonBottomLayer(commonLayer)

	------------ 初始化动画状态 ------------
	bgMask:setOpacity(0)
	mainSpineNode:setVisible(false)
	drawNode:setVisible(false)
	drawNode:setOpacity(0)
	drawNode:setPositionY(drawNode:getPositionY() - animationConf.drawMoveY)
	if self.particleSpine then
		self.particleSpine:setOpacity(0)
	end
	------------ 初始化动画状态 ------------

	local ShowSelf = function ()
		local costFrame = 0

		------------ 显示遮罩渐变动画 ------------
		local bgMaskActionSeq = cc.Sequence:create(
			cc.FadeTo:create(animationConf.bgMaskFadeInTime / self.fps, 255))
		bgMask:runAction(bgMaskActionSeq)
		------------ 显示遮罩渐变动画 ------------

		------------ 显示主spine动画 ------------
		local mainSpineNodeActionSeq = cc.Sequence:create(
			cc.DelayTime:create(animationConf.bgMaskFadeInTime / self.fps),
			cc.Show:create(),
			cc.CallFunc:create(function ()
				mainSpineNode:setAnimation(0, 'play', false)
				mainSpineNode:addAnimation(0, 'idle', true)

				-- 播放胜利音效
				PlayAudioClip(AUDIOS.UI.ui_war_win.id)
			end)
		)
		mainSpineNode:runAction(mainSpineNodeActionSeq)
		------------ 显示主spine动画 ------------

		------------ 显示立绘 ------------
		local drawNodeActionSeq = cc.Sequence:create(
			cc.DelayTime:create((animationConf.bgMaskFadeInTime + animationConf.drawAppearDelayTime) / self.fps),
			cc.Show:create(),
			cc.EaseOut:create(cc.Spawn:create(
				cc.FadeTo:create(animationConf.drawAppearTime / self.fps, 255),
				cc.MoveBy:create(animationConf.drawAppearTime / self.fps, cc.p(0, animationConf.drawMoveY))), 2),
			cc.CallFunc:create(function ()
				if self.particleSpine then
					self.particleSpine:runAction(cc.Sequence:create(
						cc.Show:create(),
						cc.FadeIn:create(0.5)))
				end
			end)
			)
		drawNode:runAction(drawNodeActionSeq)
		------------ 显示立绘 ------------
		costFrame = animationConf.bgMaskFadeInTime + animationConf.drawAppearDelayTime

		------------ 附加信息的动画 ------------
		-- 满星条件动画
		if self.showMessage then

			-- 留言的动画
			local messageDelayFrame = animationConf.bgMaskFadeInTime + animationConf.drawAppearDelayTime
			local messageActionSeq = cc.Sequence:create(
				cc.DelayTime:create(messageDelayFrame / self.fps),
				cc.Show:create(),
				cc.FadeTo:create(0.5, 255)
			)

			messageTitleLabel:runAction(messageActionSeq:clone())
			messageBg:runAction(messageActionSeq:clone())

		elseif nil ~= cleanConditionNodes then
			for i,v in ipairs(cleanConditionNodes) do
				-- 火动画
				local fireDelayFrame = animationConf.bgMaskFadeInTime + animationConf.firstFireDelayTime + (i - 1) * animationConf.fireDelayTime
				local fireActionSeq = cc.Sequence:create(
					cc.DelayTime:create(fireDelayFrame / self.fps),
					cc.CallFunc:create(function ()
						local cleanId = allCleanIds[i]
						if nil ~= cleanedIds[tostring(cleanId)] then
							-- 播放满星音效
							PlayAudioClip(AUDIOS.UI.ui_war_assess.id)
						end
					end),
					cc.ScaleTo:create(5 / self.fps, 1.5),
					cc.ScaleTo:create(4 / self.fps, 1))
				v.fire:runAction(fireActionSeq)

				-- 三星条件动画
				local conditionBgDelayFrame = animationConf.bgMaskFadeInTime + animationConf.firstConditionBgDelayTime + (i - 1) * animationConf.conditionBgDelayTime
				local conditionBgActionSeq = cc.Sequence:create(
					cc.DelayTime:create(conditionBgDelayFrame / self.fps),
					cc.Show:create(),
					cc.Spawn:create(
						cc.MoveBy:create(animationConf.conditionBgMoveTime / self.fps, cc.p(animationConf.conditionBgMoveX, 0)),
						cc.FadeTo:create(animationConf.conditionBgMoveTime / self.fps, 255)))
				v.conditionBg:runAction(conditionBgActionSeq)

				-- 三星文字动画
				local conditionLabelDelayFrame = conditionBgDelayFrame + 4 
				local conditionLabelActionSeq = cc.Sequence:create(
					cc.DelayTime:create(conditionLabelDelayFrame / self.fps),
					cc.Show:create(),
					cc.FadeTo:create(animationConf.conditionBgMoveTime / self.fps, 255))
				v.conditionLabel:runAction(conditionLabelActionSeq)

				costFrame = conditionLabelDelayFrame + animationConf.conditionBgMoveTime
			end
		end
		------------ 附加信息的动画 ------------

		------------ 底部的动画 ------------
		if commonBottomLayer and commonBottomLayer.ShowSelf then
			commonBottomLayer.ShowSelf(costFrame)
		end
		------------ 底部的动画 ------------


	end

	local HideSelf = function ()
		-- commonLayer:setVisible(false)
		-- 屏蔽触摸
		self.canTouch = false

		-- 隐藏common层
		local commonLayerActionSeq = cc.Sequence:create(
			cc.EaseIn:create(
				cc.Spawn:create(
					cc.MoveBy:create(animationConf.hideMoveTime / self.fps, cc.p(0, animationConf.hideMoveY)),
					cc.FadeTo:create(animationConf.hideMoveTime / self.fps, 0)),
				2
			),
			cc.Hide:create())
		commonLayer:runAction(commonLayerActionSeq:clone())
		commonCenterTopLayer:runAction(commonLayerActionSeq:clone())

		------------ 底部的动画 ------------
		if commonBottomLayer and commonBottomLayer.ShowSelf then
			commonBottomLayer.HideSelf()
		end
		------------ 底部的动画 ------------
	end

	local layer = {ShowSelf = ShowSelf, HideSelf = HideSelf}
	return layer
end
--[[
获取common层底部nodes
@params parentNode cc.Node 父节点
--]]
function BattleSuccessView:AddCommonBottomLayer(parentNode)

	if ConfigBattleResultType.NO_EXP == self.viewType then

		-- 该类型没有第二层的展示 直接显示退出按钮
		local backBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
		display.commonUIParams(backBtn, {po = cc.p(
			parentNode:getContentSize().width * 0.5 + 375,
			backBtn:getContentSize().height * 0.5 + 10
		)})
		display.commonLabelParams(backBtn, fontWithColor('14', {text = __('退出')}))
		parentNode:addChild(backBtn)
		self.backBtn = backBtn
		local x = backBtn:getPositionX()

		local repeatBtn = nil
		if self:CanRepeatChallenge() then
			-- 重新挑战按钮
			x = x - 150
			repeatBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
			display.commonUIParams(repeatBtn, {po = cc.p(
				x,
				repeatBtn:getContentSize().height * 0.5 + 10
			)})
			display.commonLabelParams(repeatBtn, fontWithColor('14', {text = __('重新挑战')}))
			parentNode:addChild(repeatBtn)
			self.repeatBtn = repeatBtn

			backBtn:setPositionX(backBtn:getPositionX() + 150)
		end

		-- 伤害统计按钮
		local skadaBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_white_default.png') , scale9 = true })
		x = x - (skadaBtn:getContentSize().width * 0.5 + backBtn:getContentSize().width * 0.5 + 50)
		display.commonUIParams(skadaBtn, {po = cc.p(
			x,
			backBtn:getPositionY()
		)})
		display.commonLabelParams(skadaBtn, fontWithColor('14', {text = __('伤害统计') , paddingW = 10 }))
		parentNode:addChild(skadaBtn)
		self.skadaBtn = skadaBtn

		------------ 初始化动画状态 ------------
		backBtn:setVisible(false)
		backBtn:setOpacity(0)

		if nil ~= repeatBtn then
			repeatBtn:setVisible(false)
			repeatBtn:setOpacity(0)
		end

		skadaBtn:setVisible(false)
		skadaBtn:setOpacity(0)
		------------ 初始化动画状态 ------------

		local ShowSelf = function (delayFrame)
			local btnActionSeq = cc.Sequence:create(
				cc.DelayTime:create(delayFrame / self.fps),
				cc.Show:create(),
				cc.FadeTo:create(0.5, 255),
				cc.CallFunc:create(function ()
					------------ 动画完成 可以点击 ------------
					self.canTouch = true
					------------ 动画完成 可以点击 ------------
				end))
			backBtn:runAction(btnActionSeq)

			local otherBtnActionSeq = cc.Sequence:create(
				cc.DelayTime:create(delayFrame / self.fps),
				cc.Show:create(),
				cc.FadeTo:create(0.5, 255)
			)
			if GAME_MODULE_OPEN.BATTLE_SKADA then
				skadaBtn:runAction(otherBtnActionSeq:clone())
			end

			if nil ~= repeatBtn then
				repeatBtn:runAction(otherBtnActionSeq:clone())
			end
		end

		local HideSelf = function (delayFrame)
			
		end

		return {ShowSelf = ShowSelf, HideSelf = HideSelf}

	else

		-- 其他类型都有第二层的展示
		local nextLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('点击空白处继续')}))
		display.commonUIParams(nextLabel, {po = cc.p(
			display.cx + 375,
			30
		)})
		parentNode:addChild(nextLabel, 99)

		------------ 初始化动画状态 ------------
		nextLabel:setVisible(false)
		nextLabel:setOpacity(0)
		------------ 初始化动画状态 ------------

		local ShowSelf = function (delayFrame)
			------------ 下一层文字 ------------
			local nextLabelActionSeq = cc.Sequence:create(
				cc.DelayTime:create(delayFrame / self.fps),
				cc.Show:create(),
				cc.FadeTo:create(0.5, 255),
				cc.CallFunc:create(function ()
					------------ 动画完成 可以点击 ------------
					self.canTouch = true
					------------ 动画完成 可以点击 ------------
				end))
			nextLabel:runAction(nextLabelActionSeq)
			------------ 下一层文字 ------------
		end

		local HideSelf = function (delayFrame)
			
		end

		return {ShowSelf = ShowSelf, HideSelf = HideSelf}

	end
end
--[[
初始化第二层 经验 道具
--]]
function BattleSuccessView:InitExpLayer()
	local layerSize = cc.size(display.SAFE_RECT.width, display.SAFE_RECT.height)

	-- 刷新卡牌经验需要的数据
	self.expBars = {}
	self.levelLabels = {}
	self.expLeft = {}

	local animationConf = {
		titleMoveY = 65,
		titleMoveTime = 10,
		contentBgDelayTime = 2,
		contentBgMoveY = 75,
		contentBgMoveTime = 10 
	}

	-- 通用层节点
	local expLayer = display.newLayer(display.SAFE_L + layerSize.width * 0.5, layerSize.height * 0.5,
		{size = layerSize, ap = cc.p(0.5, 0.5)})
	self:addChild(expLayer, 3)

	local contentBg = display.newImageView(_res('ui/battle/battleresult/settlement_bg_reward.png'), 0, 0)
	local contentBgSize = contentBg:getContentSize()
	local contentBgLayer = display.newLayer(0, 0, {size = contentBgSize, ap = cc.p(0.5, 0.5)})
	display.commonUIParams(contentBgLayer, {po = cc.p(
		layerSize.width - contentBgSize.width * 0.5,
		layerSize.height * 0.5
	)})
	expLayer:addChild(contentBgLayer)
	contentBgLayer:setTag(3)

	display.commonUIParams(contentBg, {po = utils.getLocalCenter(contentBgLayer)})
	contentBgLayer:addChild(contentBg)

	self.rewardsParentNode = contentBgLayer

	local bgCenterX = contentBgLayer:getPositionX() + 10
	local bgBottomY = contentBgLayer:getPositionY() - contentBgLayer:getContentSize().height * 0.5

	-- 标题
	local titleLabel = display.newImageView(_res('ui/battle/battleresult/settlement_ico_pass_reward.png'), 0, 0)
	display.commonUIParams(titleLabel, {po = cc.p(
		bgCenterX,
		contentBgLayer:getPositionY() + contentBgLayer:getContentSize().height * 0.5 + titleLabel:getContentSize().height * 0.5 + 10
	)})
	expLayer:addChild(titleLabel)

	-- 一级货币奖励
	self:AddStairCurrencyLayer(contentBgLayer)

	------------ 经验模块 ------------
	-- 背景
	local headIconBg = display.newImageView(_res('ui/battle/battleresult/settlement_bg_reward_white.png'), 0, 0)
	display.commonUIParams(headIconBg, {po = cc.p(
		contentBgSize.width * 0.5 + 20,
		contentBgSize.height * 0.675
	)})
	contentBgLayer:addChild(headIconBg)

	-- 文字
	local expLabel = display.newLabel(0, 0, fontWithColor('6', {text = __('卡牌提升'), color = '#c5c5c5'}))
	display.commonUIParams(expLabel, {ap = cc.p(0, 0), po = cc.p(
		headIconBg:getPositionX() - headIconBg:getContentSize().width * 0.5,
		headIconBg:getPositionY() + headIconBg:getContentSize().height * 0.5 + 5
	)})
	contentBgLayer:addChild(expLabel)

	local maxCardAmount = 5
	local paddingX = 10
	local cellWidth = (headIconBg:getContentSize().width - paddingX * 2) / maxCardAmount
	local nextExpData, curExpData = nil, nil
	local addFavorNodes = {}

	for i,v in ipairs(self.teamData) do
		-- 头像
		local cardHeadNode = require('common.CardHeadNode').new({
			id = checkint(v.id),
			showBaseState = false,
			showActionState = false,
			showVigourState = false
		})
		cardHeadNode:setPosition(cc.p(
			paddingX + (i - 0.5) * cellWidth,
			headIconBg:getContentSize().height * 0.5
		))
		local cardHeadNodeScale = (cellWidth - 10) / cardHeadNode:getContentSize().width
		cardHeadNode:setScale(cardHeadNodeScale)
		headIconBg:addChild(cardHeadNode)

		-- 经验条
		nextExpData = CommonUtils.GetConfig('cards', 'level', checkint(v.level) + 1) or {}
		curExpData = CommonUtils.GetConfig('cards', 'level', checkint(v.level)) or {}

		local expBarBg = display.newNSprite(_res('ui/battle/battleresult/result_bar_bg.png'), 0, 0)
		display.commonUIParams(expBarBg, {po = cc.p(
			cardHeadNode:getPositionX(),
			cardHeadNode:getPositionY() - cardHeadNode:getContentSize().height * 0.5 * cardHeadNodeScale - expBarBg:getContentSize().height * 0.5
		)})
		headIconBg:addChild(expBarBg)

		local expBar = cc.ProgressTimer:create(cc.Sprite:create(_res('ui/battle/battleresult/result_bar_1.png')))
		expBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
		expBar:setMidpoint(cc.p(0, 0))
		expBar:setBarChangeRate(cc.p(1, 0))
		expBar:setPercentage((checkint(v.exp) - checkint(curExpData.totalExp)) / checkint(nextExpData.exp) * 100)
		expBar:setPosition(utils.getLocalCenter(expBarBg))
		expBarBg:addChild(expBar)

		-- 等级
		local levelLabel = display.newLabel(0, 0, fontWithColor('3', {text = string.format(__('%d级'), checkint(v.level))}))
		display.commonUIParams(levelLabel, {ap = cc.p(0.5, 1), po = cc.p(
			expBarBg:getPositionX(),
			expBarBg:getPositionY() - expBarBg:getContentSize().height * 0.5 - 2
		)})
		headIconBg:addChild(levelLabel)

		-- 好感度
	    if nil ~= self.trophyData.favorabilityCards and nil ~= self.trophyData.favorabilityCards[tostring(v.id)] then
	    	local favorSpine = sp.SkeletonAnimation:create(
	    		'battle/effect/haogan.json',
	    		'battle/effect/haogan.atlas',
	    		1
	    	)
	    	favorSpine:update(0)
	    	favorSpine:setPosition(cc.p(cardHeadNode:getPositionX(), cardHeadNode:getPositionY()))
	    	headIconBg:addChild(favorSpine, 5)
	    	favorSpine:setVisible(false)

	    	addFavorNodes[tostring(v.id)] = favorSpine
	    end

		------------ 计算经验差值 ------------
		local deltaExp = 0
		if nil ~= self.trophyData.cardExp and nil ~= self.trophyData.cardExp[tostring(v.id)] then
			deltaExp = checkint(self.trophyData.cardExp[tostring(v.id)].exp) - gameMgr:GetCardDataById(v.id).exp
		end

		local addExpLabel = display.newLabel(0, 0, fontWithColor('3', {text = string.format(__('+%d经验'), deltaExp), fontSize = BattleConfigUtils:UseJapanLocalize() and 22 or 24}))
		display.commonUIParams(addExpLabel, {ap = cc.p(0.5, 0), po = cc.p(
			cardHeadNode:getPositionX(),
			cardHeadNode:getPositionY() + cardHeadNode:getContentSize().height * 0.5 * cardHeadNodeScale
		)})
		headIconBg:addChild(addExpLabel)
		------------ 计算经验差值 ------------

		self.expBars[tostring(v.id)] = expBar
		self.levelLabels[tostring(v.id)] = levelLabel
		self.expLeft[tostring(v.id)] = deltaExp
		
	end
	------------ 经验模块 ------------

	------------ 奖励模块 ------------
	if ConfigBattleResultType.NO_DROP ~= self.viewType then
		-- 背景
		local rewardBg = display.newImageView(_res('ui/battle/battleresult/settlement_bg_reward_white.png'), 0, 0)
		display.commonUIParams(rewardBg, {po = cc.p(
			headIconBg:getPositionX(),
			headIconBg:getPositionY() - rewardBg:getContentSize().height - 60
		)})
		contentBgLayer:addChild(rewardBg)
		self.rewardsBg = rewardBg

		-- 未掉落奖励提示
		local norewardsLabel = display.newLabel(0, 0, fontWithColor('3', {text = __('未掉落道具')}))
		display.commonUIParams(norewardsLabel, {po = utils.getLocalCenter(rewardBg)})
		rewardBg:addChild(norewardsLabel)

		-- 文字
		local rewardLabel = display.newLabel(0, 0, fontWithColor('6', {text = __('获得奖励'), color = '#c5c5c5'}))
		display.commonUIParams(rewardLabel, {ap = cc.p(0, 0), po = cc.p(
			rewardBg:getPositionX() - rewardBg:getContentSize().width * 0.5,
			rewardBg:getPositionY() + rewardBg:getContentSize().height * 0.5 + 5
		)})
		contentBgLayer:addChild(rewardLabel)

		-- 添加奖励
		if self.trophyData and self.trophyData.rewards then
			norewardsLabel:setVisible(0 >= #self.trophyData.rewards)
			self:AddRewards(self.trophyData.rewards)
		end
	end
	------------ 奖励模块 ------------

	------------ 添加底部按钮 ------------
	local expBottomLayer = self:AddExpBottomLayer(expLayer)
	------------ 添加底部按钮 ------------

	------------ 初始化动画状态 ------------
	expLayer:setVisible(false)

	titleLabel:setVisible(false)
	titleLabel:setOpacity(0)
	titleLabel:setPositionY(titleLabel:getPositionY() - animationConf.titleMoveY)

	contentBgLayer:setVisible(false)
	contentBgLayer:setOpacity(0)
	contentBgLayer:setPositionY(contentBgLayer:getPositionY() - animationConf.contentBgMoveY)
	------------ 初始化动画状态 ------------

	local ShowSelf = function ()
		expLayer:setVisible(true)

		local delayTime = 10 / self.fps
		local costFrame = 17

		------------ 标题动画 ------------
		local titleLabelActionSeq = cc.Sequence:create(
			cc.DelayTime:create(delayTime),
			cc.Show:create(),
			cc.Spawn:create(
				cc.MoveBy:create(animationConf.titleMoveTime / self.fps, cc.p(0, animationConf.titleMoveY)),
				cc.FadeTo:create(animationConf.titleMoveTime / self.fps, 255)))
		titleLabel:runAction(titleLabelActionSeq)
		------------ 标题动画 ------------

		------------ 主要层动画 ------------
		local contentBgActionSeq = cc.Sequence:create(
			cc.DelayTime:create(delayTime + animationConf.contentBgDelayTime / self.fps),
			cc.Show:create(),
			cc.Spawn:create(
				cc.MoveBy:create(animationConf.contentBgMoveTime / self.fps, cc.p(0, animationConf.contentBgMoveY)),
				cc.FadeTo:create(animationConf.contentBgMoveTime / self.fps, 255)
			),
			cc.CallFunc:create(function ()
				local addFavorNode = nil
				local favorData = nil
				for i,v in ipairs(self.teamData) do

					------------ 好感度动画 ------------
					addFavorNode = addFavorNodes[tostring(v.id)]
					if self.trophyData.favorabilityCards and addFavorNode then
						favorData = self.trophyData.favorabilityCards[tostring(v.id)]
						if nil ~= favorData then
							if checkint(favorData.favorabilityLevel) > checkint(v.favorLevel) then
								addFavorNode:setVisible(true)
								addFavorNode:setAnimation(0, 'play2', false)
							elseif checkint(favorData.favorability) > checkint(v.favorExp) then
								addFavorNode:setVisible(true)
								addFavorNode:setAnimation(0, 'play1', false)
							end

							-- 好感度音效
							PlayAudioClip(AUDIOS.UI.ui_levelup.id)
						end
					end
					------------ 好感度动画 ------------

					------------ 刷新经验条 ------------
					-- 经验提升时播放音效
					if 0 < checkint(self.expLeft[tostring(v.id)]) then
						PlayAudioClip(AUDIOS.UI.ui_levelup.id)
					end
					self:RefreshExp(checkint(v.id))
					------------ 刷新经验条 ------------

				end
			end))
		contentBgLayer:runAction(contentBgActionSeq)
		------------ 主要层动画 ------------

		------------ 底部按钮 ------------
		if expBottomLayer and expBottomLayer.ShowSelf then
			expBottomLayer.ShowSelf(costFrame)
		end
		------------ 底部按钮 ------------

	end

	local HideSelf = function ()

	end

	local layer = {ShowSelf = ShowSelf, HideSelf = HideSelf}
	return layer
end
--[[
添加一级货币奖励
@params parentNode cc.Node 父节点
--]]
function BattleSuccessView:AddStairCurrencyLayer(parentNode)
	if nil == self.trophyData then return end

	local stairCurrencyInfo = {
		{goodsId = EXP_ID, fieldName = 'mainExp', isFinalAmount = true},
		{goodsId = GOLD_ID, fieldName = 'gold', isFinalAmount = true},
	}

	if QuestBattleType.PVC == G_BattleMgr:GetQuestBattleType() then
		stairCurrencyInfo = {
			{goodsId = PVC_POINT_ID, fieldName = 'integral', isFinalAmount = false},
			{goodsId = PVC_MEDAL_ID, fieldName = 'medal', isFinalAmount = true},
		}
	elseif QuestBattleType.UNION_BEAST == G_BattleMgr:GetQuestBattleType() then
		stairCurrencyInfo = {
			{goodsId = UNION_POINT_ID, fieldName = 'unionPoint', isFinalAmount = false},
			{goodsId = UNION_CONTRIBUTION_POINT_ID, fieldName = 'contributionPoint', isFinalAmount = false},
		}
	end

	local currencyAmount = nil
	local deltaAmount = nil

	local goodsIconScale = 0.25
	local currencyNodes = {}

	for i,v in ipairs(stairCurrencyInfo) do
		currencyAmount = self.trophyData[v.fieldName]
		if nil ~= currencyAmount then
			currencyAmount = checkint(currencyAmount)
			-- 计算差值
			if v.isFinalAmount then
				deltaAmount = currencyAmount - gameMgr:GetAmountByIdForce(v.goodsId)
			else
				deltaAmount = currencyAmount
			end
			local goodsIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(v.goodsId)), 0, 0)
			goodsIcon:setScale(goodsIconScale)
			parentNode:addChild(goodsIcon)

			local goodsAmountLabel = display.newLabel(0, 0, {text = string.format('+%d', deltaAmount), fontSize = 26, color = '#ffd146'})
			parentNode:addChild(goodsAmountLabel)

			currencyNodes[i] = {goodsIcon = goodsIcon, goodsAmountLabel = goodsAmountLabel}
		end
	end

	-- 刷新货币位置
	local nodesAmount = #currencyNodes
	local cellWidth = 200
	local bgCenterX = parentNode:getContentSize().width * 0.5 + 20
	local x, y = 0, parentNode:getContentSize().height - 30
	for i,v in ipairs(currencyNodes) do
		x = bgCenterX + ((i - 0.5) - nodesAmount * 0.5) * cellWidth

		display.commonUIParams(v.goodsIcon, {ap = cc.p(1, 0.5), po = cc.p(
			x - 1,
			y
		)})

		display.commonUIParams(v.goodsAmountLabel, {ap = cc.p(0, 0.5), po = cc.p(
			x + 1,
			y
		)})
	end
end
--[[
添加奖励
@params rewards list 奖励列表
--]]
function BattleSuccessView:AddRewards(rewards)
	if nil == self.rewardsBg then return end

	for i,v in ipairs(rewards) do
		local goodsIcon = require('common.GoodNode').new({
			id = checkint(v.goodsId),
			amount = checkint(v.num),
			showAmount = true,
			callBack = function (sender)
				AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
			end
		})
		self.rewardsParentNode:addChild(goodsIcon, 99)
		table.insert(self.rewardNodes, goodsIcon)
	end

	display.setNodesToNodeOnCenter(self.rewardsBg, self.rewardNodes, {spaceW = 15})
end
--[[
添加经验层底部按钮
@params parentNode cc.Node 父节点
--]]
function BattleSuccessView:AddExpBottomLayer(parentNode)
	local contentBgNode = parentNode:getChildByTag(3)

	local animationConf = {
		backBtnMoveY = 75,
		backBtnMoveTime = 5
	}

	-- 返回按钮
	local backBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
	display.commonUIParams(backBtn, {po = cc.p(
		contentBgNode:getPositionX() + contentBgNode:getContentSize().width * 0.5 - backBtn:getContentSize().width * 0.5 - 35,
		contentBgNode:getPositionY() - contentBgNode:getContentSize().height * 0.5 - backBtn:getContentSize().height * 0.5 - 10
	)})
	display.commonLabelParams(backBtn, fontWithColor('14', {text = __('退出')}))
	parentNode:addChild(backBtn)
	self.backBtn = backBtn
	local x = backBtn:getPositionX()

	-- 重打按钮
	local repeatBtn = nil
	if self:CanRepeatChallenge() then
		-- 重新挑战按钮
		x = x - 400
		repeatBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
		display.commonUIParams(repeatBtn, {po = cc.p(
			backBtn:getPositionX() - 400,
			backBtn:getPositionY()
		)})
		display.commonLabelParams(repeatBtn, fontWithColor('14', {text = __('重新挑战')}))
		parentNode:addChild(repeatBtn)
		self.repeatBtn = repeatBtn
	end

	-- 伤害统计按钮
	local skadaBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_white_default.png') , scale9 = true })
	x = x - (skadaBtn:getContentSize().width * 0.5 + backBtn:getContentSize().width * 0.5 + 50)
	display.commonUIParams(skadaBtn, {po = cc.p(
		x,
		backBtn:getPositionY()
	)})
	display.commonLabelParams(skadaBtn, fontWithColor('14', {text = __('伤害统计') , paddingW = 10}))
	parentNode:addChild(skadaBtn)
	self.skadaBtn = skadaBtn

	------------ 初始化动画状态 ------------
	backBtn:setVisible(false)
	backBtn:setOpacity(0)
	backBtn:setPositionY(backBtn:getPositionY() - animationConf.backBtnMoveY)

	if nil ~= repeatBtn then
		repeatBtn:setVisible(false)
		repeatBtn:setOpacity(0)
		repeatBtn:setPositionY(repeatBtn:getPositionY() - animationConf.backBtnMoveY)
	end

	skadaBtn:setVisible(false)
	skadaBtn:setOpacity(0)
	skadaBtn:setPositionY(skadaBtn:getPositionY() - animationConf.backBtnMoveY)
	------------ 初始化动画状态 ------------

	local ShowSelf = function (delayFrame)
		local backBtnActionSeq = cc.Sequence:create(
			cc.DelayTime:create(delayFrame / self.fps),
			cc.Show:create(),
			cc.Spawn:create(
				cc.MoveBy:create(animationConf.backBtnMoveTime / self.fps, cc.p(0, animationConf.backBtnMoveY)),
				cc.FadeTo:create(animationConf.backBtnMoveTime / self.fps, 255)),
			cc.CallFunc:create(function ()
				self.canTouch = true
			end))
		backBtn:runAction(backBtnActionSeq)

		local otherBtnActionSeq = cc.Sequence:create(
			cc.DelayTime:create(delayFrame / self.fps),
			cc.Show:create(),
			cc.Spawn:create(
				cc.MoveBy:create(animationConf.backBtnMoveTime / self.fps, cc.p(0, animationConf.backBtnMoveY)),
				cc.FadeTo:create(animationConf.backBtnMoveTime / self.fps, 255)
			)
		)
		if GAME_MODULE_OPEN.BATTLE_SKADA then
			skadaBtn:runAction(otherBtnActionSeq:clone())
		end

		if nil ~= repeatBtn then
			repeatBtn:runAction(otherBtnActionSeq:clone())
		end
	end

	local HideSelf = function ()

	end

	return {ShowSelf = ShowSelf, HideSelf = HideSelf}
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- ui control begin --
---------------------------------------------------
--[[
显示下一步的ui层
--]]
function BattleSuccessView:ShowNextLayer()
	if nil ~= self.curLayer and self.curLayer.HideSelf and #self.layers > 0 then
		-- 若存在上一层 隐藏上一层
		self.curLayer:HideSelf()
	end
	if #self.layers > 0 then
		-- 变换上一层
		self.curLayer = self.layers[1]
		if self.curLayer.ShowSelf then
			self.curLayer:ShowSelf()
		end
		-- 将上一层指针出栈
		table.remove(self.layers, 1)
	else
		-- 不存在下一层
		self.curLayer = nil
	end
end
--[[
刷新经验条动画
@params id int 卡牌id
--]]
function BattleSuccessView:RefreshExp(id)
	if nil == self.expLeft[tostring(id)] or 0 >= self.expLeft[tostring(id)] then return end

	local cardInfo = nil
	local idx = 0
	for i,v in ipairs(self.teamData) do
		if checkint(v.id) == id then
			cardInfo = v
			idx = i
			break
		end
	end

	local expData = CommonUtils.GetConfig('cards', 'level', checkint(cardInfo.level) + 1)
	local expLeft = self.expLeft[tostring(id)]
	local cardData = gameMgr:GetCardDataById(id)

	------------ !!! 判断是否升级 !!! ------------
	-- 需要满足 当前经验加上获得经验满足升级条件
	-- 并且卡牌可以升到下一级 卡牌等级有锁级限制
	-- 此时获取的玩家等级是已经刷新过的玩家等级
	------------ !!! 判断是否升级 !!! ------------

	if (checkint(cardInfo.level) + 1) <= cardMgr.GetCardMaxLevelByCardId(checkint(cardInfo.cardId), gameMgr:GetUserInfo().level, cardData.breakLevel) and
		(cardInfo.exp + expLeft >= expData.totalExp) then

		-- 能升级
		local progressAction = cc.Sequence:create(
			cc.ProgressTo:create(0.75, 100),
			cc.CallFunc:create(function ()
				local expBar = self.expBars[tostring(id)]

				-- 出现升级了文字
				local p = cc.p(
					expBar:getParent():getPositionX(),
					expBar:getParent():getPositionY()
				)
				local levelUpLabel = display.newNSprite(_res('ui/battle/result_levelup.png'), p.x, p.y + 25)
				expBar:getParent():getParent():addChild(levelUpLabel, 99)

				levelUpLabel:setOpacity(0)
				local levelUpActionSeq = cc.Sequence:create(
					cc.Spawn:create(
						cc.MoveBy:create(20 / self.fps, cc.p(0, 50)),
						cc.Sequence:create(
							cc.FadeTo:create(5 / self.fps, 255),
							cc.DelayTime:create(10 / self.fps),
							cc.FadeTo:create(5 / self.fps, 0)
						)
					),
					cc.RemoveSelf:create()
				)
				levelUpLabel:runAction(levelUpActionSeq)

				self.expBars[tostring(id)]:setPercentage(0)
				self.levelLabels[tostring(id)]:setString(string.format(__('%d级'), self.teamData[idx].level))

				-- 递归刷新
				self:RefreshExp(id)
			end)
		)
		self.expBars[tostring(id)]:runAction(progressAction)
		self.expLeft[tostring(id)] = self.expLeft[tostring(id)] - (checkint(expData.totalExp) - checkint(cardInfo.exp))
		self.teamData[idx].exp = expData.totalExp
		self.teamData[idx].level = checkint(cardInfo.level) + 1

	else

		-- 升不了级
		local percent = (cardInfo.exp + expLeft - (expData.totalExp - expData.exp)) / expData.exp * 100
		local progressAction = cc.Sequence:create(
			cc.ProgressTo:create(0.75 * percent * 0.01, percent))
		self.expBars[tostring(id)]:runAction(progressAction)
		self.expLeft[tostring(id)] = nil
		self.teamData[idx].exp = cardInfo.exp + expLeft

	end


end
--[[
显示评论列表
@params show bool 是否显示评论列表
--]]
function BattleSuccessView:ShowSelectMessage(show)
	self.messageListViewBg:setVisible(show)
	self.messageListView:setVisible(show)
end
--[[
根据选择的评论idx刷新界面
@params index int 评论序号
--]]
function BattleSuccessView:RefreshMessageByIndex(index)
	if index == self.selectedMessageIndex then return end

	-- 刷新选中状态
	if nil ~= index then
		local curCell = self.messageListView:getNodeAtIndex(index - 1)
		if nil ~= curCell then
			curCell:getChildByTag(9867):setVisible(true)

			-- 刷新展示文字
			local messageConfigs = CommonUtils.GetConfigAllMess('robberyRidicule', 'takeaway')
			local messageAmount = table.nums(messageConfigs)
			local messageId = curCell:getTag()
			local messageStr = ''

			if messageAmount < index then
				messageStr = __('(不留言)')
			else
				messageStr = messageConfigs[tostring(messageId)].descr
			end
			self.messageLabel:setString(messageStr)
		end
	end

	if nil ~= self.selectedMessageIndex then
		local preCell = self.messageListView:getNodeAtIndex(self.selectedMessageIndex - 1)
		if nil ~= preCell then
			preCell:getChildByTag(9867):setVisible(false)
		end	
	end

	self.selectedMessageIndex = index
end
---------------------------------------------------
-- ui control end --
---------------------------------------------------

---------------------------------------------------
-- data control begin --
---------------------------------------------------
--[[
更新本地数据
--]]
function BattleSuccessView:UpdateLocalData()
	------------ 刷新本地数据 ------------
	if self.trophyData then

		local newestUserData = {}

		-- 玩家体力
		if self.trophyData.hp then
			newestUserData.hp = self.trophyData.hp
		end

		-- 玩家经验
		if self.trophyData.mainExp then
			local newestExpData = {}
			newestExpData.mainExp = checkint(self.trophyData.mainExp)

			local level = gameMgr:GetUserInfo().level
			local expData = CommonUtils.GetConfig('player', 'level', level + 1)
			newestExpData.level = level

			while (nil ~= newestExpData and nil ~= expData) and (newestExpData.mainExp >= checkint(expData.totalExp)) do
				print('here log while when calc main exp')
				newestExpData.level = checkint(expData.level)
				expData = CommonUtils.GetConfig('player', 'level', newestExpData.level + 1)

				if nil == expData then
					break
				end
			end

			gameMgr:UpdatePlayer(newestExpData)

			self.delayUpgradeLevelData  =  {
				isLevel = gameMgr:GetUserInfo().level > level,
				newLevel = gameMgr:GetUserInfo().level,
				oldLevel = level,
				canJump = false,
				canJumpHint = __('战斗中无法跳转哦')
			}
		end

		-- 关卡数
		if self.trophyData.newestQuestId then
			-- 插入一个调出剧情的标识
			if checkint(self.trophyData.newestQuestId) == 2 and gameMgr:GetUserInfo().newestQuestId == 1 then
				gameMgr:GetUserInfo().isFirstGuide = true
			end

			newestUserData.newestQuestId = checkint(self.trophyData.newestQuestId)
		end
		if self.trophyData.newestHardQuestId then
			newestUserData.newestHardQuestId = checkint(self.trophyData.newestHardQuestId)
		end
		if self.trophyData.newestInsaneQuestId then
			newestUserData.newestInsaneQuestId = checkint(self.trophyData.newestInsaneQuestId)
		end

		-- 金币
		if self.trophyData.gold then
			newestUserData.gold = checkint(self.trophyData.gold)
		end

		-- 竞技场勋章
		if self.trophyData.medal then
			newestUserData.medal = checkint(self.trophyData.medal)
		end

		-- 刷新玩家信息
		gameMgr:UpdatePlayer(newestUserData)
		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)

		-- 卡牌信息 等级 经验
		if self.trophyData.cardExp then
			for k,v in pairs(self.trophyData.cardExp) do
				if checkint(k) > 0 then
					gameMgr:UpdateCardDataById(k, v)
				end
			end
		end

		-- 卡牌信息 活力
		if self.trophyData.cardsVigour then
			for k,v in pairs(self.trophyData.cardsVigour) do
				if checkint(k) > 0 then
					local data = {vigour = checknumber(v)}
					gameMgr:UpdateCardDataById(k, data)
				end
			end
		end

		-- 卡牌信息 好感度等级
		if self.trophyData.favorabilityCards then
			for k,v in pairs(self.trophyData.favorabilityCards) do
				if checkint(k) > 0 then
					local data = {
						favorability = checkint(v.favorability),
						favorabilityLevel = checkint(v.favorabilityLevel)
					}
					gameMgr:UpdateCardDataById(k, data)
				end
			end
		end

		-- 剩余挑战次数
		if self.trophyData.challengeTime then

			-- 刷新重复挑战次数
			local stageId = checkint(self.trophyData.requestData.questId)
			if nil ~= stageId then
				local stageConf = CommonUtils.GetQuestConf(stageId)

				if nil ~= stageConf and
					ValueConstants.V_NORMAL == checkint(stageConf.repeatChallenge) and
					ValueConstants.V_NONE < checkint(stageConf.challengeTime) then

					-- 满足 可以重复挑战 并且挑战次数大于0 刷新剩余挑战次数
					gameMgr:UpdateChallengeTimeByStageId(stageId, checkint(self.trophyData.challengeTime))

				end
			end

		end

		-- 道具信息
		if self.trophyData.rewards then
			CommonUtils.DrawRewards(checktable(self.trophyData.rewards))
		end

	end
	------------ 刷新本地数据 ------------
end
--[[
是否可以重打
@return _ bool
--]]
function BattleSuccessView:CanRepeatChallenge()
	return self.canRepeatChallenge
end
---------------------------------------------------
-- data control end --
---------------------------------------------------

---------------------------------------------------
-- click callback begin --
---------------------------------------------------
--[[
评论cell的按钮回调
--]]
function BattleSuccessView:MessageClickCallback(sender)
	if not self.canTouch then return end
	local index = sender:getTag()
	self:RefreshMessageByIndex(index)
	self:ShowSelectMessage(false)
end
--[[
退出按钮的回调
--]]
function BattleSuccessView:BackClickCallback(sender)
	if not self.canTouch then return end
	if not self.canTouchBackBtn then return end
	-- 如果留有打劫留言 先请求一次服务器
	if self.showMessage then
		local messageId = nil
		if nil ~= self.selectedMessageIndex and nil ~= self.trophyData.logRobberyId then
			local curCell = self.messageListView:getNodeAtIndex(self.selectedMessageIndex - 1)
			if nil ~= curCell then
				messageId = curCell:getTag()
				if nil ~= CommonUtils.GetConfigAllMess('robberyRidicule', 'takeaway')[tostring(messageId)] then
					self:SendMessageAndBack(messageId)
				else
					self.canTouch = false
					self.canTouchBackBtn = false
					G_BattleMgr:QuitBattle()
				end
			end
		end
	else
		self.canTouch = false
		self.canTouchBackBtn = false
		G_BattleMgr:QuitBattle()
	end
end
--[[
发送评论留言
@params messageId int 留言id
--]]
function BattleSuccessView:SendMessageAndBack(messageId)
	----- network command -----
	local function callback(responseData)
		self.canTouch = false
		self.canTouchBackBtn = false
		G_BattleMgr:QuitBattle()
	end

	AppFacade.GetInstance():DispatchObservers('BATTLE_COMMON_NETWORK_REQUEST', {
		requestCommand = POST.TAKEAWAY_ROBBERY_RIDICULE.cmdName,
		responseSignal = POST.TAKEAWAY_ROBBERY_RIDICULE.sglName,
		data = {
			logRobberyId = self.trophyData.logRobberyId,
			ridicule = messageId
		},
		callback = callback
	})
	----- network command -----
end
--[[
重新挑战按钮回调
--]]
function BattleSuccessView:RechallengeClickCallback(sender)
	
end
--[[
显示伤害统计界面按钮回调
--]]
function BattleSuccessView:SkadaClickHandler(sender)
	if G_BattleMgr:GetBattleInvalid() then return end
	PlayAudioByClickNormal()
	G_BattleMgr:ShowSkada()
end
--[[
注册按钮回调
--]]
function BattleSuccessView:RegistBtnClickHandler()
	if nil ~= self.backBtn then
		display.commonUIParams(self.backBtn, {cb = handler(self, self.BackClickCallback)})
	end

	if nil ~= self.repeatBtn then
		display.commonUIParams(self.repeatBtn, {cb = handler(self, self.RechallengeClickCallback)})
	end

	if nil ~= self.skadaBtn then
		display.commonUIParams(self.skadaBtn, {cb = handler(self, self.SkadaClickHandler)})
	end
end
---------------------------------------------------
-- click callback end --
---------------------------------------------------

---------------------------------------------------
-- cocos2dx callback begin --
---------------------------------------------------
function BattleSuccessView:onEnter()
	self:ShowNextLayer()
	------------ 停掉录像 ------------
	BattleUtils.StopScreenRecord()
	------------ 停掉录像 ------------
end

function BattleSuccessView:onCleanup()
	AppFacade.GetInstance():DispatchObservers(
		SIGNALNAMES.PlayerLevelUpExchange,
		self.delayUpgradeLevelData
	)
end
---------------------------------------------------
-- cocos2dx callback end --
---------------------------------------------------

return BattleSuccessView
