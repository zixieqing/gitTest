--[[
竞技场更换对手弹窗
@params table {
	maxMatchFreeTimes int 最大剩余的免费刷新次数
	matchFreeTimes int 剩余的免费刷新次数
	rivalsInfo list 备选对手信息
}
--]]
local CommonDialog = require('common.CommonDialog')
local PVCSelectRivalView = class('PVCSelectRivalView', CommonDialog)

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
------------ import ------------

------------ define ------------

------------ define ------------

--[[
override
initui
--]]
function PVCSelectRivalView:InitialUI()

	self.maxMatchFreeTimes = self.args.maxMatchFreeTimes
	self.matchFreeTimes = self.args.matchFreeTimes
	self.rivalsInfo = self.args.rivalsInfo

	local function CreateView()
		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_5.png'), 0, 0)
		local size = bg:getContentSize()

		-- base view
		local view = display.newLayer(0, 0, {size = size, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		view:addChild(bg, 1)

		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
		display.commonUIParams(titleBg, {po = cc.p(size.width * 0.5, size.height - titleBg:getContentSize().height * 0.5)})
		display.commonLabelParams(titleBg, fontWithColor('14', {text = __('选择对手'), offset = cc.p(0, -2)}))
        titleBg:setEnabled(false)
		bg:addChild(titleBg)

		-- grid view
		local gridViewSize = cc.size(1058, 450)
		local row = 2
		local col = 2
		local cellSize = cc.size(gridViewSize.width / col, gridViewSize.height / row)

		local gridViewBg = display.newImageView(_res('ui/common/common_bg_goods'), {scale9 = true, size = gridViewSize})
		display.commonUIParams(gridViewBg, {po = cc.p(
			size.width * 0.5,
			size.height * 0.5 + 15
		)})
		view:addChild(gridViewBg, 5)

		local gridView = CGridView:create(gridViewSize)
		gridView:setAnchorPoint(cc.p(0.5, 0.5))
		gridView:setPosition(cc.p(
			gridViewBg:getPositionX(),
			gridViewBg:getPositionY()
		))
		view:addChild(gridView, 10)

		gridView:setCountOfCell(#self.rivalsInfo)
		gridView:setColumns(col)
		gridView:setSizeOfCell(cellSize)
		gridView:setAutoRelocate(false)
		gridView:setBounceable(false)
		gridView:setDataSourceAdapterScriptHandler(handler(self, self.RivalInfoGridViewDataAdapter))

		-- shuffle
		local shuffleBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
		display.commonUIParams(shuffleBtn, {po = cc.p(
			size.width * 0.5,
			60
		), cb = handler(self, self.ShuffleClickHandler)})
		view:addChild(shuffleBtn, 5)

		local shuffleBtnLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('换一批')}))
		display.commonUIParams(shuffleBtnLabel, {po = cc.p(
			shuffleBtn:getContentSize().width * 0.5,
			shuffleBtn:getContentSize().height * 0.5 + 10
		)})
		shuffleBtn:addChild(shuffleBtnLabel)

		local shuffleCostConfig = {
			goodsId = DIAMOND_ID,
			amount = 5
		}
		local shuffleCostIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(shuffleCostConfig.goodsId)), 0, 0)
		shuffleCostIcon:setScale(0.15)
		shuffleBtn:addChild(shuffleCostIcon)

		local shuffleCostAmountLabel = display.newLabel(0, 0, fontWithColor('9', {text = tostring(shuffleCostConfig.amount)}))
		shuffleBtn:addChild(shuffleCostAmountLabel)

		display.setNodesToNodeOnCenter(shuffleBtn, {shuffleCostAmountLabel, shuffleCostIcon}, {y = 18})

		local freeShuffleTimesLabel = display.newLabel(0, 0, fontWithColor('9', {text = ''}))
		display.commonUIParams(freeShuffleTimesLabel, {po = cc.p(
			shuffleBtnLabel:getPositionX(),
			18
		)})
		shuffleBtn:addChild(freeShuffleTimesLabel)

		-- free shuffle tips
		local listSize=cc.size( 440 ,80)
		local listView = CListView:create(listSize)
		listView:setBounceable(true)
		listView:setDirection(eScrollViewDirectionVertical)
		listView:setPosition(cc.p(
				shuffleBtn:getPositionX() + shuffleBtn:getContentSize().width * 0.5 + 10,
				shuffleBtn:getPositionY()
		))
		listView:setAnchorPoint(display.LEFT_CENTER)

		local freeShuffleTipsLabel = display.newLabel(0, 0, fontWithColor('15', {text = __('每次次数刷新后 会有两次免费换一批次数'), w = 440, h = 100}))
		display.commonUIParams(freeShuffleTipsLabel, {ap = cc.p(0.5, 0.5), po = cc.p(
			shuffleBtn:getPositionX() + shuffleBtn:getContentSize().width * 0.5 + 10,
			shuffleBtn:getPositionY()
		)})
		local freeShuffleTipsLabelSize  = display.getLabelContentSize(freeShuffleTipsLabel)
		local layout  = display.newLayer(0,0,{size =freeShuffleTipsLabelSize })
		layout:addChild(freeShuffleTipsLabel)
		freeShuffleTipsLabel:setPosition(cc.p(freeShuffleTipsLabelSize.width/2, freeShuffleTipsLabelSize.height/2))
		listView:insertNodeAtLast(layout)
		listView:reloadData()
		view:addChild(listView, 5)

		return {
			view = view,
			gridView = gridView,
			gridViewCellNodes = {},
			shuffleBtnLabel = shuffleBtnLabel,
			shuffleCostIcon = shuffleCostIcon,
			shuffleCostAmountLabel = shuffleCostAmountLabel,
			freeShuffleTimesLabel = freeShuffleTimesLabel,
			freeShuffleTipsLabel = freeShuffleTipsLabel
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	self:RefreshShuffleInfo(self.matchFreeTimes, self.maxMatchFreeTimes)
	self.viewData.gridView:reloadData()

end
--[[
根据对手信息初始化一个grid view cell
@params rivalInfo table 对手信息
@params index int 序号
--]]
function PVCSelectRivalView:GetARivalInfoCell(rivalInfo, index)
	local cellSize = self.viewData.gridView:getSizeOfCell()
	local cell = CGridViewCell:new()
	cell:setContentSize(cellSize)

	local cellBtn = display.newButton(cellSize.width * 0.5, cellSize.height * 0.5, {size = cellSize,
		animate = false, cb = handler(self, self.SelectRivalClickHandler)})
	cell:addChild(cellBtn)

	-- 背景图
	local bg = display.newImageView(_res('ui/pvc/pvp_select_bg_enemy.png'), 0, 0)
	display.commonUIParams(bg, {po = cc.p(
		cellSize.width * 0.5,
		cellSize.height * 0.5
	)})
	cell:addChild(bg)

	local bgSize = bg:getContentSize()

	local playerInfoSplitLine = display.newImageView(_res('ui/pvc/pvp_select_bg_line4.png'), 0, 0)
	display.commonUIParams(playerInfoSplitLine, {po = cc.p(
		bgSize.width * 0.5,
		143
	)})
	bg:addChild(playerInfoSplitLine)

	-- 玩家信息
	local playerHeadNodeScale = 0.425
	local playerHeadNode = require('common.PlayerHeadNode').new({
		avatar = rivalInfo.avatar,
		avatarFrame = rivalInfo.avatarFrame,
		showLevel = false
	})
	playerHeadNode:setScale(playerHeadNodeScale)
	display.commonUIParams(playerHeadNode, {po = cc.p(
		15 + playerHeadNode:getContentSize().width * 0.5 * playerHeadNodeScale,
		playerInfoSplitLine:getPositionY() + playerHeadNode:getContentSize().height * 0.5 * playerHeadNodeScale
	)})
	bg:addChild(playerHeadNode)

	local playerNameLabel = display.newLabel(0, 0, {text = tostring(rivalInfo.name), fontSize = 22, color = '#6c4a31'})
	display.commonUIParams(playerNameLabel, {ap = cc.p(0, 0), po = cc.p(
		playerHeadNode:getPositionX() + playerHeadNode:getContentSize().width * 0.5 * playerHeadNodeScale + 5,
		playerHeadNode:getPositionY() - 3
	)})
	bg:addChild(playerNameLabel)

	local playerLevelLabel = display.newLabel(0, 0, {text = string.format(__('等级: %s'), tostring(rivalInfo.level)), fontSize = 20, color = '#c68656'})
	display.commonUIParams(playerLevelLabel, {ap = cc.p(0, 1), po = cc.p(
		playerNameLabel:getPositionX(),
		playerNameLabel:getPositionY() - 2
	)})
	bg:addChild(playerLevelLabel)

	-- 阵容
	local teamNodes = {}
	local cardCellSize = cc.size(84, 84)
	local itor = 0
	local battlePoint = 0
	for i,v in ipairs(rivalInfo.defenseTeam) do
		if nil ~= v.cardId and 0 ~= checkint(v.cardId) then
			itor = itor + 1
			local cardHeadNode = require('common.CardHeadNode').new({
				cardData = {
					cardId = v.cardId,
					level = v.level,
					breakLevel = v.breakLevel,
					skinId = v.defaultSkinId,
					favorabilityLevel = v.favorabilityLevel,
				},
				showBaseState = true, showActionState = false, showVigourState = false
			})
			cardHeadNode:setScale(cardCellSize.width / cardHeadNode:getContentSize().width)
			display.commonUIParams(cardHeadNode, {po = cc.p(
				bgSize.width * 0.5 - 220 + (itor - 0.5) * (cardCellSize.width),
				bgSize.height * 0.5 - 7
			)})
			bg:addChild(cardHeadNode)

			-- 计算战斗力
			battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointByCardData(v)

			table.insert(teamNodes, {cardHeadNode = cardHeadNode})
		end
	end

	-- 战斗力标签
	local battlePointLabel = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', tostring(battlePoint))
	battlePointLabel:setAnchorPoint(cc.p(0, 0.5))
	battlePointLabel:setHorizontalAlignment(display.TAC)
	battlePointLabel:setPosition(cc.p(
		bg:getContentSize().width - 140,
		playerInfoSplitLine:getPositionY() + 15
	))
	bg:addChild(battlePointLabel)
	battlePointLabel:setScale(0.7)

	local battlePointNameLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('总灵力:')}))
	display.commonUIParams(battlePointNameLabel, {ap = cc.p(1, 0.5), po = cc.p(
		battlePointLabel:getPositionX() -0,
		battlePointLabel:getPositionY() + 5
	)})
	bg:addChild(battlePointNameLabel)

	-- 获胜奖励
	local rewardNodes = {}
	local rewardsLabel = display.newLabel(0, 0, {text = __('获胜可得'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(rewardsLabel, {ap = cc.p(1, 0.5), po = cc.p(
		bgSize.width * 0.55,
		30
	)})
	bg:addChild(rewardsLabel)

	local rewardsInfo = {
		{goodsId = PVC_POINT_ID, amount = checkint(rivalInfo.winIntegral)},
		{goodsId = PVC_MEDAL_ID, amount = checkint(rivalInfo.winMedal)},
	}
	local goodsIconScale = 0.2

	for i,v in ipairs(rewardsInfo) do
		local goodsIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(v.goodsId)))
		goodsIcon:setScale(goodsIconScale)
		display.commonUIParams(goodsIcon, {po = cc.p(
			bgSize.width - 30 - (i - 1) * 100,
			30
		)})
		bg:addChild(goodsIcon)

		local goodsAmountLabel = display.newLabel(0, 0, fontWithColor('14', {text = tostring(v.amount)}))
		display.commonUIParams(goodsAmountLabel, {ap = cc.p(1, 0.5), po = cc.p(
			bgSize.width - 50 - (i - 1) * 100,
			goodsIcon:getPositionY()
		)})
		bg:addChild(goodsAmountLabel)

		table.insert(rewardNodes, {goodsIcon = goodsIcon, goodsAmountLabel = goodsAmountLabel})
	end

	local nodes = {
		bg = bg,
		playerHeadNode = playerHeadNode,
		playerNameLabel = playerNameLabel,
		playerLevelLabel = playerLevelLabel,
		battlePointLabel = battlePointLabel,
		battlePointNameLabel = battlePointNameLabel,
		teamNodes = teamNodes,
		rewardNodes = rewardNodes
	}
	self.viewData.gridViewCellNodes[tostring(index)] = nodes

	return cell
end
---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
gridview data adapter
--]]
function PVCSelectRivalView:RivalInfoGridViewDataAdapter(c, i)
	local index = i + 1
	local cell = c
	local rivalInfo = self.rivalsInfo[index]

	xTry(function()
		if nil == cell then
			cell = self:GetARivalInfoCell(rivalInfo, index)
		else
			-- 刷新一次保存的各个节点信息
			local nodes = self.viewData.gridViewCellNodes[tostring(cell:getTag())]
			self.viewData.gridViewCellNodes[tostring(cell:getTag())] = nil
			self.viewData.gridViewCellNodes[tostring(index)] = nodes

			self:RefreshRivalInfoCell(cell, index, rivalInfo)
		end
	end, function()
		__G__TRACKBACK__(debug.traceback())
		if nil == cell then
			cell = CGridViewCell:new()
			cell:setContentSize(self.viewData.gridView:getSizeOfCell())
			cell:setBackgroundColor(cc.c4b(0, 0, 0, 255))
		end
	end)

	cell:setTag(index)

	return cell
