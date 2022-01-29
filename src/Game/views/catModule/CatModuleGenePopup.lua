--[[
 * author : panmeng
 * descpt : 猫咪基因 展示
]]

local CommonDialog   = require('common.CommonDialog')
local CatModuleGenePopup = class('CatModuleGenePopup', CommonDialog)

local RES_DICT = {
    BG_FRAME     = _res('ui/common/common_bg_4.png'),
    IMG_MAT      = _res('ui/catModule/catPreview/grow_get_mat.png'),
    --           = tips
    BG_ATTR      = _res('ui/catModule/familyTree/grow_book_details_bg_tips.png'),
    BG_TITLE     = _res('ui/catModule/familyTree/grow_book_details_bg_head.png'),
    BG_ADD       = _res('ui/catModule/familyTree/grow_book_team_pic_plus.png'),
    BG_DESCR     = _res('ui/home/infor/personal_information_bg_autograph.png'),
    BTN_CONFIRM  = _res('ui/common/common_btn_orange.png'),
}

local DEFAULT_RACE = 1


function CatModuleGenePopup:ctor(args)
    local initArgs      = checktable(args)
    self.closeCB_       = initArgs.closeCB

    self:setPosition(display.center)
    self.viewData = CatModuleGenePopup.CreateView()
    self:add(self:getViewData().view)

    ui.bindClick(self:getViewData().blockLayer, handler(self, self.close), false)
    ui.bindClick(self:getViewData().matchBtn, handler(self, self.onClickMatchBtnHandler_))
    ui.bindClick(self:getViewData().listBtn, handler(self, self.onClickListBtnHandler_))

    self:setGeneId(initArgs.geneId)
end


function CatModuleGenePopup:getViewData()
    return self.viewData
end


function CatModuleGenePopup:setGeneId(geneId)
    self.geneId_ = checkint(geneId)
    self:updateView()
end
function CatModuleGenePopup:getGeneId()
    return checkint(self.geneId_)
end


-------------------------------------------------------------------------------
-- public
-------------------------------------------------------------------------------

function CatModuleGenePopup:close()
    self:runAction(cc.RemoveSelf:create())
    if self.closeCB_ then
        self.closeCB_()
    end
end


