--[[
竞技场编辑队伍场景
@params params table {
	teamDatas list 阵容信息 支持多队
	maxTeamAmount int 最大队伍数量
	teamData list 现有阵容
	title string 标题
	tipsText table/string 编队提示文字 
	avatarTowards int 1 朝右 -1 朝左
	teamChangeSingalName string 阵容变化回调信号
	enterBattleSignalName string 进入战斗按钮回调信号 显示战斗按钮
	teamTowards int 队伍朝向 1 朝右 -1 朝左
	battleType int 1 不显示一些pvc专用的ui
	isDisableHomeTopSignal bool  是否禁止隐藏HomeTopLayer 信号
	isOpenRecommendState bool 是否开启卡牌推荐状态
	limitCardsCareers table 限制卡牌职业
	limitCardsQualities table 限制品质 ,
	allCards table 推荐的卡牌
	banList map 禁用列表 {
		career list 职业禁用
		quality list 稀有度禁用
		card list 卡牌禁用
	}
	battleData map 战斗数据 {
		questBattleType QuestBattleType 战斗类型
		settlementType ConfigBattleResultType 结算类型
		rivalTeamData list 敌方阵容 卡牌信息
		serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
		fromtoData BattleMediatorsConnectStruct 跳转信息
	}
	showCardStatus map 是否显示血量蓝量 {
		------------ pattern 1 ------------
		-- 传字段名 自己去读
		hpFieldName string 当前剩余血量的字段
		energyFieldName string 当前剩余能量的字段
		------------ pattern 1 ------------

		------------ pattern 2 ------------
		-- 传信息 直接用
		cardHpData map 血量信息
		cardEnergyData map 能量信息
		------------ pattern 2 ------------
	}
	costGoodsInfo map 刷新卡牌状态的消耗 {
		goodsId int 道具id
		num int 道具数量
	}
	battleButtonSkinType BattleButtonSkinType 战斗按钮的皮肤类型
}
--]]
local GameScene = require( "Frame.GameScene" )
local PVCChangeTeamScene = class("PVCChangeTeamScene", GameScene)

------------ import ------------
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function PVCChangeTeamScene:ctor(...)
	local args = unpack({...})

	GameScene.ctor(self, 'Game.views.pvc.PVCChangeTeamScene')

	self.teamDatas = args.teamDatas
	self.teamData = args.teamData
	self.maxTeamAmount = args.maxTeamAmount or #args.teamDatas or 1

	self.title = args.title or __('编辑队伍')
	self.tipsText = args.tipsText
	self.avatarTowards = args.avatarTowards or 1
	self.teamTowards = args.teamTowards or 1
	self.allCards = args.allCards or {}
	self.teamChangeSingalName = args.teamChangeSingalName
	self.enterBattleSignalName = args.enterBattleSignalName
	self.battleType = args.battleType
	self.isDisableHomeTopSignal = args.isDisableHomeTopSignal == true
	self.isOpenRecommendState = args.isOpenRecommendState
	self.recommendCards = args.recommendCards
	self.limitCardsCareers = args.limitCardsCareers
	self.limitCardsQualities = args.limitCardsQualities
	self.battleData = args.battleData
	self.banList = args.banList
	self.costGoodsInfo = args.costGoodsInfo
	self.battleButtonSkinType = args.battleButtonSkinType
	self.showCardStatus = args.showCardStatus

	-- 注册信号回调
	self:RegisterSignal()
	-- 初始化
	self:InitValue()
	self:InitUI()

	-- 隐藏游戏顶栏
	if not self.isDisableHomeTopSignal then
		AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	end
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化数据
--]]
function PVCChangeTeamScene:InitValue()
	-- 当前的队伍信息
	self.currentTeamIndex = nil
