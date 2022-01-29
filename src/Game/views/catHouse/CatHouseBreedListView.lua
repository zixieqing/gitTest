--[[
 * author : liuzhipeng
 * descpt : type 繁殖列表View
--]]
local CatHouseBreedListView = class('CatHouseBreedListView', function ()
    return ui.layer({name = 'Game.views.catHouse.CatHouseBreedListView', enableEvent = true, ap = display.CENTER})
end)
-------------------------------------------------
-------------------- define ---------------------
local RES_DICT = {
    LIST_BG       = _res('ui/catHouse/breed/grow_birth_list_details_bg_list.png'),
    TITLE_BG      = _res('ui/common/common_title_5.png'),

    SEARCH_ICON   = _res('ui/common/raid_boss_btn_search.png'),
    OUT_TIP_BG    = _res('ui/catHouse/chooseCat/cat_select_tips_bg.png'),
}
local CreateCatListCell = nil
-------------------- define ---------------------
-------------------------------------------------

-------------------------------------------------
-------------------- import ---------------------
local CatHeadNode = require('Game.views.catModule.cat.CatHeadNode')
-------------------- import ---------------------
-------------------------------------------------

-------------------------------------------------
------------------ inheritance ------------------
function CatHouseBreedListView:ctor( ... )
    self:InitUI()
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
init ui
--]]
function CatHouseBreedListView:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.LIST_BG, 0, 0)
        local size = bg:getContentSize()
        local view = CLayout:create(size)
        view:setAnchorPoint(display.RIGHT_CENTER)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- 标题
        local titleBg = display.newImageView(RES_DICT.TITLE_BG, size.width / 2, size.height - 14, {ap = display.CENTER_TOP})
        view:addChild(titleBg, 1)
        local titleLabel = display.newLabel(titleBg:getContentSize().width / 2, titleBg:getContentSize().height / 2, {text = __('猫咪列表'), color = '#796545', fontSize = 20})
        titleBg:addChild(titleLabel, 1)
        -- 列表
        local catGridViewSize = cc.size(size.width, 675)
        local catGridView = ui.gridView({x = size.width / 2, y = size.height / 2 - 15, size = catGridViewSize, cols = 1, csizeH = 214, auto = true})
        catGridView:setCellCreateHandler(CreateCatListCell)
        view:addChild(catGridView, 3)
        
        return {
            view                = view,
            catGridView         = catGridView,
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 0), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(cc.p(display.width - display.SAFE_L, display.cy))
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
进入动画
--]]
function CatHouseBreedListView:EnterAction(  )
    local viewData = self:GetViewData()
    viewData.view:setPositionX(display.width + self:getContentSize().width + 50)
    viewData.view:runAction(
        cc.MoveTo:create(0.3, cc.p(display.width - display.SAFE_L, display.cy))
    )
end

CreateCatListCell = function ( cellParent )
    local view = cellParent
    local size = cellParent:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local catHeadNode = CatHeadNode.new()
    view:addList(catHeadNode):alignTo(nil, ui.cc)

    local matingTips = ui.title({n = RES_DICT.OUT_TIP_BG}):updateLabel({fnt = FONT.D14, fontSize = 22, outline = "#311717", text = __("不可交配"), reqW = 160})
    view:addList(matingTips):alignTo(nil, ui.cc)

    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    view:addList(clickArea):alignTo(nil, ui.cc)

    local infoBtn = display.newButton(size.width - 65, size.height - 30, {n = RES_DICT.SEARCH_ICON})
    infoBtn:setScale(0.55)
    view:addChild(infoBtn, 1)

    return {
        view        = view,
        catHeadNode = catHeadNode,
        matingTips  = matingTips,
        clickArea   = clickArea,
        infoBtn     = infoBtn,
    }
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- public ---------------------
--[[
刷新列表cell
--]]
function CatHouseBreedListView:RefreshListCell( cellViewData, catModel, inviterData )
    cellViewData.catHeadNode:setCatUuid(catModel:getUuid())
    if inviterData then
        cellViewData.matingTips:setVisible(not catModel:isMatingToFriend(inviterData))
    else
        cellViewData.matingTips:setVisible(not catModel:checkMatingToFriend())
    end
end
-------------------- public ---------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取viewData
--]]
function CatHouseBreedListView:GetViewData()
    return self.viewData
end
------------------- get / set -------------------
-------------------------------------------------
return CatHouseBreedListView