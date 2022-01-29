--[[
 * author : kaishiqi
 * descpt : 水吧 - 上架视图
]]
local WaterBarPutawayView = class('WaterBarPutawayView', function()
    return ui.layer({name = 'Game.views.waterBar.WaterBarPutawayView', enableEvent = true})
end)

local RES_DICT = {
    PUTAWAY_FRAME      = _res('ui/waterBar/putaway/bar_roost_bg.png'),
    PUTAWAY_FRAME2     = _res('ui/waterBar/putaway/bar_roost_bg2.png'),
    GOODS_FRAME        = _res('ui/common/common_bg_goods.png'),
    DECORATE_TITLE     = _res('ui/waterBar/putaway/bar_roost_bg_title_2.png'),
    DECORATE_BALLOON   = _res('ui/waterBar/putaway/bar_roost_icon_balloons.png'),
    DECORATE_LIGHT_L   = _res('ui/waterBar/putaway/bar_roost_icon_lights_left.png'),
    DECORATE_LIGHT_R   = _res('ui/waterBar/putaway/bar_roost_icon_lights_right.png'),
    TYPE_TAB_BTN_S     = _res('ui/waterBar/putaway/gold_trade_ware_btn_fronti.png'),
    TYPE_TAB_BTN_N     = _res('ui/waterBar/putaway/gold_trade_ware_btn_later.png'),
    PUTAWAY_EMPTY_IMG  = _res('ui/common/common_bg_dialogue_tips.png'),
    BTN_CONFIRM        = _res('ui/common/common_btn_orange.png'),
    --                 = putaway cell
    PUTAWAY_CELL_CLOSE = _res('ui/waterBar/putaway/bar_btn_subtracted.png'),
    PUTAWAY_CELL_BG    = _res('ui/waterBar/putaway/common_bg_list.png'),
    DRINK_LV_ICON_N    = _res('ui/common/common_star_grey_l_ico.png'),
    DRINK_LV_ICON_S    = _res('ui/common/common_star_l_ico.png'),
    --                 = library cell
    LIBRARY_CELL_BG    = _res('ui/waterBar/putaway/bar_btn_goods_default.png'),
    LIBRARY_LEVEL_BG   = _res('ui/waterBar/putaway/gold_trade_ware_list_jiaob.png'),
    LIBRARY_HEART_N    = _res('ui/waterBar/common/bar_shop_icon_heart_bg.png'),
    LIBRARY_HEART_S    = _res('ui/waterBar/common/bar_shop_icon_heart.png'),
}

local ACTION_ENUM = {
    RELOAD_LIBRARY = 1,
    RELOAD_PUTAWAY = 2,
}

local WATER_BAR_DRINK_TYPE = FOOD.WATER_BAR.DRINK_TYPE
local PUTAWAY_PROXY_NAME   = FOOD.WATER_BAR.PUTAWAY.PROXY_NAME
local PUTAWAY_PROXY_STRUCT = FOOD.WATER_BAR.PUTAWAY.PROXY_STRUCT


