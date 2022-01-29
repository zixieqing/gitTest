local CatModuleCatListView = class('CatModuleCatListView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleCatListView', enableEvent = true})
end)

local RES_DICT = {
    --                   = cell
    WEEK_NAME_BG         = _res('ui/catModule/catList/grow_main_list_bg_state_1.png'),
    BREED_NAME_BG        = _res('ui/catModule/catList/grow_main_list_bg_state_2.png'),
    DEAD_NAME_BG         = _res('ui/catModule/catList/grow_main_list_bg_state_3.png'),
    CAT_BG_GREY          = _res('ui/catModule/catList/grow_main_list_bg_cat_back_grey.png'),
    CAT_BG               = _res('ui/catModule/catList/grow_main_list_bg_cat_back.png'),
    CAT_FRAME            = _res('ui/catModule/catList/grow_main_list_bg_cat_big.png'),
    CAT_LEVEL_BG_GREY    = _res('ui/catModule/catList/grow_main_list_bg_year_dead.png'),
    REBIRTH_BG_DEAD      = _res('ui/catModule/catList/grow_main_list_bg_year_dead.png'),
    REBIRTH_BG_NORM      = _res('ui/catModule/catList/grow_main_list_bg_year_gray.png'),
    REBIRTH_BG_SPE       = _res('ui/catModule/catList/grow_main_list_bg_year_light.png'),
    TIME_BG              = _res('ui/catModule/catList/grow_main_list_bg_state_time.png'),
    REBIRTH_ICON_DEAD    = _res('ui/catModule/catList/grow_main_list_ico_egg_dead.png'),
    REBIRTH_ICON_NORM    = _res('ui/catModule/catList/grow_main_list_ico_egg.png'),
    REBIRTH_ICON_SPE     = _res('ui/catModule/catList/grow_main_list_ico_year_chane.png'),
    PROGRESS_BG          = _res('ui/catModule/catList/grow_main_list_line_bag.png'),
    PROGRESS_IMG         = _res('ui/catModule/catList/grow_main_list_line_bag_light.png'),
    PROGRESS_ICON        = _res('ui/catModule/catList/grow_main_list_ico_bag.png'),
    IMG_LINE             = _res('ui/catModule/catList/grow_main_list_line.png'),
    IMG_NAME_BG          = _res('ui/catModule/catPreview/grow_get_name.png'),
    GIRL_ICON            = _res('ui/catModule/catList/grow_main_list_ico_f.png'),
    BOY_ICON             = _res('ui/catModule/catList/grow_main_list_ico_m.png'),
    --                   = center
    COMMON_BG_GOODS      = _res('ui/common/common_bg_goods.png'),
    GUILD_SHOP_BG_WHITE  = _res('ui/home/union/guild_shop_bg_white.png'),
    GUILD_SHOP_BG        = _res('ui/home/union/guild_shop_bg.png'),
    GUILD_SHOP_TITLE     = _res('ui/home/union/guild_shop_title.png'),
    ADD_BTN_IMG          = _res('ui/common/common_btn_add.png'),
    SHIFT_BTN_N          = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'),
    SHIFT_BTN_S          = _res('ui/home/teamformation/choosehero/team_btn_selection_choosed.png'),
    --                   = filter cell
    FILTER_BG            = _res('ui/home/cardslistNew/tujian_selection_frame_1.png'),
    FILTER_CELL_LINE     = _res('ui/common/tujian_selection_line.png'),
    FILTER_CELL_SELECTED = _res('ui/home/cardslistNew/tujian_selection_select_btn_filter_selected.png'),
    ARROW_IMG            = _res('ui/catModule/catList/cat_house_ico_arrowhead.png'),
    --                   = spine
    DEAD_SPINE           = _spn('ui/catModule/catList/anim/cat_grow_main_list_dead'),
    EXTEND_SPINE         = _spn('ui/catModule/catList/anim/cat_grow_main_list_line'),
}

CatModuleCatListView.SORT_TAG = {
    ALGEBRA  = 1,
    AGE      = 2,
    GAINTIME = 3,
    STATUE   = 4,
}

