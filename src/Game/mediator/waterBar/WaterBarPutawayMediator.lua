--[[
 * author : kaishiqi
 * descpt : 水吧 - 上架中介者
]]
local WaterBarPutawayView     = require('Game.views.waterBar.WaterBarPutawayView')
local WaterBarPutawayMediator = class('WaterBarPutawayMediator', mvc.Mediator)

local PUTAWAY_PROXY_NAME   = FOOD.WATER_BAR.PUTAWAY.PROXY_NAME
local PUTAWAY_PROXY_STRUCT = FOOD.WATER_BAR.PUTAWAY.PROXY_STRUCT

function WaterBarPutawayMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'WaterBarPutawayMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance

function WaterBarPutawayMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- init model
    self.putawayProxy_ = regVoProxy(PUTAWAY_PROXY_NAME, PUTAWAY_PROXY_STRUCT)

    -- create view
    self.viewNode_ = WaterBarPutawayView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddGameLayer(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    self:getViewData().libraryGridView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.clickArea, handler(self, self.onClickLibraryCellClickAreaHandler_))
        ui.bindClick(cellViewData.likeBtn, handler(self, self.onClickLibraryLikeButtonHandler_), false)
    end)
    self:getViewData().putawayTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.closeBtn, handler(self, self.onClickPutawayCellCloseButtonHandler_))
    end)
    for _, tabTButton in ipairs(self:getViewData().typeTabList or {}) do
        ui.bindClick(tabTButton, handler(self, self.onClickTypeTabButtonHandler_), false)
    end
    ui.bindClick(self:getViewData().btnKeyStore, handler(self, self.onClickBtnKeyStoreBtnHandler_))

    -- update datas
    local allPutawayDrinkMap = {}
    for drinkId, drinkNum in pairs(app.waterBarMgr:getAllPutaways()) do
        if checkint(drinkNum) > 0 then
            allPutawayDrinkMap[tostring(drinkId)] = drinkNum
        end
    end
    local waterBarLevelConf = CONF.BAR.LEVEL_UP:GetValue(app.waterBarMgr:getBarLevel())
    self.putawayProxy_:set(PUTAWAY_PROXY_STRUCT.FORMULA_DATA_MAP, app.waterBarMgr:getFormulaMap())
    self.putawayProxy_:set(PUTAWAY_PROXY_STRUCT.LIBRARY_DRINK_MAP, app.waterBarMgr:getAllDrinks())
    self.putawayProxy_:set(PUTAWAY_PROXY_STRUCT.PUTAWAY_DRINK_MAP, allPutawayDrinkMap)
    self.putawayProxy_:set(PUTAWAY_PROXY_STRUCT.PUTAWAY_LIMIT_NUM, checkint(waterBarLevelConf.stockNum))
    self.putawayProxy_:set(PUTAWAY_PROXY_STRUCT.PUTAWAY_DRINK_NUM, app.waterBarMgr:getAllPutawayNum())
    self.putawayProxy_:set(PUTAWAY_PROXY_STRUCT.SELECT_DRINK_TYPE, FOOD.WATER_BAR.DRINK_TYPE.ALL)
end


function WaterBarPutawayMediator:CleanupView()
    unregVoProxy(PUTAWAY_PROXY_NAME)

    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function WaterBarPutawayMediator:OnRegist()
    regPost(POST.WATER_BAR_SHELF_ON)
    regPost(POST.WATER_BAR_SHELF_OFF)
    regPost(POST.WATER_BAR_FORMULA_LIKE)
end


function WaterBarPutawayMediator:OnUnRegist()
    unregPost(POST.WATER_BAR_SHELF_ON)
    unregPost(POST.WATER_BAR_SHELF_OFF)
    unregPost(POST.WATER_BAR_FORMULA_LIKE)
end


function WaterBarPutawayMediator:InterestSignals()
    return {
        POST.WATER_BAR_SHELF_ON.sglName,
        POST.WATER_BAR_SHELF_OFF.sglName,
        POST.WATER_BAR_FORMULA_LIKE.sglName,
    }
