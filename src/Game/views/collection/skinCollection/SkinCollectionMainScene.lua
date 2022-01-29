--[[
 * author : panmeng
 * descpt : 皮肤收集 - 主界面
]]
local SkinCollectionMainScene = class('SkinCollectionMainScene', require('Frame.GameScene'))
local RemindIcon = require('common.RemindIcon')

local RES_DICT = {
    --                   = top
    COM_BACK_BTN         = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR        = _res('ui/common/common_title.png'),
    COM_TIPS_ICON        = _res('ui/common/common_btn_tips.png'),
    --                   = center
    BG_IMAGE             = _res('ui/collection/skinCollection/pokedex_monster_bg.png'),
    CENTER_BG            = _res('ui/collection/skinCollection/pokedex_monster_list_bg.png'),
    LEFT_BG_FRAME        = _res('ui/collection/skinCollection/pokedex_monster_tab_bg.png'),
    SEARCH_BG            = _res('ui/collection/skinCollection/pokedex_monster_list_bg_1.png'),
    EDIT_BG              = _res('ui/collection/skinCollection/raid_boss_btn_search.png'),
    SEARCH_BTN           = _res('ui/collection/skinCollection/pokedex_monster_btn_search.png'),
    RESET_BTN            = _res('ui/collection/skinCollection/pokedex_monster_btn_back.png'),
    PROGRESS_BG          = _res('ui/collection/skinCollection/pokedex_monster_numbers_bg.png'),
    NORMAL_BTN           = _res('ui/collection/skinCollection/pokedex_monster_tab_btn_select.png'),
    SELECTED_BTN         = _res('ui/collection/skinCollection/pokedex_monster_tab_btn_default.png'),
    REWARD_BTN           = _res('ui/collection/skinCollection/pokedex_monster_ico_rewards.png'),
    REWARD_BG            = _res('ui/collection/skinCollection/pokedex_npc_bg_collection_degree.png'),
    --                   = headSkin
    HEAD_FRAME           = _res('ui/collection/skinCollection/shop_btn_skin_default_1.png'),
    HEAD_NAME_BG         = _res('ui/home/teamformation/choosehero/team_kapai_bg_name.png'),
    HEAD_BG              = _res('ui/cards/head/kapai_frame_bg.png'),
    GRID_BG              = _res('ui/collection/skinCollection/common_bg_goods.png'),
    NEW_ICON             = _res('ui/home/cardslistNew/card_preview_ico_new.png'),
    --                   = halfBosySkin
    BODY_BG              = _res('ui/collection/skinCollection/pokedex_card_btn_life_love_lock.png'),
    BODY_FRAME           = _res('ui/collection/skinCollection/shop_btn_skin_default.png'),
    BODY_LINE            = _res('ui/collection/skinCollection/pokedex_monster_bg_name_line.png'),
    --                   = filterCell
    FILTER_BG            = _res('ui/home/cardslistNew/tujian_selection_frame_1.png'),
    FILTER_CELL_LINE     = _res('ui/common/tujian_selection_line.png'),
    FILTER_CELL_SELECTED = _res('ui/home/cardslistNew/tujian_selection_select_btn_filter_selected.png'),
    ARROW_BG             = _res("ui/anniversary20/hang/common_bg_tips_horn.png"),
    POKEDEX_ICON         = _res('ui/common/pokedex_series_ico_marriage.png'),
}

SkinCollectionMainScene.TYPE_NONE = 0

SkinCollectionMainScene.SKIN_STATE = {
    NONE                           = 0, -- 无状态，即默认所有
    OWNED                          = 1, -- 已拥有
    NOT_OWNED                      = 2, -- 未拥有
}

SkinCollectionMainScene.DISPLAY_TYPE = {
    SKIN_HEAD                      = 1,
    SKIN_HALF_BODY                 = 2,
}
SkinCollectionMainScene.DISPLAY_TITLE = {
    __("品版"),__("川版"),
}


function SkinCollectionMainScene:ctor(args)
    self.super.ctor(self, 'Game.views.collection.skinCollection.SkinCollectionMainScene')

    -- create view
    self.viewData_ = SkinCollectionMainScene.CreateView()
    self:addChild(self.viewData_.view)
end


function SkinCollectionMainScene:getViewData()
    return self.viewData_
end

function SkinCollectionMainScene:getTypeViewData()
    return self.typeViewData_
end

function SkinCollectionMainScene:getStateViewData()
    return self.stateViewData_
end


