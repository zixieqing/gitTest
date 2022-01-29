--[[
 * author : kaishiqi
 * descpt : 新游戏商店中介者
]]
local GameStoresView     = require('Game.views.stores.GameStoresView')
local GameStoresMediator = class('GameStoresMediator', mvc.Mediator)

local STORE_TYPE_DEFINE = {
    [GAME_STORE_TYPE.DIAMOND]     = {mdtName = 'DiamondStoreMediator'},     -- 幻晶石 商店
    [GAME_STORE_TYPE.MONTH]       = {mdtName = 'MonthCardStoreMediator'},   -- 月卡 商店
    [GAME_STORE_TYPE.GIFTS]       = {mdtName = 'GameGiftsStoreMediator'},   -- 礼包 商店
    [GAME_STORE_TYPE.PROPS]       = {mdtName = 'GamePropsStoreMediator'},   -- 道具 商店
    [GAME_STORE_TYPE.CARD_SKIN]   = {mdtName = 'CardSkinStoreMediator'},    -- 皮肤 商店
    [GAME_STORE_TYPE.GROCERY]     = {mdtName = 'GroceryStoreMediator'},     -- 杂货铺
    [GAME_STORE_TYPE.SEARCH_PROP] = {mdtName = 'SearchPropsStoreMediator'}, -- 道具搜索
}

function GameStoresMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'GameStoresMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function GameStoresMediator:Initial(key)
    self.super.Initial(self, key)

    -- paras args
    local args = self.ctorArgs_ or {}
    self.isOnlyDiamon_  = args.isOnlyDiamon == true
    self.searchGoodsId_ = checkint(args.searchGoodsId)
    self.initStoreType_ = args.storeType
    self.initSubType_   = args.subType

    -- init vars
    self.allStoresData_  = {}
    self.typeCellDict_   = {}
    self.typeDataList_   = {}
    self.contentMdtName_ = nil
    self.isControllable_ = true

    -- create view
	self.storesView_ = GameStoresView.new()
    local ownerScene = app.uiMgr:GetCurrentScene()
    ownerScene:AddDialog(self.storesView_)

    -- add listener
    display.commonUIParams(self:getStoresViewData().backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    display.commonUIParams(self:getStoresViewData().titleBtn, {cb = handler(self, self.onClickTitleButtonHandler_)})
    self:getStoresViewData().typeListView:setDataSourceAdapterScriptHandler(handler(self, self.onTypeListViewDataHandler_))
end


function GameStoresMediator:CleanupView()
    if self.storesView_  and (not tolua.isnull(self.storesView_)) then
        self.storesView_:runAction(cc.RemoveSelf:create())
        self.storesView_ = nil
    end
end


function GameStoresMediator:OnRegist()
    regPost(POST.GAME_STORE_HOME)

    -- request homeData
    self:SendSignal(POST.GAME_STORE_HOME.cmdName)
end


function GameStoresMediator:OnUnRegist()
    unregPost(POST.GAME_STORE_HOME)

    self:GetFacade():UnRegsitMediator(self.contentMdtName_)
    AppFacade.GetInstance():DispatchObservers(SHOP_EXIT_SHOP)
end


function GameStoresMediator:InterestSignals()
    return {
        SGL.CACHE_MONEY_UPDATE_UI,
        POST.GAME_STORE_HOME.sglName,
    }
end
function GameStoresMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.GAME_STORE_HOME.sglName then
        -- refresh diamond
		CommonUtils.RefreshDiamond(data)
        
        -- save all data
        self.allStoresData_ = data or {}
        self.dataTimestamp_ = os.time()
        self:reloadTypeList()
        
        -- show ui
        self.isControllable_ = false
        self:getStoresView():showUI(function()
            self.isControllable_ = true
        end)


    elseif name == SGL.CACHE_MONEY_UPDATE_UI then
        self:getStoresView():updateMoneyBar()

    end
end


-------------------------------------------------
-- get / set

function GameStoresMediator:getStoresView()
    return self.storesView_
end
function GameStoresMediator:getStoresViewData()
    return self:getStoresView() and self:getStoresView():getViewData() or {}
end


function GameStoresMediator:getTypeDataList()
    return self.typeDataList_ or {}
end


function GameStoresMediator:getSelectedIndex()
    return self.selectedIndex_ or 0
end
function GameStoresMediator:setSelectedIndex(index)
    local targetIndex = checkint(index)
    if self.selectedIndex_ ~= targetIndex then
        self.selectedIndex_ = targetIndex
        self:updateTypeIndex_()
    end
end


function GameStoresMediator:setSelectedType(storeType)
    for i, typeData in ipairs(self:getTypeDataList()) do
        if typeData.storeType == storeType then
            self:setSelectedIndex(i)
            break
        end
    end
end


-------------------------------------------------
-- public

function GameStoresMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


function GameStoresMediator:reloadTypeList()
    -- reset all typeData
    self.typeDataList_ = {}

    -- filter store activity
    local activityDataMap  = {}
    local activityHomeData = checktable(app.gameMgr:GetUserInfo().activityHomeData).activity or {}
    for i, activityData in ipairs(activityHomeData) do
        local activityType  = tostring(activityData.type)
        local gameStoreType = nil
        
        if activityType == ACTIVITY_TYPE.STORE_DIAMOND_LIMIT then
            gameStoreType = GAME_STORE_TYPE.DIAMOND
            
        elseif activityType == ACTIVITY_TYPE.STORE_MEMBER_PACK then
            gameStoreType = GAME_STORE_TYPE.MONTH

        elseif activityType == ACTIVITY_TYPE.STORE_GIFTS_MONEY then
            gameStoreType = GAME_STORE_TYPE.GIFTS
            
        elseif activityType == ACTIVITY_TYPE.STORE_OTHER_LIMIT then
            local activityMallType = checkint(activityData.mallId)
            if activityMallType == ACTIVITY_MALL_TYPE.GOODS then
                gameStoreType = GAME_STORE_TYPE.PROPS

            elseif activityMallType == ACTIVITY_MALL_TYPE.CARD_SKIN then
                gameStoreType = GAME_STORE_TYPE.CARD_SKIN
            end
        end

        if gameStoreType then
            local newActivityType = activityData
            local oldActivityType = activityDataMap[gameStoreType]
            if checkint(newActivityType.toTime) > getServerTime() then
                if oldActivityType then
                    if checkint(oldActivityType.toTime) > checkint(newActivityType.toTime) then
                        activityDataMap[gameStoreType] = newActivityType
                    else
                        activityDataMap[gameStoreType] = oldActivityType
                    end
                else
                    activityDataMap[gameStoreType] = newActivityType
                end
            end
        end
    end

    -- define storeData
    local commonStoreData  = {dataTimestamp = self.dataTimestamp_}
    local allStoreDataMap  = {
        [GAME_STORE_TYPE.DIAMOND]   = {storeData = self.allStoresData_.diamond},
        [GAME_STORE_TYPE.MONTH]     = {storeData = self.allStoresData_.member},
        [GAME_STORE_TYPE.GIFTS]     = {storeData = self.allStoresData_.chest},
        [GAME_STORE_TYPE.PROPS]     = {storeData = self.allStoresData_.goods},
        [GAME_STORE_TYPE.CARD_SKIN] = {storeData = self.allStoresData_.cardSkin},
        [GAME_STORE_TYPE.GROCERY]   = {},
    }
    for type, data in pairs(allStoreDataMap) do
        table.merge(data, commonStoreData)
        data.storeType    = type
        data.activityData = activityDataMap[type]
    end

    -- only diamon store
    if self.isOnlyDiamon_ then
        self.typeDataList_ = {
            allStoreDataMap[GAME_STORE_TYPE.DIAMOND] or {}
        }

    -- show all store
    else
        if self.searchGoodsId_ > 0 then
            table.insert(self.typeDataList_, {
                storeType      = GAME_STORE_TYPE.SEARCH_PROP,
                dataTimestamp  = self.dataTimestamp_,
                searchGoodsId  = self.searchGoodsId_,
                giftsStoreData = allStoreDataMap[GAME_STORE_TYPE.GIFTS].storeData,
                propsStoreData = allStoreDataMap[GAME_STORE_TYPE.PROPS].storeData,
            })
        end
        
        local typeOrderList = {
            GAME_STORE_TYPE.DIAMOND,
            GAME_STORE_TYPE.MONTH,
            GAME_STORE_TYPE.GIFTS,
            GAME_STORE_TYPE.PROPS,
            GAME_STORE_TYPE.CARD_SKIN,
            GAME_STORE_TYPE.GROCERY,
        }
        for i, storeType in ipairs(typeOrderList) do
            local storeData = allStoreDataMap[storeType] or {}
            if storeData.storeData then
                if table.nums(storeData.storeData) > 0 then
                    table.insert(self.typeDataList_, storeData)
                end
            else
                table.insert(self.typeDataList_, storeData)
            end
        end
    end

    -- reload typeListView
    local typeListView = self:getStoresViewData().typeListView
    typeListView:setCountOfCell(#self:getTypeDataList())
    typeListView:reloadData()

    -- default selectedIndex
    if self.initStoreType_ then
        self:setSelectedType(self.initStoreType_)
        self.initStoreType_ = nil
    else
        local afterSelectedTypeIndex = self:getSelectedIndex()
        self:setSelectedIndex(afterSelectedTypeIndex > 0 and afterSelectedTypeIndex or 1)
    end
end


-------------------------------------------------
-- private

function GameStoresMediator:updateTypeIndex_()
    local tweenDurationTime = 0.2
    local nowSelectedIndex  = self:getSelectedIndex()

    -------------------------------------------------
    -- scroll typeListView
    local typeListView = self:getStoresViewData().typeListView
    local typeListSize = typeListView:getContentSize()
    local continerSize = typeListView:getContainerSize()
    local typeCellSize = typeListView:getSizeOfCell()
    local typeListOffY = typeListView:getContentOffset().y
    local targetOffset = cc.p(0, -continerSize.height + typeListSize.height + (nowSelectedIndex-1) * typeCellSize.height)
    local isNeedOffset = false
    if targetOffset.y < typeListOffY then
        isNeedOffset = true
    elseif targetOffset.y > typeListOffY + typeListSize.height - typeCellSize.height then
        isNeedOffset = true
        targetOffset.y = targetOffset.y - typeListSize.height + typeCellSize.height
    end
    if isNeedOffset then
        -- typeListView:setContentOffsetInDuration(targetOffset, tweenDurationTime)
        typeListView:setContentOffset(targetOffset)
    end

    -- update all typeCell selected status
    for _, cellViewData in pairs(self.typeCellDict_) do
        local isSelected = cellViewData.view:getTag() == nowSelectedIndex
        self:getStoresView():updateTypeCellSelectStatus(cellViewData, isSelected)
    end

    -------------------------------------------------
    -- update storePanel
    self:updateStorePanel_(nowSelectedIndex)
end


function GameStoresMediator:updateTypeCell_(index, cell)
    local typeListView  = self:getStoresViewData().typeListView
    local cellViewData  = cell or self.typeCellDict_[typeListView:cellAtIndex(index - 1)]
    local storeTypeData = self:getTypeDataList()[index] or {}

    if cellViewData then
        local storeType = checkint(storeTypeData.storeType)
        local storeData = checktable(storeTypeData.storeData)
        self:getStoresView():updateTypeBaseInfo(cellViewData, storeType)
        self:getStoresView():updateTypeCellImage(cellViewData, storeType, storeTypeData.activityData)
        self:getStoresView():updateTypeCellSelectStatus(cellViewData, self:getSelectedIndex() == index)
        
        if storeType == GAME_STORE_TYPE.SEARCH_PROP then
            self:getStoresView():updateTypeCellPropsInfo(cellViewData, self.searchGoodsId_)
        else
            self:getStoresView():updateTypeCellPropsInfo(cellViewData)
        end
    end
end


function GameStoresMediator:updateStorePanel_(index)
    local storesViewData  = self:getStoresViewData()
    local storeTypeData   = self:getTypeDataList()[index] or {}
    local storeTypeDefine = STORE_TYPE_DEFINE[storeTypeData.storeType] or {}
    local storeMdtName    = checkstr(storeTypeDefine.mdtName)

    -- un-regist old contentMdt
    if self.contentMdtName_ then
        self:GetFacade():UnRegsitMediator(self.contentMdtName_)
    end

    -- update content
    if string.len(storeMdtName) > 0 and self.contentMdtName_ ~= storeMdtName then
        
        -- regist new contentMdt
        xTry(function()
            local contentMdtClass  = require(string.fmt('Game.mediator.stores.%1', storeMdtName))
            local contentMdtObject = contentMdtClass.new({ownerNode = storesViewData.storeLayer})
            self:GetFacade():RegistMediator(contentMdtObject)
            
            -- set storeData
            contentMdtObject:setStoreData(storeTypeData)

            -- init subType
            if self.initSubType_ and contentMdtObject.openSubType then
                contentMdtObject:openSubType(self.initSubType_)
                self.initSubType_ = nil
            end

            -- update content name
            self.contentMdtName_ = contentMdtObject:GetMediatorName()
        end, __G__TRACKBACK__)
    end
end


-------------------------------------------------
-- handler

function GameStoresMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    self.isControllable_ = false
    self:getStoresView():hideUI(function()
        self.isControllable_ = true
        self:close()
    end)
end


function GameStoresMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
end


function GameStoresMediator:onTypeListViewDataHandler_(p_convertview, idx)
    local index = idx + 1
    local cell  = p_convertview

    -- init cell
    local typeData = self.typeDataList_[index]
    if cell == nil then
        local typeListView = self:getStoresViewData().typeListView
        local typeListCell = self:getStoresView():createTypeCell(typeListView:getSizeOfCell())
        typeListCell.clickHotspot:setOnClickScriptHandler(handler(self, self.onClickTypeListCellHandler_))

        cell = typeListCell.view
        self.typeCellDict_[cell] = typeListCell
    end

    -- update cell
    local typeListCell = self.typeCellDict_[cell]
    if typeListCell then
        typeListCell.view:setTag(index)
        typeListCell.clickHotspot:setTag(index)
        self:updateTypeCell_(index, typeListCell)
    end
    return cell
end


function GameStoresMediator:onClickTypeListCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local typeIndex = sender:getTag()
    if self:getSelectedIndex() ~= typeIndex then
        self:setSelectedIndex(typeIndex)

        self.isControllable_ = false
        self:getStoresView():runAction(cc.Sequence:create(
            cc.DelayTime:create(0.2),
            cc.CallFunc:create(function()
                self.isControllable_ = true
            end)
        ))
    end
end


return GameStoresMediator