function CatModuleGenePopup:updateView()
    local geneData = CONF.CAT_HOUSE.CAT_GENE:GetValue(self:getGeneId())
    if not geneData or next(geneData) == nil then
        return
    end

    if self.catSpineNode_ then
        self.catSpineNode_:removeFromParent()
    end
    local geneConf = CONF.CAT_HOUSE.CAT_GENE:GetValue(self:getGeneId())
    local catRace  = #geneConf.raceLimit > 0 and geneConf.raceLimit[1] or DEFAULT_RACE
    self.catSpineNode_ = CatHouseUtils.GetCatSpineNode({catData = {gene = {self:getGeneId()}, catId = catRace, age = 2}, scale = 1.3})
    self:getViewData().catLayer:addList(self.catSpineNode_):alignTo(nil, ui.cc, {offsetY = 70})

    self:getViewData().title:updateLabel({text = geneData.name, reqW = 390})
    self:getViewData().descrLabel:setString(geneData.descr)
    local scrollSize = self:getViewData().scrollView:getContentSize()
    self:getViewData().scrollView:setContainerSize(cc.size(scrollSize.width, math.max(scrollSize.height, display.getLabelContentSize(self:getViewData().descrLabel).height + 10)))
    self:getViewData().descrLabel:alignTo(nil, ui.ct, {offsetY = -5})

    local geneType = CatHouseUtils.GetCatGeneTypeByGeneId(self:getGeneId())
    local genePartName = ""
    if geneType == CatHouseUtils.CAT_GENE_TYPE.FACADE then
        genePartName = CatHouseUtils.GetCatGenePartNameByGenePart(geneData.part)
    else
        genePartName = CatHouseUtils.GetCatGeneTypeNameByGeneType(geneType)
    end
    self:getViewData().genePosLabel:setString(tostring(genePartName))

    self:getViewData().nSourceLayer:setVisible(not geneData.compound or #geneData.compound <= 0)
    self:getViewData().tSourceLayer:setVisible(geneData.compound and #geneData.compound > 0)

    self:getViewData().tGListView:removeAllNodes()

    local compoundMap = {}
    for _, geneId in ipairs(geneData.compound or {}) do
        compoundMap[geneId] = true
    end
    local compoundList = table.keys(compoundMap)
    if #compoundList > 0 then
        local arrFilterNodes = {}
        local tGListViewSize = self:getViewData().tGListView:getContentSize()
        for index, geneId in ipairs(compoundList) do
            local geneNode = require('Game.views.catModule.cat.CatGeneNode').new({scale = 0.9, geneId = geneId})
            geneNode:getViewData().view:setTag(geneId)
            self:getViewData().tGListView:insertNodeAtLast(geneNode)

            ui.bindClick(geneNode:getViewData().view, handler(self, self.onClickGeneNodeBtnHandler_))

            if index ~= #compoundList then
                local addNode = ui.layer({size = cc.size(tGListViewSize.height - 20, tGListViewSize.height)})
                addNode:addList(ui.image({img = RES_DICT.BG_ADD})):alignTo(nil, ui.cc)
                self:getViewData().tGListView:insertNodeAtLast(addNode)
            end
        end
        self:getViewData().tGListView:reloadData()
    end
end


-------------------------------------------------------------------------------
-- handler
-------------------------------------------------------------------------------

function CatModuleGenePopup:onClickMatchBtnHandler_(sender)
    PlayAudioByClickNormal()

    local mediator = require("Game.mediator.catHouse.CatHouseBreedMediator").new()
	app:RegistMediator(mediator)
end


function CatModuleGenePopup:onClickListBtnHandler_(sender)
    PlayAudioByClickNormal()

    local geneCatListPopup = require('Game.views.catModule.CatModuleGeneCatListPopup').new({geneId = self:getGeneId()})
    app.uiMgr:GetCurrentScene():AddDialog(geneCatListPopup)
end


function CatModuleGenePopup:onClickGeneNodeBtnHandler_(sender)
    PlayAudioByClickNormal()

    if self:getGeneId() ~= checkint(sender:getTag()) then
        self:setGeneId(checkint(sender:getTag()))
        if self.closeCB_ then
            self.closeCB_()
        end
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatModuleGenePopup.CreateView(geneId)
    local view = ui.layer()

    local frameGroup = view:addList({
        ui.layer({color = cc.c4b(0, 0, 0, 120), enable = true}),
        ui.layer({color = cc.r4b(0), size = cc.size(426, 515), enable = true}),
    })
    ui.flowLayout(cc.sizep(view, ui.cc), frameGroup, {type = ui.flowC, ap = ui.cc})

    local catLayer = frameGroup[2]
    catLayer:addList(ui.image({img = RES_DICT.IMG_MAT})):alignTo(nil, ui.cc, {offsetY = -150})

    local centerGroup = view:addList({
        ui.layer({color = cc.r4b(0), size = cc.size(425, 600), enable = true}),
        ui.image({size = cc.size(426, 515), img = RES_DICT.BG_FRAME, scale9 = true, mt = -35}),
        ui.layer({size = cc.size(426, 600)}),  
    })
    ui.flowLayout(cc.rep(cc.sizep(view, ui.rc), -display.SAFE_L, 0), centerGroup, {type = ui.flowC, ap = ui.rc})

    local centerLayer = centerGroup[3]
    local infoGroup   = centerLayer:addList({
        ui.title({n = RES_DICT.BG_TITLE, mt = 10}):updateLabel({fnt = FONT.D20, fontSize = 24, outline = "#7a3f22", text = "--"}),
        ui.layer({bg = RES_DICT.BG_DESCR, scale9 = true, size = cc.size(402, 154)}),
        ui.title({n = RES_DICT.BG_ATTR, mt = 20}):updateLabel({fnt = FONT.D4, color = "#f7e8d4", text = __("显示部位")}),
        ui.label({fnt = FONT.D4, color = "#532922", text = "--", w = 400, mt = 5}),
        ui.title({n = RES_DICT.BG_ATTR, mt = 20}):updateLabel({fnt = FONT.D4, color = "#f7e8d4", text = __("获取方式")}),
        ui.layer({size = cc.size(400, 150), mt = 5}),
        ui.layer({size = cc.size(400, 70), mt = 21}),
    })
    ui.flowLayout(cc.rep(cc.sizep(centerLayer, ui.ct), 0, -10), infoGroup, {type = ui.flowV, ap = ui.cb})

    -- descr
    local descrLayer = infoGroup[2]
    local descrSize  = descrLayer:getContentSize()
    local scrollView = ui.scrollView({size = cc.resize(descrSize, 0, -3), dir = display.SDIR_V, drag = true})
    descrLayer:addList(scrollView):alignTo(nil, ui.cc, {offsetY = 2})

    local descrLabel = ui.label({fnt = FONT.D6, color = "#70645b", w = descrSize.width - 20, text = "--", ap = ui.ct})
    scrollView:getContainer():addList(descrLabel):alignTo(nil, ui.lt, {offsetX = 10, offsetY = descrSize.height - 8})

    -- source descr normal
    local fromDescrLayer = infoGroup[6]
    local nSourceLayer   = ui.layer({size = fromDescrLayer:getContentSize()})
    fromDescrLayer:add(nSourceLayer)
    local nSourceSize  = nSourceLayer:getContentSize()
    local nGScrollView = ui.scrollView({size = nSourceSize, dir = display.SDIR_V, drag = true})
    nSourceLayer:addList(nGScrollView):alignTo(nil, ui.cc)

    local sourceLabel = ui.label({fnt = FONT.D4, color = "#532922", w = nSourceSize.width - 20, text = __("成长获取")})
    nGScrollView:setContainerSize(cc.size(nSourceSize.width, math.max(display.getLabelContentSize(sourceLabel).height + 10, nSourceSize.height)))
    nGScrollView:getContainer():addList(sourceLabel):alignTo(nil, ui.ct, {offsetY = -5})

    -- source descr team
    local tSourceLayer   = ui.layer({size = fromDescrLayer:getContentSize()})
    fromDescrLayer:add(tSourceLayer)
    local tSourceSize  = tSourceLayer:getContentSize()
    local tSourceGroup = tSourceLayer:addList({
        ui.label({fnt = FONT.D4, color = "#532922", text = __("由拥有下列基因的猫咪繁育获得"), reqW = 400}),
        ui.listView({size = cc.size(tSourceSize.width, 72), dir = display.SDIR_H, mt = 20})
    })
    ui.flowLayout(cc.sizep(tSourceSize, ui.lt), tSourceGroup, {type = ui.flowV, ap = ui.lb})

    -- btnInfos
    local btnLayer = infoGroup[7]
    local btnGroup = btnLayer:addList({
        ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __("配对"), reqW = 110}),
        ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __("列表"), reqW = 110}),
    })
    ui.flowLayout(cc.sizep(btnLayer, ui.cc), btnGroup, {type = ui.flowH, ap = ui.cc, gapW = 50})


    return {
        view         = view,
        blockLayer   = frameGroup[1],
        title        = infoGroup[1],
        genePosLabel = infoGroup[4],
        matchBtn     = btnGroup[1],
        listBtn      = btnGroup[2],
        nGScrollView = nGScrollView,
        nSourceLayer = nSourceLayer,
        tSourceLayer = tSourceLayer,
        tGListView   = tSourceGroup[2],
        descrLabel   = descrLabel,
        scrollView   = scrollView,
        catLayer     = catLayer,
    }
end


return CatModuleGenePopup