function SkinCollectionMainScene:showUI(endCB)
    local viewData = self:getViewData()
    viewData.topLayer:setPosition(viewData.topLayerHidePos)
    viewData.titleBtn:setPosition(viewData.titleBtnHidePos)
    viewData.titleBtn:runAction(cc.EaseBounceOut:create(cc.MoveTo:create(1, viewData.titleBtnShowPos)))
    
    local actTime = 0.2
    self:runAction(cc.Sequence:create({
        cc.TargetedAction:create(viewData.topLayer, cc.MoveTo:create(actTime, viewData.topLayerShowPos)),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    }))
end


function SkinCollectionMainScene:updateProgress(currentProgress, totalProgress)
    self:getViewData().currentProgress:setString(currentProgress)
    self:getViewData().totalProgress:setString(totalProgress)
end


function SkinCollectionMainScene:updateEmptySkinViewVisible(visible)
    self:getViewData().emptySkinView:setVisible(visible)
end


function SkinCollectionMainScene:setDisplaySkinCellType(displayType)
    self:getViewData().tableView:setVisible(displayType == SkinCollectionMainScene.DISPLAY_TYPE.SKIN_HALF_BODY)
    self:getViewData().gridView:setVisible(displayType == SkinCollectionMainScene.DISPLAY_TYPE.SKIN_HEAD)
    self:getViewData().gridViewBg:setVisible(displayType == SkinCollectionMainScene.DISPLAY_TYPE.SKIN_HEAD)
    self:getViewData().displayBtn:updateLabel({fnt = FONT.D7, text = tostring(SkinCollectionMainScene.DISPLAY_TITLE[displayType]), reqW = 200})
end


-------------------------------------------------
-- searchNameBox

function SkinCollectionMainScene:updateSeachNameBoxEnabled(isEnabled)
    self:getViewData().commonEditView:getViewData().descBox:setTouchEnabled(isEnabled == true)
end


function SkinCollectionMainScene:getSeachNameBoxText()
    return self:getViewData().commonEditView:getViewData().descBox:getText()
end
function SkinCollectionMainScene:setSeachNameBoxText(text)
    self:getViewData().commonEditView:getViewData().descBox:setText(tostring(text))
end


-------------------------------------------------
-- skinType update

function SkinCollectionMainScene:udpateSkinTypeCellSelectState(typeId)
    if not self:getTypeViewData() then return end
    for _, viewData in pairs(self:getTypeViewData().typeTableView:getCellViewDataDict()) do
        viewData.selectedImg:setVisible(typeId == checkint(viewData.view:getTag()))
    end
    SkinCollectionMainScene.SELECTED_BTN_TAG = typeId
end

function SkinCollectionMainScene:initSkinTypeDatas()
    local maxLen     = string.len(__("全部"))
    local maxLenConf = {}
    local typeConfs  = CONF.CARD.SKIN_COLL_TYPE:GetAll()
    for _, typeConf in pairs(typeConfs) do
        local titleStrLen  = string.len(typeConf.name)
        if maxLen < titleStrLen then
            maxLen     = titleStrLen
            maxLenConf = typeConf
        end
    end
    SkinCollectionMainScene.CELL_TITLE_FONT      = FONT.D11
    SkinCollectionMainScene.CELL_ICON_SCALE      = 0.6
    SkinCollectionMainScene.CELL_IMG_TEXT_SPA    = 10
    SkinCollectionMainScene.CELL_BG_SPA          = 20

    local debugTitle     = ui.label({fnt = SkinCollectionMainScene.CELL_TITLE_FONT, text = maxLenConf.name})
    local debugIcon      = ui.image({img = CardUtils.GetCardSkinTypeIconPathBySkinType(maxLenConf.id), scale = SkinCollectionMainScene.CELL_ICON_SCALE})
    local iconSizeW      = debugIcon:getContentSize().width * SkinCollectionMainScene.CELL_ICON_SCALE

    SkinCollectionMainScene.CELL_SIZE      = cc.size(display.getLabelContentSize(debugTitle).width + iconSizeW + SkinCollectionMainScene.CELL_IMG_TEXT_SPA + SkinCollectionMainScene.CELL_BG_SPA, 58)
    SkinCollectionMainScene.CELL_TITLE_POS = cc.p((SkinCollectionMainScene.CELL_SIZE.width + SkinCollectionMainScene.CELL_IMG_TEXT_SPA + iconSizeW) * 0.5, SkinCollectionMainScene.CELL_SIZE.height * 0.5)
    SkinCollectionMainScene.SELECTED_BTN_TAG = 0
end

