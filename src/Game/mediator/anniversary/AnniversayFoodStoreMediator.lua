---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2018/10/15 2:07 PM
---
--[[
扭蛋系统mediator
--]]
local Mediator                      = mvc.Mediator
---@class AnniversayFoodStoreMediator :Mediator
local AnniversayFoodStoreMediator = class("AnniversayFoodStoreMediator", Mediator)
local NAME                          = "AnniversayFoodStoreMediator"
local BUTTON_TAG                    = {
    CLOSE_VIEW = 11001 ,
    TIP_BUTTON = 11002 ,
}
local anniversaryManager = app.anniversaryMgr
--==============================--
---@Description: 
---@author : xingweihao
---@date : 2018/10/13 10:22 AM
--==============================--

function AnniversayFoodStoreMediator:ctor(param, viewComponent)
    self.super:ctor(NAME, viewComponent)
end

function AnniversayFoodStoreMediator:InterestSignals()
    local signals = {
        POST.ANNIVERSARY_BLACK_HEART_RECIPE_SHOP.sglName,
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI
    }
    return signals
end

function AnniversayFoodStoreMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.ANNIVERSARY_BLACK_HEART_RECIPE_SHOP.sglName  then
        local requestData = data.requestData
        local shopId =  requestData.shopId
        local parserConfig = anniversaryManager:GetConfigParse()
        local blackRecipeMarketConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.BLACK_RECIPE_MARKET)
        local blackRecipeMarketData = blackRecipeMarketConfig[tostring(shopId)] or {}
        local consumeData = clone(blackRecipeMarketData.consume)  or {}
        for index , goodsData  in pairs(consumeData) do
            goodsData.num = - checkint(goodsData.num)
        end
        CommonUtils.DrawRewards(consumeData)
        local recipes = anniversaryManager.homeData.recipes or {}
        local expValue  = checkint(recipes[tostring(blackRecipeMarketData.foodId)])
        local addExpValue = checkint(blackRecipeMarketData.exp)
        anniversaryManager:SetRecipeIdAndExp(blackRecipeMarketData.foodId , addExpValue + expValue )
        local view = require("Game.views.anniversary.AnniversaryUpgradeRecipeView").new({shopId = shopId })
        app.uiMgr:GetCurrentScene():AddDialog(view)
        view:setPosition(display.center)
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

function AnniversayFoodStoreMediator:Initial(key)
    self.super.Initial(self, key)
    ---@type AnniversaryFoodStoreView
    local viewComponent = require('Game.views.anniversary.AnniversaryFoodStoreView').new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    local viewData = viewComponent.viewData
    viewData.backBtn:setTag(BUTTON_TAG.CLOSE_VIEW)
    viewData.tabNameLabel:setTag(BUTTON_TAG.TIP_BUTTON )
    display.commonUIParams(viewData.tabNameLabel , {cb = handler(self, self.ButtonAction)})
    display.commonUIParams(viewData.backBtn , {cb = handler(self, self.ButtonAction)})
    self:UpdateUI()
end
function AnniversayFoodStoreMediator:UpdateUI()
    ---@type AnniversaryBlackMarketStoreView
    local viewComponent = self:GetViewComponent()
    local homeData = anniversaryManager.homeData
    local info =homeData.chapterQuest.gridShop.info  or {}
    local viewData = viewComponent.viewData
    local buyLayouts = viewData.buyLayouts
    local parserConfig = anniversaryManager:GetConfigParse()
    local blackRecipeMarketConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.BLACK_RECIPE_MARKET)
    if #info == 0  then
        app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('商品已经售罄')))
    end
    for i = 1 , 3 do
        local buyLayout = buyLayouts[i]
        local bgImage = buyLayout:getChildByName("shopImage")
        bgImage:setTag(i)
        buyLayout:setVisible(false)
        if i > #info then
            buyLayout:setVisible(false)
        else
            local  blackRecipeMarketData = blackRecipeMarketConfig[tostring(info[i])]
            local photoId = blackRecipeMarketData.foodId
            buyLayout:setVisible(true)
            display.commonUIParams(bgImage , {cb = function(sender)
                app.uiMgr:AddDialog('Game.views.anniversary.AnniversaryBuySecrentView' , {shopId =info[sender:getTag()] })
            end})
            local recipeImage = buyLayout:getChildByName("recipeImage")
            print(anniversaryManager:GetAnniversaryRecipePathByRecipId(photoId))
            recipeImage:setTexture(anniversaryManager:GetAnniversaryRecipePathByRecipId(photoId))
            local recipeName = buyLayout:getChildByName("recipeName")
            display.commonLabelParams(recipeName , {text =blackRecipeMarketData.name } )
            local expValueLabel = buyLayout:getChildByName("expValueLabel")
            display.commonLabelParams(expValueLabel , {text = string.format(app.anniversaryMgr:GetPoText(__('熟练度 + %d ')) , checkint(blackRecipeMarketData.exp))  } )
            local amoutRichLabel = buyLayout:getChildByName("amoutRichLabel")
            local consumeData =blackRecipeMarketData.consume[1]
            display.reloadRichLabel(amoutRichLabel , { c= {
                fontWithColor('14' , {text = consumeData.num }) ,
                {img =CommonUtils.GetGoodsIconPathById( consumeData.goodsId ), scale = 0.2  }
            }})
        end
    end
    local posXtable = {
        {  550},
        { 400,  700  },
        { 250, 550, 850 },
    }
    for i = 1,  #info do
        local buyLayout = buyLayouts[i]
        buyLayout:setPositionX(posXtable[ #info][i])
    end
end

function AnniversayFoodStoreMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if tag == BUTTON_TAG.CLOSE_VIEW then
        app:UnRegsitMediator(NAME)
    elseif tag == BUTTON_TAG.TIP_BUTTON then
        app.uiMgr:ShowIntroPopup({moduleId = -17  })
    end
end
function AnniversayFoodStoreMediator:OnRegist()
    regPost(POST.ANNIVERSARY_BLACK_HEART_RECIPE_SHOP)
end
function AnniversayFoodStoreMediator:OnUnRegist()
    unregPost(POST.ANNIVERSARY_BLACK_HEART_RECIPE_SHOP)
    app.timerMgr:RemoveTimer(PUT_AWAY_TIME_EVENT)
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return AnniversayFoodStoreMediator
