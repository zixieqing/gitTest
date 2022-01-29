--[[
战斗准备界面
@params BattleReadyConstructorStruct 创建战斗选择界面的数据结构
--]]
local BattleReadyView = require('Game.views.BattleReadyView')
---@class Anniversary19BattleReadyView : BattleReadyView
local Anniversary19BattleReadyView = class('Anniversary19BattleReadyView', BattleReadyView)
local uiMgr = app.uiMgr
local gameMgr = app.gameMgr

local RES_DIR = {
	BACK 			= app.anniversary2019Mgr:GetResPath("ui/common/common_btn_back.png"),
	BG_INFORMATION 	= app.anniversary2019Mgr:GetResPath('ui/common/maps_fight_bg_information.png'),
	TABL_BTN 		= app.anniversary2019Mgr:GetResPath('ui/common/maps_fight_btn_tab_default.png'),
	SKILL_BG1 		= app.anniversary2019Mgr:GetResPath('ui/map/team_lead_skill_bg_1.png'),
	SKILL_BG2 		= app.anniversary2019Mgr:GetResPath('ui/map/team_lead_skill_bg_2.png'),
	SKILL_WORD_BG 	= app.anniversary2019Mgr:GetResPath('ui/common/team_lead_skill_word_bg.png'),
	FRAME_GOODS 	= app.anniversary2019Mgr:GetResPath('ui/common/common_frame_goods_1.png'),
	ADD         	= app.anniversary2019Mgr:GetResPath('ui/common/maps_fight_btn_pet_add.png'),
	BG_TITLE_S 		= app.anniversary2019Mgr:GetResPath('ui/common/maps_fight_bg_title_s.png'),
 	BG_SWORD1 		= app.anniversary2019Mgr:GetResPath('ui/common/maps_fight_bg_sword1.png'),
 	BTN_ORANGE 		= app.anniversary2019Mgr:GetResPath('ui/common/common_btn_orange.png'),
}

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
constructor
--]]
function Anniversary19BattleReadyView:ctor( ... )
	Anniversary19BattleReadyView.super.ctor(self, ...)  