end
--[[
根据对手信息刷新cell
@params cell cc.Node 待刷新node
@params index cell 序号
@params rivalInfo table 对手信息
--]]
function PVCSelectRivalView:RefreshRivalInfoCell(cell, index, rivalInfo)
	local nodes = self.viewData.gridViewCellNodes[tostring(index)]
	if nil ~= nodes then
		local bgSize = nodes.bg:getContentSize()

		-- 刷新玩家基本信息
		nodes.playerHeadNode:RefreshUI({avatar = rivalInfo.avatar, avatarFrame = rivalInfo.avatarFrame})
		nodes.playerNameLabel:setString(rivalInfo.name)
		nodes.playerLevelLabel:setString(string.format(__('等级: %s'), tostring(rivalInfo.level)))

		-- 刷新卡牌头像
		for i,v in ipairs(nodes.teamNodes) do
			v.cardHeadNode:removeFromParent()
		end
		self.viewData.gridViewCellNodes[tostring(index)].teamNodes = {}

		local teamNodes = {}
		local cardCellSize = cc.size(84, 84)
		local itor = 0
		local battlePoint = 0

		for i,v in ipairs(rivalInfo.defenseTeam) do
			if nil ~= v.cardId and 0 ~= checkint(v.cardId) then
				itor = itor + 1
				local cardHeadNode = require('common.CardHeadNode').new({
					cardData = {
						cardId = v.cardId,
						level = v.level,
						breakLevel = v.breakLevel,
						skinId = v.defaultSkinId,
						favorabilityLevel = v.favorabilityLevel,
					},
					showBaseState = true, showActionState = false, showVigourState = false
				})
				cardHeadNode:setScale(cardCellSize.width / cardHeadNode:getContentSize().width)
				display.commonUIParams(cardHeadNode, {po = cc.p(
					bgSize.width * 0.5 - 220 + (itor - 0.5) * (cardCellSize.width),
					bgSize.height * 0.5 - 7
				)})
				nodes.bg:addChild(cardHeadNode)

				-- 计算战斗力
				battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointByCardData(v)

				table.insert(teamNodes, {cardHeadNode = cardHeadNode})
			end
		end
		self.viewData.gridViewCellNodes[tostring(index)].teamNodes = teamNodes

		-- 刷新战斗力
		nodes.battlePointLabel:setString(tostring(battlePoint))
		display.commonUIParams(nodes.battlePointNameLabel, {ap = cc.p(1, 0.5), po = cc.p(
			nodes.battlePointLabel:getPositionX(),
			nodes.battlePointLabel:getPositionY() + 5
		)})

		-- 刷新奖励
		local rewardsInfo = {
			{goodsId = PVC_POINT_ID, amount = checkint(rivalInfo.winIntegral)},
			{goodsId = PVC_MEDAL_ID, amount = checkint(rivalInfo.winMedal)},
		}

		for i,v in ipairs(rewardsInfo) do
			nodes.rewardNodes[i].goodsAmountLabel:setString(tostring(v.amount))
		end

	end
