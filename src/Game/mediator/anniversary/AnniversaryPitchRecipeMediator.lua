---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2018/10/15 2:07 PM
---
--[[
扭蛋系统mediator
--]]
local Mediator                      = mvc.Mediator
---@class AnniversaryPitchRecipeMediator :Mediator
local AnniversaryPitchRecipeMediator = class("AnniversaryPitchRecipeMediator", Mediator)
local NAME                          = "AnniversaryPitchRecipeMediator"
local BUTTON_TAG                    = {
    RECOMMEMD_BTN   = 10011, -- 今日推荐按钮
    SALE_RECORD_BTN = 10012, -- 售卖记录
    CHANGE_CARD     = 10013, -- 更换卡牌
    ADD_FOOD_BTN    = 10014, --上菜
    CLOSE_TAG       = 10015, -- 关闭界面
    TIP_BUTTON      = 10016,   -- tip 的提示按钮
    MAKE_SURE_EXIT  = 10017   -- 确认退出
}
local anniversaryManager = app.anniversaryMgr
local  PUT_AWAY_TIME_EVENT  =  "PUT_AWAY_TIME_EVENT"
--==============================--
---@Description: TODO
---@author : xingweihao
---@date : 2018/10/13 10:22 AM
--==============================--

function AnniversaryPitchRecipeMediator:ctor(param, viewComponent)
    self.super:ctor(NAME, viewComponent)
    self.isApply = false  -- 是否在报名阶段
    self.chooseCardId = 0 -- 选择卡牌的界面
    self.recipeId = 0  -- 当前选择的菜谱
    self.priceValue = 0 -- 当前的价格
    self.isChange = false  -- 是否改变
    self.currentTime = 0  -- 当前的时间
end

function AnniversaryPitchRecipeMediator:InterestSignals()
    local signals = {
        POST.ANNIVERSARY_GET_SHOP_CONFIG.sglName,
        POST.ANNIVERSARY_SET_SHOP_CONFIG.sglName,
        POST.ANNIVERSARY_GET_SHOP_LOG.sglName,
        POST.ANNIVERSARY_GET_RECIPE_ATTR.sglName,
        ANNIVERSARY_CHOOSE_RECIPE_EVENT ,
        ANNIVERSARY_CHOOSE_CARD_EVENT 
    }
    return signals
end

function AnniversaryPitchRecipeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if  name ==  POST.ANNIVERSARY_GET_SHOP_CONFIG.sglName  then
        self.recipeId = checkint(data.recipeId)
        self.chooseCardId = checkint(data.cardId)
        self.priceValue = checkint(data.recipePrice)
        self.currentTime = checkint(data.currentTime)
        anniversaryManager.homeData.priceValue = self.priceValue
        local parserConfig = anniversaryManager:GetConfigParse()
        local paramConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.PARAMETER)["1"]
        local endTime = anniversaryManager:GetTimeSeverTime(paramConfig.prepareEnd)
        data.applyLeftSeconds = endTime -  self.currentTime
        if data.applyLeftSeconds > 0  then
            self.isApply = true
            self.applyLeftSeconds =  data.applyLeftSeconds
            app.timerMgr:AddTimer(  {name =  PUT_AWAY_TIME_EVENT, countdown = data.applyLeftSeconds } )
        else
            self.applyLeftSeconds = data.applyLeftSeconds
        end
        self:UpdateUI()
        self:ShowBusinessTips()
    elseif name == ANNIVERSARY_CHOOSE_RECIPE_EVENT  then
        self.priceValue = data.priceValue or 1
        self.recipeId = data.recipeId

        if checkint(self.chooseCardId) > 0   then
            --local cardData = app.gameMgr:GetCardDataByCardId(self.chooseCardId)
            --self:SendSignal(POST.ANNIVERSARY_SET_SHOP_CONFIG.cmdName ,{
            --    playerCardId  = cardData.id   , recipeId = self.recipeId , recipePrice = self.priceValue
            --})
        else
            app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('请添加飨灵')))
        end
        self:UpdateUI()
    elseif name == ANNIVERSARY_CHOOSE_CARD_EVENT  then
        if checkint(self.recipeId) > 0   then
            self.chooseCardId = data.cardId
            --local cardData = app.gameMgr:GetCardDataByCardId(self.chooseCardId)
            --self:SendSignal(POST.ANNIVERSARY_SET_SHOP_CONFIG.cmdName ,{
            --    playerCardId = cardData.id   , recipeId = self.recipeId , recipePrice = self.priceValue
            --})
        else
            self.chooseCardId = data.cardId
            app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('请不要忘记添加料理哦')))
        end
        self:UpdateUI()
    elseif name == POST.ANNIVERSARY_SET_SHOP_CONFIG.sglName then
        local requestData = data.requestData
        if checkint(self.chooseCardId) > 0 and checkint(self.recipeId) > 0    then
            app:DispatchObservers(ANNIVERSARY_CLOSE_PICTH_RECIPE_View_EVENT, {recipeId = self.recipeId  ,priceValue = requestData.priceValue} )
        end
        app:UnRegsitMediator(NAME)
        --self:UpdateUI()
    elseif name == POST.ANNIVERSARY_GET_RECIPE_ATTR.sglName then
        local viewComponent = require("Game.views.anniversary.AnniversaryRecommdView").new(data)
        viewComponent:setPosition(display.center)
        app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    elseif name == POST.ANNIVERSARY_GET_SHOP_LOG.sglName then
        for i, v in ipairs(data.logs) do
            if v.sellTime then
                local sellTime = checkint(v.sellTime)
                local day =  sellTime %100
                local mon  = (sellTime %10000 - day)/100
                local year  = math.floor(sellTime /10000)
                v.sellTime = string.format('%d-%02d-%02d' ,year , mon , day )
            end
        end
        local view = require('Game.views.anniversary.AnniversarySallRecordView').new(data.logs)
        app.uiMgr:GetCurrentScene():AddDialog(view)
        view:setPosition(display.center)
    elseif name == COUNT_DOWN_ACTION then
        if data.timerName == "Anniversay_Left_Second" then
            local countdown = checkint(data.countdown)
            if  countdown <=  0 then
                self.isApply = false
                self.applyLeftSeconds = countdown
             else
                self.applyLeftSeconds = countdown
            end
        end
    end
