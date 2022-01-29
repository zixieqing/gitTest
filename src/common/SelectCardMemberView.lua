--[[
通用的选择卡牌的层
@params table {
	size cc.size 基础大小
	maxTeamAmount int 最大队伍数量
	selectedCards table 当前选中的卡牌 -> {
		[teamIndex] = {
			[1] = {id = nil},
			[2] = {id = nil},
			[3] = {id = nil},
			...
		}
		...
	}
	maxCardsAmount : int 			最大可以选择的卡牌数量
	teamChangeSingalName : string 	阵容变化回调信号 显示确定按钮
	enterBattleSignalName : string 	进入战斗按钮回调信号 显示战斗按钮
	isOpenRecommendState : bool 	是否开启卡牌推荐状态
	isShowTeamIndex : bool 			是否显示队伍编号
	limitCardsCareers : table 		限制卡牌职业
	limitCardsQualities : table 	限制品质
	battleData : table 				战斗数据
	isEditOtherTeamIndex : bool     是否可编辑非当前选中编队的其他队伍（例如：当前在编辑2编队，想不切换到3编队就把3编队的卡卸下后换上来）
	battleButtonSkinType BattleButtonSkinType 战斗按钮的皮肤类型
	banList table 禁用列表
}
--]]
local SelectCardMemberView = class('SelectCardMemberView', function ()
	local node = CLayout:create()
	node.name = 'common.SelectCardMemberView'
	node:enableNodeEvents()
	return node
end)

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
function SelectCardMemberView:ctor( ... )
	local args = unpack({...})

	-- 初始化数据
	self:InitValue(args)

	self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化数据
--]]
function SelectCardMemberView:InitValue(args)
	-- 选卡界面的大小
	self.size = args.size
	-- ui信息
	self.uiLocationInfo = {
		filterBtnsW = 135,
		confirmBtnsW = 135,
		topShadowH = 20,
		bottomShadowH = 8,
		gridViewCellSize = cc.size(143, 143)
	}

	-- 初始化所有卡牌
	self:InitAllCards(args)
	-- 禁用列表
	self:InitBanList(args)
	-- 初始化携带的卡牌
	self:InitSelectedCards(args)

	-- 确定按钮发送的信号
	self.teamChangeSingalName = args.teamChangeSingalName
	-- 战斗按钮发送的信号
	self.enterBattleSignalName = args.enterBattleSignalName
	-- 是否开启推荐状态
	self.isOpenRecommendState = args.isOpenRecommendState == true
	-- 是否显示队伍编号
	self.isShowTeamIndex = args.isShowTeamIndex == true
	-- 是否可以编辑非当前选中的其他编队队伍
	self.isEditOtherTeamIndex = args.isEditOtherTeamIndex == true

	-- ?战斗类型数据?
	self.battleTypeData = {}
	-- 战斗的类型
	self.battleType =  args.battleType
	-- 战斗按钮皮肤类型
	self.battleButtonSkinType = args.battleButtonSkinType
	
	-- 战斗数据
	self.battleData = args.battleData

	self.filterCards = nil
	self.selectedFilterPattern = nil

end
--[[
初始化禁用卡牌列表
@params args 外部传参
--]]
function SelectCardMemberView:InitBanList(args)
	-- 禁用列表
	self.banList = args.banList
	self.banListMap = nil

	if nil ~= self.banList then
		self.banListMap = {}
		-- 卡牌禁用
		for i, v in ipairs(self.banList.card) do
			self.banListMap[tostring(v)] = true
		end
		-- 职业禁用
		local careerMap = {}
		for i, v in ipairs(self.banList.career) do
			careerMap[tostring(v)] = true
		end
		-- 稀有度禁用
		local qualityMap = {}
		for i, v in ipairs(self.banList.quality) do
			qualityMap[tostring(v)] = true
		end
		for i, v in ipairs(self.allCards) do
			local cardConfig = CardUtils.GetCardConfig(v.cardId) or {}
			if careerMap[tostring(cardConfig.career)] or qualityMap[tostring(cardConfig.qualityId)] then
				self.banListMap[tostring(v.cardId)] = true
			end
		end
	end
	
