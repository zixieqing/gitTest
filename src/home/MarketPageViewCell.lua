local MarketPageViewCell = class('MarketPageViewCell', function ()
	local node = CPageViewCell:new()
    node.name = 'Game.views.MarketPageViewCell'
    return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local marketPurchaseCell = require('home.MarketPurchaseCell')
function MarketPageViewCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self.pageSize = size
	self.marketDatas = nil
	self:setContentSize(size)

    self.layout = CLayout:create(size)
    self.layout:setPosition(utils.getLocalCenter(self))
    self:addChild(self.layout)
	local gridViewSize = cc.size(size.width - 6, size.height - 6)
	local cellSize = cc.size(gridViewSize.width/3, gridViewSize.height/4)
	self.gridView = CGridView:create(gridViewSize)
	self.gridView:setAnchorPoint(cc.p(0.5, 0.5))
	self.gridView:setPosition(cc.p(size.width/2, size.height/2))
	self.layout:addChild(self.gridView, 10)
	self.gridView:setSizeOfCell(cellSize)
	self.gridView:setColumns(3)
	self.gridView:setBounceable(false)
	self.gridView:setDataSourceAdapterScriptHandler(handler(self, self.PurchaseGridViewDataSource))
end
function MarketPageViewCell:ReloadGridView( marketDatas )
	self.marketDatas = marketDatas
	self.gridView:setCountOfCell(#self.marketDatas)
	self.gridView:reloadData()
end
function MarketPageViewCell:PurchaseGridViewDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    if not pCell then
		pCell = marketPurchaseCell.new(cc.size((self.pageSize.width-6)/3, (self.pageSize.height-6)/4))
		pCell.bg:setOnClickScriptHandler(handler(self, self.GridViewCellCallback))
    end
	xTry(function()
		local data = self.marketDatas[index]
		local goodsData = CommonUtils.GetConfig('goods', 'goods', data.goodsId)
		pCell.nameLabel:setString(goodsData.name)
		pCell.goodsFrame:setTexture(_res('ui/common/common_frame_goods_' .. goodsData.quality .. '.png'))
		pCell.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(data.goodsId))
		pCell.numLabel:setString(tostring(data.num))
		display.reloadRichLabel(pCell.priceLabel, {c = {
			{text = string.fmt(__('售价:_num_'), {['_num_'] = tostring(data.price)}), fontSize = fontWithColor('4').fontSize, color = fontWithColor('4').color},
			{img = _res('arts/goods/goods_icon_' .. GOLD_ID .. '.png'), scale = 0.2}
		}})
		-- 判断物品是否售出
		if data.status == 1 then
			pCell.saleImg:setVisible(false)
			pCell.bg:setEnabled(true)
		elseif data.status == 2 then
			pCell.saleImg:setVisible(true)
			pCell.bg:setEnabled(false)
		end
		pCell.bg:setTag(index)
	end,__G__TRACKBACK__)	
	return pCell
end
function MarketPageViewCell:GridViewCellCallback( sender )
	local tag = sender:getTag()
	local scene = uiMgr:GetCurrentScene() 
	local marketPurchasePopup  = require('Game.views.MarketPurchasePopup').new({tag = 5001, mediatorName = "MarketPurchaseMediator", data = self.marketDatas[tag], btnTag = tag})
	display.commonUIParams(marketPurchasePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	marketPurchasePopup:setTag(5001)
	scene:AddDialog(marketPurchasePopup)
end

return MarketPageViewCell
