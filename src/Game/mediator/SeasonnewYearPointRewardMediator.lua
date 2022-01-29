---
--- Created by xingweihao.
--- DateTime: 27/10/2017 9:53 AM
---
local Mediator = mvc.Mediator
---@class SeasonnewYearPointRewardMediator :Mediator
local SeasonnewYearPointRewardMediator = class("SeasonnewYearPointRewardMediator", Mediator)
local NAME = "SeasonnewYearPointRewardMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local scoreRewardConfig = CommonUtils.GetConfigAllMess('scoreReward','seasonActivity')
local REWARD_STATUS = {
    ALREADY_RECEIVE = 1 , -- 已经领取
    CAN_RECEIVE = 2 ,    -- 尚未领取，可以领取
    CANNOT_RECEIVE = 3   -- 不可以领取
}
--[[
    param = {
      newYearPoint =  11, -- 常量数值
      scoreRewardReceived  = {} , -- 奖励领取的类型 表结构
    }
--]]
function SeasonnewYearPointRewardMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    param = param or {}
    self.newYearPoint = param.newYearPoint or 0
    self.rareIndex = 0
    self.maxIndex = 1
    self.isRed = false
    self.sortKey = {}
    self.isChange = false  -- 用于判断是否刷新事件
    self.isClose  = false
    self.count = table.nums(scoreRewardConfig)
    self.scoreRewardReceived =param.scoreRewardReceived  or {} -- 奖励领取过的ID
end
function SeasonnewYearPointRewardMediator:InterestSignals()
    local signals = {
        POST.SEASON_ACTIVITY_RECEIVESCOER_REWARD.sglName
    }
    return signals
end
function SeasonnewYearPointRewardMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type SeasonnewYearPointRewardView
    self.viewComponent = require("Game.views.SeasonnewYearPointRewardView").new()
    uiMgr:GetCurrentScene():AddDialog(self.viewComponent)
    self.viewComponent:setPosition(display.center)
    local viewData = self.viewComponent.viewData
    viewData.closeLayer:setOnClickScriptHandler(
        function (sender)
            if self.isClose  then
                self:GetFacade():UnRegsitMediator(NAME)
            end
        end
    )
    viewData.bgLayout:runAction(
        cc.Sequence:create(
            cc.EaseExponentialOut:create(
                    cc.MoveTo:create(0.6, cc.p(display.width / 2, display.height - viewData.bgLayout:getContentSize().height))
            ),
            cc.CallFunc:create(
                function()
                    self.isClose = true
                end
            )
        )
    )
    self.sortKey =  self:GetSorceReardsKeyBySortUp()
    self.rareIndex = self:GetRareIndex()
    self.maxIndex = self:GetMaxNewyeasPintIndex()
    local maxnewYearPoint = scoreRewardConfig[self.maxIndex].newYearPoint
    viewData.progressBarThree:setMaxValue(maxnewYearPoint)
    viewData.progressBarThree:setValue(self.newYearPoint)
    display.commonLabelParams(viewData.prograssThreeLabel ,{text = string.format(__('压岁钱：%s/%s') ,checkint(self.newYearPoint)  , checkint(maxnewYearPoint) )})
    self:UpdateView()
end
function SeasonnewYearPointRewardMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.SEASON_ACTIVITY_RECEIVESCOER_REWARD.sglName then
        local requestData = data.requestData
        self.isChange = true
        self.scoreRewardReceived = self:MergeTable(self.scoreRewardReceived , tostring(requestData.rewardId))
        uiMgr:AddDialog("common.RewardPopup",{rewards = data.rewards })
        self:UpdateCellStatus(requestData.rewardId)
    end

end
--[[
    获取到最大的积分的index
--]]
function SeasonnewYearPointRewardMediator:GetMaxNewyeasPintIndex()
    local maxNum =  0
    local index = 0
    for i =1 , #self.sortKey  do
        local v = scoreRewardConfig[tostring(self.sortKey[i])]
        if maxNum <=  checkint(v.newYearPoint)  then
            maxNum = checkint(v.newYearPoint)
            index = i
        end
    end
    return self.sortKey[index]
end
--[[
    获取到最稀有的道具显示
--]]
function SeasonnewYearPointRewardMediator:GetRareIndex()
    local index = 1
    for i =1 , #self.sortKey  do
        local v = scoreRewardConfig[tostring(self.sortKey[i])]
        if checkint(v.rareGet) == 1  then
            index = i
            break
        end
    end
    return self.sortKey[index]
end

--[[
    更新界面的信息
--]]
function SeasonnewYearPointRewardMediator:UpdateView()
    local viewData = self.viewComponent.viewData
    local centerLayer = viewData.centerLayer
    local index = self.rareIndex
    local data = scoreRewardConfig[tostring(index)]
    local centerSize = viewData.centerSize
    local cellLayout = self.viewComponent:CreateOneCell(data)
    centerLayer:addChild(cellLayout)
    cellLayout:setAnchorPoint(display.RIGHT_TOP)
    cellLayout:setPosition(cc.p(centerSize.width - 30 , centerSize.height -25 ))
    cellLayout.viewData.rewardBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    self.viewComponent.viewData.cellLayout = cellLayout
    self:UpdateCellStatus(self.rareIndex)
    for i = 1 , self.count  do
        if checkint(self.sortKey[i]) ~= checkint(self.rareIndex)   then
            local data = scoreRewardConfig[tostring(self.sortKey[i])]
            cellLayout = self.viewComponent:CreateTwoCell(data)
            cellLayout.viewData.rewardBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
            viewData.rewardList:insertNodeAtLast(cellLayout)
        end
    end
    viewData.rewardList:reloadData()
    for  i = 1 , self.count  do
        if checkint(self.sortKey[i]) ~= checkint(self.rareIndex)   then
           self:UpdateCellStatus(self.sortKey[i])
        end
    end
