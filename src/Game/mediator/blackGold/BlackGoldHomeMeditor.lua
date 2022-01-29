--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class BlackGoldHomeMeditor :Mediator
local BlackGoldHomeMeditor = class("BlackGoldHomeMeditor", Mediator)
local NAME = "BlackGoldHomeMeditor"
local BUTTON_TAG = {
    BACK_BTN         = 1003, -- 返回按钮
    INVESTMENT       = 1004, -- 投资营收
    PORT_TRADE       = 1005, -- 港口贸易
    THIS_GOODS       = 1006, -- 本期货物
    BUSINESS_EFFECT  = 1007, --商团声望
    UPGRADE_BUSINESS = 1008, --商团升级
    BLACK_GOLD_RULE  = 1009, --锦安商会规则
}
local RIGHT_LAYOUT_SHOW_EVENT = "RIGHT_LAYOUT_SHOW_EVENT"
---@type CommerceConfigParser
local CommerceConfigParser = require("Game.Datas.Parser.CommerceConfigParser")
function BlackGoldHomeMeditor:ctor( param ,  viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.homeData = app.blackGoldMgr:GetHomeData()

end

function BlackGoldHomeMeditor:InterestSignals()
    local signals = {
      POST.COMMERCE_TITLE_UPGRADE.sglName ,
      SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
      POST.COMMERCE_HOME.sglName,
      SIGNALNAMES.CACHE_MONEY_UPDATE_UI ,
      RIGHT_LAYOUT_SHOW_EVENT
    }
    return signals
end

function BlackGoldHomeMeditor:ProcessSignal( signal )
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.COMMERCE_TITLE_UPGRADE.sglName then
        local requestData = data.requestData
        local titleGrade = requestData.titleGrade
        app.blackGoldMgr:SetTitleGrade(titleGrade)
        local titleConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.TITLE , 'commerce')
        local upgradeTitleConf  = titleConf[tostring(titleGrade)]
        local consumeData = {}
        consumeData[#consumeData+1] = {
            goodsId = GOLD_ID , num = -upgradeTitleConf.gold
        }
        consumeData[#consumeData+1] = {
            goodsId = REPUTATION_ID , num = - upgradeTitleConf.reputation
        }
        for i, v in pairs(upgradeTitleConf.consume) do
            consumeData[#consumeData+1] = {  goodsId = i  , num = - v}
        end
        -- 扣除升级消耗的道具
        CommonUtils.DrawRewards(consumeData)
        -- 显示升级成功页面
        local view = require('Game.views.blackGold.BlackGoldUpgradeSuccessPopUp').new({ 
            callback = function()
                -- 更新等级显示
                self:UpdateBuissnessTitle()
                ---@type BlackGoldHomeScene
                local viewComponent = self:GetViewComponent()
                viewComponent:UpgradeLevelAction()
                viewComponent:CheckTradeUnlock()
            end
        })
        view:setPosition(display.center)
        app.uiMgr:GetCurrentScene():AddDialog(view)

    elseif name == POST.COMMERCE_HOME.sglName then
        self.homeData = app.blackGoldMgr:GetHomeData()
        ---@type BlackGoldHomeScene
        local viewComponent = self:GetViewComponent()
        viewComponent:UpdateBgImage()
        viewComponent:CreateAvatorSkinId()
        self:UpdateUI()
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT or name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI  then
        ---@type BlackGoldHomeScene
        local viewComponent = self:GetViewComponent()
        local moneyNods =viewComponent.viewData.purchaseNodes
        for i, goodPurchaseNode in pairs(moneyNods) do
            goodPurchaseNode:updataUi(checkint(i))
        end
    elseif name == RIGHT_LAYOUT_SHOW_EVENT then
        ---@type BlackGoldHomeScene
        local viewComponent = self:GetViewComponent()
        viewComponent:NameLayoutEnterAction()
        viewComponent:ModuleBtnEnterAction()
    end
end

function BlackGoldHomeMeditor:Initial( key )
    self.super:Initial(key)
    ---@type BlackGoldHomeScene
    local viewComponent = require("Game.views.blackGold.BlackGoldHomeScene").new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    app.uiMgr:SwitchToScene(viewComponent)
    local viewData =viewComponent.viewData
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    viewData.upgradeBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    viewData.theirBusiness:setOnClickScriptHandler(handler(self, self.ButtonAction))
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.ButtonAction))
    for i, v in pairs(viewData.moduleBtns) do
        v:setOnClickScriptHandler(handler(self, self.ButtonAction))
    end
    viewComponent:EnterAction()
    self:UpdateUI()
end

function BlackGoldHomeMeditor:UpdateUI()
    self:UpdateTime()
    self:UpdateBuissnessTitle()

    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateModuleBtnPos()
    viewComponent:UpdateFlagImage()
    viewComponent:UpdateBlackStatus()
    viewComponent:CheckTradeUnlock()
end
function BlackGoldHomeMeditor:UpdateBuissnessTitle()
    local titleGrade = app.blackGoldMgr:GetTitleGrade()
    local titleConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.TITLE , 'commerce')
    local count = table.nums(titleConf)
    ---@type BlackGoldHomeScene
    local viewComponent = self:GetViewComponent()
    if titleGrade >= count then
        viewComponent:UpdateBuissnessLevel("MAX")
        viewComponent:AddMaxLevelSpine()
    end
    viewComponent:UpdateBuissnessTitle(titleConf[tostring(titleGrade)].name)