end
--[[
初始化ui
--]]
function PVCChangeTeamScene:InitUI()
	local size = self:getContentSize()
	local selectCardLayersize = cc.size(
		size.width,
		size.height * 0.45
	)

	-- eater layer
	local eaterLayer = display.newLayer(0, 0, {color = cc.c4b(255, 0, 255, 0), size = size, enable = true})
	display.commonUIParams(eaterLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
		size.width * 0.5,
		size.height * 0.5
	)})
	self:addChild(eaterLayer)

	-- 背景图
	local bg = display.newImageView(_res('ui/common/pvp_main_bg.jpg'), size.width/2, size.height/2, {isFull = true})
	self:addChild(bg)
	self.bg = bg

	-- 中间底
	local avatarBottom = display.newImageView(_res('ui/common/pvp_main_bg_vs.png'), 0, 0)
	display.commonUIParams(avatarBottom, {ap = display.CENTER_BOTTOM, po = cc.p(
		size.width * 0.5,
		size.height * 0.5 - 118
	)})
	self:addChild(avatarBottom)
	self.avatarBottom = avatarBottom
	-- 底色遮罩
	local cover = display.newLayer(0, 0, {size = self:getContentSize()})
	display.commonUIParams(cover, {ap = cc.p(0.5, 0.5), po = cc.p(size.width * 0.5, size.height * 0.5)})
	self:addChild(cover)
	cover:setBackgroundColor(cc.c4b(0, 0, 0, 255 * 0.4))

	-- 返回按钮
	local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png"), cb = handler(self, self.BackBtnClickHandler)})
	backBtn:setName('backBtn')
	display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.size.height - 18 - backBtn:getContentSize().height * 0.5)})
	self:addChild(backBtn, 10)

	-- title
	local titleBg = display.newImageView(_res('ui/common/pvp_edit_subtitle.png'), 0, 0)
	display.commonUIParams(titleBg, {po = cc.p(
		size.width * 0.5,
		size.height - titleBg:getContentSize().height * 0.5
	)})
	self:addChild(titleBg, 100)

	local titleLabel = display.newLabel(0, 0, fontWithColor('19', {text = self.title}))
	display.commonUIParams(titleLabel, {po = cc.p(
		utils.getLocalCenter(titleBg).x,
		utils.getLocalCenter(titleBg).y + 23
	)})
	titleBg:addChild(titleLabel)
	-- 战斗力
	local battlePointBg = display.newImageView(_res('ui/common/pvp_edit_bg_gearscore.png'), 0, 0)	
	display.commonUIParams(battlePointBg, {po = cc.p(
		display.SAFE_R - battlePointBg:getContentSize().width * 0.5 + 60,
		size.height - 80
	)})
	self:addChild(battlePointBg, 10)

	local battlePointSpine = sp.SkeletonAnimation:create('effects/fire/skeleton.json', 'effects/fire/skeleton.atlas', 1)
	battlePointSpine:update(0)
	battlePointSpine:setAnimation(0, 'huo', true)
	battlePointSpine:setPosition(cc.p(
		battlePointBg:getPositionX(),
		battlePointBg:getPositionY()
	))
	self:addChild(battlePointSpine, 10)

	local battlePointLabel = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '0')
	battlePointLabel:setAnchorPoint(cc.p(0.5, 0.5))
	battlePointLabel:setHorizontalAlignment(display.TAC)
	battlePointLabel:setPosition(cc.p(
		battlePointSpine:getPositionX(),
		battlePointSpine:getPositionY() + 10
	))
	self:addChild(battlePointLabel, 10)
	battlePointLabel:setScale(0.7)

	self.battlePointLabel = battlePointLabel

	-- 中间队伍spine小人
	local avatarOriPos = cc.p(
		size.width * 0.5 - 310,
		size.height * 0.55
	)
	local avatarLocationInfo = {
		[1] = {fixedPos = cc.p(620, 0)},
		[2] = {fixedPos = cc.p(465, 65)},
		[3] = {fixedPos = cc.p(310, 0)},
		[4] = {fixedPos = cc.p(155, 65)},
		[5] = {fixedPos = cc.p(0, 0)}
	}
	local teamMarkPosSign = 1
	if -1 == self.teamTowards then
		avatarLocationInfo = {
			[1] = {fixedPos = cc.p(0, 0)},
			[2] = {fixedPos = cc.p(155, 65)},
			[3] = {fixedPos = cc.p(310, 0)},
			[4] = {fixedPos = cc.p(465, 65)},
			[5] = {fixedPos = cc.p(620, 0)}
		}
		teamMarkPosSign = -1
	end
	local p = nil
	self.avatarNodes = {}

	for i = 1, MAX_TEAM_MEMBER_AMOUNT do
		local avatarBgPath = 'ui/common/tower_bg_team_base.png'
		p = avatarLocationInfo[i]
		if 1 == i then
			avatarBgPath = 'ui/common/tower_bg_team_base_cap.png'
		end
		local avatarBg = display.newImageView(_res(avatarBgPath),
			avatarOriPos.x + p.fixedPos.x,
			avatarOriPos.y + p.fixedPos.y)
		self:addChild(avatarBg, 20 + i % 2)

		local avatarLight = display.newImageView(_res('ui/common/tower_prepare_bg_light.png'), 0, 0)
		display.commonUIParams(avatarLight, {po = cc.p(
			utils.getLocalCenter(avatarBg).x,
			utils.getLocalCenter(avatarBg).y + avatarLight:getContentSize().height * 0.5
		)})
		avatarBg:addChild(avatarLight, 10)

		-- 透明按钮
		local avatarBtn = display.newButton(0, 0, {size = cc.size(150, 200)})
		display.commonUIParams(avatarBtn, {po = cc.p(
			avatarBg:getPositionX(),
			avatarBg:getPositionY() + avatarBtn:getContentSize().height * 0.5
		), animate = false, cb = handler(self, self.AvatarBtnClickHandler)})
		avatarBg:getParent():addChild(avatarBtn, avatarBg:getLocalZOrder())
		avatarBtn:setTag(i)
		avatarBtn:setVisible(false)

		-- debug --
		-- local l = display.newLayer(avatarBtn:getPositionX(), avatarBtn:getPositionY(), {size = avatarBtn:getContentSize(), ap = avatarBtn:getAnchorPoint()})
		-- l:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 100))
		-- avatarBtn:getParent():addChild(l, avatarBtn:getLocalZOrder())
		-- debug --

		if 1 == i then
			-- 添加队长标记
			local captainMark = display.newNSprite(_res('ui/home/teamformation/team_ico_captain.png'), 0, 0)
			display.commonUIParams(captainMark, {po = cc.p(
				avatarBg:getPositionX() + teamMarkPosSign * (avatarBg:getContentSize().width * 0.5 + 20),
				avatarBg:getPositionY() - 5
			)})
			self:addChild(captainMark, 100)
		end

		self.avatarNodes[i] = {bg = avatarBg, avatarLight = avatarLight, avatarBtn = avatarBtn, avatarSpine = nil, connectSkillNode = nil}
	end

	-- 禁用列表按钮
	local banListBtn = nil
	if self.banList then
		banListBtn = display.newButton(
			0, 0, {n = _res("ui/home/activity/ultimateBattle/duel_choose_btn_no_battle.png") , scale9 = true }
		)
		display.commonLabelParams(banListBtn , {text = __('本期不可出战飨灵'), fontSize = 22, color = '#ffffff' , paddingW = 40 })

		local banListBtnSize = banListBtn:getContentSize()
		display.commonUIParams(banListBtn, {po = cc.p(
			display.SAFE_L + 5 + banListBtnSize.width * 0.5, selectCardLayersize.height + banListBtnSize.height * 0.5
		)})
		banListBtn:setOnClickScriptHandler(handler(self, self.BanListBtnClickHandler))
		self:addChild(banListBtn, 10)
		local arrowIcon = display.newImageView(_res('ui/home/activity/ultimateBattle/duel_choose_img_arrow.png'), banListBtnSize.width - 25, banListBtnSize.height * 0.5)
		banListBtn:addChild(arrowIcon, 1)
	end
	--111
	-- 左侧队伍选择栏
	local teamInfoNodes = {}
	if 1 < self.maxTeamAmount then
		local teamAmountPerCol = 3
		local teamBgNodeScale = 0.8
		local teamMarkScale = 1 / teamBgNodeScale * 0.5
		local teamBgNodeSize = nil
		local teamBgNodeY = backBtn:getPositionY() - 10 - backBtn:getContentSize().height * 0.5
		local teamBgNodeHeight = teamBgNodeY - selectCardLayersize.height

		for i = 1, self.maxTeamAmount do

			-- 按钮背景
			local teamBgNode = display.newImageView(
				_res('ui/battle/battletagmatch/3v3_fighting_head_bg.png'), 0, 0,
				{enable = true, animate = false, cb = handler(self, self.TeamInfoBtnClickHandler)}
			)
			teamBgNode:setScale(teamBgNodeScale)
			if nil == teamBgNodeSize then
				teamBgNodeSize = cc.size(
					teamBgNode:getContentSize().width * teamBgNodeScale, teamBgNode:getContentSize().height * teamBgNodeScale
				)
			end
			display.commonUIParams(teamBgNode, {po = cc.p(
				display.SAFE_L + 20 + (teamBgNodeSize.width + 20) * (math.floor((i - 1) / teamAmountPerCol) + 0.5),
				teamBgNodeY - (teamBgNodeHeight / 3) * ((i - 1) % teamAmountPerCol + 0.5)
			)})
			self:addChild(teamBgNode, 10)
			teamBgNode:setTag(i)

			-- 队伍编号
			local teamMark = display.newSprite(_res(string.format('ui/home/teamformation/team_states_team%d.png', i)), 0, 0)
			display.commonUIParams(teamMark, {po = cc.p(
				teamBgNodeSize.width + 8, teamBgNodeSize.height + 5
			)})
			teamMark:setScale(teamMarkScale)
			teamBgNode:addChild(teamMark, 10)

			-- 选中状态
			local selectedMark = display.newSprite(_res('ui/lunatower/lunatower_ranks_select.png'), 0, 0)
			display.commonUIParams(selectedMark, {po = cc.p(
				teamBgNode:getPositionX(), teamBgNode:getPositionY()
			)})
			self:addChild(selectedMark, 9)
			selectedMark:setVisible(false)

			teamInfoNodes[i] = {teamBgNode = teamBgNode, teamMark = teamMark, selectedMark = selectedMark, cardHeadNode = nil, id = nil}

		end

		if nil ~= banListBtn then
			-- 将不可用按钮移动至返回按钮旁边
			display.commonUIParams(banListBtn, {po = cc.p(
				backBtn:getPositionX() + backBtn:getContentSize().width * 0.5 + 25 + banListBtn:getContentSize().width * 0.5,
				backBtn:getPositionY()
			)})
		end
	end
	self.teamInfoNodes = teamInfoNodes

	-- 刷新界面 初始化时默认创建第一队
	local initTeamIndex = 1
	self:RefreshViewByTeamIndex(initTeamIndex)
	-- 刷新左侧队伍信息的头像
	self:RefreshTeamInfoLeaderHead()

	-- 创建选人层
	if table.nums(self.allCards) == 0  then
		self.allCards = nil
	else
		local allCardsMap = {}
		local allCards = {}
		for index, cardId in pairs(self.allCards) do
			allCardsMap[tostring(cardId)] = cardId
		end
		for k,v in pairs(gameMgr:GetUserInfo().cards) do
			if  allCardsMap[tostring(v.cardId)] then
				allCards[#allCards+1] = v
			end
		end
		self.allCards = allCards
	end

	-- 选卡层
	local selectCardParams = {
		size = selectCardLayersize,
		selectedCards = self.teamDatas,
		maxTeamAmount = self.maxTeamAmount,
		teamChangeSingalName = self.teamChangeSingalName,
		enterBattleSignalName = self.enterBattleSignalName,
		battleType  = self.battleType, -- 战斗的类型
		isOpenRecommendState = self.isOpenRecommendState,
		recommendCards = self.recommendCards,
		limitCardsCareers = self.limitCardsCareers,
		limitCardsQualities = self.limitCardsQualities,
		allCards = self.allCards,
		battleData = self.battleData,
		banList = self.banList,
		battleButtonSkinType = self.battleButtonSkinType,
		showCardStatus = self.showCardStatus,
		isShowTeamIndex = 1 < checkint(self.maxTeamAmount)
	}

	local selectCardClassName = 'common.SelectCardMemberView'
	if nil ~= self.showCardStatus then
		selectCardClassName = 'common.SelectCardMemberViewWithHp'
	end

	local selectCardLayer = require(selectCardClassName).new(selectCardParams)
	display.commonUIParams(selectCardLayer, {ap = cc.p(0.5, 0), po = cc.p(
		size.width * 0.5,
		0
	)})
	self:addChild(selectCardLayer, 10)
	selectCardLayer:SetCurrentTeamIndex(initTeamIndex)

	self.selectCardLayer = selectCardLayer
	self.titleBg = titleBg

	-- tips
	if self.tipsText then
		local textType = type(self.tipsText)
		if textType == 'table' then
			local tipsLabel = display.newRichLabel(size.width * 0.5, selectCardLayer:getPositionY() + selectCardLayer:getContentSize().height + 10, {ap = display.CENTER_BOTTOM, r = true, c = self.tipsText})
			self:addChild(tipsLabel)
			CommonUtils.AddRichLabelTraceEffect(tipsLabel, '#5b3c25', 1)
			self.tipsLabel = tipsLabel
		elseif textType == 'string' then
			local tipsLabel = display.newLabel(size.width * 0.5, selectCardLayer:getPositionY() + selectCardLayer:getContentSize().height + 10, 
				fontWithColor(14, {color = '#ffe8a2', outline = '#5b3c25', outlineSize = 1, ap = display.CENTER_BOTTOM, text = self.tipsText}))
			self:addChild(tipsLabel)
			self.tipsLabel = tipsLabel
		end
	end

	-- 创建消耗按钮
	if nil ~= self.costGoodsInfo then
		-- 消耗按钮
		local costBtn = display.newButton(0, 0, {
			n = _res('ui/common/common_btn_green.png'),
			cb = handler(self, self.ResetAllCardsStatusClickHandler)
		})
		display.commonUIParams(costBtn, {po = cc.p(
			display.SAFE_R - costBtn:getContentSize().width * 0.5 - 25,
			selectCardLayersize.height + costBtn:getContentSize().height * 0.5 + 35
		)})
		display.commonLabelParams(costBtn, fontWithColor('14', {text = __('一键满血')}))
		self:addChild(costBtn, 10)

		-- 消耗信息
		local costLabel = display.newLabel(
			0, 0, fontWithColor('18', {text = string.format(__('消耗%d'), self.costGoodsInfo.num)})
		)
		self:addChild(costLabel, 10)

		local costIcon = display.newSprite(_res(CommonUtils.GetGoodsIconPathById(self.costGoodsInfo.goodsId)), 0, 0)
		self:addChild(costIcon, 10)
		costIcon:setScale(0.2)

		display.setNodesToNodeOnCenter(costBtn, {costLabel, costIcon}, {y = -20})
	end
	-- debug --
	-- local testLayer = display.newLayer(0, 0, {size = cc.size(
	-- 	size.width,
	-- 	avatarBottom:getPositionY() - avatarBottom:getContentSize().height * 0.5)})
	-- testLayer:setBackgroundColor(cc.c4b(128, 128, 255, 100))
	-- display.commonUIParams(testLayer, {ap = cc.p(0.5, 0.5), po = cc.p(size.width * 0.5, testLayer:getContentSize().height * 0.5)})
	-- self:addChild(testLayer, 999)
	-- debug --

	-- 刷新一些其他ui的版式
	self:RefreshUIByBattleScriptType()
end
--[[
根据相应的type 刷新UI
--]]
function PVCChangeTeamScene:RefreshUIByBattleScriptType()
	if self.battleType == BATTLE_SCRIPT_TYPE.MATERIAL_TYPE then
		self.titleBg:setVisible(false)
		self.bg:setTexture(_res('ui/home/materialScript/material_bg')) -- 设置背景颜色
		self.avatarBottom:setVisible(false)
		local x, y  =  self.selectCardLayer:getPosition()
	end
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
根据队伍序号刷新界面
@params teamIndex int 队伍的序号
--]]
function PVCChangeTeamScene:RefreshViewByTeamIndex(teamIndex)
	if teamIndex == self.currentTeamIndex then return end

	------------ 刷新左侧队伍标志 ------------
	-- 选择的队伍
	self:RefreshSelectedTeam(teamIndex)
	------------ 刷新左侧队伍标志 ------------

	------------ 刷新所有的spine小人 ------------
	-- spine小人
	self:RefreshAllAvatarSpine(teamIndex)
	------------ 刷新所有的spine小人 ------------
