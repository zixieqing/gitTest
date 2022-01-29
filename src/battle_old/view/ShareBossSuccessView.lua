--[[
共享血量模式结算
--]]
local BattleSuccessView = __Require('battle.view.BattleSuccessView')
local ShareBossSuccessView = class('ShareBossSuccessView', BattleSuccessView)

------------ import ------------
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance('AppFacade'):GetManager("CardManager")
local uiMgr = AppFacade.GetInstance('AppFacade'):GetManager("UIManager")
local unionMgr = AppFacade.GetInstance():GetManager('UnionManager')
------------ import ------------

------------ define ------------

------------ define ------------

--[[
@override
constructor
--]]
function ShareBossSuccessView:ctor( ... )
	local args = unpack({...})

	self.totalTime = checknumber(args.totalTime)
	self.totalDamage = checkint(args.totalDamage)

	cc.Director:getInstance():getScheduler():setTimeScale(1)

	BattleSuccessView.ctor(self, ...)
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化ui
--]]
function ShareBossSuccessView:InitUI()
	local commonLayer = self:InitCommonLayer()
	table.insert(self.layers, commonLayer)

	local expLayer = self:InitExpLayer()
	table.insert(self.layers, expLayer)

	if self.trophyData.rewards then
		local rewardsLayer = self:InitRewardsLayer()
		table.insert(self.layers, rewardsLayer)
	end

	local commonDamageLayer = self:InitCommonDamageLayer()
	table.insert(self.layers, commonDamageLayer)

	if nil ~= self.backBtn then
		display.commonUIParams(self.backBtn, {cb = handler(self, self.BackClickCallback)})
	end

	if nil ~= self.repeatBtn then
		display.commonUIParams(self.repeatBtn, {cb = handler(self, self.RechallengeClickCallback)})
	end
end
--[[
初始化公有层 公有层只包含立绘 共享血量战斗不存在胜负
--]]
function ShareBossSuccessView:InitCommonLayer()
	local layerSize = cc.size(display.SAFE_RECT.width, display.SAFE_RECT.height)

	local animationConf = {
		bgMaskFadeInTime = 8,
		drawAppearDelayTime = 30,
		drawAppearTime = 20,
		drawMoveY = 43,
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
					CommonUtils.PlayCardSoundByCardId(cardId, SoundType.TYPE_UPGRADE_STAR, SoundChannel.BATTLE_RESULT)
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

	-- 立绘
	local leaderData = self.teamData[1]
	local drawNode = require('common.CardSkinDrawNode').new({
		skinId = checkint(leaderData.skinId),
		coordinateType = COORDINATE_TYPE_CAPSULE
	})
	self:addChild(drawNode, 2)
	self.drawNode = drawNode

	------------ 初始化动画状态 ------------
	bgMask:setOpacity(0)
	drawNode:setVisible(false)
	drawNode:setOpacity(0)
	drawNode:setPositionY(drawNode:getPositionY() - animationConf.drawMoveY)
	------------ 初始化动画状态 ------------

	local ShowSelf = function ()
		------------ 显示遮罩渐变动画 ------------
		local bgMaskActionSeq = cc.Sequence:create(
			cc.FadeTo:create(animationConf.bgMaskFadeInTime / self.fps, 255))
		bgMask:runAction(bgMaskActionSeq)
		------------ 显示遮罩渐变动画 ------------

		------------ 显示立绘 ------------
		local drawNodeActionSeq = cc.Sequence:create(
			cc.DelayTime:create((animationConf.bgMaskFadeInTime) / self.fps),
			cc.Show:create(),
			cc.EaseOut:create(cc.Spawn:create(
				cc.FadeTo:create(animationConf.drawAppearTime / self.fps, 255),
				cc.MoveBy:create(animationConf.drawAppearTime / self.fps, cc.p(0, animationConf.drawMoveY))), 2))
		drawNode:runAction(drawNodeActionSeq)
		------------ 显示立绘 ------------
	end

	local HideSelf = function ()

	end

	local layer = {ShowSelf = ShowSelf, HideSelf = HideSelf}
	return layer
end
--[[
初始化第二层 经验 道具
--]]
function ShareBossSuccessView:InitExpLayer()
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
	self.contentBgLayer = contentBgLayer

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

		local addExpLabel = display.newLabel(0, 0, fontWithColor('3', {text = string.format(__('+%d经验'), deltaExp)}))
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

	------------ 添加底部按钮 ------------
	-- self.expBottomLayer = self:AddExpBottomLayer(expLayer)
	------------ 添加底部按钮 ------------

	------------ 添加奖励背景 ------------
	-- 背景
	local rewardsBg = display.newImageView(_res('ui/battle/battleresult/settlement_bg_reward_white.png'), 0, 0)
	display.commonUIParams(rewardsBg, {po = cc.p(
		headIconBg:getPositionX(),
		headIconBg:getPositionY() - rewardsBg:getContentSize().height - 60
	)})
	contentBgLayer:addChild(rewardsBg)
	self.rewardsBg = rewardsBg

	-- 文字
	local rewardLabel = display.newLabel(0, 0, fontWithColor('6', {text = __('获得奖励'), color = '#c5c5c5'}))
	display.commonUIParams(rewardLabel, {ap = cc.p(0, 0), po = cc.p(
		rewardsBg:getPositionX() - rewardsBg:getContentSize().width * 0.5,
		rewardsBg:getPositionY() + rewardsBg:getContentSize().height * 0.5 + 5
	)})
	contentBgLayer:addChild(rewardLabel)
	self.rewardLabel = rewardLabel
	------------ 添加奖励背景 ------------

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
							PlayUIEffects(AUDIOS.UI.ui_levelup.id)
						end
					end
					------------ 好感度动画 ------------

					------------ 刷新经验条 ------------
					-- 经验提升时播放音效
					if 0 < checkint(self.expLeft[tostring(id)]) then
						PlayUIEffects(AUDIOS.UI.ui_levelup.id)
					end
					self:RefreshExp(checkint(v.id))
					------------ 刷新经验条 ------------

				end
			end))
		contentBgLayer:runAction(contentBgActionSeq)
		------------ 主要层动画 ------------
	end

	local HideSelf = function ()

	end

	local layer = {ShowSelf = ShowSelf, HideSelf = HideSelf}
	return layer