local SORT_DATA = {
    [CatModuleCatListView.SORT_TAG.ALGEBRA]  = {title = __("代数")},
    [CatModuleCatListView.SORT_TAG.AGE]      = {title = __("年龄")},
    [CatModuleCatListView.SORT_TAG.GAINTIME] = {title = __("获得时间")},
    [CatModuleCatListView.SORT_TAG.STATUE]   = {title = __("状态")}
}

function CatModuleCatListView:ctor(args)
    -- create view
    self.viewData_ = CatModuleCatListView.CreateView()
    self:addChild(self.viewData_.view)

    self.filterViewData_ = CatModuleCatListView.CreateSiftStateView()
    self:getViewData().view:addList(self:getFilterViewData().view)

    local alignNode = self:getViewData().siftBtn
    local alignPos  = alignNode:getParent():convertToWorldSpace(cc.p(alignNode:getPosition()))
    self:getFilterViewData().centerLayer:setPosition(cc.rep(alignPos, 0, -25))
end


function CatModuleCatListView:getViewData()
    return self.viewData_
end

function CatModuleCatListView:getFilterViewData()
    return self.filterViewData_
end
-------------------------------------------------
-- public
-------------------------------------------------
function CatModuleCatListView:setFilterLayerVisible(visible)
    self:getFilterViewData().view:setVisible(visible)
end



function CatModuleCatListView:playExtendAnim()
    local extendAnim = ui.spine({path = RES_DICT.EXTEND_SPINE, cache = SpineCacheName.CAT_HOUSE, init = "idle", completeCB = function(event, spineNode)
        spineNode:runAction(cc.RemoveSelf:create())
    end})
    self:getViewData().progress:addList(extendAnim, 3):alignTo(nil, ui.cc)
end


function CatModuleCatListView:setSelectedSortType(sortType, isDes)
    local sortCell = self:getFilterViewData().sortCellNodeMap[sortType]
    self:getFilterViewData().selectedImg:alignTo(sortCell, ui.cc)

    sortCell.isDes = isDes or 1 - checkint(sortCell.isDes)
    local isDes    = checkint(sortCell.isDes) == 1
    local scaleY   = isDes and -1 or 1
    sortCell.imgArrow:setScaleY(scaleY)
    
    return isDes
end


function CatModuleCatListView:updateCatCellHandler(cellIndex, cellViewData, catUuid)
    cellViewData.view.catUuid = catUuid

    local catModel = app.catHouseMgr:getCatModel(catUuid)
     
    -- updata cat spine
    cellViewData.catLayer:removeAllChildren()
    local catSpineNode = CatHouseUtils.GetCatSpineNode({catUuid = catUuid, scale = 0.65})
    cellViewData.catLayer:addList(catSpineNode):alignTo(nil, ui.cc)

    -- isAlive
    self:updateAliveState(cellViewData, catModel:isAlive())

    -- isRebirth
    cellViewData.levelTitleBG:setChecked(catModel:isRebirth())
    cellViewData.rebirthIcon:setVisible(catModel:isRebirth())

    -- generation
    cellViewData.levelTitleText:setString(catModel:getGeneration())

    -- sex
    cellViewData.sexIcon:setChecked(catModel:getSex() == CatHouseUtils.CAT_SEX_TYPE.BOY)

    -- name
    cellViewData.nameLabel:updateLabel({text = catModel:getName(), reqW = 210})

    -- age
    self:updateCatCellAge(cellViewData, catModel:getAge())
    
    -- attr
    for attrId, attrNode in pairs(cellViewData.attrCellMap) do
        attrNode:setChecked(catModel:getAttrNum(attrId) < CatHouseUtils.CAT_ATTR_ALERT_NUM)
    end

    -- refresh state
    self:refreshBreedTime(cellViewData, catModel)
end

function CatModuleCatListView:updateAliveState(cellViewData, isAlive)
    cellViewData.levelTitleBG:setEnabled(isAlive)
    cellViewData.levelIcon:setEnabled(isAlive)
    cellViewData.bgFrame:setChecked(not isAlive)
    if not isAlive then
        local deadEffect = ui.spine({path = RES_DICT.DEAD_SPINE, cache = SpineCacheName.CAT_HOUSE, init = "idle", loop = true})
        cellViewData.deadEffectLayer:addList(deadEffect):alignTo(nil, ui.cc, {offsetY = -5})
    else
        cellViewData.deadEffectLayer:removeAllChildren()
    end
