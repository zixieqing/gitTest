local PresetView     = require('Game.views.restaurant.PresetView')
local PresetMediator = class('PresetMediator', mvc.Mediator)

function PresetMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'PresetMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function PresetMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = PresetView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    self:getViewData().menuTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.applyBtn , handler(self, self.onClickApplyBtnHandler_))
        ui.bindClick(cellViewData.confirmBtn, handler(self, self.onClickConfirmButtonHandler_))
        cellViewData.toggleBtn:setOnClickScriptHandler(handler(self, self.onClickMenuToggleBtnHandler_))  
    end)
    self:getViewData().menuTableView:setCellUpdateHandler(handler(self, self.onUpdateMeneCellHandler_))

    -- update view
    self:reloadMenuTableView()
end


function PresetMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function PresetMediator:OnRegist()
    regPost(POST.RESTAURANT_APPLY_SUIT)
    regPost(POST.RESTAURANT_SAVE_SUIT)
end


function PresetMediator:OnUnRegist()
    unregPost(POST.RESTAURANT_SAVE_SUIT)
    unregPost(POST.RESTAURANT_APPLY_SUIT)
end


function PresetMediator:InterestSignals()
    return {
        POST.RESTAURANT_APPLY_SUIT.sglName,
        POST.RESTAURANT_SAVE_SUIT.sglName,
    }
end
function PresetMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.RESTAURANT_APPLY_SUIT.sglName then
        -- refresh data
        local suitId   = data.requestData.suitId
        local suitData = clone(app.restaurantMgr:getSuitDataBySuitId(suitId))
        app.gameMgr:GetUserInfo().avatarCacheData.location = suitData

        -- refresh restaurant
        app.restaurantMgr:setHousePresetSuitId(0)

        -- refresh avatar use num
        AppFacade.GetInstance():DispatchObservers(SGL.RESTAURANT_APPLY_SUIT_RESULT)
    elseif name == POST.RESTAURANT_SAVE_SUIT.sglName then
        -- refresh data
        local suitId   = data.requestData.suitId
        local suitData = clone(app.gameMgr:GetUserInfo().avatarCacheData.location)
        app.restaurantMgr:setSuitDataBySuitId(suitId, suitData)

        -- refresh view
        app.uiMgr:ShowInformationTips(__("保存成功"))
        self:reloadMenuTableView()
        
        -- refresh restaurant
        if checkint(suitId) == app.restaurantMgr:getHousePresetSuitId() then
            app.restaurantMgr:setHousePresetSuitId(checkint(suitId))
        end


    end
end
    
    
-------------------------------------------------
-- get / set

function PresetMediator:getViewNode()
    return  self.viewNode_
end
function PresetMediator:getViewData()
    return self:getViewNode():getViewData()
end

-------------------------------------------------
-- public

function PresetMediator:close()
    if app.restaurantMgr:getHousePresetSuitId() ~= 0 then
        app.restaurantMgr:setHousePresetSuitId(0)
    end
    app:UnRegsitMediator(self:GetMediatorName())
end


function PresetMediator:reloadMenuTableView()
    self:getViewData().menuTableView:resetCellCount(checkint(CONF.BUSINESS.PARMS:GetValue("maxRestaurantAvatarCustomSuitNum")))
end
-------------------------------------------------
-- private

function PresetMediator:isHasGuest()
    for _, seatInfo in pairs(self.ctorArgs_.serveringQueue or {}) do
        if seatInfo and checkint(seatInfo.leftSeconds) == -1 and seatInfo.customerUuid then
            return true
        elseif seatInfo and (checkint(seatInfo.isSpecialCustomer) == 1 or checkint(seatInfo.questEventId) > 0) then
            return true
        end
    end
    return false
end

-------------------------------------------------
-- handler
function PresetMediator:onUpdateMeneCellHandler_(cellIndex, cellViewData)
    local cellInfo = app.restaurantMgr:getSuitDataBySuitId(cellIndex)
    self:getViewNode():updateMeneCellHandler(cellViewData, next(cellInfo) == nil)
    cellViewData.view:setTag(cellIndex)
end


function PresetMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function PresetMediator:onClickConfirmButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if table.nums(app.gameMgr:GetUserInfo().avatarCacheData.location) <= 0 then
        app.uiMgr:ShowInformationTips(__("当前设置为空！"))
        return
    end

    local cellIndex = checkint(sender:getParent():getParent():getTag())
    local strTip = __("是否保存当前设置到预设_num_")
    if next(app.restaurantMgr:getSuitDataBySuitId(cellIndex)) ~= nil then
        strTip = __("是否替换当前设置到预设_num_")
    end

    local commonTip = require('common.NewCommonTip').new({text = string.fmt(strTip, { _num_ = tostring(cellIndex)}), callback = function ()
        self:SendSignal(POST.RESTAURANT_SAVE_SUIT.cmdName, {suitId = cellIndex})
    end})
    commonTip:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(commonTip)
end


function PresetMediator:onClickApplyBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self:isHasGuest() then
        app.uiMgr:ShowInformationTips(__("餐厅还留有特殊客人,暂不能切换套装"))
    else
        local cellIndex = checkint(sender:getParent():getParent():getTag())
        local commonTip = require('common.NewCommonTip').new({text = string.fmt(__("是否启用预设_num_"), { _num_ = cellIndex}), callback = function ()
            self:SendSignal(POST.RESTAURANT_APPLY_SUIT.cmdName, {suitId = cellIndex})
        end})
        commonTip:setPosition(display.center)
        app.uiMgr:GetCurrentScene():AddDialog(commonTip)
    end
end


function PresetMediator:onClickMenuToggleBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local cellIndex = checkint(sender:getParent():getTag())
    if next(app.restaurantMgr:getSuitDataBySuitId(cellIndex)) == nil then
        sender:setChecked(false)
        return
    end

    if app.restaurantMgr:getHousePresetSuitId() == cellIndex then
        sender:setChecked(false)
        app.restaurantMgr:setHousePresetSuitId(0)
    else
        for _, cellViewData in pairs(self:getViewData().menuTableView:getCellViewDataDict()) do
            cellViewData.toggleBtn:setChecked(cellIndex == checkint(cellViewData.view:getTag()))
        end
        app.restaurantMgr:setHousePresetSuitId(cellIndex)
    end
end


return PresetMediator
