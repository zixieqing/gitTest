--[[
 * author : liuzhipeng
 * descpt : 新游戏商店 - 记忆商店View
]]
local MemoryStoreView = class('MemoryStoreView', function()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.stores.MemoryStoreView'
    node:enableNodeEvents()
    return node
end)
local STORE_TAB_DEFINE = {
    {title = __('餐厅记忆'), type = CardUtils.QUALITY_TYPE.N},
    {title = __('冒险记忆'), type = CardUtils.QUALITY_TYPE.SP}
}
local RES_DICT = {
    BG_FRAME      = _res('ui/home/union/guild_shop_bg.png'),
    VIEW_FRAME    = _res('ui/home/union/guild_shop_bg_white.png'),
    COMMON_BTN    = _res('ui/common/common_btn_orange.png'),
    FUSION_BTN_N  = _res('ui/stores/memory/shop_btn_fusing.png'),
    FUSION_BTN_D  = _res('ui/stores/memory/shop_btn_fusing_disabled.png'),
    DESCRIBE_BG   = _res("ui/backpack/bag_bg_describe_1.png"),
    LIST_BG       = _res("ui/common/common_bg_goods.png"), 
    TITLE_BG      = _res('ui/common/common_bg_title_2.png'),
    TAB_BG_N      = _res('ui/common/common_btn_tab_default.png'),
    TAB_BG_S      = _res('ui/common/common_btn_tab_select.png'),
}
function MemoryStoreView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function MemoryStoreView:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.BG_FRAME, 0, 0)
    	local size = bg:getContentSize()
        local view = CLayout:create(size)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- CommonMoneyBar
	    local moneyBar = require("common.CommonMoneyBar").new()
		self:addChild(moneyBar, 20)
        -- mask --
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- mask --

        -- 标题
        local titleLabel = display.newButton(size.width / 2, size.height - 25, {n = RES_DICT.TITLE_BG})
        display.commonLabelParams(titleLabel, fontWithColor(3, {text = __('记忆商店')}))
        view:addChild(titleLabel, 5)
        -- 道具背景
        local goodsBg = display.newImageView(RES_DICT.VIEW_FRAME, size.width / 2, size.height / 2 - 7)
        view:addChild(goodsBg, 2)
        -- 快速购买
        local batchBuyBtn = display.newButton(size.width - 230, size.height - 85, {n = RES_DICT.COMMON_BTN})
        display.commonLabelParams(batchBuyBtn, fontWithColor(14, {text =__('快速购买'), fontSize = 22}))
        view:addChild(batchBuyBtn, 5)
        -- 融合
        local fusionBtn = display.newButton(size.width - 125, size.height - 85, {n = RES_DICT.FUSION_BTN_N})
        view:addChild(fusionBtn, 5)
        -- 倒计时
        local countDownLabel = display.newLabel(size.width - 310, size.height - 85, fontWithColor(16, {text = '', ap = display.RIGHT_CENTER}))
        view:addChild(countDownLabel, 5)
        -- 商店页签
        local tabList = {}
        for i, v in ipairs(STORE_TAB_DEFINE) do
            local tabBtn = display.newButton(175 + (i - 1) * 145, size.height - 94, {n = RES_DICT.TAB_BG_N})
            view:addChild(tabBtn, 5)
            tabBtn:setTag(v.type)
            display.commonLabelParams(tabBtn, fontWithColor(14, {text = v.title, fontSize = 22}))
            table.insert(tabList, tabBtn)
        end
        -- 列表背景
        local listSize = cc.size(1044, 508)
        local listCellSize = cc.size((listSize.width - 8)/5, listSize.height*0.55)
        local listBg = display.newImageView(RES_DICT.LIST_BG, size.width / 2, size.height / 2 - 36, {size = listSize, scale9 = true})
        view:addChild(listBg, 2)
        -- 道具列表
        local gridView = CGridView:create(cc.size(listSize.width - 8, listSize.height - 2))
        gridView:setSizeOfCell(listCellSize)
        gridView:setColumns(5)
        view:addChild(gridView, 5)
        gridView:setAnchorPoint(display.CENTER_BOTTOM)
        gridView:setPosition(cc.p(size.width/2, 45))
        return {
            view                = view,
            moneyBar            = moneyBar,
            batchBuyBtn         = batchBuyBtn,
            fusionBtn           = fusionBtn,
            listCellSize        = listCellSize,
            gridView            = gridView,
            tabList             = tabList,
            countDownLabel      = countDownLabel,
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(cc.p(display.cx, display.cy - 25))
    end, __G__TRACKBACK__)
end
--[[
初始化货币栏
--]]
function MemoryStoreView:InitMoneyBar( moneyIdMap )
    local viewData = self:GetViewData()
    viewData.moneyBar:reloadMoneyBar(moneyIdMap, false, {
        [moneyIdMap[1]] = {hidePlus = true, disable = true},
        [DIAMOND_ID] = {hidePlus = true, disable = true}
    })
end
--[[
刷新列表
@params products list 商品列表
--]]
function MemoryStoreView:RefreshList( products )
    local viewData = self:GetViewData()
    viewData.gridView:setCountOfCell(#products)
    viewData.gridView:reloadData()
end
--[[
刷新商品列表   
--]]
function MemoryStoreView:GridViewReload()
    local viewData = self:GetViewData()
    viewData.gridView:reloadData()
end
--[[
刷新页签
--]]
function MemoryStoreView:RefreshTab( type )
    local viewData = self:GetViewData()
    local index = 1
    for i, v in ipairs(STORE_TAB_DEFINE) do
        if type == v.type then
            index = i
            break
        end
    end
    for i, v in ipairs(viewData.tabList) do
        if i == index then
            v:setNormalImage(RES_DICT.TAB_BG_S)
            v:setSelectedImage(RES_DICT.TAB_BG_S)
        else
            v:setNormalImage(RES_DICT.TAB_BG_N)
            v:setSelectedImage(RES_DICT.TAB_BG_N)
        end
    end
end
--[[
刷新倒计时
@params leftSeconds int 剩余秒数
--]]
function MemoryStoreView:RefreshCountDownLabel( leftSeconds )
    local viewData = self:GetViewData()
    viewData.countDownLabel:setString(string.fmt(__('商品刷新倒计时：_time_'), {_time_ = CommonUtils.getTimeFormatByType(leftSeconds, 3)}))
end
--[[
获取viewData
--]]
function MemoryStoreView:GetViewData()
    return self.viewData
end
return MemoryStoreView
                                                                                                                                                                                