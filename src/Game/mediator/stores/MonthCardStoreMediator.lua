--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 月卡商店中介者
]]
local MonthCardStoreView     = require('Game.views.stores.MonthCardStoreView')
local MonthCardStoreMediator = class('MonthCardStoreMediator', mvc.Mediator)

local NAME     = 'MonthCardStoreMediator'

local gameMgr = app.gameMgr

function MonthCardStoreMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'MonthCardStoreMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function MonthCardStoreMediator:Initial(key)
    self.super.Initial(self, key)
    
    -- init vars
    self.ownerNode_      = self.ctorArgs_.ownerNode
    self.isControllable_ = true

    -- create view
    if self.ownerNode_ then
        self.storesView_ = MonthCardStoreView.new(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self.storesView_)
        self.viewData_ = self.storesView_:getViewData()
        self:initView_()
    end
end


function MonthCardStoreMediator:CleanupView()
    self:stopCountdownUpdate_()
    if self.storesView_  and (not tolua.isnull(self.storesView_)) then
        self.storesView_:runAction(cc.RemoveSelf:create())
        self.storesView_ = nil
    end
end


function MonthCardStoreMediator:OnRegist()
    regPost(POST.GAME_STORE_DIAMOND)
end
function MonthCardStoreMediator:OnUnRegist()
    unregPost(POST.GAME_STORE_DIAMOND)
end


function MonthCardStoreMediator:InterestSignals()
    return {
        POST.GAME_STORE_DIAMOND.sglName,
        SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback,
        EVENT_PAY_MONEY_SUCCESS_UI,
        EVENT_APP_STORE_PRODUCTS,
    }
end
function MonthCardStoreMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody() or {}

    if name == EVENT_PAY_MONEY_SUCCESS_UI then
        -- body不存在  或  会员id不相同
        if checkint(data.type) == PAY_TYPE.PT_MEMBER then
            -- local member = data.member or {}
            -- local memberDatas = checktable(self.datas).memberDatas or {}
            -- for i, data in ipairs(memberDatas) do
            --     local memberData = data.memberData or {}
            --     if member[tostring(memberData.memberId)] then
            --         memberData.leftSeconds = member[tostring(memberData.memberId)].leftSeconds
            --     end
            -- end
            
            self:getStoresView():runAction(cc.Sequence:create(cc.DelayTime:create(0.2) , cc.CallFunc:create(function ()
                self:SendSignal(POST.GAME_STORE_DIAMOND.cmdName , {})
            end)))
        end
    elseif name == POST.GAME_STORE_DIAMOND.sglName then
        self:setStoreData_({dataTimestamp = os.time(), storeData = data.member}, true)
    elseif name == EVENT_APP_STORE_PRODUCTS then
        self:refreshUI()
    elseif name == SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback then 
        -- data不存在  或  请求名称不相同
        local requestData = data.requestData or {}
        if requestData.name ~= NAME then return end

        if data.orderNo then
            if device.platform == 'android' or device.platform == 'ios' then
                local AppSDK = require('root.AppSDK')
                local amount = requestData.price_
                local property = data.orderNo
                AppSDK.GetInstance():InvokePay({amount = amount, property = property, goodsId = tostring(requestData.channelProductId_),
                    goodsName = __('幻晶石'), quantifier = __('个'),price = 0.1, count = 1})
            end
        end
    end
end

-------------------------------------------------
-- get / set

function MonthCardStoreMediator:getStoresView()
    return self.storesView_
end
function MonthCardStoreMediator:getStoresViewData()
    return self:getStoresView() and self:getStoresView():getViewData() or {}
end

-------------------------------------------------
-- public

function MonthCardStoreMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end

function MonthCardStoreMediator:setStoreData(storeData)
    self:setStoreData_(storeData)
end


function MonthCardStoreMediator:refreshUI()
    if self:getStoresView() and  self:getStoresView().viewData_  then
        self:getStoresView():refreshUI(self.datas, self.dataTimestamp_)
    end
end

function MonthCardStoreMediator:calcEndTime(leftSeconds)
    return self.dataTimestamp_ + leftSeconds
end

function MonthCardStoreMediator:calcRealLeftSeconds(endTime)
    return math.max(endTime - os.time(), 0)
end

-------------------------------------------------
-- private
function MonthCardStoreMediator:setStoreData_(storeData, isRefresh)
    storeData = storeData or {}
    -- logInfo.add(5, tableToString(storeData))
    self.dataTimestamp_  = checkint(storeData.dataTimestamp)
    self.datas, self.minCountdown = self:initData_(storeData)

    --if not CommonUtils.IsNeedExtraGetRealPriceData() or isRefresh then
    self:refreshUI()
    --end

    -- start countdown
    self:stopCountdownUpdate_()
    if self.minCountdown then
        self:startCountdownUpdate_()
    end
