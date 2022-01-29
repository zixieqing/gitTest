--[[
 * author : liuzhipeng
 * descpt : 活动 新手福利 礼包Mediator
--]]
local NoviceWelfareGiftMediator = class('NoviceWelfareGiftMediator', mvc.Mediator)
local NAME = 'activity.noviceWelfare.NoviceWelfareGiftMediator'
function NoviceWelfareGiftMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
end
-------------------------------------------------
------------------ inheritance ------------------
function NoviceWelfareGiftMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.activity.noviceWelfare.NoviceWelfareGiftView').new()
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData
end
    
function NoviceWelfareGiftMediator:InterestSignals()
    local signals = {
        SGL.Restaurant_Shop_GetPayOrder_Callback,
        EVENT_PAY_MONEY_SUCCESS_UI,
    }
    return signals
end
function NoviceWelfareGiftMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == SGL.Restaurant_Shop_GetPayOrder_Callback then
        if data.requestData.name ~= 'welfareGift' then return end
        if data.orderNo then
            local index    = checkint(data.requestData.index)
            local homeData = self:GetHomeData()
            local giftData = homeData.chests[index]
            local isDiscount = checkint(index) == checkint(homeData.today)
            local amount = nil
            local channelProductId = nil
            if isDiscount then
                amount = giftData.discountPrice
                channelProductId = giftData.discountChannelProductId
            else
                amount = giftData.originalPrice
                channelProductId = giftData.originalChannelProductId
            end

            if device.platform == 'android' or device.platform == 'ios' then
                if DEBUG > 0 and checkint(Platform.id) <= 1002 then
                    --mac机器上点击直接成功的逻辑
                    app:DispatchObservers(EVENT_PAY_MONEY_SUCCESS, {type = PAY_TYPE.NOVICE_WELFARE_GIFT, rewards = {{goodsId = GOLD_ID, num = 10}} })
                else
                    require('root.AppSDK').GetInstance():InvokePay({
                        property   = data.orderNo,
                        amount     = checkint(amount),
                        goodsId    = tostring(channelProductId),
                        goodsName  = __('幻晶石'),
                        quantifier = __('个'),
                        price      = 0.1,
                        count      = 1
                    })
                end
			else
                --mac机器上点击直接成功的逻辑
                app:DispatchObservers(EVENT_PAY_MONEY_SUCCESS, {type = PAY_TYPE.NOVICE_WELFARE_GIFT, rewards = {{goodsId = GOLD_ID, num = 10}} })
            end
        else
            app.uiMgr:ShowInformationTips('pay/order callback orderNo is null !!')
        end
    elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
        if checkint(data.type) == PAY_TYPE.ASSEMBLY_ACTIVITY_GIFT then
        end
    end
end

function NoviceWelfareGiftMediator:OnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, 'allhide')
end
function NoviceWelfareGiftMediator:OnUnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, 'rightShow')
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')
    -- 移除界面
    if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then
        self:GetViewComponent():removeFromParent()
        self:SetViewComponent(nil)
    end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
礼包点击回调
--]]
function NoviceWelfareGiftMediator:GiftNodeCallback( sender )
    local tag = sender:getTag()
    local homeData = self:GetHomeData()
    if checkint(homeData.chests[tag].hasPurchased) == 1 then return end
    PlayAudioByClickNormal()
    local params = {
        giftData = homeData.chests[tag],
        isDiscount = tag == homeData.today, 
        index = tag
    }
    app.uiMgr:AddDialog("Game.views.activity.noviceWelfare.NoviceWelfareGiftPopup", params)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
刷新礼包
--]]
function NoviceWelfareGiftMediator:RefreshGifts()
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    homeData.callback = handler(self, self.GiftNodeCallback)
    viewComponent:RefreshGiftNodes(homeData)
end
--[[
更新剩余时间
--]]
function NoviceWelfareGiftMediator:UpdateLeftSeconds( leftSeconds )
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    if homeData.today <= 7 then
        viewComponent:RefreshGiftNodeTimeLabel(homeData.today, leftSeconds)
    end
    if homeData.today + 1 <= 7 then
        viewComponent:RefreshGiftNodeTimeLabel(homeData.today + 1, leftSeconds)
    end
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- public ---------------------
--[[
刷新页面
@params map {
    tasks              list    任务数据
    isLimit            int     是否为限时任务
    currentActivePoint int     当前活动点数
    today              int     当前日期
    activePoint        map     活跃奖励
}
--]]
function NoviceWelfareGiftMediator:RefreshView( params )
    local viewComponent = self:GetViewComponent()
    self:SetHomeData(params)
    self:RefreshGifts()
end
--[[
隐藏页面
--]]
function NoviceWelfareGiftMediator:HideView( )
    self:GetViewComponent():setVisible(false)
end
--[[
显示页面
--]]
function NoviceWelfareGiftMediator:ShowView( )
    self:GetViewComponent():setVisible(true)
end
-------------------- public ---------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function NoviceWelfareGiftMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function NoviceWelfareGiftMediator:GetHomeData()
    return self.homeData
end
------------------- get / set -------------------
-------------------------------------------------
return NoviceWelfareGiftMediator