end
--[[
初始化选卡界面所有的卡牌池
@params args 外部传参
--]]
function SelectCardMemberView:InitAllCards(args)
	-- 限制的职业
	self.limitCardsCareers = args.limitCardsCareers or {}
	-- 限制的品质
	self.limitCardsQualities = args.limitCardsQualities  or {}
	-- 所有的卡牌id
	self.allCards = args.allCards

	-- 如果没传数据 初始化一次玩家所有卡牌
	if nil == self.allCards then
		self.allCards = {}
		local limitCardsCareers = {}
		local limitCardsQualities = {}
		if table.nums(self.limitCardsCareers) > 0 or table.nums(self.limitCardsQualities) > 0 then
			for index, careerId in pairs(self.limitCardsCareers) do
				limitCardsCareers[tostring(careerId)] = careerId
			end
			for index, qualityId in pairs(self.limitCardsQualities) do
				limitCardsQualities[tostring(qualityId)] = qualityId
			end

			local cardConfig = nil
			for k,v in pairs(gameMgr:GetUserInfo().cards) do
				cardConfig = CardUtils.GetCardConfig(checkint(v.cardId))
				if (not limitCardsCareers[tostring(cardConfig.career)]) and (not limitCardsQualities[tostring(cardConfig.qualityId)]) then
					table.insert(self.allCards, v)
				end
			end
		else
			for k,v in pairs(gameMgr:GetUserInfo().cards) do
				table.insert(self.allCards, v)
			end
		end
	else
		if table.nums(self.limitCardsCareers) > 0 or table.nums(self.limitCardsQualities) > 0 then
			local limitCardsCareers = {}
			local limitCardsQualities = {}
			for index, careerId in pairs(self.limitCardsCareers) do
				limitCardsCareers[tostring(careerId)] = careerId
			end
			for index, qualityId in pairs(self.limitCardsQualities) do
				limitCardsQualities[tostring(qualityId)] = qualityId
			end

			local cardConfig = nil
			for i = #self.allCards , 1, -1 do
				local v = self.allCards[i]
				cardConfig = CardUtils.GetCardConfig(checkint(v.cardId))
				if (not limitCardsCareers[tostring(cardConfig.career)]) and (not limitCardsQualities[tostring(cardConfig.qualityId)]) then
				else
					table.remove(self.allCards, i)
				end
			end
		end
	end
end
--[[
初始化队伍信息 携带的卡牌
@params args 外部传参
--]]
function SelectCardMemberView:InitSelectedCards(args)
	-- 队伍数量
	self.maxTeamAmount = args.maxTeamAmount or 1
	-- 最大携带的卡牌数量
	self.maxCardsAmount = args.maxCardsAmount or MAX_TEAM_MEMBER_AMOUNT
	-- 设置推荐卡牌
	self:SetRecommendCards(args.recommendCards)

	-- 已选择的卡牌
	self.selectedCards = {}
	self.selectedCardIds = {}
	self.selectedCardTeams = {}

	local teamData = nil
	local cardData = nil
	local id = nil

	for teamIndex = 1, self.maxTeamAmount do
		self.selectedCards[teamIndex] = {}
		for i = 1, self.maxCardsAmount do
			self.selectedCards[teamIndex][i] = {}

			if nil ~= args.selectedCards[teamIndex] and nil ~= args.selectedCards[teamIndex][i] then

				id = checkint(args.selectedCards[teamIndex][i].id)

				if 0 ~= id then

					-- 检查是否被禁用
					cardData = app.gameMgr:GetCardDataById(id)

					if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
						
						if self:CanEquipCard(id, cardData) then

							-- 可用装载
							self.selectedCards[teamIndex][i].id = checkint(args.selectedCards[teamIndex][i].id)
							self.selectedCardIds[tostring(cardData.id)] = checkint(args.selectedCards[teamIndex][i].id)
							self.selectedCardTeams[tostring(cardData.id)] = checkint(teamIndex)

						else

							-- 不可用卸载
							AppFacade.GetInstance():DispatchObservers('UNEQUIP_A_CARD', {teamIndex = teamIndex, position = i})

						end

					end


				end

			end
		end
	end

	self.currentTeamIndex = nil
