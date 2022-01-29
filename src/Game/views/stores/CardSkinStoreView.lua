--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 卡皮商店视图
]]
local DiamondStoreView   = class('DiamondStoreView', function()
    return display.newLayer(0, 0, {name = 'Game.views.stores.DiamondStoreView'})
end)

local RES_DICT = {
    PROMOTE_BG = _res('ui/stores/cardSkin/shop_skin_ad_share.png'),
}

local CreateView = nil


function DiamondStoreView:ctor(size)
    self:setContentSize(size)

    -- create view
    self.viewData_ = CreateView(size)
    self:addChild(self.viewData_.view)
end


CreateView = function(size)
    local view = display.newLayer(0, 0, {size = size})

    local isRecommendOpen = app.gameMgr:GetUserInfo().isRecommendOpen
    local offsetY = size.height
    if isRecommendOpen then
        --推广员是打开的建立页面最上方的条
        local promoterView = CLayout:create(cc.size(size.width, 80))
        promoterView:setPosition(cc.p(size.width * 0.5, offsetY - 40))
        view:addChild(promoterView)
        offsetY = offsetY - 80
        local adBg = display.newImageView(RES_DICT.PROMOTE_BG,size.width * 0.5, 40)
        promoterView:addChild(adBg)

        local promoterBtn = display.newButton(size.width - 30, 40, {ap = cc.p(1, 0.5), n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png')})
        display.commonLabelParams(promoterBtn, fontWithColor(18, {text = __('推广员')}))
        promoterView:addChild(promoterBtn)
        display.commonUIParams(promoterBtn, {cb = function ()
        local PromotersMediator = require( 'Game.mediator.PromotersMediator' )
        local mediator = PromotersMediator.new()
            AppFacade.GetInstance():RegistMediator(mediator)
        end})
    end

    --添加列表功能
    local taskListSize = cc.size(1078, 558)
    local taskListCellSize = cc.size(234 , 558)

    local gridView = CTableView:create(taskListSize)
    gridView:setName('gridView')
    gridView:setSizeOfCell(taskListCellSize)
    gridView:setAutoRelocate(true)
    gridView:setDirection(eScrollViewDirectionHorizontal)
    view:addChild(gridView,2)
    gridView:setAnchorPoint(cc.p(0.5, 0))
    -- gridView:setDragable(false)
    -- gridView:setPosition(cc.p(42, 20))
    -- local gridView = CGridView:create(taskListSize)
    -- gridView:setSizeOfCell(taskListCellSize)
    -- gridView:setColumns(4)
    -- gridView:setAutoRelocate(true)
    -- view:addChild(gridView,2)
    -- gridView:setAnchorPoint(cc.p(0.5, 0.5))
    if isRecommendOpen then
        gridView:setPosition(cc.p(size.width * 0.5 , 10))
    else
        gridView:setPosition(cc.p(size.width * 0.5 , 40))
    end
    -- gridView:setBackgroundColor(cc.c4b(200, 0, 0, 100))
    return {
        view      = view,
        gridView  = gridView,
    }
end


function DiamondStoreView:getViewData()
    return self.viewData_
end


return DiamondStoreView
