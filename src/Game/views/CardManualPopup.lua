--[[
图鉴弹窗
--]]
local CommonDialog = require('common.CommonDialog')
local CardManualPopup = class('CardManualPopup', CommonDialog)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

--[[
override
initui
--]]
function CardManualPopup:InitialUI()

	self.sortType = {
		{tag = 0, descr = __('筛选'), typeDescr = __('所有')},
		{tag = CardUtils.CAREER_TYPE.DEFEND},
		{tag = CardUtils.CAREER_TYPE.ATTACK},
		{tag = CardUtils.CAREER_TYPE.ARROW},
		{tag = CardUtils.CAREER_TYPE.HEART},
	}

	local cardsConf = CommonUtils.GetConfigAllMess('card', 'cards')

	local function CreateView()

		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_11.png'), 0, 0)
		local bgSize = bg:getContentSize()

		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)

		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
		display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5 - 10)})
		display.commonLabelParams(titleBg,
			{text = __('图鉴'),
			fontSize = 24,color = fontWithColor('BC').color,ttf = true, font = TTF_GAME_FONT,
			offset = cc.p(0, -2)})
		bg:addChild(titleBg)

		-- own label 
		local ownAmountLabel = display.newLabel(50, bgSize.height - 95,
			{text = string.format(__('卡牌持有数：%d/%d'), table.nums(gameMgr:GetUserInfo().cards), table.nums(cardsConf)), fontSize = 24, color = '#76553b', ap = cc.p(0, 0.5)})
		view:addChild(ownAmountLabel, 6)

		-- sort btn
		local sortBtn = display.newCheckBox(0, 0,
			{n = _res('ui/common/tujian_btn_selection_unused.png'), s = _res('ui/common/tujian_btn_selection_choosed.png')})
		display.commonUIParams(sortBtn, {po = cc.p(bgSize.width - sortBtn:getContentSize().width * 0.5 - 70, ownAmountLabel:getPositionY())})
		view:addChild(sortBtn, 10)
		sortBtn:setOnClickScriptHandler(handler(self, self.SortBtnCallback))

		local sortLabel = display.newLabel(utils.getLocalCenter(sortBtn).x, utils.getLocalCenter(sortBtn).y,
			fontWithColor(5,{text = __('筛选')}))
		sortBtn:addChild(sortLabel)

		local sortBoardImg = display.newImageView(_res('ui/common/tujian_selection_frame_1.png'), sortBtn:getPositionX(), sortBtn:getPositionY() - sortBtn:getContentSize().height * 0.5)
		local sortBoard = display.newLayer(sortBtn:getPositionX(), sortBtn:getPositionY() - sortBtn:getContentSize().height * 0.5,
			{size = sortBoardImg:getContentSize(), ap = cc.p(0.5, 1)})
		view:addChild(sortBoard, 15)
		display.commonUIParams(sortBoardImg, {po = utils.getLocalCenter(sortBoard)})
		sortBoard:addChild(sortBoardImg)
		sortBoard:setVisible(false)

		-- 排序类型
		local topPadding = 18
		local bottomPadding = 4
		local listSize = cc.size(sortBoard:getContentSize().width, sortBoard:getContentSize().height - topPadding - bottomPadding)
		local cellSize = cc.size(listSize.width, listSize.height / (table.nums(self.sortType)))
		local centerPos = nil
		for i,v in ipairs(self.sortType) do
			centerPos = cc.p(listSize.width * 0.5, listSize.height + bottomPadding - (i - 0.5) * cellSize.height)
			local sortTypeBtn = display.newButton(0, 0, {size = cellSize, ap = cc.p(0.5, 0.5), cb = handler(self, self.SortTypeBtnCallback)})
			display.commonUIParams(sortTypeBtn, {po = cc.p(centerPos)})
			sortBoard:addChild(sortTypeBtn)
			sortTypeBtn:setTag(v.tag)

			if v.tag ~= 0 then
				local descrLabel = display.newLabel(0, 0,
					fontWithColor(5,{text = CardUtils.GetCardCareerName(v.tag), ap = cc.p(0, 0.5)}))

				local careerBg = display.newImageView(_res(CardUtils.CAREER_ICON_FRAME_PATH_MAP[tostring(v.tag)]), centerPos.x - 25, centerPos.y)

				local totalWidth = careerBg:getContentSize().width * careerBg:getScale() + display.getLabelContentSize(descrLabel).width
				display.commonUIParams(careerBg, {po = cc.p(
					centerPos.x - totalWidth * 0.5 + careerBg:getContentSize().width * 0.5 * careerBg:getScale(),
					centerPos.y)})
				sortBoard:addChild(careerBg)

				local careerIcon = display.newImageView(_res(CardUtils.CAREER_ICON_PATH_MAP[tostring(v.tag)]), utils.getLocalCenter(careerBg).x, utils.getLocalCenter(careerBg).y + 2)
				careerIcon:setScale(0.65)
				careerBg:addChild(careerIcon)
				
				display.commonUIParams(descrLabel, {po = cc.p(careerBg:getPositionX() + careerBg:getContentSize().width * 0.5, careerBg:getPositionY())})
				sortBoard:addChild(descrLabel)


			else
				local descrLabel = display.newLabel(0, 0,
					fontWithColor(5,{text = v.typeDescr, ap = cc.p(0.5, 0.5)}))
				display.commonUIParams(descrLabel, {po = centerPos})
				sortBoard:addChild(descrLabel)
			end

			if i < table.nums(self.sortType) then
				local splitLine = display.newNSprite(_res('ui/common/tujian_selection_line.png'), centerPos.x, centerPos.y - cellSize.height * 0.5)
				sortBoard:addChild(splitLine)
			end
		end

		-- card grid view
		local gridViewBgSize = cc.size(835, 460)
		local gridViewBg = display.newImageView(_res('ui/common/common_bg_goods.png'), 0, 0, {scale9 = true, size = gridViewBgSize})
		display.commonUIParams(gridViewBg, {po = cc.p(bgSize.width * 0.5, bgSize.height * 0.425)})
		view:addChild(gridViewBg, 6)

		local perLine = 5
		local gridViewSize = cc.size(gridViewBgSize.width, gridViewBgSize.height - 2)
		local cellSize = cc.size(gridViewSize.width / perLine, gridViewSize.width / perLine)
		local gridView = CGridView:create(gridViewSize)
		gridView:setAnchorPoint(gridViewBg:getAnchorPoint())
		gridView:setPosition(cc.p(gridViewBg:getPositionX(), gridViewBg:getPositionY()))
		view:addChild(gridView, 10)
		-- gridView:setBackgroundColor(cc.c4b(255, 128, 0, 128))

		gridView:setColumns(perLine)
		gridView:setSizeOfCell(cellSize)
		gridView:setAutoRelocate(false)
		gridView:setDataSourceAdapterScriptHandler(handler(self, self.GridViewDataAdapter))

		return {
			view = view,
			gridView = gridView,
			sortBtn = sortBtn,
			sortLabel = sortLabel,
			sortBoard = sortBoard
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	self:SortCards(0)

	-- 重写触摸
	self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    -- self.touchListener_:setSwallowTouches(true)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchCanceled_), cc.Handler.EVENT_TOUCH_CANCELLED)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self)
