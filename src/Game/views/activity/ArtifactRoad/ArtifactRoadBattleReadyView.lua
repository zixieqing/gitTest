local BattleReadyView = require('Game.views.BattleReadyView')
local ArtifactRoadBattleReadyView = class('ArtifactRoadBattleReadyView', BattleReadyView)
local shareFacade = AppFacade.GetInstance()
local uiMgr = app.uiMgr
local gameMgr = app.gameMgr

local BATTLE_TYPE = {
    COMMON_TYPE = 1 ,  	-- 普通模式
    PAID_TYPE 	= 2 	-- 付费模式
}

function ArtifactRoadBattleReadyView:ctor( ... )
	ArtifactRoadBattleReadyView.super.ctor(self, ...)  
end

--[[
init ui
--]]
function ArtifactRoadBattleReadyView:InitUI()

	-- bg mask
	-- local eaterLayer = display.newImageView(_res('ui/common/common_bg_mask.png'), display.cx, display.cy, {enable = true, animate = false})
	local eaterLayer = display.newLayer(display.cx, display.cy, {enable = true, size = display.size, color = '#000000', ap = cc.p(0.5, 0.5)})
	eaterLayer:setOpacity(0.7 * 255)
	self:addChild(eaterLayer, 1)

	-- 返回按钮
	local closeBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png"),
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
	-- 	{text = __('点击空白处返回'), fontSize = fontWithColor('9').fontSize, color = fontWithColor('9').color})
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
	local centerBg = display.newImageView(_res('ui/common/maps_fight_bg_information.png'), display.cx, display.height * 0.7,
			{scale9 = true, size = centerBgSize, enable = true, animate = false})
	self:addChild(centerBg, 5)

	-- player skill info
	local belongsBgFrame = display.newImageView(_res('ui/common/maps_fight_bg_information.png'),
		centerBg:getPositionX() - centerBgSize.width * 0.5 + belongsBgFrameSize.width * 0.5,
		centerBg:getPositionY() - centerBgSize.height * 0.5 - 80 - belongsBgFrameSize.height * 0.5,
		{scale9 = true, size = belongsBgFrameSize})
	belongsBgFrame:setName('belongsBgFrame')
	self:addChild(belongsBgFrame, 5)

	-- hint label
	local hintLabel = display.newLabel(0, 0,
		{text = __('点击技能图标更改主角技'), fontSize = 20, w = 350 , hAlign = display.TAC , ap = display.CENTER_BOTTOM ,  color = '#c8b3af'})
	display.commonUIParams(hintLabel, {po = cc.p(belongsBgFrameSize.width * 0.5, display.getLabelContentSize(hintLabel).height * 0.5 -25 )})
	belongsBgFrame:addChild(hintLabel)

	-- battle btn
	local battleBtn = require('common.CommonBattleButton').new({
		pattern = 1,
		clickCallback = function()
            local chooseQuestTypeView = require("Game.views.activity.ArtifactRoad.ArtifactRoadQuestChooseTypeView").new({questId = self.stageId , callfunc = handler(self, self.EnterBattle)})
            uiMgr:GetCurrentScene():AddDialog(chooseQuestTypeView)
            chooseQuestTypeView:setPosition(display.center)
        end
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
		costHpLabel = costHpLabel,
		costHpIcon = costHpIcon,
		costHpTime = costHpTime
	}

	if 2 == self.battleType then
		self.centerContentData = {
			-- {name = __('队伍'), tag = 1, initHandler = handler(self, self.InitTeamFormationPanel), showHandler = handler(self, self.ShowTeamFormationPanel)},
			{name = __('主角技'), tag = 1, initHandler = handler(self, self.InitPlayerSkillPanel), showHandler = handler(self, self.ShowPlayerSkillPanel)},
			-- {name = __('堕神诱饵'), tag = 2, initHandler = handler(self, self.InitMagicFoodPanel), showHandler = handler(self, self.ShowMagicFoodPanel)}
		}
		self:InitStageInfo()
	elseif 3 == self.battleType then
		self.centerContentData = {
			-- {name = __('队伍'), tag = 1, initHandler = handler(self, self.InitTeamFormationPanel), showHandler = handler(self, self.ShowTeamFormationPanel)},
			-- {name = __('主角技'), tag = 1, initHandler = handler(self, self.InitPlayerSkillPanel), showHandler = handler(self, self.ShowPlayerSkillPanel)}
		}
	else
		self.centerContentData = {
			-- {name = __('队伍'), tag = 1, initHandler = handler(self, self.InitTeamFormationPanel), showHandler = handler(self, self.ShowTeamFormationPanel)},
			{name = __('主角技'), tag = 1, initHandler = handler(self, self.InitPlayerSkillPanel), showHandler = handler(self, self.ShowPlayerSkillPanel)}
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
function ArtifactRoadBattleReadyView:InitStageInfo()

	local stageConf = CommonUtils.GetQuestConf(checkint(self.stageId))

	-- 关卡详情底板
	local stageInfoBgSize = cc.size(578, 605)
	local stageInfoBgPos = cc.p(display.SAFE_L + stageInfoBgSize.width * 0.5 + 30, display.height * 0.45)
	local stageInfoBg = display.newImageView(_res('ui/common/maps_fight_bg_information.png'), 0, 0,
		{scale9 = true, size = stageInfoBgSize, enable = true, animate = false})
	display.commonUIParams(stageInfoBg, {po = stageInfoBgPos})
	self:addChild(stageInfoBg, 5)

	-- 分隔线1 关卡信息
	local splitLineStageInfo = display.newNSprite(_res('ui/common/maps_fight_line.png'), stageInfoBgSize.width * 0.5, stageInfoBgSize.height - 70)
	stageInfoBg:addChild(splitLineStageInfo)

	local maxStarLabel = display.newLabel(
		splitLineStageInfo:getPositionX() - splitLineStageInfo:getContentSize().width * 0.5 + 5,
		splitLineStageInfo:getPositionY() + 20,
		{text = __('三星条件'), fontSize = 26,  reqW = 290 ,color = '#bba496', ap = cc.p(0, 0.5)})
	stageInfoBg:addChild(maxStarLabel)

	-- 天气预报
	local forecastLabel = display.newLabel(
		maxStarLabel:getPositionX(),
		stageInfoBgSize.height * 0.575,
		{text = __('天气情况'), fontSize = 26, color = '#bba496', ap = cc.p(0, 0.5)})
	stageInfoBg:addChild(forecastLabel)

	-- 分隔线2 关卡掉落
	local splitLineStageReward = display.newNSprite(_res('ui/common/maps_fight_line.png'), stageInfoBgSize.width * 0.5, 235)
	stageInfoBg:addChild(splitLineStageReward)

	-- 掉落信息
	local rewardLabel = display.newLabel(
		splitLineStageReward:getPositionX() - splitLineStageReward:getContentSize().width * 0.5 + 5,
		splitLineStageReward:getPositionY() + 20,
		{text = __('关卡掉落'), fontSize = 26, color = '#bba496', ap = cc.p(0, 0.5)})
	stageInfoBg:addChild(rewardLabel)

	local x = 1
	-- 扫荡按钮
	if QuestRechallenge.QR_CAN == checkint(stageConf.repeatChallenge) then
		-- 三星显示绿色按钮 未达到三星显示灰色按钮
		local btnPath = 'ui/common/common_btn_green.png'
		if (QuestBattleType.MAP == CommonUtils.GetQuestBattleByQuestId(self.stageId)) and
			(not gameMgr:CanSweepQuestByQuestGrade(self.stageId)) then
			btnPath = 'ui/common/common_btn_orange_disable.png'
		elseif (QuestBattleType.ARTIFACT_ROAD == CommonUtils.GetQuestBattleByQuestId(self.stageId)) and self.star ~= 3 then
			btnPath = 'ui/common/common_btn_orange_disable.png'
		end
		local sweepBtn = display.newButton(0, 0, {n = _res('ui/artifact/sore_btn_saodang_1.png'),scale9 = true , cb = handler(self, self.SweepBtnCallback)})
		display.commonUIParams(sweepBtn, {po = cc.p(stageInfoBgPos.x * 0.5, stageInfoBgPos.y - stageInfoBgSize.height * 0.5 + sweepBtn:getContentSize().height * 0.5 + 20)})
		display.commonLabelParams(sweepBtn, fontWithColor(14,{text = __('体力扫荡') , paddingW = 20}))
		sweepBtn:setTag(BATTLE_TYPE.COMMON_TYPE)
		self:addChild(sweepBtn, 20)
		x = 2
    end
    
    local PaidSweepBtn = display.newButton(0, 0, {n = _res('ui/artifact/sore_btn_saodang_2.png'), scale9 = true , cb = handler(self, self.SweepBtnCallback)})
	display.commonUIParams(PaidSweepBtn, {po = cc.p(stageInfoBgPos.x * 0.5 * (1 + x), stageInfoBgPos.y - stageInfoBgSize.height * 0.5 + PaidSweepBtn:getContentSize().height * 0.5 + 20)})
    display.commonLabelParams(PaidSweepBtn, fontWithColor(14,{text = __('门票扫荡'), hAlign = display.TAC , paddingW = 20 } ))
    PaidSweepBtn:setTag(BATTLE_TYPE.PAID_TYPE)
    self:addChild(PaidSweepBtn, 111)

	if stageConf then
		local questBattleType = CommonUtils.GetQuestBattleByQuestId(checkint(self.stageId))

		local stageTitleStr = ''
		local bgId = 1

		if QuestBattleType.MAP == questBattleType then

			stageTitleStr = string.format('%s-%s %s', stageConf.cityId, stageConf.position, stageConf.name)

			local cityConf = CommonUtils.GetConfig('quest', 'city', stageConf.cityId)
			bgId = cityConf.backgroundId[stageConf.difficulty]

		elseif QuestBattleType.ACTIVITY_QUEST == CommonUtils.GetQuestBattleByQuestId(checkint(self.stageId)) then

			stageTitleStr = string.format('%s', stageConf.name)

			local zoneId = checkint(stageConf.zoneId)
			local zoneConfig = CommonUtils.GetConfigNoParser('activityQuest', 'questType', zoneId)
			if nil ~= zoneConfig then
				local activityQuestConfig = zoneConfig[tostring(self.stageId)]
				if nil ~= activityQuestConfig then
					bgId = checkint(activityQuestConfig.backgroundId)
				end
			end
		elseif QuestBattleType.ARTIFACT_ROAD == CommonUtils.GetQuestBattleByQuestId(checkint(self.stageId)) then

			stageTitleStr = string.format('%s', stageConf.name)
		end
		-- 垫上一张背景图
        local bgView = CLayout:create(cc.size(1336,1002))
		local bgPath = string.format('arts/maps/maps_bg_%s', bgId)
        local leftImage = display.newImageView(_res(string.format('%s_01', bgPath)), 0, 0, {ap = display.LEFT_BOTTOM})
        bgView:addChild(leftImage)
        local rightImage = display.newImageView(_res(string.format('%s_02', bgPath)), 1336, 0, {ap = display.RIGHT_BOTTOM})
        bgView:addChild(rightImage)
        display.commonUIParams(bgView,{ap = display.CENTER, po = cc.p(self:getContentSize().width * 0.5, self:getContentSize().height * 0.5)})
        fullScreenFixScale(bgView)
        self:addChild(bgView)

		-- 关卡信息
		local stageTitleBg = display.newNSprite(_res('ui/common/maps_fight_bg_title.png'), 0, 0)
		display.commonUIParams(stageTitleBg, {po = cc.p(
			self.closeBtn:getPositionX() + self.closeBtn:getContentSize().width * 0.5 + stageTitleBg:getContentSize().width * 0.5 + 10,
			self.closeBtn:getPositionY())})
		self:addChild(stageTitleBg, 5)

		local stageTitleLabel = display.newLabel(stageTitleBg:getContentSize().width * 0.4, utils.getLocalCenter(stageTitleBg).y,
			{text = stageTitleStr , fontSize = 28, color = '#ffffff'})
		stageTitleBg:addChild(stageTitleLabel)
		self.stageTitleText = stageTitleStr

		-- 推荐战力
		local recommandLabel = display.newLabel(
			splitLineStageInfo:getPositionX() + splitLineStageInfo:getContentSize().width * 0.5 - 5,
			splitLineStageInfo:getPositionY() + 20,
			{text = string.format(__('(推荐等级:%d)'), checkint(stageConf.recommendLevel)), reqW = 200,  fontSize = 22, color = '#ffffff', ap = cc.p(1, 0.5)})
		stageInfoBg:addChild(recommandLabel)

		if QuestRechallenge.QR_CAN == checkint(stageConf.repeatChallenge) and nil ~= stageConf.allClean then
			-- 三星条件
			local itor = 1
			for k,v in pairs(stageConf.allClean) do
				local clearData = CommonUtils.GetConfig('quest', 'starCondition', checkint(k))
				local descr = CommonUtils.GetFixedClearDesc(clearData, v)
				local pass = table.nums(stageConf.allClean) == self.star
				local cleanLabelColor = '#ffffff'
				if pass then
					cleanLabelColor = '#ffd52c'
				end
				local cleanLabel = display.newLabel(maxStarLabel:getPositionX(), splitLineStageInfo:getPositionY() - 30 - (itor - 1) * 35,
					{text = descr, fontSize = 22, color = cleanLabelColor, reqW = 500 ,  ap = cc.p(0, 0.5)})
				stageInfoBg:addChild(cleanLabel)
				itor = itor + 1
			end

			if 0 < checkint(stageConf.challengeTime) then
				-- 剩余挑战次数
				local challengeTimeLabelBg = display.newNSprite(_res('ui/battleready/maps_fight_bg_challenge_times.png'), 0, 0)
				self:addChild(challengeTimeLabelBg, 5)
				self.challengeTimeLabelBg = challengeTimeLabelBg

				local challengeTimeDescrLabel = display.newLabel(0, 0, {
					text = __('今日挑战次数'), fontSize = fontWithColor('18').fontSize, color = fontWithColor('18').color, ap = cc.p(0, 0.5)})
				display.commonUIParams(challengeTimeDescrLabel, {po = cc.p(5, utils.getLocalCenter(challengeTimeLabelBg).y)})
				challengeTimeLabelBg:addChild(challengeTimeDescrLabel)

				local challengeTimeLabel = display.newLabel(0, 0, {
					text = string.format('%d/%d', checkint(gameMgr:GetUserInfo().allQuestChallengeTimes[tostring(self.stageId)]), checkint(stageConf.challengeTime)), fontSize = 22, color = '#ffd52c'})
				display.commonUIParams(challengeTimeLabel, {po = cc.p(170, utils.getLocalCenter(challengeTimeLabelBg).y)})
				challengeTimeLabelBg:addChild(challengeTimeLabel)
				self.challengeTimeLabel = challengeTimeLabel

				local buyChallengTimeBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_add.png'), cb = function (sender)
					AppFacade.GetInstance():DispatchObservers("SHOW_BUY_CHALLENGE_TIME", {stageId = self.stageId})
				end})
				self:addChild(buyChallengTimeBtn, 5)
				self.buyChallengTimeBtn = buyChallengTimeBtn
			end

		else
			local noAllCleanLabel = display.newLabel(
				maxStarLabel:getPositionX() + 3,
				splitLineStageInfo:getPositionY() - 50,
				{text = __('本关卡无三星过关条件'), fontSize = 22, color = '#c9b4b0', ap = cc.p(0, 0.5)})
			stageInfoBg:addChild(noAllCleanLabel)
		end

		-- 天气情况
		local weatherId = nil
		local weatherIconScale = 0.4
		for i,v in ipairs(stageConf.weatherId) do
			weatherId = checkint(v)
			local weatherConf = CommonUtils.GetConfig('quest', 'weather', weatherId)
			local weatherBtn = display.newButton(0, 0, {
				n = _res(string.format('ui/common/fight_ico_weather_%d.png', checkint(weatherConf.weatherProperty))),
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
		local goldIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(900002)), 0, 0)
		goldIcon:setScale(iconScale)
		display.commonUIParams(goldIcon, {po = cc.p(splitLineStageReward:getPositionX() + 75, splitLineStageReward:getPositionY() + 20)})
		stageInfoBg:addChild(goldIcon)

		local goldLabel = display.newLabel(
			goldIcon:getPositionX() + goldIcon:getContentSize().width * 0.5 * iconScale + 5,
			goldIcon:getPositionY(),
			{text = tostring(stageConf.gold), fontSize = 22, color = '#ffffff', ap = cc.p(0, 0.5)})
		stageInfoBg:addChild(goldLabel)

		local expIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(EXP_ID)), 0, 0)
		expIcon:setScale(iconScale)
		display.commonUIParams(expIcon, {po = cc.p(goldIcon:getPositionX() + 120, splitLineStageReward:getPositionY() + 20)})
		stageInfoBg:addChild(expIcon)
		local doubleExpSpine = self:GetDoubleActivitySpine()
		if doubleExpSpine  then
			stageInfoBg:addChild(doubleExpSpine)
			doubleExpSpine:setPosition(goldIcon:getPositionX() + 210, splitLineStageReward:getPositionY() + 20)
		end
		local mainExp = stageConf.mainExp
		if stageConf.firstPassMainExp and checkint(self.stageId) >= gameMgr:GetNewestQuestIdByDifficulty(checkint(stageConf.difficulty)) then
			mainExp = stageConf.firstPassMainExp

			local firstLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('首次通关')}))
			display.commonUIParams(firstLabel, {ap = cc.p(0, 0), po = cc.p(
				expIcon:getPositionX() - expIcon:getContentSize().width * 0.5 * iconScale,
				expIcon:getPositionY() + expIcon:getContentSize().height * 0.5 * iconScale
			)})
			stageInfoBg:addChild(firstLabel)
		end

		local expLabel = display.newLabel(
			expIcon:getPositionX() + expIcon:getContentSize().width * 0.5 * iconScale + 5,
			expIcon:getPositionY(),
			{text = tostring(mainExp), fontSize = 22, color = '#ffffff', ap = cc.p(0, 0.5)})
		stageInfoBg:addChild(expLabel)

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
				local goodNode = require('common.GoodNode').new({id = checkint(v.goodsId), num = v.num, showAmount = true, callBack = callBack})
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