end
--[[
init ui
--]]
function Anniversary19BattleReadyView:InitUI()

	-- bg mask
	local eaterLayer = display.newLayer(display.cx, display.cy, {enable = true, size = display.size, color = '#000000', ap = cc.p(0.5, 0.5)})
	eaterLayer:setOpacity(0.7 * 255)
	self:addChild(eaterLayer, 1)

	-- 返回按钮
	local closeBtn = display.newButton(0, 0, {n = RES_DIR.BACK,
		cb = function (sender)
			-- 发信号 关闭
            sender:setEnabled(false)
            PlayAudioByClickClose()
            self:destory()
		end})
	display.commonUIParams(closeBtn, {po = cc.p(
		display.SAFE_L + closeBtn:getContentSize().width * 0.5 + 30,
		display.height - 18 - closeBtn:getContentSize().height * 0.5
	)})
    closeBtn:setName('BTN_CLOSE')
	self:addChild(closeBtn, 20)
	self.closeBtn = closeBtn

	local centerBgSize = cc.size(630, 185)
	local belongsBgFrameSize = cc.size(375, 215)
	local cardHeadScale = 0.625
	if 1 == self.battleType or 3 == self.battleType then
		centerBgSize = cc.size(830, 206)
		cardHeadScale = 0.85
	end

	-- center bg
	local centerBg = display.newImageView(RES_DIR.BG_INFORMATION, display.cx, display.height * 0.7,
			{scale9 = true, size = centerBgSize, enable = true, animate = false})
	self:addChild(centerBg, 5)

	-- player skill info
	local belongsBgFrame = display.newImageView(RES_DIR.BG_INFORMATION,
		centerBg:getPositionX() - centerBgSize.width * 0.5 + belongsBgFrameSize.width * 0.5,
		centerBg:getPositionY() - centerBgSize.height * 0.5 - 80 - belongsBgFrameSize.height * 0.5,
		{scale9 = true, size = belongsBgFrameSize})
	belongsBgFrame:setName('belongsBgFrame')
	self:addChild(belongsBgFrame, 5)

	-- hint label
	local hintLabel = display.newLabel(0, 0,
		{text = app.anniversary2019Mgr:GetPoText(__('点击技能图标更改主角技')), fontSize = 20, color = '#c8b3af'})
	display.commonUIParams(hintLabel, {po = cc.p(belongsBgFrameSize.width * 0.5, display.getLabelContentSize(hintLabel).height * 0.5 + 2)})
	belongsBgFrame:addChild(hintLabel)

	-- battle btn
	local battleBtn = require('common.CommonBattleButton').new({
		pattern = 1,
		clickCallback = handler(self, self.EnterBattleClick)
	})
    battleBtn:setName('BattleBTN')
	display.commonUIParams(battleBtn, {po = cc.p(
		centerBg:getPositionX() + centerBgSize.width * 0.5 - battleBtn:getContentSize().width * 0.5,
		belongsBgFrame:getPositionY()
	)})
	self:addChild(battleBtn, 5)


	self.viewData = {
		centerBg = centerBg,
		belongsBgFrame = belongsBgFrame,
		hintLabel = hintLabel,
		cardHeadScale = cardHeadScale,
		battleBtn = battleBtn,
	}

	self.centerContentData = {
	}
	belongsBgFrame:setVisible(0 < #self.centerContentData)
	
	self.recommendCardNodes = {}

    self:InitStageInfo()
	self:InitFormationContent()
	self:InitBelongings()

	self:RefreshCenterContent(self.selectedCenterIdx or 1)
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

function Anniversary19BattleReadyView:AddTopCurrency( currency, args )
	local GoodPurchaseNode = require('common.GoodPurchaseNode')
	-- top icon
	local currencyBG = display.newImageView(app.anniversary2019Mgr:GetResPath('ui/home/nmain/main_bg_money'),0,0,{enable = false})
	display.commonUIParams(currencyBG,{ap = cc.p(1.0,1.0), po = cc.p(display.width + 400, display.height)})
	self:addChild(currencyBG)
	self.datas = args

	if args and args.consumeGoods and args.consumeGoodsNum then
		if self.viewData.costHpIcon then
			self.viewData.costHpIcon:setTexture(CommonUtils.GetGoodsIconPathById(args.consumeGoods))
		else
			local costHpIcon = display.newNSprite(CommonUtils.GetGoodsIconPathById(args.consumeGoods), 0, 0)
			costHpIcon:setScale(0.2)
			self:addChild(costHpIcon, 5)
			self.viewData.costHpIcon = costHpIcon
		end
		if self.viewData.costHpLabel then
			self.viewData.costHpLabel:setString(string.format(app.anniversary2019Mgr:GetPoText(__('消耗%d')), checkint(args.consumeGoodsNum)))
		else
			local costHpLabel = display.newLabel(0, 0,
				fontWithColor(9, {text = string.format(app.anniversary2019Mgr:GetPoText(__('消耗%d')), checkint(args.consumeGoodsNum))}))
			self:addChild(costHpLabel, 5)
			self.viewData.costHpLabel = costHpLabel
		end

		if nil ~= self.viewData.costHpLabel and nil ~= self.viewData.costHpIcon then
			display.setNodesToNodeOnCenter(self.viewData.battleBtn, {self.viewData.costHpLabel, self.viewData.costHpIcon}, {y = -15})
		end

		self.needCost = true
	end

	self.moneyNodes = {}
	for i,v in ipairs(currency or {}) do
		local purchaseNode = GoodPurchaseNode.new({id = v, animate = false, datas = args})
		purchaseNode:updataUi(checkint(v))
		display.commonUIParams(purchaseNode,
			{ap = cc.p(1, 0.5), po = cc.p(display.SAFE_R - 20 - (( #currency - i) * (purchaseNode:getContentSize().width + 16)), currencyBG:getPositionY()- 26)})
		self:addChild(purchaseNode, 5)
		purchaseNode:setName('purchaseNode' .. i)
		purchaseNode.viewData.touchBg:setTag(checkint(v))
		self.moneyNodes[tostring( v )] = purchaseNode
	end
	AppFacade.GetInstance():RegistObserver("REFRESH_NOT_CLOSE_GOODS_EVENT", mvc.Observer.new(function (_, signal)
		local data = signal:GetBody() or {}
		for k,v in pairs(self.moneyNodes) do
			v:updataUi(checkint( k ))
		end
	end, self))
end

function Anniversary19BattleReadyView:onExit()
	if self.moneyNodes then
		AppFacade.GetInstance():UnRegistObserver("REFRESH_NOT_CLOSE_GOODS_EVENT", self)
	end
end
---------------------------------------------------
-- stage info control begin --
---------------------------------------------------
--[[
初始化关卡详情
--]]
function Anniversary19BattleReadyView:InitStageInfo()

	local stageConf = CommonUtils.GetQuestConf(checkint(self.stageId))

	-- 关卡详情底板
	local stageInfoBgSize = cc.size(578, 605)
	local stageInfoBgPos = cc.p(display.SAFE_L + stageInfoBgSize.width * 0.5 + 30, display.height * 0.45)
	local stageInfoBg = display.newImageView(RES_DIR.BG_INFORMATION, 0, 0,
		{scale9 = true, size = stageInfoBgSize, enable = true, animate = false})
	display.commonUIParams(stageInfoBg, {po = stageInfoBgPos})
	self:addChild(stageInfoBg, 5)

	local stageInfoBgLayer = display.newLayer(stageInfoBg:getPositionX(), stageInfoBg:getPositionY(), {ap = stageInfoBg:getAnchorPoint(), size = stageInfoBgSize})
	self:addChild(stageInfoBgLayer, 5)

	-- 分隔线1 关卡信息
	local splitLineStageInfo = display.newNSprite(app.anniversary2019Mgr:GetResPath('ui/common/maps_fight_line.png'), stageInfoBgSize.width * 0.5, stageInfoBgSize.height - 70)
	stageInfoBg:addChild(splitLineStageInfo)

    if DEBUG > 0 then
        local resetBtn = display.newButton(stageInfoBgSize.width - 150, stageInfoBgSize.height - 250,
        {
            ap = display.CENTER,
            n = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_orange_big.png'), 
        })
        display.commonLabelParams(resetBtn, fontWithColor(14, 
        {
            text = "去掉推荐飨灵\n只在测试有效",
            ap = display.CENTER,
            fontSize = 26,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#5b3c25',
        }))
		stageInfoBgLayer:addChild(resetBtn)
		resetBtn:setOnClickScriptHandler(function ()
			self:RefreshRecommendCards({})
		end)
	end
	
	local maxStarLabel = display.newLabel(
		splitLineStageInfo:getPositionX() - splitLineStageInfo:getContentSize().width * 0.5 + 5,
		splitLineStageInfo:getPositionY() + 20,
		{text = app.anniversary2019Mgr:GetPoText(__('今日能力提升飨灵')), fontSize = 26, color = '#bba496', ap = cc.p(0, 0.5)})
	stageInfoBg:addChild(maxStarLabel)
	local maxStarLabelSize = display.getLabelContentSize(maxStarLabel)

	local tipsBtn = display.newButton(maxStarLabel:getPositionX() + maxStarLabelSize.width + 10, maxStarLabel:getPositionY(), {ap = display.LEFT_CENTER, n = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_tips.png'), cb = handler(self, self.TipsBtnCallback)})	
	stageInfoBgLayer:addChild(tipsBtn)
	
	local recommendCardLayerSize = cc.size(stageInfoBgSize.width, 120)
	local recommendCardLayer = display.newLayer(stageInfoBgSize.width / 2, stageInfoBgSize.height - 145, 
		{ap = display.CENTER, size = recommendCardLayerSize})
	stageInfoBg:addChild(recommendCardLayer)
	self.recommendCardLayer = recommendCardLayer
	-- 推荐卡牌
	if self.recommendCards then
		self:CreateRecommendCards(recommendCardLayer, self.recommendCards)
	end

	-- 天气预报
	local forecastLabel = display.newLabel(
		maxStarLabel:getPositionX(),
		stageInfoBgSize.height * 0.575,
		{text = app.anniversary2019Mgr:GetPoText(__('天气情况')), fontSize = 26, color = '#bba496', ap = cc.p(0, 0.5)})
	stageInfoBg:addChild(forecastLabel)

	-- 分隔线2 关卡掉落
	local splitLineStageReward = display.newNSprite(app.anniversary2019Mgr:GetResPath('ui/common/maps_fight_line.png'), stageInfoBgSize.width * 0.5, 235)
	stageInfoBg:addChild(splitLineStageReward)

	
	-- 掉落信息
	local rewardLabel = display.newLabel(
		splitLineStageReward:getPositionX() - splitLineStageReward:getContentSize().width * 0.5 + 5,
		splitLineStageReward:getPositionY() + 20,
		{text = app.anniversary2019Mgr:GetPoText(__('关卡可能掉落')), fontSize = 26, color = '#bba496', ap = cc.p(0, 0.5)})
	stageInfoBg:addChild(rewardLabel)

	
	if stageConf then

		local questBattleType = CommonUtils.GetQuestBattleByQuestId(checkint(self.stageId))

		local stageTitleStr = stageConf.name
		local bgId = stageConf.backgroundId or 1

		-- 垫上一张背景图
		local BGSize = cc.size(1336,1002)
        local bgView = CLayout:create(BGSize)
		bgView:addChild(display.newNSprite(app.anniversary2019Mgr:GetResPath('ui/home/activity/ptDungeon/activity_ptfb_bg.jpg'), BGSize.width / 2, BGSize.height / 2, {ap = display.CENTER}))
        display.commonUIParams(bgView,{ap = display.CENTER, po = cc.p(self:getContentSize().width * 0.5, self:getContentSize().height * 0.5)})
        fullScreenFixScale(bgView)
        self:addChild(bgView)

		-- 关卡信息
		local stageTitleBg = display.newNSprite(app.anniversary2019Mgr:GetResPath('ui/common/maps_fight_bg_title.png'), 0, 0)
		display.commonUIParams(stageTitleBg, {po = cc.p(
			self.closeBtn:getPositionX() + self.closeBtn:getContentSize().width * 0.5 + stageTitleBg:getContentSize().width * 0.5 + 10,
			self.closeBtn:getPositionY())})
		self:addChild(stageTitleBg, 5)

		local stageTitleLabel = display.newLabel(stageTitleBg:getContentSize().width * 0.4, utils.getLocalCenter(stageTitleBg).y,
			{text = stageTitleStr, fontSize = 28, color = '#ffffff'})
		stageTitleBg:addChild(stageTitleLabel)
		self.stageTitleText = stageTitleStr

		-- 天气情况
		local weatherId = nil
		local weatherIconScale = 0.4
		for i,v in ipairs(stageConf.weatherId) do
			weatherId = checkint(v)
			local weatherConf = CommonUtils.GetConfig('quest', 'weather', weatherId)
			local weatherBtn = display.newButton(0, 0, {
				n = app.anniversary2019Mgr:GetResPath(string.format('ui/common/fight_ico_weather_%d.png', checkint(weatherConf.weatherProperty))),
				cb = function (sender)
					uiMgr:ShowInformationTipsBoard({targetNode = sender, title = weatherConf.name, descr = weatherConf.descr, type = 5})
				end
			})
			weatherBtn:setScale(weatherIconScale)
			local pos = self:convertToNodeSpace(stageInfoBg:convertToWorldSpace(cc.p(
				forecastLabel:getPositionX() + display.getLabelContentSize(forecastLabel).width + 10 + weatherBtn:getContentSize().width * weatherIconScale * 0.5 + (((weatherBtn:getContentSize().width * weatherIconScale) + 5) * (i - 1)),
				forecastLabel:getPositionY() + 2)))
			display.commonUIParams(weatherBtn, {po = pos})
			self:addChild(weatherBtn, 15)
		end

		-- 奖励金币和经验
		local iconScale = 0.2
		local goldIcon = display.newNSprite(app.anniversary2019Mgr:GetResPath(CommonUtils.GetGoodsIconPathById(900002)), 0, 0)
		goldIcon:setScale(iconScale)
		display.commonUIParams(goldIcon, {po = cc.p(splitLineStageReward:getPositionX() + 75 + 120, splitLineStageReward:getPositionY() + 20)})
		stageInfoBg:addChild(goldIcon)

		local goldLabel = display.newLabel(
			goldIcon:getPositionX() + goldIcon:getContentSize().width * 0.5 * iconScale + 5,
			goldIcon:getPositionY(),
			{text = tostring(stageConf.gold), fontSize = 22, color = '#ffffff', ap = cc.p(0, 0.5)})
		stageInfoBg:addChild(goldLabel)

		local rewardIconPerLine = 5
		local paddingX = -5
		local cellWidth = 105
		local goodNodeScale = 0.9
		local _p = self:convertToNodeSpace(stageInfoBg:convertToWorldSpace(cc.p(splitLineStageReward:getPositionX(), splitLineStageReward:getPositionY())))

		-- 处理奖励信息 有的关卡存在拆分的奖励信息
		local stageRewardsInfo = {}

		if stageConf.rewards and 0 < #stageConf.rewards then
			-- 插入通常奖励
			for i,v in ipairs(stageConf.rewards) do
				table.insert(stageRewardsInfo, v)
			end
		end

		for i,v in ipairs(stageRewardsInfo) do
			if i <= 5 then
				local function callBack(sender)
					AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
				end
				local goodNode = require('common.GoodNode').new({id = checkint(v.goodsId), showAmount = false, callBack = callBack})
				goodNode:setScale(goodNodeScale)
				display.commonUIParams(goodNode, {po = cc.p(
					stageInfoBgPos.x + paddingX + (cellWidth * (((i - 1) % rewardIconPerLine + 1) - (rewardIconPerLine + 1) * 0.5)),
					_p.y - 15 - goodNode:getContentSize().height * (0.5 + math.ceil(i / rewardIconPerLine) - 1) * goodNodeScale)})
				self:addChild(goodNode, 15)
			end
		end
	end

	-- 移动中间块位置
	self.viewData.centerBg:setPosition(cc.p(
		display.SAFE_R - self.viewData.centerBg:getContentSize().width * 0.5 - 50,
		stageInfoBgPos.y + stageInfoBgSize.height * 0.5 - self.viewData.centerBg:getContentSize().height * 0.5)
	)

	-- 移动主角技模块
	self.viewData.belongsBgFrame:setPosition(
		self.viewData.centerBg:getPositionX() - self.viewData.centerBg:getContentSize().width * 0.5 + self.viewData.belongsBgFrame:getContentSize().width * 0.5,
		stageInfoBgPos.y - stageInfoBgSize.height * 0.5 + self.viewData.belongsBgFrame:getContentSize().height * 0.5
	)

	-- 移动进入战斗位置
	local offsetY = nil ~= self.challengeTimeLabelBg and 35 or 0
	display.commonUIParams(self.viewData.battleBtn, {po = cc.p(
		self.viewData.centerBg:getPositionX() + self.viewData.centerBg:getContentSize().width * 0.5 - self.viewData.battleBtn:getContentSize().width * 0.5,
		self.viewData.belongsBgFrame:getPositionY() + offsetY)})

	-- 剩余挑战次数位置
	if nil ~= self.challengeTimeLabelBg and nil ~= self.buyChallengTimeBtn then
		display.commonUIParams(self.challengeTimeLabelBg, {po = cc.p(
			self.viewData.battleBtn:getPositionX() - 25,
			self.viewData.battleBtn:getPositionY() - self.viewData.battleBtn:getContentSize().height * 0.5 - 58)})
		display.commonUIParams(self.buyChallengTimeBtn, {po = cc.p(
			self.challengeTimeLabelBg:getPositionX() + self.challengeTimeLabelBg:getContentSize().width * 0.5 + self.buyChallengTimeBtn:getContentSize().width * 0.5 - 20,
			self.challengeTimeLabelBg:getPositionY())})
	end

end

function Anniversary19BattleReadyView:CreateRecommendCards(parent, recommendCards)
	if parent:getChildrenCount() > 0 then parent:removeAllChildren() end

	local scale = 0.6
	local parentSize = parent:getContentSize()
	local count = table.nums(recommendCards)
	for i = 1, count do
		local cardId = checkint(recommendCards[i])
		if cardId > 0 then
			local node = self:CreateRecommendCard(cardId, scale)
			display.commonUIParams(node, {po = cc.p(80 + 130 * (i-1), parentSize.height / 2)})
			parent:addChild(node)
			-- table.insert(self.recommendCardNodes, node)
			self.recommendCardNodes[tostring(cardId)] = node
		end
	end
end

function Anniversary19BattleReadyView:CreateRecommendCard(cardId, scale)
	local size = cc.size(120,120)
	local layer = display.newLayer(0, 0, {size = size, ap = display.CENTER})

	local cardNodeData = {cardData = {cardId = cardId}, showBaseState = true, showActionState = false, showRecommendState = true}
	local cardHeadNode = require('common.CardHeadNode').new(cardNodeData)
	display.commonUIParams(cardHeadNode, {po = cc.p(size.width / 2, size.height / 2), ap = display.CENTER})
	cardHeadNode:setScale(scale)
	layer:addChild(cardHeadNode)

	local recommendImg = display.newImageView(app.anniversary2019Mgr:GetResPath('ui/common/summer_activity_mvpxiangling_icon_unlock.png'), size.width - 22 , size.height - 20)
	layer:addChild(recommendImg, 20)

	local frameSpine = sp.SkeletonAnimation:create('effects/activity/biankuang.json', 'effects/activity/biankuang.atlas', 1)
	frameSpine:update(0)
	-- frameSpine:setScale(scale)
	-- frameSpine:setAnimation(0, 'idle', true)
	display.commonUIParams(frameSpine, {po = cc.p(size.width / 2, size.height / 2)})
	layer:addChild(frameSpine,10)
	frameSpine:setVisible(false)
	
	layer.viewData = {
		cardHeadNode = cardHeadNode,
		recommendImg = recommendImg,
		frameSpine = frameSpine,
	}
	return layer
end

function Anniversary19BattleReadyView:GetRecommendCardsByAdditions(additions)
	self.additions = additions
	local activeCards = {}
    for i, v in orderedPairs(additions) do
        local tempActiveCards = v.activeCards or {}
        for i, cardId in ipairs(tempActiveCards) do
            activeCards[tostring(cardId)] = cardId
        end
    end

    return table.values(activeCards) or {}
end

function Anniversary19BattleReadyView:SetLeftHP(leftHp)
	self.leftHp = leftHp
end

function Anniversary19BattleReadyView:RefreshRecommendCards(recommendCards)
	self.recommendCardNodes = {}
	self.recommendCards = self:GetRecommendCardsByAdditions(recommendCards)
	self:CreateRecommendCards(self.recommendCardLayer, self.recommendCards)
	self:RefreshRecommendCardsState()
end

function Anniversary19BattleReadyView:RefreshRecommendCardsState()
	local teamCardIds = {}
	local selectedTeamData = self.teamData[self.selectedTeamIdx or 1].members or {}
	for i,v in ipairs(selectedTeamData) do
		local cardId = gameMgr:GetCardDataById(v.id).cardId
		teamCardIds[tostring(cardId)] = cardId
	end
	for cardId, node in pairs(self.recommendCardNodes) do
		local viewData = node.viewData
		local recommendImg = viewData.recommendImg
		local frameSpine = viewData.frameSpine
		local isRecommend = teamCardIds[tostring(cardId)]

		if isRecommend then
			recommendImg:setTexture(app.anniversary2019Mgr:GetResPath('ui/common/summer_activity_mvpxiangling_icon.png'))
			frameSpine:setVisible(true)
			frameSpine:setAnimation(0, 'idle', true)
		else
			recommendImg:setTexture(app.anniversary2019Mgr:GetResPath('ui/common/summer_activity_mvpxiangling_icon_unlock.png'))
			frameSpine:setVisible(false)
		end
	end
end

---------------------------------------------------
-- stage info control end --
---------------------------------------------------

---------------------------------------------------
-- formation control begin --
---------------------------------------------------
--[[
刷新中间队伍区域
@params data table 队伍信息
--]]
function Anniversary19BattleReadyView:RefreshTeamFormation(data)
	------------ 处理编队数据 ------------
	local teamData = {}
	for tNo, tData in ipairs(data) do
		teamData[tNo] = {teamId = tData.teamId, members = {}}
		for no, card in ipairs(tData.cards) do
			if card.id then
				local id = checkint(card.id)
				local cardData = gameMgr:GetCardDataById(id)
				table.insert(teamData[tNo].members, {id = id, isLeader = id == checkint(tData.captainId)})
			end
		end
	end
	
	self.teamData = teamData

	self:RefreshRecommendCardsState()
	self:RefreshTeamTabs()
end
---------------------------------------------------
-- formation control end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
阵容前后按钮点击回调
1001 前
1002 后
--]]
function Anniversary19BattleReadyView:ChangeTeamFormationBtnCallback(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if 1001 == tag then
		self:RefreshTeamSelectedState(math.max(1, self.selectedTeamIdx - 1))
	elseif 1002 == tag then
		self:RefreshTeamSelectedState(math.min(table.nums(self.teamData), self.selectedTeamIdx + 1))
	end
	self:RefreshRecommendCardsState()
end

function Anniversary19BattleReadyView:TipsBtnCallback(sender)
	uiMgr:ShowIntroPopup({moduleId = '-5'})
end



--[[
进入战斗
--]]
function Anniversary19BattleReadyView:EnterBattle()
	------------ 本地逻辑判断 ------------
	local selectedTeamData = self.teamData[self.selectedTeamIdx]

	if table.nums(selectedTeamData.members) == 0 then
		-- TODO 跳转编队
		local CommonTip  = require( 'common.CommonTip' ).new({text = app.anniversary2019Mgr:GetPoText(__('队伍不能为空')),isOnlyOK = true})
		CommonTip:setPosition(display.center)
		AppFacade.GetInstance():GetManager("UIManager"):GetCurrentScene():AddDialog(CommonTip)
	else

		if self.needCost then
			local anniversary2019Mgr = app.anniversary2019Mgr
			if app.activityHpMgr:GetHpAmountByHpGoodsId(anniversary2019Mgr:GetSuppressHPId()) < tonumber(anniversary2019Mgr:GetSuppressHPConsume()) then
				local goodsConfig = CommonUtils.GetConfig('goods', 'goods', anniversary2019Mgr:GetSuppressHPId())
				app.uiMgr:ShowInformationTips(string.format(app.anniversary2019Mgr:GetPoText(__('%s不足')), goodsConfig.name))
				return
			end
		end

		local serverCommand = BattleNetworkCommandStruct.New(
			self.enterBattleRequestCommand,
			self.enterBattleRequestData,
			self.enterBattleResponseSignal,
			self.exitBattleRequestCommand,
			self.exitBattleRequestData,
			self.exitBattleResponseSignal,
			nil,
			nil,
			nil
		)

		local fromToStruct = BattleMediatorsConnectStruct.New(
			self.fromMediatorName,
			self.toMediatorName
		)

		local battleConstructor = require('battleEntry.BattleConstructor').new()

		------------ 初始化怪物血量参数 这里写死一波一个怪 ------------
		local monsterAttrData = {
			['1'] = {
				[1] = {
					[CardUtils.PROPERTY_TYPE.HP] = {percent = 1, value = self.leftHp}
				}
			}
		}
		------------ 初始化怪物血量参数 这里写死一波一个怪 ------------

		local canBattle, waringText = battleConstructor:CanEnterBattleByTeamId(self.selectedTeamIdx)
		if not canBattle then
			if nil ~= waringText then
				uiMgr:ShowInformationTips(waringText)
			end
			return
		end

		serverCommand.enterBattleRequestData.teamId = self.selectedTeamIdx

		battleConstructor:InitDataByShareBoss(
			self.stageId,
			self.selectedTeamIdx,
			monsterAttrData,
			0,
			0,
			false,
			{},
			self.additions,
			serverCommand,
			fromToStruct
		)

		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)

	end
end
function Anniversary19BattleReadyView:EnterBattleClick(sender)
	if self.isEnterBattleClick  then
		print(" self.isEnterBattleClick = "  ,  self.isEnterBattleClick)
		return
	end
	self.isEnterBattleClick = true
	self.viewData.hintLabel:runAction(
		cc.Sequence:create(
			cc.DelayTime:create(1.5) ,
			cc.CallFunc:create(function()
				self.isEnterBattleClick = false
			end)
		)
	)
	local enterBattleRequestData  = self.enterBattleRequestData
	local bossUuid  = enterBattleRequestData.bossUuid
	app:DispatchSignal(POST.ANNIVERSARY2_BOSS_HP.cmdName , {bossUuid = bossUuid })
end
function Anniversary19BattleReadyView:ProcessSignal(signal)
	local name = signal:GetName()
	local body = signal:GetBody()
	if name == POST.ANNIVERSARY2_BOSS_HP.sglName  then
		self.viewData.battleBtn:stopAllActions()

		local leftHp  = body.leftHp
		self:SetLeftHP(leftHp)
		self:EnterBattle()
	end
end
function Anniversary19BattleReadyView:onEnter()
	regPost(POST.ANNIVERSARY2_BOSS_HP)
	app:RegistObserver(POST.ANNIVERSARY2_BOSS_HP.sglName ,mvc.Observer.new(self.ProcessSignal, self))
end

function Anniversary19BattleReadyView:onCleanup()
	unregPost(POST.ANNIVERSARY2_BOSS_HP)
	app:UnRegistObserver(POST.ANNIVERSARY2_BOSS_HP.sglName , self)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

return Anniversary19BattleReadyView
