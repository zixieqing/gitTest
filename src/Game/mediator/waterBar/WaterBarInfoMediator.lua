--[[
 * author : kaishiqi
 * descpt : 水吧 - 信息中介者
]]
local WaterBarInfoView     = require('Game.views.waterBar.WaterBarInfoView')
local WaterBarInfoMediator = class('WaterBarInfoMediator', mvc.Mediator)

local WATER_BAR_DEFINE   = FOOD.WATER_BAR.DEFINE
local INFO_PROXY_NAME    = FOOD.WATER_BAR.INFO.PROXY_NAME
local INFO_PROXY_STRUCT  = FOOD.WATER_BAR.INFO.PROXY_STRUCT
local INFO_TAB_FUNC_ENUM = FOOD.WATER_BAR.INFO.TAB_FUNC_ENUM

function WaterBarInfoMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'WaterBarInfoMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function WaterBarInfoMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- init model
    self.infoProxy_ = regVoProxy(INFO_PROXY_NAME, INFO_PROXY_STRUCT)

    -- create view
    self.viewNode_ = WaterBarInfoView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddGameLayer(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    ui.bindClick(self:getViewData().expireBtn, handler(self, self.onClickTabButtonHandler_), false)
    ui.bindClick(self:getViewData().updateBtn, handler(self, self.onClickTabButtonHandler_), false)
    ui.bindClick(self:getViewData().billBtn, handler(self, self.onClickTabButtonHandler_), false)
    self:getViewNode().initUpgradeCallback = function(viewData)
        ui.bindClick(viewData.upateLevelBtn, handler(self, self.onClickUpdateLevelButtonHandler_))
    end

    -- update datas
    self.infoProxy_:set(INFO_PROXY_STRUCT.WATER_BAR_LEVEL, app.waterBarMgr:getBarLevel())
    self.infoProxy_:set(INFO_PROXY_STRUCT.WATER_BAR_POPULARITY, app.waterBarMgr:getBarPopularity())
    self.infoProxy_:set(INFO_PROXY_STRUCT.SELECT_TAB_INDEX, INFO_TAB_FUNC_ENUM.UPGRADE)
    self.infoProxy_:set(INFO_PROXY_STRUCT.YESTERDAY_BILL_LIST, app.waterBarMgr:getYesterdayBill())
    self.infoProxy_:set(INFO_PROXY_STRUCT.YESTERDAY_EXPIRE_LIST, app.waterBarMgr:getYesterdayExpire())
end


function WaterBarInfoMediator:CleanupView()
    unregVoProxy(INFO_PROXY_NAME)

    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function WaterBarInfoMediator:OnRegist()
    regPost(POST.WATER_BAR_LEVELUP)
end


function WaterBarInfoMediator:OnUnRegist()
    unregPost(POST.WATER_BAR_LEVELUP)
end


function WaterBarInfoMediator:InterestSignals()
    return {
        POST.WATER_BAR_LEVELUP.sglName,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
    }
end
function WaterBarInfoMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.WATER_BAR_LEVELUP.sglName then
        self.infoProxy_:set(INFO_PROXY_STRUCT.UPGRADE_TAKE, data)
        
        local newBarLevel   = self.infoProxy_:get(INFO_PROXY_STRUCT.UPGRADE_TAKE.NEW_BAR_LEVEL)
        local newPopularity = self.infoProxy_:get(INFO_PROXY_STRUCT.UPGRADE_TAKE.NEW_POPULARITY)
        local newBarConf    = CONF.BAR.LEVEL_UP:GetValue(newBarLevel)

        -- update costGoods
        local costGoodsData = {}
        for i, goodsData in ipairs(newBarConf.consumeGoods or {}) do
            costGoodsData[i] = {goodsId = checkint(goodsData.goodsId), num = -checkint(goodsData.num)}
        end
        CommonUtils.DrawRewards(costGoodsData)

        -- update infoData
        app.waterBarMgr:setBarLevel(newBarLevel)
        app.waterBarMgr:setBarPopularity(newPopularity)
        self.infoProxy_:set(INFO_PROXY_STRUCT.WATER_BAR_LEVEL, app.waterBarMgr:getBarLevel())
        self.infoProxy_:set(INFO_PROXY_STRUCT.WATER_BAR_POPULARITY, app.waterBarMgr:getBarPopularity())

        -- show animation or tips
        app.uiMgr:ShowInformationTips(__('恭喜您水吧升级成功！！'))


    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        self.infoProxy_:event(INFO_PROXY_STRUCT.WATER_BAR_LEVEL)

    end
end


-------------------------------------------------
-- get / set

function WaterBarInfoMediator:getViewNode()
    return  self.viewNode_
end
function WaterBarInfoMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function WaterBarInfoMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private


-------------------------------------------------
-- handler

function WaterBarInfoMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    
    self:close()
end


function WaterBarInfoMediator:onClickTabButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    local tabBtnIndex = checkint(sender:getTag())
    if self.infoProxy_:get(INFO_PROXY_STRUCT.SELECT_TAB_INDEX) == tabBtnIndex then
        sender:setChecked(true)
    else
        self.infoProxy_:set(INFO_PROXY_STRUCT.SELECT_TAB_INDEX, tabBtnIndex)
    end
end


function WaterBarInfoMediator:onClickUpdateLevelButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local popularityNow = self.infoProxy_:get(INFO_PROXY_STRUCT.WATER_BAR_POPULARITY)
    local currentLevel  = self.infoProxy_:get(INFO_PROXY_STRUCT.WATER_BAR_LEVEL)
    local maxBarLevel   = CONF.BAR.LEVEL_UP:GetLength()
    local nextBarLevel  = math.min(currentLevel + 1, maxBarLevel)
    local nextBarConf   = CONF.BAR.LEVEL_UP:GetValue(nextBarLevel)

    if currentLevel < maxBarLevel then
        -- check costGoods
        local notEnoughGoodsId = 0
        for i, goodsData in ipairs(nextBarConf.consumeGoods or {}) do
            local costGoodsNum = checkint(goodsData.num)
            local haveGoodsNum = CommonUtils.GetCacheProductNum(goodsData.goodsId)
            if haveGoodsNum < costGoodsNum then
                notEnoughGoodsId = checkint(goodsData.goodsId)
                break
            end
        end

        -- check popularity
        if notEnoughGoodsId == 0 and popularityNow < checkint(nextBarConf.barPopularity) then
            notEnoughGoodsId = FOOD.GOODS.DEFINE.WATER_BAR_POPULARITY_ID
        end

        -- check enough
        if notEnoughGoodsId > 0 then
            app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {_name_ = CommonUtils.GetCacheProductName(notEnoughGoodsId)}))
        else
            if app.waterBarMgr:isHomeClosing() then
                self:SendSignal(POST.WATER_BAR_LEVELUP.cmdName)
            else
                app.uiMgr:ShowInformationTips(__('水吧只能在打烊期间进行升级'))
            end
        end
    else
        app.uiMgr:ShowInformationTips(__('水吧已达到最高等级'))
    end
end


return WaterBarInfoMediator
