--[[
餐厅信息页面UI
--]]
---@class FishingInformationView
local FishingInformationView = class('FishingInformationView', function()
    local node = CLayout:create(display.size)
    node.name = 'common.FishingInformationView'
    node:enableNodeEvents()
    return node
end)
local  RES_DICT = {
    COMMON_BG = 'ui/common/common_bg_13.png' ,
}
function FishingInformationView:ctor( ... )
    self.viewData = nil
    local function CreateView()
        -- bg
        local bg = display.newImageView(_res(RES_DICT.COMMON_BG), 0, 0)
        local bgSize = bg:getContentSize()
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(bgSize)
        mask:setAnchorPoint(cc.p(0.5, 0.5))
        mask:setPosition(display.center)
        self:addChild(mask)
        -- bg view
        local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
        view:setPosition(display.center)
        self:addChild(view)
        display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
        view:addChild(bg, 5)
        local titleBg = display.newButton(bgSize.width/2, bgSize.height - 8, {n = _res('ui/common/common_bg_title_2.png'), enable = false})
        display.commonUIParams(titleBg, {ap = display.CENTER_TOP})
        display.commonLabelParams(titleBg, fontWithColor(1,{fontSize = 24, text = __('钓场信息'), color = 'ffffff',offset = cc.p(0, -2)}))
        view:addChild(titleBg, 5)
        local gridViewSize = cc.size(226, 550)
        local gridViewCellSize = cc.size(226, 90)
        local gridView = CGridView:create(gridViewSize)
        gridView:setSizeOfCell(gridViewCellSize)
        gridView:setColumns(1)
        gridView:setAutoRelocate(true)
        gridView:setBounceable(false)
        view:addChild(gridView, 5)
        gridView:setAnchorPoint(cc.p(0, 1))
        gridView:setPosition(cc.p(50, 580))
        local showLayout = CLayout:create(cc.size(753, 556))
        showLayout:setAnchorPoint(cc.p(0, 0))
        showLayout:setPosition(cc.p(280, 22))
        view:addChild(showLayout, 5)
        return {
            view        = view,
            gridView    = gridView,
            showLayout  = showLayout
        }
    end
    xTry(function ( )
        -- eaterLayer
        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setContentSize(display.size)
        eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
        eaterLayer:setPosition(cc.p(display.cx, display.height))
        self:addChild(eaterLayer, -10)
        self.viewData = CreateView( )
        self.viewData.eaterLayer = eaterLayer
    end, __G__TRACKBACK__)
end

return FishingInformationView