end

--[[
    更新cell 的显示
--]]
function SeasonnewYearPointRewardMediator:UpdateCellStatus(index)
    local node = nil
    local viewData = self.viewComponent.viewData
    -- 查找到对应的index的node 节点
    if checkint(index) == checkint(self.rareIndex)then
        node = viewData.cellLayout
    else
        local nodes =  viewData.rewardList:getNodes()
        local btn = nil
        local tag = nil
        for k ,v in pairs(nodes) do
            btn = v.viewData.rewardBtn
            tag = btn:getTag()
            if checkint(index) == tag then
                node = v
                break
            end
        end
    end
    local status = self:GetRewardStatusByIndex(index)
    if status ==  REWARD_STATUS.ALREADY_RECEIVE then
        node.viewData.rewardBtn:setNormalImage(_res('ui/common/activity_mifan_by_ico'))
        node.viewData.rewardBtn:setSelectedImage(_res('ui/common/activity_mifan_by_ico'))
        node.viewData.rewardBtn:setDisabledImage(_res('ui/common/activity_mifan_by_ico'))
        display.commonLabelParams(node.viewData.rewardBtn,fontWithColor('14',{text = __('已领取')}) )
        node.viewData.rewardBtn:setEnabled(false)
    elseif status ==  REWARD_STATUS.CAN_RECEIVE then
        node.viewData.rewardBtn:setEnabled(true)
    elseif status ==  REWARD_STATUS.CANNOT_RECEIVE then
        node.viewData.rewardBtn:setNormalImage(_res('ui/common/common_btn_orange_disable'))
        node.viewData.rewardBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable'))
        node.viewData.rewardBtn:setDisabledImage(_res('ui/common/common_btn_orange_disable'))
    end
end
--[[
    获取到积分的升序表的key
--]]
function SeasonnewYearPointRewardMediator:GetSorceReardsKeyBySortUp()
    local data = {}
    for i, v in pairs(scoreRewardConfig) do
        data[#data+1] = i
    end
    table.sort(data, function (a, b )
        if a <= b then
            return false
        end
        return true
    end)
    return data
end
--[[
    根据index 获取Cell 的状态
--]]
function SeasonnewYearPointRewardMediator:GetRewardStatusByIndex(index)
    if checkint(self.scoreRewardReceived[tostring(index)]) > 0 then
        return  REWARD_STATUS.ALREADY_RECEIVE
    else
        local newYearPoint = scoreRewardConfig[tostring(index)].newYearPoint
        if checkint(newYearPoint) <= self.newYearPoint then -- 可以领取
            return  REWARD_STATUS.CAN_RECEIVE
        else -- 不能领取
            return  REWARD_STATUS.CANNOT_RECEIVE
        end
    end
end
--[[
    传入的数组  , 字符串 ，返回加工后的数据
-- ]]
function SeasonnewYearPointRewardMediator:MergeTable(data, str)
    -- 转化为字符串
    str              = tostring(str)
    local spliteData = table.split(str, ",")
    for k, v in pairs(spliteData) do
        data[v] = checkint(data[v]) + 1
    end
    return data
end


--[[
统一绑定事件
--]]
function SeasonnewYearPointRewardMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if self.newYearPoint < checkint(scoreRewardConfig[tostring(tag)].newYearPoint)  then
        uiMgr:ShowInformationTips(__("压岁钱不足"))
        return
    end
    if tag == checkint(self.maxIndex)  then
        ---@type GameManager
        local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
        local isFirstOpen = cc.UserDefault:getInstance():getBoolForKey(string.format("%s_SEASOING_LIVE_END" , tostring(gameMgr:GetUserInfo().playerId) ), true)
        if isFirstOpen then
            local storyStage = require('Frame.Opera.OperaStage').new({id = checkint(4), path = string.format("conf/%s/seasonActivity/springStory.json",i18n.getLang()), guide = true, cb = function(sender)
                cc.UserDefault:getInstance():setBoolForKey(string.format("%s_SEASOING_LIVE_END" , tostring(gameMgr:GetUserInfo().playerId) ), false)
                cc.UserDefault:getInstance():flush()
                self:SendSignal(POST.SEASON_ACTIVITY_RECEIVESCOER_REWARD.cmdName ,{rewardId = tag})
            end})
            storyStage:setPosition(display.center)
            sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
        else
            self:SendSignal(POST.SEASON_ACTIVITY_RECEIVESCOER_REWARD.cmdName ,{rewardId = tag})
        end
    else
        self:SendSignal(POST.SEASON_ACTIVITY_RECEIVESCOER_REWARD.cmdName ,{rewardId = tag})

    end
end
--[[
    进入的时候材料副本的请求
--]]
function SeasonnewYearPointRewardMediator:EnterLayer()

end

function SeasonnewYearPointRewardMediator:OnRegist()
    regPost(POST.SEASON_ACTIVITY_RECEIVESCOER_REWARD)
end

function SeasonnewYearPointRewardMediator:OnUnRegist()
    self:GetFacade():DispatchObservers(ALREADY_RECEIVE_NEW_YEAR_POINT_EVENT,
                   {scoreRewardReceived = self.scoreRewardReceived , newYearPoint = self.newYearPoint, isChange = self.isChange })

    unregPost(POST.SEASON_ACTIVITY_RECEIVESCOER_REWARD)
    if self.viewComponent and (not tolua.isnull(self.viewComponent) ) then
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
end
return SeasonnewYearPointRewardMediator