end

----=======================----
--@author : xingweihao
--@date : 2019-08-19 17:59
--@Description ：更新贸易的剩余时间
--@params
--@return
---=======================----
function BlackGoldHomeMeditor:UpdateTime()
    ---@type BlackGoldHomeScene
    local viewComponent = self:GetViewComponent()
    viewComponent:runAction(
        cc.RepeatForever:create(
            cc.Sequence:create(
                cc.CallFunc:create(
                    function()
                        local leftSeconds = self.homeData.leftSeconds
                        local timeTable = string.formattedTime(leftSeconds)
                        timeTable.h = string.format("%03d" , checkint(timeTable.h))
                        timeTable.m = string.format("%02d" , checkint(timeTable.m))
                        timeTable.s = string.format("%02d" , checkint(timeTable.s))
                        local data = { "h", "m" ,"s" }
                        local times  = {}
                        for j = 1 , #data do
                            for i = 1, string.len(timeTable[tostring(data[j])]) do
                                times[#times+1] = string.byte(timeTable[tostring(data[j])] , i ) - 48
                            end
                        end
                        viewComponent:UpdateNum(times)
                    end
                ),
                cc.DelayTime:create(1)
            )
        )
    )
end

function BlackGoldHomeMeditor:ButtonAction(sender)
    local tag = sender:getTag()
    if tag ==  BUTTON_TAG.BACK_BTN  then
        local viewComponent = self:GetViewComponent()
        viewComponent:stopAllActions()
        AppFacade.GetInstance():BackHomeMediator()
    elseif tag ==  BUTTON_TAG.INVESTMENT  then
        self:HideRightLayout()
        local mediator = require("Game.mediator.blackGold.BlackGoldInvestMentMediator").new()
        app:RegistMediator(mediator)
    elseif tag ==  BUTTON_TAG.PORT_TRADE  then
        local grade = app.blackGoldMgr:GetTitleGrade()
        local titleConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.TITLE , 'commerce')
        local unlock = (checkint(titleConf[tostring(grade)].unlockMarket) > 0 and true ) or false
        if not unlock then
            app.uiMgr:ShowInformationTips(__('贸易暂未解锁'))
            return
        end
        self:HideRightLayout()
        local mediator = require("Game.mediator.blackGold.BlackGoldTradeMediator").new()
        app:RegistMediator(mediator)
    elseif tag ==  BUTTON_TAG.THIS_GOODS  then
        self:HideRightLayout()
        local mediator = require("Game.mediator.blackGold.BlackGoldThisGoodsMediator").new()
        app:RegistMediator(mediator)
    elseif tag ==  BUTTON_TAG.BUSINESS_EFFECT  then
        ---@type BlackGoldHomeScene
        local viewComponent = self:GetViewComponent()

        viewComponent:CreateBusinessEffectView(sender ,checkint(self.homeData.titleGrade) )

    elseif tag ==  BUTTON_TAG.BLACK_GOLD_RULE  then
        app.uiMgr:ShowIntroPopup({moduleId =90  })
    elseif tag ==  BUTTON_TAG.UPGRADE_BUSINESS  then
        local titleGrade = checkint(self.homeData.titleGrade)
        local titleConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.TITLE , 'commerce')
        local count = table.nums(titleConf)
        if titleGrade == count  then
            app.uiMgr:ShowInformationTips(__('已达到商团最高称号'))
            return
        end
        ---@type BlackGoldUpgradeView
        local view = require('Game.views.blackGold.BlackGoldUpgradeView').new()
        view:setPosition(display.center)
        app.uiMgr:GetCurrentScene():AddDialog(view)
        view:setName("Game.views.blackGold.BlackGoldUpgradeView")
        view:UpdateViewByLevel(self.homeData.titleGrade)

    end
end
function BlackGoldHomeMeditor:HideRightLayout()
    ---@type BlackGoldHomeScene
    local viewComponent = self:GetViewComponent()
    viewComponent:ModuleBtnOutAction()
    viewComponent:NameLayoutEnterOut()
end
function BlackGoldHomeMeditor:EnterLayer()
end
function BlackGoldHomeMeditor:RemovePopLayer()
    local dialogNode = sceneWorld:getChildByTag(GameSceneTag.Dialog_GameSceneTag)
    local popLayerTable = {
        "Game.views.blackGold.BlackGoldUpgradeView" ,
        "Game.views.blackGold.BlackGoldUpgradeBackpackView"
    }
    for index, nodeName in pairs(popLayerTable) do
        local popLayer = dialogNode:getChildByName(nodeName)
        if popLayer then
            popLayer:OnUnRegist()
        end
    end
end
function BlackGoldHomeMeditor:OnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    regPost(POST.COMMERCE_WARE_HOUSE_EXTEND)
    regPost(POST.COMMERCE_TITLE_UPGRADE)
    self:EnterLayer()
end
function BlackGoldHomeMeditor:OnUnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
    app.blackGoldMgr:RemoveSpineCache()
    self:RemovePopLayer()
    unregPost(POST.COMMERCE_TITLE_UPGRADE)
    unregPost(POST.COMMERCE_WARE_HOUSE_EXTEND)
end

return BlackGoldHomeMeditor