function WaterBarPutawayView:ctor(args)
    self.libraryDrinkIdList_ = {}
    self.libraryDrinkIdxMap_ = {}
    self.putawayDrinkIdList_ = {}
    self.putawayDrinkIdxMap_ = {}

    self.customerLikeDrinkMap_ = {}
    for _, customerId in ipairs(app.waterBarMgr:getCurrentScheduleCustomers()) do
        local customerConf = CONF.BAR.CUSTOMER:GetValue(customerId)
        for _, likeFormulaId in ipairs(customerConf.formula or {}) do
            local formulaConf = CONF.BAR.FORMULA:GetValue(likeFormulaId)
            for _, likeDrinkId in ipairs(formulaConf.drinks or {}) do
                self.customerLikeDrinkMap_[tostring(likeDrinkId)] = true
            end
        end
    end

    self.isViewModel_ = app.waterBarMgr:isHomeOpening()

    -- create view
    self.viewData_ = WaterBarPutawayView.CreateView(self.isViewModel_)
    self:addChild(self.viewData_.view)

    self:getViewData().libraryGridView:setCellUpdateHandler(handler(self, self.onUpdateLibraryCellHandler_))
    self:getViewData().putawayTableView:setCellUpdateHandler(handler(self, self.onUpdatePutawayCellHandler_))

    -- bind model
    self.putawayProxy_ = app:RetrieveProxy(PUTAWAY_PROXY_NAME)
    self.viewBindMap_  = {
        [PUTAWAY_PROXY_STRUCT.PUTAWAY_LIMIT_NUM]                          = self.updatePutawayDrinkCount_,
        [PUTAWAY_PROXY_STRUCT.PUTAWAY_DRINK_NUM]                          = self.updatePutawayDrinkCount_,
        [PUTAWAY_PROXY_STRUCT.SELECT_DRINK_TYPE]                          = self.onUpdateSelectDrinkType_,
        [PUTAWAY_PROXY_STRUCT.LIBRARY_DRINK_MAP]                          = self.onUpdateLibraryDrinkGridView_,  -- clean all / update all
        [PUTAWAY_PROXY_STRUCT.LIBRARY_DRINK_MAP.COUNT]                    = self.onUpdateLibraryDrinkGridCell_,  -- add key / del key
        [PUTAWAY_PROXY_STRUCT.PUTAWAY_DRINK_MAP]                          = self.onUpdatePutawayDrinkTableView_, -- clean all / update all
        [PUTAWAY_PROXY_STRUCT.PUTAWAY_DRINK_MAP.COUNT]                    = self.onUpdatePutawayDrinkTableCell_, -- add key / del key
        [PUTAWAY_PROXY_STRUCT.FORMULA_DATA_MAP.FORMULA_DATA.FORMULA_LIKE] = self.onUpdateFormulaLikeHandler_,
    }

    -- update view
    local handerList = VoProxy.EventBind(PUTAWAY_PROXY_NAME, self.viewBindMap_, self)
    table.each(handerList, function(_, v) v(self) end)
end


function WaterBarPutawayView:onCleanup()
    VoProxy.EventUnbind(PUTAWAY_PROXY_NAME, self.viewBindMap_, self)
end


function WaterBarPutawayView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- handler

function WaterBarPutawayView:updatePutawayDrinkCount_(signal)
    local putawayCount = self.putawayProxy_:get(PUTAWAY_PROXY_STRUCT.PUTAWAY_DRINK_NUM)
    local putawayLimit = self.putawayProxy_:get(PUTAWAY_PROXY_STRUCT.PUTAWAY_LIMIT_NUM)
    self:getViewData().putawayCountBar:updateLabel({text = string.fmt('%1/%2', putawayCount, putawayLimit)})
end


function WaterBarPutawayView:onUpdateSelectDrinkType_(signal)
    local selectDrinkType = self.putawayProxy_:get(PUTAWAY_PROXY_STRUCT.SELECT_DRINK_TYPE)
    for _, tabTButton in ipairs(self:getViewData().typeTabList or {}) do
        tabTButton:setChecked(tabTButton:getTag() == selectDrinkType)
    end
    self:onUpdateLibraryDrinkGridView_()
end


