--[[
 * descpt : 特殊活动 幸运字符页签mediator
]]
local NAME = 'SpActivityLuckNumberPageMediator'
local SpActivityLuckNumberPageMediator = class(NAME, mvc.Mediator)

local uiMgr = app.uiMgr
local CommonUtils = CommonUtils
local ACTIVITY_COUNTDOWN_LUCKNUMBER = 'ACTIVITY_COUNTDOWN_LUCKNUMBER'

local RES_DICT = {
    ACTIVITY_LUCK_NUM_PIC_NO_GET         = _res('ui/home/activity/luckNumber/activity_luck_num_pic_no_get.png'),
    ACTIVITY_LUCK_NUM_PIC                = _res('ui/home/activity/luckNumber/activity_luck_num_pic.png'),
}

function SpActivityLuckNumberPageMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self.totalStockText = string.split(__('全服库存：|_cost_|'), '|')
    self.leftStockText = string.split(__('剩余购买次数：|_cost_|'), '|')

end


-------------------------------------------------
-- inheritance method

function SpActivityLuckNumberPageMediator:Initial(key)
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    self.typeData_  = self.ctorArgs_.typeData

    local view
    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        ---@type SpActivityLuckNumberPageView
        view = require("Game.views.specialActivity.SpActivityLuckNumberPageView").new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)

    else
        view = require( 'Game.views.activity.luckNumber.ActivityLuckNumberView' ).new()
        display.commonUIParams(view:GetViewData().ruleBtn, {cb = handler(self, self.OnClickRuleBtnAction)})
        local posterImage = checktable(self.typeData_.image)[i18n.getLang()]
        view:UpdateBg(posterImage)
    end

    self:SetViewComponent(view)
    self.viewData_ = view:GetViewData()

    self:InitView_()
end

function SpActivityLuckNumberPageMediator:InitView_()
    local viewData = self:GetViewData()

    display.commonUIParams(viewData.buyButton, {cb = handler(self , self.OnClickBuyButtonAction), animate = false})
    display.commonUIParams(viewData.exchangeBtn, {cb = handler(self , self.OnClickExchangeBtnAction), animate = false})

    viewData.tableView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAdapter))

end

function SpActivityLuckNumberPageMediator:CleanupView()
    if self.ownerNode_ then
        local viewData = self:GetViewData()
        if viewData.exchangeBtnLayer then
            viewData.exchangeBtnLayer:stopAllActions()
        end
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function SpActivityLuckNumberPageMediator:OnRegist()
    regPost(POST.ACTIVITY_LUCKY_NUM_HOME)
    regPost(POST.ACTIVITY_LUCKY_NUM_PRIZE_HOME)

    self:EnterLayer()
end
function SpActivityLuckNumberPageMediator:OnUnRegist()
    unregPost(POST.ACTIVITY_LUCKY_NUM_HOME)
    unregPost(POST.ACTIVITY_LUCKY_NUM_PRIZE_HOME)

    self:StopTimer_()
end


function SpActivityLuckNumberPageMediator:InterestSignals()
    local signals = {
        POST.ACTIVITY_LUCKY_NUM_HOME.sglName,
        POST.ACTIVITY_LUCKY_NUM_PRIZE_HOME.sglName,
        POST.ACTIVITY_LUCKY_NUM_PRIZE.sglName,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,            -- 刷新幸运字符 (兑换道具后更新)
        SGL.Restaurant_Shop_GetPayOrder_Callback,	-- 创建支付订单信号
        EVENT_PAY_MONEY_SUCCESS_UI,
        COUNT_DOWN_ACTION
	}
	return signals