function ArtifactRoadBattleReadyView:AddTopCurrency( currency, args )
	local GoodPurchaseNode = require('common.GoodPurchaseNode')
	-- top icon
	local currencyBG = display.newImageView(_res('ui/home/nmain/main_bg_money'),0,0,{enable = false, scale9 = true, size = cc.size(480 + (display.width - display.SAFE_R),54)})
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
扫荡按钮回调
--]]
function ArtifactRoadBattleReadyView:SweepBtnCallback(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local sweepView = require("Game.views.activity.ArtifactRoad.ArtifactRoadQuestSweepView").new({
        questId = self.stageId  ,
        questType = tag ,
		star = self.star,
		activityId = self.enterBattleRequestData.activityId
    })
    sweepView:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(sweepView)
end
--[[
进入战斗
--]]
function ArtifactRoadBattleReadyView:EnterBattle(sender)
    local tag = sender:getTag()
    self.enterBattleRequestData.consumeType = tag
    self.exitBattleRequestData.consumeType = tag
	------------ 本地逻辑判断 ------------
	-- 是否可以进入该关卡
	local canEnter, errLog = CommonUtils.CanEnterStageIdByStageId(self.stageId)
	if not canEnter then
		uiMgr:ShowInformationTips(errLog)
		return
	end

	-- 是否可以复刷
	local stageConf = CommonUtils.GetQuestConf(checkint(self.stageId))
	if stageConf and QuestRechallenge.QR_CAN == checkint(stageConf.repeatChallenge) and 0 < checkint(stageConf.challengeTime) then
		-- 可以复刷的条件
		if QuestRechallengeTime.QRT_NONE == checkint(gameMgr:GetUserInfo().allQuestChallengeTimes[tostring(self.stageId)]) then
			-- 次数不够
			uiMgr:ShowInformationTips(__('挑战次数不足\n挑战次数每日0:00重置'))
			return
		end
	end
	------------ 本地逻辑判断 ------------

	local selectedTeamData = self.teamData[self.selectedTeamIdx]

	if table.nums(selectedTeamData.members) == 0 then
		-- TODO 跳转编队
		local CommonTip  = require( 'common.CommonTip' ).new({text = __('队伍不能为空'),isOnlyOK = true})
		CommonTip:setPosition(display.center)
		AppFacade.GetInstance():GetManager("UIManager"):GetCurrentScene():AddDialog(CommonTip)
	else

		-- 如果是工会神兽战 传信号出去 不在里面处理
		if QuestBattleType.UNION_BEAST == self.questBattleType then
			local data = {
				teamIdx = self.selectedTeamIdx
			}
			AppFacade.GetInstance():DispatchObservers('ENTER_UNION_BEAST_BATTLE', data)
			return
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

		local canBattle, waringText = battleConstructor:CanEnterBattleByTeamId(self.selectedTeamIdx)
		if not canBattle then
			if nil ~= waringText then
				uiMgr:ShowInformationTips(waringText)
			end
			return
		end

		if QuestBattleType.ROBBERY == self.questBattleType then
		-- if true then
			battleConstructor:InitDataByTakeawayRobbery(self.selectedTeamIdx, serverCommand, fromToStruct)
		elseif QuestBattleType.UNION_PARTY == self.questBattleType then
			battleConstructor:InitDataByUnionParty(self.stageId, self.selectedTeamIdx, serverCommand, fromToStruct)
		else
			battleConstructor:InitByNormalStageIdAndTeamId(self.stageId, self.selectedTeamIdx, serverCommand, fromToStruct)
		end

		GuideUtils.DispatchStepEvent()


		if checkint(battleConstructor.battleConstructorData.totalWave) > 0 then
			AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)
		else
			app.uiMgr:ShowInformationTips(__('该关卡未配置敌人'))
		end

	end
end

return ArtifactRoadBattleReadyView