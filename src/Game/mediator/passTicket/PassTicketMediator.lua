--[[
 * descpt : pass ticket 中介者
]]
local NAME = 'passTicket.PassTicketMediator'
local PassTicketMediator = class(NAME, mvc.Mediator)

local uiMgr         = app.uiMgr
local gameMgr       = app.gameMgr
local passTicketMgr = app.passTicketMgr

local PURCHASE_POPUP_TAG = 1102120

function PassTicketMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self.activityId = self.ctorArgs_.activityId
    self.timerName = app.activityMgr:GetHomeActivityIconTimerName(self.activityId, ACTIVITY_TYPE.PASS_TICKET)
end

-------------------------------------------------
-- inheritance method
function PassTicketMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    
    -- create view
    local viewComponent = require('Game.views.passTicket.PassTicketView').new()
    self:SetViewComponent(viewComponent)
    display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})
    -- uiMgr:SwitchToScene(viewComponent)
    self:initOwnerScene_()
    self.viewData_      = viewComponent:getViewData()
    self:getOwnerScene():AddDialog(viewComponent)

    self:initData_()
    -- init view
    self:initView_()
    
end

function PassTicketMediator:initOwnerScene_()
    self.ownerScene_ = uiMgr:GetCurrentScene()
end

function PassTicketMediator:initData_()

   
end

function PassTicketMediator:initView_()
    local viewData = self:getViewData()
    local shadowLayer = viewData.shadowLayer
    display.commonUIParams(shadowLayer, {cb = handler(self, self.onClickShadowAction), animate = false})

    viewData.tableView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))

    display.commonUIParams(viewData.tipsImg, {cb = handler(self, self.onClickTipsBtnAction)})
    display.commonUIParams(viewData.overflowBtn, {cb = handler(self, self.onClickOverflowBtnAction)})
    display.commonUIParams(viewData.oneKeyDrawBtn, {cb = handler(self, self.onClickOneKeyDrawBtnAction), animate = false})
    display.commonUIParams(viewData.superRewardTitle, {cb = handler(self, self.onClickSuperRewardTitleAction)})

    self:GetViewComponent():updateCardImg(app.passTicketMgr:GetPassTickeCardId())

end

function PassTicketMediator:cleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        viewComponent:stopAllActions()
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function PassTicketMediator:OnRegist()
    regPost(POST.ACTIVITY_PASS_TICKET, true)
    regPost(POST.ACTIVITY_DRAW_PASS_TICKET, true)
    regPost(POST.ACTIVITY_SKIP_PASS_TICKET, true)
    regPost(POST.ACTIVITY_DRAW_PASS_TICKET_OVERFLOW, true)
    self:enterLayer()
end
function PassTicketMediator:OnUnRegist()
    unregPost(POST.ACTIVITY_PASS_TICKET)
    unregPost(POST.ACTIVITY_DRAW_PASS_TICKET)
    unregPost(POST.ACTIVITY_SKIP_PASS_TICKET)
    unregPost(POST.ACTIVITY_DRAW_PASS_TICKET_OVERFLOW)

    self:cleanupView()
end


function PassTicketMediator:InterestSignals()
    return {
        SGL.CACHE_MONEY_UPDATE_UI,
        POST.ACTIVITY_PASS_TICKET.sglName,
        POST.ACTIVITY_DRAW_PASS_TICKET.sglName,
        POST.ACTIVITY_SKIP_PASS_TICKET.sglName,
        POST.ACTIVITY_DRAW_PASS_TICKET_OVERFLOW.sglName,

        SGL.Restaurant_Shop_GetPayOrder_Callback,	-- 创建支付订单信号
        'PASS_TICKET_GET_PAY_ORDER',
        EVENT_PAY_MONEY_SUCCESS_UI,
        EVENT_APP_STORE_PRODUCTS,
        COUNT_DOWN_ACTION,
    }
end

function PassTicketMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    self:getOwnerScene():AddViewForNoTouch()
    if name == POST.ACTIVITY_PASS_TICKET.sglName then
        passTicketMgr:InitData(body)

        if isElexSdk() then
            local t = {body.channelProductId}
            require('root.AppSDK').GetInstance():QueryProducts(t)
        end
        self:refreshUI()
    elseif name == EVENT_APP_STORE_PRODUCTS then
        self:refreshUI()
    elseif name == POST.ACTIVITY_DRAW_PASS_TICKET.sglName then
        local rewards     = body.rewards or {}
        if next(rewards) ~= nil then
            uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
        end

        local viewComponent = self:GetViewComponent()
        local viewData = self:getViewData()

        local requestData = body.requestData or {}
        local level       = checkint(requestData.level)
        local homeData    = passTicketMgr:GetHomeData()
        local levelList   = homeData.level or {}
        local curLevel    = checkint(homeData.curLevel)
        local hasPurchasePassTicket = checkint(homeData.hasPurchasePassTicket)
        if level == 0 then
            for i, levelData in ipairs(levelList) do
                if checkint(levelData.hasDrawn) <= 1 and (curLevel == 0 or checkint(levelData.level) < curLevel) then
                    if hasPurchasePassTicket > 0 then
                        levelData.hasDrawn = 2
                    else
                        levelData.hasDrawn = 1
                    end
                end
            end
            viewComponent:updateTableView(viewData, levelList)
        else
            local newLevelData = nil
            local dataIndex = nil
            for i, levelData in ipairs(levelList) do
                if checkint(levelData.hasDrawn) <= 1 and checkint(levelData.level) == level then
                    if hasPurchasePassTicket > 0 then
                        levelData.hasDrawn = 2
                    else
                        levelData.hasDrawn = 1
                    end

                    local tableView = viewData.tableView
                    local cell = tableView:cellAtIndex(i - 1)
                    if cell then
                        local layer = cell.layer
                        viewComponent:updateCell(layer, levelData, curLevel, hasPurchasePassTicket)
                    end
                    break
                end
            end
        end
        
        viewComponent:updateOneKeyDrawBtnShowState(viewData, levelList, curLevel, hasPurchasePassTicket)

    elseif name == POST.ACTIVITY_SKIP_PASS_TICKET.sglName then
        local requestData = body.requestData or {}
        local level       = checkint(requestData.level)
        local homeData    = passTicketMgr:GetHomeData()
        local levelList   = homeData.level or {}
        local levelConf   = passTicketMgr:GetLevelConf(homeData.passTicketId)
        local levelConfData = levelConf[tostring(level)] or {}
        local levelConfDataExp = checkint(levelConfData.exp)

        local skipConsume = passTicketMgr:GetSkipConsume(level)
        local consume = {}
        for i, v in ipairs(skipConsume) do
            table.insert(consume, {goodsId = v.goodsId, num = -1 * checkint(v.num)})
        end
        CommonUtils.DrawRewards(consume)
        passTicketMgr:UpdateExp(checkint(homeData.exp) + levelConfDataExp)

        local tableView = self:getViewData().tableView
        local listContentOffset = tableView:getContentOffset()
        self:refreshUI()
        tableView:setContentOffset(listContentOffset)

    elseif name == POST.ACTIVITY_DRAW_PASS_TICKET_OVERFLOW.sglName then
        local rewards     = body.rewards or {}
        local times       = checkint(body.requestData.times)
        if next(rewards) ~= nil then
            uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
        end
        
        local homeData    = passTicketMgr:GetHomeData()
        local overflowCircle = checkint(passTicketMgr:GetOverflowCircle())
        local curLvExp = checkint(passTicketMgr:GetCurLvExp()) - overflowCircle * times
        
        passTicketMgr:UpdateOverflowRewardsDrawnTimes(times)
        passTicketMgr:SetCurLvExp(curLvExp)

        local viewComponent = self:GetViewComponent()
        local viewData = self:getViewData()
        viewComponent:updateLevelProgress(viewData, true, curLvExp, homeData.lvMaxExp)
        viewComponent:updateOverflowConsume(viewData, overflowCircle)

    elseif name == SGL.CACHE_MONEY_UPDATE_UI then
    elseif name == 'PASS_TICKET_GET_PAY_ORDER' then
        local homeData = app.passTicketMgr:GetHomeData()
        self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder, {productId = homeData.productId, name = 'passTicket.PassTicketMediator'})
    elseif name == SGL.Restaurant_Shop_GetPayOrder_Callback then
        -- body不存在  或  请求名称不相同
		if not body or body.requestData.name ~= NAME then return end

		if body.orderNo then
	        if device.platform == 'android' or device.platform == 'ios' then
                local AppSDK = require('root.AppSDK')
                local homeData = app.passTicketMgr:GetHomeData()
				local amount = homeData.price
				local property = body.orderNo
			    AppSDK.GetInstance():InvokePay({amount = amount, property = property,goodsId = tostring(homeData.channelProductId),
                    goodsName = __('幻晶石'), quantifier = __('个'),price = 0.1, count = 1})
			end
        end
        
    elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
        if checkint(body.type) == PAY_TYPE.PT_PASS_TICKET then
            self:enterLayer()

            local popView = self:getOwnerScene():GetDialogByTag(PURCHASE_POPUP_TAG)
            if popView and not tolua.isnull(popView) then
                popView:updateRechangeBtn()
            end
        end
    elseif name == COUNT_DOWN_ACTION then
        local timerName = body.timerName
		if timerName == self.timerName then
            local countdown = body.countdown
            self:GetViewComponent():updateActTimeLabel(self:getViewData(), countdown)
            if countdown <= 0 then
                app.activityMgr:ShowBackToHomeUI()
                self:getOwnerScene():RemoveViewForNoTouch()
            end
		end
    end

    self:getOwnerScene():RemoveViewForNoTouch()
end

-------------------------------------------------
-- get / set

function PassTicketMediator:getViewData()
    return self.viewData_
end

function PassTicketMediator:getOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function PassTicketMediator:enterLayer()
    self:SendSignal(POST.ACTIVITY_PASS_TICKET.cmdName, {activityId = self.activityId})
end

function PassTicketMediator:refreshUI()
    local viewComponent = self:GetViewComponent()
    local homeData      = passTicketMgr:GetHomeData()
    viewComponent:refreshUI(homeData)
