--[[
组队战斗胜利界面
@params table {
	viewType = viewType,
	cleanCondition = nil,{
	showMessage = false,
	canRepeatChallenge = false,
	teamData = self:GetBData():getFriendMembers(1),
	trophyData = responseData,
	playersData = playersData,
	playerRewardsData = self.playerRewardsData}
}
--]]
local BattleSuccessView = __Require('battle.view.BattleSuccessView')
local RaidBattleSuccessView = class('RaidBattleSuccessView', BattleSuccessView)

------------ import ------------
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance('AppFacade'):GetManager("CardManager")
local uiMgr = AppFacade.GetInstance('AppFacade'):GetManager("UIManager")
------------ import ------------

------------ define ------------

------------ define ------------

--[[
@override
constructor
--]]
function RaidBattleSuccessView:ctor( ... )
	local args = unpack({...})
	-- dump(args)
	-- local testJson = json.encode(args)
	-- print('here check fuck json>>>>>>>', testJson)

	cc.Director:getInstance():getScheduler():setTimeScale(1)

	self.viewType = args.viewType
	self.cleanCondition = args.cleanCondition
	self.showMessage = args.showMessage
	self.canRepeatChallenge = args.canRepeatChallenge or false 
	self.teamData = args.teamData
	self.trophyData = args.trophyData
	self.playersData = args.playersData

	------------ 动画配置 ------------
	self.fps = 30
	self.layers = {}
	self.curLayer = nil
	------------ 动画配置 ------------

	self.rewardsParentNode = nil
	self.rewardsBg = nil
	self.rewardNodes = {}
	self.backBtn = nil
	self.repeatBtn = nil
	self.drawNode = nil
	self.drawRewardsNodes = {}
	self.selectedCardIndex = nil
	self.drawRewardsLayer = nil

	self.messageLabel = nil
	self.messageListView = nil
	self.messageListViewBg = nil
	self.selectedMessageIndex = nil

	self.canTouchBackBtn = true

	self.leftChallengeTimes = {}
	for k,v in pairs(self.playersData) do
		self.leftChallengeTimes[tostring(v.playerId)] = checkint(v.raidLeftChallengeTimes)
	end

	local selfPlayerId = checkint(gameMgr:GetUserInfo().playerId)
	-- 如果本地次数为0 取一次服务器次数
	if 0 >= checkint(self.leftChallengeTimes[tostring(selfPlayerId)]) then
		-- 刷新一次自己的剩余次数
		if self.trophyData and self.trophyData.leftAttendTimes then
			self.leftChallengeTimes[tostring(selfPlayerId)] = checkint(self.trophyData.leftAttendTimes)
		end
	end

	-- 向外传参 延迟的升级奖励信息
	self.delayUpgradeLevelData = {}

	-- debug --
	-- self.trophyData.rareRewards = {
	-- 	{goodsId = 250123, num = 1}
	-- }
	-- debug --

	self.canShowNormalRewards = {
		[tostring(gameMgr:GetUserInfo().playerId)] = true -- 自己默认能显示
	}
	for k,v in pairs(args.canShowNormalRewards) do
		if nil ~= v then
			self.canShowNormalRewards[k] = v
		end
	end

	-- 处理一次玩家奖励信息
	self.playerRewardsData = args.playerRewardsData
	self.playerRewardsNodes = {}
	self:AddPlayerRewards(
		gameMgr:GetUserInfo().playerId,
		self.trophyData.rewardIndex,
		self.trophyData.rewards,
		self.trophyData.rareRewards,
		self.trophyData.extraRewards
	)

	-- 分享确认按钮锁
	self.canHideShareView = false

	self:InitUI()
	self:UpdateLocalData()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function RaidBattleSuccessView:InitUI()
	local commonLayer = self:InitCommonLayer()
	table.insert(self.layers, commonLayer)

	if 0 < checkint(self:GetLeftChallengeTimeByPlayerId(gameMgr:GetUserInfo().playerId)) then
		-- 如果没有次数 不初始化翻牌界面
		local drawRewardsLayer = self:InitDrawRewardsLayer()
		table.insert(self.layers, drawRewardsLayer)
	end

	local rareRewardData = self:GetPlayerRareRewardByPlayerId(checkint(gameMgr:GetUserInfo().playerId))
	if nil ~= rareRewardData then
		local rareRewardLayer = self:InitRareRewardLayer()
		table.insert(self.layers, rareRewardLayer)
	end

	local playerInfoLayer = self:InitPlayerInfoLayer()
	table.insert(self.layers, playerInfoLayer)

	self:RegistBtnClickHandler()
