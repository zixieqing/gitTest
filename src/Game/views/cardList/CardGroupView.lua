local CardNode = require("common.CardHeadNode")

---@class CardGroupView
local CardGroupView = class('CardGroupView', function()
    return ui.layer({name = 'Game.views.cardList.CardGroupView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME           = _res('ui/home/cardslistNew/card_grouping_bg.jpg'),
    VIEW_BG              = _res('ui/home/cardslistNew/card_grouping_finish_fg.png'),
    BTN_LEFT             = _res('ui/home/cardslistNew/common_btn_direct_l.png'),
    BTN_RIGHT            = _res('ui/home/cardslistNew/common_btn_direct_r.png'),
    EMPTY_FRAME          = _res('ui/home/cardslistNew/card_grouping_bg_enter.png'),
    TITLE_BG             = _res('ui/home/cardslistNew/card_grouping_name_modify.png'),
    GROUP_BG             = _res('ui/home/cardslistNew/card_grouping_finish_bg.png'),
    CARD_BG              = _res('ui/home/cardslistNew/card_selected_total_bg.png'),
    ADD_IMG              = _res('ui/home/cardslistNew/card_grouping_selsct_first.png'),
    SELECTE_IMG          = _res('ui/home/cardslistNew/card_grouping_selsct_frame.png'),
    TOTAL_BG             = _res('ui/home/cardslistNew/card_selected_total_type.png'),
    BTN_SCREEN_N         = _res('ui/home/cardslistNew/card_preview_btn_unselection.png'),
    BTN_SCREEN_S         = _res('ui/home/cardslistNew/card_preview_btn_selection.png'),
    BACK_BTN             = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR        = _res('ui/common/common_title.png'),
    BTN_CANCEL           = _res('ui/common/common_btn_white_default.png'),
    BTN_CONFIRM          = _res('ui/common/common_btn_orange.png'),
    SORT_ARROW_IMG       = _res('ui/home/cardslistNew/tujian_selection_select_ico_filter_direction.png'),
    SCREEN_ARROW_IMG     = _res("ui/home/cardslistNew/card_ico_direction.png"),
    SELECTED_IMG         = _res('ui/common/common_bg_frame_goods_elected.png'),
    FILTER_BG            = _res('ui/home/cardslistNew/tujian_selection_frame_1.png'),
    FILTER_CELL_LINE     = _res('ui/common/tujian_selection_line.png'),
    FILTER_CELL_SELECTED = _res('ui/home/cardslistNew/tujian_selection_select_btn_filter_selected.png'),
}


CardGroupView.SCREEN_TYPE_DEFINE = {
	[CardUtils.CAREER_TYPE.BASE]   = {typeDescr = __('全部'), title = __('筛选')},
	[CardUtils.CAREER_TYPE.DEFEND] = {typeDescr = CardUtils.GetCardCareerName(CardUtils.CAREER_TYPE.DEFEND)},
	[CardUtils.CAREER_TYPE.ATTACK] = {typeDescr = CardUtils.GetCardCareerName(CardUtils.CAREER_TYPE.ATTACK)},
	[CardUtils.CAREER_TYPE.ARROW]  = {typeDescr = CardUtils.GetCardCareerName(CardUtils.CAREER_TYPE.ARROW)},
	[CardUtils.CAREER_TYPE.HEART]  = {typeDescr = CardUtils.GetCardCareerName(CardUtils.CAREER_TYPE.HEART)},
}

CardGroupView.SORT_TYPE_TAG = {
    ALL          = 0, -- 默认
    LEVEL        = 1, -- 等级
    RARITY       = 2, -- 稀有度
    WAKEN        = 3, -- 灵力
    STAR         = 4, -- 星级
    FAVORABILITY = 5, -- 好感度
    FROMATION    = 6, -- 编队信息
}


CardGroupView.SORT_TYPE_DEFINE = {
	[CardGroupView.SORT_TYPE_TAG.ALL]          = { sort = {"qualityId", "breakLevel", "level", "battlePoint", "favorabilityLevel", "cardId" }, ignoreLowUp = true,  typeDescr = __('默认'), title = __('排序')},
	[CardGroupView.SORT_TYPE_TAG.LEVEL]        = { sort = {"level", "qualityId", "breakLevel", "battlePoint", "favorabilityLevel", "cardId" }, ignoreLowUp = false, typeDescr = __('等级')},
	[CardGroupView.SORT_TYPE_TAG.RARITY]       = { sort = {"qualityId", "breakLevel", "level", "battlePoint", "favorabilityLevel", "cardId" }, ignoreLowUp = false, typeDescr = __('稀有度')},
	[CardGroupView.SORT_TYPE_TAG.WAKEN]        = { sort = {"battlePoint", "qualityId", "breakLevel", "level", "favorabilityLevel", "cardId" }, ignoreLowUp = false, typeDescr = __('灵力')},
	[CardGroupView.SORT_TYPE_TAG.STAR]         = { sort = {"breakLevel", "qualityId", "level", "battlePoint", "favorabilityLevel", "cardId" }, ignoreLowUp = false, typeDescr = __('星级')},
	[CardGroupView.SORT_TYPE_TAG.FAVORABILITY] = { sort = {"favorabilityLevel", "breakLevel", "qualityId", "level", "battlePoint", "cardId" }, ignoreLowUp = false, typeDescr = __('好感度')},
	[CardGroupView.SORT_TYPE_TAG.FROMATION]    = { sort = {"teamIndex", "qualityId", "breakLevel", "level", "battlePoint", "cardId" },         ignoreLowUp = true,  typeDescr = __('编队信息')},
}


function CardGroupView:ctor(args)
    -- create view
    self.viewData_ = CardGroupView.CreateView()
    self:addChild(self.viewData_.view)
end


function CardGroupView:getViewData()
    return self.viewData_
end


-------------------------------------------------------------------------------
-- public
-------------------------------------------------------------------------------

------------------ screen view
function CardGroupView:updateScreenViewVisible(visible, closeCB, clickCB)
    if self.screenViewData_ then
        self.screenViewData_.view:setVisible(visible)
    else
        self.screenViewData_ = CardGroupView.CreateScreenView(true, closeCB, clickCB)
        self:getViewData().view:addList(self.screenViewData_.view)
        self.screenViewData_.centerLayer:setPosition(cc.rep(self:getViewData().siftBtnP, 0, -25))
        self.screenViewData_.view:setVisible(visible)
    end
end


function CardGroupView:updateScreenCellSelected(selectedTag)
    if not self.screenViewData_ then
        return
    end
    for tag, cellNode in pairs(self.screenViewData_.typeCellMap) do
        cellNode:setChecked(checkint(selectedTag) + 1 == tag)
    end
    
    local screenDefine = CardGroupView.SCREEN_TYPE_DEFINE[checkint(selectedTag)]
    local str          = screenDefine.title or screenDefine.typeDescr
    self:getViewData().siftTitle:updateLabel({text = str, reqW = 100})
end


---------------- sort view
function CardGroupView:updateSortViewVisible(visible, closeCB, clickCB)
    if self.sortViewData_ then
        self.sortViewData_.view:setVisible(visible)
    else
        self.sortViewData_ = CardGroupView.CreateScreenView(false, closeCB, clickCB)
        self:getViewData().view:addList(self.sortViewData_.view)
        self.sortViewData_.centerLayer:setPosition(cc.rep(self:getViewData().sortBtnP, 0, -25))
        self.sortViewData_.view:setVisible(visible)
    end
end


function CardGroupView:updateSortCellSelected(selectedTag, isUp)
    if not self.sortViewData_ then
        return
    end
    for tag, cellNode in pairs(self.sortViewData_.typeCellMap) do
        cellNode:setChecked(checkint(selectedTag) + 1 == tag)
        cellNode:updateArrow(checkint(selectedTag) + 1 == tag and not CardGroupView.SORT_TYPE_DEFINE[tag - 1].ignoreLowUp, isUp)
    end
    
    local sortDefine = CardGroupView.SORT_TYPE_DEFINE[checkint(selectedTag)]
    local str        = sortDefine.title or sortDefine.typeDescr
    self:getViewData().sortTitle:updateLabel({text = str, reqW = 130})
end


----------------- other
function CardGroupView:goToChoosingMode(visible, isNeedAnim)
    self:updateEmptyViewVisible(false)
    self:updateGroupListP(visible, isNeedAnim)
    self:updateCardListP(visible, isNeedAnim)
end


function CardGroupView:updateGroupListP(visible, isNeedAnim)
    if visible then
        if isNeedAnim then
            self:getViewData().groupLayer:stopAllActions()
            self:getViewData().groupLayer:setPosition(self:getViewData().groupCardViewP)
            self:getViewData().groupLayer:runAction(cc.MoveTo:create(0.1, cc.p(self:getViewData().groupCardViewP.x, self:getViewData().highestH)))
        else
            self:getViewData().groupLayer:setPosition(cc.p(self:getViewData().groupCardViewP.x, self:getViewData().highestH))
        end
    else
        if isNeedAnim then
            self:getViewData().groupLayer:stopAllActions()
            self:getViewData().groupLayer:setPosition(cc.p(self:getViewData().groupCardViewP.x, self:getViewData().highestH))
            self:getViewData().groupLayer:runAction(cc.MoveTo:create(0.1, self:getViewData().groupCardViewP))
        else
            self:getViewData().groupLayer:setPosition(self:getViewData().groupCardViewP)
        end
    end
    self:getViewData().groupNameBtn:setVisible(not visible)
end


function CardGroupView:updateCardListP(visible, isNeedAnim)
    if visible then
        if isNeedAnim then
            self:getViewData().cardListLayer:stopAllActions()
            self:getViewData().cardListLayer:setPosition(cc.rep(self:getViewData().cardListViewP, 0, self:getViewData().lowestH))
            self:getViewData().cardListLayer:runAction(cc.Spawn:create(cc.MoveTo:create(0.1, self:getViewData().cardListViewP), cc.FadeIn:create(0.1)))
        else
            self:getViewData().cardListLayer:setPosition(self:getViewData().cardListViewP)
        end
    else
        if isNeedAnim then
            self:getViewData().cardListLayer:stopAllActions()
            self:getViewData().cardListLayer:setPosition(self:getViewData().cardListViewP)
            self:getViewData().cardListLayer:runAction(cc.Spawn:create(cc.MoveTo:create(0.1, cc.rep(self:getViewData().cardListViewP, 0, self:getViewData().lowestH)), cc.FadeIn:create(0.1)))
        else
            self:getViewData().cardListLayer:setPosition(cc.rep(self:getViewData().cardListViewP, 0, self:getViewData().lowestH))
        end
    end
    self:getViewData().blackLayer:setVisible(visible)
end


function CardGroupView:updateEmptyViewVisible(visible)
    self:getViewData().emptyLayer:setVisible(visible)
    self:getViewData().groupCardLayer:setVisible(not visible)
end


function CardGroupView:updateTitleNameStr(name)
    self:getViewData().groupNameBtn:updateLabel({text = tostring(name), reqW = 250})
end


function CardGroupView:refreshGroupData(groupData)
    self:updateTitleNameStr(groupData.name)
    self:getViewData().groupGridView:resetCellCount(#groupData.cards + 1)
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------
function CardGroupView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.r4b(0), enable = true}),
        ui.layer({bg = RES_DICT.VIEW_FRAME}),
        ui.layer(),
    })
    ui.flowLayout(cpos, backGroundGroup, {type = ui.flowC, ap = ui.cc})

    ----------------------------------------------- [center]
    local centerLayer = backGroundGroup[2]
    local viewGroup = centerLayer:addList({
        ui.button({n = RES_DICT.BTN_LEFT, mb = 250}),
        ui.layer({size = cc.size(1144, 650)}),
        ui.button({n = RES_DICT.BTN_RIGHT, mb = 250}),
    })
    ui.flowLayout(cc.rep(cc.sizep(centerLayer, ui.cb), 0, 140), viewGroup, {type = ui.flowH, ap = ui.cb, gapW = 10})

    local viewFrame = ui.image({img = RES_DICT.VIEW_BG})
    centerLayer:addList(viewFrame):alignTo(nil, ui.cb)

    local btnUp = ui.layer({size = cc.size(100, 50), color = cc.r4b(0), enable = true})
    centerLayer:addList(btnUp):alignTo(nil, ui.cb, {offsetY = 110})

    local groupLayer = viewGroup[2]
    local groupTitle = ui.button({n = RES_DICT.TITLE_BG}):updateLabel({fnt = FONT.D4, color = "#76553b", fontSize = 30, text = "--"})
    groupLayer:addList(groupTitle):alignTo(nil, ui.lt, {offsetY = -30})

    local cardLayerGroup = groupLayer:addList({
        ui.layer({bg = RES_DICT.EMPTY_FRAME}),
        ui.layer({bg = RES_DICT.GROUP_BG}),
    })

    ------------------------------------------------- empty view
    local emptyLayer = cardLayerGroup[1]
    local emptyAddBtn = ui.layer({color = cc.r4b(0), size = cc.size(135, 135), enable = true, p = cc.p(255, 135)})
    emptyLayer:addList(emptyAddBtn)

    local emptyDescr = ui.label({fnt = FONT.D7, color = "#9d7666", fontSize = 30, text = __("点击编辑飨灵列表分组"), reqW = 570, p = cc.p(360, 380)})
    emptyLayer:addList(emptyDescr)
    -------------------------------------------------- group card layer
    local groupCardLayer = cardLayerGroup[2]
    local groupGridView  = ui.gridView({size = cc.resize(groupCardLayer:getContentSize(), -10, -30), cols = 9, csizeH = 120, dir = display.SDIR_V})
    groupCardLayer:addList(groupGridView):alignTo(nil, ui.ct, {offsetY = -10})
    groupGridView:setCellCreateHandler(CardGroupView.CreateGroupCardCell)

    -------------------------------------------------- blackLayer
    local blackLayer = ui.layer({color = cc.c4b(0, 0, 0, 130), enable = true, size = centerLayer:getContentSize()})
    centerLayer:addList(blackLayer)

    --------------------------------------------------- card list view
    local cardListViewData =  CardGroupView.CreateCardListView()
    centerLayer:addList(cardListViewData.view):alignTo(nil, ui.cb, {offsetY = 120})

    ------------------------------------------------- [top]
    local topLayer = backGroundGroup[3]

    -- back button
    local backBtn = ui.button({n = RES_DICT.BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 30, offsetY = -15})

    local titleBtn = ui.button({n = RES_DICT.COM_TITLE_BAR}):updateLabel({fnt = FONT.D1, text = __('列表分组'), offset = cc.p(0,-10)})
    topLayer:addList(titleBtn):alignTo(backBtn, ui.rc, {offsetX = 2, offsetY = 10})


    return {
        view           = view,
        --             = top
        backBtn        = backBtn,
        titleBtn       = titleBtn,
        --             = center
        centerLayer    = centerLayer,
        btnLeft        = viewGroup[1],
        btnRigth       = viewGroup[3],
        groupNameBtn   = groupTitle,
        blackLayer     = blackLayer,
        btnUp          = btnUp,
        --             = emptyLayer
        emptyLayer     = emptyLayer,
        emptyAddBtn    = emptyAddBtn,
        --             = groupCardLayer
        groupCardLayer = groupCardLayer,
        groupLayer     = groupLayer,
        groupGridView  = groupGridView,
        --             = cardListView
        cardListLayer  = cardListViewData.view,
        siftBtn        = cardListViewData.siftBtn,
        sortBtn        = cardListViewData.sortBtn,
        cleanAllBtn    = cardListViewData.cleanAllBtn,
        confirmBtn     = cardListViewData.confirmBtn,
        cardGridView   = cardListViewData.gridView,
        sortTitle      = cardListViewData.sortTitle,
        siftTitle      = cardListViewData.siftTitle,
        btnDown        = cardListViewData.btnDown,
        cardListViewP  = cc.p(cardListViewData.view:getPosition()),
        groupCardViewP = cc.p(groupLayer:getPosition()),
        siftBtnP       = cardListViewData.view:convertToWorldSpace(cc.p(cardListViewData.siftBtn:getPosition())),
        sortBtnP       = cardListViewData.view:convertToWorldSpace(cc.p(cardListViewData.sortBtn:getPosition())),
        highestH       = centerLayer:getContentSize().height - groupLayer:getContentSize().height - 120,
        lowestH        = -display.height * 0.5 - 200,
    }