end
--[[
刷新选择的队伍
@params teamIndex int 队伍序号
--]]
function PVCChangeTeamScene:RefreshSelectedTeam(teamIndex)
	if teamIndex == self.currentTeamIndex then return end

	if nil ~= self.currentTeamIndex then
		local preTeamInfoNodes = self.teamInfoNodes[self.currentTeamIndex]
		if nil ~= preTeamInfoNodes then
			preTeamInfoNodes.selectedMark:setVisible(false)
		end
	end

	if nil ~= teamIndex then
		local curTeamInfoNodes = self.teamInfoNodes[teamIndex]
		if nil ~= curTeamInfoNodes then
			curTeamInfoNodes.selectedMark:setVisible(true)
		end
	end

	self.currentTeamIndex = teamIndex
	if nil ~= self.selectCardLayer then
		self.selectCardLayer:SetCurrentTeamIndex(self.currentTeamIndex)
	end
end
--[[
刷新左侧队伍的头像
--]]
function PVCChangeTeamScene:RefreshTeamInfoLeaderHead()
	for i = 1, self.maxTeamAmount do
		self:RefreshTeamInfoLeaderHeadByTeamIndex(i)
	end
end
--[[
根据队伍序号刷新左侧队长头像 1号位没人的时候往后取第一个
@params teamIndex int 队伍序号
--]]
function PVCChangeTeamScene:RefreshTeamInfoLeaderHeadByTeamIndex(teamIndex)
	if 1 >= self.maxTeamAmount then return end

	local nodes = self.teamInfoNodes[teamIndex]
	--[[
	{
		{teamBgNode = teamBgNode, teamMark = teamMark, selectedMark = selectedMark, cardHeadNode = nil, id = nil},
		{teamBgNode = teamBgNode, teamMark = teamMark, selectedMark = selectedMark, cardHeadNode = nil, id = nil},
		{teamBgNode = teamBgNode, teamMark = teamMark, selectedMark = selectedMark, cardHeadNode = nil, id = nil},
		...
	}
	--]]
	if nil ~= nodes then

		local leaderId = self:GetFirstMemberByTeamIndex(teamIndex)

		if nil == leaderId then
			-- 没人 隐藏老的头像
			if nil ~= nodes.cardHeadNode then
				nodes.cardHeadNode:setVisible(false)
				-- 置空之前的id
				self.teamInfoNodes[teamIndex].id = nil
			end
		else

			-- 有人创建刷新
			if nil == nodes.cardHeadNode then
				-- 创建
				local cardHeadNode = require('common.CardHeadNode').new({
					id = leaderId,
					showBaseState = true,
					showActionState = false,
					showVigourState = false
				})
				display.commonUIParams(cardHeadNode, {po = utils.getLocalCenter(nodes.teamBgNode)})
				nodes.teamBgNode:addChild(cardHeadNode, 5)
				cardHeadNode:setScale(0.5)

				self.teamInfoNodes[teamIndex].cardHeadNode = cardHeadNode
			else
				-- 刷新
				if nodes.id ~= leaderId then
					nodes.cardHeadNode:setVisible(true)
					-- 如果是同一张卡就不刷新了
					nodes.cardHeadNode:RefreshUI({
						id = leaderId,
						showBaseState = true,
						showActionState = false,
						showVigourState = false
					})
				end
			end

			-- 刷新一次id
			self.teamInfoNodes[teamIndex].id = leaderId

		end

	end
