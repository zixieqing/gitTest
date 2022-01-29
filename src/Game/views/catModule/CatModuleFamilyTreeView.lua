--[[
 * author : panmeng
 * descpt : 猫咪族谱
]]
local CatModuleFamilyTreeView = class('CatModuleFamilyTreeView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleFamilyTreeView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME      = _res('ui/common/common_bg_2.png'),
    BACK_BTN        = _res('ui/common/common_btn_back.png'),
    TITLE_BAR       = _res('ui/common/common_bg_title_2.png'),
    LIST_FRAME      = _res('ui/common/common_bg_list_3.png'),
    BTN_CANCEL      = _res('ui/common/common_btn_white_default.png'),
    BTN_CONFIRM     = _res('ui/common/common_btn_orange.png'),
    --              = attr cell
    BG_ATTR_GREY    = _res('ui/catModule/familyTree/grow_book_btn_gene_grey.png'),
    BG_ATTR_NORM    = _res('ui/catModule/familyTree/grow_book_btn_gene_light.png'),
    BG_LIST_FRAME   = _res('ui/catModule/familyTree/grow_book_pic_gene.png'),
    ATTR_UNLOCK     = _res('ui/catModule/familyTree/grow_book_line_gene_light.png'),
    ATTR_LOCKED     = _res('ui/catModule/familyTree/grow_book_line_gene_grey.png'),
    SELECTED_IMG    = _res('ui/catModule/headNode/grow_book_details_btn_cat_light.png'),
    --              = team cell
    TEAM_TITLE      = _res('ui/catModule/familyTree/grow_book_team_bg_head.png'),
    TEAM_FRAME      = _res('ui/catModule/familyTree/grow_book_team_pic_gene.png'),
    TEAM_ATTR_GREY  = _res('ui/catModule/familyTree/grow_book_line_gene_grey_small.png'),
    TEAM_ATTR_NORM  = _res('ui/catModule/familyTree/grow_book_line_gene_light_small.png'),
    TEAM_ICON       = _res('ui/catModule/familyTree/grow_book_team_btn_look.png'),
    --              = center
    BG_FRAME_FRONT  = _res('ui/catModule/familyTree/grow_book_bg_bottle_front.png'),
    BG_FRAME_AFTER  = _res('ui/catModule/familyTree/grow_book_bg_bottle_after.png'),
    BG_FRAME_BOTTOM = _res('ui/catModule/familyTree/grow_book_bg_bottle_bat.png'),
    BG_COLL_FRAME   = _res('ui/catModule/familyTree/grow_book_bg_time.png'),
    BG_TYPE_DARK    = _res('ui/catModule/familyTree/grow_book_btn_dark.png'),
    BG_TYPE_LIGNT   = _res('ui/catModule/familyTree/grow_book_btn_light.png'),
    --              = amim
    BG_SPINE        = _spn('ui/catModule/familyTree/anim/cat_grow_book'), 
}

local GENE_NODE_POS_LIST = {
    cc.p(-260, 300),
    cc.p(270, 240),
    cc.p(-245, 165),
    cc.p(220, 155),
    cc.p(-250, 0),
    cc.p(235, 15),
    cc.p(-270, -110),
    cc.p(275, -95)
}

function CatModuleFamilyTreeView:ctor(args)
    -- create view
    self.viewData_ = CatModuleFamilyTreeView.CreateView()
    self:addChild(self.viewData_.view)
end


function CatModuleFamilyTreeView:getViewData()
    return self.viewData_
end


