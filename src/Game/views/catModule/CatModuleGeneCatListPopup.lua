--[[
 * author : panmeng
 * descpt : 基因猫 列表
]]

local CommonDialog   = require('common.CommonDialog')
local CatModuleGeneCatListPopup = class('CatModuleGeneCatListPopup', CommonDialog)

local RES_DICT = {
    BTN_CANCEL  = _res("ui/common/common_btn_white_default.png"),
    BTN_CONFIRM = _res('ui/common/common_btn_orange.png'),
    --          = list
    LIST_FRAME  = _res('ui/catModule/familyTree/grow_book_details_bg_list.png'),
    LIST_LINE   = _res('ui/catModule/familyTree/grow_book_details_line_list.png'),
}


function CatModuleGeneCatListPopup:ctor(args)
    self.args    = checktable(args)
    self.geneId_ = self.args.geneId or 1001
    -- create view

    self:setPosition(display.center)
    self.viewData = CatModuleGeneCatListPopup.CreateView()
    self:addList(self.viewData.view):alignTo(nil, ui.cb)

    self:getViewData().catTView:setCellInitHandler(function(cell)
        ui.bindClick(cell, handler(self, self.onClickCatCellHandler_))
    end)
    ui.bindClick(self:getViewData().btnDetail, handler(self, self.onClickDetailBtnHandler_))
    ui.bindClick(self:getViewData().btnCancel, handler(self, self.onClickCancelBtnHandler_))
    self:getViewData().catTView:setCellUpdateHandler(handler(self, self.setCellUpdateHandler))

    self:initCatData()
end

-------------------------------------------------------------------------------
-- get/ set
-------------------------------------------------------------------------------

function CatModuleGeneCatListPopup:getViewData()
    return self.viewData
end


function CatModuleGeneCatListPopup:getSelectedCatId()
    return self.selectedCatId_
end

function CatModuleGeneCatListPopup:setSelectedCatId(catId)
    local selectedCatId = catId
    if self:getSelectedCatId() == selectedCatId then
        return
    end
    self.selectedCatId_ = selectedCatId
    for _, cellNode in pairs(self:getViewData().catTView:getCellViewDataDict()) do
        cellNode:updateSelectedImgVisible(cellNode:getCatUuid() == self:getSelectedCatId())
    end
end

-------------------------------------------------------------------------------
-- public
-------------------------------------------------------------------------------
function CatModuleGeneCatListPopup:setCellUpdateHandler(cellIndex, cellNode)
    local playerCatId = self.displayCatIds_[cellIndex]
    cellNode:setCatUuid(playerCatId)
end

function CatModuleGeneCatListPopup:initCatData()
    local catMapData = app.catHouseMgr:getCatsModelMap()
    self.displayCatIds_ = {}

    if next(catMapData) == nil then
        return
    end
    for playerCatId, catModule in pairs(catMapData) do
        if catModule:hasGeneId(self.geneId_) then
            table.insert(self.displayCatIds_, playerCatId)
        end
    end
    self:getViewData().tipLabel:setVisible(#self.displayCatIds_ <= 0)
    self:getViewData().catTView:resetCellCount(#self.displayCatIds_)
end

-------------------------------------------------------------------------------
-- handler
-------------------------------------------------------------------------------

function CatModuleGeneCatListPopup:onClickCatCellHandler_(sender)
    PlayAudioByClickNormal()

    self:setSelectedCatId(sender:getCatUuid())
end


function CatModuleGeneCatListPopup:onClickDetailBtnHandler_(sender)
    PlayAudioByClickNormal()

    if self:getSelectedCatId() == nil then
        app.uiMgr:ShowInformationTips(__("请先选择猫咪"))
        return
    end

    local catInfoMdt = require('Game.mediator.catModule.CatModuleCatInfoMediator').new({catUuid = self:getSelectedCatId()})
    app:RegistMediator(catInfoMdt)
end


function CatModuleGeneCatListPopup:onClickCancelBtnHandler_(sender)
    PlayAudioByClickNormal()

    self:runAction(cc.RemoveSelf:create())
end

-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatModuleGeneCatListPopup.CreateView()
    local view = ui.layer()

    local viewGroup = view:addList({
        ui.layer({color = cc.r4b(0), enable = true}),
        ui.layer({bg = RES_DICT.LIST_FRAME, scale9 = true, size = cc.size(display.SAFE_SIZE.width, 246)}),
    })
    ui.flowLayout(cc.sizep(view, ui.cb), viewGroup, {type = ui.flowC, ap = ui.cb})

    local frameLayer = viewGroup[2]
    local frameSize  = frameLayer:getContentSize()
    local frameGroup = frameLayer:addList({
        ui.tableView({size = cc.resize(frameSize, -300, -20), dir = display.SDIR_H, csizeW = 210}),
        ui.image({img = RES_DICT.LIST_LINE}),
        ui.layer({size = cc.size(260, frameSize.height - 20)}),
    })
    ui.flowLayout(cc.rep(cc.sizep(frameSize, ui.cc), 0, -10), frameGroup, {type = ui.flowH, ap = ui.cc})
    
    -- tableView
    local catTView = frameGroup[1]
    catTView:setCellCreateClass(require('Game.views.catModule.cat.CatHeadNode'), {size = cc.size(210, 210)})

    local tipLabel = ui.label({fnt = FONT.D4, color = "#bdaa9a", text = __("尚无基因猫咪")})
    frameLayer:addList(tipLabel):alignTo(catTView, ui.cc)

    -- btnGroups
    local btnLayer = frameGroup[3]
    local btnGroup = btnLayer:addList({
        ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __("查看详情"), reqW = 110}),
        ui.button({n = RES_DICT.BTN_CANCEL}):updateLabel({fnt = FONT.D14, text = __("取消"), reqW = 110}),
    })
    ui.flowLayout(cc.sizep(btnLayer, ui.cc), btnGroup, {type = ui.flowV, ap = ui.cc, gapH = 30})

    return {
        view       = view,
        blockLayer = viewGroup[1],
        catTView   = catTView,
        btnDetail  = btnGroup[1],
        btnCancel  = btnGroup[2],
        tipLabel   = tipLabel,
    }
end


return CatModuleGeneCatListPopup