end
--[[
添加奖励层
--]]
function ShareBossSuccessView:InitRewardsLayer()
	if nil == self.rewardsBg then return {} end

	self.rewardLabel:setString(__('获得奖励'))

	local animationConf = {
		titleMoveY = 65,
		titleMoveTime = 10,
		contentBgDelayTime = 2,
		contentBgMoveY = 75,
		contentBgMoveTime = 10 
	}
	local layerSize = cc.size(display.SAFE_RECT.width, display.SAFE_RECT.height)

	local rewardsLayer = display.newLayer(display.SAFE_L + layerSize.width * 0.5, layerSize.height * 0.5,
		{size = layerSize, ap = cc.p(0.5, 0.5)})
	self:addChild(rewardsLayer, 5)
	self.rewardsLayer = rewardsLayer
	-- rewardsLayer:setBackgroundColor(cc.c4b(255, 255, 128, 100))

	local rewardsBgWorldPos = self.rewardsBg:getParent():convertToWorldSpace(cc.p(self.rewardsBg:getPositionX(), self.rewardsBg:getPositionY()))
	local bglayerSize = self.rewardsBg:getContentSize()
	local rewardsBgLayer = display.newLayer(0, 0, {size = bglayerSize})
	display.commonUIParams(rewardsBgLayer, {ap = cc.p(0.5, 0.5), po = rewardsLayer:convertToNodeSpace(rewardsBgWorldPos)})
	rewardsLayer:addChild(rewardsBgLayer)
	-- rewardsBgLayer:setBackgroundColor(cc.c4b(25, 255, 25, 100))

	-- 未掉落奖励提示
	local norewardsLabel = display.newLabel(0, 0, fontWithColor('3', {text = __('未掉落道具')}))
	display.commonUIParams(norewardsLabel, {po = utils.getLocalCenter(rewardsBgLayer)})
	rewardsBgLayer:addChild(norewardsLabel)
	norewardsLabel:setVisible(0 >= #self.trophyData.rewards)

	local rewardIconScale = 1
	for i,v in ipairs(self.trophyData.rewards) do
		local goodsIcon = require('common.GoodNode').new({
			id = checkint(v.goodsId),
			amount = checkint(v.num),
			showAmount = true,
			callBack = function (sender)
				AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
			end
		})
		goodsIcon:setScale(rewardIconScale)
		display.commonUIParams(goodsIcon, {po = cc.p(
			bglayerSize.width * 0.5 + ((i - 0.5) - (#self.trophyData.rewards * 0.5)) * (goodsIcon:getContentSize().width + 15),
			bglayerSize.height * 0.5
		)})
		rewardsBgLayer:addChild(goodsIcon, 99)

		table.insert(self.rewardNodes, goodsIcon)
	end
	-- display.setNodesToNodeOnCenter(rewardsBgLayer, self.rewardNodes, {spaceW = 15})

	-- 第二层展示
	local nextLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('点击空白处继续')}))
	display.commonUIParams(nextLabel, {po = cc.p(
		rewardsBgLayer:getPositionX(),
		30
	)})
	rewardsLayer:addChild(nextLabel, 99)

	------------ 初始化动画状态 ------------
	rewardsLayer:setVisible(false)

	rewardsBgLayer:setVisible(false)
	rewardsBgLayer:setOpacity(0)

	nextLabel:setVisible(false)
	------------ 初始化动画状态 ------------

	local ShowSelf = function ()
		rewardsLayer:setVisible(true)

		local delayTime = 10 / self.fps
		local costFrame = 17

		------------ 奖励层动画 ------------
		local layerActionSeq = cc.Sequence:create(
			cc.DelayTime:create(delayTime + animationConf.contentBgDelayTime / self.fps),
			cc.Show:create(),
			cc.Spawn:create(
				cc.MoveBy:create(animationConf.contentBgMoveTime / self.fps, cc.p(0, animationConf.contentBgMoveY)),
				cc.FadeTo:create(animationConf.contentBgMoveTime / self.fps, 255)
			),
			cc.CallFunc:create(function ()
				self.canTouch = true

				nextLabel:setVisible(true)
			end)
		)
		rewardsBgLayer:runAction(layerActionSeq)
		------------ 奖励层动画 ------------
	end

	local HideSelf = function ()
		self.canTouch = false

		nextLabel:setVisible(false)

		local rewardsActionSeq = cc.Sequence:create(
			cc.FadeTo:create(0.2, 0),
			cc.CallFunc:create(function ()
				rewardsLayer:setVisible(false)
			end)
		)
		rewardsBgLayer:runAction(rewardsActionSeq)
	end

	local layer = {ShowSelf = ShowSelf, HideSelf = HideSelf}
	return layer