end


function CardGroupView.CreateCardListView()
    local view = ui.layer({bg = RES_DICT.CARD_BG, scale9 = true, size = cc.size(display.SAFE_RECT.width + 60, 507)})
    local size = view:getContentSize()

    local gridView = ui.gridView({size = cc.resize(size, -80, -90), csizeH = 120, cols = math.floor((size.width - 80) / 120), dir = display.SDIR_V})
    view:addList(gridView):alignTo(nil, ui.cb, {offsetY = 10})
    gridView:setCellCreateHandler(CardGroupView.CreateListCardCell)

    -------------------------------------------------- left btn
    local leftBtnGroup = view:addList({
        ui.title({n = RES_DICT.TOTAL_BG}):updateLabel({fnt = FONT.D4, fontSize = 30, color = "#542f1d", text = __("所有飨灵")}),
        ui.tButton({n = RES_DICT.BTN_SCREEN_N, s = RES_DICT.BTN_SCREEN_S, scale = 0.8}),
        ui.tButton({n = RES_DICT.BTN_SCREEN_N, s = RES_DICT.BTN_SCREEN_S, scale = 0.8}),
    })
    ui.flowLayout(cc.rep(cc.sizep(view, ui.lt), 45, -10), leftBtnGroup, {type = ui.flowH, ap = ui.lt, gapW = 10})

    local siftBtn   = leftBtnGroup[2]
    local siftTitle = ui.label({fnt = FONT.D4, fontSize = 26, text = __("筛选"), reqW = 100, color = "#FFFFFF"})
    siftBtn:addList(siftTitle, 3):alignTo(nil, ui.cc, {offsetY = 15, offsetX = 5})
    siftBtn:addList(ui.image({img = RES_DICT.SCREEN_ARROW_IMG})):alignTo(nil, ui.rc, {offsetY = 15, offsetX = 15})

    local sortBtn   = leftBtnGroup[3]
    local sortTitle = ui.label({fnt = FONT.D4, fontSize = 26, text = __("排序"), reqW = 130, color = "#FFFFFF"})
    sortBtn:addList(sortTitle, 3):alignTo(nil, ui.cc, {offsetY = 15, offsetX = 15})

    local btnDown = ui.layer({size = cc.size(130, 60), color = cc.r4b(0), enable = true})
    view:addList(btnDown):alignTo(nil, ui.ct, {offsetY = -10})

    --------------------------------------------------- rigth btn
    local rightButtonGroup = view:addList({
        ui.button({n = RES_DICT.BTN_CANCEL}):updateLabel({fnt = FONT.D14, text = __("清空选择"), reqW = 110}),
        ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __("确认"), reqW = 110}),
    })
    ui.flowLayout(cc.rep(cc.sizep(view, ui.rt), -45, -10), rightButtonGroup, {type = ui.flowH, ap = ui.rt, gapW = 10})

    return {
        view        = view,
        siftBtn     = siftBtn,
        sortBtn     = sortBtn,
        sortTitle   = sortTitle,
        siftTitle   = siftTitle,
        gridView    = gridView,
        btnDown     = btnDown,
        cleanAllBtn = rightButtonGroup[1],
        confirmBtn  = rightButtonGroup[2],
    }
