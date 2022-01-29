--[[
市场售后模块view
--]]
local MarketRecordView = class('MarketRecordView', function ()
	local node = CLayout:create(cc.size(1082, 641))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.MarketRecordView'
	node:enableNodeEvents()
	return node
end)

local function CreateView( )
	local size = cc.size(1082, 641)
	local view = CLayout:create(size)
	view:setAnchorPoint(0, 0)
	-- 顶部向导栏
	local guideBar = display.newImageView(_res('ui/home/market/market_result_bar_list.png'), size.width/2, 538, {ap = cc.p(0.5, 0)})
	view:addChild(guideBar, 10)
	local nameTable = {
		{name = __('物品'), x = 163},
		{name = __('物品价格'), x = 410},
		{name = __('剩余时间'), x = 604},
		{name = __('状态'), x = 828}
	}
	for i=1, #nameTable do
		local nameLabel = display.newLabel(nameTable[i].x, 17, {text = nameTable[i].name, fontSize = 22, color = '#ffffff'})
		guideBar:addChild(nameLabel)
	end
	-- 寄售列表
	local gridViewSize = cc.size(968, 514)
	local cellSize = cc.size(964, 108)
	local consignmentGridView = CGridView:create(gridViewSize)
	consignmentGridView:setAnchorPoint(cc.p(0.5, 0))
	consignmentGridView:setPosition(cc.p(size.width / 2, 25))
	view:addChild(consignmentGridView, 10)
	consignmentGridView:setSizeOfCell(cellSize)
	consignmentGridView:setColumns(1)
	return {
		view           		= view,
		guideBar       		= guideBar,
		consignmentGridView = consignmentGridView
	}
end

function MarketRecordView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(cc.p(0, 0))
end

return MarketRecordView