end
--[[
@override
获取common层底部nodes
@params parentNode cc.Node 父节点
--]]
function RaidBattleSuccessView:AddCommonBottomLayer(parentNode)

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
		local skadaBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_white_default.png') , scale9 = true})
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
				-- cc.Show:create(),
				cc.FadeTo:create(0.5, 255),
				cc.DelayTime:create(1),
				cc.CallFunc:create(function ()
					------------ 动画完成 直接进行下一步 ------------
					self:ShowNextLayer()
					------------ 动画完成 直接进行下一步 ------------
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
初始化翻牌界面
--]]
function RaidBattleSuccessView:InitDrawRewardsLayer()
	local layerSize = cc.size(display.width, display.height)

	-- 翻牌层节点
	local drawRewardsLayer = display.newLayer(display.cx, display.cy, {size = layerSize, ap = cc.p(0.5, 0.5)})
	self:addChild(drawRewardsLayer, 3)
	self.drawRewardsLayer = drawRewardsLayer
	-- drawRewardsLayer:setBackgroundColor(cc.c4b(255, 120, 21, 100))

	-- title
	local titleLabel = display.newImageView(_res('ui/battle/battleresult/common_words_flop.png'), 0, 0)
	display.commonUIParams(titleLabel, {po = cc.p(display.SAFE_CX, display.SAFE_RECT.height * 0.9)})
	drawRewardsLayer:addChild(titleLabel)

	-- 牌
	local rewards = self.trophyData.rewards
	local rewardsAmount = #rewards
	local layerTowords = -1
	for i = 1, rewardsAmount do
		-- 牌背
		local rewardBg = display.newImageView(_res('ui/battle/battleresult/team_fight_flop_btn_default.png'), 0, 0)
		local rewardCardLayer = display.newLayer(0, 0, {size = rewardBg:getContentSize()})
		display.commonUIParams(rewardCardLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
			display.SAFE_CX + ((i - 0.5) - rewardsAmount * 0.5) * (rewardBg:getContentSize().width + 50),
			display.SAFE_RECT.height * 0.55
		)})
		rewardCardLayer:setScaleX(layerTowords)
		drawRewardsLayer:addChild(rewardCardLayer, 5)	

		display.commonUIParams(rewardBg, {po = utils.getLocalCenter(rewardBg)})
		rewardBg:setScaleX(-1)
		rewardCardLayer:addChild(rewardBg, 5)

		-- 牌光
		local rewardLight = display.newImageView(_res('ui/battle/battleresult/team_fight_flop_btn_light.png'), 0, 0)
		display.commonUIParams(rewardLight, {po = utils.getLocalCenter(rewardCardLayer)})
		rewardCardLayer:addChild(rewardLight)
		rewardLight:setVisible(false)

		-- 牌面
		local rewardFront = display.newImageView(_res('ui/battle/battleresult/team_fight_flop_btn_select.png'), 0, 0)
		display.commonUIParams(rewardFront, {po = cc.p(
			rewardBg:getPositionX(),
			rewardBg:getPositionY()
		)})
		rewardCardLayer:addChild(rewardFront, 4)
		rewardFront:setScaleX(layerTowords)

		-- 隐藏的按钮
		local drawRewardsBtn = display.newButton(0, 0, {size = rewardCardLayer:getContentSize()})
		display.commonUIParams(drawRewardsBtn, {po = cc.p(
			rewardCardLayer:getPositionX(),
			rewardCardLayer:getPositionY()
		),
		cb = handler(self, self.DrawCardClickHandler)})
		drawRewardsLayer:addChild(drawRewardsBtn)
		drawRewardsBtn:setTag(i)

		self.drawRewardsNodes[i] = {
			rewardNode = rewardCardLayer,
			layerTowords = layerTowords,
			rewardBg = rewardBg,
			rewardLight = rewardLight,
			rewardFront = rewardFront,
			rewardBtn = drawRewardsBtn,
			rewardIcon = nil
		}

		------------ 初始化动画状态 ------------
		rewardCardLayer:setVisible(false)
		rewardCardLayer:setOpacity(0)

		drawRewardsBtn:setEnabled(false)
		------------ 初始化动画状态 ------------

	end

	-- 倒计时
	local countdownSecond = 5
	local countdown = display.newLabel(0, 0, {text = tostring(countdownSecond), fontSize = 30, color = '#d23d3d', ttf = true, font = TTF_GAME_FONT})
	drawRewardsLayer:addChild(countdown)

	local countdownLabel = display.newLabel(0, 0, {text = __('秒后自动翻牌'), fontSize = 30, color = '#ffffff', ttf = true, font = TTF_GAME_FONT})
	drawRewardsLayer:addChild(countdownLabel)

	display.setNodesToNodeOnCenter(drawRewardsLayer, {countdown, countdownLabel}, {y = 35})

	------------ 初始化动画状态 ------------
	drawRewardsLayer:setVisible(false)

	titleLabel:setVisible(false)
	titleLabel:setOpacity(0)

	countdown:setVisible(false)
	countdown:setOpacity(0)

	countdownLabel:setVisible(false)
	countdownLabel:setOpacity(0)
	------------ 初始化动画状态 ------------

	local ShowSelf = function ()
		drawRewardsLayer:setVisible(true)

		local delayTime = 10 / self.fps

		------------ 隐藏立绘 ------------
		local drawNodeActionSeq = cc.Sequence:create(
			cc.FadeTo:create(delayTime, 0),
			cc.Hide:create()
		)
		self.drawNode:runAction(drawNodeActionSeq)
		------------ 隐藏立绘 ------------

		------------ 显示标题 ------------
		local titleActionSeq = cc.Sequence:create(
			cc.DelayTime:create(delayTime),
			cc.Show:create(),
			cc.FadeTo:create(0.2, 255)
		)
		titleLabel:runAction(titleActionSeq)
		------------ 显示标题 ------------

		------------ 牌动画 ------------
		local cardDelayTime = 0
		for i,v in ipairs(self.drawRewardsNodes) do
			cardDelayTime = delayTime + 0.1 + (i - 1) * 0.25
			local rewardNodeActionSeq = cc.Sequence:create(
				cc.DelayTime:create(cardDelayTime),
				cc.CallFunc:create(function ()
					PlayAudioClip(AUDIOS.UI.ui_teamwork_appear.id)
				end),
				cc.Show:create(),
				cc.FadeTo:create(0.5, 255)
			)
			v.rewardNode:runAction(rewardNodeActionSeq)
		end
		------------ 牌动画 ------------

		------------ 倒计时动画 ------------
		local countdownActionSeq = cc.Sequence:create(
			cc.DelayTime:create(cardDelayTime + 0.5),
			cc.Show:create(),
			cc.FadeTo:create(0.5, 255),
			cc.CallFunc:create(function ()
				for i,v in ipairs(self.drawRewardsNodes) do
					v.rewardBtn:setEnabled(true)
				end
			end),
			cc.DelayTime:create(0.25),
			CountAction:create(4, countdownSecond, 1),
			cc.CallFunc:create(function ()
				countdown:setString('0')
				-- 自动翻牌
				self:AutoDrawReward()

				-- 隐藏倒计时label
				local hideActionSeq = cc.Sequence:create(
					cc.FadeTo:create(0.5, 0),
					cc.Hide:create()
				)
				countdown:runAction(hideActionSeq:clone())
				countdownLabel:runAction(hideActionSeq:clone())

				------------ 发送信号 翻牌结束 ------------
				AppFacade.GetInstance():DispatchObservers('RAID_PLAYER_CHOOSE_REWARD', {playerId = checkint(gameMgr:GetUserInfo().playerId)})
				------------ 发送信号 翻牌结束 ------------
			end)
		)
		countdown:runAction(countdownActionSeq)

		local countdownLabelActionSeq = cc.Sequence:create(
			cc.DelayTime:create(cardDelayTime + 0.5),
			cc.Show:create(),
			cc.FadeTo:create(0.5, 255)
		)
		countdownLabel:runAction(countdownLabelActionSeq)
		------------ 倒计时动画 ------------


	end

	local HideSelf = function ()

		-- 屏蔽触摸
		self.canTouch = false

		local animationConf = {
			hideMoveTime = 15,
			hideMoveY = 85
		}

		local drawRewardsLayerActionSeq = cc.Sequence:create(
			cc.EaseIn:create(
				cc.Spawn:create(
					cc.MoveBy:create(animationConf.hideMoveTime / self.fps, cc.p(0, animationConf.hideMoveY)),
					cc.FadeTo:create(animationConf.hideMoveTime / self.fps, 0)),
				2
			),
			cc.Hide:create()
		)
		drawRewardsLayer:runAction(drawRewardsLayerActionSeq)

	end

	local layer = {ShowSelf = ShowSelf, HideSelf = HideSelf}
	return layer