end


function AnniversaryPitchRecipeMediator:Initial(key)
    self.super.Initial(self, key)
    ---@type AnniversaryPitchRecipView
    local viewComponent = require('Game.views.anniversary.AnniversaryPitchRecipView').new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    local viewData   = viewComponent.viewData
    local closeLayer = viewData.closeLayer
    closeLayer:setTag(BUTTON_TAG.CLOSE_TAG)
    display.commonUIParams(closeLayer, { cb =  handler(self, self.ButtonAction) })

    local addCardBtn = viewData.addCardBtn
    addCardBtn:setTag(BUTTON_TAG.CHANGE_CARD)
    display.commonUIParams(addCardBtn, { cb =  handler(self, self.ButtonAction) })

    local refreshCardBtn = viewData.refreshCardBtn
    refreshCardBtn:setTag(BUTTON_TAG.CHANGE_CARD)
    display.commonUIParams(refreshCardBtn, { cb =  handler(self, self.ButtonAction) })

    local refreshRecipeBtn = viewData.refreshRecipeBtn
    refreshRecipeBtn:setTag(BUTTON_TAG.ADD_FOOD_BTN)
    display.commonUIParams(refreshRecipeBtn, { cb =  handler(self, self.ButtonAction) })

    local addStall = viewData.addStall
    addStall:setTag(BUTTON_TAG.ADD_FOOD_BTN)
    display.commonUIParams(addStall, { cb =  handler(self, self.ButtonAction) })

    local recommendBtn = viewData.recommendBtn
    recommendBtn:setTag(BUTTON_TAG.RECOMMEMD_BTN)
    display.commonUIParams(recommendBtn, { cb =  handler(self, self.ButtonAction) })

    local sellRecordBtn = viewData.sellRecordBtn
    sellRecordBtn:setTag(BUTTON_TAG.SALE_RECORD_BTN)
    display.commonUIParams(sellRecordBtn, { cb =  handler(self, self.ButtonAction) })

    local makeSureBtn = viewData.makeSureBtn
    makeSureBtn:setTag(BUTTON_TAG.MAKE_SURE_EXIT)
    display.commonUIParams(makeSureBtn, { cb =  handler(self, self.ButtonAction) })
end
function AnniversaryPitchRecipeMediator:ShowBusinessTips()
    if checkint(self.applyLeftSeconds)  <= 0  then
        if checkint(self.recipeId) <= 0   then
            app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('未能及时做好今日营业准备，本摊位暂停售卖。')))
        end
    end