end
--[[
初始化ui
--]]
function SelectCardMemberView:InitUI()
	self:setContentSize(self.size)
	-- self:setBackgroundColor(cc.c4b(255, 64, 64, 100))
	local uiLocationInfo = self.uiLocationInfo

	-- bg
	local bg = display.newImageView(_res('ui/common/pvp_select_bg_allcard.png'), 0, 0, {scale9 = true, size = self.size})
	display.commonUIParams(bg, {po = cc.p(self.size.width * 0.5, self.size.height * 0.5)})
	self:addChild(bg)

	-- 左侧筛选按钮
	local filterInfo = {
		{tag = 1, career = CardUtils.CAREER_TYPE.BASE},
		{tag = 2, career = CardUtils.CAREER_TYPE.DEFEND},
		{tag = 3, career = CardUtils.CAREER_TYPE.ATTACK},
		{tag = 4, career = CardUtils.CAREER_TYPE.ARROW},
		{tag = 5, career = CardUtils.CAREER_TYPE.HEART},
	}
	local filterBtns = {}

	for i,v in ipairs(filterInfo) do
		local checkBtn = display.newCheckBox(0, 0, {
			n = _res('ui/common/tower_select_btn_filter_default.png'),
			s = _res('ui/common/tower_select_btn_filter_selected.png')
		})
		display.commonUIParams(checkBtn, {po = cc.p(
			display.SAFE_L + uiLocationInfo.filterBtnsW * 0.5,
			(self.size.height - uiLocationInfo.topShadowH) * 0.5 + (-((i - 0.5) - #filterInfo * 0.5)) * checkBtn:getContentSize().height
		)})
		checkBtn:setOnClickScriptHandler(handler(self, self.FilterBtnClickHandler))
		self:addChild(checkBtn, 5)
		checkBtn:setTag(v.tag)

		filterBtns[v.tag] = checkBtn

		local checkBtnIcon = nil
		if CardUtils.CAREER_TYPE.BASE == v.career then
			checkBtnIcon = display.newLabel(0, 0, fontWithColor('8', {text = __('所有')}))
		else
			checkBtnIcon = display.newNSprite(_res(CardUtils.CAREER_ICON_FRAME_PATH_MAP[tostring(v.career)]), 0, 0)
			local careerIcon = display.newNSprite(_res(CardUtils.CAREER_ICON_PATH_MAP[tostring(v.career)]), 0, 0)
			display.commonUIParams(careerIcon, {po = cc.p(
				utils.getLocalCenter(checkBtnIcon).x,
				utils.getLocalCenter(checkBtnIcon).y + 2
			)})
			careerIcon:setScale(0.65)
			checkBtnIcon:addChild(careerIcon)
		end
		display.commonUIParams(checkBtnIcon, {po = cc.p(
			utils.getLocalCenter(checkBtn).x,
			utils.getLocalCenter(checkBtn).y
		)})
		checkBtn:addChild(checkBtnIcon)
	end

	-------------------------------------------------
	-- 计算gridviewsize
	local paddingX = 10
	local paddingY = 2
	-- gridView的最大期望宽度
	local maxGridW = display.SAFE_RECT.width - uiLocationInfo.filterBtnsW - uiLocationInfo.confirmBtnsW - paddingX * 2
	-- gridView最大期望宽度下col数
	local col = math.floor(maxGridW / uiLocationInfo.gridViewCellSize.width)
	-- 反向算出gridView size
	local gridViewSize = cc.size(
		col * uiLocationInfo.gridViewCellSize.width,
		self.size.height - uiLocationInfo.topShadowH - uiLocationInfo.bottomShadowH - paddingY * 2
	)
	local gridViewBg = display.newImageView(_res('ui/common/common_bg_goods'), 0, 0, {
		scale9 = true, size = cc.size(gridViewSize.width + paddingX * 2, gridViewSize.height + paddingY * 2)
	})
	display.commonUIParams(gridViewBg, {po = cc.p(
		-- display.SAFE_L + uiLocationInfo.filterBtnsW + gridViewBg:getContentSize().width * 0.5,
		self.size.width/2,
		uiLocationInfo.bottomShadowH + gridViewBg:getContentSize().height * 0.5
	)})
	self:addChild(gridViewBg, 10)

	-------------------------------------------------
	-- 右侧两个按钮
	local confirmBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
	display.commonUIParams(confirmBtn, {cb = handler(self, self.ConfirmBtnClickHandler), po = cc.p(
		display.SAFE_R - uiLocationInfo.confirmBtnsW * 0.5 - 10,
		gridViewBg:getPositionY() - gridViewBg:getContentSize().height * 0.5 + confirmBtn:getContentSize().height * 0.5 + 10
	)})
	display.commonLabelParams(confirmBtn, fontWithColor('14', {text = __('确  定')}))
	self:addChild(confirmBtn, 10)

	local clearBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_white_default.png'), cb = handler(self, self.ClearAllCardsClickHandler)})
	display.commonUIParams(clearBtn, {po = cc.p(
		confirmBtn:getPositionX(),
		gridViewBg:getPositionY() + gridViewBg:getContentSize().height * 0.5 - clearBtn:getContentSize().height * 0.5 - 10
	)})
	display.commonLabelParams(clearBtn, fontWithColor('14', {text = __('清空选择') , reqH = 40 , w = 170 , hAlign = display.TAC }))
	self:addChild(clearBtn, 10)

	-- gridView 卡牌列表
	local gridView = CGridView:create(gridViewSize)
	gridView:setAnchorPoint(cc.p(0.5, 0.5))
	gridView:setPosition(cc.p(
		gridViewBg:getPositionX(),
		gridViewBg:getPositionY()
	))
	self:addChild(gridView, 15)
	-- gridView:setBackgroundColor(cc.c4b(178, 63, 88, 100))

	gridView:setCountOfCell(0)
	gridView:setColumns(col)
	gridView:setSizeOfCell(uiLocationInfo.gridViewCellSize)
	gridView:setAutoRelocate(false)
	gridView:setBounceable(false)
	gridView:setDataSourceAdapterScriptHandler(handler(self, self.CardsGridViewDataAdapter))

	-- 战斗按钮
	if nil ~= self.battleData or nil ~= self.enterBattleSignalName then
		confirmBtn:setVisible(false)
		-- battle btn
		local battleBtn = require('common.CommonBattleButton').new({
			pattern = 1,
			clickCallback = handler(self, self.EnterBattleBtnClickHandler),
			buttonSkinType = self.battleButtonSkinType
		})
		display.commonUIParams(battleBtn, {po = cc.p(
			display.SAFE_R - uiLocationInfo.confirmBtnsW * 0.5 - 10,
			gridViewBg:getPositionY() - gridViewBg:getContentSize().height * 0.5 + battleBtn:getContentSize().height * 0.5 + 10
		)})
		self:addChild(battleBtn, 10)
	end

	self.gridView = gridView
	self.filterInfo = filterInfo
	self.filterBtns = filterBtns
	self.bg = bg
	self:RefreshCheckBtnByIndex(1)
end

---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
gridview data adapter
--]]
function SelectCardMemberView:CardsGridViewDataAdapter(c, i)
	local index = i + 1
	local cell = c
	local cardData = self:GetCardDataByListIndex(index)

	if nil == cell then
		cell = self:CreateCardCell(index)
	else
		cell:getChildByTag(3):RefreshUI({
			id = checkint(cardData.id)
		})
	end

	-- 刷新cell
	self:RefreshCardCell(cell, index)

	return cell