end
--[[
添加翻牌界面底部点击继续的文字
@params parentNode cc.Node 父节点
--]]
function RaidBattleSuccessView:AddDrawRewardsBottomLayer(parentNode)
	local nextLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('点击空白处继续')}))
	display.commonUIParams(nextLabel, {po = cc.p(
		utils.getLocalCenter(parentNode).x,
		35
	)})
	parentNode:addChild(nextLabel)
	nextLabel:setTag(3)

	------------ 初始化动画状态 ------------
	nextLabel:setVisible(false)
	nextLabel:setOpacity(0)
	------------ 初始化动画状态 ------------

	local ShowSelf = function (delayTime)

		------------ 下一层文字 ------------
		local nextLabelActionSeq = cc.Sequence:create(
			cc.DelayTime:create(delayTime or 0),
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

	local HideSelf = function ()

	end

	local layer = {ShowSelf = ShowSelf, HideSelf = HideSelf}
	return layer

end
--[[
初始化玩家信息结算层
--]]
function RaidBattleSuccessView:InitPlayerInfoLayer()
	local layerSize = cc.size(display.width, display.height)

	local animationConf = {
		contentBgMoveY = 75,
		contentBgMoveTime = 10 
	}

	-- 玩家信息汇总节点
	local playerInfoLayer = display.newLayer(display.cx, display.cy, {size = layerSize, ap = cc.p(0.5, 0.5)})
	self:addChild(playerInfoLayer, 2)
	-- playerInfoLayer:setBackgroundColor(cc.c4b(255, 120, 21, 100))

	-- 创建玩家信息层
	local sk = sortByKey(self.playersData)
	for i, playerPos in ipairs(sk) do
		local playerData = self.playersData[tostring(playerPos)]

		-- 背景
		local playerInfoBg = display.newImageView(_res('ui/battle/battleresult/team_fight_reward_bg.png'), 0, 0)
		local playerInfoBgSize = playerInfoBg:getContentSize()
		local playerInfoBgLayer = display.newLayer(0, 0, {size = playerInfoBgSize})
		display.commonUIParams(playerInfoBgLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
			layerSize.width - playerInfoBgSize.width * 0.5,
			layerSize.height - 20 - (i - 0.5) * (playerInfoBgSize.height + 10)
		)})
		playerInfoLayer:addChild(playerInfoBgLayer)

		display.commonUIParams(playerInfoBg, {po = utils.getLocalCenter(playerInfoBgLayer)})
		playerInfoBgLayer:addChild(playerInfoBg)

		-- 玩家头像
		local playerHeadNodeScale = 0.85
		local playerHeadNode = require('common.PlayerHeadNode').new({
			playerId = checkint(playerData.playerId),
			avatar = tostring(playerData.avatar),
			avatarFrame = tostring(playerData.avatarFrame),
			showLevel = false,
			defaultCallback = true
		})
		display.commonUIParams(playerHeadNode, {po = cc.p(
			playerInfoBgSize.width * 0.2,
			playerInfoBgSize.height * 0.5 + 15
		)})
		playerHeadNode:setScale(playerHeadNodeScale)
		playerInfoBgLayer:addChild(playerHeadNode)

		-- 玩家名字
		local nameColor = checkint(playerData.playerId) == checkint(gameMgr:GetUserInfo().playerId) and '#ffc600' or '#ffffff'
		local playerNameLabel = display.newLabel(0, 0, {text = tostring(playerData.playerName), fontSize = 24, color = nameColor})
		display.commonUIParams(playerNameLabel, {ap = cc.p(0.5, 1), po = cc.p(
			playerHeadNode:getPositionX(),
			playerHeadNode:getPositionY() - playerHeadNode:getContentSize().height * 0.5 * playerHeadNodeScale - 5
		)})
		playerInfoBgLayer:addChild(playerNameLabel)

		------------ 普通奖励 ------------
		-- 奖励
		local rewardsLabel = display.newLabel(0, 0, fontWithColor('18', {text = __('获得奖励')}))
		display.commonUIParams(rewardsLabel, {ap = cc.p(1, 1), po = cc.p(
			playerInfoBgSize.width - 200,
			playerInfoBgSize.height - 20
		)})
		playerInfoBgLayer:addChild(rewardsLabel)

		-- 奖励节点
		local rewardsData = self:GetPlayerRewardsByPlayerId(checkint(playerData.playerId))
		local canShowNormalRewards = self:GetCanShowNormalRewards(checkint(playerData.playerId))
		local rewardsId = 0
		local amount = 0

		local baseRewardX = playerInfoBgSize.width - 240

		if nil ~= rewardsData and canShowNormalRewards then
			rewardsId = checkint(rewardsData.goodsId)
			amount = checkint(rewardsData.num)
		end
		local goodsNode = require('common.GoodNode').new({
			id = rewardsId,
			amount = amount,
			showAmount = amount > 0,
			callBack = function (sender)
				PlayAudioByClickNormal()
				local rewardsData = self:GetPlayerRewardsByPlayerId(checkint(playerData.playerId))
				local canShowNormalRewards = self:GetCanShowNormalRewards(checkint(playerData.playerId))
				if nil ~= rewardsData and 0 ~= checkint(rewardsData.goodsId) and canShowNormalRewards then
					uiMgr:ShowInformationTipsBoard({
						targetNode = self.playerRewardsNodes[tostring(playerData.playerId)].goodsNode, iconId = checkint(rewardsData.goodsId), type = 1	
					})
				end
			end
		})
		display.commonUIParams(goodsNode, {po = cc.p(
			baseRewardX,
			playerInfoBgSize.height * 0.5
		)})
		playerInfoBgLayer:addChild(goodsNode)

		-- 如果没有次数 隐藏基础奖励节点
		local showBaseReward = 0 < checkint(self:GetLeftChallengeTimeByPlayerId(playerData.playerId))
		rewardsLabel:setVisible(showBaseReward)
		goodsNode:setVisible(showBaseReward)
		------------ 普通奖励 ------------

		------------ 额外奖励 ------------
		-- 额外奖励节点
		local extraGoodsNodes = {}
		local extraRewardsData = self:GetPlayerExtraRewardsByPlayerId(checkint(playerData.playerId))

		if nil ~= extraRewardsData then
			for extraRewardIndex_, extraRewardData_ in ipairs(extraRewardsData) do
				local extraGoodsNode = require('common.GoodNode').new({
					goodsId = checkint(extraRewardData_.goodsId),
					amount = checkint(extraRewardData_.num),
					showAmount = true,
					callBack = function (sender)
					PlayAudioByClickNormal()
						local extraRewardsData = self:GetPlayerExtraRewardsByPlayerId(checkint(playerData.playerId))
						print('here check fuck extra<<<<<<<<<<<<<<<<', extraRewardIndex_, playerData.playerId)
						dump(extraRewardsData)
						if nil ~= extraRewardsData then
							if nil ~= extraRewardsData[extraRewardIndex_] then
								uiMgr:ShowInformationTipsBoard({
									targetNode = self.playerRewardsNodes[tostring(playerData.playerId)].extraGoodsNodes[extraRewardIndex_],
									iconId = checkint(extraRewardsData[extraRewardIndex_].goodsId),
									type = 1
								})
							end
						end
					end
				})
				local orix = baseRewardX
				if showBaseReward then
					-- 如果显示基础奖励 向右移一格
					orix = baseRewardX + (extraGoodsNode:getContentSize().width + 10)
				end
				display.commonUIParams(extraGoodsNode, {po = cc.p(
					orix + (extraRewardIndex_ - 1) * (extraGoodsNode:getContentSize().width + 10),
					playerInfoBgSize.height * 0.5
				)})
				playerInfoBgLayer:addChild(extraGoodsNode)

				table.insert(extraGoodsNodes, extraGoodsNode)
			end

			rewardsLabel:setVisible(0 < #extraRewardsData)
		end
		------------ 额外奖励 ------------

		------------ 稀有奖励 ------------
		-- 稀有奖励节点
		local rareRewardData = self:GetPlayerRareRewardByPlayerId(checkint(playerData.playerId))
		local rareRewardId = 0
		local rareRewardAmount = 0
		if nil ~= rareRewardData then
			rareRewardId = checkint(rareRewardData.goodsId)
			rareRewardAmount = checkint(rareRewardData.num)
		end

		local rareRewardsLabel = display.newLabel(0, 0, fontWithColor('18', {text = __('超稀有奖励!'), color = '#ffc600'}))
		display.commonUIParams(rareRewardsLabel, {ap = cc.p(0.5, 1), po = cc.p(
			playerInfoBgSize.width - 380,
			rewardsLabel:getPositionY()
		)})
		playerInfoBgLayer:addChild(rareRewardsLabel)

		local rareRewardGoodsNode = require('common.GoodNode').new({
			id = rareRewardId,
			amount = rareRewardAmount,
			showAmount = amount > 0,
			callBack = function (sender)
				PlayAudioByClickNormal()
				dump(playerData)
				dump(rewardsData)
				local rewardsData = self:GetPlayerRareRewardByPlayerId(checkint(playerData.playerId))
				if nil ~= rewardsData and 0 ~= checkint(rewardsData.goodsId) then
					uiMgr:ShowInformationTipsBoard({
						targetNode = self.playerRewardsNodes[tostring(playerData.playerId)].rareRewardGoodsNode, iconId = checkint(rewardsData.goodsId), type = 1	
					})
				end
			end
		})
		display.commonUIParams(rareRewardGoodsNode, {po = cc.p(
			rareRewardsLabel:getPositionX(),
			playerInfoBgSize.height * 0.5
		)})
		playerInfoBgLayer:addChild(rareRewardGoodsNode)

		-- 如果当前没有获得稀有奖励 隐藏稀有奖励信息
		if nil == rareRewardData or 0 == rareRewardId then
			rareRewardsLabel:setVisible(false)
			rareRewardGoodsNode:setVisible(false)
		end
		------------ 稀有奖励 ------------

		self.playerRewardsNodes[tostring(playerData.playerId)] = {
			playerInfoBgLayer = playerInfoBgLayer,
			goodsNode = goodsNode,
			rareRewardsLabel = rareRewardsLabel,
			rareRewardGoodsNode = rareRewardGoodsNode,
			extraGoodsNodes = extraGoodsNodes,
			rewardsLabel = rewardsLabel
		}

		------------ 初始化动画状态 ------------
		playerInfoBgLayer:setVisible(false)
		playerInfoBgLayer:setOpacity(0)
		display.commonUIParams(playerInfoBgLayer, {po = cc.p(
			playerInfoBgLayer:getPositionX(),
			playerInfoBgLayer:getPositionY() - animationConf.contentBgMoveY
		)})
		------------ 初始化动画状态 ------------
	end

	-- 返回按钮
	local backBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
	display.commonUIParams(backBtn, {po = cc.p(
		display.SAFE_R - backBtn:getContentSize().width * 0.5 - 20,
		display.SAFE_B + backBtn:getContentSize().height * 0.5 + 20
	)})
	display.commonLabelParams(backBtn, fontWithColor('14', {text = __('退出')}))
	playerInfoLayer:addChild(backBtn)
	self.backBtn = backBtn

	-- 伤害统计按钮
	local skadaBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_white_default.png') , scale9 = true })
	local x = backBtn:getPositionX() - (skadaBtn:getContentSize().width * 0.5 + backBtn:getContentSize().width * 0.5 + 50)
	display.commonUIParams(skadaBtn, {po = cc.p(
		x,
		backBtn:getPositionY()
	)})
	display.commonLabelParams(skadaBtn, fontWithColor('14', {text = __('伤害统计') , paddingW = 10 }))
	playerInfoLayer:addChild(skadaBtn)
	self.skadaBtn = skadaBtn

	------------ 初始化动画状态 ------------
	playerInfoLayer:setVisible(false)

	backBtn:setVisible(false)
	backBtn:setOpacity(0)

	skadaBtn:setVisible(false)
	skadaBtn:setOpacity(0)
	------------ 初始化动画状态 ------------

	local ShowSelf = function ()
		playerInfoLayer:setVisible(true)

		local delayTime = 10 / self.fps

		------------ 显示立绘 ------------
		local drawNodeActionSeq = cc.Sequence:create(
			cc.DelayTime:create(delayTime),
			cc.Show:create(),
			cc.FadeTo:create(delayTime, 255)
		)
		self.drawNode:runAction(drawNodeActionSeq)
		------------ 显示立绘 ------------

		------------ 显示显示玩家奖励 ------------
		local costTime = 0
		local sk = sortByKey(self.playersData)
		for i, playerPos in ipairs(sk) do
			local playerData = self.playersData[tostring(playerPos)]
			local nodes = self.playerRewardsNodes[tostring(playerData.playerId)]
			local delayTime_ = delayTime + 0.2 + (i - 1) * 0.25
			local actionSeq = cc.Sequence:create(
				cc.DelayTime:create(delayTime_),
				cc.Show:create(),
				cc.Spawn:create(
					cc.MoveBy:create(animationConf.contentBgMoveTime / self.fps, cc.p(0, animationConf.contentBgMoveY)),
					cc.FadeTo:create(animationConf.contentBgMoveTime / self.fps, 255)
				)
			)
			nodes.playerInfoBgLayer:runAction(actionSeq)

			costTime = delayTime_ + animationConf.contentBgMoveTime / self.fps + 0.1
		end
		------------ 显示显示玩家奖励 ------------

		------------ 显示返回按钮 ------------
		local backBtnActionSeq = cc.Sequence:create(
			cc.DelayTime:create(costTime),
			cc.Show:create(),
			cc.FadeTo:create(0.2, 255),
			cc.CallFunc:create(function ()
				-- 动画完成 恢复触摸
				self.canTouch = true
			end)
		)
		backBtn:runAction(backBtnActionSeq)

		local otherBtnActionSeq = cc.Sequence:create(
			cc.DelayTime:create(costTime),
			cc.Show:create(),
			cc.FadeTo:create(0.2, 255)
		)
		if GAME_MODULE_OPEN.BATTLE_SKADA then
			skadaBtn:runAction(otherBtnActionSeq:clone())
		end
		------------ 显示返回按钮 ------------
	end

	local HideSelf = function ()

	end

	local layer = {ShowSelf = ShowSelf, HideSelf = HideSelf}
	return layer
end
--[[
初始化玩家稀有掉落界面
--]]
function RaidBattleSuccessView:InitRareRewardLayer()
	local layerSize = cc.size(display.width, display.height)

	local rareRewardData = self:GetPlayerRareRewardByPlayerId(checkint(gameMgr:GetUserInfo().playerId))

	-- 稀有奖励节点
	local rareRewardLayer = display.newLayer(display.cx, display.cy, {size = layerSize, ap = cc.p(0.5, 0.5)})
	self:addChild(rareRewardLayer, 3)
	self.rareRewardLayer = rareRewardLayer

	local goodsLayer = require('common.CommonCardGoodsShareView').new({
		goodsId = checkint(rareRewardData.goodsId),
		confirmCallback = function (sender)
			if not self.canHideShareView then return end
			-- 确认按钮回调 进入下一步界面
			self:ShowNextLayer()

			self.canHideShareView = false
		end
	})
	display.commonUIParams(goodsLayer, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(rareRewardLayer)})
	rareRewardLayer:addChild(goodsLayer)

	------------ 初始化动画状态 ------------
	rareRewardLayer:setVisible(false)
	rareRewardLayer:setOpacity(0)
	------------ 初始化动画状态 ------------

	local ShowSelf = function ()
		local delayTime = 10 / self.fps

		------------ 道具层动画 ------------
		local actionSeq = cc.Sequence:create(
			cc.DelayTime:create(0.5),
			cc.Show:create(),
			cc.FadeTo:create(0.5, 255),
			cc.CallFunc:create(function ()
				self.canHideShareView = true
			end)
		)
		rareRewardLayer:runAction(actionSeq)
		------------ 道具层动画 ------------

		------------ 如果没有翻牌子 手动隐藏立绘 ------------
		if 0 < checkint(self:GetLeftChallengeTimeByPlayerId(gameMgr:GetUserInfo().playerId)) then
			local drawNodeActionSeq = cc.Sequence:create(
				cc.FadeTo:create(delayTime, 0),
				cc.Hide:create()
			)
			self.drawNode:runAction(drawNodeActionSeq)
		end
		------------ 如果没有翻牌子 手动隐藏立绘 ------------		
	end

	local HideSelf = function ()
		self.canTouch = false

		------------ 道具层动画 ------------
		local actionSeq = cc.Sequence:create(
			cc.FadeTo:create(0.5, 0),
			cc.Hide:create()
		)
		rareRewardLayer:runAction(actionSeq)
		------------ 道具层动画 ------------
	end

	local layer = {ShowSelf = ShowSelf, HideSelf = HideSelf}
	return layer
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
翻牌按钮回调
--]]
function RaidBattleSuccessView:DrawCardClickHandler(sender)
	local tag = sender:getTag()
	if nil == self.selectedCardIndex then
		self.selectedCardIndex = tag
	else
		return
	end
	local nodes = self.drawRewardsNodes[tag]
	--[[
	{
		rewardNode = rewardCardLayer,
		rewardBg = rewardBg,
		rewardLight = rewardLight,
		rewardFront = rewardFront,
		rewardBtn = drawRewardsBtn,
		rewardIcon = nil
	}
	--]]
	nodes.rewardLight:setVisible(true)
	self:DoDrawCard(tag, checkint(self.trophyData.rewardIndex), true)
