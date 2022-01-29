--[[
 * author : weihao
 * descpt : 猫屋 - 信息 中介者
]]
local CatHouseInfoView     = require('Game.views.catHouse.CatHouseInfoView')
---@class CatHouseInfoMediator:Mediator
local CatHouseInfoMediator = class('CatHouseInfoMediator', mvc.Mediator)
--[[
{
    friendId = "" , 玩家id
    houseData = {   猫屋数据

    }
}
--]]
local EVENTS = {
    CAT_HOUSE_UPGRADE_LEVEL_EVENT = "CAT_HOUSE_UPGRADE_LEVEL_EVENT"
}
local BUTTON_TAGS = {
    CAT_INFO  = 1001 ,
    CAT_LEVEL = 1002
}

function CatHouseInfoMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatHouseInfoMediator', viewComponent)

    self.ctorArgs_ = checktable(params)
    self.selectTag = BUTTON_TAGS.CAT_INFO
end


-------------------------------------------------
-- inheritance

function CatHouseInfoMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    local viewNode_ = CatHouseInfoView.new()
    self:SetViewComponent(viewNode_)
    self:setViewNode(viewNode_)
    app.uiMgr:GetCurrentScene():AddDialog(viewNode_)
    -- update views
    local viewData = self:getViewData()
    viewData.catLevelBtn:setVisible(CommonUtils.JuageMySelfOperation(self.ctorArgs_.friendId))
    ui.bindClick(viewData.closeLayer ,handler( self,self.onClickBackButtonHandler_) , false)
    ui.bindClick(viewData.catLevelBtn , handler(self, self.ButtonAction))
    ui.bindClick(viewData.catInfoBtn , handler(self, self.ButtonAction))
    viewNode_:UpdateView(BUTTON_TAGS.CAT_INFO , self.ctorArgs_)
end


function CatHouseInfoMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end

function CatHouseInfoMediator:InterestSignals()
    return {
        EVENTS.CAT_HOUSE_UPGRADE_LEVEL_EVENT ,
        POST.HOUSE_LEVEL_UPGRADE.sglName 
    }
end
function CatHouseInfoMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == EVENTS.CAT_HOUSE_UPGRADE_LEVEL_EVENT then
        local catHouseMgr = app.catHouseMgr
        local houseLevel = catHouseMgr:getHouseLevel()
        local nextLevel = houseLevel + 1
        local levelUpConf = CONF.CAT_HOUSE.LEVEL_INFO:GetAll()
        local nextConf = levelUpConf[tostring(nextLevel)]
        if nextConf then
            local houseData = self.ctorArgs_.houseData
            local location = houseData.location or {}
            local catTriggerEvent = houseData.catTriggerEvent or {}
            local comfortCount = 0
            for i, v in pairs(location) do
                comfortCount = comfortCount + CatHouseUtils.GetComfortValueByGoodsId(v.goodsId)
            end
            for _, eventData in ipairs(catTriggerEvent) do
                local eventId   = checkint(eventData.eventId)
                local eventConf = CONF.CAT_HOUSE.CAT_TRIGGER_EVENT:GetValue(eventId)
                local discount  = checkint(eventConf.eventParameter)
                comfortCount = comfortCount * ((100 - discount) / 100)
                break
            end

            if comfortCount < checkint(nextConf.comfort) then
                app.uiMgr:ShowInformationTips(__('舒适度不足'))
                return
            end
            local isUnlock = true
            local consume = nextConf.consume
            for i, v in pairs(consume) do
                local num = checkint(v.num)
                local ownerNum = CommonUtils.GetCacheProductNum(v.goodsId)
                if num > ownerNum then
                    isUnlock = false
                    break
                end
            end
            if not isUnlock then
                app.uiMgr:ShowInformationTips(__('道具不足！'))
                return
            end
            self:SendSignal(POST.HOUSE_LEVEL_UPGRADE.cmdName ,{ })
        end
    elseif name == POST.HOUSE_LEVEL_UPGRADE.sglName then
        local newLevel = checkint(data.newLevel)
        app.catHouseMgr:setHouseLevel(newLevel)
        local levelUpConf = CONF.CAT_HOUSE.LEVEL_INFO:GetAll()
        local consume = clone(levelUpConf[tostring(newLevel)].consume)
        for i, v in pairs(consume) do
        v.num = -v.num
        end
        --- 扣除道具
        CommonUtils.DrawRewards(consume)
        local viewNode_ = self:getViewNode()
        viewNode_:UpdateLevelLayout(self.ctorArgs_)
        app.uiMgr:ShowInformationTips(__('猫屋升级成功'))
    end
end


-------------------------------------------------
-- get / set
---@return CatHouseInfoView
function CatHouseInfoMediator:getViewNode()
    return  self.viewNode_
end

---@return CatHouseInfoView
function CatHouseInfoMediator:setViewNode(viewNode_)
    self.viewNode_ = viewNode_
end
function CatHouseInfoMediator:getViewData()
    return self:getViewNode():getViewData()
end

-------------------------------------------------
-- public

function CatHouseInfoMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end
-------------------------------------------------
-- handler

function CatHouseInfoMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end

function CatHouseInfoMediator:ButtonAction(sender)
    local tag = sender:getTag()
    local viewNode_ = self:getViewNode()
    viewNode_:UpdateView(tag , self.ctorArgs_)
end


function CatHouseInfoMediator:OnRegist()
    regPost(POST.HOUSE_LEVEL_UPGRADE)
end


function CatHouseInfoMediator:OnUnRegist()
    unregPost(POST.HOUSE_LEVEL_UPGRADE)
    local viewNew = self:GetViewComponent()
    if viewNew and (not tolua.isnull(viewNew)) then
        self:SetViewComponent(nil)
        app.uiMgr:GetCurrentScene():RemoveDialog(viewNew)
    end
end
return CatHouseInfoMediator