end
function AnniversaryPitchRecipeMediator:UpdateUI()
    if self.isApply then
        self:UpdateUIInApply()
    else
        self:UpdateUIInPutAway()
    end
end
--==============================--
---@Description: 更新在报名阶段的UI
---@author : xingweihao
---@date : 2018/10/15 9:16 PM
--==============================--
function AnniversaryPitchRecipeMediator:UpdateUIInApply()
    ---@type AnniversaryPitchRecipView
    local viewComponent    = self:GetViewComponent()
    local viewData         = viewComponent.viewData
    local contentLayer     = viewData.contentLayer
    local refreshCardBtn   = viewData.refreshCardBtn
    local refreshRecipeBtn = viewData.refreshRecipeBtn
    local titleBtn         = viewData.titleBtn
    local addCardBtn       = viewData.addCardBtn
    local recipeImage      = viewData.recipeImage
    local inToFood         = viewData.inToFood
    local sallTwoLayout         = viewData.sallTwoLayout
    local sallLayout         = viewData.sallLayout
    local addStall         = viewData.addStall
    local stallBgOne         = viewData.stallBgOne
    local stallBgTwo         = viewData.stallBgTwo
    local makeSureBtn         = viewData.makeSureBtn
    sallTwoLayout:setVisible(true)
    sallLayout:setVisible(true)
    local  qAvatar = contentLayer:getChildByName("qAvatar")
    if qAvatar then  -- 如果avatar 存在
        qAvatar:removeFromParent()
    end
    addStall:setTouchEnabled(true)
    addStall:setVisible(false)
    makeSureBtn:setVisible(true)
    -- 存在售卖员
    if checkint(self.chooseCardId) > 0   then
        local  cardData =  app.gameMgr:GetCardDataByCardId(self.chooseCardId)
        local qAvatar = AssetsUtils.GetCardSpineNode({skinId = cardData.defaultSkinId, scale = 0.9})
        qAvatar:update(0)
        qAvatar:setTag(1)
        qAvatar:setAnimation(0, 'idle', true)
        qAvatar:setScale(0.8)
        qAvatar:setName("qAvatar")
        qAvatar:setPosition(cc.p(1031/2 -50  , 669/2 -115))
        contentLayer:addChild(qAvatar , -1)
        qAvatar:setName("qAvatar")
        refreshCardBtn:setVisible(true)
        titleBtn:setVisible(false)
        addCardBtn:setVisible(false)
    else
        refreshCardBtn:setVisible(false)
        titleBtn:setVisible(true)
        addCardBtn:setVisible(true)
    end
    if checkint(self.recipeId) > 0   then
        refreshRecipeBtn:setVisible(true)
        recipeImage:setVisible(true)
        recipeImage:setTexture(anniversaryManager:GetAnniversaryRecipePathByRecipId(self.recipeId))
        inToFood:setVisible(false)
        stallBgTwo:setVisible(true)
        stallBgOne:setVisible(true)
        local stallBgOneLabel = viewData.stallBgOneLabel
        local stallBgTwoLabel = viewData.stallBgTwoLabel
        display.reloadRichLabel(stallBgTwoLabel , {

            c = {
                fontWithColor(16, {text = app.anniversaryMgr:GetPoText(__('售价:'))}),
                fontWithColor(6, {text = self.priceValue}),
                { img = CommonUtils.GetGoodsIconPathById(app.anniversaryMgr:GetIncomeCurrencyID()) , scale = 0.2}
            }
        })
        self.recipes = anniversaryManager.homeData.recipes  or {}
        local rate = anniversaryManager:GetPriceSuccessRate(self.recipeId , self.priceValue , self.chooseCardId )
        display.reloadRichLabel(stallBgOneLabel , {
            width = 260 ,
            c = {
                fontWithColor(16, {text = app.anniversaryMgr:GetPoText(__('售菜成功率：'))}),
                fontWithColor(6, {text = rate .. "%" })
            }
        })
        addStall:setVisible(false)
     else
        refreshRecipeBtn:setVisible(false)
        recipeImage:setVisible(false)
        inToFood:setVisible(true)
        stallBgTwo:setVisible(false)
        stallBgOne:setVisible(false)
        addStall:setVisible(true)
    end
    local businessLabel         = viewData.businessLabel
    local parserConfig = anniversaryManager:GetConfigParse()
    local parameterConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.PARAMETER)["1"]
    local managementStart = parameterConfig.managementStart
    local  managementStartTable= string.split(managementStart,":")
    local managementEnd = parameterConfig.managementEnd
    local managementEndTable = string.split(managementEnd,":")
    display.commonLabelParams(businessLabel,
                              {text = string.format(app.anniversaryMgr:GetPoText(__('营业时间：%s:%s~%s:%s')) , managementStartTable[1] ,managementStartTable[2],managementEndTable[1] ,managementEndTable[2] )  })
