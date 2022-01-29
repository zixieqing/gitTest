--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动 商城View
--]]
local AssemblyActivityStoreView = class('AssemblyActivityStoreView', function ()
    local node = CLayout:create(display.size)
    node.name = 'activity.assemblyActivity.AssemblyActivityStoreView'
    node:enableNodeEvents()
    return node
end)

local STORE_TAB_DEFINE = {
    {title = __('幻晶石购买'),  type = 1},
    {title = __('礼包购买'), type = 2}
}

local RES_DICT = {
    BG_FRAME              = _res('ui/home/union/guild_shop_bg.png'),
    BG_CENTER             = _res('ui/home/union/guild_shop_bg_white.png'),
    TITLE_BG              = _res('ui/home/union/guild_shop_title.png'),
    TAB_BG_N              = _res('ui/common/common_btn_tab_default.png'),
    TAB_BG_S              = _res('ui/common/common_btn_tab_select.png'),
    LIST_BG               = _res("ui/common/common_bg_goods.png"), 
}

function AssemblyActivityStoreView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function AssemblyActivityStoreView:InitUI()
    local function CreateView()
        local bgFrame = display.newImageView(RES_DICT.BG_FRAME, 0, 0)
        local size = bgFrame:getContentSize()
        local view = CLayout:create(size)
        bgFrame:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bgFrame, 1)
        local bgCenter = display.newImageView(RES_DICT.BG_CENTER, size.width / 2, size.height / 2 - 25)
        view:addChild(bgCenter, 1)
        local bgCenterSize = bgCenter:getContentSize()
        -- CommonMoneyBar
	    local moneyBar = require("common.CommonMoneyBar").new()
		self:addChild(moneyBar, 20)
        -- mask --
        local mask = display.newLayer(bgCenterSize.width/2 ,bgCenterSize.height/2 ,{ap = display.CENTER , size = bgCenterSize, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- mask --
        
        -- 标题
        local titleBg = display.newImageView(RES_DICT.TITLE_BG, size.width / 2, size.height - 25)
        view:addChild(titleBg, 5)
        local titleLabel = display.newLabel(titleBg:getContentSize().width / 2, titleBg:getContentSize().height / 2, fontWithColor(18, {text = __("商店")}))
        titleBg:addChild(titleLabel, 1)
        -- 商店页签
        local tabList = {}
        for i, v in ipairs(STORE_TAB_DEFINE) do
            local tabBtn = display.newButton(230 + (i - 1) * 252, size.height - 110, {n = RES_DICT.TAB_BG_N, scale9 = true, size = cc.size(248, 44)})
            view:addChild(tabBtn, 5)
            tabBtn:setTag(v.type)
            display.commonLabelParams(tabBtn, fontWithColor(14, {text = v.title, fontSize = 22}))
            table.insert(tabList, tabBtn)
        end
        -- 列表背景
        local listSize = cc.size(1064, 508)
        local listBg = display.newImageView(RES_DICT.LIST_BG, size.width / 2, size.height / 2 - 50, {size = listSize, scale9 = true})
        view:addChild(listBg, 2)
        local listLayout = CLayout:create(listSize)
        listLayout:setPosition(size.width / 2, size.height / 2 - 50)
        view:addChild(listLayout, 2)

        return {
            view                = view,
            moneyBar            = moneyBar,
            listSize            = listSize,
            listBg              = listBg,
            tabList             = tabList,
            listLayout          = listLayout,
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(cc.p(display.width / 2, display.height / 2 - 20))
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
进入动画
--]]
function AssemblyActivityStoreView:EnterAction(  )
    local viewData = self:GetViewData()
    viewData.view:setOpacity(255 * 0.3)
    viewData.view:runAction(
        cc.FadeIn:create(0.2)
    )
end
--[[
关闭动画
--]]
function AssemblyActivityStoreView:CloseAction()
    local viewData = self:GetViewData()
    viewData.view:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0.2),
            cc.CallFunc:create(function()
                local scene = app.uiMgr:GetCurrentScene()
                scene:RemoveDialog(self)
            end)
        )
    )
end
--[[
初始化货币栏
--]]
function AssemblyActivityStoreView:InitMoneyBar( moneyIdMap )
    local viewData = self:GetViewData()
    viewData.moneyBar:reloadMoneyBar(moneyIdMap, false)
end
--[[
刷新列表
@params products list 商品列表
--]]
function AssemblyActivityStoreView:RefreshList( products )
    local viewData = self:GetViewData()
    viewData.gridView:setCountOfCell(#products)
    viewData.gridView:reloadData()
end
--[[
刷新商品列表   
--]]
function AssemblyActivityStoreView:GridViewReload()
    local viewData = self:GetViewData()
    viewData.gridView:reloadData()
end
--[[
刷新页签
--]]
function AssemblyActivityStoreView:RefreshTab( type )
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
获取viewData
--]]
function AssemblyActivityStoreView:GetViewData()
    return self.viewData
end
return AssemblyActivityStoreView