end
function WaterBarPutawayMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.WATER_BAR_FORMULA_LIKE.sglName then
        local FORMULA_SEND_STRUCT = PUTAWAY_PROXY_STRUCT.FORMULA_LIKE_SEND
        local likeFormulaIdList   = string.split2(self.putawayProxy_:get(FORMULA_SEND_STRUCT.FORMULA_IDS), ',')
        for _, formulaId in ipairs(likeFormulaIdList) do

            -- reversal formulaLike
            local FORMULA_STRUCT = PUTAWAY_PROXY_STRUCT.FORMULA_DATA_MAP.FORMULA_DATA
            local formulaVoProxy = self.putawayProxy_:get(FORMULA_STRUCT, tostring(formulaId))
            local isFormulaLike  = WaterBarUtils.IsFormulaLike(formulaVoProxy:get(FORMULA_STRUCT.FORMULA_LIKE))
            formulaVoProxy:set(FORMULA_STRUCT.FORMULA_LIKE, isFormulaLike and 0 or 1)

            -- update  waterBarMgr cacheData
            app.waterBarMgr:setFormulaLike(formulaId, not isFormulaLike)
        end

    elseif name == POST.WATER_BAR_SHELF_ON.sglName then
        local LIBRARY_SEND_STRUCT = PUTAWAY_PROXY_STRUCT.PUTAWAY_ON_SEND
        local putawayOnDrinkMap   = json.decode(self.putawayProxy_:get(LIBRARY_SEND_STRUCT.DRINKS))
        for drinkId, drinkNum in pairs(putawayOnDrinkMap) do
            self:updateDrinkData_(drinkId, -drinkNum, drinkNum)
        end


    elseif name == POST.WATER_BAR_SHELF_OFF.sglName then
        local PUTAWAY_SEND_STRUCT = PUTAWAY_PROXY_STRUCT.PUTAWAY_OFF_SEND
        local putawayOffDrinkMap  = json.decode(self.putawayProxy_:get(PUTAWAY_SEND_STRUCT.DRINKS))
        for drinkId, drinkNum in pairs(putawayOffDrinkMap) do
            self:updateDrinkData_(drinkId, drinkNum, -drinkNum)
        end
    end
end


-------------------------------------------------
-- get / set

function WaterBarPutawayMediator:getViewNode()
    return  self.viewNode_
end
function WaterBarPutawayMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function WaterBarPutawayMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function WaterBarPutawayMediator:updateDrinkData_(drinkId, libraryAdd, putawayAdd)
    local LIBRARY_DRINK_STRUCT = PUTAWAY_PROXY_STRUCT.LIBRARY_DRINK_MAP.COUNT
    local PUTAWAY_DRINK_STRUCT = PUTAWAY_PROXY_STRUCT.PUTAWAY_DRINK_MAP.COUNT
    
    -- update proxy data
    local libraryNum = self.putawayProxy_:get(LIBRARY_DRINK_STRUCT, drinkId)
    local putawayNum = self.putawayProxy_:get(PUTAWAY_DRINK_STRUCT, drinkId)
    self.putawayProxy_:set(PUTAWAY_DRINK_STRUCT, putawayNum + putawayAdd, drinkId)
    self.putawayProxy_:set(LIBRARY_DRINK_STRUCT, libraryNum + libraryAdd, drinkId)

    -- erase empty data
    -- if self.putawayProxy_:get(LIBRARY_DRINK_STRUCT, drinkId) <= 0 then
    --     self.putawayProxy_:del(LIBRARY_DRINK_STRUCT, drinkId)
    -- end
    if self.putawayProxy_:get(PUTAWAY_DRINK_STRUCT, drinkId) <= 0 then
        self.putawayProxy_:del(PUTAWAY_DRINK_STRUCT, drinkId)
    end

    -- update waterBarMgr cacheData
    app.waterBarMgr:addDrinkNum(drinkId, libraryAdd)
    app.waterBarMgr:addPutawayNum(drinkId, putawayAdd)

    -- update putawayDrinkNum
    local putawayDrinkNum = self.putawayProxy_:get(PUTAWAY_PROXY_STRUCT.PUTAWAY_DRINK_NUM)
    self.putawayProxy_:set(PUTAWAY_PROXY_STRUCT.PUTAWAY_DRINK_NUM, putawayDrinkNum + putawayAdd)
end


-------------------------------------------------
-- handler

function WaterBarPutawayMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function WaterBarPutawayMediator:onClickTypeTabButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    sender:setChecked(true)
    
    local tabDrinkType = checkint(sender:getTag())
    if self.putawayProxy_:get(PUTAWAY_PROXY_STRUCT.SELECT_DRINK_TYPE) == tabDrinkType then
    else
        self.putawayProxy_:set(PUTAWAY_PROXY_STRUCT.SELECT_DRINK_TYPE, tabDrinkType)
    end