end


function CatModuleCatListView:updateCatCellAge(cellViewData, ageNum)
    local ageConf = CONF.CAT_HOUSE.CAT_AGE:GetValue(ageNum)
    cellViewData.ageLabel:updateLabel({text = ageConf.name, reqW = 150})
end


---@param catModel HouseCatModel
function CatModuleCatListView:refreshBreedTime(cellViewData, catModel)
    local isDoNothing = catModel:isDoNothing()
    local isSicked    = catModel:isSicked()
    local isDie       = not catModel:isAlive()
    local showCatState = isDie or isSicked or not isDoNothing
    cellViewData.catStateImg:setVisible(showCatState)
    cellViewData.catStateImg:setChecked(isSicked)
    cellViewData.catStateImg:setEnabled(not isDie)
    cellViewData.timeTitle:setVisible(not isDie and not isDoNothing)

    if not isDie and not isDoNothing then
        local stateStr = ""
        local leftTime = os.time()
        if catModel:isMating() then
            stateStr = __("孕育中")
            leftTime = catModel:getMatingLeftSeconds()
        elseif catModel:isStudying() then
            stateStr = __("学习中")
            leftTime = catModel:getStudyLeftSeconds()
        elseif catModel:isWorking() then
            stateStr = __("工作中")
            leftTime = catModel:getWorkLeftSeconds()
        elseif catModel:isOutGoing() then
            stateStr = __("外出中")
            leftTime = catModel:getOutLeftSeconds()
        elseif catModel:isSleeping() then
            stateStr = __("睡觉中")
            leftTime = catModel:getSleepLeftSeconds()
        elseif catModel:isHousing() then
            stateStr = __("等待中")
            leftTime = catModel:getHouseLeftSeconds()
        else
            stateStr = __("如厕中")
            leftTime = catModel:getToiletLeftSeconds()
        end
        cellViewData.normalStr:updateLabel({text = stateStr, reqW = 190})
        local timeText = CommonUtils.getTimeFormatByType(math.max(checkint(leftTime), 0), 2)
        cellViewData.timeTitle:updateLabel({text = timeText})
    end
end

function CatModuleCatListView:setCatWarehouseCapacity(curCapacity, totalCapacity)
    self:getViewData().progress:setValue(curCapacity / totalCapacity * 100)
    self:getViewData().progressLabel:setString(string.fmt("_num1_/_num2_", {_num1_ = curCapacity, _num2_ = totalCapacity}))
