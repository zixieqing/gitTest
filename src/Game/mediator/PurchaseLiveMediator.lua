---
--- Created by xingweihao.
--- DateTime: 16/08/2017 6:10 PM
---

--[[
排行榜Mediator
--]]
---@type Mediator 
local Mediator = mvc.Mediator
---@class PurchaseLiveMediator : Mediator
local PurchaseLiveMediator = class("PurchaseLiveMediator", Mediator)

local NAME = "PurchaseLiveMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local BUTTON_TAG = {
    CANCEL_BTN  = 1 ,
    PURCHASELIVE_BTN  = 2 ,
    CLOSE_BTN = 3 ,
}
function PurchaseLiveMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.data = param or {}
    self.data.currentTime = 1
    self.data.residueTime = 2
    self.purchaseLiveData = CommonUtils.GetConfigAllMess('towerBuyLiveConsume', "tower") -- 购买次数
end

function PurchaseLiveMediator:InterestSignals()
    local signals = {
        --SIGNALNAMES.Rank_Restaurant_Callback
        POST.TOWER_QUEST_BUY_LIVE.sglName
    }
    return signals
end

function PurchaseLiveMediator:ProcessSignal( signal )
    local name = signal:GetName()
    if name == POST.TOWER_QUEST_BUY_LIVE.sglName then

    end

end

function PurchaseLiveMediator:Initial( key )
    self.super.Initial(self,key)
    local scene = uiMgr:GetCurrentScene()
    ---@type PurchaseLiveView
    local viewComponent  = require( 'Game.views.PurchaseLiveView' ).new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    scene:AddDialog(viewComponent)
    viewComponent.viewData.makeSureBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    viewComponent.viewData.btnCancel:setOnClickScriptHandler(handler(self, self.ButtonAction))
    viewComponent.viewData.swallowLayer:setOnClickScriptHandler(handler(self, self.ButtonAction))
    viewComponent:UpdateView(self.data)
end
--[[
    事件响应
--]]
function PurchaseLiveMediator:ButtonAction(sender)
    local  tag = sender:getTag()
    if tag ~= BUTTON_TAG.PURCHASELIVE_BTN then -- 关闭界面相应
        ---@type Facade
        local facade = self:GetFacade() 
        facade:UnRegsitMediator("PurchaseLiveMediator")
    elseif tag == BUTTON_TAG.PURCHASELIVE_BTN then -- 购买按钮
        if self.data.residueTime  <= 0 then
            uiMgr:ShowInformationTips(__('购买次数已经用完'))
        else
            local data = self.purchaseLiveData[tostring(self.data.currentTime)]
            if self.data.currentTime  and data then
                if CommonUtils.GetCacheProductNum(data.consume ) >=  checkint(data.consumeNum) then
                    --- 发送信号
                    self:SendSignal(POST.TOWER_QUEST_BUY_LIVE.cmdName, {buyLiveNum  = self.data.currentTime})
                else
                    if GAME_MODULE_OPEN.NEW_STORE then
                        app.uiMgr:showDiamonTips()
                    else
                        local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('幻晶石不足是否去商城购买？'),
                            isOnlyOK = false, callback = function ()
                                app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})  
                            end})
                        CommonTip:setPosition(display.center)
                        app.uiMgr:GetCurrentScene():AddDialog(CommonTip)
                    end
                end
            end
        end
    end
end

function PurchaseLiveMediator:EnterLayer()
    --self:SendSignal(COMMANDS.COMMAND_Rank_Restaurant)
end
function PurchaseLiveMediator:OnRegist(  )
    regPost(POST.TOWER_QUEST_BUY_LIVE)
end

function PurchaseLiveMediator:OnUnRegist(  )
    unregPost(POST.TOWER_QUEST_BUY_LIVE)
    local scene = uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
end
return PurchaseLiveMediator