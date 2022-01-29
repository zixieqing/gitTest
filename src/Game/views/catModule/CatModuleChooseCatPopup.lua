--[[
 * author : panmeng
 * descpt : 猫屋 选择猫咪 界面
]]
local CommonDialog            = require('common.CommonDialog')
local CatModuleChooseCatPopup = class('CatModuleChooseCatPopup', CommonDialog)

local RES_DICT = {
    VIEW_FRAME      = _res('ui/common/common_bg_2.png'),
    BACK_BTN        = _res('ui/common/common_btn_back.png'),
    TITLE_BAR       = _res('ui/common/common_bg_title_2.png'),
    TITLE_PROPERTY  = _res('ui/common/common_title_3.png'),
    LIST_FRAME      = _res('ui/common/common_bg_list_3.png'),
    BTN_CANCEL      = _res('ui/common/common_btn_white_default.png'),
    BTN_CONFIRM     = _res('ui/common/common_btn_orange.png'),
    GRID_VIEW_BG    = _res('ui/catHouse/home/common_bg_goods.png'),
    CHECK_BG        = _res('ui/catHouse/chooseCat/cat_btn_check_default.png'),
    CHECK_IMG       = _res('ui/catHouse/chooseCat/activity_ico_novice_seven_day_arrow.png'),
    OUT_INFO_BG     = _res('ui/catHouse/chooseCat/cat_select_frequency_bg.png'),
    OUT_TIP_BG      = _res('ui/catHouse/chooseCat/cat_select_tips_bg.png'),
    TAB_BTN_GREY    = _res('ui/catHouse/chooseCat/grow_cat_record_love_btn_type_grey.png'),
    TAB_BTN_LIGHT   = _res('ui/catHouse/chooseCat/grow_cat_record_love_btn_type_light.png'),
    PROPERTY_BG     = _res('ui/catHouse/chooseCat/common_bg_frequenter.png'),
    PROP_CELL_BG_L  = _res('ui/catHouse/chooseCat/cat_pet_bg_attribute_list_1.png'),
    PROP_CELL_BG_G  = _res('ui/catHouse/chooseCat/cat_pet_bg_attribute_list_2.png'),
    PROP_CELL_LINE  = _res('ui/catHouse/chooseCat/cat_ico_attribute_line.png')

}


function CatModuleChooseCatPopup:ctor(args)
    self:setPosition(display.center)

    -- init vars
    local initArgs         = checktable(args)
    self.confirmCB_        = initArgs.confirmCB
    self.equipConfirmCB_   = initArgs.equipConfirmCB
    self.multipChooseMix_  = initArgs.multipChooseMix or 1
    self.multipChooseMax_  = initArgs.multipChooseMax or 1
    self.choosePopupType_  = initArgs.choosePopupType or CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.HOUSE_PLACE
    self.selectedTab_      = self.choosePopupType_
    self.equipCatId_       = app.gameMgr:GetUserInfo().equippedHouseCat.id and CatHouseUtils.BuildCatUuid(app.gameMgr:GetPlayerId(), app.gameMgr:GetUserInfo().equippedHouseCat.id)
    self.buffMap_          = {}
    self.selectedCatIdMap_ = {}
    if initArgs.selectedCatIdList then
        for _, catUuid in ipairs(initArgs.selectedCatIdList) do
            self.selectedCatIdMap_[catUuid] = true
        end
    end
    
    -- create view
    self.viewData_ = CatModuleChooseCatPopup.CreateView(initArgs.confirmStr)
    self:add(self:getViewData().view)

    -- add listener
    ui.bindClick(self:getViewData().confirmBtn, handler(self, self.onClickConfirmBtnHandler_))
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_))
    self:getViewData().gridView:setCellUpdateHandler(handler(self, self.onUpdateCellHandler_))
    self:getViewData().gridView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.view, handler(self, self.onClickCellHandler_), false)
    end)
    self:getViewData().propertyListView:setCellUpdateHandler(handler(self, self.onUpdatePropertyCellHandler_))
    for i, v in ipairs(self:getViewData().tabGroup) do
        ui.bindClick(v, handler(self, self.onClickTabCellHandler_), false)
    end
    -- init view
    self:initView()
