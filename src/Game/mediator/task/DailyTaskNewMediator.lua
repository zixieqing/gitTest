--[[
    日常任务Mediator
]]
local Mediator = mvc.Mediator
local DailyTaskNewMediator = class("DailyTaskNewMediator", Mediator)

local NAME = "task.DailyTaskNewMediator"
DailyTaskNewMediator.NAME = NAME

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local GoodNode         = require('common.GoodNode')
local TaskCellNode     = require('home.TaskCellNode')
local DailyTaskNewView = require('Game.views.task.DailyTaskNewView')

local TAB_TAG = {
    DAILY           = 1001,     -- 日常任务
    ACHIEVEMENT     = 1002,     -- 成长任务
}

function DailyTaskNewMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)

    self.taskDatas = {}--每日任务数据
    self.dailyActivenessDatas = {}--每日活跃度任务数据
    

    self.rewardsLayer = 10000

    self.viewTag           = self.ctorArgs_.viewTag

end

-------------------------------------------------
-- inheritance method

function DailyTaskNewMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    
    -- create view
    local view = DailyTaskNewView.new()
    self.viewData_ = view:getViewData()
    self:SetViewComponent(view)
    
    -- init view
    self:initView()
end

function DailyTaskNewMediator:initData(body)
    
    self:initTaskDatas(body)

    sortByMember(self.taskDatas, "sortIndex", true)

    self.dailyActivenessDatas.list = checktable(body.activePointRewards)
    self.dailyActivenessDatas.activePoint = checkint(body.activePoint)
end

function DailyTaskNewMediator:initTaskDatas(body)
    self.taskDatas = {}
    self.isOpenMoudle = app.passTicketMgr:CheckOpenModuleByModuleId(app.passTicketMgr.MODULE_TYPE.DAILY_TASK)
    if self.isOpenMoudle then
        -- self.passTicketConf = CommonUtils.GetConfig('goods', "money", PASS_TICKET_ID)
    end
    for i,task in ipairs(body.tasks or {}) do
        if task.hasDrawn == 0 then
            if checkint(task.progress) >= checkint(task.targetNum) then
                task.sortIndex = 1
            else
                task.sortIndex = 2
            end

            table.insert(self.taskDatas, task)
        end
    end
end

function DailyTaskNewMediator:initView()
    local viewData = self:getViewData()
    local boxs = self:getViewData().boxs
    for k, v in pairs(boxs) do
        v:setOnClickScriptHandler(handler(self,self.onLivenessRewardActions))
    end

    local taskListView = self:getViewData().taskListView
    taskListView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSource))

    local oneKeyReceiveBtn = viewData.oneKeyReceiveBtn
    display.commonUIParams(oneKeyReceiveBtn, {cb = handler(self, self.oneKeyReceiveBtnAction)})
end

function DailyTaskNewMediator:CleanupView()
    
end


function DailyTaskNewMediator:OnRegist()
    local DailyTaskCommand = require( 'Game.command.DailyTaskCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_DailyTask, DailyTaskCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_DailyTask_Get, DailyTaskCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_DailyTask_ActiveGet, DailyTaskCommand)

    self:enterLayer()

end
function DailyTaskNewMediator:OnUnRegist()
    app.gameMgr:GetUserInfo().dailyTaskCacheData_.isRequestDailyTask = false
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_DailyTask)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_DailyTask_Get)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_DailyTask_ActiveGet)
end

function DailyTaskNewMediator:InterestSignals()
    return {
        SIGNALNAMES.DailyTask_Message_Callback,
		SIGNALNAMES.DailyTask_Get_Callback,
        SIGNALNAMES.DailyTask_ActiveGet_Callback,
        SGL.FRESH_DAILY_TASK_VIEW,
		-- GET_MONEY_CALLBACK,--使用砸金蛋后刷新相关任务进度
    }
end

function DailyTaskNewMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = checktable(signal:GetBody())

    if name == SIGNALNAMES.DailyTask_Message_Callback then
        app.gameMgr:GetUserInfo().dailyTaskCacheData_.isRequestDailyTask = true
        app.badgeMgr:refreshDailyTaskCacheData(body)
        self:refreshUI(body)
       
    elseif name == SIGNALNAMES.DailyTask_Get_Callback then
        PlayAudioClip(AUDIOS.UI.ui_dailymission.id)

        local rewards = body.rewards or {}
        
        if body.activePoint and checkint(body.activePoint) > 0 then
			self.dailyActivenessDatas.activePoint = checkint(body.activePoint)
		end

        local requestData = body.requestData
        local taskId = requestData.taskId
        local taskIds = {}
        if taskId == -1 then
            gameMgr:GetUserInfo().dailyTaskCacheData_.daily = 0
            local taskList = {}
            for i, taskData in ipairs(self.taskDatas) do
                if checkint(taskData.hasDrawn) == 0 and checkint(taskData.progress) >= checkint(taskData.targetNum) then
                    table.insert(taskIds, taskData.id)
                else
                    table.insert(taskList, taskData)
                end
            end
            self.taskDatas = taskList
            self:SendSignal(COMMANDS.COMMAND_DailyTask)
        else
            table.insert(taskIds, taskId)
            gameMgr:GetUserInfo().dailyTaskCacheData_ = gameMgr:GetUserInfo().dailyTaskCacheData_ or {}
            gameMgr:GetUserInfo().dailyTaskCacheData_.daily = checkint(gameMgr:GetUserInfo().dailyTaskCacheData_.daily) - 1
            table.remove(self.taskDatas, self.tag)
            self:updateView()
            self:updateRedPoint()
        end
        
        if nil ~= app.passTicketMgr and nil ~= app.passTicketMgr.UpdateExpByTask then
            -- app.passTicketMgr:UpdateExpByTask(app.passTicketMgr.MODULE_TYPE.DAILY_TASK, taskIds)
            local point = app.passTicketMgr:GetTaskPointByModuleId(app.passTicketMgr.MODULE_TYPE.DAILY_TASK, taskIds)
            if point > 0 then
                table.insert(rewards, {goodsId = PASS_TICKET_ID, num = point})
            end
        end

        uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, mainExp = body.mainExp, tag = self.rewardsLayer, closeCallback = function ()
            local level = app.gameMgr:GetUserInfo().level
            local expDatas = CommonUtils.GetConfigAllMess('level', 'player')
            if expDatas then
                local keys = sortByKey(expDatas)
                local maxLevel = checkint(keys[#keys])
                if level >= maxLevel then
                    app.passTicketMgr:ShowUppgradeLevelView()
                end
            end
        end})

    elseif name == SIGNALNAMES.DailyTask_ActiveGet_Callback then
        PlayAudioClip(AUDIOS.UI.ui_dailymission.id)
        self.dailyActivenessDatas.list[self.activenessTag].hasDrawn = 1

		local viewData = self:getViewData()
        local box = viewData.boxs[self.activenessTag]
        local spBox = box:getChildByName('spBox')
        if box:getChildByName('particle') then
			box:getChildByName('particle'):removeFromParent()
        end
        
        spBox:setAnimation(0, 'play', true)
        spBox:setColor(cc.c3b(100, 100, 100))
        
        local rewards = body.rewards
        if not rewards then rewards = {} end
        if body.mainExp then
            local deltaExp = checkint(body.mainExp) - gameMgr:GetUserInfo().mainExp
            table.insert(rewards, {goodsId = EXP_ID, num = deltaExp})
        end
        local delayFuncList_ = CommonUtils.DrawRewards(rewards, true)

		local view = self.viewComponent.viewData_.bgView

		uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, addBackpack = false, delayFuncList_ = delayFuncList_})

	    self.dailyActivenessCount = self:GetViewComponent():updateLivenessUI(self.dailyActivenessDatas)
        gameMgr:GetUserInfo().dailyTaskCacheData_.activePoint = self.dailyActivenessCount
        self:updateRedPoint()
        
    elseif name == SGL.FRESH_DAILY_TASK_VIEW then
        self:refreshUI(body)
    elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
        if checkint(body.type) == PAY_TYPE.PT_PASS_TICKET then
            self:GetViewComponent():updateListUI(self.taskDatas)
        end
    end
    
end

function DailyTaskNewMediator:enterLayer()
    self:SendSignal(COMMANDS.COMMAND_DailyTask)
end

function DailyTaskNewMediator:refreshUI(body)
    self.isControllable_ = false
    self:initData(checktable(body))

    self:updateView()

    self:updateRedPoint()
    self.isControllable_ = true
end

--==============================--
--desc: 刷新每日任务界面
--time:2018-01-05 03:25:00
--@return 
--==============================-- 
function DailyTaskNewMediator:updateView()
    
	self:GetViewComponent():updateListUI(self.taskDatas)

    gameMgr:GetUserInfo().dailyTaskCacheData_.activePoint = self:GetViewComponent():updateLivenessUI(self.dailyActivenessDatas)

end

function DailyTaskNewMediator:updateRedPoint()
    self:GetFacade():DispatchObservers('TASK_UPDATE_EXTERNAL_TAB_RED_POINT', {viewTag = self.viewTag})