end
--[[
创建cell
@params index cell index(lua)
@return cell CGridViewCell cell
--]]
function SelectCardMemberView:CreateCardCell(index)
	local cardData = self:GetCardDataByListIndex(index)
	local cellSize = self.gridView:getSizeOfCell()

	local cell = CGridViewCell:new()
	cell:setContentSize(cellSize)

	local cardHeadNode = require('common.CardHeadNode').new({
		id = checkint(cardData.id),
		showBaseState = true, showActionState = false, showVigourState = false
	})
	local scale = (cellSize.width - 10) / cardHeadNode:getContentSize().width
	cardHeadNode:setScale(scale)
	cardHeadNode:setPosition(utils.getLocalCenter(cell))
	cell:addChild(cardHeadNode)
	cardHeadNode:setTag(3)
	display.commonUIParams(cardHeadNode, {cb = handler(self, self.CardHeadClickHandler), animate = false})

	local selectCover = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), size = cc.size(
		cardHeadNode:getContentSize().width * scale - 10,
		cardHeadNode:getContentSize().height * scale - 10
	)})
	display.commonUIParams(selectCover, {ap = cc.p(0.5, 0.5), po = cc.p(
		cardHeadNode:getPositionX(),
		cardHeadNode:getPositionY()
	)})
	cell:addChild(selectCover, 5)
	selectCover:setTag(5)

	selectCover:setVisible(false)

	local selectMark = display.newImageView(_res('ui/common/common_bg_frame_goods_elected.png'), 0, 0)
	display.commonUIParams(selectMark, {po = cc.p(
		cardHeadNode:getPositionX(),
		cardHeadNode:getPositionY()
	)})
	selectMark:setScale((cardHeadNode:getContentSize().width * scale + 10) / selectMark:getContentSize().width)
	cell:addChild(selectMark, 5)
	selectMark:setTag(7)

	selectMark:setVisible(false)

	if self.isOpenRecommendState then
		local recommendImg = display.newImageView(_res('ui/common/summer_activity_mvpxiangling_icon.png'), cardHeadNode:getContentSize().width * scale - 10 , cardHeadNode:getContentSize().height * scale - 10)
		cell:addChild(recommendImg, 5)
		recommendImg:setTag(8)
		recommendImg:setVisible(false)
	end
	if self.banListMap then
		local banTextLabel = display.newLabel(cardHeadNode:getPositionX(), cardHeadNode:getPositionY(), {
			text = __('不可出战'), fontSize = 20, color = '#ffffff',
			w = 120 , hAlign = display.TAC
		})
		cell:addChild(banTextLabel, 10)
		banTextLabel:setTag(9)
	end

	local cardMark = display.newImageView()
	display.commonUIParams(cardMark, {ap = display.RIGHT_TOP, po = cc.p(
		cardHeadNode:getContentSize().width - 46,
		cardHeadNode:getContentSize().height - 46
	)})
	cardMark:setScale(scale)
	cardMark:setVisible(false)
	cell:addChild(cardMark, 5)
	cardMark:setTag(99)

	return cell
end
--[[
刷新cell
@params cell CGridViewCell 卡牌cell
@params index cell index(lua)
--]]
function SelectCardMemberView:RefreshCardCell(cell, index)
	local cardData = self:GetCardDataByListIndex(index)

	cell:setTag(index)

	-- 是否选中
	local selected = self:IsCardSelectedById(cardData.id)
	self:UpdateCellCoverShowState(cell, selected)

	-- 推荐状态
	if cell:getChildByTag(8) then
		cell:getChildByTag(8):setVisible(self:IsCardRecommendByCardId(cardData.cardId))
	end
	
	-- 禁用状态
	if self.banListMap then
		if self.banListMap[tostring(cardData.cardId)] then
			self:UpdateCellCoverShowState(cell, true)
		else
			cell:getChildByTag(9):setVisible(false)
		end
	end

	-- 显示队伍编号
	self:UpdateTeamMarkShowState(cell, cardData.id)