end


function CatModuleChooseCatPopup:getViewData()
    return self.viewData_
end


-------------------------------------------------------------
-- get/set

--@see CatHouseUtils.CAT_CHOOSE_POPUP_TYPE
function CatModuleChooseCatPopup:getChoosePopupType()
    return checkint(self.choosePopupType_)
end


-- choose mix
function CatModuleChooseCatPopup:getMutipleChooseMix()
    if self:getSelectedTab() == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.EQUIP_CAT then
        return 1
    end
    return checkint(self.multipChooseMix_)
end


-- choose max
function CatModuleChooseCatPopup:getMutipleChooseMax()
    if self:getSelectedTab() == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.EQUIP_CAT then
        return 1
    end
    return checkint(self.multipChooseMax_)
end


-- selected cat
function CatModuleChooseCatPopup:getSelectedCatIdMap()
    return checktable(self.selectedCatIdMap_)
end
function CatModuleChooseCatPopup:addSelectedCatId(catUuid)
    if self:getSelectedTab() == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.EQUIP_CAT then
        self:setEquipCatId(catUuid)
    else
        self.selectedCatIdMap_[catUuid] = true
    end
    for _, cellViewData in pairs(self:getViewData().gridView:getCellViewDataDict()) do
        if cellViewData.view.catUuid == catUuid then
            cellViewData.view.setChecked(true)
        end
    end
end
function CatModuleChooseCatPopup:delSelectedCatId(catUuid)
    if self:getSelectedTab() == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.EQUIP_CAT then
        self:setEquipCatId()
    else
        self.selectedCatIdMap_[catUuid] = nil
    end
    for _, cellViewData in pairs(self:getViewData().gridView:getCellViewDataDict()) do
        if cellViewData.view.catUuid == catUuid then
            cellViewData.view.setChecked(false)
        end
    end
end
function CatModuleChooseCatPopup:isCatSelected(catUuid)
    if self:getSelectedTab() == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.EQUIP_CAT then
        return catUuid == self:getEquipCatId()
    end
    return checkbool(self:getSelectedCatIdMap()[catUuid])
end


-- all cats
function CatModuleChooseCatPopup:getCatUuidList()
    return checktable(self.catUuIdList_)
end


-- selected cats
function CatModuleChooseCatPopup:getSelectedCats()
    return table.keys(self:getSelectedCatIdMap())
end

function CatModuleChooseCatPopup:getSelectedTab()
    return self.selectedTab_
end

function CatModuleChooseCatPopup:setSelectedTab( type )
    self.selectedTab_ = type
end

function CatModuleChooseCatPopup:getEquipCatId()
    return self.equipCatId_
end

function CatModuleChooseCatPopup:setEquipCatId( catId )
    self.equipCatId_ = catId
end

function CatModuleChooseCatPopup:setBuffMap( buffMap )
    self.buffMap_ = buffMap
end

function CatModuleChooseCatPopup:getBuffMap()
    return self.buffMap_ or {}
end


function CatModuleChooseCatPopup:setTabViewVisible( visible )
    local viewData = self:getViewData()
    local visible_ = visible and true or false
    viewData.tabView:setVisible(visible_)
    if visible then
        self:refreshTabView()
    end
end

function CatModuleChooseCatPopup:setPropertyViewVisible( visible )
    local viewData = self:getViewData()
    local visible_ = visible and true or false
    viewData.propertyView:setVisible(visible_)
end

-------------------------------------------------------------
-- public

function CatModuleChooseCatPopup:close()
    self:runAction(cc.RemoveSelf:create())
end

function CatModuleChooseCatPopup:initView()
    self:switchView(self:getChoosePopupType())
end