end
--[[
根据队伍序号刷新所有的spine小人
@params teamIndex int 队伍序号
--]]
function PVCChangeTeamScene:RefreshAllAvatarSpine(teamIndex)
	-- 先移除所有老的spine节点
	for teamIdx, nodes in pairs(self.avatarNodes) do
		self:RemoveAvatarNodeByTeamIdx(teamIdx, false)
	end

	local teamData = self:GetTeamDataByTeamIndex(teamIndex)
	if nil == teamData then return end

	-- 创建spine小人
	for i,v in ipairs(teamData) do
		if nil ~= v.id and 0 ~= checkint(v.id) then
			local cardData = gameMgr:GetCardDataById(v.id)
			if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
				local skinId = nil
				if nil == cardData.defaultSkinId then
					skinId = CardUtils.GetCardSkinId(checkint(cardData.cardId))
				else
					skinId = checkint(cardData.defaultSkinId)
				end

				self:RefreshAvatarSpine(i, skinId)
				self:RefreshConnectSkillNode(i, checkint(cardData.cardId))
			end
		end
	end
	-- 刷新一次连携技按钮
	self:RefreshAllConnectSkillState()
end
--[[
根据序号 卡牌皮肤 刷新卡牌spine小人
@params teamIdx int 编队序号
@params skinId int 皮肤id
--]]
function PVCChangeTeamScene:RefreshAvatarSpine(teamIdx, skinId)
	local nodes = self.avatarNodes[teamIdx]
	if nil ~= nodes.avatarSpine then
		nodes.avatarSpine:removeFromParent()
		self.avatarNodes[teamIdx].avatarSpine = nil
	end

	if nil ~= nodes.avatarLight then
		nodes.avatarLight:setVisible(false)
	end
	if nil ~= nodes.avatarBtn then
		nodes.avatarBtn:setVisible(true)
	end

	------------ 卡牌spine小人 ------------
	local avatarSpine = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.5})
	avatarSpine:update(0)
	avatarSpine:setScaleX(self.avatarTowards)
	avatarSpine:setAnimation(0, 'idle', true)
	avatarSpine:setPosition(cc.p(
		nodes.bg:getContentSize().width * 0.5,
		nodes.bg:getContentSize().height * 0.5 + 5
	))
	nodes.bg:addChild(avatarSpine, 5)

	self.avatarNodes[teamIdx].avatarSpine = avatarSpine
	------------ 卡牌spine小人 ------------