end
--[[
刷新所有对手信息
@params rivalsInfo table 所有对手信息
--]]
function PVCSelectRivalView:RefreshAllRivals(rivalsInfo)
	self.rivalsInfo = rivalsInfo
	self.viewData.gridView:setCountOfCell(#self.rivalsInfo)
	self.viewData.gridView:reloadData()
end
--[[
刷新换一批信息
@params matchFreeTimes int 剩余刷新次数
@params maxMatchFreeTimes int 最大剩余刷新次数
--]]
function PVCSelectRivalView:RefreshShuffleInfo(matchFreeTimes, maxMatchFreeTimes)
	self.matchFreeTimes = checkint(matchFreeTimes)

	self.viewData.freeShuffleTipsLabel:setVisible(nil ~= matchFreeTimes)

	if nil ~= maxMatchFreeTimes then
		self.maxMatchFreeTimes = maxMatchFreeTimes
	end

	if 0 >= self.matchFreeTimes then
		-- 免费次数耗尽
		self.viewData.shuffleCostIcon:setVisible(true)
		self.viewData.shuffleCostAmountLabel:setVisible(true)
		self.viewData.freeShuffleTimesLabel:setVisible(false)
	else
		-- 有免费次数
		self.viewData.shuffleCostIcon:setVisible(false)
		self.viewData.shuffleCostAmountLabel:setVisible(false)
		self.viewData.freeShuffleTimesLabel:setVisible(true)
		self.viewData.freeShuffleTimesLabel:setString(string.format('%d/%d', self.matchFreeTimes, self.maxMatchFreeTimes))
	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
对手信息按钮回调
--]]
function PVCSelectRivalView:SelectRivalClickHandler(sender)
	PlayAudioClip(AUDIOS.UI.ui_click_confirm.id)
	local index = sender:getParent():getTag()
	local rivalInfo = self.rivalsInfo[index]
	AppFacade.GetInstance():DispatchObservers('SELECT_A_RIVAL', {rivalInfo = rivalInfo})
end
--[[
洗牌按钮回调
--]]
function PVCSelectRivalView:ShuffleClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('SHUFFLE_ALL_RIVALS')
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

return PVCSelectRivalView
