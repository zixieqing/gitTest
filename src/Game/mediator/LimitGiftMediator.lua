---
--- Created by xingweihao.
--- DateTime: 30/10/2017 11:24 AM
---
local Mediator = mvc.Mediator
---@class LimitGiftMediator :Mediator
local LimitGiftMediator = class("LimitGiftMediator", Mediator)
local NAME = "LimitGiftMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')

function LimitGiftMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    local data  = param or {}
    self.datas = data

end

function LimitGiftMediator:InterestSignals()
    local signals = {
        COUNT_DOWN_ACTION ,
        SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback,
        --POST.ACTIVITY_DRAW_FIRSTPAY.sglName ,
        EVENT_PAY_MONEY_SUCCESS_UI,
    }
    return signals
end
function LimitGiftMediator:Initial( key )
    self.super.Initial(self,key)
    self.isLoadView = false
    local str = string.format("Game/views/limitGift/LimitGiftChestView%s.lua" ,  tostring(checkint(self.datas.uiTplId) ))
    local fileUtils = cc.FileUtils:getInstance()
    local isFileExist =  fileUtils:isFileExist(str)
    if  isFileExist then
        str =string.format("Game.views.limitGift.LimitGiftChestView%s" ,  tostring(self.datas.uiTplId))
    else
        str = "Game.views.limitGift.LimitGiftChestView1"
    end
    self.viewComponent = require(str).new()
    self:SetViewComponent(self.viewComponent)
    self.viewComponent:setPosition(cc.p(display.cx , display.cy ))
    self.viewComponent:setAnchorPoint(display.CENTER)
    uiMgr:GetCurrentScene():AddDialog(self.viewComponent)
    local viewData_ = self.viewComponent.viewData_
    viewData_.closeLayer:setOnClickScriptHandler(function (sender)
        if not  self.viewComponent.isAction then
            PlayAudioByClickClose()
            self.viewComponent:CloseAction()
        end
    end)
    self:UpdateView()
    self.viewComponent:needGoods(self.datas.rewards)
    self.viewComponent:ExpandAction()
    -- 购买的按钮
    viewData_.buyButton:setOnClickScriptHandler(handler(self , self.ButtonAction))
    self.isLoadView = true
end
-- 更新界面的信息
function LimitGiftMediator:UpdateView()

    local viewData_ = self.viewComponent.viewData_

    if CommonUtils.IsGoldSymbolToSystem() then
        CommonUtils.SetCardNameLabelStringByIdUseSysFont(viewData_.buyButton:getLabel() , nil,{fontSizeN = 24 , colorN = "ffffff" , outline = '#734441'} , string.format(__("￥ %s" ) , tostring(self.datas.discountPrice)))
        --CommonUtils.SetCardNameLabelStringByIdUseSysFont(viewData_.priceLbale , nil,{fontSizeN = 24 , colorN = "ffffff" , outline = '#734441'} ,string.format(__("原价￥%s" ) , tostring(self.datas.price) ) )
    else
        display.commonLabelParams(viewData_.buyButton , fontWithColor('14' , {fontSize = 30 ,text = string.format(__("￥ %s" ) , tostring(self.datas.discountPrice))}))
        --display.commonLabelParams(viewData_.priceLbale ,  { text = string.format(__("原价￥%s" ) , tostring(self.datas.price) ), reqW = 220})
    end

    display.reloadRichLabel(viewData_.discountNumLabel , { c=  {
            fontWithColor('14', { fontSize = 60 , color = '#ff8124' ,text = tostring(self.datas.discount)     .. "%" } )
        }
    })
    display.commonLabelParams(viewData_.timeButton , fontWithColor('14' , { fontSize = 36, otline = "52311d" , outlineSize =1 ,text = self.datas.countdown}))
    CommonUtils.AddRichLabelTraceEffect(viewData_.discountLabel,"#5311d",1)
end
function LimitGiftMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name ==  COUNT_DOWN_ACTION  then
        -- 防止页面未加载就直接刷新页面
        if self.isLoadView then
            local viewData_ = self.viewComponent.viewData_
            if RemindTag.Limite_Time_GIFT_BG == data.tag then
                local eventOneName =  string.format("Limit_Gift_%d_%d_%d" ,  checkint(self.datas.productId) ,  checkint(self.datas.iconId) , checkint(self.datas.uiTplId))
                local eventTwoName =  string.format("Limit_Gift_%d_%d_%d" ,  checkint(self.datas.productId) ,  checkint(self.datas.iconId) , checkint(self.datas.uiTplId))
                if eventOneName == eventTwoName then
                    display.commonLabelParams(viewData_.timeButton, { text  =  string.formattedTime(checkint(data.countdown) , "%02i:%02i:%02i")})
                    if checkint(data.countdown) == 0 then
                        viewData_.buyButton:setOnClickScriptHandler(function (sender)
                            uiMgr:ShowInformationTips(__('该限时礼包已经过期'))
                        end)
                    end
                end
            end
        end
    elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
        if checkint(data.type) == PAY_TYPE.PT_TIME_LIMIT_GIFT then
            -- 首充奖励

            local viewData_ = self.viewComponent.viewData_
            display.commonLabelParams(viewData_.buyButton , { text =__('已购买')})
            viewData_.buyButton:setOnClickScriptHandler(function (sender)
                uiMgr:ShowInformationTips(__('已经购买成功该礼包'))
            end)
        end
    --elseif  name == POST.ACTIVITY_DRAW_FIRSTPAY.sglName then
    --    if gameMgr:GetUserInfo().firstPay == 1 then
    --        gameMgr:GetUserInfo().firstPay = 3
    --        uiMgr:AddDialog('common.RewardPopup', {rewards = data.rewards, msg = __('恭喜获得首充奖励')})
    --    end
    elseif name == SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback then
        if signal:GetBody().requestData.name ~= 'LimitChest' then return end
        if data.orderNo then
            if device.platform == 'android' or device.platform == 'ios' then
                local AppSDK = require('root.AppSDK')
                local price =  checkint( self.datas.discountPrice)
                AppSDK.GetInstance():InvokePay({amount =  price  , property = data.orderNo, goodsId = tostring(self.datas.channelProductId), goodsName = __('幻晶石'), quantifier = __('个'),price = 0.1, count = 1})
            end
        end
    end
end

function LimitGiftMediator:ButtonAction(sender)
    PlayAudioByClickNormal()
    self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = self.datas.productId , name = 'LimitChest'})
end
function LimitGiftMediator:OnRegist()
    --regPost(POST.ACTIVITY_DRAW_FIRSTPAY)
    
    
end

function LimitGiftMediator:OnUnRegist()
    --unregPost(POST.ACTIVITY_DRAW_FIRSTPAY)
    
    if self.viewComponent and (not tolua.isnull(self.viewComponent)) then -- 防止程序执行过快 删除两次
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return LimitGiftMediator



