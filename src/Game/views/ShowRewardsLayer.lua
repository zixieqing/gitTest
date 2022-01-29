--[[

--]]
local GameScene = require( "Frame.GameScene" )
local ShowRewardsLayer = class('ShowRewardsLayer', function()
    local clb = CLayout:create(cc.size(display.width,display.height))
    clb.name = 'Game.views.ShowRewardsLayer'
    clb:enableNodeEvents()
    return clb
end)

local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local RES_DICT = {
	BG 					= 'ui/common/common_bg_4.png',
	BG_UP 				= 'ui/common/common_bg_title_2.png',
	BG_CARD_DEFAULT 	= 'ui/home/teamformation/choosehero/card_order_ico_default.png',
	BG_CARD_SELECTED	= 'ui/home/teamformation/choosehero/card_order_ico_selected.png',
	BTN_BG				= 'ui/home/teamformation/choosehero/team_btn_screen_white.png',
	SORT_BG				= 'ui/home/teamformation/choosehero/team_sort_bg.png',
	IMG_LINE			= 'ui/home/teamformation/choosehero/team_sort_ico_line.png',
	IMG_CHOOSE_DEFAULT	= 'ui/home/teamformation/choosehero/team_sort_ico_point_unselected.png',
	IMG_CHOOSE_SELECTED = 'ui/home/teamformation/choosehero/team_sort_ico_point_selected.png',
}


function ShowRewardsLayer:ctor( ... )
	local arg = unpack({...})
    self.datas = arg
    if arg.callback then self.callback = arg.callback end
    self.clickTag = 1
	self.eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 178))
	self.eaterLayer:setTouchEnabled(true)
	self.eaterLayer:setContentSize(display.size)
	self.eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	self.eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
	self:addChild(self.eaterLayer, -1)


	local function CreateView( ... )
		local view = CLayout:create()
		local bg = display.newImageView(_res(RES_DICT.BG),{scale9 = true, size = cc.size(584, 651)})
		bg:setTouchEnabled(true)
		view:addChild(bg)

		local frameSize  = bg:getContentSize()
		-- title
		local titleFont = fontWithColor(2, {color = '5b3c25',text = self.datas.name or __('皮肤礼包')})
		local titleLabel = display.newLabel(frameSize.width / 2, frameSize.height * 0.94, titleFont)
		view:addChild(titleLabel, 5)

		-- splitLine
		local splitLine = display.newImageView(_res("ui/home/commonShop/monthcard_tool_split_line.png"), frameSize.width / 2, frameSize.height * 0.9)
		view:addChild(splitLine, 5)


	    bg:setAnchorPoint(display.LEFT_BOTTOM)
	    view:setContentSize(cc.size(frameSize.width,frameSize.height))

	    local pox = frameSize.width * 0.5
	    --标题  物品名称

		local taskListSize = cc.size(frameSize.width - 10, frameSize.height -200)
		local taskListCellSize = cc.size(taskListSize.width, 100)--taskListSize.height/5

		local gridViewBg = display.newImageView(_res('ui/common/commcon_bg_text.png'), 0, 0, {scale9 = true, size = cc.size(taskListSize.width,taskListSize.height + 6)})
		display.commonUIParams(gridViewBg, {ap = cc.p(0.5,1),po = cc.p(frameSize.width * 0.5,frameSize.height - 80)})
		view:addChild(gridViewBg, bg:getLocalZOrder() + 1)

	   	local gridView = CGridView:create(taskListSize)
	    gridView:setSizeOfCell(taskListCellSize)
	    gridView:setColumns(1)
	    gridView:setAutoRelocate(false)
	    gridView:setBounceable(true)
		view:addChild(gridView, gridViewBg:getLocalZOrder() + 1)
		gridView:setAnchorPoint(cc.p(0.5, 1))
	    gridView:setPosition(cc.p(frameSize.width * 0.5,frameSize.height - 80 ))
		-- gridView:setBackgroundColor(cc.c4b(200, 0, 0, 100))



		-- 购买 取消 按钮
		local cancelBtn = display.newButton(frameSize.width * 0.3, frameSize.height * 0.1, { n = _res("ui/common/common_btn_white_default.png")})
        display.commonLabelParams(cancelBtn, fontWithColor(14, {text = __("取消")}))
        view:addChild(cancelBtn, 5)

		local buyBtn = display.newButton(frameSize.width * 0.7, frameSize.height * 0.1, { n = _res("ui/common/common_btn_orange.png")})
        local price = tostring(self.datas.price)
        if isElexSdk() then
            local sdkInstance = require("root.AppSDK").GetInstance()
            if sdkInstance.loadedProducts[tostring(self.datas.channelProductId)] then
				price = sdkInstance.loadedProducts[tostring(self.datas.channelProductId)].priceLocale
			else
				price = string.fmt( __('￥_num1_'),{ _num1_ = price})
			end
		else
			price = string.fmt( __('￥_num1_'),{ _num1_ = price})
        end
		if  CommonUtils.IsGoldSymbolToSystem() then
			CommonUtils.SetCardNameLabelStringByIdUseSysFont(buyBtn:getLabel() , nil ,{fontSizeN = 24 , colorN = 'ffffff' }, price)
		else
			display.commonLabelParams(buyBtn, fontWithColor(14, {text = price} )) 
		end
        view:addChild(buyBtn, 5)

		return {
			view 		= view,
			gridView 	= gridView,
 			buyBtn 		= buyBtn,
 			cancelBtn   = cancelBtn,
		}
	end


	self.viewData_ = CreateView()
	display.commonUIParams(self.viewData_.view, {po = display.center})
	self:addChild(self.viewData_.view,1)

	local gridView = self.viewData_.gridView
	gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
	-- gridView:setBackgroundColor(cc.c4b(200, 0, 0, 100))
	gridView:setCountOfCell(table.nums(self.datas.rewards))
	gridView:reloadData( )

	self.viewData_.buyBtn:setOnClickScriptHandler(function()
		if self.callback then
			self.callback()
		end
		self:runAction(cc.RemoveSelf:create())
	end)
	self.viewData_.cancelBtn:setOnClickScriptHandler(function()
		self:runAction(cc.RemoveSelf:create())
	end)
	self.eaterLayer:setOnClickScriptHandler(function()
		self:runAction(cc.RemoveSelf:create())
	end)