end
--[[
根据序号 卡牌id 刷新卡牌连携技按钮
@params teamIdx int 编队序号
@params cardId int 卡牌id
--]]
function PVCChangeTeamScene:RefreshConnectSkillNode(teamIdx, cardId)
	local nodes = self.avatarNodes[teamIdx]

	if nil ~= nodes.connectSkillNode then
		nodes.connectSkillNode:removeFromParent()
		self.avatarNodes[teamIdx].connectSkillNode = nil
	end

	------------ 卡牌连携技按钮 ------------
	local connectSkillId = CardUtils.GetCardConnectSkillId(cardId)
	if nil ~= connectSkillId then
		local skillNode = self:GetAConnectSkillNodeBySkillId(connectSkillId)
		display.commonUIParams(skillNode, {po = cc.p(
			nodes.bg:getContentSize().width * 0.5,
			nodes.bg:getContentSize().height * 0.5 + 5
		)})
		nodes.bg:addChild(skillNode, 10)

		self.avatarNodes[teamIdx].connectSkillNode = skillNode
	end
	------------ 卡牌连携技按钮 ------------
end
--[[
刷新一次所有连携技状态
--]]
function PVCChangeTeamScene:RefreshAllConnectSkillState()
	local teamData = self:GetCurrentTeamData()
	if nil == teamData then return end

	local battlePoint = 0
	for i,v in ipairs(teamData) do
		if v.id then
			local cardData = gameMgr:GetCardDataById(v.id)
			if cardData then
				-- 连携技状态
				self:RefreshConnectSkillNodeState(i, checkint(cardData.cardId))

				-- 计算一次战斗力
				battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointById(v.id)
			end
		end
	end

	-- 设置战斗力标签
	self.battlePointLabel:setString(tostring(battlePoint))