end


function CardGroupView.CreateScreenView(isScreen, closeCB, clickCB)
    local typeDefines = isScreen and CardGroupView.SCREEN_TYPE_DEFINE or CardGroupView.SORT_TYPE_DEFINE

    -- get max str
    local maxWidth = 0
    local maxStr   = ""
    for _, typeDefine in pairs(typeDefines) do
        local strLen = string.len(typeDefine.typeDescr)
        if strLen > maxWidth then
            maxStr = typeDefine.typeDescr
        end
    end

    -- init font params
    local CELL_TITLE_FONT = FONT.D11
    local CELL_SIZE_H     = 55

    local debugLabel = ui.label({fnt = CELL_TITLE_FONT, text = maxStr})
    local imgWidth   = isScreen and 60 or 30
    local spaceWidth = isScreen and 0 or 30
    local maxWidth   = display.getLabelContentSize(debugLabel).width + imgWidth + 20 + spaceWidth


    local bgSize  = cc.size(maxWidth, CELL_SIZE_H * table.nums(typeDefines))
    local view    = ui.layer()

    local bgFrame = view:addList({
        ui.layer({color = cc.c4b(0,0,0,140), enable = true, cb = function(sender) 
            sender:getParent():setVisible(false)
            if closeCB then
                closeCB()
            end
        end}),
        ui.layer({size = bgSize, ap = ui.ct}),
    })
    local centerLayer = bgFrame[2]
    local frameBg     = ui.image({img = RES_DICT.FILTER_BG, scale9 = true, size = cc.size(bgSize.width + 10, bgSize.height + 10)})
    centerLayer:addList(frameBg):alignTo(nil, ui.cc)
    
    -------------------------------------------- cell
    local typeCellMap = {}
    for tag, typeDefine in pairs(typeDefines) do
        local cellSize = cc.size(maxWidth, CELL_SIZE_H)
        local view     = ui.layer({size = cellSize, color = cc.r4b(0), enable = true, cb = clickCB})
        view:setTag(tag)
    
        local selectedImg = ui.image({img = RES_DICT.FILTER_CELL_SELECTED, scale9 = true, size = cc.resize(cellSize, 5, 0)})
        view:addList(selectedImg):alignTo(nil, ui.cc)
    
        local titleAp = isScreen and ui.lc or ui.cc
        local titleLabel  = ui.label({fnt = CELL_TITLE_FONT, text = typeDefine.typeDescr, ap = titleAp})
        view:addList(titleLabel):alignTo(nil, titleAp, {offsetX = isScreen and imgWidth or (imgWidth - spaceWidth) * 0.5})
        
        local imgLine = ui.image({img = RES_DICT.FILTER_CELL_LINE, scale9 = true, size = cc.size(cellSize.width, 4)})
        view:addList(imgLine):alignTo(nil, ui.cb, {offsetY = -2})
    
        local iconPath = isScreen and CardUtils.GetCardCareerBgPathByCareerId(tag) or RES_DICT.SORT_ARROW_IMG
        local imgFrame = ui.image({img = iconPath})
        view:addList(imgFrame):alignTo(nil, ui.lc, {offsetX = 10})

        if isScreen then
            imgFrame:addList(ui.image({img = CardUtils.GetCardCareerIconPathByCareerId(tag)})):alignTo(nil, ui.cc)
        end

        view.setChecked = function(self, visible)
            selectedImg:setVisible(visible)
        end
        view.updateArrow = function(self, visible, isUp)
            imgFrame:setVisible(visible)
            if visible then
                imgFrame:setScaleY(isUp and 1 or -1)
            end
        end

        typeCellMap[checkint(tag) + 1] = view
    end
    centerLayer:addList(typeCellMap)
    ui.flowLayout(cc.sizep(centerLayer, ui.cc), typeCellMap, {type = ui.flowV, ap = ui.cc})

    return {
        blockLayer    = bgFrame[1],
        centerLayer   = centerLayer,
        view          = view,
        typeCellMap   = typeCellMap,
    }