end

function ShowRewardsLayer:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local index = idx + 1
    local goodsNode = nil
    local tempBtn = nil
    local tempLabel = nil
    local size = self.viewData_.gridView:getSizeOfCell()
   	local data =  self.datas.rewards[index]
   	local localData = CommonUtils.GetConfig('goods', 'goods', data.goodsId) or {}
    if nil ==  pCell  then
		pCell = CGridViewCell:new()
		pCell:setContentSize(size)
		-- pCell:setBackgroundColor(cc.c4b(200, 0, 0, 100))

		local goodsNode = require('common.GoodNode').new({id = data.goodsId, amount = data.num, showAmount = true,callBack = function( sender )
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
		end})
		pCell:addChild(goodsNode, 5)
		goodsNode:setTag(123)
		goodsNode:setPosition(cc.p(size.width*0.35,size.height*0.5))
		goodsNode:setScale(0.8)

	    local cutLine = display.newImageView(_res('ui/common/common_tips_line.png'), size.width*0.5, 2, {scale9 = true, size = cc.size(size.width - 40, 2)})
		pCell:addChild(cutLine)

		local text = string.format('%s*%d', tostring(localData.name), data.num)
	    tempLabel = display.newLabel(size.width*0.5 - 20, size.height*0.5, fontWithColor(16, {text = text,ap = cc.p(0,0.5)}))
   		pCell:addChild(tempLabel)
   		tempLabel:setTag(456)
    else
    	goodsNode = pCell:getChildByTag(123)
    	goodsNode:RefreshSelf(data)
		goodsNode.callBack = function(goodsNode)
			uiMgr:ShowInformationTipsBoard({targetNode = goodsNode, iconId = data.goodsId, type = 1})
		end
    	local text = string.format('%s*%d', tostring(localData.name), data.num)
    	tempLabel = pCell:getChildByTag(456)
    	tempLabel:setString(text)
    end

    return pCell
end

return ShowRewardsLayer