end
--[[
根据翻牌序号 奖励序号 做翻牌动画
@params cardIndex int 翻牌序号
@params rewardIndex int 奖励序号
@params active bool 是否是手动点击
--]]
function RaidBattleSuccessView:DoDrawCard(cardIndex, rewardIndex, active)
	local nodes = self.drawRewardsNodes[cardIndex]
	local towards = nodes.layerTowords
	--[[
	{
		rewardNode = rewardCardLayer,
		rewardBg = rewardBg,
		rewardLight = rewardLight,
		rewardFront = rewardFront,
		rewardBtn = drawRewardsBtn,
		rewardIcon = nil
	}
	--]]
	local actionSeq = cc.Sequence:create(
		cc.CallFunc:create(function ()
			if active then
				PlayAudioClip(AUDIOS.UI.ui_teamwork_reverse.id)
			else
				PlayAudioClip(AUDIOS.UI.ui_teamwork_turn.id)
			end
		end),
		cc.ScaleTo:create(0.25, 0, nodes.rewardNode:getScaleY()),
		cc.CallFunc:create(function ()
			nodes.rewardBg:setVisible(false)
			nodes.rewardFront:setVisible(true)

			-- 创建奖励node
			local rewardData = self.trophyData.rewards[rewardIndex]
			local goodsNode = require('common.GoodNode').new({
				id = checkint(rewardData.goodsId),
				amount = checkint(rewardData.num),
				showAmount = true,
				callBack = function (sender)
					uiMgr:ShowInformationTipsBoard({
						targetNode = self.drawRewardsNodes[cardIndex].rewardIcon, iconId = checkint(rewardData.goodsId), type = 1
					})
				end
			})
			display.commonUIParams(goodsNode, {po = utils.getLocalCenter(nodes.rewardNode)})
			nodes.rewardNode:addChild(goodsNode, 10)

			self.drawRewardsNodes[cardIndex].rewardIcon = goodsNode
		end),
		cc.ScaleTo:create(0.25, -1 * towards, nodes.rewardNode:getScaleY())
	)
	nodes.rewardNode:runAction(actionSeq)