end
function SpActivityLuckNumberPageMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()

    if name == POST.ACTIVITY_LUCKY_NUM_HOME.sglName then
        
        -- 修正 购买限量 与 库存
        body.buyLimit = math.max(checkint(body.buyLimit), 0)
        body.stock = math.max(checkint(body.stock), 0)

        self:InitHomeData(body)

        local leftTime = checkint(body.countDown)
        if leftTime > 0 then
            -- 购买倒计时
            self:AddTimer_(leftTime)
        end

    elseif name == POST.ACTIVITY_LUCKY_NUM_PRIZE_HOME.sglName then

        local mediator = app:RetrieveMediator("ActivityExchangeLargeMediator")
        if mediator then
            return
        end
        
        local temp = {}
        local prize = body.prize or {}
        for index, value in orderedPairs(prize) do
            table.insert(temp, {
                leftExchangeTimes = value.remain,
                rewards = value.rewards,
                require = value.consume,
                id = value.prizeId
            })
        end
        self.exchangeListData = temp

        local activityId = body.requestData.activityId
        local activityHomeDatas = self:GetTypeData()
        local leftSeconds = activityHomeDatas.leftSeconds
        if activityHomeDatas.closeTimestamp_ then
            leftSeconds = checkint(activityHomeDatas.closeTimestamp_) - os.time()
        end

        local params = {
            isLarge = true,
            exchangePost = POST.ACTIVITY_LUCKY_NUM_PRIZE, 
            exchangeListData = temp,
            leftSeconds = leftSeconds,
            extra = {activityId = activityId},
            exchangeIdName = 'prizeId',
            oneMaxExchangeTimes = 1,
            leftExchangeName = __('全服剩余兑换次数 _num_次'),
        }
        local mediator = require("Game.mediator.activity.ActivityExchangeLargeMediator").new(params)
        self:GetFacade():RegistMediator(mediator)
    elseif name == POST.ACTIVITY_LUCKY_NUM_PRIZE.sglName then
        
        local requestData = body.requestData or {}
        local prizeId = checkint(requestData.prizeId)
        if prizeId <= 0 then return end

        local remain = body.remain or {}

        for index, value in ipairs(self.exchangeListData) do

            local times = checkint(remain[tostring(value.id)])
            value.leftExchangeTimes = math.max(times, 0)

            if checkint(value.id) == prizeId then
                local consume = clone(value.require or {})
                for _, consumeData in ipairs(consume) do
                    consumeData.num = -checkint(consumeData.num)
                end
                -- 这里不发送刷新道具的事件 从RewardPopup 中发送
                CommonUtils.DrawRewards(consume, false, false, false)
            end
        end

        local mediator = app:RetrieveMediator("ActivityExchangeLargeMediator")
        if mediator == nil then
            return
        end
        mediator.exchangeListData = self.exchangeListData
        
        local rewards = body.rewards or {}
        if next(rewards) then
            uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
        end

    elseif name == SGL.Restaurant_Shop_GetPayOrder_Callback then
        -- body不存在  或  请求名称不相同
        if not body or body.requestData.name ~= NAME then return end

        if body.orderNo then
            if device.platform == 'android' or device.platform == 'ios' then
                local AppSDK = require('root.AppSDK')
                local homeData = self:GetHomeData()
                AppSDK.GetInstance():InvokePay({amount = tonumber(homeData.price), property = body.orderNo, goodsId = tostring(homeData.channelProductId),
                    goodsName = __('幻晶石'), quantifier = __('个'),price = 0.1, count = 1})
            end
        end
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        
        self:UpdateLuckNumCells(self:GetViewData(), self:GetHomeData())

    elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
        
        if checkint(body.type) == PAY_TYPE.PT_LUCK_NUMBER then
            self:EnterLayer()
        end

    elseif name == COUNT_DOWN_ACTION then
        local timerName = body.timerName
        if timerName == NAME then
            local countdown = body.countdown
            local viewData, homeData = self:GetViewData(), self:GetHomeData()
            homeData.countDown = countdown
            if countdown <= 0 then
                self:EnterLayer()
            else
                self:UpdateCountDown(viewData, homeData)
            end

        end

    end
end


-------------------------------------------------
-- handler method

function SpActivityLuckNumberPageMediator:OnClickBuyButtonAction()
    local homeData = self:GetHomeData()
    if checkint(homeData.stock) <= 0 then
        uiMgr:ShowInformationTips(__('全服库存不足'))
        return
    elseif checkint(homeData.buyLimit) <= 0 then
        uiMgr:ShowInformationTips(__('已达到最大购买次数'))
        return
    end

    self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder, {productId = homeData.productId, name = NAME})
