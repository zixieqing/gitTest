
---
--- Created by xingweihao.
--- DateTime: 27/10/2017 9:53 AM
---
local Mediator = mvc.Mediator
---@class CastleRewardKeysMediator :Mediator
local CastleRewardKeysMediator = class("CastleRewardKeysMediator", Mediator)
local NAME = "CastleRewardKeysMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local ActivityHoneyBentoCell = require('home.ActivityHoneyBentoCell')

local ticketConfig= CommonUtils.GetConfigAllMess('goodsRewards' , 'springActivity')
--[[
{
 seasonActivityData = {}
}
--]]
function CastleRewardKeysMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.homeData = param.homeData or {}
end
function CastleRewardKeysMediator:InterestSignals()
    local signals = {
        POST.SPRING_ACTIVITY_DRAWTICKET.sglName
    }
    return signals
end
function CastleRewardKeysMediator:GetHomeDataTicketReceive()
    return self.homeData.ticketReceive
end
function CastleRewardKeysMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type CastleRewardKeysView
    self.viewComponent = require('Game.views.castle.CastleRewardKeysView').new()
    uiMgr:GetCurrentScene():AddDialog(self.viewComponent)
    self.viewComponent:setPosition(cc.p(display.cx, display.cy))
    self.rewardTimeTable = {}

    for k ,v in pairs(ticketConfig) do
        local startTimeData = string.split(v.startTime, ':')
        local endedTimeData = string.split(v.endTime, ':')
        local startTimeText = l10nHours(startTimeData[1], startTimeData[2]):fmt('%H:%M')
        local endedTimeText = l10nHours(endedTimeData[1], endedTimeData[2]):fmt('%H:%M')
        self.rewardTimeTable[tostring(k)] = {}
        self.rewardTimeTable[tostring(k)].startTimeText = startTimeText
        self.rewardTimeTable[tostring(k)].endedTimeText = endedTimeText
    end
    self.rewardTimeTable['1'].title = app.activityMgr:GetCastleText(__('初之钥'))
    self.rewardTimeTable['2'].title = app.activityMgr:GetCastleText(__('暮之钥'))
    self.rewardTimeTable['3'].title = app.activityMgr:GetCastleText(__('终之钥'))
    local viewData_ = self.viewComponent.viewData_
    viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
    viewData_.gridView:setCountOfCell(3)
    viewData_.gridView:reloadData()
    local currentIndex = nil
    local homeData = self:GetHomeDataTicketReceive()
    self.viewComponent:runAction(cc.RepeatForever:create( cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(
            function ()
                local nowIndex = nil
                for i, timeData in pairs(homeData) do
                    if  checkint(timeData.hadDrawn) == 2   then
                        nowIndex =  i
                    end
                end
                if  nowIndex and  currentIndex ~= nowIndex    then
                    local cell = viewData_.gridView:cellAtIndex(nowIndex -1 )
                    if cell and ( not tolua.isnull(cell)) then
                        self:updateActivityHoneyBentoCell_(nowIndex ,cell )
                    end
                end
                if currentIndex and   currentIndex ~= nowIndex  then
                    local cell = viewData_.gridView:cellAtIndex(currentIndex -1 )
                    if cell and ( not tolua.isnull(cell)) then
                        self:updateActivityHoneyBentoCell_(currentIndex ,cell )
                    end
                    currentIndex = nil
                end
                if nowIndex ~=  currentIndex  then
                    currentIndex = nowIndex
                end
            end
    ))))
    viewData_.closeLayout:setOnClickScriptHandler(
            function ()
                self:GetFacade():UnRegsitMediator(NAME)
            end)
    self.rewardTimeTable = {}

end


function CastleRewardKeysMediator:OnDataSource(p_convertview,idx)
    local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(224, 482)
    if pCell == nil then
        pCell = ActivityHoneyBentoCell.new(cSize)
        pCell.drawBtn:setOnClickScriptHandler(handler(self, self.DrawSeasonGoodClick))
    end
    xTry(function()
        local goodData = ticketConfig[tostring(index)].rewards[1]
        local rewardTable = self.rewardTimeTable[tostring(index)]
        pCell.drawBtn:setTag(index)
        if goodData and rewardTable then
            pCell.title:setString(rewardTable.title)
            pCell.rewardNum:setString(checkint(goodData.num))
            pCell.rewardIcon:setTexture(CommonUtils.GetGoodsIconPathById(checkint(goodData.goodsId)))
            pCell.bg:setTexture(app.activityMgr:CastleResEx(string.format('ui/castle/rewards/castle_keys_bg_%d.png', index)))
            pCell.icon:setTexture(app.activityMgr:CastleResEx(_res("ui/castle/rewards/castle_keys_ico_keys")))
            pCell.icon:setScale(0.7)
            pCell.timeLabel:setString(string.fmt('%1 - %2', rewardTable.startTimeText, rewardTable.endedTimeText))
            self:updateActivityHoneyBentoCell_(index, pCell)
        end
    end,__G__TRACKBACK__)
    return pCell