end

function CardManualPopup:GridViewDataAdapter(c, i)
	local cell = c
	local index = i + 1
	local cardHeadNode = nil
	local cardId = checkint(self.sortedCardIds[index])
	local cardConf = CommonUtils.GetConfig('cards', 'card', cardId)

	if nil == cell then
		cell = CGridViewCell:new()
		cell:setContentSize(self.viewData.gridView:getSizeOfCell())

		cardHeadNode = require('common.CardHeadNode').new({
			cardData = {cardId = cardId}
		})
		cardHeadNode:setScale(0.85)
		cardHeadNode:setPosition(utils.getLocalCenter(cell))
		display.commonUIParams(cardHeadNode, {animate = false, cb = handler(self, self.HeadCallback)})
		cell:addChild(cardHeadNode)
		cardHeadNode:setTag(3)
	else
		cardHeadNode = cell:getChildByTag(3)
		cardHeadNode:RefreshUI({
			cardData = {cardId = cardId}
		})
	end

	cardHeadNode:SetGray(nil == gameMgr:GetCardDataByCardId(cardId))

	cell:setTag(index)

	return cell
end
---------------------------------------------------
-- sort control begin --
---------------------------------------------------
--[[
对指定卡牌map按照卡牌id排序
@params cards table 卡牌map
@return keys table 排序后的卡牌id
--]]
function CardManualPopup:SortByCardId(cards)
	local keys = table.keys(cards)
	table.sort(keys, function (a, b)
		return checkint(a) < checkint(b)
	end)
	return keys