end
--==============================--
---@Description: 更新售卖阶段
---@author : xingweihao
---@date : 2018/10/15 9:19 PM
--==============================--

function AnniversaryPitchRecipeMediator:UpdateUIInPutAway()
    ---@type AnniversaryPitchRecipView
    local viewComponent    = self:GetViewComponent()
    local viewData         = viewComponent.viewData
    local contentLayer     = viewData.contentLayer
    local refreshCardBtn   = viewData.refreshCardBtn
    local refreshRecipeBtn = viewData.refreshRecipeBtn
    local titleBtn         = viewData.titleBtn
    local addCardBtn       = viewData.addCardBtn
    local addStall         = viewData.addStall
    local recipeImage      = viewData.recipeImage
    local inToFood         = viewData.inToFood
    local stallBgOne         = viewData.stallBgOne
    local stallBgTwo         = viewData.stallBgTwo
    local businessLabel         = viewData.businessLabel
    local sallTwoLayout         = viewData.sallTwoLayout
    local sallLayout         = viewData.sallLayout
    local makeSureBtn         = viewData.makeSureBtn
    local parserConfig = anniversaryManager:GetConfigParse()
    local parameterConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.PARAMETER)["1"]
    local managementStart = parameterConfig.managementStart
    local  managementStartTable= string.split(managementStart,":")
    local managementEnd = parameterConfig.managementEnd
    local managementEndTable = string.split(managementEnd,":")
    sallLayout:setVisible(true)
    makeSureBtn:setVisible(false)
    sallTwoLayout:setVisible(true)
    addStall:setTouchEnabled(false)
    businessLabel:setVisible(true)
    display.commonLabelParams(businessLabel,
{text = string.format(app.anniversaryMgr:GetPoText(__('营业时间：%s:%s~%s:%s')) , managementStartTable[1] ,managementStartTable[2],managementEndTable[1] ,managementEndTable[2] )  })
    -- 存在售卖员
    if checkint(self.chooseCardId) > 0   then
        local  cardData =  app.gameMgr:GetCardDataByCardId(self.chooseCardId)
        local qAvatar = AssetsUtils.GetCardSpineNode({skinId = cardData.defaultSkinId, scale = 0.7})
        qAvatar:update(0)
        qAvatar:setTag(1)
        qAvatar:setAnimation(0, 'idle', true)
        qAvatar:setScale(0.8)
        qAvatar:setName("qAvatar")
        qAvatar:setPosition(cc.p(1031/2 -50 , 669/2-80 ))
        contentLayer:addChild(qAvatar , -1)
        qAvatar:setName("qAvatar")
        refreshCardBtn:setVisible(false)
        titleBtn:setVisible(false)
        addCardBtn:setVisible(false)
    else
        refreshCardBtn:setVisible(false)
        titleBtn:setVisible(false)
        addCardBtn:setVisible(false)
    end
    if checkint(self.recipeId) > 0   then
        refreshRecipeBtn:setVisible(false)
        recipeImage:setVisible(true)
        recipeImage:setTexture(anniversaryManager:GetAnniversaryRecipePathByRecipId(self.recipeId))
        inToFood:setVisible(false)
        stallBgTwo:setVisible(true)
        stallBgOne:setVisible(true)
        local stallBgOneLabel = viewData.stallBgOneLabel
        local stallBgTwoLabel = viewData.stallBgTwoLabel
        display.reloadRichLabel(stallBgTwoLabel , {
            c = {
                fontWithColor(16, {text = app.anniversaryMgr:GetPoText(__('售价:'))}),
                fontWithColor(6, {text = self.priceValue}),
                { img = CommonUtils.GetGoodsIconPathById(app.anniversaryMgr:GetIncomeCurrencyID()) , scale = 0.2}
            }
        })
        self.recipes = anniversaryManager.homeData.recipes  or {}
        local rate = anniversaryManager:GetPriceSuccessRate(self.recipeId , self.priceValue , self.chooseCardId )
        display.reloadRichLabel(stallBgOneLabel , {
            c = {
                fontWithColor(16, {text = app.anniversaryMgr:GetPoText(__('售菜成功率：'))}),
                fontWithColor(6, {text = rate  .. "%"})
            }
        })
        addStall:setVisible(false)
    else
        refreshRecipeBtn:setVisible(false)
        recipeImage:setVisible(false)
        inToFood:setVisible(false)
        stallBgTwo:setVisible(false)
        addStall:setVisible(false)
        stallBgOne:setVisible(false)
    end
