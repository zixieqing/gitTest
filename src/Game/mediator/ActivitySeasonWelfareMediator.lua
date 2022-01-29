
---
--- Created by xingweihao.
--- DateTime: 27/10/2017 9:53 AM
---
local Mediator = mvc.Mediator
---@class ActivitySeasonWelfareMediator :Mediator
local ActivitySeasonWelfareMediator = class("ActivitySeasonWelfareMediator", Mediator)
local NAME = "ActivitySeasonWelfareMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local ActivityHoneyBentoCell = require('home.ActivityHoneyBentoCell')

local ticketConfig= CommonUtils.GetConfigAllMess('ticketReceive' , 'seasonActivity')
--[[
{
 seasonActivityData = {}
}
--]]
function ActivitySeasonWelfareMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)

end
function ActivitySeasonWelfareMediator:InterestSignals()
    local signals = {
        POST.SEASON_ACTIVITY_RECEIVE_TICKET.sglName
    }
    return signals
end
function ActivitySeasonWelfareMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type ActivitySeasonWelfareView
    self.viewComponent = require('Game.views.ActivitySeasonWelfareView').new()
    uiMgr:GetCurrentScene():AddDialog(self.viewComponent)
    self.viewComponent:setPosition(cc.p(display.cx, display.cy))
    self.rewardTimeTable = {}
    for k ,v in pairs(ticketConfig) do
        local startTimeData = string.split(v.startTime, ':')
        local endedTimeData = string.split(v.endTime, ':')
        local startTimeText = l10nHours(startTimeData[1], startTimeData[2]):fmt('%H:%M')
        local endedTimeText = l10nHours(endedTimeData[1], endedTimeData[2]):fmt('%H:%M')
        self.rewardTimeTable[k] = {}
        self.rewardTimeTable[k].startTimeText = startTimeText
        self.rewardTimeTable[k].endedTimeText = endedTimeText
    end
    self.rewardTimeTable['1'].title = __('中午开门炮')
    self.rewardTimeTable['2'].title = __('晚上开门炮')
    self.rewardTimeTable['3'].title = __('半夜开门炮')
    local viewData_ = self.viewComponent.viewData_
    viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
    viewData_.gridView:setCountOfCell(3)
    viewData_.gridView:reloadData()
    local currentIndex = nil
    self.viewComponent:runAction(cc.RepeatForever:create( cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(
        function ()
            local isReceived , nowIndex  = app.activityMgr:JudageSeasonFoodIsReward()
            if checkint(isReceived)  ==1 and  nowIndex  then
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
                self:GetFacade():DispatchObservers(ALREADY_RECEIVE_NEW_YEAR_POINT_EVENT,{isSeasonGoods = true })
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


function ActivitySeasonWelfareMediator:OnDataSource(p_convertview,idx)
    local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(224, 482)
    if pCell == nil then
        pCell = ActivityHoneyBentoCell.new(cSize)
        pCell.drawBtn:setOnClickScriptHandler(handler(self, self.DrawSeasonGoodClick))
    end
    xTry(function()
        local goodData = ticketConfig[tostring(index)].reward[1]
        local rewardTable = self.rewardTimeTable[tostring(index)]
        pCell.drawBtn:setTag(index)
        if goodData and rewardTable then
            pCell.title:setString(rewardTable.title)
            pCell.rewardNum:setString(checkint(goodData.num))
            pCell.rewardIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(checkint(goodData.goodsId))))
            pCell.bg:setTexture(_res(string.format('ui/home/activity/activity_love_lunch_bg_%d.png', index)))
            pCell.icon:setTexture(_res('ui/home/activity/seasonlive/season_loots_btn_rewards_2'))
            pCell.timeLabel:setString(string.fmt('%1 - %2', rewardTable.startTimeText, rewardTable.endedTimeText))
            self:updateActivityHoneyBentoCell_(index, pCell)
        end
    end,__G__TRACKBACK__)
    return pCell
end
function ActivitySeasonWelfareMediator:DrawSeasonGoodClick(sender)
    local tag = sender:getTag()
    local isReceived      = gameMgr:GetUserInfo().seasonActivityTickets[tostring(tag)]
    if checkint(isReceived)  ~= 1  then
        self:SendSignal(POST.SEASON_ACTIVITY_RECEIVE_TICKET.cmdName, {ticketId = tag })
    else
        uiMgr:ShowInformationTips(__('已经领取过该档的开门炮奖励'))
    end
end
function ActivitySeasonWelfareMediator:updateActivityHoneyBentoCell_(index, bentoGridCell)
    local viewData_ = self.viewComponent.viewData_
    local bentoGridView  =  viewData_.gridView
    local bentoGridCell  = bentoGridCell or (bentoGridView and bentoGridView:cellAtIndex(checkint(index) - 1))
    local bentoData      = gameMgr:GetUserInfo().seasonActivityTickets
    if bentoGridCell and bentoData then
        local isReceived = checkint(bentoData[tostring(index)])  == 1
        if isReceived then
            display.commonLabelParams(bentoGridCell.drawBtn, fontWithColor(14, {text = __('已领取')}))
            bentoGridCell:updateDrawButtonStatus(false)
            bentoGridCell.frame:setVisible(false)
            bentoGridCell.drawIcon:setVisible(true)
            bentoGridCell.status = false
        else
            display.commonLabelParams(bentoGridCell.drawBtn, fontWithColor(14, {text = __('领取')}))
            local isReward , pos = app.activityMgr:JudageSeasonFoodIsReward()
            if isReward and pos == index  then
                bentoGridCell:updateDrawButtonStatus(true)
                bentoGridCell.frame:setVisible(true)
                bentoGridCell.status = true
                bentoGridCell.drawIcon:setVisible(false)
            else
                bentoGridCell.status = false
                bentoGridCell:updateDrawButtonStatus(false)
                bentoGridCell.frame:setVisible(false)
                bentoGridCell.drawIcon:setVisible(false)

            end
        end
    end
end

function ActivitySeasonWelfareMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.SEASON_ACTIVITY_RECEIVE_TICKET.sglName then
        local requestData = data.requestData
        local type = checkint(requestData.ticketId)
        local rewards = data.rewards
        local viewData_  = self.viewComponent.viewData_
        local gridView = viewData_.gridView
        local cell =  gridView:cellAtIndex(checkint(type) - 1)
        gameMgr:GetUserInfo().seasonActivityTickets[tostring(type)] = 1
        if cell and ( not tolua.isnull(cell)) then
            self:updateActivityHoneyBentoCell_(type ,cell )
        end
        uiMgr:AddDialog('common.RewardPopup',{rewards = rewards})
    end

end

function ActivitySeasonWelfareMediator:OnRegist()
    regPost(POST.SEASON_ACTIVITY_RECEIVE_TICKET)

end

function ActivitySeasonWelfareMediator:OnUnRegist()
    unregPost(POST.SEASON_ACTIVITY_RECEIVE_TICKET)
    if self.viewComponent and (not tolua.isnull(self.viewComponent)) then
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return ActivitySeasonWelfareMediator