end

function DailyTaskNewMediator:onDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    local data = self.taskDatas[index]
    local pButton = nil
    if pCell == nil then
        local bg = self:getViewData().taskListView
        pCell = CGridViewCell:new()
        local size = bg:getSizeOfCell()
        pCell:setContentSize(size)
        
        pButton = TaskCellNode.new({size = cc.size(size.width,  size.height)})
        pButton:setName('pButton')
        pButton:setAnchorPoint(cc.p(1,0.5))
        pButton:setPosition(cc.p(size.width ,size.height*0.5))
        pCell:addChild(pButton,1)

        pButton.viewData.button:setOnClickScriptHandler(handler(self,self.onCellButtonAction))
    else
        pButton = pCell:getChildByName('pButton')
    end

    xTry(function()
        pButton:refreshUI(data)
        local viewData = pButton.viewData
        local view = viewData.view
        viewData.button:setTag(index)
        view:removeChildByName('GOODS_VIEW')

        local rewards = checktable(data.rewards)
        if next(rewards) ~= nil then
            local goodsView = CLayout:create(view:getContentSize())
            goodsView:setName('GOODS_VIEW')
            goodsView:setPosition(utils.getLocalCenter(view))
            view:addChild(goodsView, 5)
            local maxRewardCount = 0
            for i,v in ipairs(data.rewards) do
                maxRewardCount = maxRewardCount + 1
                local function callBack(sender)
                    uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
                end
                local goodsNode = GoodNode.new({id = v.goodsId, amount = v.num, showAmount = true, callBack = callBack})
                goodsNode:setPosition(cc.p(view:getContentSize().width/2 + 50  + 100*(i-1), pButton.viewData.view:getContentSize().height/2))
                goodsNode:setScale(0.75)
                goodsView:addChild(goodsNode, 5)
            end

            -- local isOpenMoudle = app.passTicketMgr:CheckOpenModuleByModuleId(app.passTicketMgr.MODULE_TYPE.DAILY_TASK)
            if self.isOpenMoudle then
                local goodsNode = app.passTicketMgr:CreatePassTicketNode(app.passTicketMgr.MODULE_TYPE.DAILY_TASK, data.id)
                if goodsNode then
                    goodsNode:setPosition(cc.p(view:getContentSize().width/2 + 50  + 100*(maxRewardCount), pButton.viewData.view:getContentSize().height/2))
                    goodsNode:setScale(0.75)
                    goodsView:addChild(goodsNode, 5)
                end
            end
        end
    end,__G__TRACKBACK__)
    return pCell
end

function DailyTaskNewMediator:onCellButtonAction(sender)
    if not self.isControllable_ then return end
    local scene = uiMgr:GetCurrentScene()
    if  scene:GetDialogByTag( self.rewardsLayer) then
		return
    end
    local tag = sender:getTag()
    self.tag = tag
    
    local data = self.taskDatas[tag]
    if data then
		if checkint(data.progress) >= checkint(data.targetNum) then
            self:SendSignal(COMMANDS.COMMAND_DailyTask_Get,{taskId = checkint(data.id)})
		end
	end
end

function DailyTaskNewMediator:onLivenessRewardActions(sender)
    if not self.isControllable_ then return end
    local tag = sender:getTag()

    self.activenessTag = tag
    local data = self.dailyActivenessDatas.list[tag]
    if data.hasDrawn == 0 then
		if checkint(self.dailyActivenessDatas.activePoint) < data.activePoint then
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconIds = data.rewards, type = 4})
		else
			self:SendSignal(COMMANDS.COMMAND_DailyTask_ActiveGet,{activePoint = data.activePoint})
		end
	else
		uiMgr:ShowInformationTipsBoard({targetNode = sender, iconIds = data.rewards, type = 4})
	end
end

function DailyTaskNewMediator:oneKeyReceiveBtnAction()
    if not self.isControllable_ then return end
    local isCanReceive = checkint(gameMgr:GetUserInfo().dailyTaskCacheData_.daily) > 0 or checkint(gameMgr:GetUserInfo().dailyTaskCacheData_.activePoint) > 0
	if isCanReceive then
		self:SendSignal(COMMANDS.COMMAND_DailyTask_Get, {taskId = -1})
	else
		uiMgr:ShowInformationTips(__('没有可领取的奖励'))
	end
end

-------------------------------------------------
-- get / set

function DailyTaskNewMediator:getViewData()
    return self.viewData_
end

return DailyTaskNewMediator