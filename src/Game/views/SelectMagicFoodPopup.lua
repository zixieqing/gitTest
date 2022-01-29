--[[
选择魔法食物弹窗
@params table {
	mediatorName string parent mediator name
	tag int self tag
	equipedMagicFoodId int 已装备的魔法食物id
	equipCallback function 装备魔法食物事件回调
}
--]]
local CommonDialog = require('common.CommonDialog')
local SelectMagicFoodPopup = class('SelectMagicFoodPopup', CommonDialog)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

--[[
override
initui
--]]
function SelectMagicFoodPopup:InitialUI()
-- 	local magicFoodData = {
-- 	{goodsId = 180004, amount = 57},
-- 	{goodsId = 180005, amount = 44},
-- 	{goodsId = 180006, amount = 33},
-- 	{goodsId = 180007, amount = 22},
-- 	{goodsId = 180008, amount = 11},
-- 	{goodsId = 180009, amount = 1},


-- }
	local magicFoodData = gameMgr:GetAllGoodsDataByGoodsType(GoodsType.TYPE_MAGIC_FOOD)
	-- 移除大力丸
	-- print(self.args.equipedMagicFoodId)
	self.equipIdx = nil
	for i = table.nums(magicFoodData), 1, -1 do
		local goodsConf = CommonUtils.GetConfig('goods', 'magicFood', magicFoodData[i].goodsId)
		if self.args.equipedMagicFoodId and self.args.equipedMagicFoodId == magicFoodData[i].goodsId then
			self.equipIdx = i
		end
		if goodsConf and 2 ~= checkint(goodsConf.magicFoodType) then
			if self.equipIdx and self.equipIdx > i then
				self.equipIdx = self.equipIdx - 1
			end
			table.remove(magicFoodData, i)
		end
	end
	-- print(self.equipIdx, 'aaaaaaaaaa')
	self.magicFoodData = magicFoodData
	self.selectedIdx = 0

	local function CreateView()

		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_5.png'), 0, 0)
		local bgSize = bg:getContentSize()

		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)

		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
		display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5)})
		display.commonLabelParams(titleBg,
			{text = __('堕神诱饵'),
			fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color,
			offset = cc.p(0, -2)})
		bg:addChild(titleBg)

		-- -- close btn
		-- local closeBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_quit.png'), animaion = false, cb = handler(self, self.CloseHandler)})
		-- display.commonUIParams(closeBtn, {po = cc.p(bgSize.width - 10 + closeBtn:getContentSize().width * 0.5, bgSize.height - closeBtn:getContentSize().height * 0.5 - 3)})
		-- view:addChild(closeBtn, 4)

		-- 可选道具
		local goodsGridView = nil
		local cellSize = cc.size(0, 0)
		-- 有可选道具
		local gridViewBg = display.newImageView(_res('ui/backpack/bag_bg_frame_gray_1.png'),
			bgSize.width * 0.75 - 15, bgSize.height * 0.473)
		view:addChild(gridViewBg, 6)
		local gridViewSize = cc.size(
			gridViewBg:getContentSize().width - 10,
			gridViewBg:getContentSize().height - 3)
		local goodsPerLine = 5
		cellSize = cc.size(gridViewSize.width / goodsPerLine, gridViewSize.width / goodsPerLine)
		-- 可选道具列表
		goodsGridView = CGridView:create(gridViewSize)
		-- goodsGridView:setBackgroundColor(cc.c4b(255, 0, 0, 128))
		goodsGridView:setAnchorPoint(cc.p(0.5, 0.5))
		goodsGridView:setPosition(cc.p(gridViewBg:getPositionX(), gridViewBg:getPositionY()))
		view:addChild(goodsGridView, 10)
		goodsGridView:setCountOfCell(table.nums(magicFoodData))
		goodsGridView:setColumns(goodsPerLine)
		goodsGridView:setSizeOfCell(cellSize)
		goodsGridView:setAutoRelocate(false)
		goodsGridView:setDataSourceAdapterScriptHandler(handler(self, self.GoodsGridViewDataAdapter))

		-- 道具说明
		local descrBg = display.newImageView(_res('ui/common/commcon_bg_text.png'), 0, 0, {scale9 = true, size = cc.size(500, 315)})
		local descrBgSize = descrBg:getContentSize()
		display.commonUIParams(descrBg,{po = cc.p(
			gridViewBg:getPositionX() - gridViewBg:getContentSize().width * 0.5 - 20 - descrBgSize.width * 0.5, bgSize.height * 0.46)})
		view:addChild(descrBg, 6)
		local descrHintLabel = display.newLabel(descrBgSize.width * 0.5, 20,
			{text = __('注：每场战斗消耗一个食物'), fontSize = 18, color = '#9c9c9c'})
		descrBg:addChild(descrHintLabel)
		local descrPadding = cc.p(20, 20)
		local descrLabel = display.newLabel(descrPadding.x, descrBgSize.height - descrPadding.y,
			{text = '',
			fontSize = 20, color = fontWithColor('TC2').color, ap = cc.p(0, 1), hAlign = display.TAL,
			w = descrBgSize.width - descrPadding.x * 2, h = descrBgSize.height - descrPadding.y * 2})
		descrBg:addChild(descrLabel)

		local descrGoodsNode = require('common.GoodNode').new({id = 0})
		display.commonUIParams(descrGoodsNode, {ap = cc.p(0, 0),
			po = cc.p(descrBg:getPositionX() - descrBgSize.width * 0.5, descrBg:getPositionY() + descrBgSize.height * 0.5 + 10)})
		view:addChild(descrGoodsNode, 6)

		local descrGoodsNameLabel = display.newRichLabel(
			descrGoodsNode:getPositionX() + descrGoodsNode:getContentSize().width + 10,
			descrGoodsNode:getPositionY() + descrGoodsNode:getContentSize().height - 20,
			{ap = cc.p(0, 0.5), c = {
			}})
		-- descrGoodsNameLabel:reloadData()
		view:addChild(descrGoodsNameLabel, 6)

		local holdAmountLabel = display.newLabel(descrGoodsNameLabel:getPositionX(), descrGoodsNameLabel:getPositionY() - 40,
			{text = __('拥有：0'), fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('LC').color, ap = descrGoodsNameLabel:getAnchorPoint()})
		view:addChild(holdAmountLabel, 6)

		local equipBtn = display.newCheckBox(0, 0, {
			n = _res('ui/common/common_btn_orange.png'),
			s = _res('ui/common/common_btn_white_default.png')})
		equipBtn:setOnClickScriptHandler(handler(self, self.EquipBtnCallback))
		display.commonUIParams(equipBtn, {po = cc.p(
			descrBg:getPositionX(),
			descrBg:getPositionY() - descrBgSize.height * 0.5 - equipBtn:getContentSize().height * 0.5 - 25)})
		view:addChild(equipBtn, 6)
		local equipBtnLabel = display.newLabel(utils.getLocalCenter(equipBtn).x, utils.getLocalCenter(equipBtn).y,
			{text = '使用', fontSize = 26, color = fontWithColor('LC').color})
		equipBtn:addChild(equipBtnLabel)

		if table.nums(magicFoodData) == 0 then
			-- 无可选道具
			descrBg:setVisible(false)
			descrGoodsNode:setVisible(false)
			descrGoodsNameLabel:setVisible(false)
			equipBtn:setVisible(false)
			gridViewBg:setVisible(false)
			goodsGridView:setVisible(false)
			holdAmountLabel:setVisible(false)
			local index = (math.random(1, 200) % 3 ) + 1
	        -- 中间小人
		    local loadingCardQ = AssetsUtils.GetCartoonNode(3, bgSize.width * 0.5, bgSize.height * 0.55)
		    view:addChild(loadingCardQ, 6)
		    loadingCardQ:setScale(0.85)
		    local hintLabel = display.newLabel(bgSize.width * 0.5, bgSize.height * 0.1,
		    	{text = __('你并没有魔法食物'), fontSize = 30, color = '#6c6c6c'})
		    view:addChild(hintLabel, 6)
		end

		return {
			view = view,
			gridCellSize = cellSize,
			goodsGridView = goodsGridView,
			gridViewBg = gridViewBg,
			descrGoodsNode = descrGoodsNode,
			descrGoodsNameLabel = descrGoodsNameLabel,
			holdAmountLabel = holdAmountLabel,
			equipBtnLabel = equipBtnLabel,
			descrLabel = descrLabel,
			equipBtn = equipBtn,
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	if table.nums(self.magicFoodData) > 0 then
		self.viewData.goodsGridView:reloadData()
		self:GoodsNodeClickHandler(1)
	end
end
--[[
gridView数据回调
--]]
function SelectMagicFoodPopup:GoodsGridViewDataAdapter(c, i)
	local cell = c
	local index = i + 1
	local goodsData = self.magicFoodData[index]
	if nil == cell then
		cell = CGridViewCell:new()
		cell:setContentSize(self.viewData.gridCellSize)
		-- cell:setBackgroundColor(cc.c4b(56, 98, math.random(255), 128))
		local goodsNode = require('common.GoodNode').new({id = goodsData.goodsId})
		goodsNode:setPosition(utils.getLocalCenter(cell))
		goodsNode:setScale((self.viewData.gridCellSize.width - 4) / goodsNode:getContentSize().width)
		cell:addChild(goodsNode)
		goodsNode:setTag(3)
		display.commonUIParams(goodsNode, {animate = false, cb = handler(self, self.GoodsNodeClickCallback)})

		-- 选中状态
		local selectedCover = display.newImageView(_res('ui/map/common_bg_list_selected.png'), utils.getLocalCenter(cell).x, utils.getLocalCenter(cell).y)
		cell:addChild(selectedCover, 15)
		selectedCover:setTag(5)
		selectedCover:setVisible(false)

		-- 数量
		local amountLabel = display.newLabel(self.viewData.gridCellSize.width - 10, 10,
			{text = tostring(goodsData.amount), fontSize = 20, color = '#ffffff', ap = cc.p(1, 0)})
		cell:addChild(amountLabel, 7)
		amountLabel:setTag(7)

		-- 装备状态
		local equipCover = display.newNSprite(_res('ui/common/common_frame_goods_lock.png'), utils.getLocalCenter(cell).x, utils.getLocalCenter(cell).y)
		equipCover:setScale(goodsNode:getScale() * 1.1)
		cell:addChild(equipCover, 10)
		equipCover:setTag(9)
		local equipLabel = display.newLabel(utils.getLocalCenter(equipCover).x, utils.getLocalCenter(equipCover).y,fontWithColor(14,
			{text = __('使用中'), fontSize = 20, color = '#ffffff'}))
		equipLabel:enableOutline(ccc4FromInt('#67403d'), 1)
		equipCover:addChild(equipLabel)
		equipCover:setVisible(false)
	end
	cell:setTag(index)
	self:RefreshGoodsNode(cell, index)

	return cell
end
--[[
刷新goodsNode
--]]
function SelectMagicFoodPopup:RefreshGoodsNode(cell, index)
	local goodsData = self.magicFoodData[index]
	local goodsNode = cell:getChildByTag(3)
	goodsNode:RefreshSelf({goodsId = goodsData.goodsId})
	if self.selectedIdx == index then
		cell:getChildByTag(5):setVisible(true)
	else
		cell:getChildByTag(5):setVisible(false)
	end
	cell:getChildByTag(7):setString(tostring(goodsData.amount))
	if self.equipIdx == index then
		cell:getChildByTag(9):setVisible(true)
	else
		cell:getChildByTag(9):setVisible(false)
	end
end
--[[
点击道具node回调
--]]
function SelectMagicFoodPopup:GoodsNodeClickCallback(sender)
	PlayAudioByClickNormal()
	local index = sender:getParent():getTag()
	self:GoodsNodeClickHandler(index)
end
--[[
点击回调函数
@params index int 点击cell序号
--]]
function SelectMagicFoodPopup:GoodsNodeClickHandler(index)
	if self.selectedIdx == index then return end
	local goodsData = self.magicFoodData[index]
	local goodsConf = CommonUtils.GetConfig('goods', 'magicFood', goodsData.goodsId)
	-- 刷新说明部分
	-- 道具图标
	self.viewData.descrGoodsNode:RefreshSelf({goodsId = goodsData.goodsId})
	-- 道具名字
	local nameTextInfo = {
		{text = goodsConf.name, fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('LC').color},
	}
	display.reloadRichLabel(self.viewData.descrGoodsNameLabel, {c = nameTextInfo})
	-- 道具说明
	self.viewData.descrLabel:setString(goodsConf.descr)
	self.viewData.holdAmountLabel:setString(string.format(__('拥有数量：%d'), goodsData.amount))
	-- 装备按钮状态
	if self.equipIdx and self.equipIdx == index then
		self.viewData.equipBtn:setChecked(true)
		self.viewData.equipBtnLabel:setString(__('移除'))
	else
		self.viewData.equipBtn:setChecked(false)
		self.viewData.equipBtnLabel:setString(__('使用'))
	end

	-- 选中状态
	local preCell = self.viewData.goodsGridView:cellAtIndex(self.selectedIdx - 1)
	if preCell then
		preCell:getChildByTag(5):setVisible(false)
	end

	local curCell = self.viewData.goodsGridView:cellAtIndex(index - 1)
	if curCell then
		curCell:getChildByTag(5):setVisible(true)
	end

	self.selectedIdx = index
end
--[[
使用按钮回调
--]]
function SelectMagicFoodPopup:EquipBtnCallback(sender)
	PlayAudioByClickNormal()
	-- 刷新前一个
	if self.equipIdx then
		local preCell = self.viewData.goodsGridView:cellAtIndex(self.equipIdx - 1)
		if preCell then
			preCell:getChildByTag(9):setVisible(false)
		end
	end
	if sender:isChecked() then
		-- 点击装备对应的食物
		self.equipIdx = self.selectedIdx
		self.viewData.equipBtnLabel:setString(__('移除'))
		local curCell = self.viewData.goodsGridView:cellAtIndex(self.equipIdx - 1)
		if curCell then
			curCell:getChildByTag(9):setVisible(true)
		end
	else
		self.equipIdx = nil
		self.viewData.equipBtnLabel:setString(__('使用'))
	end
	if self.args.equipCallback then
		xTry(function ( )
			self.args.equipCallback(checktable(self.magicFoodData[self.equipIdx]).goodsId)
		end, __G__TRACKBACK__)
	end
end


return SelectMagicFoodPopup