end

-------------------------------------------------
-- private method
function PassTicketMediator:onDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1

	if pCell == nil then
        local tableView = self:getViewData().tableView
        local size = tableView:getSizeOfCell()
        pCell = CTableViewCell:new()
        pCell:setContentSize(size)
        local layer = require('Game.views.passTicket.PassTicketListCell').new({size = size})
        display.commonUIParams(layer, {ap = display.CENTER, po = cc.p(size.width / 2, size.height / 2)})
        pCell.layer = layer
        
        display.commonUIParams(layer.drawBtn, {cb = handler(self, self.onClickDrawBtnAction), animate = false})

        pCell:addChild(layer)
    end

    local layer = pCell.layer

    local homeData = passTicketMgr:GetHomeData()
    local levelList = homeData.level or {}
    self:GetViewComponent():updateCell(layer, levelList[index] or {}, checkint(homeData.curLevel), checkint(homeData.hasPurchasePassTicket))
    layer.drawBtn:setTag(index)
    
	return pCell
end


-------------------------------------------------
-- check

-------------------------------------------------
-- handler

function PassTicketMediator:onClickTipsBtnAction(sender)
    uiMgr:ShowIntroPopup({moduleId = -26})
end

function PassTicketMediator:onClickOverflowBtnAction(sender)
    local curLevel = checkint(passTicketMgr:GetCurLevel())
    if curLevel ~= 0 then
        uiMgr:ShowInformationTips(__('等级满级时，可以兑换'))
        return 
    end

    local curLvExp = checkint(passTicketMgr:GetCurLvExp())
    local overflowCircle = checkint(passTicketMgr:GetOverflowCircle())
    if curLvExp < overflowCircle then
        uiMgr:ShowInformationTips(__('溢出经验不足'))
        return
    end
    -- 修改为兑换全部可兑换宝箱
    local times = math.floor(curLvExp / overflowCircle)
    self:SendSignal(POST.ACTIVITY_DRAW_PASS_TICKET_OVERFLOW.cmdName, {activityId = self.activityId, times = times})
end

function PassTicketMediator:onClickOneKeyDrawBtnAction(sender)
    local state = checkint(sender:getTag())

    if state <= 0 then
        uiMgr:ShowInformationTips(__('没有可领取的奖励'))
        return
    end
    
    self:SendSignal(POST.ACTIVITY_DRAW_PASS_TICKET.cmdName, {activityId = self.activityId, level = 0})
end

function PassTicketMediator:onClickSuperRewardTitleAction()
    local popView = require('Game.views.passTicket.PassTicketPurchasePopup').new()
    popView:setTag(PURCHASE_POPUP_TAG)
    display.commonUIParams(popView, {ap = display.CENTER, po = display.center})
    self:getOwnerScene():AddDialog(popView)
end

function PassTicketMediator:onClickDrawBtnAction(sender)
    local index = sender:getTag()
    local homeData = passTicketMgr:GetHomeData()
    local levelList = homeData.level or {}
    local levelData = levelList[index]
    local hasDrawn = checkint(levelData.hasDrawn)
    local hasPurchasePassTicket = checkint(homeData.hasPurchasePassTicket)

    if (hasDrawn == 1 and hasPurchasePassTicket == 0) or (hasDrawn > 1) then
        uiMgr:ShowInformationTips(__('已领取'))
        return
    end

    local level     = checkint(levelData.level)
    local curLevel = checkint(passTicketMgr:GetCurLevel())
    if curLevel ~= 0 and level > curLevel then
        uiMgr:ShowInformationTips(__('请完成前置等级任务'))
        return
    end
    
    if level == curLevel then
        -- todo skip level
        local skipConsume = passTicketMgr:GetSkipConsume(level)
        
        local isSatisfya = true
        local consumeTipText = ''
        for i, consumeData in ipairs(skipConsume) do
            local goodsId = consumeData.goodsId
            local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
            consumeTipText = string.fmt(__('是否消耗_num__name_来提升等级'), {_num_ = tostring(consumeData.num), _name_ = tostring(goodsConfig.name)})
            if gameMgr:GetAmountByIdForce(goodsId) < checkint(consumeData.num) then
                isSatisfya = false
                break
            end
        end

        if not isSatisfya then
            uiMgr:ShowInformationTips(__('道具不足'))
            return
        end

        local CommonTip = require( 'common.NewCommonTip' ).new({text = consumeTipText,
            isOnlyOK = false, callback = function ()
                self:SendSignal(POST.ACTIVITY_SKIP_PASS_TICKET.cmdName, {activityId = self.activityId, level = level})
        end})
        CommonTip:setPosition(display.center)
        self:getOwnerScene():AddDialog(CommonTip)
        
        return
    end

    self:SendSignal(POST.ACTIVITY_DRAW_PASS_TICKET.cmdName, {activityId = self.activityId, level = level})
end

function PassTicketMediator:onClickRechangeBtnAction()
    
end

function PassTicketMediator:onClickShadowAction()
    app:UnRegsitMediator(NAME)
end

return PassTicketMediator