end
--[[
根据卡牌数据刷新可选择列表
@params cards list 可选择卡牌
--]]
function SelectCardMemberView:RefreshFilterCards(cards)
	------------ data ------------
	self.filterCards = cards
	------------ data ------------

	------------ view ------------
	self.gridView:setCountOfCell(#self.filterCards)
	self.gridView:reloadData()
	------------ view ------------
end
--[[
根据筛选的类型刷新可选择的卡牌
@params ftype int 筛选类型
--]]
function SelectCardMemberView:RefreshFilterCardsByFilerType(ftype)
	local filterInfo = self.filterInfo[ftype]
	local filterCards = {}

	local cardId = nil
	local cardConfig = nil

	if CardUtils.CAREER_TYPE.BASE == filterInfo.career then
		filterCards = self.allCards
	else
		for i,v in ipairs(self.allCards) do
			cardId = checkint(v.cardId)
			cardConfig = CardUtils.GetCardConfig(cardId)
			if cardConfig ~= nil and filterInfo.career == checkint(cardConfig.career) then
				table.insert(filterCards, v)
			end
		end
	end

	self:RefreshCardSort(filterCards)

	self:RefreshFilterCards(filterCards)
end
--[[
根据序号刷新筛选按钮状态
@params index int 选中的按钮序号
--]]
function SelectCardMemberView:RefreshCheckBtnByIndex(index)
	if nil ~= index then
		local curBtn = self.filterBtns[index]
		if nil ~= curBtn then
			curBtn:setChecked(true)
		end
	end

	if index == self.selectedFilterPattern then return end

	if nil ~= self.selectedFilterPattern then
		local preBtn = self.filterBtns[self.selectedFilterPattern]
		if nil ~= preBtn then
			preBtn:setChecked(false)
		end
	end

	self.selectedFilterPattern = index
	self:RefreshFilterCardsByFilerType(index)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- btn click handler begin --
---------------------------------------------------
--[[
筛选标签按钮点击回调
--]]
function SelectCardMemberView:FilterBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	self:RefreshCheckBtnByIndex(tag)
end
--[[
卡牌头像点击回调
--]]
function SelectCardMemberView:CardHeadClickHandler(sender)
	PlayAudioByClickNormal()
	local cell = sender:getParent()
	local listIndex = cell:getTag()
	local cardData = self:GetCardDataByListIndex(listIndex)

	local canEquip, waringText = self:CanEquipCard(checkint(cardData.id))
	if not canEquip then
		app.uiMgr:ShowInformationTips(waringText)
		return
	end

	if self:IsCardSelectedById(checkint(cardData.id)) then
		-- 卸下卡牌
		self:UnequipACardById(checkint(cardData.id), listIndex)
	else
		-- 装备卡牌
		self:EquipACardById(checkint(cardData.id), listIndex)
	end
end
--[[
清空所有卡牌
--]]
function SelectCardMemberView:ClearAllCardsClickHandler(sender)
	PlayAudioByClickNormal()
	self:ClearAllCards()
end
--[[
确定按钮回调
--]]
function SelectCardMemberView:ConfirmBtnClickHandler(sender)
	PlayAudioByClickNormal()
	if nil ~= self.teamChangeSingalName then

		if 1 >= self.maxTeamAmount then
			-- 单队
			AppFacade.GetInstance():DispatchObservers(self.teamChangeSingalName, {teamData = self.selectedCards[self:GetCurrentTeamIndex()]})
		else
			-- 多队
			if self.enterBattleSignalName then
				AppFacade.GetInstance():DispatchObservers(self.enterBattleSignalName, {teamData = self.selectedCards})
			else
				AppFacade.GetInstance():DispatchObservers(self.teamChangeSingalName, {teamData = self.selectedCards})
			end
		end
		
	end
end
--[[
进入战斗按钮点击回调
--]]
function SelectCardMemberView:EnterBattleBtnClickHandler( sender )
	PlayAudioByClickNormal()

	if nil ~= self.battleData then

		-- 根据传入的战斗数据内部起战斗
		if 1 >= self.maxTeamAmount then
			self:EnterBattleOnlyOneTeam(self:GetCurrentTeamIndex())
		else
			
		end
	
	elseif nil ~= self.enterBattleSignalName then

		-- 根据传入的信号外部起战斗
		self:EnterBattleAllTeams()

	end

	
end
--[[
单队进入战斗
@params teamIndex int 队伍序号
--]]
function SelectCardMemberView:EnterBattleOnlyOneTeam(teamIndex)
	local selectedCards = self.selectedCards[teamIndex]

	local teamData = {}
	local cards = ''

	for i, v in ipairs(selectedCards) do
		if v.id and 0 ~= checkint(v.id) then
			table.insert(teamData, checkint(v.id))
			if cards == '' then
				cards = tostring(v.id)
			else
				cards = cards .. ',' .. tostring(v.id)
			end
		end
	end

	if #teamData == 0 then -- 判空
		app.uiMgr:ShowInformationTips(__('队伍不能为空'))
		return
	end

	self.battleData.serverCommand.enterBattleRequestData.cards = cards

	local battleConstructor = require('battleEntry.BattleConstructor').new()
    battleConstructor:InitByCommonPVCSingleTeam(
			self.battleData.questBattleType,
            self.battleData.settlementType,
            teamData,
            self.battleData.rivalTeamData,
            {},
            {},
            nil,
            nil ,
            self.battleData.serverCommand,
            self.battleData.fromtoData
    )
	battleConstructor:OpenBattle()
	AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')
end
--[[
多队进入战斗
--]]
function SelectCardMemberView:EnterBattleAllTeams()
	local canEnterBattle, waringText = self:CanEnterBattle()
	if not canEnterBattle then
		app.uiMgr:ShowInformationTips(waringText)
		return
	end

	AppFacade.GetInstance():DispatchObservers(self.enterBattleSignalName, {teamData = self.selectedCards})
end
--[[
判断阵容是否满足了进入战斗的条件
@return canEnterBattle, waringText bool, string 是否可以, 警告文字
--]]
function SelectCardMemberView:CanEnterBattle()
	local canEnterBattle = true
	local waringText = nil

	if 0 >= table.nums(self.selectedCards) then
		return false, __('必须要有一队!!!')
	end

	local teamData = nil
	local cardData = nil
	local hasCard = false
	
	for teamIndex = 1, self.maxTeamAmount do

		hasCard = false
		teamData = self.selectedCards[teamIndex]

		if nil ~= teamData then
			for teamIdx = 1, self.maxCardsAmount do

				cardData = teamData[teamIdx]
				if nil ~= cardData and 0 ~= checkint(cardData.id) then
					hasCard = true
					break
				end
	
			end
		end

		if false == hasCard then
			return false, __('队伍不能为空!!!')
		end

	end

	return canEnterBattle, waringText
end
---------------------------------------------------
-- btn click handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
当前队伍序号
@return _ int 队伍序号	
--]]
function SelectCardMemberView:GetCurrentTeamIndex()
	return self.currentTeamIndex