function SkinCollectionMainScene:updateTypeCellHandler_(cellIndex, cellViewData)
    local isAll     = cellIndex == 1
    local typeConf  = isAll and {name = __("全部"), id = 0} or CONF.CARD.SKIN_COLL_TYPE:GetValue(cellIndex)
    if cellIndex == CONF.CARD.SKIN_COLL_TYPE:GetLength() + 1 then
        typeConf = CONF.CARD.SKIN_COLL_TYPE:GetValue(CardUtils.DEFAULT_SKIN_TYPE)
    end
    local titlePosX = isAll and SkinCollectionMainScene.CELL_SIZE.width * 0.5 or SkinCollectionMainScene.CELL_TITLE_POS.x
    cellViewData.titleLabel:setPositionX(titlePosX)
    cellViewData.titleLabel:setString(tostring(typeConf.name))
    cellViewData.iconImg:setVisible(not isAll)
    cellViewData.view:setTag(typeConf.id)
    cellViewData.selectedImg:setVisible(SkinCollectionMainScene.SELECTED_BTN_TAG == typeConf.id)
    if not isAll then
        cellViewData.iconImg:setTexture(CardUtils.GetCardSkinTypeIconPathBySkinType(typeConf.id))
    end
end

function SkinCollectionMainScene:setSkinTypeViewVisible(visible, typeInitArgs)
    if not self:getTypeViewData() then
        self:initSkinTypeDatas()
        self.typeViewData_ = SkinCollectionMainScene.CreateSkinTypeView()
        self:getTypeViewData().typeTableView:setCellUpdateHandler(handler(self, self.updateTypeCellHandler_))
        self:getTypeViewData().typeTableView:setCellInitHandler(function(cellViewData)
            ui.bindClick(cellViewData.view, function(sender)
                typeInitArgs.closeClickCB()
                typeInitArgs.typeClickCB(sender)
            end, false)
        end)
        self:getTypeViewData().typeTableView:resetCellCount(CONF.CARD.SKIN_COLL_TYPE:GetLength() + 1)
        self:getViewData().centerLayer:add(self:getTypeViewData().view)
        ui.bindClick(self:getTypeViewData().blockLayer, typeInitArgs.closeClickCB, false)

        self:getTypeViewData().centerLayer:alignTo(self:getViewData().leftLayer, ui.rc, {offsetX = 10, offsetY = -30})
        local positionY = (self:getTypeViewData().centerLayer:getContentSize().height - self:getViewData().leftLayer:getContentSize().height) * 0.5 + self:getViewData().typeBtn:getPositionY() + 30
        self:getTypeViewData().arrowBg:setPositionY(positionY)
    end
    
    self:getTypeViewData().view:setVisible(visible)
end


function SkinCollectionMainScene:updateTypeBtnTitle(typeId)
    local titleStr = __("类型")
    if typeId ~= SkinCollectionMainScene.TYPE_NONE then
        local typeConf = checktable(CONF.CARD.SKIN_COLL_TYPE:GetValue(typeId))
        titleStr = tostring(typeConf.name)
    end
    self:getViewData().typeBtn.title:updateLabel({text = titleStr, reqW = 180})
end


-------------------------------------------------
-- skinState update

function SkinCollectionMainScene:udpateSkinStateCellSelectState(stateIndex)
    if not self:getStateViewData() then return end
    local stateCellNode = self:getStateViewData().stateCellNodes[stateIndex + 1]
    self:getStateViewData().selectedImg:alignTo(stateCellNode, ui.cc, {offsetY = -2})
end


function SkinCollectionMainScene:setSkinStateViewVisible(visible, stateInitArgs)
    if not self:getStateViewData() then
        self.stateViewData_ = SkinCollectionMainScene.CreateSkinStateView(function(sender)
            stateInitArgs.closeClickCB()
            stateInitArgs.stateClickCB(sender)
        end)
        self:getViewData().centerLayer:add(self:getStateViewData().view)

        ui.bindClick(self:getStateViewData().blockLayer, stateInitArgs.closeClickCB, false)

        self:getStateViewData().centerLayer:alignTo(self:getViewData().leftLayer, ui.rc, {offsetX = 10, offsetY = -240})
        self:getStateViewData().arrowBg:alignTo(nil, ui.lc, {offsetX = -10})
    end
    self:getStateViewData().view:setVisible(visible)
end


function SkinCollectionMainScene:updateStateBtnTitle(stateIndex, checkedState)
    local titleStr = __("拥有状态")
    if stateIndex ~= SkinCollectionMainScene.SKIN_STATE.NONE then
        local titleGroupTexts = {__("已拥有"), __("未拥有")}
        titleStr = tostring(titleGroupTexts[stateIndex])
    end
    self:getViewData().stateBtn.title:updateLabel({text = titleStr, reqW = 180})
end


-------------------------------------------------
-- cells update