end
--[[
刷新连携技状态
@params teamIdx int 队伍序号
@params cardId int 卡牌id
--]]
function PVCChangeTeamScene:RefreshConnectSkillNodeState(teamIdx, cardId)
	local nodes = self.avatarNodes[teamIdx]
	if nil ~= nodes.connectSkillNode then
		local skillEnable = app.cardMgr.IsConnectSkillEnable(cardId, self:GetCurrentTeamData() or {})
		if skillEnable then
			nodes.connectSkillNode:getChildByTag(3):setColor(cc.c4b(255, 255, 255, 255))
		else
			nodes.connectSkillNode:getChildByTag(3):setColor(cc.c4b(100, 100, 100, 100))
		end
	end
end
--[[
装备一张卡
@params teamIndex int 操作的队伍序号
@params teamIdx int 队伍序号
@params id int 卡牌数据库id
--]]
function PVCChangeTeamScene:EquipACard(teamIndex, teamIdx, id)
	local cardData = gameMgr:GetCardDataById(id)
	------------ data ------------
	self:UpdateTeamData(teamIndex, teamIdx, id)
	------------ data ------------

	------------ view ------------
	-- 刷新中间spine小人
	local skinId = checkint(cardData.defaultSkinId or CardUtils.GetCardSkinId(checkint(cardData.cardId)))
	self:RefreshAvatarSpine(teamIdx, skinId)
	self:RefreshConnectSkillNode(teamIdx, checkint(cardData.cardId))

	-- 刷新一次连携技按钮状态
	self:RefreshAllConnectSkillState()

	-- 刷新左侧队伍leader
	self:RefreshTeamInfoLeaderHeadByTeamIndex(teamIndex)
	------------ view ------------