function CatModuleFamilyTreeView:setSelectedEntrance(entranceId, dataNum)
    local selectedTag = checkint(entranceId)
    for _, entranceBtn in pairs(self:getViewData().entranceBtnGroup) do
        entranceBtn:setChecked(selectedTag == checkint(entranceBtn:getTag()))
    end
    self:getViewData().normalGeneTView:setVisible(selectedTag ~= CatHouseUtils.CAT_GENE_TYPE.SUIT)
    self:getViewData().teamGeneTView:setVisible(selectedTag == CatHouseUtils.CAT_GENE_TYPE.SUIT)
    self:getViewData().teamGeneTips:setVisible(selectedTag == CatHouseUtils.CAT_GENE_TYPE.SUIT)

    if selectedTag == CatHouseUtils.CAT_GENE_TYPE.SUIT then
        self:getViewData().teamGeneTView:resetCellCount(dataNum)
    else
        self:getViewData().normalGeneTView:resetCellCount(math.ceil(dataNum / #GENE_NODE_POS_LIST))
    end
end


function CatModuleFamilyTreeView:updateGeneCell(cellNode, geneData)
    local geneState = app.catHouseMgr:isCatsUnlockedGeneId(geneData.id) and CatHouseUtils.CAT_GENE_CELL_STATU.SELECT or CatHouseUtils.CAT_GENE_CELL_STATU.UNLOCK
    cellNode:updateView(geneData.id, geneState)
    cellNode:getViewData().lineImg:setVisible(geneData and next(geneData) ~= nil)
    cellNode:getViewData().view:setTag(checkint(geneData.id))
end


function CatModuleFamilyTreeView:setUnlockProgress(curNum, allNum)
    display.reloadRichLabel(self:getViewData().progressR, {c = {
        fontWithColor('14',{text = checkint(curNum), color = "#ffc178", outline = "#56190d"}),
        fontWithColor('14',{text = "/" .. checkint(allNum), color = "#c7A894", outline = "#56190d"}),
    }})
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatModuleFamilyTreeView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer/frame after/ view/frame front/ view
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150), enable = true}),
        ui.layer({color = cc.r4b(0), enable = true, size = cc.size(1000, 800)}),
        ui.image({img = RES_DICT.BG_FRAME_AFTER}),
        ui.spine({path = RES_DICT.BG_SPINE, init = "idle", ml = 140, cache = SpineCacheName.CAT_HOUSE}),
        ui.layer(),
        ui.image({img = RES_DICT.BG_FRAME_FRONT}),
        ui.image({img = RES_DICT.BG_FRAME_BOTTOM}),
        ui.layer(),
    })
    ui.flowLayout(cc.sizep(size, ui.cc), backGroundGroup, {type = ui.flowC, ap = ui.cc})

    ------------------------------------------------- [center after]
    local centerAfterLayer = backGroundGroup[5]
    local normalGeneTView  = ui.tableView({size = cc.size(1000, 630), csizeH = 663, dir = display.SDIR_V})
    normalGeneTView:setCellCreateHandler(CatModuleFamilyTreeView.CreateGeneCell)
    centerAfterLayer:addList(normalGeneTView):alignTo(nil, ui.cc, {offsetY = 60})

    local teamGeneTView = ui.tableView({size = cc.size(1000, 560), csizeH = 320, dir = display.SDIR_V})
    teamGeneTView:setCellCreateHandler(CatModuleFamilyTreeView.CreateTeamGeneCell)
    centerAfterLayer:addList(teamGeneTView):alignTo(nil, ui.cc, {offsetY = 50})
    
    ------------------------------------------------- [center front]
    -- btnGroups
    local centerFrontLayer = backGroundGroup[8]
    local entranceBtnGroup = {}
    for btnIndex, btnInfo in pairs(CatHouseUtils.CAT_GENE_TYPE_DEFINE_MAP) do
        local tFrame = ui.tButton({n = RES_DICT.BG_TYPE_DARK, s = RES_DICT.BG_TYPE_LIGNT})
        local tTitle = ui.title({n = _res(btnInfo.bigIconPath)}):updateLabel({fnt = FONT.D20, fontSize = 24, outline = "#56190d", text = btnInfo.titleFunc(), offset = cc.p(0, -70)})
        tFrame:addList(tTitle):alignTo(nil, ui.cc)

        tFrame:setTag(btnIndex)
        table.insert(entranceBtnGroup, tFrame)
    end
    centerFrontLayer:addList(entranceBtnGroup)
    ui.flowLayout(cc.rep(cc.sizep(size, ui.cc), 0, -280), entranceBtnGroup, {type = ui.flowH, gapW = 210, ap = ui.cc})

    -- progress
    local progressBg = ui.image({img = RES_DICT.BG_COLL_FRAME})
    centerFrontLayer:addList(progressBg):alignTo(nil, ui.rt, {offsetX = -display.SAFE_L})

    local progressGroup = progressBg:addList({
        ui.label({fnt = FONT.D6, color = "#5f291f", text = __("收集总进度"), reqW = 250}),
        ui.rLabel({r = true, c = {
            {text = "--", fnt = FONT.D14, color = "#ffc178", outline = "#56190d"},
            {text = "/--", fnt = FONT.D14, color = "#c7A894", outline = "#56190d"}
        }})
    })
    ui.flowLayout(cc.sizep(progressBg, ui.cc), progressGroup, {type = ui.flowV, ap = ui.cc, gapH = 7})

    local teamGeneTips = ui.label({fnt = FONT.D4, color = "#532922", text = __("TIPS:获得套装基因后需要放置在天选之猫选择位上才可生效该套装基因的属性加成, 天选之猫属性加成只能生效一只"), reqW = 800})
    centerFrontLayer:addList(teamGeneTips):alignTo(teamGeneTView, ui.ct, {offsetY = 0})

    return {
        view             = view,
        blockLayer       = backGroundGroup[1],
        entranceBtnGroup = entranceBtnGroup,
        progressR        = progressGroup[2],
        normalGeneTView  = normalGeneTView,
        teamGeneTView    = teamGeneTView,
        teamGeneTips     = teamGeneTips,
    }
end