function WaterBarPutawayView:onUpdateLibraryDrinkGridView_(signal)
    if not self:getActionByTag(ACTION_ENUM.RELOAD_LIBRARY) then
        self:runAction(cc.CallFunc:create(function()

            -- reset libraryDrink idList/idxMap
            self.libraryDrinkIdxMap_ = {}
            self.libraryDrinkIdList_ = self:getLibraryDrinkDataByType(self.putawayProxy_:get(PUTAWAY_PROXY_STRUCT.SELECT_DRINK_TYPE))
            
            -- update libraryDrinkIdxMap
            for index, drinkId in ipairs(self.libraryDrinkIdList_) do
                self.libraryDrinkIdxMap_[drinkId] = index
            end
            
            -- reload libraryGridView
            self:getViewData().libraryGridView:resetCellCount(#self.libraryDrinkIdList_)
            self:getViewData().libraryEmptyLayer:setVisible(#self.libraryDrinkIdList_ == 0)
        end)):setTag(ACTION_ENUM.RELOAD_LIBRARY)
    end
end


function WaterBarPutawayView:getLibraryDrinkDataByType(drinkType)
    local libraryDrinkIdList = {}
    local allLibraryDataMap  = self.putawayProxy_:get(PUTAWAY_PROXY_STRUCT.LIBRARY_DRINK_MAP):getData()
    local libraryDataIndex   = 1
    for drinkId, drinkNum in pairs(allLibraryDataMap) do
        if drinkType == WATER_BAR_DRINK_TYPE.ALL or WaterBarUtils.GetDrinkType(drinkId) == drinkType then
            libraryDrinkIdList[libraryDataIndex] = drinkId
            libraryDataIndex = libraryDataIndex + 1
        end
    end

    local FORMULA_STRUCT  = PUTAWAY_PROXY_STRUCT.FORMULA_DATA_MAP.FORMULA_DATA
    local isLikeDrinkFunc = function(formulaId)
        local formulaVoProxy = self.putawayProxy_:get(FORMULA_STRUCT, tostring(formulaId))
        local isFormulaLike  = WaterBarUtils.IsFormulaLike(formulaVoProxy:get(FORMULA_STRUCT.FORMULA_LIKE))
        return isFormulaLike
    end

    -- sort libraryDrinkIdList
    table.sort(libraryDrinkIdList, function(a, b)
        local aDrinkConf = CONF.BAR.DRINK:GetValue(a)
        local bDrinkConf = CONF.BAR.DRINK:GetValue(b)
        local aDrinkStar = checkint(aDrinkConf.star)
        local bDrinkStar = checkint(bDrinkConf.star)
        local aFormulaId = tostring(aDrinkConf.formulaId)
        local bFormulaId = tostring(bDrinkConf.formulaId)

        local isFormulaLikeA  = isLikeDrinkFunc(aFormulaId)
        local isFormulaLikeB  = isLikeDrinkFunc(bFormulaId)
        local isCustomerLikeA = self.customerLikeDrinkMap_[tostring(a)] == true
        local isCustomerLikeB = self.customerLikeDrinkMap_[tostring(b)] == true
        if isCustomerLikeA == isCustomerLikeB then
            if isFormulaLikeA == isFormulaLikeB then
                return (aDrinkStar == bDrinkStar) and (checkint(a) < checkint(b)) or (aDrinkStar > bDrinkStar)
            else
                return isFormulaLikeA
            end
        else
            return isCustomerLikeA
        end
    end)

    return libraryDrinkIdList
end


function WaterBarPutawayView:onUpdatePutawayDrinkTableView_(signal)
    if not self:getActionByTag(ACTION_ENUM.RELOAD_PUTAWAY) then
        self:runAction(cc.CallFunc:create(function()

            -- reset putawayDrink idList/idxMap
            self.putawayDrinkIdxMap_ = {}
            self.putawayDrinkIdList_ = table.keys(self.putawayProxy_:get(PUTAWAY_PROXY_STRUCT.PUTAWAY_DRINK_MAP):getData())

            local FORMULA_STRUCT  = PUTAWAY_PROXY_STRUCT.FORMULA_DATA_MAP.FORMULA_DATA
            local isLikeDrinkFunc = function(formulaId)
                local formulaVoProxy = self.putawayProxy_:get(FORMULA_STRUCT, tostring(formulaId))
                local isFormulaLike  = WaterBarUtils.IsFormulaLike(formulaVoProxy:get(FORMULA_STRUCT.FORMULA_LIKE))
                return isFormulaLike
            end
            
            -- sort putawayDrinkIdList
            table.sort(self.putawayDrinkIdList_, function(a, b)
                local aDrinkConf = CONF.BAR.DRINK:GetValue(a)
                local bDrinkConf = CONF.BAR.DRINK:GetValue(b)
                local aDrinkStar = checkint(aDrinkConf.star)
                local bDrinkStar = checkint(bDrinkConf.star)
                local aFormulaId = tostring(aDrinkConf.formulaId)
                local bFormulaId = tostring(bDrinkConf.formulaId)

                local isFormulaLikeA  = isLikeDrinkFunc(aFormulaId)
                local isFormulaLikeB  = isLikeDrinkFunc(bFormulaId)
                local isCustomerLikeA = self.customerLikeDrinkMap_[tostring(a)] == true
                local isCustomerLikeB = self.customerLikeDrinkMap_[tostring(b)] == true
                if isCustomerLikeA == isCustomerLikeB then
                    if isFormulaLikeA == isFormulaLikeB then
                        return (aDrinkStar == bDrinkStar) and (checkint(a) < checkint(b)) or (aDrinkStar > bDrinkStar)
                    else
                        return isFormulaLikeA
                    end
                else
                    return isCustomerLikeA
                end
            end)

            -- update putawayDrinkIdxMap
            for index, drinkId in ipairs(self.putawayDrinkIdList_) do
                self.putawayDrinkIdxMap_[drinkId] = index
            end

            -- reload putawayTableView
            self:getViewData().putawayTableView:resetCellCount(#self.putawayDrinkIdList_)
            self:getViewData().putawayEmptyLabel:setVisible(#self.putawayDrinkIdList_ == 0)
        end)):setTag(ACTION_ENUM.RELOAD_PUTAWAY)
    end
end


function WaterBarPutawayView:onUpdateLibraryDrinkGridCell_(signal)
    local signalEventType = signal and signal:GetType() or nil
    local changedVoDefine = signal and signal:GetBody().voDefine or nil
    local updateCellKey   = signal and signal:GetBody().dataKey or nil
    local updateCellIndex = self.libraryDrinkIdxMap_[tostring(updateCellKey)]
    
    if signalEventType == VoProxy.EVENTS.DELETE then
        self:onUpdateLibraryDrinkGridView_()
    elseif signalEventType == VoProxy.EVENTS.APPEND then
        self:onUpdateLibraryDrinkGridView_()
    else
        self:getViewData().libraryGridView:updateCellViewData(updateCellIndex, nil, changedVoDefine)
    end
end


function WaterBarPutawayView:onUpdatePutawayDrinkTableCell_(signal)
    local signalEventType = signal and signal:GetType() or nil
    local changedVoDefine = signal and signal:GetBody().voDefine or nil
    local updateCellKey   = signal and signal:GetBody().dataKey or nil
    local updateCellIndex = self.putawayDrinkIdxMap_[tostring(updateCellKey)]
    
    if signalEventType == VoProxy.EVENTS.DELETE then
        self:onUpdatePutawayDrinkTableView_()
    elseif signalEventType == VoProxy.EVENTS.APPEND then
        self:onUpdatePutawayDrinkTableView_()
    else
        self:getViewData().putawayTableView:updateCellViewData(updateCellIndex, nil, changedVoDefine)
    end
end


function WaterBarPutawayView:onUpdateFormulaLikeHandler_(signal)
    local updateCellKey   = signal and signal:GetBody().root:key() or nil
    local changedVoDefine = signal and signal:GetBody().voDefine or nil

    if updateCellKey then
        local FORMULA_STRUCT = PUTAWAY_PROXY_STRUCT.FORMULA_DATA_MAP.FORMULA_DATA
        local formulaVoProxy = self.putawayProxy_:get(FORMULA_STRUCT, tostring(updateCellKey))
        local eventFormulaId = formulaVoProxy:get(FORMULA_STRUCT.FORMULA_ID)
        local formulaConf    = CONF.BAR.FORMULA:GetValue(eventFormulaId)
        -- update formula all drinks
        for _, drinkId in ipairs(checktable(formulaConf.drinks)) do
            local libraryCellIndex = self.libraryDrinkIdxMap_[drinkId]
            self:getViewData().libraryGridView:updateCellViewData(libraryCellIndex, nil, changedVoDefine)
        end
    end
end


function WaterBarPutawayView:onUpdateLibraryCellHandler_(cellIndex, cellViewData, changedVoDefine)
    if cellViewData == nil then return end

    local FORMULA_STRUCT = PUTAWAY_PROXY_STRUCT.FORMULA_DATA_MAP.FORMULA_DATA
    local CELL_STRUCT    = PUTAWAY_PROXY_STRUCT.LIBRARY_DRINK_MAP.COUNT
    local drinkId        = self.libraryDrinkIdList_[cellIndex]
    local drinkNum       = self.putawayProxy_:get(CELL_STRUCT, drinkId)
    local drinkConf      = CONF.BAR.DRINK:GetValue(drinkId)

    -- init cell status
    if changedVoDefine == nil then
        cellViewData.likeBtn:setTag(drinkId)
        cellViewData.clickArea:setTag(drinkId)

        -- update name
        local cellSize = cellViewData.view:getContentSize()
        cellViewData.nameLabel:updateLabel({text = drinkConf.name, maxW = cellSize.width - 20})

        -- udpate image
        local drinkImg = ui.goodsImg({goodsId = drinkId, scale = 0.8})
        cellViewData.goodsLayer:addAndClear(drinkImg):alignTo(nil, ui.cc, {offsetY = -10})

        -- update level
        for index, lvTBtn in ipairs(cellViewData.lvTBtnList) do
            lvTBtn:setChecked(index <= checkint(drinkConf.star))
        end

        -- upate customer like
        if self.customerLikeDrinkMap_[drinkId] then
            cellViewData.frameImg:setColor(cc.c3b(255,225,175))
        else
            cellViewData.frameImg:setColor(cc.c3b(255,255,255))
        end
    end

    -- update drink count
    if changedVoDefine == nil or changedVoDefine == CELL_STRUCT then
        cellViewData.countLabel:updateLabel({text = string.fmt(__('库存：_num_'), {_num_ = drinkNum})})
    end

    -- update like tButton
    if changedVoDefine == nil or changedVoDefine == FORMULA_STRUCT.FORMULA_LIKE then
        local formulaId      = tostring(drinkConf.formulaId)
        local hasFormulaData = self.putawayProxy_:has(FORMULA_STRUCT, tostring(formulaId))
        local formulaVoProxy = self.putawayProxy_:get(FORMULA_STRUCT, tostring(formulaId))
        local isFormulaLike  = WaterBarUtils.IsFormulaLike(formulaVoProxy:get(FORMULA_STRUCT.FORMULA_LIKE))
        cellViewData.likeBtn:setVisible(checkint(formulaId) > 0 and hasFormulaData)
        cellViewData.likeBtn:setChecked(isFormulaLike)
    end
end


function WaterBarPutawayView:onUpdatePutawayCellHandler_(cellIndex, cellViewData, changedVoDefine)
    if cellViewData == nil then return end

    local CELL_STRUCT = PUTAWAY_PROXY_STRUCT.PUTAWAY_DRINK_MAP.COUNT
    local drinkId     = self.putawayDrinkIdList_[cellIndex]
    local drinkNum    = self.putawayProxy_:get(CELL_STRUCT, drinkId)
    
    -- init cell status
    if changedVoDefine == nil then
        cellViewData.closeBtn:setTag(drinkId)
        cellViewData.closeBtn:setVisible(not self.isViewModel_)
        
        -- update name
        local drinkConf = CONF.BAR.DRINK:GetValue(drinkId)
        cellViewData.nameLabel:updateLabel({text = drinkConf.name})

        -- update goodsNode
        cellViewData.goodsNode:RefreshSelf({goodsId = drinkId, num = drinkNum})

        -- update level
        for index, lvTBtn in ipairs(cellViewData.lvTBtnList) do
            lvTBtn:setChecked(index <= checkint(drinkConf.star))
        end

        -- upate customer like
        if self.customerLikeDrinkMap_[drinkId] then
            cellViewData.frameImg:setColor(cc.c3b(255,225,175))
        else
            cellViewData.frameImg:setColor(cc.c3b(255,255,255))
        end
    end

    -- update drink count
    if changedVoDefine == nil or changedVoDefine == CELL_STRUCT then
        cellViewData.countLabel:updateLabel({text = string.fmt('x%1',drinkNum)})
    end
end


-------------------------------------------------------------------------------
-- view struct
-------------------------------------------------------------------------------

function WaterBarPutawayView.CreateView(isViewModel)
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black layer
    view:add(ui.layer({color = cc.c4b(0,0,0,150)}))
    
    -- block layer
    local blockLayer = ui.layer({color = cc.r4b(0), enable = true})
    view:add(blockLayer)


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- content group
    local contentSize  = isViewModel and cc.size(330, 656) or cc.size(1130, 656)
    local contentGroup = centerLayer:addList({
        ui.layer({size = contentSize, color = cc.r4b(0), enable = true}),
        isViewModel and ui.image({img = RES_DICT.PUTAWAY_FRAME2}) or ui.image({img = RES_DICT.PUTAWAY_FRAME, ml = 72}),
        ui.layer({size = contentSize}),
    })
    ui.flowLayout(cpos, contentGroup, {type = ui.flowC, ap = ui.cc})
    
    -- content layer
    local contentLayer = contentGroup[3]
    

    -- library group
    local libraryLayerPos   = cc.rep(cc.sizep(contentSize, ui.cc), -83, 0)
    local libraryLayerSize  = cc.size(660, 534)
    local libraryLayerGroup = contentLayer:addList({
        ui.layer({size = libraryLayerSize, bg = RES_DICT.GOODS_FRAME, scale9 = true}),
        ui.gridView({size = cc.resize(libraryLayerSize, -14, -4), cols = 3, csizeAdd = cc.size(0,50)}),
        ui.layer({size = libraryLayerSize}),
    })
    ui.flowLayout(libraryLayerPos, libraryLayerGroup, {type = ui.flowC, ap = ui.cc})
    libraryLayerGroup[2]:setCellCreateHandler(WaterBarPutawayView.CreateLibraryCell)

    local libraryEmptyLayer = libraryLayerGroup[3]
    local libraryEmptyGroup = libraryEmptyLayer:addList({
        ui.title({img = RES_DICT.PUTAWAY_EMPTY_IMG, cut = cc.dir(135,10,65,92)}):updateLabel({fnt = FONT.D6, w = 220, text = __('当前无任何饮品库存\n请前往【调制】'), paddingH = 40, hAlign = display.TAC}),
        ui.image({img = AssetsUtils.GetCartoonPath(3), scale = 0.45}),
    })
    ui.flowLayout(cc.sizep(libraryEmptyLayer, ui.cc), libraryEmptyGroup, {type = ui.flowH, ap = ui.cc})
    
    
    -- putaway layer
    local putawayLayerPos   = cc.rep(cc.sizep(contentSize, ui.rc), -9, -17)
    local putawayLayerSize  = cc.size(275, isViewModel and 500 or 450)
    local putawayLayerGroup = contentLayer:addList({
        ui.layer({size = putawayLayerSize, bg = RES_DICT.GOODS_FRAME, scale9 = true}),
        ui.tableView({size = cc.resize(putawayLayerSize, -4, -4), csizeH = 82, dir = display.SDIR_V, mr = 2}),
        ui.label({fnt = FONT.D11, text = __('请从左侧选择今日上架的饮品'), w = putawayLayerSize.width - 2, hAlign = display.TAC}),
    })
    ui.flowLayout(putawayLayerPos, putawayLayerGroup, {type = ui.flowC, ap = ui.rc})
    putawayLayerGroup[2]:setCellCreateHandler(WaterBarPutawayView.CreatePutawayCell)


    -- putaway count
    local putawayCountBar = ui.title({img = RES_DICT.GOODS_FRAME, size = cc.size(120, 30), scale9 = true, cut = cc.dir(5,5,5,5), ap = rc}):updateLabel({fnt = FONT.D4, text = '--/--'})
    contentLayer:addList(putawayCountBar):alignTo(putawayLayerGroup[1], ui.rt, {inside = true, offsetY = 38})

    -- btnKeyStore
    local btnKeyStore = ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __("一键上架"), reqW = 120})
    contentLayer:addList(btnKeyStore):alignTo(nil, ui.rb, {offsetX = -80, offsetY = 15})
    btnKeyStore:setVisible(not isViewModel)
    

    -- decorate group
    local decorateGroup = contentLayer:addList({
        ui.label({fnt = FONT.TEXT24, color = '#76553b', mr = 80, mb = contentSize.height/2-35, text = __('选择今日需要上架的饮品')}),
        ui.label({fnt = FONT.TEXT20, color = '#76553b', mr = 80, mt = contentSize.height/2-35, text = __('没上架的饮品营业开始后会自动作废，歇业后将被清空')}),
        ui.title({img = RES_DICT.DECORATE_TITLE, ml = contentSize.width/2-145, mb = contentSize.height/2}):updateLabel({fnt = FONT.D14, text = __('今日上架'), offset = cc.p(0,-24)}),
        ui.image({img = RES_DICT.DECORATE_BALLOON, ml = contentSize.width/2, mt = contentSize.height/2 - 65}),
        ui.image({img = RES_DICT.DECORATE_LIGHT_L, mr = libraryLayerSize.width/2+10, mb = contentSize.height/2-60}),
        ui.image({img = RES_DICT.DECORATE_LIGHT_R, ml = libraryLayerSize.width/2-160, mb = contentSize.height/2-60}),
    })
    ui.flowLayout(cc.sizep(contentLayer, ui.cc), decorateGroup, {type = ui.flowC, ap = ui.cc})


    -- type tabGroup
    local typeTabDefine = {
        {name = __('全部'), type = WATER_BAR_DRINK_TYPE.ALL},
        {name = __('酒水'), type = WATER_BAR_DRINK_TYPE.ALCOHO},
        {name = __('软饮'), type = WATER_BAR_DRINK_TYPE.SOFT},
    }
    local typeTabGroup = {}
    for index, tabDefine in ipairs(typeTabDefine) do
        local tabTButton = ui.tButton({n = RES_DICT.TYPE_TAB_BTN_N, s = RES_DICT.TYPE_TAB_BTN_S, tag = tabDefine.type})
        tabTButton:add(ui.label({p = cc.rep(cc.sizep(tabTButton, ui.cc), 10, 0), fnt = FONT.D14, text = tabDefine.name}))
        typeTabGroup[index] = tabTButton
    end
    contentLayer:addList(typeTabGroup)
    ui.flowLayout(cc.p(147, contentSize.height-90), typeTabGroup, {type = ui.flowV, ap = ui.rb, gapH = 12})


    if isViewModel then
        libraryLayerGroup[1]:setVisible(false)
        libraryLayerGroup[2]:setVisible(false)
        libraryEmptyLayer:setScale(0)

        local offsetX = 20
        putawayLayerGroup[1]:setPositionX(putawayLayerGroup[1]:getPositionX() - offsetX)
        putawayLayerGroup[2]:setPositionX(putawayLayerGroup[2]:getPositionX() - offsetX)
        putawayLayerGroup[3]:setPositionX(putawayLayerGroup[3]:getPositionX() - offsetX)
        putawayLayerGroup[3]:updateLabel({text = __('本次营业未上架饮品，请在下个筹备阶段积极准备')})
        decorateGroup[3]:setPositionX(decorateGroup[3]:getPositionX() - offsetX)
        putawayCountBar:setPositionX(putawayCountBar:getPositionX() - offsetX)

        decorateGroup[1]:setVisible(false)
        decorateGroup[2]:setVisible(false)
        decorateGroup[4]:setVisible(false)
        decorateGroup[5]:setVisible(false)
        decorateGroup[6]:setVisible(false)

        for index, tabTButton in ipairs(typeTabGroup) do
            tabTButton:setVisible(false)
        end
    end

    return {
        view              = view,
        blockLayer        = blockLayer,
        typeTabList       = typeTabGroup,
        putawayCountBar   = putawayCountBar,
        libraryGridView   = libraryLayerGroup[2],
        libraryEmptyLayer = libraryEmptyLayer,
        putawayTableView  = putawayLayerGroup[2],
        putawayEmptyLabel = putawayLayerGroup[3],
        btnKeyStore       = btnKeyStore,
    }
end


function WaterBarPutawayView.CreateLibraryCell(cellParent)
    local view = cellParent
    local size = cellParent:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local frameImg = ui.image({p = cpos, img = RES_DICT.LIBRARY_CELL_BG})
    view:add(frameImg)

    local goodsInfoGroup = view:addList({
        ui.layer({size = cc.resize(size, -40, -110)}),
        ui.label({fnt = FONT.D4, mt = 18}),
        ui.label({fnt = FONT.D14, mt = 40}),
    })
    ui.flowLayout(cc.p(cpos.x, 30), goodsInfoGroup, {type = ui.flowV, ap = ui.ct})


    local levelBar = ui.layer({bg = RES_DICT.LIBRARY_LEVEL_BG})
    view:addList(levelBar):alignTo(nil, ui.lt, {offsetX = 0, offsetY = -20})

    local lvTBtnList = {}
    for i = 1, FOOD.WATER_BAR.DEFINE.FORMULA_STAR_MAX do
        lvTBtnList[i] = ui.tButton({n = RES_DICT.DRINK_LV_ICON_N, s = RES_DICT.DRINK_LV_ICON_S, enable = false, scale = 0.5})
    end
    levelBar:addList(lvTBtnList)
    ui.flowLayout(cc.rep(cc.sizep(levelBar, ui.cc), -2, 0), lvTBtnList, {type = ui.flowH, ap = ui.cc, gapW = 1})
    
    
    local clickArea = ui.layer({color = cc.r4b(0), size = size, enable = true})
    view:addList(clickArea):alignTo(nil, ui.cc)
    
    local likeBtn = ui.tButton({n = RES_DICT.LIBRARY_HEART_N, s = RES_DICT.LIBRARY_HEART_S, enable = false})
    view:addList(likeBtn):alignTo(nil, ui.rt, {offsetX = -20, offsetY = -20})

    return {
        view       = view,
        frameImg   = frameImg,
        clickArea  = clickArea,
        goodsLayer = goodsInfoGroup[1],
        nameLabel  = goodsInfoGroup[2],
        countLabel = goodsInfoGroup[3],
        lvTBtnList = lvTBtnList,
        likeBtn    = likeBtn,
    }
end


function WaterBarPutawayView.CreatePutawayCell(cellParent)
    local view = cellParent
    local size = cellParent:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local frameImg = ui.image({p = cc.rep(cpos, 0, -2), img = RES_DICT.PUTAWAY_CELL_BG})
    view:add(frameImg)

    local goodsNode = ui.goodsNode({scale = 0.6})
    view:addList(goodsNode):alignTo(nil, ui.lc, {offsetX = 12})

    local lvTBtnList = {}
    for i = 1, FOOD.WATER_BAR.DEFINE.FORMULA_STAR_MAX do
        lvTBtnList[i] = ui.tButton({n = RES_DICT.DRINK_LV_ICON_N, s = RES_DICT.DRINK_LV_ICON_S, enable = false, scale = 0.5})
    end
    view:addList(lvTBtnList)
    ui.flowLayout(cc.p(15, 10), lvTBtnList, {type = ui.flowH, ap = ui.lb})
    
    local nameLabel = ui.label({fnt = FONT.D8, w = size.width-90, ap = ui.lt})
    view:addList(nameLabel):alignTo(goodsNode, ui.rt, {offsetX = 6})

    local countLabel = ui.label({fnt = FONT.D11, w = size.width-90, ap = ui.lb})
    view:addList(countLabel):alignTo(goodsNode, ui.rb, {offsetX = 6})

    local closeBtn = ui.button({n = RES_DICT.PUTAWAY_CELL_CLOSE})
    view:addList(closeBtn):alignTo(nil, ui.rb, {offsetY = -2})

    return {
        view       = view,
        frameImg   = frameImg,
        goodsNode  = goodsNode,
        lvTBtnList = lvTBtnList,
        nameLabel  = nameLabel,
        countLabel = countLabel,
        closeBtn   = closeBtn,
    }
end


return WaterBarPutawayView