end
--[[
卸下一张卡
@params teamIndex int 操作的队伍序号
@params teamIdx int 队伍序号
--]]
function PVCChangeTeamScene:UnequipACard(teamIndex, teamIdx)
	------------ data ------------
	self:UpdateTeamData(teamIndex, teamIdx)
	------------ data ------------

	------------ view ------------
	if teamIndex == self.currentTeamIndex then
		-- 刷新spine相关节点
		self:RemoveAvatarNodeByTeamIdx(teamIdx, true)
	end

	-- 刷新左侧队伍leader
	self:RefreshTeamInfoLeaderHeadByTeamIndex(teamIndex)
	------------ view ------------
end
--[[
清空所有选择卡牌
@params teamIndex int 操作的队伍序号
--]]
function PVCChangeTeamScene:ClearAllCards(teamIndex)
	local teamData = self:GetTeamDataByTeamIndex(teamIndex)
	if nil == teamData then return end

	for i,v in ipairs(teamData) do
		------------ data ------------
		self:UpdateTeamData(teamIndex, i)
		------------ data ------------

		------------ view ------------
		local nodes = self.avatarNodes[i]
		if nil ~= nodes.avatarSpine then
			nodes.avatarSpine:removeFromParent()
			self.avatarNodes[i].avatarSpine = nil
		end
		if nil ~= nodes.connectSkillNode then
			nodes.connectSkillNode:removeFromParent()
			self.avatarNodes[i].connectSkillNode = nil
		end
		if nil ~= nodes.avatarLight then
			nodes.avatarLight:setVisible(true)
		end
		if nil ~= nodes.avatarBtn then
			nodes.avatarBtn:setVisible(false)
		end
		------------ view ------------
	end

	-- 刷新一次连携技按钮状态
	self:RefreshAllConnectSkillState()

	-- 刷新左侧队伍leader
	self:RefreshTeamInfoLeaderHeadByTeamIndex(teamIndex)
end
--[[
根据技能id获取一个连携技图标
@params skillId int 技能id
--]]
function PVCChangeTeamScene:GetAConnectSkillNodeBySkillId(skillId)
	local node = display.newImageView(_res('ui/home/teamformation/team_ico_skill_circle.png'), 0, 0)

	local skillIcon = display.newImageView(_res(CommonUtils.GetSkillIconPath(skillId)), 0, 0)
	skillIcon:setScale((node:getContentSize().width - 10) / skillIcon:getContentSize().width)
	display.commonUIParams(skillIcon, {po = utils.getLocalCenter(node)})
	skillIcon:setTag(3)
	node:addChild(skillIcon, -1)

	skillIcon:setColor(cc.c4b(100, 100, 100, 100))

	return node
end
--[[
根据队伍中的序号移除对应的各种节点
@params teamIdx int 队伍中的序号
@params refreshConnect bool 是否刷新连携技按钮状态
--]]
function PVCChangeTeamScene:RemoveAvatarNodeByTeamIdx(teamIdx, refreshConnect)
	local nodes = self.avatarNodes[teamIdx]

	-- spine节点
	if nil ~= nodes.avatarSpine then
		nodes.avatarSpine:stopAllActions()
		nodes.avatarSpine:setVisible(false)
		nodes.avatarSpine:removeFromParent()
		self.avatarNodes[teamIdx].avatarSpine = nil
	end

	-- 连携技节点
	if nil ~= nodes.connectSkillNode then
		nodes.connectSkillNode:removeFromParent()
		self.avatarNodes[teamIdx].connectSkillNode = nil
	end

	-- spine小人背光
	if nil ~= nodes.avatarLight then
		nodes.avatarLight:setVisible(true)
	end

	-- spine小人按钮
	if nil ~= nodes.avatarBtn then
		nodes.avatarBtn:setVisible(false)
	end

	if true == refreshConnect then
		-- 刷新一次连携技按钮状态
		self:RefreshAllConnectSkillState()
	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