end
function AnniversaryPitchRecipeMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if tag == BUTTON_TAG.CLOSE_TAG then
        if checkint(self.applyLeftSeconds ) > 0   then
            if checkint(self.recipeId) > 0 and checkint(self.chooseCardId) > 0     then
                local callback = function()
                    local cardData = app.gameMgr:GetCardDataByCardId(self.chooseCardId)
                    self:SendSignal(POST.ANNIVERSARY_SET_SHOP_CONFIG.cmdName ,{
                        playerCardId = cardData.id   , recipeId = self.recipeId , recipePrice = self.priceValue
                    })
                end
                local cancelBack = function()
                    self:GetFacade():UnRegsitMediator(NAME)
                end
                app.uiMgr:AddCommonTipDialog({descr  = app.anniversaryMgr:GetPoText(__('是否保存数据？')) ,callback =callback ,cancelBack = cancelBack })
            else
                self:GetFacade():UnRegsitMediator(NAME)
            end
        else
            self:GetFacade():UnRegsitMediator(NAME)
        end
    elseif tag == BUTTON_TAG.ADD_FOOD_BTN then
        local mediator = require("Game.mediator.anniversary.AnniversarySelectPriceMediator").new({recipeId = self.recipeId  , priceValue = self.priceValue })
        app:RegistMediator(mediator)
    elseif tag == BUTTON_TAG.CHANGE_CARD then
        local mediator = require('Game.mediator.anniversary.AnniversaryChooseCardMediator').new({cardId = self.chooseCardId  })
        app:RegistMediator(mediator)
    elseif tag == BUTTON_TAG.RECOMMEMD_BTN then
      self:SendSignal(POST.ANNIVERSARY_GET_RECIPE_ATTR.cmdName , {})
    elseif tag == BUTTON_TAG.SALE_RECORD_BTN then
        self:SendSignal(POST.ANNIVERSARY_GET_SHOP_LOG.cmdName , {})
    elseif tag == BUTTON_TAG.MAKE_SURE_EXIT then
        if checkint(self.applyLeftSeconds ) > 0   then
            if checkint(self.recipeId) > 0 and checkint(self.chooseCardId) > 0     then
                local cardData = app.gameMgr:GetCardDataByCardId(self.chooseCardId)
                self:SendSignal(POST.ANNIVERSARY_SET_SHOP_CONFIG.cmdName ,{
                    playerCardId = cardData.id   , recipeId = self.recipeId , recipePrice = self.priceValue
                })
            else
                self:GetFacade():UnRegsitMediator(NAME)
            end
        end

    end
end
function AnniversaryPitchRecipeMediator:OnRegist()
    regPost(POST.ANNIVERSARY_GET_SHOP_CONFIG)
    regPost(POST.ANNIVERSARY_SET_SHOP_CONFIG)
    regPost(POST.ANNIVERSARY_GET_SHOP_LOG)
    regPost(POST.ANNIVERSARY_GET_RECIPE_ATTR)
    self:SendSignal(POST.ANNIVERSARY_GET_SHOP_CONFIG.cmdName , {})
end
function AnniversaryPitchRecipeMediator:OnUnRegist()
    unregPost(POST.ANNIVERSARY_GET_SHOP_CONFIG)
    unregPost(POST.ANNIVERSARY_GET_SHOP_LOG)
    unregPost(POST.ANNIVERSARY_SET_SHOP_CONFIG)
    unregPost(POST.ANNIVERSARY_GET_RECIPE_ATTR)

    app.timerMgr:RemoveTimer(PUT_AWAY_TIME_EVENT)
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return AnniversaryPitchRecipeMediator