end
--[[
添加奖励详细层
--]]
function ShareBossSuccessView:InitCommonDamageLayer()
	if nil == self.rewardsBg then return {} end

	local statisticsInfo = {
		{title = __('战斗用时'), value = self.totalTime, str = tostring(self.totalTime) .. __('秒')},
		{title = __('造成伤害'), value = self.totalDamage, str = tostring(self.totalDamage)}
	}
	if nil ~= self.trophyData and nil ~= self.trophyData.energy and 0 ~= checkint(self.trophyData.energy) then
		local energyInfo = {title = __('获得能量'), value = checkint(self.trophyData.energy), str = checkint(self.trophyData.energy)}
		table.insert(statisticsInfo, energyInfo)
	end

	local animationConf = {
		titleMoveY = 65,
		titleMoveTime = 10,
		contentBgDelayTime = 2,
		contentBgMoveY = 75,
		contentBgMoveTime = 10 
	}

	local layerSize = cc.size(display.SAFE_RECT.width, display.SAFE_RECT.height)

	local damageLayer = display.newLayer(display.SAFE_L + layerSize.width * 0.5, layerSize.height * 0.5,
		{size = layerSize, ap = cc.p(0.5, 0.5)})
	self:addChild(damageLayer, 5)

	local rewardsBgWorldPos = self.rewardsBg:getParent():convertToWorldSpace(cc.p(self.rewardsBg:getPositionX(), self.rewardsBg:getPositionY()))
	local bglayerSize = self.rewardsBg:getContentSize()
	local damageBgLayer = display.newLayer(0, 0, {size = bglayerSize})
	display.commonUIParams(damageBgLayer, {ap = cc.p(0.5, 0.5), po = damageLayer:convertToNodeSpace(rewardsBgWorldPos)})
	damageLayer:addChild(damageBgLayer, 5)
	-- damageBgLayer:setBackgroundColor(cc.c4b(25, 255, 25, 100))

	-- 添加统计信息
	local paddingY = 8
	local cellAmount = 4
	for i,v in ipairs(statisticsInfo) do
		local cellBg = display.newImageView(_res('ui/battle/battleresult/settlement_guild_bg_result.png'), 0, 0)
		display.commonUIParams(cellBg, {po = cc.p(
			bglayerSize.width * 0.5,
			bglayerSize.height - paddingY - ((i - 0.5) * ((bglayerSize.height - paddingY * 2) / cellAmount))
		)})
		damageBgLayer:addChild(cellBg)

		local titleLabel = display.newLabel(0, 0, fontWithColor('18', {text = tostring(v.title)}))
		display.commonUIParams(titleLabel, {ap = cc.p(0, 0.5), po = cc.p(
			20,
			cellBg:getContentSize().height * 0.5
		)})
		cellBg:addChild(titleLabel)

		local valueLabel = display.newLabel(0, 0, fontWithColor('18', {text = v.str, color = '#f6d93d'}))
		display.commonUIParams(valueLabel, {ap = cc.p(1, 0.5), po = cc.p(
			cellBg:getContentSize().width - 25,
			cellBg:getContentSize().height * 0.5
		)})
		cellBg:addChild(valueLabel)
	end

	-- 返回按钮
	local backBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
	display.commonUIParams(backBtn, {po = cc.p(
		self.contentBgLayer:getPositionX() + self.contentBgLayer:getContentSize().width * 0.5 - backBtn:getContentSize().width * 0.5 - 35,
		self.contentBgLayer:getPositionY() - self.contentBgLayer:getContentSize().height * 0.5 - backBtn:getContentSize().height * 0.5 - 10
	)})
	display.commonLabelParams(backBtn, fontWithColor('14', {text = __('退出')}))
	damageLayer:addChild(backBtn)
	self.backBtn = backBtn

	------------ 初始化动画状态 ------------
	damageLayer:setVisible(false)

	damageBgLayer:setVisible(false)
	damageBgLayer:setOpacity(0)

	backBtn:setVisible(false)
	self.canTouchBackBtn = false

	if nil ~= self.rewardsLayer then
		backBtn:setOpacity(0)

		-- 如果存在奖励界面 修正一些动画位置
		damageBgLayer:setPositionY(damageBgLayer:getPositionY() + animationConf.contentBgMoveY)
		backBtn:setPositionY(backBtn:getPositionY() + animationConf.contentBgMoveY)
	end
	------------ 初始化动画状态 ------------

	local ShowSelf = function ()
		damageLayer:setVisible(true)

		local delayTime = 10 / self.fps
		local costFrame = 17

		if nil ~= self.rewardsLayer then
			------------ 统计层动画 ------------
			local layerActionSeq = cc.Sequence:create(
				cc.Show:create(),
				cc.FadeTo:create(animationConf.contentBgMoveTime / self.fps, 255)
			)
			damageBgLayer:runAction(layerActionSeq)
			------------ 统计层动画 ------------

			------------ 返回按钮动画 ------------
			local backBtnActionSeq = cc.Sequence:create(
				cc.Show:create(),
				cc.FadeTo:create(animationConf.contentBgMoveTime / self.fps, 255),
				cc.CallFunc:create(function ()
					self.canTouch = true
					self.canTouchBackBtn = true
				end)
			)
			backBtn:runAction(backBtnActionSeq)
			------------ 返回按钮动画 ------------
		else
			------------ 统计层动画 ------------
			local layerActionSeq = cc.Sequence:create(
				cc.DelayTime:create(delayTime + animationConf.contentBgDelayTime / self.fps),
				cc.Show:create(),
				cc.Spawn:create(
					cc.MoveBy:create(animationConf.contentBgMoveTime / self.fps, cc.p(0, animationConf.contentBgMoveY)),
					cc.FadeTo:create(animationConf.contentBgMoveTime / self.fps, 255)
				)
			)
			damageBgLayer:runAction(layerActionSeq)
			------------ 统计层动画 ------------

			------------ 返回按钮动画 ------------
			local backBtnActionSeq = cc.Sequence:create(
				cc.DelayTime:create(delayTime + animationConf.contentBgDelayTime / self.fps),
				cc.Show:create(),
				cc.Spawn:create(
					cc.MoveBy:create(animationConf.contentBgMoveTime / self.fps, cc.p(0, animationConf.contentBgMoveY)),
					cc.FadeTo:create(animationConf.contentBgMoveTime / self.fps, 255)
				),
				cc.CallFunc:create(function ()
					self.canTouch = true
					self.canTouchBackBtn = true
				end)
			)
			backBtn:runAction(backBtnActionSeq)
			------------ 返回按钮动画 ------------
		end
	end

	local HideSelf = function ()

	end

	local layer = {ShowSelf = ShowSelf, HideSelf = HideSelf}
	return layer
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
更新本地数据
--]]
function ShareBossSuccessView:UpdateLocalData()
	BattleSuccessView.UpdateLocalData(self)

	if self.trophyData then
		-- 工会币
		if self.trophyData.unionPoint then
			CommonUtils.DrawRewards({
				{goodsId = UNION_POINT_ID, amount = checkint(self.trophyData.unionPoint)}
			})
		end

		-- 工会积分
		if self.trophyData.contributionPoint then
			if gameMgr:hasUnion() then
				local newUnionData = {
					playerContributionPoint = checkint(self.trophyData.contributionPoint)
				}
				unionMgr:updateUnionData(newUnionData)
			end
		end
	end
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- cocos2dx callback begin --
---------------------------------------------------
function ShareBossSuccessView:onEnter()
	self:ShowNextLayer()
	self:ShowNextLayer()
	self:ShowNextLayer()
end
---------------------------------------------------
-- cocos2dx callback end --
---------------------------------------------------

return ShareBossSuccessView
