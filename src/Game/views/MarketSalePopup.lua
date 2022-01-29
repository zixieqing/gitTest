--[[
市场出售界面
--]]
local CommonDialog = require('common.CommonDialog')
local MarketSalePopup = class('MarketSalePopup', CommonDialog)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function MarketSalePopup:InitialUI()
	local data = self.args.data
	local goodsData = CommonUtils.GetConfig('goods', 'goods', data.goodsId)
	local function CreateView()
		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_9.png'), 0, 0)
		local bgSize = bg:getContentSize()
		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)
		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
		display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5)})
		display.commonLabelParams(titleBg,
			{text = __('出售'),
			fontSize = fontWithColor('3').fontSize, color = fontWithColor('3').color,
			offset = cc.p(0, -2)})
		bg:addChild(titleBg)
		-- 物品
		local goodsBg = display.newImageView(_res('ui/common/common_frame_goods_' .. goodsData.quality .. '.png'), bgSize.width/2, 384, {ap = cc.p(0.5, 0), scale9 = true, size = cc.size(93, 93)})
		view:addChild(goodsBg, 10)
		local goodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(data.goodsId), goodsBg:getContentSize().width/2, goodsBg:getContentSize().height/2)
		goodsBg:addChild(goodsIcon, 10)
		goodsIcon:setScale(0.5)
		local goodsName = display.newLabel(bgSize.width/2, 350, {ap = cc.p(0.5, 0), text = goodsData.name, fontSize = fontWithColor('4').fontSize, color = fontWithColor('4').color})
		view:addChild(goodsName, 10)
		-- 出售数量
		local saleNumLabelBg = display.newImageView(_res('ui/home/market/market_bg_bag_num.png'), 37, 316, {ap = cc.p(0, 0.5), scale9 = true, size = cc.size(188, 31)})
		view:addChild(saleNumLabelBg, 10)
		local saleNumLabel = display.newLabel(saleNumLabelBg:getContentSize().width/2, saleNumLabelBg:getContentSize().height/2, {text = __('出售数量'), fontSize = fontWithColor('14').fontSize, color = fontWithColor('14').color})
		saleNumLabelBg:addChild(saleNumLabel)
		local saleNumBg = display.newImageView(_res('ui/home/market/market_buy_bg_info.png'), 236, 316, {ap = cc.p(0, 0.5), scale9 = true, size = cc.size(180, 44)})
		view:addChild(saleNumBg, 10)
		local saleNum = display.newLabel(saleNumBg:getContentSize().width/2, saleNumBg:getContentSize().height/2, {text = data.num, fontSize = fontWithColor('10').fontSize, color = fontWithColor('10').color})
		saleNumBg:addChild(saleNum)
		-- 单价
		local univalentLabelBg = display.newImageView(_res('ui/home/market/market_bg_bag_num.png'), 37, 240, {ap = cc.p(0, 0.5), scale9 = true, size = cc.size(188, 31)})
		view:addChild(univalentLabelBg, 10)
		local univalentLabel = display.newLabel(univalentLabelBg:getContentSize().width/2, univalentLabelBg:getContentSize().height/2, {text = __('单价'), fontSize = fontWithColor('14').fontSize, color = fontWithColor('14').color})
		univalentLabelBg:addChild(univalentLabel)
		local univalentNumBg = display.newImageView(_res('ui/home/market/market_buy_bg_info.png'), 236, 240, {ap = cc.p(0, 0.5), scale9 = true, size = cc.size(180, 44)})
		view:addChild(univalentNumBg, 10)
		local univalentNum = display.newLabel(univalentNumBg:getContentSize().width*0.4, univalentNumBg:getContentSize().height/2, {text = tostring(data.price/data.num), fontSize = fontWithColor('10').fontSize, color = fontWithColor('10').color})
		univalentNumBg:addChild(univalentNum)
		local univalentSelectBtn = display.newButton(393, 240, {tag = 3101, n = _res('ui/home/market/market_sold_btn_up_info.png'), scale9 = true, size = cc.size(44, 42)})
		view:addChild(univalentSelectBtn, 10)
		univalentSelectBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
		-- 总价
		local totalLabelBg = display.newImageView(_res('ui/home/market/market_bg_bag_num.png'), 37, 168, {ap = cc.p(0, 0.5), scale9 = true, size = cc.size(188, 31)})
		view:addChild(totalLabelBg, 10)
		local totalLabel = display.newLabel(totalLabelBg:getContentSize().width/2, totalLabelBg:getContentSize().height/2, {text = __('总价'), fontSize = fontWithColor('14').fontSize, color = fontWithColor('14').color})
		totalLabelBg:addChild(totalLabel)
		local totalNumBg = display.newImageView(_res('ui/home/market/market_buy_bg_info.png'), 236, 168, {ap = cc.p(0, 0.5), scale9 = true, size = cc.size(180, 44)})
		view:addChild(totalNumBg, 10)
		local totalNum = display.newLabel(totalNumBg:getContentSize().width*0.5, totalNumBg:getContentSize().height/2, {text = data.price, fontSize = fontWithColor('10').fontSize, color = fontWithColor('10').color})
		totalNumBg:addChild(totalNum)
		-- button
		local consignmentBtn = display.newButton(bgSize.width/2, 28, {n = _res('ui/common/common_btn_orange.png'), ap = cc.p(0.5, 0), scale9 = true, size = cc.size(120, 54), tag = 3102})
		view:addChild(consignmentBtn, 10)
		display.commonLabelParams(consignmentBtn, fontWithColor(14, {text = __('寄售')}))
		consignmentBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))

		return {
			view    	 = view,
			univalentNum = univalentNum,
			totalNum 	= totalNum
		}
	end
	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)
