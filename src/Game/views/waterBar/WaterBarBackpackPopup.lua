local CommonDialog   = require('common.CommonDialog')
local WaterBarBackpackPopup = class('WaterBarBackpackPopup', CommonDialog)

local RES_DICT = {
    BG_FRAME  = _res('ui/common/common_bg_11.png'),
    COM_TITLE = _res('ui/common/common_bg_title_2.png'),
    LIST_BG   = _res('ui/backpack/bag_bg_frame_gray_1.png'),
    DESCR_BG  = _res('ui/backpack/bag_bg_font.png'),
    DETAIL_BG = _res("ui/backpack/bag_bg_describe_1.png"),
    FONT_BG   = _res("ui/common/common_bg_font_name.png"),
}


function WaterBarBackpackPopup:InitialUI()
    -- create view
    self.viewData = WaterBarBackpackPopup.CreateView(handler(self, self.onClickGoodNodeHandler_))
    self:setPosition(display.center)

    
    -- bind event
    self:getViewData().goodsGridView:setCellInitHandler(function(cellNode)
        cellNode:alignTo(nil, ui.cc)
    end)
    self:getViewData().goodsGridView:setCellUpdateHandler(function(cellIndex, cellNode)
        local goodsData = self.backpackList[checkint(cellIndex)]
        cellNode:setTag(goodsData.goodsId)
        cellNode:RefreshSelf(goodsData)
        cellNode:updateSelectedImgVisible(cellNode:getTag() == self:getSelectedGoodsId())
    end)

    -- update view
    self:initView_()
end


function WaterBarBackpackPopup:getViewData()
    return self.viewData
end

function WaterBarBackpackPopup:setSelectedGoodsId(goodsId)
    self.selectedGoodsId_ = checkint(goodsId)
    self:updateDetailView(self:getSelectedGoodsId())
    for _, cellNode in pairs(self:getViewData().goodsGridView:getCellViewDataDict()) do
        cellNode:updateSelectedImgVisible(cellNode:getTag() == self:getSelectedGoodsId())
    end
end
function WaterBarBackpackPopup:getSelectedGoodsId()
    return checkint(self.selectedGoodsId_)
end

-------------------------------------------------------------------------------
-- handler
-------------------------------------------------------------------------------

