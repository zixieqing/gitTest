
--[[
多阵容的选择卡牌的层
@params table {
	size cc.size 基础大小
	selectedCards table 当前选中的卡牌 -> {
		[1] = {id = nil},
		[2] = {id = nil},
		[3] = {id = nil},
		...
	}
	maxCardsAmount int 最大可以选择的卡牌数量
	teamChangeSingalName string 阵容变化回调信号
}
--]]
local MultipleLineupSelectCardView = class('MultipleLineupSelectCardView', function ()
	local node = CLayout:create()
	node.name = 'common.MultipleLineupSelectCardView'
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
function MultipleLineupSelectCardView:ctor( ... )
	local args = unpack({...})

	self.size = args.size
	self.teamChangeSingalName = args.teamChangeSingalName
	self.maxTeamAmount  = args.maxTeamAmount  or 3
	self.maxCardsAmount = args.maxCardsAmount or MAX_TEAM_MEMBER_AMOUNT
	self.selectedCards = {}
	self.battleTypeData = {}
	self.battleType =  args.battleType
	self.teamId = args.teamId
	
	self:SetTeamDatas(args.teamDatas or {})
	-- self:SetSelectedCards(args.selectedCards)
	-- self:SetSelectedCardIds(args.selectedCards)

	self.allCards = args.allCards
	-- 如果没传数据 初始化一次玩家所有卡牌
	if nil == self.allCards then
		self.allCards = {}
		for k,v in pairs(gameMgr:GetUserInfo().cards) do
			table.insert(self.allCards, v)
		end
	end

	-- logInfo.add(5, tableToString(self.allCards))

	self.filterCards = nil
	self.selectedFilterPattern = nil

	self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------


--[[
初始化ui
--]]
function MultipleLineupSelectCardView:InitUI()
	self:setContentSize(self.size)
	-- self:setBackgroundColor(cc.c4b(255, 64, 64, 100))

	local uiLocationInfo = {
		filterBtnsW = 135,
		confirmBtnsW = 135,
		gridViewCellSize = cc.size(143, 143),
		topShadowH = 20,
		bottomShadowH = 8
	}

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
			checkBtnIcon = display.newImageView(_res(CardUtils.CAREER_ICON_FRAME_PATH_MAP[tostring(v.career)]), 0, 0)
			local careerIcon = display.newImageView(_res(CardUtils.CAREER_ICON_PATH_MAP[tostring(v.career)]), 0, 0)
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
	local confirmBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png') , scale9 = true , size = cc.size(140, 70  )})
	display.commonUIParams(confirmBtn, {cb = handler(self, self.ConfirmBtnClickHandler), po = cc.p(
		display.SAFE_R - uiLocationInfo.confirmBtnsW/2 - 10 ,
		gridViewBg:getPositionY() - gridViewBg:getContentSize().height * 0.5 + confirmBtn:getContentSize().height * 0.5 + 10
	)})
	display.commonLabelParams(confirmBtn, fontWithColor('14', { text = __('保存阵容') , w = 140  , hAlign = display.TAC }))
	self:addChild(confirmBtn, 10)

	local clearBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_white_default.png'),scale9 = true , size = cc.size(140, 70  ) ,cb = handler(self, self.ClearAllCardsClickHandler)})
	display.commonUIParams(clearBtn, {po = cc.p(
		confirmBtn:getPositionX(),
		gridViewBg:getPositionY() + gridViewBg:getContentSize().height * 0.5 - clearBtn:getContentSize().height * 0.5 - 10
	)})
	display.commonLabelParams(clearBtn, fontWithColor('14', {text = __('清空选择')  , w = 140 , hAlign = display.TAC}))
	self:addChild(clearBtn, 10)

	-- gridView
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

	self.uiLocationInfo = uiLocationInfo
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
function MultipleLineupSelectCardView:CardsGridViewDataAdapter(c, i)
	local index = i + 1
	local cell = c
	local cardData = self:GetCardDataByListIndex(index)

	if nil == cell then
		cell = CGridViewCell:new()
		cell:setContentSize(self.uiLocationInfo.gridViewCellSize)

		local cardHeadNode = require('common.CardHeadNode').new({
			id = checkint(cardData.id),
			showBaseState = true, showActionState = false, showVigourState = false
		})
		local scale = (self.uiLocationInfo.gridViewCellSize.width - 10) / cardHeadNode:getContentSize().width
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

        local cardMark = display.newImageView()
        display.commonUIParams(cardMark, {ap = display.RIGHT_TOP, po = cc.p(
			cardHeadNode:getContentSize().width - 46,
			cardHeadNode:getContentSize().height - 46
        )})
        cardMark:setScale(scale)
        cell:addChild(cardMark, 5)
        cardMark:setTag(9)

        cardMark:setVisible(false)

	else
		cell:getChildByTag(3):RefreshUI({
			id = checkint(cardData.id)
		})
	end

	cell:setTag(index)
	
	local selected = self:IsCardSelectedById(cardData.id)
	self:UpdateCellCoverShowState(cell, selected)
	self:UpdateTeamMarkShowState(cell, cardData.id)
	
	return cell
end
--[[
根据卡牌数据刷新可选择列表
@params cards list 可选择卡牌
--]]
function MultipleLineupSelectCardView:RefreshFilterCards(cards)
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
function MultipleLineupSelectCardView:RefreshFilterCardsByFilerType(ftype)
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
function MultipleLineupSelectCardView:RefreshCheckBtnByIndex(index)
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
function MultipleLineupSelectCardView:FilterBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	self:RefreshCheckBtnByIndex(tag)
end
--[[
卡牌头像点击回调
--]]
function MultipleLineupSelectCardView:CardHeadClickHandler(sender)
	PlayAudioByClickNormal()
	local cell = sender:getParent()
	local listIndex = cell:getTag()
	local cardData = self:GetCardDataByListIndex(listIndex)
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
function MultipleLineupSelectCardView:ClearAllCardsClickHandler(sender)
	PlayAudioByClickNormal()
	self:ClearAllCards()
end
--[[
确定按钮回调 (保存团队数据)

send signal data 
	@params teamData 所有的团队数据
	@params teamId   当前的团队id  
--]]
function MultipleLineupSelectCardView:ConfirmBtnClickHandler(sender)
	PlayAudioByClickNormal()
	if nil ~= self.teamChangeSingalName then
		AppFacade.GetInstance():DispatchObservers(self.teamChangeSingalName, {teamDatas = self:GetTeamDatas(), teamId = self:GetTeamId()})
	end
end
---------------------------------------------------
-- btn click handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------

function MultipleLineupSelectCardView:UpdateCellCoverShowState(cell, selected)
	cell:getChildByTag(5):setVisible(selected)
	cell:getChildByTag(7):setVisible(selected)
end

--[[
更新团队图标显示状态
@params id int 卡牌数据库id
@params listIndex int 列表序号
--]]
function MultipleLineupSelectCardView:UpdateTeamMarkShowState(cell, id)
	local teamMark = checkint(self:GetCardTeamMark(id))
	cell:getChildByTag(9):setVisible(teamMark > 0)
	if teamMark > 0 then
		cell:getChildByTag(9):setTexture(_res(string.format('ui/home/teamformation/team_states_team%d.png', teamMark)))
	end
end

--[[
装备卡牌
@params id int 卡牌数据库id
@params listIndex int 列表序号
--]]
function MultipleLineupSelectCardView:EquipACardById(id, listIndex)
	local slotIndex = self:GetAEmptyCardSlot()

	-- 判断是否可以上卡
	if nil == slotIndex then
		uiMgr:ShowInformationTips(__('没有多余位置了!!!'))
		return
	end

	------------ data ------------
	self.selectedCards[slotIndex] = {id = id}
	self.selectedCardIds[tostring(id)] = {id = id, teamId = self:GetTeamId()}
	AppFacade.GetInstance():DispatchObservers('EQUIP_A_CARD', {id = id, position = slotIndex})
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
function MultipleLineupSelectCardView:UnequipACardById(id, listIndex)
	if not self:CheckIsCanUnequipACard(id) then
		uiMgr:ShowInformationTips(__('不能编辑其他编队'))
		return
	end
	
	local position = nil
	if self:IsCardSelectedById(id) then
		------------ data ------------

		self.selectedCardIds[tostring(id)] = nil
		for i,v in ipairs(self.selectedCards) do
			if nil ~= v.id and checkint(id) == checkint(v.id) then
				position = i
				self.selectedCards[i] = {}
				break
			end
		end
		
		------------ data ------------

		------------ view ------------
		local cell = self.gridView:cellAtIndex(listIndex - 1)
		if nil ~= cell then
			self:UpdateCellCoverShowState(cell, false)
			self:UpdateTeamMarkShowState(cell, id)
		end
		------------ view ------------
	end

	if nil ~= position then
		AppFacade.GetInstance():DispatchObservers('UNEQUIP_A_CARD', {id = id, position = position})
	end
end
--[[
卸下卡牌
@params teamIndex int 队伍序号
--]]
function MultipleLineupSelectCardView:UnequipACardByTeamIndex(teamIndex)
	------------ data ------------
	local id = nil
	if nil ~= self.selectedCards[teamIndex] then
		id = self.selectedCards[teamIndex].id
		self.selectedCards[teamIndex] = {}
	end

	if nil ~= id then
		self.selectedCardIds[tostring(id)] = nil
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
function MultipleLineupSelectCardView:ClearAllCards()
	------------ data ------------
	local id = nil
	for i = 1, self.maxCardsAmount do
		local selectedCard = self.selectedCards[i] or {}
		id = selectedCard.id
		if nil ~= id then
			self.selectedCardIds[tostring(id)] = nil
			self.selectedCards[i] = {}

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

	AppFacade.GetInstance():DispatchObservers('CLEAR_ALL_CARDS')
end

function MultipleLineupSelectCardView:ResetSelectedCardIds()
	for teamId, teamData in pairs(self.teamDatas) do
		for i,cardData in ipairs(teamData) do
			local cId = cardData.id
			if nil ~= cId then
				self.selectedCardIds[tostring(cId)] = {id = cId, teamId = teamId}
			end
		end
	end
end

--[[
	重置所有卡牌选中状态
--]]
function MultipleLineupSelectCardView:ResetAllCardSelectState()
	local cells = self.gridView:getCells()
	if cells == nil or next(cells) == nil then return end
	
	for i, cell in ipairs(cells) do
		local index = cell:getTag()
		local cardData = self:GetCardDataByListIndex(index)
		local id = cardData.id
		local selected = self:IsCardSelectedById(id)
		
		self:UpdateCellCoverShowState(cell, selected)
		self:UpdateTeamMarkShowState(cell, id)
	end
end

function MultipleLineupSelectCardView:GetCardTeamDataById(id)
	return self.selectedCardIds[tostring(id)]
end
--[[
根据卡牌数据库id判断卡牌是否被选中
@params id int 卡牌数据库id
@return _ bool 是否被选中
--]]
function MultipleLineupSelectCardView:GetCardTeamMark(id)
	local selectCardData = self:GetCardTeamDataById(id)
	return selectCardData and selectCardData.teamId or 0
end
--[[
根据列表序号获取卡牌数据
@params listIndex int 列表序号
@return _ table cardData
--]]
function MultipleLineupSelectCardView:GetCardDataByListIndex(listIndex)
	return self.filterCards[listIndex]
end
--[[
根据卡牌id获取列表序号
@params id int 卡牌id
@return listIndex int 列表序号
--]]
function MultipleLineupSelectCardView:GetListIndexById(id)
	id = checkint(id)
	local listIndex = nil
	for i,v in ipairs(self.filterCards) do
		if id == checkint(v.id) then
			listIndex = i
		end
	end
	return listIndex
end
--[[
获取一个空槽
@return index int 空槽id
--]]
function MultipleLineupSelectCardView:GetAEmptyCardSlot()
	local index = nil
	for i = 1, self.maxCardsAmount do
		self.selectedCards[i] = self.selectedCards[i] or {}
		if nil == self.selectedCards[i].id then
			return i
		end
	end
	return index
end
--[[
获得 选择的卡牌
@return 选择的卡牌
--]]
function MultipleLineupSelectCardView:GetSelectedCardsByTeamId(teamId)
	return self.teamDatas[tostring(teamId)]
end
--[[
交换卡牌数据
@return 
	@params newTeamData  交换前的新数据
	@params oldTeamData  交换前的旧数据
--]]
function MultipleLineupSelectCardView:SwapSelectedCards(oldTeamId, newTeamId)
	local oldTeamData = self:GetSelectedCardsByTeamId(oldTeamId)
	local newTeamData = self:GetSelectedCardsByTeamId(newTeamId)
	-- logInfo.add(5, tableToString(newTeamData))
	-- logInfo.add(5, tableToString(oldTeamData))
	self:SetTeamData(oldTeamId, newTeamData)
	self:SetTeamData(newTeamId, oldTeamData)

	-- 重置选中卡牌id数据
	self:ResetSelectedCardIds()
	return newTeamData, oldTeamData
end


function MultipleLineupSelectCardView:GetTeamId()
	return self.teamId
end
function MultipleLineupSelectCardView:SetTeamId(teamId)
	self.teamId = teamId
	
	-- 更新选择的数据
	self:SetSelectedCards_new()
end

function MultipleLineupSelectCardView:GetTeamDatas()
	return self.teamDatas
end
function MultipleLineupSelectCardView:SetTeamDatas(teamDatas)
	-- self.teamDatas = clone(teamDatas)
	self.teamDatas = {}
	self.selectedCardIds = {}
	for teamId = 1, self.maxTeamAmount do
		self.teamDatas[tostring(teamId)] = {}

		local teamData = teamDatas[tostring(teamId)]
		if teamData then
			for i,cardData in ipairs(teamData) do
				local cId = cardData.id
				if i <= self.maxCardsAmount then
					self.teamDatas[tostring(teamId)][i] = self.teamDatas[tostring(teamId)][i] or {}
					self.teamDatas[tostring(teamId)][i].id = cId
				end
	
				-- 设置 选择的卡牌Id
				if nil ~= cId then
					self.selectedCardIds[tostring(cId)] = {id = cId, teamId = teamId}
				end
			end
		end
	end

	self:SetSelectedCards_new()

end

function MultipleLineupSelectCardView:SetTeamData(teamId, teamData)
	self.teamDatas[tostring(teamId)] = teamData
end

--[[
设置 选择的卡牌
--]]
function MultipleLineupSelectCardView:SetSelectedCards_new()
	self.selectedCards = self:GetSelectedCardsByTeamId(self:GetTeamId())
	-- for teamId, teamData in pairs(teamDatas) do
	-- 	self.selectedCards[tostring(teamId)] = {}
	-- 	for i = 1, self.maxCardsAmount do
	-- 		local cardData = teamData[i]
	-- 		self.selectedCards[tostring(teamId)][i] = self.selectedCards[tostring(teamId)][i] or {}
	-- 		self.selectedCards[tostring(teamId)][i].id = cardData.id
	-- 	end
	-- end
end
-- --[[
-- 设置 选择的卡牌Id
-- --]]
-- function MultipleLineupSelectCardView:SetSelectedCardIds_new(teamDatas)
-- 	self.selectedCardIds = {}
-- 	for teamId, teamData in pairs(teamDatas) do
-- 		for i, cardData in ipairs(teamData) do
-- 			local cId = cardData.id
-- 			if nil ~= cId then
-- 				self.selectedCardIds[tostring(cId)] = {id = cId, teamId = teamId}
-- 			end
-- 		end
-- 	end
-- end

-- --[[
-- 设置 选择的卡牌
-- --]]
-- function MultipleLineupSelectCardView:SetSelectedCards(selectedCards)
-- 	self.selectedCards = {}
-- 	selectedCards = selectedCards or {}
-- 	for i = 1, self.maxCardsAmount do
-- 		self.selectedCards[i] = {}
-- 		if nil ~= selectedCards[i] and nil ~= selectedCards[i].id then
-- 			self.selectedCards[i].id = selectedCards[i].id
-- 		end
-- 	end
-- end
-- --[[
-- 设置 选择的卡牌Id
-- --]]
-- function MultipleLineupSelectCardView:SetSelectedCardIds(selectedCards)
-- 	self.selectedCardIds = {}
-- 	selectedCards = selectedCards or {}
-- 	for i,v in ipairs(selectedCards) do
-- 		if nil ~= v.id then
-- 			self.selectedCardIds[tostring(v.id)] = v.id
-- 		end
-- 	end
-- end
--[[
按照品质 星级 等级 灵力刷一次排序
@params t 目标table
--]]
function MultipleLineupSelectCardView:RefreshCardSort(t)
	table.sort(t, function (a, b)
		local acardId = checkint(a.cardId)
		local bcardId = checkint(b.cardId)

		local acardConf = CardUtils.GetCardConfig(acardId)
		local bcardConf = CardUtils.GetCardConfig(bcardId)

		if acardConf and bcardConf then
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
			return checkint(acardId) < checkint(bcardId)
		end
	end)
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- check begin --
---------------------------------------------------

--[[
根据卡牌数据库id判断卡牌是否被选中
@params id int 卡牌数据库id
@return _ bool 是否被选中
--]]
function MultipleLineupSelectCardView:IsCardSelectedById(id)
	return nil ~= self:GetCardTeamDataById(id)
end

--[[
检查是否能卸载卡牌
@params id 卡牌id

return 是否能卸载卡牌
--]]
function MultipleLineupSelectCardView:CheckIsCanUnequipACard(id)
	-- 1.先获取 该 cardId 所对应的 teamId
	local cardTeamData = self:GetCardTeamDataById(id) or {}
	local teamId = cardTeamData.teamId

	return checkint(teamId) == checkint(self:GetTeamId())
end

---------------------------------------------------
-- check end --
---------------------------------------------------

return MultipleLineupSelectCardView
