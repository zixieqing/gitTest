--[[
 * author : panmeng
 * descpt : 皮肤收集 - 收集任务
]]

local SkinCollectionTaskView     = require('Game.views.collection.skinCollection.SkinCollectionTaskView')
local SkinCollectionTaskMediator = class('SkinCollectionTaskMediator', mvc.Mediator)

function SkinCollectionTaskMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SkinCollectionTaskMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

SkinCollectionTaskMediator.SKIN_TYPE_ALL = 0 -- 为所有

-------------------------------------------------
-- inheritance

function SkinCollectionTaskMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = SkinCollectionTaskView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    self:getViewData().taskTableView:setCellUpdateHandler(handler(self, self.onTaskCellUpdateHandler_))
    self:getViewData().taskTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.receiveBtn, handler(self, self.onClickReceiveBtnHandler_), false)
    end)

    -- set homeData
    self:initHomeData_(self.ctorArgs_.taskData)
end


function SkinCollectionTaskMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function SkinCollectionTaskMediator:OnRegist()
    regPost(POST.CARD_SKIN_COLLECT_DRAW_TASK)
end


function SkinCollectionTaskMediator:OnUnRegist()
    unregPost(POST.CARD_SKIN_COLLECT_DRAW_TASK)
end


function SkinCollectionTaskMediator:InterestSignals()
    return {
        POST.CARD_SKIN_COLLECT_DRAW_TASK.sglName
    }
end
function SkinCollectionTaskMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.CARD_SKIN_COLLECT_DRAW_TASK.sglName then
        local taskData = checktable(self.displayedTaskData[checkint(self.selectedTaskIndex)])
        if not self.ctorArgs_.taskData.rewardIds then
            self.ctorArgs_.taskData.rewardIds = {}
        end
        app.cardMgr:setCardSkinCollTaskCompleted(checkint(taskData.taskId), checkint(taskData.groupId))
        self:updateTaskPage()

        app.uiMgr:AddDialog('common.RewardPopup', {rewards = data.rewards})
    end
end


-------------------------------------------------
-- get / set

function SkinCollectionTaskMediator:getViewNode()
    return  self.viewNode_
end
function SkinCollectionTaskMediator:getViewData()
    return self:getViewNode():getViewData()
end

-------------------------------------------------
-- public

function SkinCollectionTaskMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())

    if self.ctorArgs_.closeCb then
        self.ctorArgs_.closeCb()
    end
end


-------------------------------------------------
-- private

function SkinCollectionTaskMediator:initHomeData_(homeData)
    self:updateTaskPage()
end

function SkinCollectionTaskMediator:updateTaskPage()
    self.displayedTaskData = {}

    if next(app.cardMgr:getOnGoingCardCollTaskMap()) then
        for groupId, taskId in pairs(app.cardMgr:getOnGoingCardCollTaskMap()) do
            local taskConf   = CONF.CARD.SKIN_COLL_TASK:GetValue(taskId)
            local currentNum = app.cardMgr:getCardSkinCollNumByType(checkint(taskConf.targetId))
            local canGet     = checkint(currentNum) >= checkint(taskConf.targetNum)
            table.insert(self.displayedTaskData, {taskId = checkint(taskId), isFinish = false, groupId = checkint(groupId), canGet = canGet, currentNum = currentNum})
        end
    end

    if next(app.cardMgr:getCardSkinCollTaskCompletedMap()) ~= nil then
        for groupId, taskIds in pairs(app.cardMgr:getCardSkinCollTaskCompletedMap()) do
            for taskId, _ in pairs(taskIds) do
                table.insert(self.displayedTaskData, {taskId = checkint(taskId), isFinish = true, groupId = checkint(groupId)})
            end
        end
    end

    if #self.displayedTaskData > 1 then
        table.sort(self.displayedTaskData, function(taskDataA, taskDataB)
            if taskDataA.isFinish ~= taskDataB.isFinish then
                return taskDataB.isFinish
            end

            if taskDataA.isFinish == false then
                if taskDataA.canGet ~= taskDataB.canGet then
                    return taskDataA.canGet
                end
            end
            return checkint(taskDataA.taskId) < checkint(taskDataB.taskId)
        end)
    end

    self:getViewData().taskTableView:resetCellCount(#self.displayedTaskData)
end


function SkinCollectionTaskMediator:onTaskCellUpdateHandler_(cellIndex, cellViewData)
    local taskData = self.displayedTaskData[checkint(cellIndex)]
    self:getViewNode():updateTaskCell(cellIndex, cellViewData, checktable(taskData))
end


-------------------------------------------------
-- handler

function SkinCollectionTaskMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end



function SkinCollectionTaskMediator:onClickReceiveBtnHandler_(sender)
    self.selectedTaskIndex = checkint(sender:getTag())
    local taskData = self.displayedTaskData[self.selectedTaskIndex]

    -- check could get
    if taskData.canGet then
        self:SendSignal(POST.CARD_SKIN_COLLECT_DRAW_TASK.cmdName, {rewardId = checkint(taskData.taskId)})
    end
end

return SkinCollectionTaskMediator
