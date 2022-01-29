--[[
 * author : panmeng
 * descpt : 猫屋 - 选择装饰外观弹窗
]]
local CatHouseChooseStyleView = class('CatHouseChooseStyleView', function()
    return ui.layer({name = 'Game.views.catHouse.CatHouseChooseStyleView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME      = _res('ui/common/common_bg_2.png'),
    BACK_BTN        = _res('ui/common/common_btn_back.png'),
    TITLE_BAR       = _res('ui/common/common_bg_title_2.png'),
    LIST_FRAME      = _res('ui/common/common_bg_list_3.png'),
    BTN_CANCEL      = _res('ui/common/common_btn_white_default.png'),
    BTN_CONFIRM     = _res('ui/common/common_btn_orange.png'),
    CHANGE_CARD_N   = _res('ui/catHouse/home/cat_avator_nameplate_bg.png'),
    CHANGE_CARD_S   = _res('ui/catHouse/home/cat_avator_nameplate_bg_select.png'),
    CHANGE_BUBBLE_N = _res('ui/catHouse/home/cat_avator_bubble_bg.png'),
    CHANGE_BUBBLE_S = _res('ui/catHouse/home/cat_avator_bubble_bg_select.png'),
    GRID_VIEW_BG    = _res('ui/catHouse/home/common_bg_goods.png'),
}


function CatHouseChooseStyleView:ctor(args)
    args                  = checktable(args)
    self.disGoodsType_    = args.disGoodsType or CatHouseUtils.AVATAR_STYLE_TYPE.IDENTITY
    self.selectedItemId_  = args.selectedItemId

    self.confirmCallback_ = args.callback

    local csizeH         = nil
    local createFunc     = nil
    local titleStr       = nil
    if self.disGoodsType_ == CatHouseUtils.AVATAR_STYLE_TYPE.IDENTITY then
        csizeH     = 170
        createFunc = CatHouseChooseStyleView.CreateCardCell
        titleStr   = __("更换名片")
    else
        csizeH     = 230
        createFunc = CatHouseChooseStyleView.CreateBubbleCell
        titleStr   = __("更换气泡")
    end
    self.viewData_ = CatHouseChooseStyleView.CreateView(csizeH, titleStr)
    self:addChild(self.viewData_.view)

    self:getViewData().gridView:setCellCreateHandler(createFunc)
    self:getViewData().gridView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.view, handler(self, self.onClickCellHandler_), false)
    end)
    self:getViewData().gridView:setCellUpdateHandler(handler(self, self.onUpdateCellHandler_))
    ui.bindClick(self:getViewData().confirmBtn, handler(self, self.onClickConfirmBtnHandler_))
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_))
    
    self:initDisplayData()
end


function CatHouseChooseStyleView:getViewData()
    return self.viewData_
end

function CatHouseChooseStyleView:setSelectedItemId(itemId)
    self.selectedItemId_ = checkint(itemId)
end
function CatHouseChooseStyleView:getSelectedItemId()
    return checkint(self.selectedItemId_)
end

-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatHouseChooseStyleView.CreateView(csizeH, titleStr)
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150)}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })

    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- view frame
    local viewFrameNode = ui.layer({p = cpos, bg = RES_DICT.VIEW_FRAME, ap = ui.cc, enable = true})
    local viewFrameSize = viewFrameNode:getContentSize()
    centerLayer:add(viewFrameNode)

    local frameLayer = ui.layer({size = viewFrameSize, p = cpos, ap = ui.cc})
    centerLayer:add(frameLayer)
    -- title bar
    local titleBar = ui.title({img = RES_DICT.TITLE_BAR}):updateLabel({fnt = FONT.D3, text = titleStr, paddingW = 60, safeW = 120, offset = cc.p(0,-2)})
    frameLayer:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -4})

    -- gridView
    local GRID_SIZE = cc.resize(viewFrameSize, -60, -130)
    local gridViewBg = ui.image({img = RES_DICT.GRID_VIEW_BG, scale9 = true, size = GRID_SIZE})
    frameLayer:addList(gridViewBg):alignTo(nil, ui.ct, {offsetY = -50})

    local gridView = ui.gridView({size = GRID_SIZE, dir = display.SDIR_V, cols = 2, csizeH = csizeH})
    frameLayer:addList(gridView):alignTo(gridViewBg, ui.cc)

    local confirmBtn = ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __("更换")})
    frameLayer:addList(confirmBtn):alignTo(nil, ui.cb, {offsetY = 10})


    return {
        view       = view,
        blackLayer = backGroundGroup[1],
        blockLayer = backGroundGroup[2],
        --         = top
        backBtn    = backBtn,
        --         = center
        gridView   = gridView,
        confirmBtn = confirmBtn,
    }