end
--[[
自动翻牌逻辑
--]]
function RaidBattleSuccessView:AutoDrawReward()

	-- 自动翻牌
	local delayTime = 0.1
	if nil == self.selectedCardIndex then
		-- 如果没有手动翻牌 先自动翻一张牌
		local cardIndex = math.random(#self.drawRewardsNodes)
		self.selectedCardIndex = cardIndex

		local nodes = self.drawRewardsNodes[self.selectedCardIndex]
		nodes.rewardLight:setVisible(true)

		self:DoDrawCard(cardIndex, checkint(self.trophyData.rewardIndex))
		delayTime = delayTime + 0.5
	end


	local drawCardActionSeq = cc.Sequence:create(
		cc.DelayTime:create(delayTime),
		cc.CallFunc:create(function ()
			-- 翻掉其他剩余的牌
			local t = {}
			for i,v in ipairs(self.trophyData.rewards) do
				if i ~= self.trophyData.rewardIndex then
					table.insert(t, {rewardIndex = i})
				end
			end

			for i,v in ipairs(self.drawRewardsNodes) do
				if i ~= self.selectedCardIndex then
					local tIndex = math.random(#t)
					local randomRewardIndex = t[tIndex].rewardIndex
					table.remove(t, tIndex)

					self:DoDrawCard(i, randomRewardIndex)
				end
			end
		end),
		cc.DelayTime:create(0.75),
		cc.CallFunc:create(function ()
			-- 翻牌结束 显示点击继续
			local bottomLayer = self:AddDrawRewardsBottomLayer(self.drawRewardsLayer)
			bottomLayer.ShowSelf(0)
		end)
	)
	self:runAction(drawCardActionSeq)
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- data control begin --
---------------------------------------------------
--[[
@override
更新本地数据
--]]
function RaidBattleSuccessView:UpdateLocalData()

	if self.trophyData then
		-- 将玩家奖励插入背包
		local selfPlayerId = checkint(gameMgr:GetUserInfo().playerId)

		local rewards = self:GetPlayerRewardsByPlayerId(selfPlayerId)
		if nil ~= rewards then
			CommonUtils.DrawRewards({rewards})
		end

		local rareRewardData = self:GetPlayerRareRewardByPlayerId(selfPlayerId)
		if nil ~= rareRewardData then
			CommonUtils.DrawRewards({rareRewardData})
		end

		local extraRewardData = self:GetPlayerExtraRewardsByPlayerId(selfPlayerId)
		if nil ~= extraRewardData then
			CommonUtils.DrawRewards(extraRewardData)
		end
	end

end
--[[
根据玩家id 奖励index 奖励集 添加玩家奖励信息
@params playerId int 玩家id
@params rewardIndex int 奖励index
@params rewards 奖励集
@params rareRewards 稀有奖励集
@params extraRewards 其他奖励集
--]]
function RaidBattleSuccessView:AddPlayerRewards(playerId, rewardIndex, rewards, rareRewards, extraRewards)
	self.playerRewardsData[tostring(playerId)] = {
		playerId = playerId,
		rewardIndex = rewardIndex,
		rewards = rewards,
		rareRewards = rareRewards,
		extraRewards = extraRewards
	}

	self:RefreshPlayerRewardInfo(playerId, self:GetPlayerRewardsByPlayerId(playerId))
	self:RefreshPlayerRareRewardInfo(playerId, self:GetPlayerRareRewardByPlayerId(playerId))
	self:RefreshPlayerExtraRewardInfo(playerId, self:GetPlayerExtraRewardsByPlayerId(playerId))
end
--[[
根据玩家id获取获得的奖励信息
@params playerId int 玩家id
@return rewardData table 奖励信息
--]]
function RaidBattleSuccessView:GetPlayerRewardsByPlayerId(playerId)
	local rewardsData = self.playerRewardsData[tostring(playerId)]
	if nil ~= rewardsData and nil ~= rewardsData.rewards then
		return rewardsData.rewards[rewardsData.rewardIndex]
	else
		return nil
	end
end
--[[
获取玩家稀有奖励
@params playerId int 玩家id
@return rareRewardData table 奖励信息
--]]
function RaidBattleSuccessView:GetPlayerRareRewardByPlayerId(playerId)
	local rareRewardData = nil
	local rewardsData = self.playerRewardsData[tostring(playerId)]
	if nil ~= rewardsData then
		if nil ~= rewardsData.rareRewards and 0 < #rewardsData.rareRewards then
			rareRewardData = rewardsData.rareRewards[1]
		end
	end

	return rareRewardData
end
--[[
获取玩家其他奖励
@params playerId int 玩家id
@return extraRewardsData table 奖励信息
--]]
function RaidBattleSuccessView:GetPlayerExtraRewardsByPlayerId(playerId)
	local extraRewardsData = nil
	local rewardsData = self.playerRewardsData[tostring(playerId)]
	if nil ~= rewardsData then
		if nil ~= rewardsData.extraRewards and 0 < #rewardsData.extraRewards then
			extraRewardsData = rewardsData.extraRewards
		end
	end
	return extraRewardsData
end
--[[
根据玩家id 奖励信息刷新奖励节点
@params playerId int 玩家id
@params rewardData table 奖励信息
--]]
function RaidBattleSuccessView:RefreshPlayerRewardInfo(playerId, rewardData)
	local nodes = self.playerRewardsNodes[tostring(playerId)]
	local canShowNormalRewards = self:GetCanShowNormalRewards(playerId)
	if nil ~= rewardData and nil ~= nodes and nil ~= nodes.goodsNode and canShowNormalRewards then
		nodes.goodsNode:RefreshSelf({
			goodsId = checkint(rewardData.goodsId),
			amount = checkint(rewardData.num),
			showAmount = checkint(rewardData.num) > 0
		})
	end
end
--[[
根据玩家id 稀有奖励信息刷新奖励节点
@params playerId int 玩家id
@params rareRewardData table 稀有奖励信息
--]]
function RaidBattleSuccessView:RefreshPlayerRareRewardInfo(playerId, rareRewardData)
	local nodes = self.playerRewardsNodes[tostring(playerId)]
	if nil ~= rareRewardData and nil ~= nodes and nil ~= nodes.rareRewardGoodsNode and nil ~= nodes.rareRewardsLabel then
		nodes.rareRewardsLabel:setVisible(true)
		nodes.rareRewardGoodsNode:setVisible(true)
		nodes.rareRewardGoodsNode:RefreshSelf({
			goodsId = checkint(rareRewardData.goodsId),
			amount = checkint(rareRewardData.num),
			showAmount = checkint(rareRewardData.num) > 0
		})
	end
end
--[[
根据玩家id 其他奖励信息刷新奖励节点
@params playerId int 玩家id
@params extraRewardsData table 其他奖励信息
--]]
function RaidBattleSuccessView:RefreshPlayerExtraRewardInfo(playerId, extraRewardsData)
	local nodes = self.playerRewardsNodes[tostring(playerId)]

	if nil ~= extraRewardsData and nil ~= nodes then
		-- 获取玩家信息
		local playerData = nil
		for k,v in pairs(self.playersData) do
			if playerId == checkint(v.playerId) then
				playerData = v
				break
			end
		end

		local showBaseReward = false
		if nil ~= playerData then
			showBaseReward = 0 < checkint(checkint(self:GetLeftChallengeTimeByPlayerId(playerId)))
		end

		local playerInfoBgSize = nodes.playerInfoBgLayer:getContentSize()

		for extraRewardIndex_, extraRewardData_ in ipairs(extraRewardsData) do
			local extraGoodsNode = require('common.GoodNode').new({
				goodsId = checkint(extraRewardData_.goodsId),
				amount = checkint(extraRewardData_.num),
				showAmount = true,
				callBack = function (sender)
				PlayAudioByClickNormal()
					local extraRewardsData = self:GetPlayerExtraRewardsByPlayerId(checkint(playerId))
					if nil ~= extraRewardsData then
						if nil ~= extraRewardsData[extraRewardIndex_] then
							uiMgr:ShowInformationTipsBoard({
								targetNode = self.playerRewardsNodes[tostring(playerData.playerId)].extraGoodsNodes[extraRewardIndex_],
								iconId = checkint(extraRewardsData[extraRewardIndex_].goodsId),
								type = 1
							})
						end
					end
				end
			})

			local orix = playerInfoBgSize.width - 240
			if showBaseReward then
				-- 如果显示基础奖励 向右移一格
				orix = playerInfoBgSize.width - 240 + (extraGoodsNode:getContentSize().width + 10)
			end
			display.commonUIParams(extraGoodsNode, {po = cc.p(
				orix + (extraRewardIndex_ - 1) * (extraGoodsNode:getContentSize().width + 10),
				playerInfoBgSize.height * 0.5
			)})
			nodes.playerInfoBgLayer:addChild(extraGoodsNode)

			table.insert(nodes.extraGoodsNodes, extraGoodsNode)
		end

		nodes.rewardsLabel:setVisible(0 < #extraRewardsData)
	end
end
--[[
是否可以显示玩家普通奖励
--]]
function RaidBattleSuccessView:SetCanShowNormalRewards(playerId, show)
	self.canShowNormalRewards[tostring(playerId)] = show

	if show then
		self:RefreshPlayerRewardInfo(playerId, self:GetPlayerRewardsByPlayerId(playerId))
	end
end
function RaidBattleSuccessView:GetCanShowNormalRewards(playerId)
	local show = self.canShowNormalRewards[tostring(playerId)]
	if nil == show then
		return false
	else
		return show
	end
end
--[[
根据玩家id获取剩余次数
@params playerId int 玩家id
--]]
function RaidBattleSuccessView:GetLeftChallengeTimeByPlayerId(playerId)
	return checkint(self.leftChallengeTimes[tostring(playerId)])
end
---------------------------------------------------
-- data control end --
---------------------------------------------------

return RaidBattleSuccessView