end
--[[
排序整个界面
@params pattern int 排序模式
0 默认所有卡牌按照 id 排序
1 所有防御型
2 所有近战 dps
3 所有远程 dps
4 所有辅助型
--]]
function CardManualPopup:SortCards(pattern)
	local cardsConf = CommonUtils.GetConfigAllMess('card', 'cards')
	if 0 == pattern then
		self.sortedCardIds = self:SortByCardId(cardsConf)
	elseif 1 == pattern or
		2 == pattern or
		3 == pattern or
		4 == pattern then
		local t = {}
		for k,v in pairs(cardsConf) do
			if pattern == checkint(v.career) then
				t[k] = k
			end
		end
		self.sortedCardIds = self:SortByCardId(t)
	end

	self.viewData.gridView:setCountOfCell(table.nums(self.sortedCardIds))
	self.viewData.gridView:reloadData()
end
--[[
筛选按钮回调
--]]
function CardManualPopup:SortBtnCallback(sender)
	PlayAudioByClickNormal()
	local checked = sender:isChecked()
	self:ShowSortBoard(checked)
end
--[[
显示排序板
@params visible bool 是否显示排序板
--]]
function CardManualPopup:ShowSortBoard(visible)
	self.viewData.sortBtn:setChecked(visible)
	self.viewData.sortBoard:setVisible(visible)
	local labelColor = fontWithColor('5').color
	if visible then
		labelColor = '#ffffff'
	end
	self.viewData.sortLabel:setColor(ccc3FromInt(labelColor))
end
--[[
排序按钮点击回调
--]]
function CardManualPopup:SortTypeBtnCallback(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	self:SortCards(tag)
	self.viewData.sortLabel:setString(self.sortType[tag + 1].descr or CardUtils.GetCardCareerName(tag))
	self:ShowSortBoard(false)
end
---------------------------------------------------
-- sort control end --
---------------------------------------------------

---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
function CardManualPopup:onTouchBegan_(touch, event)
	if not self:TouchedBoard(touch:getLocation()) then
		self:ShowSortBoard(false)
	end
	return true
end
function CardManualPopup:onTouchMoved_(touch, event)

end
function CardManualPopup:onTouchEnded_(touch, event)

end
function CardManualPopup:onTouchCanceled_( touch, event )
	print('here touch canceled by some unknown reason')
end
--[[
是否触摸到了提示板
@params touchPos cc.p 触摸位置
@return _ bool 
--]]
function CardManualPopup:TouchedBoard(touchPos)
	local boundingBox = self.viewData.sortBoard:getBoundingBox()
	local fixedP = cc.CSceneManager:getInstance():getRunningScene():convertToNodeSpace(
		self.viewData.sortBoard:getParent():convertToWorldSpace(cc.p(boundingBox.x, boundingBox.y)))
	if cc.rectContainsPoint(cc.rect(fixedP.x, fixedP.y, boundingBox.width, boundingBox.height), touchPos) then
		return true
	end
	return false
end
--[[
卡牌头像点击回调
--]]
function CardManualPopup:HeadCallback(sender)
	PlayAudioByClickNormal()
	local index = sender:getParent():getTag()
	local cardId = checkint(self.sortedCardIds[index])
	local cardData = gameMgr:GetCardDataByCardId(cardId)
	if nil == cardData then
	-- if false then
		uiMgr:ShowInformationTips(__('你并没有这张卡'))
	else
		local tag = 4444
		-- local layer = require('Game.views.CardManualView').new({tag = tag, cardId = cardId, breakLevel = nil ~= cardData and checkint(cardData.breakLevel) or 0})
		-- display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
		-- layer:setTag(tag)
		-- uiMgr:GetCurrentScene():AddDialog(layer)
		local CardManualMediator = require( 'Game.mediator.CardManualMediator' )
		local mediator = CardManualMediator.new({tag = tag, cardId = cardId, breakLevel = nil ~= cardData and checkint(cardData.breakLevel) or 0})
		AppFacade.GetInstance():RegistMediator(mediator)
	end

	
end
---------------------------------------------------
-- touch logic end --
---------------------------------------------------
function CardManualPopup:onCleanup()
	AppFacade.GetInstance():UnRegsitMediator("HandbookMediator")
end



return CardManualPopup