end
function SelectCardMemberView:SetCurrentTeamIndex(teamIndex)
	self.currentTeamIndex = teamIndex
end


function SelectCardMemberView:UpdateCellCoverShowState(cell, selected)
	cell:getChildByTag(5):setVisible(selected)
	cell:getChildByTag(7):setVisible(selected)
end

--[[
更新团队图标显示状态
@params id int 卡牌数据库id
@params listIndex int 列表序号
--]]
function SelectCardMemberView:UpdateTeamMarkShowState(cell, id)
	local teamIndex = checkint(self.selectedCardTeams[tostring(id)])
	local isShowTeam = teamIndex > 0 and self.isShowTeamIndex
	cell:getChildByTag(99):setVisible(isShowTeam)
	if isShowTeam then
		cell:getChildByTag(99):setTexture(_res(string.format('ui/home/teamformation/team_states_team%d.png', teamIndex)))
	end
end

--[[
装备卡牌
@params id int 卡牌数据库id
@params listIndex int 列表序号
--]]
function SelectCardMemberView:EquipACardById(id, listIndex)
	local slotIndex = self:GetAEmptyCardSlot()

	-- 判断是否可以上卡
	if nil == slotIndex then
		uiMgr:ShowInformationTips(__('没有多余位置了!!!'))
		return
	end

	------------ data ------------
	self:AddASelectedCard(self.currentTeamIndex, slotIndex, id)
	AppFacade.GetInstance():DispatchObservers('EQUIP_A_CARD', {id = id, position = slotIndex, teamIndex = self.currentTeamIndex})
	------------ data ------------

	------------ view ------------
	local cell = self.gridView:cellAtIndex(listIndex - 1)
	if nil ~= cell then
		self:UpdateCellCoverShowState(cell, true)
		self:UpdateTeamMarkShowState(cell, id)
	end
	------------ view ------------
