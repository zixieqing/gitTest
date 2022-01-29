--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）战前Mediator
]]
local BattleReadyView = require('Game.views.BattleReadyView')
local MurderBattleReadyView = class('MurderBattleReadyView', BattleReadyView)
local shareFacade = AppFacade.GetInstance()
local uiMgr = app.uiMgr
local gameMgr = app.gameMgr

function MurderBattleReadyView:ctor( ... )
    self.recommendCardNodes = {}
    self.teamCardIds = {}
    MurderBattleReadyView.super.ctor(self, ...)  
    
end
--[[
init ui
--]]
function MurderBattleReadyView:InitUI()
	-- bg mask
	-- local eaterLayer = display.newImageView(app.murderMgr:GetResPath('ui/common/common_bg_mask.png'), display.cx, display.cy, {enable = true, animate = false})
	local eaterLayer = display.newLayer(display.cx, display.cy, {enable = true, size = display.size, color = '#000000', ap = cc.p(0.5, 0.5)})
	eaterLayer:setOpacity(0.7 * 255)
	self:addChild(eaterLayer, 1)

	-- 返回按钮
	local closeBtn = display.newButton(0, 0, {n = app.murderMgr:GetResPath("ui/common/common_btn_back.png"),
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

	-- local closeLabel = display.newLabel(self:getContentSize().width * 0.5, 25,
	-- 	{text = app.murderMgr:GetPoText(__('点击空白处返回')), fontSize = fontWithColor('9').fontSize, color = fontWithColor('9').color})
	-- self:addChild(closeLabel)
	-- closeLabel:runAction(cc.RepeatForever:create(cc.Sequence:create(
	-- 	cc.DelayTime:create(0.5),
	-- 	cc.FadeTo:create(1, 0),
	-- 	cc.FadeTo:create(1, 255))))

	local centerBgSize = cc.size(630, 185)
	local belongsBgFrameSize = cc.size(375, 215)
	local cardHeadScale = 0.625
	if 1 == self.battleType or 3 == self.battleType then
		centerBgSize = cc.size(830, 206)
		cardHeadScale = 0.85
	end

	-- center bg
	local centerBg = display.newImageView(app.murderMgr:GetResPath('ui/common/maps_fight_bg_information.png'), display.cx, display.height * 0.7,
			{scale9 = true, size = centerBgSize, enable = true, animate = false})
	self:addChild(centerBg, 5)

	-- player skill info
	local belongsBgFrame = display.newImageView(app.murderMgr:GetResPath('ui/common/maps_fight_bg_information.png'),
		centerBg:getPositionX() - centerBgSize.width * 0.5 + belongsBgFrameSize.width * 0.5,
		centerBg:getPositionY() - centerBgSize.height * 0.5 - 80 - belongsBgFrameSize.height * 0.5,
		{scale9 = true, size = belongsBgFrameSize})
	belongsBgFrame:setName('belongsBgFrame')
	self:addChild(belongsBgFrame, 5)

	-- hint label
	local hintLabel = display.newLabel(0, 0,
		{text = app.murderMgr:GetPoText(__('点击技能图标更改主角技')), fontSize = 20, color = '#c8b3af'})
	display.commonUIParams(hintLabel, {po = cc.p(belongsBgFrameSize.width * 0.5, display.getLabelContentSize(hintLabel).height * 0.5 + 2)})
	belongsBgFrame:addChild(hintLabel)

	-- battle btn
	local battleBtn = require('common.CommonBattleButton').new({
		pattern = 1,
		clickCallback = handler(self, self.EnterBattle)
	})
    battleBtn:setName('BattleBTN')
	display.commonUIParams(battleBtn, {po = cc.p(
		centerBg:getPositionX() + centerBgSize.width * 0.5 - battleBtn:getContentSize().width * 0.5,
		belongsBgFrame:getPositionY()
	)})
	self:addChild(battleBtn, 5)

	-- 消耗体力
	local costHpLabel, costHpIcon, costHpTime = nil, nil, nil
	local stageConf = CommonUtils.GetQuestConf(checkint(self.stageId))
	if self.stageId and stageConf then
		local consumeNum = nil 
		if self.battleType == 4 then
			consumeNum = stageConf.consumeHpNum
		elseif self.battleType == 5 then
			consumeNum = stageConf.consumeNum
		end
		costHpLabel = display.newLabel(0, 0,
			fontWithColor(9, {text = string.format(app.murderMgr:GetPoText(__('消耗%d')), checkint(consumeNum))}))
		self:addChild(costHpLabel, 5)
		local costHpIconPath = CommonUtils.GetGoodsIconPathById(app.murderMgr:GetMurderHpId())
		if self.battleType == 5 then
			costHpIconPath = CommonUtils.GetGoodsIconPathById(app.murderMgr:GetMurderGoodsIdByKey("murder_ticket_id"))
		end
		costHpIcon = display.newNSprite(app.murderMgr:GetResPath(costHpIconPath), 0, 0)
		costHpIcon:setScale(0.2)
		self:addChild(costHpIcon, 5)

		costHpTime = display.newLabel(0, 0,
			-- fontWithColor(9, {text = app.murderMgr:GetPoText(__('/次'))}))
			fontWithColor(9, {text = ''}))
		self:addChild(costHpTime, 5)

		-- display.setNodesToNodeOnCenter(battleBtn, {costHpLabel, costHpIcon}, {y = -15})
	end

	self.viewData = {
		centerBg = centerBg,
		belongsBgFrame = belongsBgFrame,
		hintLabel = hintLabel,
		cardHeadScale = cardHeadScale,
		battleBtn = battleBtn,
		costHpLabel = costHpLabel,
		costHpIcon = costHpIcon,
		costHpTime = costHpTime
	}

	if 2 == self.battleType then
		self.centerContentData = {
			-- {name = app.murderMgr:GetPoText(__('队伍')), tag = 1, initHandler = handler(self, self.InitTeamFormationPanel), showHandler = handler(self, self.ShowTeamFormationPanel)},
			{name = app.murderMgr:GetPoText(__('主角技')), tag = 1, initHandler = handler(self, self.InitPlayerSkillPanel), showHandler = handler(self, self.ShowPlayerSkillPanel)},
			-- {name = app.murderMgr:GetPoText(__('堕神诱饵')), tag = 2, initHandler = handler(self, self.InitMagicFoodPanel), showHandler = handler(self, self.ShowMagicFoodPanel)}
		}
		self:InitStageInfo()
	elseif 3 == self.battleType then
		self.centerContentData = {
			-- {name = app.murderMgr:GetPoText(__('队伍')), tag = 1, initHandler = handler(self, self.InitTeamFormationPanel), showHandler = handler(self, self.ShowTeamFormationPanel)},
			-- {name = app.murderMgr:GetPoText(__('主角技')), tag = 1, initHandler = handler(self, self.InitPlayerSkillPanel), showHandler = handler(self, self.ShowPlayerSkillPanel)}
        }
    elseif 4 == self.battleType then -- 材料本
		self.centerContentData = {}
		self:InitStageInfo()
    elseif 5 == self.battleType then -- boss本
		self.centerContentData = {}
		self:InitStageInfo()
	else
		self.centerContentData = {
			-- {name = app.murderMgr:GetPoText(__('队伍')), tag = 1, initHandler = handler(self, self.InitTeamFormationPanel), showHandler = handler(self, self.ShowTeamFormationPanel)},
			{name = app.murderMgr:GetPoText(__('主角技')), tag = 1, initHandler = handler(self, self.InitPlayerSkillPanel), showHandler = handler(self, self.ShowPlayerSkillPanel)}
		}
	end
	belongsBgFrame:setVisible(0 < #self.centerContentData)

	self:InitFormationContent()
	self:InitBelongings()

	self:RefreshCenterContent(self.selectedCenterIdx or 1)
end
--[[
初始化关卡详情
--]]
function MurderBattleReadyView:InitStageInfo()

	local stageConf = CommonUtils.GetQuestConf(checkint(self.stageId))

	-- 关卡详情底板
	local stageInfoBgSize = cc.size(578, 605)
	local stageInfoBgPos = cc.p(display.SAFE_L + stageInfoBgSize.width * 0.5 + 30, display.height * 0.45)
	local stageInfoBg = display.newImageView(app.murderMgr:GetResPath('ui/common/maps_fight_bg_information.png'), 0, 0,
		{scale9 = true, size = stageInfoBgSize, enable = true, animate = false})
	display.commonUIParams(stageInfoBg, {po = stageInfoBgPos})
	self:addChild(stageInfoBg, 5)

    local stageInfoBgLayer = display.newLayer(stageInfoBg:getPositionX(), stageInfoBg:getPositionY(), {ap = stageInfoBg:getAnchorPoint(), size = stageInfoBgSize})
	self:addChild(stageInfoBgLayer, 5)
	-- 分隔线1 关卡信息
	local splitLineStageInfo = display.newNSprite(app.murderMgr:GetResPath('ui/common/maps_fight_line.png'), stageInfoBgSize.width * 0.5, stageInfoBgSize.height - 70)
	stageInfoBg:addChild(splitLineStageInfo)

    local titleText = app.murderMgr:GetPoText(__('三星条件'))
    if self.battleType == 4 then
        titleText = app.murderMgr:GetPoText(__('掉落加成飨灵'))
    elseif self.battleType == 5 then
        titleText = app.murderMgr:GetPoText(__('伤害提升飨灵'))
    end
	local maxStarLabel = display.newLabel(
		splitLineStageInfo:getPositionX() - splitLineStageInfo:getContentSize().width * 0.5 + 5,
		splitLineStageInfo:getPositionY() + 20,
		{text = titleText, fontSize = 26, color = '#bba496', ap = cc.p(0, 0.5)})
    stageInfoBg:addChild(maxStarLabel)
    local maxStarLabelSize = display.getLabelContentSize(maxStarLabel)
    -- 提示按钮
    if self.battleType == 4 or self.battleType == 5 then
	    local tipsBtn = display.newButton(maxStarLabel:getPositionX() + maxStarLabelSize.width + 10, maxStarLabel:getPositionY(), {ap = display.LEFT_CENTER, n = app.murderMgr:GetResPath('ui/common/common_btn_tips.png'), cb = handler(self, self.TipsBtnCallback)})	
        stageInfoBgLayer:addChild(tipsBtn)
    end
    -- 推荐卡牌
    local recommendCardLayerSize = cc.size(stageInfoBgSize.width, 120)
	local recommendCardLayer = display.newLayer(stageInfoBgSize.width / 2, stageInfoBgSize.height - 145, 
		{ap = display.CENTER, size = recommendCardLayerSize})
	stageInfoBg:addChild(recommendCardLayer)
    self.recommendCardLayer = recommendCardLayer
    
    if self.battleType == 4 or self.battleType == 5 then
        self:CreateRecommendCards(recommendCardLayer)
    end
	-- 天气预报
	local forecastLabel = display.newLabel(
		maxStarLabel:getPositionX(),
		stageInfoBgSize.height * 0.575,
		{text = app.murderMgr:GetPoText(__('天气情况')), fontSize = 26, color = '#bba496', ap = cc.p(0, 0.5)})
	stageInfoBg:addChild(forecastLabel)

	-- 分隔线2 关卡掉落
	local splitLineStageReward = display.newNSprite(app.murderMgr:GetResPath('ui/common/maps_fight_line.png'), stageInfoBgSize.width * 0.5, 235)
	stageInfoBg:addChild(splitLineStageReward)

	-- 掉落信息
	local rewardLabel = display.newLabel(
		splitLineStageReward:getPositionX() - splitLineStageReward:getContentSize().width * 0.5 + 5,
		splitLineStageReward:getPositionY() + 20,
		{text = app.murderMgr:GetPoText(__('关卡可能掉落')), fontSize = 26, color = '#bba496', ap = cc.p(0, 0.5)})
	stageInfoBg:addChild(rewardLabel)

    local x = 1
    -- 扫荡按钮
    if self.battleType == 4 then
        local btnPath = 'ui/common/common_btn_green.png'
        if not app.murderMgr:IsMaterialQuestCanSkip(self.stageId) then
            btnPath = 'ui/common/common_btn_orange_disable.png'
        end
	    local sweepBtn = display.newButton(0, 0, {n = app.murderMgr:GetResPath(btnPath), cb = handler(self, self.SweepBtnCallback)})
	    display.commonUIParams(sweepBtn, {po = cc.p(stageInfoBgPos.x * 0.5, stageInfoBgPos.y - stageInfoBgSize.height * 0.5 + sweepBtn:getContentSize().height * 0.5 + 20)})
	    display.commonLabelParams(sweepBtn, fontWithColor(14,{text = app.murderMgr:GetPoText(__('扫荡'))}))
        self:addChild(sweepBtn, 20)
    end
	--x = 2

	if stageConf then
		local questBattleType = CommonUtils.GetQuestBattleByQuestId(checkint(self.stageId))

		local stageTitleStr = ''
		local bgId = 1

        stageTitleStr = string.format('%s', stageConf.name)

        -- bgId = checkint(stageConf.backgroundId)

		-- 垫上一张背景图
        local bgView = CLayout:create(cc.size(1336,1002))
		local bgPath = string.format('arts/maps/maps_bg_%s', bgId)
        local leftImage = display.newImageView(app.murderMgr:GetResPath(string.format('%s_01', bgPath)), 0, 0, {ap = display.LEFT_BOTTOM})
        bgView:addChild(leftImage)
        local rightImage = display.newImageView(app.murderMgr:GetResPath(string.format('%s_02', bgPath)), 1336, 0, {ap = display.RIGHT_BOTTOM})
        bgView:addChild(rightImage)
        display.commonUIParams(bgView,{ap = display.CENTER, po = cc.p(self:getContentSize().width * 0.5, self:getContentSize().height * 0.5)})
        fullScreenFixScale(bgView)
        self:addChild(bgView)

		-- 关卡信息
		local stageTitleBg = display.newNSprite(app.murderMgr:GetResPath('ui/common/maps_fight_bg_title.png'), 0, 0)
		display.commonUIParams(stageTitleBg, {po = cc.p(
			self.closeBtn:getPositionX() + self.closeBtn:getContentSize().width * 0.5 + stageTitleBg:getContentSize().width * 0.5 + 10,
			self.closeBtn:getPositionY())})
		self:addChild(stageTitleBg, 5)

		local stageTitleLabel = display.newLabel(stageTitleBg:getContentSize().width * 0.4, utils.getLocalCenter(stageTitleBg).y,
			{text = stageTitleStr, fontSize = 28, color = '#ffffff'})
		stageTitleBg:addChild(stageTitleLabel)
		self.stageTitleText = stageTitleStr

		local itor = 1
		local descr = stageConf.cleanCoditionMsg
		local cleanLabelColor = '#ffffff'
		local cleanLabel = display.newLabel(maxStarLabel:getPositionX(), splitLineStageInfo:getPositionY() - 30 - (itor - 1) * 35,
			{text = descr, fontSize = 22, color = cleanLabelColor, ap = cc.p(0, 0.5)})
		stageInfoBg:addChild(cleanLabel)
		itor = itor + 1		
		
		-- 天气情况
		local weatherId = nil
		local weatherIconScale = 0.4
		for i,v in ipairs(stageConf.weatherId) do
			weatherId = checkint(v)
			local weatherConf = CommonUtils.GetConfig('quest', 'weather', weatherId)
			local weatherBtn = display.newButton(0, 0, {
				n = app.murderMgr:GetResPath(string.format('ui/common/fight_ico_weather_%d.png', checkint(weatherConf.weatherProperty))),
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
		local goldIcon = display.newNSprite(app.murderMgr:GetResPath(CommonUtils.GetGoodsIconPathById(900002)), 0, 0)
		goldIcon:setScale(iconScale)
		display.commonUIParams(goldIcon, {po = cc.p(splitLineStageReward:getPositionX() + 205, splitLineStageReward:getPositionY() + 20)})
		stageInfoBg:addChild(goldIcon)

		local goldLabel = display.newLabel(
			goldIcon:getPositionX() + goldIcon:getContentSize().width * 0.5 * iconScale + 5,
			goldIcon:getPositionY(),
			{text = tostring(stageConf.gold), fontSize = 22, color = '#ffffff', ap = cc.p(0, 0.5)})
		stageInfoBg:addChild(goldLabel)

		-- local expIcon = display.newNSprite(app.murderMgr:GetResPath(CommonUtils.GetGoodsIconPathById(EXP_ID)), 0, 0)
		-- expIcon:setScale(iconScale)
		-- display.commonUIParams(expIcon, {po = cc.p(goldIcon:getPositionX() + 120, splitLineStageReward:getPositionY() + 20)})
		-- stageInfoBg:addChild(expIcon)

		-- local mainExp = stageConf.mainExp
		-- if stageConf.firstPassMainExp and checkint(self.stageId) >= gameMgr:GetNewestQuestIdByDifficulty(checkint(stageConf.difficulty)) then
		-- 	mainExp = stageConf.firstPassMainExp

		-- 	local firstLabel = display.newLabel(0, 0, fontWithColor('14', {text = app.murderMgr:GetPoText(__('首次通关'))}))
		-- 	display.commonUIParams(firstLabel, {ap = cc.p(0, 0), po = cc.p(
		-- 		expIcon:getPositionX() - expIcon:getContentSize().width * 0.5 * iconScale,
		-- 		expIcon:getPositionY() + expIcon:getContentSize().height * 0.5 * iconScale
		-- 	)})
		-- 	stageInfoBg:addChild(firstLabel)
		-- end

		-- local expLabel = display.newLabel(
		-- 	expIcon:getPositionX() + expIcon:getContentSize().width * 0.5 * iconScale + 5,
		-- 	expIcon:getPositionY(),
		-- 	{text = tostring(mainExp), fontSize = 22, color = '#ffffff', ap = cc.p(0, 0.5)})
        -- stageInfoBg:addChild(expLabel)
        

		local rewardIconPerLine = 5
		local paddingX = -5
		local cellWidth = 105
		local goodNodeScale = 0.9
		local _p = self:convertToNodeSpace(stageInfoBg:convertToWorldSpace(cc.p(splitLineStageReward:getPositionX(), splitLineStageReward:getPositionY())))

		-- 处理奖励信息 有的关卡存在拆分的奖励信息
		local stageRewardsInfo = {}

		if stageConf.hardQuestRewards and 0 < #stageConf.hardQuestRewards then
			-- 插入困难本拆分的奖励
			for i,v in ipairs(stageConf.hardQuestRewards) do
				table.insert(stageRewardsInfo, v)
			end
		end

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
		if self.battleType == 4 then
			-- 加成道具
			local i = #stageRewardsInfo + 1
			local goodNode = require('common.GoodNode').new({id = checkint(GOLD_ID), showAmount = true, callBack = function() end})
			goodNode:setScale(goodNodeScale)
			display.commonUIParams(goodNode, {po = cc.p(
				stageInfoBgPos.x + paddingX + (cellWidth * (((i - 1) % rewardIconPerLine + 1) - (rewardIconPerLine + 1) * 0.5)),
				_p.y - 15 - goodNode:getContentSize().height * (0.5 + math.ceil(i / rewardIconPerLine) - 1) * goodNodeScale)})
			self:addChild(goodNode, 15)
			local icon = display.newImageView(app.murderMgr:GetResPath('ui/common/summer_activity_mvpxiangling_icon.png'), 92, 96)
			goodNode:addChild(icon, 10)
			goodNode:setVisible(false)
			self.addGoodsNode = goodNode
		end
    end
    -- 提示Label
	if self.battleType == 5 then
		local config = CommonUtils.GetConfig('newSummerActivity', 'param', 1)
        local tipsLabel = display.newLabel(stageInfoBgPos.x - 265, stageInfoBgPos.y - 210, {text = string.fmt(app.murderMgr:GetPoText(__('每造成_num_点伤害可获得1点调查点数')), {['_num_'] = checkint(config.rate)}), color = '#ffffff', fontSize = 20, ap = cc.p(0, 0.5)})
		self:addChild(tipsLabel, 10)
		local bossDetailBtn = display.newButton(0, 0, {n = app.murderMgr:GetResPath('ui/common/common_btn_white_default.png'), cb = handler(self, self.BossDetailBtnClickHandler)})
		display.commonUIParams(bossDetailBtn, {po = cc.p(
			stageInfoBgPos.x - 200, stageInfoBgPos.y - 260
		)})
		display.commonLabelParams(bossDetailBtn, fontWithColor('14', {text = app.murderMgr:GetPoText(__('boss详情'))}))
		self:addChild(bossDetailBtn, 10)
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

	if nil ~= self.viewData.costHpLabel and nil ~= self.viewData.costHpIcon and nil ~= self.viewData.costHpTime then
		display.setNodesToNodeOnCenter(self.viewData.battleBtn, {self.viewData.costHpLabel, self.viewData.costHpIcon, self.viewData.costHpTime}, {y = -15})
	end

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

function MurderBattleReadyView:AddTopCurrency( currency, args )
	local GoodPurchaseNode = require('common.GoodPurchaseNode')
	-- top icon
	local currencyBG = display.newImageView(app.murderMgr:GetResPath('ui/home/nmain/main_bg_money'),0,0,{enable = false, scale9 = true, size = cc.size(480 + (display.width - display.SAFE_R),54)})
	display.commonUIParams(currencyBG,{ap = cc.p(1.0,1.0), po = cc.p(display.width, display.height)})
	self:addChild(currencyBG)
	self.datas = args

	local moneyNodes = {}
	for i,v in ipairs(currency or {}) do
		local purchaseNode = GoodPurchaseNode.new({id = v, animate = false, datas = args})
		purchaseNode:updataUi(checkint(v))
		display.commonUIParams(purchaseNode,
			{ap = cc.p(1, 0.5), po = cc.p(display.SAFE_R - 20 - (( #currency - i) * (purchaseNode:getContentSize().width + 16)), currencyBG:getPositionY()- 26)})
		self:addChild(purchaseNode, 5)
		purchaseNode:setName('purchaseNode' .. i)
		purchaseNode.viewData.touchBg:setTag(checkint(v))
		moneyNodes[tostring( v )] = purchaseNode
	end
	return moneyNodes
end

--[[
进入战斗
--]]
function MurderBattleReadyView:EnterBattle(sender)
	local stageConf = CommonUtils.GetQuestConf(checkint(self.stageId))
	local selectedTeamData = self.teamData[self.selectedTeamIdx]
	local num = nil 
	local consumeNum = nil 
	if self.battleType == 4 then
		consumeNum = stageConf.consumeHpNum
		num = app.activityHpMgr:GetHpAmountByHpGoodsId(app.murderMgr:GetMurderHpId())
	elseif self.battleType == 5 then
		consumeNum = stageConf.consumeNum
		num = app.gameMgr:GetAmountByIdForce(app.murderMgr:GetMurderGoodsIdByKey("murder_ticket_id"))
	end
	if checkint(num) < checkint(consumeNum) then
		if self.battleType == 4 then
			uiMgr:ShowInformationTips(app.murderMgr:GetPoText(__('体力不足！')))
		elseif self.battleType == 5 then
			uiMgr:ShowInformationTips(app.murderMgr:GetPoText(__('道具不足！')))
		end
	else
		if table.nums(selectedTeamData.members) == 0 then
			-- TODO 跳转编队
			local CommonTip  = require( 'common.CommonTip' ).new({text = app.murderMgr:GetPoText(__('队伍不能为空')),isOnlyOK = true})
			CommonTip:setPosition(display.center)
			AppFacade.GetInstance():GetManager("UIManager"):GetCurrentScene():AddDialog(CommonTip)
		else
	
			local serverCommand = BattleNetworkCommandStruct.New(
				self.enterBattleRequestCommand,
				self.enterBattleRequestData,
				self.enterBattleResponseSignal,
				self.exitBattleRequestCommand,
				self.exitBattleRequestData,
				self.exitBattleResponseSignal,
				'',
				self.enterBattleRequestData,
				''
			)
	
			local fromToStruct = BattleMediatorsConnectStruct.New(
				self.fromMediatorName,
				self.toMediatorName
			)
	
			local battleConstructor = require('battleEntry.BattleConstructor').new()
	
			local canBattle, waringText = battleConstructor:CanEnterBattleByTeamId(self.selectedTeamIdx)
			if not canBattle then
				if nil ~= waringText then
					uiMgr:ShowInformationTips(waringText)
				end
				return
			end
			local additions = {}
			if self.battleType == 5 and not app.murderMgr:GetDebugMode() then
				additions = CommonUtils.GetConfigAllMess('cardAddition', 'newSummerActivity')
			end
			battleConstructor:InitStageDataByNormalEventAndTeamId(
				self.stageId,
				serverCommand,
				fromToStruct,
				self.selectedTeamIdx,
				additions,
				0,
				0,
				false
			)
			GuideUtils.DispatchStepEvent()
			AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)
	
		end
	end
end
--[[
提示按钮回调
--]]
function MurderBattleReadyView:TipsBtnCallback(sender)
    if self.battleType == 4 then
        uiMgr:ShowIntroPopup({moduleId = '-33'})
    elseif self.battleType == 5 then
        uiMgr:ShowIntroPopup({moduleId = '-31'})
    else
        uiMgr:ShowIntroPopup({moduleId = '-5'})
    end
	
end
--[[
扫荡按钮回调
--]]
function MurderBattleReadyView:SweepBtnCallback(sender)
	PlayAudioByClickNormal()
	
	shareFacade:DispatchObservers(MURDER_SWEEP_POPUP_SHOWUP_EVENT, {
		stageId = self.stageId
	})
end
function MurderBattleReadyView:CreateRecommendCards(parent)
    local recommendCards = nil 
    if self.battleType == 4 then
		recommendCards = app.murderMgr:GetMaterialQuestAdditionCardsByQuestId(self.stageId)
    elseif self.battleType == 5 then
		recommendCards = app.murderMgr:GetBossQuestAdditionCards()
    else
        return 
    end
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

function MurderBattleReadyView:CreateRecommendCard(cardId, scale)
	local size = cc.size(120,120)
	local layer = display.newLayer(0, 0, {size = size, ap = display.CENTER})

	local cardNodeData = {cardData = {cardId = cardId}, showBaseState = true, showActionState = false, showRecommendState = true}
	local cardHeadNode = require('common.CardHeadNode').new(cardNodeData)
	display.commonUIParams(cardHeadNode, {po = cc.p(size.width / 2, size.height / 2), ap = display.CENTER})
	cardHeadNode:setScale(scale)
	layer:addChild(cardHeadNode)

	local recommendImg = display.newImageView(app.murderMgr:GetResPath('ui/common/summer_activity_mvpxiangling_icon_unlock.png'), size.width - 22 , size.height - 20)
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

function MurderBattleReadyView:RefreshRecommendCards(recommendCards)
	self.recommendCardNodes = {}
	self.recommendCards = recommendCards
	self:CreateRecommendCards(self.recommendCardLayer)
	self:RefreshRecommendCardsState()
end

function MurderBattleReadyView:RefreshRecommendCardsState()
	for cardId, node in pairs(self.recommendCardNodes) do
		local viewData = node.viewData
		local recommendImg = viewData.recommendImg
		local frameSpine = viewData.frameSpine
		local isRecommend = self.teamCardIds[tostring(cardId)]

		if isRecommend then
			local iconPath = app.murderMgr:GetResPath('ui/common/summer_activity_mvpxiangling_icon.png')
			if self.battleType == 5 then
				iconPath = app.murderMgr:GetResPath('ui/home/activity/murder/murder_team_ico_vip_harm.png')
			end
			recommendImg:setTexture(iconPath)
			frameSpine:setVisible(true)
			frameSpine:setAnimation(0, 'idle', true)
		else
			local iconPath = app.murderMgr:GetResPath('ui/common/summer_activity_mvpxiangling_icon_unlock.png')
			if self.battleType == 5 then
				iconPath = app.murderMgr:GetResPath('ui/home/activity/murder/murder_team_ico_vip_harm_lock.png')
			end
			recommendImg:setTexture(iconPath)
			frameSpine:setVisible(false)
		end
	end
end

--[[
刷新中间队伍区域
@params data table 队伍信息
--]]
function MurderBattleReadyView:RefreshTeamFormation(data)
	------------ 处理编队数据 ------------
	local teamData = {}
	local teamCardIds = {}
	for tNo, tData in ipairs(data) do
		teamData[tNo] = {teamId = tData.teamId, members = {}}
		for no, card in ipairs(tData.cards) do
			if card.id then
				local id = checkint(card.id)
				local cardData = gameMgr:GetCardDataById(id)
				table.insert(teamData[tNo].members, {id = id, isLeader = id == checkint(tData.captainId)})
				teamCardIds[tostring(cardData.cardId)] = cardData.cardId
			end
		end
	end
	
	self.teamCardIds = teamCardIds
	self.teamData = teamData

	self:RefreshRecommendCardsState()
	if self.battleType == 4 then
		self:RefreshRewards()
	end
	self:RefreshTeamTabs()
end
--[[
刷新奖励区域
--]]
function MurderBattleReadyView:RefreshRewards()
	local addition = app.murderMgr:GetTeamMaterialQuestAddition(self.teamCardIds, self.stageId)
	if not addition then 
		-- 无加成
		if self.addGoodsNode then
			self.addGoodsNode:setVisible(false)
		end
	else
		-- 显示加成
		if self.addGoodsNode then
			self.addGoodsNode:RefreshSelf({
				id = addition.goodsId,
				num = addition.num,
				callBack = function( sender )
					AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = addition.goodsId, type = 1})
				end
			})
			self.addGoodsNode:setVisible(true)
		end
	end 
end
--[[
刷新队伍选中状态
--]]
function MurderBattleReadyView:RefreshTeamSelectedState(index)
	-- 刷新选中状态
	local preCircle = self.viewData.teamTabs[self.selectedTeamIdx]
	if preCircle then
		preCircle:setTexture(app.murderMgr:GetResPath('ui/common/maps_fight_ico_round_default.png'))
	end
	local curCircle = self.viewData.teamTabs[index]
	if curCircle then
		curCircle:setTexture(app.murderMgr:GetResPath('ui/common/maps_fight_ico_round_select.png'))
	end

	if table.nums(self.teamData) <= 1 then
		self.viewData.preTeamBtn:setVisible(false)
		self.viewData.nextTeamBtn:setVisible(false)
	elseif index == 1 then
		self.viewData.preTeamBtn:setVisible(false)
		self.viewData.nextTeamBtn:setVisible(true)
	elseif index == table.nums(self.teamData) then
		self.viewData.preTeamBtn:setVisible(true)
		self.viewData.nextTeamBtn:setVisible(false)
	else
		self.viewData.preTeamBtn:setVisible(true)
		self.viewData.nextTeamBtn:setVisible(true)
	end

	self.selectedTeamIdx = index

	-- 刷新队伍信息
	self.viewData.teamFormationLabel:setString(string.format(app.murderMgr:GetPoText(__('出战队伍%d')), self.selectedTeamIdx))

	self:RefreshTeamInfo(self.teamData[self.selectedTeamIdx])
	-- 刷新左侧信息
	local teamCardIds = {}
	for no, card in ipairs(self.teamData[self.selectedTeamIdx].members) do
		if card.id then
			local id = checkint(card.id)
			local cardData = gameMgr:GetCardDataById(id)
			teamCardIds[tostring(cardData.cardId)] = cardData.cardId
		end
	end
	self.teamCardIds = teamCardIds
	self:RefreshRecommendCardsState()
	if self.battleType == 4 then
		self:RefreshRewards()
	end

end
--[[
boss详情按钮回调
--]]
function MurderBattleReadyView:BossDetailBtnClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():RegistMediator(
		require('Game.mediator.BossDetailMediator').new({questId = self.stageId})
	)
end
return MurderBattleReadyView