function CatModuleFamilyTreeView.CreateGeneCell(cellParent)
    local size = cellParent:getContentSize()
    local view = ui.layer({size = size})
    cellParent:addList(view)

    local bg = ui.image({img = RES_DICT.BG_LIST_FRAME})
    view:addList(bg):alignTo(nil, ui.ct, {offsetY = 100})

    local geneNodeDatas = {}
    for index, pos in pairs(GENE_NODE_POS_LIST) do
        local geneNode = require('Game.views.catModule.cat.CatGeneNode').new({scale = 0.85})
        view:addList(geneNode):alignTo(bg, ui.cc, {offsetX = checkint(pos.x), offsetY = checkint(pos.y)})

        local lineImg = ui.button({n = RES_DICT.ATTR_UNLOCK, d = RES_DICT.ATTR_LOCKED})
        lineImg:setTouchEnabled(false)
        geneNode:addList(lineImg):alignTo(nil, ui.cb, {offsetY = -15, offsetX = (index %2) == 0 and -20 or 20})
        geneNode:getViewData().lineImg = lineImg
        lineImg:setScaleX(index % 2 == 0 and -1 or 1)
        
        table.insert(geneNodeDatas, geneNode)
    end

    return {
        view              = view,
        geneNodeDatas = geneNodeDatas
    }
end


function CatModuleFamilyTreeView.CreateAttrCell(scale)
    local size   = cc.size(260, 80)
    local view   = ui.layer({size = cc.size(size.width * scale, size.height * scale), color = cc.r4b(0), enable = true})
    local node   = ui.layer({scale = scale, size = size})
    view:add(node)

    local attrTBtn = ui.button({n = RES_DICT.BG_ATTR_NORM, d = RES_DICT.BG_ATTR_GREY})
    attrTBtn:setTouchEnabled(false)
    node:addList(attrTBtn):alignTo(nil, ui.cc)

    local nLabel = ui.label({fnt = FONT.D4, color = "#eed290", text = "--"})
    attrTBtn:getNormalImage():addList(nLabel):alignTo(nil, ui.cc, {offsetX = 15})

    local dLabel = ui.label({fnt = FONT.D4, color = "#bbac9f", text = "--"})
    attrTBtn:getDisabledImage():addList(dLabel):alignTo(nil, ui.cc, {offsetX = 15})

    local icon = ui.tButton({
        n = CatHouseUtils.GetCatAttrIconPathByAttrType(1, CatHouseUtils.CAT_GENE_CELL_STATU.SELECT),
        d = CatHouseUtils.GetCatAttrIconPathByAttrType(1, CatHouseUtils.CAT_GENE_CELL_STATU.UNLOCK),
    })
    icon:setTouchEnabled(false)
    attrTBtn:addList(icon):alignTo(nil, ui.lc, {offsetX = 30, offsetY = 5})

    local selectedImg = ui.image({img = RES_DICT.SELECTED_IMG, scale9 = true, size = cc.resize(size, 5, 0)})
    attrTBtn:addList(selectedImg):alignTo(nil, ui.cc)
    selectedImg:setVisible(false)
    view.selectedImg = selectedImg


    return {
        attrTBtn    = attrTBtn,
        icon        = icon,
        selectedImg = selectedImg,
        view        = view,
    }
end


function CatModuleFamilyTreeView.CreateTeamGeneCell(cellParent)
    local size = cellParent:getContentSize()
    local view = ui.layer({size = size})
    cellParent:addList(view)

    local frameGroup = view:addList({
        ui.button({n = RES_DICT.TEAM_TITLE, s = RES_DICT.TEAM_TITLE, ml = 50}):updateLabel({fnt = FONT.D4, color = "#532922", text = "--", ap = ui.lc, offset = cc.p(-420, 0)}),
        ui.label({fnt = FONT.D4, color = "#8A6A46", text = "--", ml = 60, ap = ui.lc, mt = 5}),
        ui.image({img = RES_DICT.TEAM_FRAME}),
        ui.layer({size = cc.size(size.width, 100), mt = -35}),
    })
    ui.flowLayout(cc.sizep(size, ui.lc), frameGroup, {type = ui.flowV, ap = ui.lc})

    local title = frameGroup[1]
    title:addList(ui.image({img = RES_DICT.TEAM_ICON})):alignTo(nil, ui.lc)

    local geneNodeGroup = {}
    local geneNodeLayer     = frameGroup[4]
    local geneNodeDatas     = {45, 70, 45, 50}
    for _, posY in ipairs(geneNodeDatas) do
        local geneNode = require('Game.views.catModule.cat.CatGeneNode').new({scale = 0.85})
        geneNodeLayer:addList(geneNode)

        local lineImg = ui.button({n = RES_DICT.TEAM_ATTR_NORM, d = RES_DICT.TEAM_ATTR_GREY})
        lineImg:setTouchEnabled(false)
        geneNode:addList(lineImg):alignTo(nil, ui.ct, {offsetY = posY})
        geneNode:getViewData().lineImg = lineImg
        
        table.insert(geneNodeGroup, geneNode)
    end
    ui.flowLayout(cc.sizep(geneNodeLayer, ui.cc), geneNodeGroup, {type = ui.flowH, ap = ui.cc, gapW = 5})

    return {
        view              = view,
        geneNodeDatas     = geneNodeGroup,
        title             = title,
        descr             = frameGroup[2],
    }
end


return CatModuleFamilyTreeView