end


function WaterBarPutawayMediator:onClickBtnKeyStoreBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local putawayCount = self.putawayProxy_:get(PUTAWAY_PROXY_STRUCT.PUTAWAY_DRINK_NUM)
    local putawayLimit = self.putawayProxy_:get(PUTAWAY_PROXY_STRUCT.PUTAWAY_LIMIT_NUM)
    if putawayCount >= putawayLimit then
        app.uiMgr:ShowInformationTips(__('今日上架已满'))
    else
        local drinkIdList = self:getViewNode():getLibraryDrinkDataByType(FOOD.WATER_BAR.DRINK_TYPE.ALL)
        local onData      = {}
        local canPutNum   = putawayLimit - putawayCount
        for _, drinkId in ipairs(drinkIdList) do
            local drinkNum    = self.putawayProxy_:get(PUTAWAY_PROXY_STRUCT.LIBRARY_DRINK_MAP.COUNT, tostring(drinkId))
            local putDrinkNum = math.min(canPutNum, drinkNum)
            onData[tostring(drinkId)] = putDrinkNum
            canPutNum = canPutNum - putDrinkNum
            if canPutNum <= 0 then
                break
            end
        end
        local SEND_STRUCT  = PUTAWAY_PROXY_STRUCT.PUTAWAY_ON_SEND
        self.putawayProxy_:set(SEND_STRUCT.DRINKS, json.encode(onData))
        self:SendSignal(POST.WATER_BAR_SHELF_ON.cmdName, self.putawayProxy_:get(SEND_STRUCT):getData())
    end
end


function WaterBarPutawayMediator:onClickPutawayCellCloseButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local drinkId     = checkint(sender:getTag())
    local offData     = { [tostring(drinkId)] = 1 }
    local SEND_STRUCT = PUTAWAY_PROXY_STRUCT.PUTAWAY_OFF_SEND
    self.putawayProxy_:set(SEND_STRUCT.DRINKS, json.encode(offData))
    self:SendSignal(POST.WATER_BAR_SHELF_OFF.cmdName, self.putawayProxy_:get(SEND_STRUCT):getData())
end


function WaterBarPutawayMediator:onClickLibraryCellClickAreaHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local putawayCount = self.putawayProxy_:get(PUTAWAY_PROXY_STRUCT.PUTAWAY_DRINK_NUM)
    local putawayLimit = self.putawayProxy_:get(PUTAWAY_PROXY_STRUCT.PUTAWAY_LIMIT_NUM)

    if putawayCount < putawayLimit then
        local drinkId = checkint(sender:getTag())
        if self.putawayProxy_:get(PUTAWAY_PROXY_STRUCT.LIBRARY_DRINK_MAP.COUNT, tostring(drinkId)) > 0 then
            local onData      = { [tostring(drinkId)] = 1 }
            local SEND_STRUCT = PUTAWAY_PROXY_STRUCT.PUTAWAY_ON_SEND
            self.putawayProxy_:set(SEND_STRUCT.DRINKS, json.encode(onData))
            self:SendSignal(POST.WATER_BAR_SHELF_ON.cmdName, self.putawayProxy_:get(SEND_STRUCT):getData())
        else
            app.uiMgr:ShowInformationTips(__('没有更多库存了'))
        end
    else
        app.uiMgr:ShowInformationTips(__('已达到当前水吧等级的上架数量上限'))
    end
end


function WaterBarPutawayMediator:onClickLibraryLikeButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    sender:setChecked(true)
    
    local drinkId        = checkint(sender:getTag())
    local drinkConf      = CONF.BAR.DRINK:GetValue(tostring(drinkId))
    local formulaId      = tostring(drinkConf.formulaId)
    local SEND_STRUCT    = PUTAWAY_PROXY_STRUCT.FORMULA_LIKE_SEND
    local FORMULA_STRUCT = PUTAWAY_PROXY_STRUCT.FORMULA_DATA_MAP.FORMULA_DATA
    if self.putawayProxy_:has(FORMULA_STRUCT, tostring(formulaId)) then
        self.putawayProxy_:set(SEND_STRUCT.FORMULA_IDS, formulaId)
        self:SendSignal(POST.WATER_BAR_FORMULA_LIKE.cmdName, self.putawayProxy_:get(SEND_STRUCT):getData())
    else
        sender:setChecked(false)
        app.uiMgr:ShowInformationTips(__('还未拥有该配方'))
    end
end


return WaterBarPutawayMediator