end
-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatModuleCatListView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local viewFrame = ui.layer({bg = RES_DICT.GUILD_SHOP_BG})
    local viewSize  = cc.resize(viewFrame:getContentSize(), -100, -20)
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150), enable = true}),
        ui.layer({color = cc.r4b(0), enable = true, size = viewSize}),
        viewFrame,
        ui.layer({size = viewSize}),
    })
    ui.flowLayout(cpos, backGroundGroup, {type = ui.flowC, ap = ui.cc})

    -- centerLayer
    local centerLayer = backGroundGroup[4]
    local bgFrame = ui.image({img = RES_DICT.GUILD_SHOP_BG_WHITE})
    centerLayer:addList(bgFrame):alignTo(nil, ui.cc, {offsetY = -20})

    -- frameGroup
    local gridBgSize = cc.resize(viewSize, -70, -145)
    local frameGroup = centerLayer:addList({
        ui.title({n = RES_DICT.GUILD_SHOP_TITLE}):updateLabel({fnt = FONT.D18, text = __("猫咪列表"), reqW = 240}),
        ui.layer({size = cc.size(gridBgSize.width, 80)}),
        ui.layer({bg = RES_DICT.COMMON_BG_GOODS, scale9 = true, size = gridBgSize})
    })
    ui.flowLayout(cc.sizep(centerLayer, ui.cc), frameGroup, {type = ui.flowV, ap = ui.cc})

    local operatorLayer = frameGroup[2]
    local progress      = ui.pBar({bg = RES_DICT.PROGRESS_BG, img = RES_DICT.PROGRESS_IMG})
    operatorLayer:addList(progress):alignTo(nil, ui.lc, {offsetX = 10})

    local progressIcon = ui.image({img = RES_DICT.PROGRESS_ICON})
    progress:addList(progressIcon, 3):alignTo(nil, ui.lc)

    local progressAddBtn = ui.button({n = RES_DICT.ADD_BTN_IMG})
    operatorLayer:addList(progressAddBtn, 3):alignTo(progress, ui.rc, {offsetX = -30})

    local progressLabel = ui.label({fnt = FONT.D9, text = "--"})
    progress:addList(progressLabel, 3):alignTo(nil, ui.cc)

    local siftBtn = ui.button({n = RES_DICT.SHIFT_BTN_N}):updateLabel({fnt = FONT.D14, text = __("筛选"), reqW = 110})
    operatorLayer:addList(siftBtn):alignTo(nil, ui.rc, {offsetX = -5})

    -- gridView
    local gridLayer = frameGroup[3]
    local gridSize  = gridLayer:getContentSize()
    local GRID_COL  = 4
    local catGridView = ui.gridView({cols = GRID_COL, dir = display.SDIR_V, csizeH = 380, size = gridSize})
    gridLayer:addList(catGridView):alignTo(nil, ui.cc)
    catGridView:setCellCreateHandler(CatModuleCatListView.CreateCatCell)

    return {
        view           = view,
        blockLayer     = backGroundGroup[1],
        --             = center
        centerLayer    = centerLayer,
        catGridView    = catGridView,
        progress       = progress,
        progressLabel  = progressLabel,
        progressAddBtn = progressAddBtn,
        siftBtn        = siftBtn,
    }
end