end
function CastleRewardKeysMediator:DrawSeasonGoodClick(sender)
    local tag = sender:getTag()
    local homeData = self:GetHomeDataTicketReceive()
    local isReceived  = checkint(homeData[tag].hasDrawn)
    if checkint(isReceived)  ~= 1  then
        self:SendSignal(POST.SPRING_ACTIVITY_DRAWTICKET.cmdName, {ticketId = tag })
    else
        uiMgr:ShowInformationTips(app.activityMgr:GetCastleText(__('已经领取过该档的钥匙串奖励')))
    end
end
function CastleRewardKeysMediator:updateActivityHoneyBentoCell_(index, bentoGridCell)
    local viewData_ = self.viewComponent.viewData_
    local bentoGridView  =  viewData_.gridView
    local bentoGridCell  = bentoGridCell or (bentoGridView and bentoGridView:cellAtIndex(checkint(index) - 1))
    local bentoData      = self:GetHomeDataTicketReceive()
    if bentoGridCell and bentoData then
        local isReceived = checkint(bentoData[index].hasDrawn)  == 1
        if isReceived then
            display.commonLabelParams(bentoGridCell.drawBtn, fontWithColor(14, {text = app.activityMgr:GetCastleText(__('已领取'))}))
            bentoGridCell:updateDrawButtonStatus(false)
            bentoGridCell.frame:setVisible(false)
            bentoGridCell.drawIcon:setVisible(true)
            bentoGridCell.status = false
            bentoGridCell.unlockMask:setVisible(true)
            bentoGridCell.unlockMask:setTexture(app.activityMgr:CastleResEx('ui/castle/rewards/castle_keys_bg_lock.png'))
        else
            display.commonLabelParams(bentoGridCell.drawBtn, fontWithColor(14, {text = app.activityMgr:GetCastleText(__('领取'))}))
            if checkint(bentoData[index].hasDrawn)  == 2 then
                bentoGridCell:updateDrawButtonStatus(true)
                bentoGridCell.frame:setVisible(true )
                bentoGridCell.unlockMask:setVisible(false)
                local bentoGridCellSize =  bentoGridCell:getContentSize()

                bentoGridCell.frame:setScaleY(0.97)
                bentoGridCell.frame:setPosition(bentoGridCellSize.width/2 ,bentoGridCellSize.height/2-4 )
                bentoGridCell.status = true
                bentoGridCell.drawIcon:setVisible(false)
            else
                bentoGridCell.unlockMask:setVisible(false)
                bentoGridCell.status = false
                bentoGridCell:updateDrawButtonStatus(false)
                bentoGridCell.frame:setVisible(false)
                bentoGridCell.drawIcon:setVisible(false)
            end
        end
    end
end

function CastleRewardKeysMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.SPRING_ACTIVITY_DRAWTICKET.sglName then
        local requestData = data.requestData
        local type = checkint(requestData.ticketId)
        local rewards = data.rewards
        local viewData_  = self.viewComponent.viewData_
        local gridView = viewData_.gridView
        local cell =  gridView:cellAtIndex(checkint(type) - 1)
        local ticketReceive = self:GetHomeDataTicketReceive()
        ticketReceive[type].hasDrawn  =  1
        if cell and ( not tolua.isnull(cell)) then
            self:updateActivityHoneyBentoCell_(type ,cell )
        end
        uiMgr:AddDialog('common.RewardPopup',{rewards = rewards})
    end

end

function CastleRewardKeysMediator:OnRegist()
    regPost(POST.SPRING_ACTIVITY_DRAWTICKET)

end

function CastleRewardKeysMediator:OnUnRegist()
    unregPost(POST.SPRING_ACTIVITY_DRAWTICKET)
    if self.viewComponent and (not tolua.isnull(self.viewComponent)) then
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return CastleRewardKeysMediator