end

--[[
前往按钮回调
--]]
function SpActivityLuckNumberPageMediator:OnClickExchangeBtnAction( sender )
    PlayAudioByClickNormal()
    self:SendSignal(POST.ACTIVITY_LUCKY_NUM_PRIZE_HOME.cmdName, {activityId = checkint(self:GetTypeData().activityId)})
end

-------------------------------------------------
-- get /set

function SpActivityLuckNumberPageMediator:GetViewData()
    return self.viewData_ or {}
end

function SpActivityLuckNumberPageMediator:GetHomeData()
    return self.homeData_ or {}
end

function SpActivityLuckNumberPageMediator:GetTypeData()
    return self.typeData_ or {}
end

-------------------------------------------------
-- private method

function SpActivityLuckNumberPageMediator:OnDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1

	local viewComponent = self:GetViewComponent()

	if pCell == nil then
		local tableView = self:GetViewData().tableView
		pCell = viewComponent:CreateCell(tableView:getSizeOfCell())
	end

    local goodNode = pCell.goodNode
    local homeData = self:GetHomeData()
    local superRewards = homeData.superRewards or {}
    goodNode:RefreshSelf(superRewards[index] or {})

	return pCell
end

---AddTimer_
---添加倒计时
---@param leftTime number 剩余时间
function SpActivityLuckNumberPageMediator:AddTimer_(leftTime)
    app.activityMgr:createCountdownTemplate(checkint(leftTime) + 2, NAME)
end
function SpActivityLuckNumberPageMediator:StopTimer_()
    app.activityMgr:stopCountdown(NAME)
end

-------------------------------------------------
-- UI Update method
--[[
刷新页面
--]]
function SpActivityLuckNumberPageMediator:RefreshView()
    local viewComponent = self:GetViewComponent()
    local viewData = self:GetViewData()

    --更新标题
    self:UpdateTitleNameLabel(viewData, self:GetTypeData().title[i18n.getLang()])

    --更新超级奖励
    local homeData = self:GetHomeData()
    self:UpdateTableView(viewData, homeData)

    --更新数字cell
    self:UpdateLuckNumCells(viewData, homeData)

    --更新礼包相关视图
    self:UpdateGiftInfoLayer(viewData, homeData)
end