end
--[[
卸下卡牌
@params id int 卡牌数据库id
@params listIndex int 列表序号
--]]
function SelectCardMemberView:UnequipACardById(id, listIndex)
	local teamIndex, teamIdx = self:GetCardIndexInfoById(id)

	if nil ~= teamIndex and nil ~= teamIdx then

		if self.isEditOtherTeamIndex == false and self.currentTeamIndex ~= teamIndex then
			app.uiMgr:ShowInformationTips(__('不能编辑其他编队'))
			return
		end

		------------ data ------------
		self:RemoveASelectedCard(teamIndex, teamIdx)
		------------ data ------------

		------------ view ------------
		local cell = self.gridView:cellAtIndex(listIndex - 1)
		if nil ~= cell then
			self:UpdateCellCoverShowState(cell, false)
			self:UpdateTeamMarkShowState(cell, id)
		end
		------------ view ------------

		AppFacade.GetInstance():DispatchObservers('UNEQUIP_A_CARD', {teamIndex = teamIndex, position = teamIdx})

	end
end
--[[
卸下卡牌
@params teamIndex int 队伍序号
@params teamIdx int 队伍中的序号
--]]
function SelectCardMemberView:UnequipACardByTeamIndex(teamIndex, teamIdx)
	------------ data ------------
	local id = self:RemoveASelectedCard(teamIndex, teamIdx)

	if nil ~= id then
		local listIndex = self:GetListIndexById(id)
		if nil ~= listIndex then
			------------ view ------------
			local cell = self.gridView:cellAtIndex(listIndex - 1)
			if nil ~= cell then
				self:UpdateCellCoverShowState(cell, false)
				self:UpdateTeamMarkShowState(cell, id)
			end
			------------ view ------------
		end
	end
	------------ data ------------
end
--[[
清空卡牌
--]]
function SelectCardMemberView:ClearAllCards()
	------------ data ------------
	local teamData = self:GetCurrentTeamCards()
	
	local id = nil
	for i = 1, self.maxCardsAmount do
		id = teamData[i].id
		if nil ~= id then
			self.selectedCardIds[tostring(id)] = nil
			self.selectedCardTeams[tostring(id)] = nil
			teamData[i] = {}

			-- 清空列表选择的状态
			for i,v in ipairs(self.filterCards) do
				if checkint(id) == checkint(v.id) then
					local cell = self.gridView:cellAtIndex(i - 1)
					if nil ~= cell then
						self:UpdateCellCoverShowState(cell, false)
						self:UpdateTeamMarkShowState(cell, id)
					end
					break
				end
			end
		end
	end
	------------ data ------------

	AppFacade.GetInstance():DispatchObservers('CLEAR_ALL_CARDS', {teamIndex = self.currentTeamIndex})
end
--[[
根据卡牌数据库id判断卡牌是否被选中
@params id int 卡牌数据库id
@return _ bool 是否被选中
--]]
function SelectCardMemberView:IsCardSelectedById(id)
	return nil ~= self.selectedCardIds[tostring(id)]
end
--[[
根据卡牌id获取该卡牌对应的teamIndex和teamIdx
@params id int 卡牌id
@return teamIndex, teamIdx int, int 队伍序号和队伍中的序号
--]]
function SelectCardMemberView:GetCardIndexInfoById(id)
	local teamIndex = nil
	local teamIdx = nil

	if not self:IsCardSelectedById(id) then
		return teamIndex, teamIdx
	end

	local teamData = nil
	for teamIndex_ = 1, self.maxTeamAmount do

		teamData = self:GetTeamDataByTeamIndex(teamIndex_)
		if nil ~= teamData then
			for teamIdx_ = 1, self.maxCardsAmount do

				if nil ~= teamData[teamIdx_] and nil ~= teamData[teamIdx_].id and id == teamData[teamIdx_].id then
					teamIndex = teamIndex_
					teamIdx = teamIdx_
					break
				end

			end
		end

	end

	return teamIndex, teamIdx
end
--[[
根据卡id判断卡牌是否是推荐卡牌
@params cardId int 卡牌id
@return _ bool 是否是推荐卡牌
--]]
function SelectCardMemberView:IsCardRecommendByCardId(cardId)
	return nil ~= self.recommendCardIds[tostring(cardId)]
end
--[[
根据列表序号获取卡牌数据
@params listIndex int 列表序号
@return _ table cardData
--]]
function SelectCardMemberView:GetCardDataByListIndex(listIndex)
	return self.filterCards[listIndex]
end
--[[
根据卡牌id获取列表序号
@params id int 卡牌id
@return listIndex int 列表序号
--]]
function SelectCardMemberView:GetListIndexById(id)
	local listIndex = nil
	for i,v in ipairs(self.filterCards) do
		if checkint(id) == checkint(v.id) then
			listIndex = i
		end
	end
	return listIndex
end
--[[
获取一个空槽
@return index int 空槽id
--]]
function SelectCardMemberView:GetAEmptyCardSlot()
	local teamData = self:GetCurrentTeamCards()
	local index = nil

	for i = 1, self.maxCardsAmount do
		if nil == teamData[i].id or 0 == checkint(teamData[i].id) then
			return i
		end
	end
	return index