function CatModuleChooseCatPopup:switchView( type )
    if type == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.HOUSE_PLACE then
        self:setTabViewVisible(true)
        self:setPropertyViewVisible(false)
        self:initGridView()
    elseif type == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.OUT_GOING then
        self:setTabViewVisible(false)
        self:setPropertyViewVisible(false)
        self:initGridView()
    elseif type == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.EQUIP_CAT then
        self:setTabViewVisible(true)
        self:setPropertyViewVisible(true)
        self:initGridView()
        self:refreshPropertyView()
    end
end

function CatModuleChooseCatPopup:initGridView()
    self.catUuIdList_ = table.keys(app.catHouseMgr:getCatsModelMap())
    if self:getSelectedTab() == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.HOUSE_PLACE then
        table.sort(self.catUuIdList_, function(aCatUuid, bCatUuid)
            local aSelected = self:isCatSelected(aCatUuid) and 1 or 0
            local bSelected = self:isCatSelected(bCatUuid) and 1 or 0
            return aSelected > bSelected
        end)
    elseif self:getSelectedTab() == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.OUT_GOING then
        table.sort(self.catUuIdList_, function(aCatUuid, bCatUuid)
            local aCatModel = app.catHouseMgr:getCatModel(aCatUuid)
            local bCatModel = app.catHouseMgr:getCatModel(bCatUuid)
            local aOutEnable = aCatModel:isOutEnable() and 1 or 0
            local bOutEnable = bCatModel:isOutEnable() and 1 or 0
            return aOutEnable > bOutEnable
        end)
    elseif self:getSelectedTab() == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.EQUIP_CAT then
        table.sort(self.catUuIdList_, function(aCatUuid, bCatUuid)
            local aSelected = self:isCatSelected(aCatUuid) and 1 or 0
            local bSelected = self:isCatSelected(bCatUuid) and 1 or 0
            if aSelected ~= bSelected then
                return aSelected > bSelected
            else
                local aBuffAddition = CatHouseUtils.CalculateBuffTotalAddition(app.catHouseMgr:getCatModel(aCatUuid):getGeneMap())
                local bBuffAddition = CatHouseUtils.CalculateBuffTotalAddition(app.catHouseMgr:getCatModel(bCatUuid):getGeneMap())
                return aBuffAddition > bBuffAddition
            end
        end)
    end
    self:getViewData().gridView:resetCellCount(#self:getCatUuidList(), false, true)
end

function CatModuleChooseCatPopup:refreshTabView()
    local viewData = self:getViewData()
    local tabGroup = viewData.tabGroup
    for i, v in ipairs(checktable(tabGroup)) do
        if v:getTag() == self:getSelectedTab() then
            v:setNormalImage(RES_DICT.TAB_BTN_LIGHT)
        else
            v:setNormalImage(RES_DICT.TAB_BTN_GREY)
        end
    end
end

function CatModuleChooseCatPopup:refreshPropertyView()
    local buff = {}
    if self:getEquipCatId() then
        local catModel = app.catHouseMgr:getCatModel(self:getEquipCatId())
        if catModel then
            buff = CatHouseUtils.GetCatBuff(catModel:getGeneMap())
        end
    end
    if next(buff) ~= nil  then
        self:getViewData().propertyListView:setVisible(true)
        self:getViewData().noPropertyTips:setVisible(false)
        self:setBuffMap(buff)
        self:getViewData().propertyListView:resetCellCount(table.nums(buff), false, true)
    else
        self:getViewData().propertyListView:setVisible(false)
        self:getViewData().noPropertyTips:setVisible(true)
    end
    
end
-----------------------------------------------------
-- private

function CatModuleChooseCatPopup:onUpdateCellHandler_(cellIndex, cellViewData)
    local catUuid  = self:getCatUuidList()[cellIndex]
    local catModel = app.catHouseMgr:getCatModel(catUuid)
    cellViewData.catHeadNode:updateEquippedState(self:getSelectedTab() == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.EQUIP_CAT)
    cellViewData.catHeadNode:setCatUuid(catUuid)
    cellViewData.view.catUuid = catUuid
    
    if self:getChoosePopupType() == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.OUT_GOING then
        local outCountLeft = catModel:getOutCountLeft()
        local outCountMax  = catModel:getOutCountMax()
        cellViewData.outGoingTitle:setVisible(outCountLeft > 0 and catModel:isOutEnable())
        cellViewData.outGoingTxt:setString(string.fmt("_min_/_max_", {_min_ = outCountLeft, _max_ = outCountMax}))
        cellViewData.outGoingTip:setVisible(not catModel:isOutEnable())
        cellViewData.view:setTouchEnabled(true)
    else
        cellViewData.outGoingTitle:setVisible(false)
        cellViewData.outGoingTip:setVisible(false)
        cellViewData.view:setTouchEnabled(catModel:isPlaceableToSet())
    end
    
    cellViewData.view.setChecked(self:isCatSelected(catUuid))
end

function CatModuleChooseCatPopup:onUpdatePropertyCellHandler_(cellIndex, cellViewData)
    local buffMap = self:getBuffMap()
    local sortKeys = sortByKey(buffMap)
    local buff = buffMap[sortKeys[cellIndex]]
    local buffD = app.cardMgr.GetPropertyDefine(sortKeys[cellIndex])
    if cellIndex % 2 == 0 then
        cellViewData.bg:setTexture(RES_DICT.PROP_CELL_BG_G)
    else
        cellViewData.bg:setTexture(RES_DICT.PROP_CELL_BG_L)
    end
    cellViewData.title:setString(buffD.name)
    cellViewData.propIcon:setTexture(buffD.path)
    cellViewData.value:setString(tonumber(buff) * 100 .. '%')
    cellViewData.line:setVisible(cellIndex ~= table.nums(buffMap))
end

-------------------------------------------------------------
-- handler

function CatModuleChooseCatPopup:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()

    self:close()
end


function CatModuleChooseCatPopup:onClickConfirmBtnHandler_(sender)
    PlayAudioByClickNormal()
    if self:getSelectedTab() == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.EQUIP_CAT then
        if self.equipConfirmCB_ then
            self.equipConfirmCB_(self:getEquipCatId())
        end
    else
        if self:getMutipleChooseMix() > 0 and self:getMutipleChooseMix() > table.nums(self:getSelectedCatIdMap()) then
            app.uiMgr:ShowInformationTips(string.fmt(__("请至少选择_num_只猫咪"), {_num_ = self:getMutipleChooseMix()}))
            return
        end

        if self.confirmCB_ then
            self.confirmCB_(self:getSelectedCats())
        end
    end
    self:close()
end


function CatModuleChooseCatPopup:onClickCellHandler_(sender)
    PlayAudioByClickNormal()

    local catUuid  = sender.catUuid
    local catModel = app.catHouseMgr:getCatModel(catUuid)

    if sender.isChecked() then
        -- cancel selected
        self:delSelectedCatId(catUuid)
    else
        if self:getChoosePopupType() == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.OUT_GOING then
            if not catModel:checkOutEnable(true) then
                return
            end
        end

        local selectedCats = self:getSelectedCats()
        if self:getMutipleChooseMax() > 1 then
            -- 多选模式 检测选择上限
            if table.nums(self:getSelectedCatIdMap()) >= self:getMutipleChooseMax() then
                app.uiMgr:ShowInformationTips(__("已选择的猫咪到达上限，请先取消其他勾选"))
                return
            end
        else
            -- 单选模式 取消旧的选择
            if #selectedCats > 0 then
                if self:getSelectedTab() == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.EQUIP_CAT then
                    self:delSelectedCatId(self:getEquipCatId())
                else
                    self:delSelectedCatId(selectedCats[1])
                end
            end
        end

        -- to selected new
        self:addSelectedCatId(catUuid)
    end
    if self:getSelectedTab() == CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.EQUIP_CAT then
        self:refreshPropertyView()
    end
end

function CatModuleChooseCatPopup:onClickTabCellHandler_(sender)
    local tag = sender:getTag()
    if not tag or tag == self:getSelectedTab() then return end
    PlayAudioByClickNormal()
    self:setSelectedTab(tag)
    self:switchView(tag)
end
-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatModuleChooseCatPopup.CreateHeadNode(cellParent)
    local size = cellParent:getContentSize()
    local view = ui.layer({size = size, color = cc.r4b(0), enable = true})
    cellParent:addList(view)

    local catHeadNode = require('Game.views.catModule.cat.CatHeadNode').new()
    view:addList(catHeadNode):alignTo(nil, ui.cc)

    local checkBox = ui.button({n = RES_DICT.CHECK_BG})
    view:addList(checkBox):alignTo(nil, ui.rt, {offsetX = -23, offsetY = -15})

    local checkImg = ui.image({img = RES_DICT.CHECK_IMG})
    checkImg:setVisible(false)
    checkBox:addList(checkImg):alignTo(nil, ui.lb, {offsetX = 5, offsetY = 5})

    view.setChecked  = function(visible)
        checkImg:setVisible(visible)
    end
    view.isChecked   = function()
        return checkImg:isVisible()
    end

    local outGoingTitle = ui.title({n = RES_DICT.OUT_INFO_BG}):updateLabel({fnt = FONT.D4, fontSize = 18, color = "#7e2b1a", text = __("外出次数"), paddingW = 20, offset = cc.p(-15, 10)})
    local outGoingTxt = ui.label({fnt = FONT.D4, fontSize = 18, color = "#7e2b1a", text = "--", ap = ui.lc})
    outGoingTitle:addList(outGoingTxt):alignTo(nil, ui.lb, {offsetX = 5, offsetY = 5})
    view:addList(outGoingTitle):alignTo(nil, ui.lc, {offsetY = -30, offsetX = 10})

    local outGoingTip = ui.title({n = RES_DICT.OUT_TIP_BG}):updateLabel({fnt = FONT.D14, fontSize = 22, outline = "#311717", text = __("不可外出"), reqW = 160})
    view:addList(outGoingTip):alignTo(nil, ui.cc)

    return {
        catHeadNode   = catHeadNode,
        checkBox      = checkBox,
        outGoingTxt   = outGoingTxt,
        outGoingTitle = outGoingTitle,
        outGoingTip   = outGoingTip,
        view          = view,
    }
end

function CatModuleChooseCatPopup.CreatePropertyCell(cellParent)
    local size = cellParent:getContentSize()
    local view = ui.layer({size = size, color = cc.r4b(0), enable = true})
    cellParent:addList(view)
    
    local bg = ui.image({img = RES_DICT.PROP_CELL_BG_L})
    view:addList(bg):alignTo(nil, ui.cc)
    local propIcon = ui.image({img = app.cardMgr.GetPropertyDefine(ObjP.ATTACK).path})
    view:addList(propIcon):alignTo(nil, ui.lc, {offsetX = 20})
    local title = ui.label({fnt = FONT.D1, fontSize = 22, text = '', ap = lc, x = 95, y = size.height / 2})
    view:add(title)
    local value = ui.label({fnt = FONT.D4, fontSize = 22, text = '', color = '#493328', ap = rc, x = size.width - 40, y = size.height / 2})
    view:add(value)
    local line = ui.image({img = RES_DICT.PROP_CELL_LINE})
    view:addList(line):alignTo(nil, ui.cb)
    return {
        view     = view,
        bg       = bg,
        propIcon = propIcon,
        title    = title,
        value    = value,
        line     = line,
    }
end

function CatModuleChooseCatPopup.CreateView(confirmStr)
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, cc.p(0.55, 0.5))

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
    local titleBar = ui.title({img = RES_DICT.TITLE_BAR}):updateLabel({fnt = FONT.D3, text = __("选择猫咪"), paddingW = 60, safeW = 120, offset = cc.p(0,-2)})
    frameLayer:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -4})

    -- gridView
    local GRID_SIZE = cc.resize(viewFrameSize, -60, -130)
    local gridViewBg = ui.image({img = RES_DICT.GRID_VIEW_BG, scale9 = true, size = GRID_SIZE})
    frameLayer:addList(gridViewBg):alignTo(nil, ui.ct, {offsetY = -50})

    local gridView = ui.gridView({size = GRID_SIZE, dir = display.SDIR_V, cols = 3, csizeH = csizeH})
    frameLayer:addList(gridView):alignTo(gridViewBg, ui.cc)
    gridView:setCellCreateHandler(CatModuleChooseCatPopup.CreateHeadNode)

    local confirmBtn = ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = confirmStr or __("更换")})
    frameLayer:addList(confirmBtn):alignTo(nil, ui.cb, {offsetY = 10})

    -- tab btn
    local tabDefine = {
        {title = __('展示'), type = CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.HOUSE_PLACE},
        {title = __('天选'), type = CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.EQUIP_CAT},
    }
    local tabViewSize = cc.size(130, #tabDefine * 80 + (#tabDefine - 1) * 10)
    local tabView = ui.layer({enable = true, size = tabViewSize, ap = ui.rt})
    centerLayer:addList(tabView, -1):alignTo(viewFrameNode, ui.rt, {offsetX = -23, offsetY = -250})
    local tabMask = ui.layer({color = cc.r4b(0), enable = true, size = tabViewSize, ap = ui.rt})
    tabView:addList(tabMask, -1):alignTo(nil, ui.cc)

    local tabGroupList = {}
    for i, v in ipairs(tabDefine) do
        table.insert(
            tabGroupList,
            ui.button({n = RES_DICT.TAB_BTN_GREY, tag = v.type, useS = false}):updateLabel({fnt = FONT.D20, text = v.title, fontSize = 26, offset = cc.p(-5, -2)})
        )
    end
    local tabGroup = tabView:addList(tabGroupList)
    ui.flowLayout(cc.p(0, tabViewSize.height), tabGroup, {type = ui.flowV, ap = ui.lb, gapH = 10})

    -- propertyView
    local propertyView = ui.layer({bg = RES_DICT.PROPERTY_BG, enable = true, ap = ui.rc})
    centerLayer:addList(propertyView, -1):alignTo(viewFrameNode, ui.lc, {offsetX = 20, offsetY = -16})

    local propertyTitle = ui.title({n = RES_DICT.TITLE_PROPERTY}):updateLabel({fnt = FONT.D5, text = __('当前加成属性'), reqW = 135})
    propertyView:addList(propertyTitle):alignTo(nil, ui.ct, {offsetX = -3, offsetY = -20})
    local propertyTips = ui.label({fnt = FONT.D15, fontSize = 18, text = __('(对所有飨灵加成)')})
    propertyView:addList(propertyTips):alignTo(nil, ui.ct, {offsetX = -3, offsetY = -60})
    local noPropertyTips = ui.label({fnt = FONT.D15, fontSize = 18, text = __('暂无加成\n特殊基因存在属性加成'), hAlign = display.TAC})
    propertyView:addList(noPropertyTips):alignTo(nil, ui.cc, {offsetX = -3, offsetY = 10})

    local propertyListViewSize = cc.size(propertyView:getContentSize().width, 470)
    local propertyListView = ui.tableView({size = propertyListViewSize, csizeH = 40, dir = display.SDIR_V, mr = 2})
    propertyListView:setBounceable(false)
    propertyView:addList(propertyListView):alignTo(nil, ui.cc, {offsetY = -40})
    propertyListView:setCellCreateHandler(CatModuleChooseCatPopup.CreatePropertyCell)
    return {
        view             = view,
        blackLayer       = backGroundGroup[1],
        blockLayer       = backGroundGroup[2],
        --               = center
        gridView         = gridView,
        confirmBtn       = confirmBtn,
        tabView          = tabView,
        tabGroup         = tabGroup,
        propertyView     = propertyView,
        noPropertyTips   = noPropertyTips,
        propertyListView = propertyListView,
    }
end


return CatModuleChooseCatPopup