function WaterBarBackpackPopup:initView_()
    self.backpackList = {}
    for _, barConf in pairs(CONF.BAR.MATERIAL:GetAll()) do
        local goodsId = checkint(barConf.id)
        local num     = app.goodsMgr:GetGoodsAmountByGoodsId(goodsId)
        if num > 0 then
            table.insert(self.backpackList, {goodsId = goodsId, num = num})
        end
    end
    table.sort(self.backpackList, function(goodsDataA, goodsDataB)
        return goodsDataA.goodsId > goodsDataB.goodsId
    end)


    if #self.backpackList > 0 then
        self:setSelectedGoodsId(self.backpackList[1].goodsId)
        self:getViewData().goodsGridView:resetCellCount(#self.backpackList)
    end
    self:getViewData().emptyView:setVisible(#self.backpackList <= 0)
    self:getViewData().centerLayer:setVisible(#self.backpackList > 0)
end


function WaterBarBackpackPopup:updateDetailView(goodsId)
    self:getViewData().goodsNode:RefreshSelf({goodsId = goodsId})
    self:getViewData().nameLabel:setText(GoodsUtils.GetGoodsNameById(goodsId))
    self:getViewData().numLabel:setString(string.fmt(__("数量：_num_"), {_num_ = app.goodsMgr:GetGoodsAmountByGoodsId(goodsId)}))
    local goodsConf = GoodsUtils.GetGoodsConfById(goodsId)
    self:getViewData().descrLabel:setString(goodsConf.descr)

    local descrSize  = display.getLabelContentSize(self:getViewData().descrLabel)
    local scrollSize = self:getViewData().scrollView:getContentSize()
    local containerH = math.max(descrSize.height + 10, scrollSize.height)
    self:getViewData().scrollView:getContainer():setContentSize(cc.size(scrollSize.width, containerH))
    self:getViewData().descrLabel:setPositionY(containerH - 5)
end
-------------------------------------------------------------------------------
-- handler
-------------------------------------------------------------------------------

function WaterBarBackpackPopup:onClickGoodNodeHandler_(sender)
    PlayAudioByClickNormal()

    self:setSelectedGoodsId(sender:getTag())
end

-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function WaterBarBackpackPopup.CreateView(goodNodeCb)
    local view = ui.layer({bg = RES_DICT.BG_FRAME, scale9 = true})
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local title = ui.title({n = RES_DICT.COM_TITLE}):updateLabel({fnt = FONT.D14, text = __("背 包")})
    view:addList(title):alignTo(nil, ui.ct, {offsetY = -12})

    local viewFrameGroup = view:addList({
        ui.layer({size = size}),
        ui.layer({size = size}),
    })

    ------------------------------------------------ emptyView
    local emptyView = viewFrameGroup[1]
    local emptyTips = emptyView:addList({
        AssetsUtils.GetCartoonNode(3, 0, 0, {scale = 0.7}),
        ui.label({fnt = FONT.D19, text = __("暂无水吧道具")})
    })
    ui.flowLayout(cpos, emptyTips, {type = ui.flowV, ap = ui.cc, gapH = 30})

    ------------------------------------------------ centerLayer
    local centerLayer = viewFrameGroup[2]
    local detailSize  = cc.size(370, 550)
    local listBgSize  = cc.size(450, 550)
    local centerBgGroup = centerLayer:addList({
        ui.layer({bg = RES_DICT.DETAIL_BG, scale9 = true, size = detailSize}),
        ui.layer({bg = RES_DICT.LIST_BG, scale9 = true, size = listBgSize})
    })
    ui.flowLayout(cc.rep(cpos, 0, -20), centerBgGroup, {type = ui.flowH, ap = ui.cc, gapW = 10})

    --------------------------------------- goodsInfo
    local detailBg    = centerBgGroup[1]
    local detailGroup = detailBg:addList({
        ui.layer({size = cc.size(detailSize.width - 40, 110)}),
        ui.layer({bg = RES_DICT.DESCR_BG, scale9 = true, size = cc.size(detailSize.width - 40, 400)})
    })
    ui.flowLayout(cc.sizep(detailSize, ui.cc), detailGroup, {type = ui.flowV, ap = ui.cc})

    ---------------------- goods base info
    local goodsNodeLayer = detailGroup[1]
    local goodsNodeGroup = goodsNodeLayer:addList({
        ui.goodsNode({scale = 0.9, defaultCB = true}),
        ui.layer({size = cc.resize(goodsNodeLayer:getContentSize(), -100, 0)})
    })
    ui.flowLayout(cc.sizep(goodsNodeLayer, ui.ct), goodsNodeGroup, {type = ui.flowH, ap = ui.ct})

    local goodsInfoLayer = goodsNodeGroup[2]
    local goodsInfoGroup = goodsInfoLayer:addList({
        ui.title({img = RES_DICT.FONT_BG, ml = 10}):updateLabel({fnt = FONT.D4, text = "--", ap = ui.lc, offset = cc.p(-70, 0)}),
        ui.label({fnt = FONT.D4, text = "--", ml = 23, ap = ui.lc}),
    })
    ui.flowLayout(cc.sizep(goodsInfoLayer, ui.lt), goodsInfoGroup, {type = ui.flowV, ap = ui.lb, gapH = 20})

    ----------------------- goods descr
    local goodsDescrLayer  = detailGroup[2]
    local descrScrollView =ui.scrollView({size = cc.resize(goodsDescrLayer:getContentSize(), 0, -20), dir = display.SDIR_V})
    goodsDescrLayer:addList(descrScrollView):alignTo(nil, ui.cc, {offsetY = 5})

    local goodsDescrLabel = ui.label({fnt = FONT.D4, w = goodsDescrLayer:getContentSize().width - 10, text = "--", ap = ui.lt})
    descrScrollView:getContainer():addList(goodsDescrLabel):alignTo(nil, ui.lt, {offsetX = 20})

    --------------------------------------------- goods list
    local goodsListLayer = centerBgGroup[2]
    local goodsGridView  = ui.gridView({dir = display.SDIR_V, size = cc.resize(listBgSize, 0, -10), cols = 4, csizeH = 110})
    goodsGridView:setCellCreateClass(require('common.GoodNode'), {callBack = goodNodeCb, scale = 0.9, showAmount = true})
    goodsListLayer:addList(goodsGridView):alignTo(nil, ui.cc)

    return {
        view          = view,
        goodsNode     = goodsNodeGroup[1],
        nameLabel     = goodsInfoGroup[1],
        numLabel      = goodsInfoGroup[2],
        descrLabel    = goodsDescrLabel,
        scrollView    = descrScrollView,
        goodsGridView = goodsGridView,
        emptyView     = emptyView,
        centerLayer   = centerLayer,
    }
end


return WaterBarBackpackPopup
    