end
--[[
按钮回调
tag {
	3101 -- 上拉按钮
	3102 -- 寄售按钮
}
--]]
function MarketSalePopup:ButtonCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local data = self.args.data
	local goodsData = CommonUtils.GetConfig('goods', 'goods', data.goodsId)
	if tag == 3101 then
		local auctionPrice = goodsData.auctionPrice
		local viewData = self.viewData
		if viewData.view:getChildByTag(6666) then
			viewData.view:getChildByTag(6666):runAction(cc.RemoveSelf:create())
		else
			local size = cc.size(190, #auctionPrice * 40)
			local layout = CLayout:create(size)
			-- viewData.view:addChild(layout, 15)
			layout:setAnchorPoint(cc.p(0, 0))
			-- layout:setPosition(230, 270)
			layout:setPosition(cc.p(0, 0))
			-- layout:setTag(6666)
			local bg = display.newImageView(_res('ui/home/market/market_sold_selection_frame_1.png'), 0, 0, {ap = cc.p(0, 0), scale9 = true, size = size})
			layout:addChild(bg)
			for i,v in ipairs(auctionPrice) do
				local btn = display.newButton(layout:getContentSize().width/2, 40*(i), {tag = i, ap = cc.p(0.5, 1), scale9 = true, size = cc.size(130, 40)})
				display.commonLabelParams(btn, fontWithColor(16, {text = tostring(v)}))
				layout:addChild(btn)
				btn:setOnClickScriptHandler(handler(self, self.SelectPriceBtnCallback))
				if i < #auctionPrice then
					local line = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_line.png'), layout:getContentSize().width/2, 40*i+28)
					layout:addChild(line, 10)
				end
			end
			layout:setScaleY(0)
			layout:runAction(cc.ScaleTo:create(0.1, 1))
			-------------------------------
			local listView = CListView:create(cc.size(size.width, size.height - 125))
			listView:setDirection(eScrollViewDirectionVertical)
			listView:setTag(6666)
			listView:setBounceable(false)
			viewData.view:addChild(listView, 15)
			listView:setAnchorPoint(cc.p(0, 0))
			listView:setPosition(cc.p(230, 270))
			listView:insertNodeAtLast(layout)
			listView:reloadData()
			-------------------------------
		end
	elseif tag == 3102 then -- 寄售
		local viewData = self.viewData
		local price = tonumber(viewData.univalentNum:getString())
		local mediator = AppFacade.GetInstance():RetrieveMediator(self.args.mediatorName)
		mediator:SendSignal(COMMANDS.COMMAND_Market_ConsignmentAgain, {marketId = data.id, price = price, time = 4})
	end
end
--[[
选择价格按钮回调
--]]
function MarketSalePopup:SelectPriceBtnCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local data = self.args.data
	local goodsData = CommonUtils.GetConfig('goods', 'goods', data.goodsId)
	local viewData = self.viewData
	viewData.univalentNum:setString(tostring(goodsData.auctionPrice[tag]))
	viewData.totalNum:setString(tostring(goodsData.auctionPrice[tag]*data.num))
	viewData.view:getChildByTag(6666):runAction(cc.RemoveSelf:create())
end
return MarketSalePopup