end

function MonthCardStoreMediator:initData_(data)
    local datas = {}
    local vipConfMap = {}
    local vipJosn = CommonUtils.GetConfigAllMess('vip', 'player') or {}
    for i, v in pairs(vipJosn) do
        vipConfMap[tostring(v.vipLevel)] = v
    end

    local activityData = {}
    local memberDatas = {}
    datas.memberDatas = {}

    local storeData = data.storeData or {}
    local minCountdown = nil
    local member = clone(gameMgr:GetUserInfo().member)
    for k, memberData in pairs(storeData) do
        local memberId = tostring(memberData.memberId)
        -- 大于10000即为活动数据
        local isActData = checkint(memberData.productId) > 10000
        local leftSeconds = isActData and checkint(memberData.purchaseLeftSeconds) or checkint(memberData.leftSeconds)
        local endSeconds = self:calcEndTime(leftSeconds)
        local realLeftSeconds = self:calcRealLeftSeconds(endSeconds)
        
        if minCountdown == nil then
            minCountdown = realLeftSeconds
        else
            minCountdown = math.min(realLeftSeconds, minCountdown)
        end

        if isActData then
            -- 活动数据根据 剩余时间来添加
            -- logInfo.add(5, tableToString(realLeftSeconds))
            if realLeftSeconds > 0 then
                table.insert(activityData, {
                    vipConf = vipConfMap[memberId],
                    memberData = memberData,
                    -- adImg = 
                }) 
            end
        else
            table.insert(memberDatas, {
                vipConf = vipConfMap[memberId],
                memberData = memberData
            })
            
            if realLeftSeconds > 0 then
                member[memberId] = member[memberId] or {}
                member[memberId].leftSeconds = realLeftSeconds
                member[memberId].endTime = endSeconds
            end
        end
    end
    
    datas.memberDatas  = memberDatas
    datas.activityData = activityData

    if minCountdown ~= nil then
        gameMgr:UpdateMember(member)
    end
    if CommonUtils.IsNeedExtraGetRealPriceData() then
        local t = {}
        for name,val in pairs(activityData) do
            if val.memberData.channelProductId then
                table.insert(t, val.memberData.channelProductId)
            end
        end
        for name,val in pairs(memberDatas) do
            if val.memberData.channelProductId then
                table.insert(t, val.memberData.channelProductId)
            end
        end
        require('root.AppSDK').GetInstance():QueryProducts(t)
    end

    return datas, minCountdown
end

function MonthCardStoreMediator:initView_()
    local viewData = self:getStoresViewData()
    viewData.tableView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))
end

function MonthCardStoreMediator:onDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1

	if pCell == nil then
        local tableView = self:getStoresViewData().tableView
        local size = tableView:getSizeOfCell()
        pCell = self:getStoresView():CreateCell(size)
    end

    local cellViewData        = pCell.viewData
    self:getStoresView():updateCell(cellViewData, checktable(self.datas.memberDatas)[index] or {}, self.dataTimestamp_)

	return pCell
end

function MonthCardStoreMediator:stopCountdownUpdate_()
    if self.countdownUpdateHandler_ then
        scheduler.unscheduleGlobal(self.countdownUpdateHandler_)
        self.countdownUpdateHandler_ = nil
    end
end
function MonthCardStoreMediator:startCountdownUpdate_()
    if self.countdownUpdateHandler_ then return end
    self.countdownUpdateHandler_ = scheduler.scheduleGlobal(function()
        local viewData = self:getStoresViewData()
        if viewData.actView and viewData.actView:isVisible() then
            local activityList = viewData.activityList
            local nodes = activityList:getNodes()
            if nodes and next(nodes) ~= nil then
                local activityData = self.datas.activityData
                for i, node in ipairs(nodes) do
                    local index = node:getTag()
                    local actData = activityData[index] or {}
                    local memberData = actData.memberData
                    if memberData then
                        local purchaseLeftSeconds = checkint(memberData.purchaseLeftSeconds)
                        local endSeconds = self:calcEndTime(purchaseLeftSeconds)
                        local realLeftSeconds = self:calcRealLeftSeconds(endSeconds)
                        node:updateTimeLabel(realLeftSeconds)
                    end
                end
            end
        end

        local tableView = viewData.tableView
        local cells = tableView:getCells()
        for i, cell in ipairs(cells) do
            if cell and not tolua.isnull(cell) then
                local cellViewData = cell.viewData
                local storeCell    = cellViewData.storeCell
                storeCell:updateMemberInfoLabel(storeCell:getData().memberData or {})
            end
        end
    end, 1)
end

-------------------------------------------------
-- handler

return MonthCardStoreMediator