end


function CardGroupView.CreateGroupCardCell(cellParent)
    local size = cellParent:getContentSize()
    local view = ui.layer({size = size, color = cc.r4b(0), enable = true})
    cellParent:addList(view):alignTo(nil, ui.cc)

    local addImg = ui.image({img = RES_DICT.ADD_IMG})
    view:addList(addImg):alignTo(nil, ui.cc)

    local cardNode = CardNode.new({scale = 0.6, specialType = 1})
    view:addList(cardNode):alignTo(nil, ui.cc)

    return {
        view     = view,
        addImg   = addImg,
        cardNode = cardNode,
    }
end


function CardGroupView.CreateListCardCell(cellParent)
    local size = cellParent:getContentSize()
    local view = ui.layer({size = size, color = cc.r4b(0), enable = true})
    cellParent:addList(view):alignTo(nil, ui.cc)

    local cardNode = CardNode.new({scale = 0.6, specialType = 1})
    view:addList(cardNode):alignTo(nil, ui.cc)

    local blackLayer = ui.layer({color = cc.c4b(0, 0, 0, 170), size = cc.resize(size, 65, 70)})
    cardNode:addList(blackLayer, 100)

    local selectedImg = ui.image({img = RES_DICT.SELECTED_IMG, scale9 = true, size = cc.resize(size, 65, 70), ap = ui.lb})
    cardNode:addList(selectedImg, 100)

    cardNode.setChecked = function(cardNode, visible)
        blackLayer:setVisible(visible)
        selectedImg:setVisible(visible)
    end

    return {
        view      = view,
        cardNode  = cardNode,
    }
end


return CardGroupView