end
--[[
在指定位置插入一张卡牌
@params teamIndex int 队伍序号
@params teamIdx int 队伍中的序号
@params id int 卡牌的id
--]]
function SelectCardMemberView:AddASelectedCard(teamIndex, teamIdx, id)
	self.selectedCards[teamIndex][teamIdx] = {id = id}
	self.selectedCardIds[tostring(id)] = id
	self.selectedCardTeams[tostring(id)] = checkint(teamIndex)
end
--[[
根据id移除一张卡牌
@params id int 卡牌的id
@return teamIndex, teamIdx int, int 移除卡牌的队伍序号和队伍中的序号
--]]
function SelectCardMemberView:RemoveASelectedCardById(id)
	local teamIndex = self.currentTeamIndex
	local teamIdx = nil
	if self:IsCardSelectedById(id) then

		self.selectedCardIds[tostring(id)] = nil
		self.selectedCardTeams[tostring(id)] = nil
		local teamData = self:GetCurrentTeamCards()

		for i,v in ipairs(teamData) do
			if nil ~= v.id and checkint(id) == checkint(v.id) then
				teamIdx = i
				teamData[i] = {}
				break
			end
		end
	end
	return teamIndex, teamIdx
end
--[[
移除一张卡牌
@params teamIndex int 队伍序号
@params teamIdx int 队伍中的序号
@return id int 移除的卡牌id
--]]
function SelectCardMemberView:RemoveASelectedCard(teamIndex, teamIdx)
	local id = nil
	if nil ~= self.selectedCards[teamIndex] and nil ~= self.selectedCards[teamIndex][teamIdx] then
		id = self.selectedCards[teamIndex][teamIdx].id
		self.selectedCards[teamIndex][teamIdx] = {}
	end

	if nil ~= id then
		self.selectedCardIds[tostring(id)] = nil
		self.selectedCardTeams[tostring(id)] = nil
	end

	return id
end
--[[
根据队伍序号获取队伍信息
@params teamIndex int 队伍序号
--]]
function SelectCardMemberView:GetTeamDataByTeamIndex(teamIndex)
	return self.selectedCards[teamIndex]
end
--[[
获取当前队伍的卡
--]]
function SelectCardMemberView:GetCurrentTeamCards()
	return self.selectedCards[self.currentTeamIndex]
end
function SelectCardMemberView:GetAllTeamData()
	return self.selectedCards
end
--[[
设置推荐卡牌
@params recommendCards table 推荐卡牌列表
--]]
function SelectCardMemberView:SetRecommendCards(recommendCards)
	self.recommendCards = recommendCards or {}
	self.recommendCardIds = {}
	for i, cardId in pairs(self.recommendCards) do
		if nil ~= cardId then
			self.recommendCardIds[tostring(cardId)] = cardId
		end
	end
end
--[[
按照品质 星级 等级 灵力刷一次排序
@params t 目标table
--]]
function SelectCardMemberView:RefreshCardSort(t)
	table.sort(t, function (a, b)
		local acardId = checkint(a.cardId)
		local bcardId = checkint(b.cardId)

		local acardConf = CardUtils.GetCardConfig(acardId)
		local bcardConf = CardUtils.GetCardConfig(bcardId)
		
		if acardConf and bcardConf then
			local aRecommendState = self:IsCardRecommendByCardId(acardId) and 1 or 0
			local bRecommendState = self:IsCardRecommendByCardId(bcardId) and 1 or 0

			if aRecommendState == bRecommendState then
				if checkint(acardConf.qualityId) == checkint(bcardConf.qualityId) then
					if checkint(a.breakLevel) == checkint(b.breakLevel) then
						if checkint(a.level) == checkint(b.level) then
							return checkint(acardId) < checkint(bcardId)
						else
							return checkint(a.level) > checkint(b.level)
						end
					else
						return checkint(a.breakLevel) > checkint(b.breakLevel)
					end
				else
					return checkint(acardConf.qualityId) > checkint(bcardConf.qualityId)
				end
			else
				return aRecommendState > bRecommendState
			end

		else
			return checkint(acardId) < checkint(bcardId)
		end
	end)
end
--[[
判断卡牌是否可以装载
@params id int 卡牌数据库id
@params cardData table 卡牌信息
@return canEquip, waringText bool, string 是否可以, 警告文字
--]]
function SelectCardMemberView:CanEquipCard(id, cardData)
	local cardId = nil
	if nil == cardData or 0 == checkint(cardData.cardId) then
		cardData = app.gameMgr:GetCardDataById(id)
	end

	if 0 == checkint(id) or nil == cardData or 0 == checkint(cardData.cardId) then
		return false, __('卡牌不存在')
	end

	cardId = checkint(cardData.cardId)

	if nil ~= self.banListMap and nil ~= self.banListMap[tostring(cardId)] then
		return false, __('卡牌被禁用')
	end

	return true
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return SelectCardMemberView