function CatModuleCatListView.CreateCatCell(cellParent)
    local size = cellParent:getContentSize()
    local view = ui.layer({size = size, color = cc.r4b(0), enable = true})
    cellParent:addList(view):alignTo(nil, ui.cc)

    local bgFrame = ui.tButton({n = RES_DICT.CAT_BG, s = RES_DICT.CAT_BG_GREY})
    view:addList(bgFrame):alignTo(nil, ui.ct, {offsetY = -10})

    local catLayerSize = cc.resize(bgFrame:getContentSize(), 0, 0)
    local catLayer = ui.layer({size = catLayerSize})
    bgFrame:addList(catLayer):alignTo(nil, ui.cc)
    
    local catClipNode  = ui.clipNode({size = catLayerSize, at = 1, stencil = {img = RES_DICT.BG_FRAME, scale9 = true, size = catLayerSize, ap = ui.lb}})
    catLayer:addList(catClipNode):alignTo(nil, ui.cc, {offsetY = 0, offsetX = 0})

    local infoFrame = ui.layer({bg = RES_DICT.CAT_FRAME})
    view:addList(infoFrame):alignTo(nil, ui.cc)

    local bgFrameGroup = infoFrame:addList({
        ui.layer({size = cc.size(size.width - 40, size.height * 0.5), color = cc.r4b(0)}),
        ui.title({img = RES_DICT.IMG_NAME_BG}):updateLabel({fnt = FONT.D18, color = "#fef2cf", text = "--"}),
        ui.layer({size = cc.size(size.width - 40, 40), color = cc.r4b(0)}),
        ui.image({img = RES_DICT.IMG_LINE}),
        ui.layer({size = cc.size(size.width - 40, 90), color = cc.r4b(0)}),
    })
    ui.flowLayout(cc.sizep(infoFrame, ui.cc), bgFrameGroup, {type = ui.flowV, ap = ui.cc})

    -- catInfoLayer
    local catInfoLayer = bgFrameGroup[1]
    local levelTitleBG   = ui.tButton({n = RES_DICT.REBIRTH_BG_NORM, d = RES_DICT.REBIRTH_BG_DEAD, s= RES_DICT.REBIRTH_BG_SPE})
    local levelTitleText = ui.label({fnt = FONT.D18, text = "--"})
    catInfoLayer:addList(levelTitleBG):alignTo(nil, ui.lt)
    levelTitleBG:addList(levelTitleText):alignTo(nil, ui.cc, {offsetX = 10})

    -- state
    local catStateImg = ui.tButton({n = RES_DICT.BREED_NAME_BG, s = RES_DICT.WEEK_NAME_BG, d = RES_DICT.DEAD_NAME_BG})
    catInfoLayer:addList(catStateImg):alignTo(nil, ui.cc, {offsetY= -10})

    catStateImg:getSelectedImage():addList(ui.label({fnt = FONT.D19, fontSize = 22, outline = "#821e0f", text = __("生病中"), reqW = 190})):alignTo(nil, ui.cc)
    local normalStr = ui.label({fnt = FONT.D19, fontSize = 22, outline = "#304767", text = __("孕育中"), reqW = 190})
    catStateImg:getNormalImage():addList(normalStr):alignTo(nil, ui.cc)
    catStateImg:getDisabledImage():addList(ui.label({fnt = FONT.D19, fontSize = 22, outline = "#2e2e2e", text = __("回喵星"), reqW = 190})):alignTo(nil, ui.cc)

    -- rebirth leftTime
    local timeTitle = ui.title({img = RES_DICT.TIME_BG}):updateLabel({fnt = FONT.D5, color = "#B7a892", text = "--", offset = cc.p(0, 5)})
    catInfoLayer:addList(timeTitle):alignTo(nil, ui.cc, {offsetY = -60})

    -- level
    local levelIcon = ui.button({n = RES_DICT.REBIRTH_ICON_NORM, d = RES_DICT.REBIRTH_ICON_DEAD})
    levelTitleBG:addList(levelIcon):alignTo(nil, ui.lc)

    local rebirthIcon = ui.image({img = RES_DICT.REBIRTH_ICON_SPE})
    levelTitleBG:addList(rebirthIcon):alignTo(nil, ui.lc, {offsetX = -15})

    local sexIcon = ui.tButton({n = RES_DICT.GIRL_ICON, s = RES_DICT.BOY_ICON})
    sexIcon:setTouchEnabled(false)
    catInfoLayer:addList(sexIcon):alignTo(nil, ui.rb, {offsetX = 10, offsetY = -5})

    local deadEffectLayer = ui.layer({size = catInfoLayer:getContentSize()})
    catInfoLayer:addList(deadEffectLayer)

    -- catState title layer
    local stateInfoLayer = bgFrameGroup[3]
    local stateTit = ui.label({fnt = FONT.D18, color = "#6c472d", text = __("状态:")})
    stateInfoLayer:addList(stateTit):alignTo(nil, ui.lc, {offsetX = 10})

    local ageLabel = ui.label({fnt = FONT.D18, color = "#B6967B", text = "--", ap = ui.rc})
    stateInfoLayer:addList(ageLabel):alignTo(nil, ui.rc, {offsetX = -10})

    -- cat value layer
    local attrCellMap   = {}
    local sortCellNodeMap = {}
    local attrIconLayer = bgFrameGroup[5]
    for i, attrId in pairs(CONF.CAT_HOUSE.CAT_ATTR:GetIdList()) do
        local attrNor = CatHouseUtils.GetCatAttrTypeIconPath(attrId)
        local attrSel = CatHouseUtils.GetCatAttrTypeIconPath(attrId, true)

        local attrNode = ui.tButton({n = attrNor, s = attrSel, scale = 0.5})
        attrNode:setTouchEnabled(false)
        attrIconLayer:addList(attrNode)
        
        attrCellMap[checkint(attrId)] = attrNode
        local row = math.floor(i / 3.1)
        if not sortCellNodeMap[row] then
            sortCellNodeMap[row] = {}
        end
        table.insert(sortCellNodeMap[row], attrNode)
    end

    for row, attrNodes in pairs(sortCellNodeMap) do
        ui.flowLayout(cc.rep(cc.sizep(attrIconLayer, ui.ct), 0, (row - 1) * 40), attrNodes, {type = ui.flowH, ap = ui.ct, gapW = 40})
    end

    return {
        view            = view,
        levelIcon       = levelIcon,
        levelTitleBG    = levelTitleBG,
        levelTitleText  = levelTitleText,
        sexIcon         = sexIcon,
        ageLabel        = ageLabel,
        catLayer        = catClipNode,
        nameLabel       = bgFrameGroup[2],
        attrCellMap     = attrCellMap,
        deadEffectLayer = deadEffectLayer,
        catStateImg     = catStateImg,
        normalStr       = normalStr,
        timeTitle       = timeTitle,
        rebirthIcon     = rebirthIcon,
        bgFrame         = bgFrame,
    }
