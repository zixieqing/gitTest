---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2018/10/15 2:07 PM
---
--[[
扭蛋系统mediator
--]]
local Mediator                      = mvc.Mediator
---@class AnniversaryBlackMarketMediator :Mediator
local AnniversaryBlackMarketMediator = class("AnniversaryBlackMarketMediator", Mediator)
local NAME                          = "AnniversaryBlackMarketMediator"
local BUTTON_TAG                    = {
    CLOSE_VIEW = 11001 ,
    TIP_BUTTON = 11002 ,
}
local anniversaryManager = app.anniversaryMgr
--==============================--
---@Description: TODO
---@author : xingweihao
---@date : 2018/10/13 10:22 AM
--==============================--

function AnniversaryBlackMarketMediator:ctor(param, viewComponent)
    self.super:ctor(NAME, viewComponent) 
end

function AnniversaryBlackMarketMediator:InterestSignals()
    local signals = {
        POST.ANNIVERSARY_BLACK_HEART_SHOP.sglName,
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI
    }
    return signals
end

function AnniversaryBlackMarketMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.ANNIVERSARY_BLACK_HEART_SHOP.sglName  then
        local requestData = data.requestData
        local shopId =  requestData.shopId
        local parserConfig = anniversaryManager:GetConfigParse()
        local blackMarketConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.BLACK_MARKET)
        local blackMarketData = blackMarketConfig[tostring(shopId)] or {}
        local consumeData = clone(blackMarketData.consume)  or {}
        local rewards = data.rewards
        for index , goodsData  in pairs(consumeData) do
            goodsData.num = - checkint(goodsData.num)
        end
        app.uiMgr:AddDialog('common.RewardPopup',{ rewards = rewards })
        CommonUtils.DrawRewards(consumeData)
        local homeData = anniversaryManager.homeData
        local chapterQuest = homeData.chapterQuest
        if  not chapterQuest then
            homeData.chapterQuest = {}
        end
        if not  homeData.chapterQuest.gridShop then
            homeData.chapterQuest.gridShop = {}
        end
        homeData.chapterQuest.gridShop.isPurchase = 1
        app:UnRegsitMediator(NAME)
    elseif name ==  SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
        if self.viewComponent then
            self.viewComponent:UpdateCountUI()
        end

    end
end

function AnniversaryBlackMarketMediator:Initial(key)
    self.super.Initial(self, key)
    ---@type AnniversaryBlackMarketStoreView
    local viewComponent = require('Game.views.anniversary.AnniversaryBlackMarketStoreView').new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    local viewData = viewComponent.viewData
    viewData.backBtn:setTag(BUTTON_TAG.CLOSE_VIEW)
    local viewData = viewComponent.viewData
    viewData.tabNameLabel:setTag(BUTTON_TAG.TIP_BUTTON )
    display.commonUIParams(viewData.backBtn , {cb = handler(self, self.ButtonAction)})
    display.commonUIParams(viewData.tabNameLabel , {cb = handler(self, self.ButtonAction)})
    self:UpdateUI()
end
function AnniversaryBlackMarketMediator:UpdateUI()
    ---@type AnniversaryBlackMarketStoreView
    local viewComponent = self:GetViewComponent()
    local homeData = anniversaryManager.homeData
    local info =homeData.chapterQuest.gridShop.info  or {}
    local viewData = viewComponent.viewData
    local buyLayouts = viewData.buyLayouts
    local parserConfig = anniversaryManager:GetConfigParse()
    local blackMarketConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.BLACK_MARKET)
    if #info == 0  then
        app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('商品已经售罄')))
    end
    for i = 1 ,  3 do
        local buyLayout = buyLayouts[i]
        local goodNode = buyLayout:getChildByName("goodNode")
        buyLayout:setVisible(false)
        if i > #info then
            buyLayout:setVisible(false)
        else
            buyLayout:setVisible(true)
            local rewardData = blackMarketConfig[tostring(info[i])].rewards[1]
            goodNode:RefreshSelf(rewardData)
            goodNode:setTag(checkint(rewardData.goodsId))
            display.commonUIParams(goodNode , {cb  = function(sender)
                                               app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
            end})
            local bgImage = buyLayout:getChildByName("bgImage")
            bgImage:setTag(i)
            display.commonUIParams(bgImage , {cb = function(sender)
                local index = sender:getTag()
                local consumeData = blackMarketConfig[tostring(info[index])].consume[1]
                local goodsId = consumeData.goodsId
                local ownerNum = CommonUtils.GetCacheProductNum(goodsId)
                local goodData = CommonUtils.GetConfig('goods','goods' , goodsId) or {}
                local name = goodData.name or ""
                if ownerNum < checkint(consumeData.num)   then
                    if GAME_MODULE_OPEN.NEW_STORE and checkint(goodsId) == DIAMOND_ID then
                        app.uiMgr:showDiamonTips()
                    else
                        app.uiMgr:ShowInformationTips(string.format(app.anniversaryMgr:GetPoText(__('%s不足')) ,name ) )
                    end
                    return
                end
                app.uiMgr:AddCommonTipDialog({
                    descr = string.format(app.anniversaryMgr:GetPoText(__('要消耗%d%s购买商品么')) , consumeData.num , name) ,
                    callback = function()
                        self:SendSignal(POST.ANNIVERSARY_BLACK_HEART_SHOP.cmdName, { shopId = info[sender:getTag()] })
                end})
            end})
            local amoutRichLabel = buyLayout:getChildByName("amoutRichLabel")
            local consumeData = blackMarketConfig[tostring(info[i])].consume[1]
            display.reloadRichLabel(amoutRichLabel , { c= {
                fontWithColor('14' , {text = consumeData.num }) ,
                {img =CommonUtils.GetGoodsIconPathById( consumeData.goodsId ), scale = 0.2  }
            }})
        end
    end
    local posXtable = {
        {  550},
        { 400,  700 },
        { 250, 550, 850 },
    }
    for i = 1,  #info do
        local buyLayout = buyLayouts[i]
        buyLayout:setPositionX(posXtable[ #info][i])
    end

end

function AnniversaryBlackMarketMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if tag == BUTTON_TAG.CLOSE_VIEW then
        app:UnRegsitMediator(NAME)
    elseif tag == BUTTON_TAG.TIP_BUTTON then
        app.uiMgr:ShowIntroPopup({moduleId = -16  })
    end
end
function AnniversaryBlackMarketMediator:OnRegist()
    regPost(POST.ANNIVERSARY_BLACK_HEART_SHOP)
end
function AnniversaryBlackMarketMediator:OnUnRegist()
    unregPost(POST.ANNIVERSARY_BLACK_HEART_SHOP)
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return AnniversaryBlackMarketMediator