end

function CatHouseChooseStyleView.CreateCardCell(parent)
    return CatHouseChooseStyleView.CreateCell(parent, RES_DICT.CHANGE_CARD_N, RES_DICT.CHANGE_CARD_S)
end

function CatHouseChooseStyleView.CreateBubbleCell(parent)
    return CatHouseChooseStyleView.CreateCell(parent, RES_DICT.CHANGE_BUBBLE_N, RES_DICT.CHANGE_BUBBLE_S)
end

function CatHouseChooseStyleView.CreateCell(parent, n, s)
    local size = parent:getContentSize()
    local view = ui.layer({size = size, color = cc.r4b(0), enable = true})
    parent:add(view)

    local bgFrame    = ui.image({img = n})
    view:addList(bgFrame):alignTo(nil, ui.cc)

    local selectedImg = ui.image({img = s})
    view:addList(selectedImg):alignTo(nil, ui.cc)


    local itemNodeGroup = view:addList({
        ui.layer({size = cc.size(size.width, size.height - 50)}),
        ui.label({fnt = FONT.D16, text = "--"}),
    })
    ui.flowLayout(cc.sizep(size, ui.cc), itemNodeGroup, {type = ui.flowV, ap = ui.cc})
    -- local itemName = 
    -- view:addList(itemName):alignTo(nil, ui.cb)

    return {
        view        = view,
        itemLayer   = itemNodeGroup[1],
        itemName    = itemNodeGroup[2],
        selectedImg = selectedImg,
    }
end

function CatHouseChooseStyleView:initDisplayData()
    self.displayItemIdData_ = {}

    for _, itemData in pairs(CONF.CAT_HOUSE.MALL_INFO:GetAll()) do
        local goodsId     = checkint(itemData.id)
        local goodsConf   = GoodsUtils.GetGoodsConfById(goodsId)
        local goodsNum    = app.goodsMgr:GetGoodsAmountByGoodsId(goodsId)

        if checkint(goodsConf.effectType) == checkint(self.disGoodsType_) and goodsNum > 0 then
            table.insert(self.displayItemIdData_, itemData)
        end
    end
    self:getViewData().gridView:resetCellCount(#self.displayItemIdData_)
end

function CatHouseChooseStyleView:onUpdateCellHandler_(cellIndex, cellViewData)
    local itemData = self.displayItemIdData_[cellIndex]

    cellViewData.itemLayer:removeAllChildren()
    local itemNode = nil
    if self.disGoodsType_ == CatHouseUtils.AVATAR_STYLE_TYPE.IDENTITY then
        itemNode = CatHouseUtils.GetBusinessCardNode(itemData.id, app.gameMgr:GetUserInfo().playerName)
    else
        itemNode = CatHouseUtils.GetBubbleNode(itemData.id, __("请输入文字"))
    end
    cellViewData.itemLayer:addList(itemNode):alignTo(nil, ui.cc)
    cellViewData.view:setTag(itemData.id)
    cellViewData.itemName:setString(tostring(itemData.name))
    cellViewData.selectedImg:setVisible(self:getSelectedItemId() == checkint(itemData.id))
end

function CatHouseChooseStyleView:onClickCellHandler_(sender)
    PlayAudioByClickClose()
    
    local selectedItemId = checkint(sender:getTag())
    if selectedItemId == self:getSelectedItemId() then
        return
    end

    self:setSelectedItemId(selectedItemId)
    for _, cellViewData in pairs(self:getViewData().gridView:getCellViewDataDict()) do
        local itemId = checkint(cellViewData.view:getTag())
        cellViewData.selectedImg:setVisible(itemId == self:getSelectedItemId())
    end
end

function CatHouseChooseStyleView:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()

    self:runAction(cc.RemoveSelf:create())
end

function CatHouseChooseStyleView:onClickConfirmBtnHandler_(sender)
    PlayAudioByClickClose()

    if self.confirmCallback_ then
        self.confirmCallback_(self:getSelectedItemId())
    end
    self:runAction(cc.RemoveSelf:create())
end

return CatHouseChooseStyleView