function SkinCollectionMainScene:updateSkinGridCell(cellIndex, cellViewData, skinData)
    cellViewData.nameTitle:updateLabel({text = tostring(skinData.skinName), reqW = 140})

    local skinPath = CardUtils.GetCardHeadPathBySkinId(checkint(skinData.skinId))
    cellViewData.headIcon:setTexture(skinPath)

    cellViewData.addImg:setVisible(skinData.isNew)

    ---- update grey
    local grayFilter = GrayFilter:create()

    if skinData.isHaveSkin == true then
        cellViewData.headIcon:clearFilter()
        cellViewData.frame:clearFilter()
    else
        cellViewData.headIcon:setFilter(grayFilter)
        cellViewData.frame:setFilter(grayFilter)
    end

    cellViewData.cellNode:setTag(skinData.skinId)
end


function SkinCollectionMainScene:updateSkinTableCell(cellIndex, cellViewData, skinData)
    cellViewData.skinNameLabel:updateLabel({text = tostring(skinData.skinName), reqW = 190})
    cellViewData.cardNameLabel:updateLabel({text = tostring(skinData.cardName), reqW = 190})

    local cardDrawName = CardUtils.GetCardDrawNameBySkinId(checkint(skinData.skinId))
    local skinPath = AssetsUtils.GetCardDrawPath(cardDrawName)

    local locationInfo = CommonUtils.GetConfig('cards', 'coordinate', cardDrawName)
    if nil == locationInfo or not locationInfo[COORDINATE_TYPE_TEAM] then
        print('\n**************\n', '立绘坐标信息未找到', cardDrawName, '\n**************\n')
        locationInfo = {x = 0, y = 0, scale = 50, rotate = 0}
    else
        locationInfo = locationInfo[COORDINATE_TYPE_TEAM]
    end

    ---- resetInfo
    cellViewData.bodyImg:setTexture(skinPath)
    cellViewData.bodyImg:setScale(locationInfo.scale/100)
    cellViewData.bodyImg:setRotation( (locationInfo.rotate)) 
    local size = cellViewData.bodyImg:getContentSize()
    cellViewData.bodyImg:setPosition(cc.p(locationInfo.x ,(-1)*(locationInfo.y-540) - 8))
    
    local typeConf = checktable(CONF.CARD.SKIN_COLL_TYPE:GetValue(checkint(skinData.skinType)))
    local skinTypeIconPath = typeConf.logo

    if skinTypeIconPath then
        cellViewData.typeImg:setVisible(true)
        cellViewData.typeImg:setTexture(CardUtils.GetCardSkinTypeIconPathBySkinType(typeConf.id))
    else
        cellViewData.typeImg:setVisible(false)
    end

    cellViewData.addImg:setVisible(skinData.isNew)

    --------------------- update grey
    local grayFilter = GrayFilter:create()

    if skinData.isHaveSkin then
        cellViewData.bodyImg:clearFilter()
        cellViewData.frame:clearFilter()
        cellViewData.typeImg:clearFilter()
    else
        cellViewData.bodyImg:setFilter(grayFilter)
        cellViewData.frame:setFilter(grayFilter)
        cellViewData.typeImg:setFilter(grayFilter)
    end

    cellViewData.cellNode:setTag(skinData.skinId)
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function SkinCollectionMainScene.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- bgImg / black / block layer
    local backGroundGroup = view:addList({
        ui.image({img = RES_DICT.BG_IMAGE, p = cpos, isFull = true}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })


    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- back button
    local backBtn = ui.button({n = RES_DICT.COM_BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 35, offsetY = -15})

    -- title button
    local titleBtn = ui.button({n = RES_DICT.COM_TITLE_BAR}):updateLabel({fnt = FONT.D1, text = __('飨灵外观图鉴'), offset = cc.p(0,-10)})
    topLayer:addList(titleBtn):alignTo(backBtn, ui.rc, {offsetX = 2, offsetY = 10})


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- rewardBtn
    local rewardTitle = ui.title({n = RES_DICT.REWARD_BG, scale9 = true}):updateLabel({fontSize = 26, text = __('收集奖励'), paddingW = 50, offset = cc.p(15,0)})
    local rewardBtnSize = rewardTitle:getContentSize()
    RemindIcon.addRemindIcon({parent = rewardTitle, tag = RemindTag.SKIN_COLL_TASK, po = cc.p(rewardBtnSize.width - 20, rewardBtnSize.height / 2 + 20)})

    local rewardBtn = ui.colorBtn({color = cc.r4b(0), size = cc.resize(rewardTitle:getContentSize(), 40, 20)})
    centerLayer:addList(rewardBtn):alignTo(nil, ui.rt, {offsetX = -display.SAFE_L - 30, offsetY = - 10})

    rewardBtn:addList(rewardTitle):alignTo(nil, ui.rc, {offsetY = -5})
    rewardBtn:addList(ui.image({img = RES_DICT.REWARD_BTN})):alignTo(nil, ui.lc, {offsetY = 5})


    ------------------------------------------------leftlayer
    local leftLayer = ui.layer({bg = RES_DICT.LEFT_BG_FRAME})
    centerLayer:addList(leftLayer):alignTo(nil, ui.lc, {offsetX = display.SAFE_L, offsetY = -30})
    
    local leftBgSize = leftLayer:getContentSize()
    local centerBgSizeW = display.SAFE_SIZE.width - leftBgSize.width
    local centerBg = ui.image({img = RES_DICT.CENTER_BG, ap = ui.lc, scale9 = true, size = cc.size(centerBgSizeW, 649)})
    centerLayer:addList(centerBg):alignTo(nil, ui.lc, {offsetX = display.SAFE_L + leftBgSize.width - 5, offsetY = -30})

    ---- createPorgress
    local progressBg = ui.image({img = RES_DICT.PROGRESS_BG})
    leftLayer:addList(progressBg):alignTo(nil, ui.ct, {offsetY = -50})

    local progressGroup = progressBg:addList({
        ui.label({fnt = FONT.D19, fontSize = 32, outline = "#000000", text = "-"}),
        ui.label({fnt = FONT.D7, fontSize = 30, color = "#882b15", text = "-"}),
    })
    ui.flowLayout(cc.rep(cc.sizep(progressBg, ui.cc), -5, 0), progressGroup, {type = ui.flowV, ap = ui.cc, gapH = 20})
    
    ---- createButton
    local buttonTexts = {"--", __("类型"), __("拥有状态")}
    local buttonGroup = leftLayer:addList({
        ui.button({n = RES_DICT.NORMAL_BTN, s = RES_DICT.SELECTED_BTN}):updateLabel({fnt = FONT.D7, text = buttonTexts[1], reqW = 200}),
        ui.tButton({n = RES_DICT.NORMAL_BTN, s = RES_DICT.SELECTED_BTN}),
        ui.tButton({n = RES_DICT.NORMAL_BTN, s = RES_DICT.SELECTED_BTN}),
    })
    for buttonIndex = 2, #buttonGroup do
        local label = ui.label({fnt = FONT.D7, text = buttonTexts[buttonIndex], reqW = 200})
        buttonGroup[buttonIndex].title = label
        buttonGroup[buttonIndex]:addList(label):alignTo(nil, ui.cc)
    end
    ui.flowLayout(cc.rep(cc.sizep(leftLayer, ui.cb), 0, 50), buttonGroup, {type = ui.flowV, ap = ui.ct, gapH = 20})


    --------------------------------------  createSearchNode
    local searchLayer = ui.layer({bg = RES_DICT.SEARCH_BG, ap = ui.rb, scale9 = true, size = cc.size(centerBgSizeW - 40, 66)})
    centerLayer:addList(searchLayer):alignTo(centerBg, ui.ct, {offsetX = 0, offsetY = -80})

    local debugLabel   = ui.label({text = __('请输入飨灵的名字'), fontSize = 20})
    local editViewSize = cc.size(math.max(218, debugLabel:getContentSize().width / 2 + 20), 40)
    local searchGroup  = searchLayer:addList({
        require('common.CommonEditView').new({placeHolder = debugLabel:getString(), maxLength = 50, bg = RES_DICT.EDIT_BG, isScale9 = true, bgSize = editViewSize, placeholderFontColor = "#ffffff", placeholderFontSize = 20, boxFontColor = "#ffffff", boxFontSize = 20}), 
        ui.button({n = RES_DICT.SEARCH_BTN}),
        ui.button({n = RES_DICT.RESET_BTN}),
    })
    ui.flowLayout(cc.rep(cc.sizep(searchLayer, ui.rc), -10, 0), searchGroup, {type = ui.flowH, ap = ui.rc, gapW = 10})
    searchGroup[1]:getViewData().descBox:setVisible(true)

    ------ createCenter
    local tableView = ui.tableView({size = cc.size(display.SAFE_SIZE.width - leftBgSize.width - 24, 560), dir = display.SDIR_H, csizeW = 230})
    centerLayer:addList(tableView):alignTo(nil, ui.rc, {offsetY = -60, offsetX = -display.SAFE_L - 20})
    tableView:setCellCreateHandler(SkinCollectionMainScene.CreateHalfBodySkinCell)
    tableView:setVisible(false)

    local GRIDW = display.SAFE_SIZE.width - leftBgSize.width - 34
    local GRIDH = 550
    local GRIDCELLW = 173
    local GRID_COL = math.floor(GRIDW / GRIDCELLW)

    local gridViewGroup = centerLayer:addList({
        ui.image({img = RES_DICT.GRID_BG, scale9 = true, size = cc.size(GRIDW, 540), mr = 5}),
        ui.gridView({cols = GRID_COL, size = cc.size(GRIDW, 540), csizeH = 210, dir = display.SDIR_V}),
    })
    ui.flowLayout(cc.rep(cc.sizep(centerLayer, ui.rc), -display.SAFE_L - 20, -60), gridViewGroup, {type = ui.flowC, ap = ui.rc})
    gridViewGroup[2]:setCellCreateHandler(SkinCollectionMainScene.CreateHeadSkinCell)
    gridViewGroup[2]:setVisible(false)

    ------------------------------ empty skin View
    local emptySkinView = ui.layer({size = cc.size(GRIDW, 540)})
    centerLayer:addList(emptySkinView):alignTo(tableView, ui.cc)
    
    local emptySkinGroup = emptySkinView:addList({
        ui.label({text = __("当前飨灵暂无皮肤"), fnt = FONT.D7, fontSize = 30, color = "#9d3b3b"}),
        AssetsUtils.GetCartoonNode(3, 0, 0, {scale = 0.6}),
    })
    ui.flowLayout(cc.sizep(emptySkinView, ui.cc), emptySkinGroup, {type = ui.flowH, ap = ui.cc})


    return {
        view            = view,
        --              = top
        topLayer        = topLayer,
        topLayerHidePos = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos = cc.p(topLayer:getPosition()),
        titleBtn        = titleBtn,
        titleBtnHidePos = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        titleBtnShowPos = cc.p(titleBtn:getPosition()),
        backBtn         = backBtn,
        --              = center
        centerLayer     = centerLayer,
        tableView       = tableView,
        gridView        = gridViewGroup[2],
        gridViewBg      = gridViewGroup[1],
        commonEditView  = searchGroup[1],
        leftLayer       = leftLayer,
        currentProgress = progressGroup[1],
        totalProgress   = progressGroup[2],
        emptySkinView   = emptySkinView,
        --              = editTips
        searchBtn       = searchGroup[2],
        resetBtn        = searchGroup[3],
        displayBtn      = buttonGroup[1],
        typeBtn         = buttonGroup[2],
        stateBtn        = buttonGroup[3],
        rewardBtn       = rewardBtn,
    }
end


function SkinCollectionMainScene.CreateHalfBodySkinCell(cellParent)
    local view = cellParent

    local cellSize = cellParent:getContentSize()  
    local bg       = AssetsUtils.GetCardTeamBgNode(0, cellSize.width * 0.5 + 1, cellSize.height * 0.5 + 2)
    local cellNode = ui.layer({size = cellSize, color = cc.r4b(0), enable = true})
    view:addList(cellNode):alignTo(nil, ui.cc, {offsetY = -5})


    ----------- create clipNode
    local clipLayer = ui.layer({size = cc.resize(cellSize, -30, -20), color = cc.r4b(0)})
    cellNode:addList(clipLayer):alignTo(nil, ui.cc)

    local clipNode = cc.ClippingNode:create(clipLayer)
    clipNode:setContentSize(cellSize)
    cellNode:addList(clipNode):alignTo(nil, ui.cb)
    clipNode:setInverted(false)

    -----[bg | skin]
    local bgGroup      = clipNode:addList({
        bg,
        FilteredSpriteWithOne:create(),
    })
    ui.flowLayout(cc.sizep(cellSize, ui.cc), bgGroup, {type = ui.flowC, ap = ui.cc})
    bgGroup[2]:setAnchorPoint(ui.lb)

    ------ info
    local infoBg = ui.layer({size = cc.size(200, 130), color = cc.c4b(0,0,0,150)})
    cellNode:addList(infoBg):alignTo(nil, ui.cb)
    
    local infoGroup = infoBg:addList({
        SkinCollectionMainScene.GetFilterImg(RES_DICT.POKEDEX_ICON),
        ui.label({fnt = FONT.D20, fontSize = 22, color = '#ffcb69', outline = '#402008', text = '--'}),
        ui.image({img = RES_DICT.BODY_LINE}),
        ui.label({fnt = FONT.D14, fontSize = 20, color = '#ffffff', outline = '#402008', text = '--'}),
    })
    ui.flowLayout(cc.rep(cc.sizep(infoBg, ui.ct), 0, 30), infoGroup, {type = ui.flowV, ap = ui.cb, gapH = 10})

    -- bg Frame
    local bgFrame = SkinCollectionMainScene.GetFilterImg(RES_DICT.BODY_FRAME)
    cellNode:addList(bgFrame):alignTo(nil, ui.cc, {offsetX = 10})

    local addImg = ui.image({img = RES_DICT.NEW_ICON})
    cellNode:addList(addImg):alignTo(nil, ui.rt)
    
    return {
        bodyImg       = bgGroup[2],
        cellNode      = cellNode,
        typeImg       = infoGroup[1],
        skinNameLabel = infoGroup[2],
        cardNameLabel = infoGroup[4],
        frame         = bgFrame,
        addImg        = addImg,
    }
end


function SkinCollectionMainScene.CreateHeadSkinCell(cellParent)
    local view = cellParent

    local bg        = ui.image({img = RES_DICT.HEAD_BG})
    local nameTitle = ui.title({n = RES_DICT.HEAD_NAME_BG}):updateLabel({fnt = FONT.D19, fontSize = 24, outline = "#000000", reqW = 200})
    local layerSize = cc.size(bg:getContentSize().width, bg:getContentSize().height + nameTitle:getContentSize().height)

    --- 解决头像点击后，回不到原来的缩放比例的问题
    local blockLayer = ui.layer({size = layerSize, scale = 0.9})
    view:addList(blockLayer)

    local cellNode = ui.layer({size = layerSize, color = cc.r4b(0), enable = true})
    blockLayer:addList(cellNode):alignTo(nil, ui.cc)

    --[bg | nameTitle]
    local cellGroup = cellNode:addList({
        ui.layer({size = bg:getContentSize()}),
        nameTitle,
    })
    ui.flowLayout(cc.rep(cc.sizep(cellNode, ui.cc), 10, 10), cellGroup, {type = ui.flowV, ap = ui.cc})

    local bgView = cellGroup[1]:addList({
        bg,
        SkinCollectionMainScene.GetFilterImg(),
        SkinCollectionMainScene.GetFilterImg(RES_DICT.HEAD_FRAME, 1.1),
    })
    ui.flowLayout(cc.rep(cc.sizep(cellGroup[1], ui.cc), 0, -15), bgView, {type = ui.flowC, ap = ui.cc})

    bgView[3]:setPosition(cc.rep(cc.p(bgView[3]:getPosition()), 7, 1))

    local addImg = ui.image({img = RES_DICT.NEW_ICON})
    cellGroup[1]:addList(addImg):alignTo(nil, ui.rt, {offsetY = -5})

    return {
        view      = view,
        nameTitle = nameTitle,
        headIcon  = bgView[2],
        cellNode  = cellNode,
        frame     = bgView[3],
        addImg    = addImg,
    }
end


function SkinCollectionMainScene.CreateSkinTypeCell(cellParent)
    local view  = ui.layer({size = SkinCollectionMainScene.CELL_SIZE, color = cc.r4b(0), enable = true})
    cellParent:addList(view):alignTo(nil, ui.cc)

    local selectedImg = ui.image({img = RES_DICT.FILTER_CELL_SELECTED, scale9 = true, size = cc.resize(SkinCollectionMainScene.CELL_SIZE, 10, 0)})
    view:addList(selectedImg):alignTo(nil, ui.cc)

    local titleLabel = ui.label({fnt = SkinCollectionMainScene.CELL_TITLE_FONT, text = "--", p = SkinCollectionMainScene.CELL_TITLE_POS})
    view:addList(titleLabel):alignTo(nil, ui.cc)
    
    local imgLine = ui.image({img = RES_DICT.FILTER_CELL_LINE, scale9 = true, size = cc.size(SkinCollectionMainScene.CELL_SIZE.width, 3)})
    view:addList(imgLine):alignTo(nil, ui.cb, {offsetY = -2})

    local imgIcon = ui.image({img = CardUtils.GetCardSkinTypeIconPathBySkinType(CardUtils.DEFAULT_SKIN_TYPE), scale = SkinCollectionMainScene.CELL_ICON_SCALE})
    view:addList(imgIcon):alignTo(nil, ui.lc, {offsetX = SkinCollectionMainScene.CELL_BG_SPA * 0.5})
    return {
        view                = view,
        iconImg             = imgIcon,
        titleLabel          = titleLabel,
        selectedImg         = selectedImg,
    }
end


function SkinCollectionMainScene.CreateSkinStateCell(strName, cellH, stateBtnHandler)
    local cellLayer = ui.layer({size = cc.size(80, cellH), color = cc.r4b(0), enable = true, cb = stateBtnHandler})

    local titleGroup = cellLayer:addList({
        ui.label({fnt = FONT.D11, text = tostring(strName)}),
        ui.image({img = RES_DICT.FILTER_CELL_LINE, scale9 = true}),
    })
    cellLayer.titleGroup  = titleGroup
    cellLayer.contentSize = cc.size(display.getLabelContentSize(titleGroup[1]).width * 2, cellH)
    return cellLayer
end


function SkinCollectionMainScene.CreateSkinTypeView(typeBtnHandler)
    local view = ui.layer()
    local showMaxNum = math.min(CONF.CARD.SKIN_COLL_TYPE:GetLength() + 1, 10)
    local bgSize     = cc.size(SkinCollectionMainScene.CELL_SIZE.width, SkinCollectionMainScene.CELL_SIZE.height * showMaxNum)
    local bgFrame = view:addList({
        ui.layer({color = cc.c4b(0,0,0,140), enable = true}),
        ui.layer({size = bgSize}),
    })
    local centerLayer = bgFrame[2]
    local frameBg     = ui.image({img = RES_DICT.FILTER_BG, scale9 = true, size = cc.size(bgSize.width + 10, bgSize.height + 10)})
    centerLayer:addList(frameBg):alignTo(nil, ui.cc)
    local arrowBg     = centerLayer:addList(ui.image({img = RES_DICT.ARROW_BG, p = cc.p(-2, 0), rotation = -90}))
    
    ------------------------------------------createTableView
    local typeTableView = ui.tableView({size = bgSize, dir = display.SDIR_V, csizeH = SkinCollectionMainScene.CELL_SIZE.height})
    centerLayer:addList(typeTableView):alignTo(nil, ui.cc)
    typeTableView:setCellCreateHandler(SkinCollectionMainScene.CreateSkinTypeCell)
    return {
        blockLayer    = bgFrame[1],
        centerLayer   = centerLayer,
        view          = view,
        arrowBg       = arrowBg,
        typeTableView = typeTableView,
    }
end


function SkinCollectionMainScene.CreateSkinStateView(stateBtnHandler)
    local view = ui.layer()

    local bgFrame = view:addList({
        ui.layer({color = cc.c4b(0,0,0,140), enable = true}),
        ui.layer(),
    })
    local centerLayer = bgFrame[2]

    local bgView = centerLayer:addList({
        ui.image({img = RES_DICT.FILTER_BG, scale9 = true}),
        ui.image({img = RES_DICT.ARROW_BG, p = cc.p(2, 0), rotation = -90}),
        ui.image({img = RES_DICT.FILTER_CELL_SELECTED, scale9 = true}),
    })
    local bg = bgView[1]
    ---------------------------------------- createCell
    local stateCellNodes = {}
    local CELL_HEIGHT = 58

    local titleGroupTexts = {__("全部"), __("已拥有"), __("未拥有")}
    local maxCellWidth = 0

    for cellIndex, titleStr in ipairs(titleGroupTexts) do
        local stateCell = SkinCollectionMainScene.CreateSkinStateCell(titleStr, CELL_HEIGHT, stateBtnHandler)
        stateCell:setTag(checkint(cellIndex - 1))
        maxCellWidth = math.max(maxCellWidth, stateCell.contentSize.width)

        table.insert(stateCellNodes, stateCell)
    end
    
    for cellIndex, stateCell in pairs(stateCellNodes) do
        stateCell:setContentSize(cc.size(maxCellWidth, CELL_HEIGHT))
        ui.flowLayout(cc.rep(cc.sizep(stateCell, ui.ct), 0, -15), stateCell.titleGroup, {type = ui.flowV, ap = ui.cb, gapH = 15})
    end
    centerLayer:addList(stateCellNodes)

    ----------------------------------------------- resize
    bg:setContentSize(cc.size(maxCellWidth, CELL_HEIGHT * #titleGroupTexts + 10))
    centerLayer:setContentSize(cc.size(maxCellWidth, CELL_HEIGHT * #titleGroupTexts))
    bg:alignTo(nil, ui.cc, {offsetY = -2})
    ui.flowLayout(cc.sizep(centerLayer, ui.cc), stateCellNodes, {type = ui.flowV, ap = ui.cc})

    local selectedImg = bgView[3]
    selectedImg:setContentSize(cc.size(maxCellWidth - 10, CELL_HEIGHT))
    selectedImg:alignTo(stateCellNodes[1], ui.cc, {offsetY = -2})

    return {
        blockLayer     = bgFrame[1],
        centerLayer    = centerLayer,
        stateCellNodes = stateCellNodes,
        view           = view,
        arrowBg        = bgView[2],
        selectedImg    = selectedImg,
    }
end


function SkinCollectionMainScene.GetFilterImg(imgPath, scale)
    local node = FilteredSpriteWithOne:create()
    if imgPath then
        node:setTexture(imgPath)
    end
    if scale then
        node:setScale(scale)
    end
    return node
end


return SkinCollectionMainScene