end


function CatModuleCatListView.CreateSiftStateView(stateBtnHandler)
    local view = ui.layer()
    view:setVisible(false)
    ---------------------------------------- findMaxStr
    local titleGroupTexts = {__("代数"), __("年龄"), __("获得时间"), __("状态")}
    local maxLen    = 0
    local maxLenStr = ""
    for _, sortData in ipairs(SORT_DATA) do
        local titleStrLen  = string.len(sortData.title)
        if maxLen < titleStrLen then
            maxLen    = titleStrLen
            maxLenStr = sortData.title
        end
    end

    local CELL_TITLE_FONT      = FONT.D11
    local CELL_IMG_TEXT_SPA    = 10
    local CELL_BG_SPA          = 20

    local debugTitle = ui.label({fnt = CELL_TITLE_FONT, text = maxLenStr})
    local debugIcon  = ui.image({img = RES_DICT.ARROW_IMG})
    local iconSizeW  = debugIcon:getContentSize().width
    local CELL_SIZE  = cc.size(display.getLabelContentSize(debugTitle).width + iconSizeW + CELL_IMG_TEXT_SPA + CELL_BG_SPA, 58)

    ---------------------------------------- create view
    local bgFrame = view:addList({
        ui.layer({color = cc.r4b(0), enable = true}),
        ui.layer({size  = cc.size(CELL_SIZE.width, CELL_SIZE.height * #titleGroupTexts), ap = ui.ct}),
    })
    local centerLayer = bgFrame[2]

    local bg = ui.image({img = RES_DICT.FILTER_BG, scale9 = true, size = cc.size(CELL_SIZE.width + 10, CELL_SIZE.height * #titleGroupTexts + 10)})
    centerLayer:addList(bg):alignTo(nil, ui.cc)

    local selectedImg = ui.image({img = RES_DICT.FILTER_CELL_SELECTED, scale9 = true, size = CELL_SIZE})
    centerLayer:addList(selectedImg)
    ---------------------------------------- createCell
    local sortCellNodeMap = {}
    local sortCellNodes   = {}
    for sortTag, sortData in ipairs(SORT_DATA) do
        local sortCellNode = CatModuleCatListView.CreateStateCell(sortData.title, CELL_SIZE)
        sortCellNode:setTag(sortTag)
        sortCellNodeMap[sortTag] = sortCellNode

        table.insert(sortCellNodes, sortCellNode)
    end
    centerLayer:addList(sortCellNodes)
    ui.flowLayout(cc.sizep(centerLayer, ui.cc), sortCellNodes, {type = ui.flowV, ap = ui.cc})

    return {
        blockLayer      = bgFrame[1],
        centerLayer     = centerLayer,
        sortCellNodeMap = sortCellNodeMap,
        view            = view,
        selectedImg     = selectedImg,
    }
end

function CatModuleCatListView.CreateStateCell(strName, cellSize)
    local cellLayer = ui.layer({size = cellSize, color = cc.r4b(0), enable = true})

    local titleGroup = cellLayer:addList({
        ui.layer({size = cc.size(cellSize.width, 57)}),
        ui.image({img = RES_DICT.FILTER_CELL_LINE, scale9 = true, size = cc.size(cellSize.width, 5)}),
    })
    ui.flowLayout(cc.sizep(cellSize, ui.cc), titleGroup, {type = ui.flowV, ap = ui.cc})

    local titleLayer   = titleGroup[1]
    local imgArrow     = ui.image({img = RES_DICT.ARROW_IMG})
    cellLayer.imgArrow = imgArrow
    titleLayer:addList(imgArrow):alignTo(nil, ui.rc, {offsetX = -10})
    
    local title = ui.label({fnt = FONT.D11, text = tostring(strName), p = cc.rep(cc.sizep(titleLayer, ui.cc), -20, 0)})
    titleLayer:addList(title)
    return cellLayer
end

return CatModuleCatListView