---UpdateTableView
---@param viewData table 视图数据
---@param data table 幸运字符秒杀活动 首页数据
function SpActivityLuckNumberPageMediator:UpdateTableView(viewData, data)
    local tableView = viewData.tableView
    local superRewards = data.superRewards or {}
    tableView:setCountOfCell(#superRewards)
    tableView:reloadData()
end

---UpdateTitleNameLabel
---更新标题
---@param viewData table 视图数据
---@param title string
function SpActivityLuckNumberPageMediator:UpdateTitleNameLabel(viewData, title)
    local titleNameLabel = viewData.titleNameLabel
    display.commonLabelParams(titleNameLabel, {text = tostring(title)})
    if viewData.ruleBtn then
        viewData.ruleBtn:setVisible(true)
        viewData.ruleBtn:setPositionX(titleNameLabel:getPositionX() + display.getLabelContentSize(titleNameLabel).width + 20)
    end
end

---UpdateLuckNumCells
---更新数字cell
---@param viewData table 视图数据
---@param data table 幸运字符秒杀活动 首页数据
function SpActivityLuckNumberPageMediator:UpdateLuckNumCells(viewData, data)
    local luckNumCells = viewData.luckNumCells
    local showCollectGoodsId = data.showCollectGoodsId
    
    local countDown = checkint(data.countDown)
    local isShowCountdown = countDown > 0
    local numCountColor = isShowCountdown and '#987e7e' or '#ffffff'

    local t = {1, 3, 5, 7, 9}
    for i, goodsId in ipairs(showCollectGoodsId or {}) do
        local cell = luckNumCells[i]
        if cell then
            local ownNum = CommonUtils.GetCacheProductNum(goodsId)
            local cellViewData = cell.viewData
            
            local isOwn = ownNum > 0
            cellViewData.numBg:setTexture(isOwn and RES_DICT.ACTIVITY_LUCK_NUM_PIC or RES_DICT.ACTIVITY_LUCK_NUM_PIC_NO_GET)
            
            local goodsConf = CommonUtils.GetConfig("goods", "goods", goodsId) or {}
            display.commonLabelParams(cellViewData.numLabel, {text = goodsConf.name or tostring(t[i]), color = isOwn and "#b21415" or "#847272"})

            local numCount = cellViewData.numCount
            display.commonLabelParams(numCount, {text = ownNum, paddingW = 5, color = numCountColor})

        end
    end
end

---UpdateGiftInfoLayer
---更新礼包相关视图
---@param viewData table 视图数据
---@param data table 幸运字符秒杀活动 首页数据
function SpActivityLuckNumberPageMediator:UpdateGiftInfoLayer(viewData, data)
    local countDown = checkint(data.countDown)
    local isShowCountdown = countDown > 0
    viewData.startTimeBg:setVisible(isShowCountdown)
    viewData.giftInfoUnactiveBg:setVisible(isShowCountdown)

    viewData.totalStockBg:setVisible(not isShowCountdown)
    viewData.buyButton:setVisible(not isShowCountdown)
    viewData.buyTimesLabel:setVisible(not isShowCountdown)
    viewData.giftInfoActiveBg:setVisible(not isShowCountdown)
    viewData.spineFrame:setVisible(not isShowCountdown)

    if isShowCountdown then
        self:UpdateCountDown(viewData, data)
    else
        self:UpdateStock(viewData, data)
    end
end

---UpdateStock
---更新库存
---@param viewData table 视图数据
---@param data table 幸运字符秒杀活动 首页数据
function SpActivityLuckNumberPageMediator:UpdateStock(viewData, data)
    local richText = {}
    dump(data)
    for index, text in ipairs(self.totalStockText) do
        if '_cost_' == text then
            table.insert(richText, {fontSize = 22, color = '#ffd6c9', text = tostring(data.stock)})
        else
            table.insert(richText, {fontSize = 22, color = '#cf6144', text = text})
        end
    end
    display.reloadRichLabel(viewData.totalStockLabel, {width = 210 , c = richText})

    display.commonLabelParams(viewData.buyButton, {text = CommonUtils.GetCurrentAndOriginPriceDByPriceData(data)})

    local leftTimesTable = {}
    for i, text in ipairs(self.leftStockText) do
        if '_cost_' == text then
            table.insert(leftTimesTable, {fontSize = 22, color = '#ffd6c9', text = tostring(data.buyLimit)})
        else
            table.insert(leftTimesTable, {fontSize = 22, color = '#ffb594', text = text})
        end
    end
    display.reloadRichLabel(viewData.buyTimesLabel, {width =220 ,  c = leftTimesTable})
end

---UpdateCountDown
---@param viewData table 视图数据
---@param data table 幸运字符秒杀活动 首页数据
function SpActivityLuckNumberPageMediator:UpdateCountDown(viewData, data)
    local startLeftTimeLabel = viewData.startLeftTimeLabel
    display.commonLabelParams(startLeftTimeLabel, {text = CommonUtils.getTimeFormatByType(data.countDown)})
end

-------------------------------------------------
-- public method
function SpActivityLuckNumberPageMediator:InitHomeData(homeData)
    self.homeData_ = homeData
    self:RefreshView()
end

function SpActivityLuckNumberPageMediator:EnterLayer()
    self:SendSignal(POST.ACTIVITY_LUCKY_NUM_HOME.cmdName, {activityId = self:GetTypeData().activityId})
end

function SpActivityLuckNumberPageMediator:OnClickRuleBtnAction()
    local typeData  = self:GetTypeData()
    app.uiMgr:ShowIntroPopup({title = typeData.title[i18n.getLang()], descr = typeData.detail[i18n.getLang()]})
end

return SpActivityLuckNumberPageMediator
