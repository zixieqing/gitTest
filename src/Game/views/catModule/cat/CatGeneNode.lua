--[[
 * author : panmeng
 * descpt : 猫屋属性节点
]]
local CELL_SIZE = cc.size(260, 80)
local CatGeneNode = class('CatGeneNode', function()
    return ui.layer({name = 'Game.views.catModule.cat.CatGeneNode', enableEvent = true, size = CELL_SIZE})
end)

local RES_DICT = {
    BG_ATTR_GREY    = _res('ui/catModule/familyTree/grow_book_btn_gene_grey.png'),
    BG_ATTR_NORM    = _res('ui/catModule/familyTree/grow_book_btn_gene_light.png'),
    SELECTED_IMG    = _res('ui/catModule/headNode/grow_book_details_btn_cat_light.png'),
}


function CatGeneNode:ctor(args)
    -- create view
    self.args = checktable(args)
    self.scale  = self.args.scale or 1
    self.viewData_ = CatGeneNode.CreateView()
    self:addChild(self.viewData_.view)

    self:getViewData().view.clickCloseCB = handler(self, self.updateSelectedImgVisible)
    self:updateView(self.args.geneId, self.args.geneState)

    if self.args.defaultCB then
        ui.bindClick(self:getViewData().view, handler(self, self.onClickGeneNodeBtnHandler_))
    end
end


function CatGeneNode:getViewData()
    return self.viewData_
end

function CatGeneNode:updateView(geneId, geneState)
    self.geneId = checkint(geneId)
    self.geneState = geneState or CatHouseUtils.CAT_GENE_CELL_STATU.SELECT
    self:setContentSize(cc.size(CELL_SIZE.width * self.scale, CELL_SIZE.height * self.scale))
    self:getViewData().cellNode:setScale(self.scale)


    local geneData = CONF.CAT_HOUSE.CAT_GENE:GetValue(self.geneId)
    self:getViewData().view:setVisible(geneData and next(geneData) ~= nil)
    if not geneData or next(geneData) == nil then
        return 
    end

    local geneType = CatHouseUtils.GetCatGeneTypeByGeneId(geneId)
    self:getViewData().icon:setNormalImage(CatHouseUtils.GetCatGeneIconPathByGeneType(geneType, CatHouseUtils.CAT_GENE_CELL_STATU.NORMAL))
    self:getViewData().icon:setSelectedImage(CatHouseUtils.GetCatGeneIconPathByGeneType(geneType, CatHouseUtils.CAT_GENE_CELL_STATU.SELECT))
    self:getViewData().icon:setDisabledImage(CatHouseUtils.GetCatGeneIconPathByGeneType(geneType, CatHouseUtils.CAT_GENE_CELL_STATU.UNLOCK))

    self:getViewData().attrTBtn.nLabel:updateLabel({text = geneData.name, reqW = 180})
    self:getViewData().attrTBtn.dLabel:updateLabel({text = geneData.name, reqW = 180})


    if self.geneState == CatHouseUtils.CAT_GENE_CELL_STATU.UNLOCK then
        self:getViewData().icon:setEnabled(false)
        self:getViewData().attrTBtn:setEnabled(false)
    else
        self:getViewData().icon:setEnabled(true)
        self:getViewData().icon:setChecked(true)
        self:getViewData().attrTBtn:setEnabled(true)
    end
end


function CatGeneNode:updateSelectedImgVisible(visible)
    self:getViewData().selectedImg:setVisible(visible)
end


function CatGeneNode:onClickGeneNodeBtnHandler_(sender)
    PlayAudioByClickNormal()

    self:updateSelectedImgVisible(true)
    app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = self.geneId, type = 21, closeCB = function()
        self:updateSelectedImgVisible(false)
    end})
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatGeneNode.CreateView()
    local view   = ui.layer({size = cc.size(CELL_SIZE.width, CELL_SIZE.height), color = cc.r4b(0), enable = true})
    local node   = ui.layer({size = CELL_SIZE})
    view:add(node)

    local attrTBtn = ui.button({n = RES_DICT.BG_ATTR_NORM, d = RES_DICT.BG_ATTR_GREY})
    attrTBtn:setTouchEnabled(false)
    node:addList(attrTBtn):alignTo(nil, ui.cc)

    local nLabel = ui.label({fnt = FONT.D4, color = "#eed290", text = "--"})
    attrTBtn:getNormalImage():addList(nLabel):alignTo(nil, ui.cc, {offsetX = 23})
    attrTBtn.nLabel = nLabel

    local dLabel = ui.label({fnt = FONT.D4, color = "#bbac9f", text = "--"})
    attrTBtn:getDisabledImage():addList(dLabel):alignTo(nil, ui.cc, {offsetX = 23})
    attrTBtn.dLabel = dLabel

    local icon = ui.tButton({
        n = CatHouseUtils.GetCatGeneIconPathByGeneType(CatHouseUtils.CAT_GENE_TYPE.FACADE, CatHouseUtils.CAT_GENE_CELL_STATU.NORMAL),
        s = CatHouseUtils.GetCatGeneIconPathByGeneType(CatHouseUtils.CAT_GENE_TYPE.FACADE, CatHouseUtils.CAT_GENE_CELL_STATU.SELECT),
        d = CatHouseUtils.GetCatGeneIconPathByGeneType(CatHouseUtils.CAT_GENE_TYPE.FACADE, CatHouseUtils.CAT_GENE_CELL_STATU.UNLOCK),
    })
    icon:setTouchEnabled(false)
    attrTBtn:addList(icon):alignTo(nil, ui.lc, {offsetX = 30, offsetY = 5})

    local selectedImg = ui.image({img = RES_DICT.SELECTED_IMG, scale9 = true, size = cc.resize(CELL_SIZE, 5, 0)})
    attrTBtn:addList(selectedImg):alignTo(nil, ui.cc)
    selectedImg:setVisible(false)
    view.selectedImg = selectedImg

    return {
        attrTBtn    = attrTBtn,
        icon        = icon,
        selectedImg = selectedImg,
        view        = view,
        cellNode    = node,
    }
end

return CatGeneNode