返回按钮回调
--]]
function PVCChangeTeamScene:BackBtnClickHandler(sender)
	if self.battleData then -- 直接关闭页面，不需要弹提示了
		AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')
		return
	end
	-- 弹提示
	local commonTip = require('common.NewCommonTip').new({
		text = __('返回将无法保存编队 是否继续?'),
		callback = function ()
			-- self:runAction(cc.RemoveSelf:create())
			AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')
		end
	})
	commonTip:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(commonTip)
end
--[[
小人按钮回调
--]]
function PVCChangeTeamScene:AvatarBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local index = sender:getTag()
	self:UnequipACard(self.currentTeamIndex, index)
	self.selectCardLayer:UnequipACardByTeamIndex(self.currentTeamIndex, index)
end
--[[
禁用列表按钮点击回调
--]]
function PVCChangeTeamScene:BanListBtnClickHandler( sender )
	PlayAudioByClickNormal()
	app.uiMgr:AddDialog('common.CommonBanListView', {banList = self.banList or {}})
end
--[[
左侧队伍leader按钮回调
--]]
function PVCChangeTeamScene:TeamInfoBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local teamIndex = sender:getTag()
	-- 刷新整个界面
	self:RefreshViewByTeamIndex(teamIndex)
end
--[[
注册信号回调
--]]
function PVCChangeTeamScene:RegisterSignal()

	------------ 卸下一张卡 ------------
	AppFacade.GetInstance():RegistObserver('UNEQUIP_A_CARD', mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		self:UnequipACard(checkint(data.teamIndex), checkint(data.position))
	end, self))
	------------ 卸下一张卡 ------------

	------------ 装备一张卡 ------------
	AppFacade.GetInstance():RegistObserver('EQUIP_A_CARD', mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		self:EquipACard(self.currentTeamIndex, checkint(data.position), checkint(data.id))
	end, self))
	------------ 装备一张卡 ------------

	------------ 清空所有卡牌 ------------
	AppFacade.GetInstance():RegistObserver('CLEAR_ALL_CARDS', mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		self:ClearAllCards(self.currentTeamIndex)
	end, self))
	------------ 清空所有卡牌 ------------

	------------ 关闭本界面 ------------
	AppFacade.GetInstance():RegistObserver('CLOSE_CHANGE_TEAM_SCENE', mvc.Observer.new(function (_, signal)
		self:setVisible(false)
		self:runAction(cc.RemoveSelf:create())
	end, self))
	------------ 关闭本界面 ------------
end
--[[
注销信号
--]]
function PVCChangeTeamScene:UnRegistSignal()
	AppFacade.GetInstance():UnRegistObserver('UNEQUIP_A_CARD', self)
	AppFacade.GetInstance():UnRegistObserver('EQUIP_A_CARD', self)
	AppFacade.GetInstance():UnRegistObserver('CLEAR_ALL_CARDS', self)
	AppFacade.GetInstance():UnRegistObserver('CLOSE_CHANGE_TEAM_SCENE', self)
end
--[[
重置所有卡牌状态按钮回调
--]]
function PVCChangeTeamScene:ResetAllCardsStatusClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('COMMON_RESET_ALL_CARDS_STATUS', {resetHp = true, resetEnergy = true})
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据站位序号刷新队伍信息
@params teamIndex int 队伍的序号
@params teamIdx int 站位序号
@params id int 卡牌数据库id
--]]
function PVCChangeTeamScene:UpdateTeamData(teamIndex, teamIdx, id)
	-- id为nil时置空
	if nil == self.teamDatas[teamIndex] then
		self.teamDatas[teamIndex] = {}
	end

	self.teamDatas[teamIndex][teamIdx] = {id = id}
end
--[[
获取当前的队伍信息
@return _ list 队伍信息
--]]
function PVCChangeTeamScene:GetCurrentTeamData()
	return self:GetTeamDataByTeamIndex(self.currentTeamIndex)
end
--[[
获取根据队伍序号获取队伍信息
@params teamIndex int 队伍序号
@return _ list 队伍信息
--]]
function PVCChangeTeamScene:GetTeamDataByTeamIndex(teamIndex)
	return self.teamDatas[teamIndex]
end
--[[
根据队伍序号获取该队第一个卡牌的id
--]]
function PVCChangeTeamScene:GetFirstMemberByTeamIndex(teamIndex)
	local teamData = self:GetTeamDataByTeamIndex(teamIndex)
	if nil ~= teamData then
		local data = nil
		for i = 1, MAX_TEAM_MEMBER_AMOUNT do
			data = teamData[i]
			if nil ~= data and nil ~= data.id and 0 ~= checkint(data.id) then
				return checkint(data.id)
			end
		end
	end
	return nil
end
---------------------------------------------------
-- get set end --
---------------------------------------------------
function PVCChangeTeamScene:onCleanup()
	-- 注销信号
	self:UnRegistSignal()
end

return PVCChangeTeamScene
