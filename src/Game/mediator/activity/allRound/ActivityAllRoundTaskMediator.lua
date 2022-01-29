--[[
 * author : liuzhipeng
 * descpt : 活动 全能活动 任务Mediator
--]]
local ActivityAllRoundTaskMediator = class('ActivityAllRoundTaskMediator', mvc.Mediator)
local NAME = 'Game.mediator.activity.allRound.ActivityAllRoundTaskMediator'
local uiMgr =  app.uiMgr
local gameMgr = app.gameMgr
local BUTTON_TAG                    = {
    CLOSE_VIEW = 11001 ,
    TIP_BUTTON = 11002 ,
}

function ActivityAllRoundTaskMediator:ctor(param, viewComponent)
    self.super:ctor(NAME, viewComponent)
    self.isGoto = false
    self.routeData = clone(param.routeData)
    self.activityId = param.activityId
    self.tasksList = self.routeData.tasks
    self:SortFunction()
end

function ActivityAllRoundTaskMediator:InterestSignals()
    local signals = {
        POST.ACTIVITY_ALLROUND_TASK_DRAW.sglName ,
    }
    return signals
end

function ActivityAllRoundTaskMediator:ProcessSignal(signal)
    local data  = signal:GetBody()
    local name = signal:GetName()
    if name == POST.ACTIVITY_ALLROUND_TASK_DRAW.sglName then
        self:DrawTaskRequestCallBack(data)
    end

end
function ActivityAllRoundTaskMediator:DrawTaskRequestCallBack(data)
    uiMgr:AddDialog('common.RewardPopup', data)
    local requestData = data.requestData
    local taskId = requestData.taskId
    local index = 0
    for k, v in pairs(self.tasksList) do
        if checkint(v.taskId) == checkint(taskId) then
            v.hasDrawn = 1
            break
        end
    end
    self:GetFacade():DispatchObservers( "ACTIVITY_ALL_ROUND_TASK_DRAW_EVENT", { pathId = self.routeData.routeId , taskId = taskId })
    self:SortFunction()
    ---@type AllRoundModuleTaskView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    viewData.tableView:reloadData()
end

function ActivityAllRoundTaskMediator:SortFunction()
    table.sort(self.tasksList , function(aTaskData , bTaskData)
        local isTrue  = true
        if checkint(aTaskData.hasDrawn) ==  checkint(bTaskData.hasDrawn) then
            if  checkint(aTaskData.hasDrawn)  == 1 then
                if checkint(aTaskData.taskId) >= checkint(bTaskData.taskId)  then
                     isTrue = false
                else
                    isTrue = true
                end
            else
                local aReady = 0
                local bReady = 0
                if checkint(aTaskData.progress)  >=  checkint(aTaskData.targetNum) then
                    aReady = 1
                end
                if checkint(bTaskData.progress)  >=  checkint(bTaskData.targetNum) then
                    bReady = 1
                end
                if aReady == bReady  then
                    if checkint(aTaskData.taskId) >= checkint(bTaskData.taskId)  then
                        isTrue = false
                    else
                        isTrue = true
                    end
                else
                    isTrue = aReady > bReady and true or false
                end
            end
        else
            if checkint(aTaskData.hasDrawn) >  checkint(bTaskData.hasDrawn)  then
                isTrue = false
            else
                isTrue = true
            end
        end
        return isTrue
    end)
end
function ActivityAllRoundTaskMediator:Initial(key)
    self.super.Initial(self, key)
    ---@type AllRoundModuleTaskView
    local viewComponent = require('Game.views.activity.allRound.ActivityAllRoundTaskView').new()
    self:SetViewComponent(viewComponent)
    uiMgr:GetCurrentScene():AddDialog(viewComponent)
    viewComponent:setPosition(display.center)
    local viewData = viewComponent.viewData
    local closeLayout = viewData.closeLayout
    closeLayout:setTag(BUTTON_TAG.CLOSE_VIEW)
    display.commonUIParams(closeLayout , { cb = handler(self, self.ButtonAction)})
    self:UpdateUI()
end

function ActivityAllRoundTaskMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if tag == BUTTON_TAG.CLOSE_VIEW  then
        self:GetFacade():UnRegsitMediator(NAME)
    end
end

function ActivityAllRoundTaskMediator:UpdateUI()
    ---@type AllRoundModuleTaskView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local tableView = viewData.tableView
    local RES_DICT = {
        ALLROUND_ICO_BOOK_1     = _res('ui/home/allround/allround_ico_book_1.png'),
        ALLROUND_ICO_BOOK_2     = _res('ui/home/allround/allround_ico_book_2.png'),
        ALLROUND_ICO_BOOK_3     = _res('ui/home/allround/allround_ico_book_3.png'),
        ALLROUND_ICO_BOOK_4     = _res('ui/home/allround/allround_ico_book_4.png'),
    }
    local moduleTable = {
        {tag = 1, name = __('养成路线') , image = RES_DICT.ALLROUND_ICO_BOOK_4 ,pos = cc.p(display.cx + 407, display.cy + -148)},
        {tag = 2, name = __('战斗路线') , image = RES_DICT.ALLROUND_ICO_BOOK_3 ,pos = cc.p(display.cx + 452, display.cy + 228)},
        {tag = 3, name = __('经营路线') , image = RES_DICT.ALLROUND_ICO_BOOK_1 ,pos = cc.p(display.cx + -412, display.cy + 120)},
        {tag = 4, name = __('堕神路线') , image = RES_DICT.ALLROUND_ICO_BOOK_2 ,pos = cc.p(display.cx + -331, display.cy + -198)}
    }
    viewData.moduleImage:setTexture( moduleTable[ checkint(self.routeData.routeId)].image)
    display.commonLabelParams(viewData.moduleName , fontWithColor(14, {text = moduleTable[ checkint(self.routeData.routeId)].name }))
    tableView:setCountOfCell(#self.tasksList+1)
    tableView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
    tableView:reloadData()
end
function ActivityAllRoundTaskMediator:OnDataSource(cell , idx)
    local index = idx +1
    local taskData = self.tasksList[index] or {}
    local taskId = taskData.taskId
    local sizee =  cc.size(883,140)
    xTry(function()
        if not cell then
            ---@type AllRoundModuleTaskView
            local viewComponent  = self:GetViewComponent()
            cell = CTableViewCell:new()
            cell:setContentSize(sizee)
            local listCell =viewComponent:CreateListCell()
            listCell:setName("listCell")
            listCell:setPosition(sizee.width/2 , sizee.height/2 )
            cell:addChild(listCell)
            local viewData = listCell.viewData
            display.commonUIParams(viewData.rewardBtn , {cb = handler(self, self.DrawTaskRewards ) , animate = false})
        end
        if   table.nums(taskData) ==  0  then
            cell:setVisible(false)
            return cell
        else
            cell:setVisible(true)
        end
        local progress = checkint(taskData.progress)
        local targetNum = checkint(taskData.targetNum)
        local hasDrawn = checkint(taskData.hasDrawn)
        local difficulty = taskData.difficulty
        local rewards = taskData.rewards
        local listCell = cell:getChildByName("listCell")
        local viewData = listCell.viewData
        local rewardLayout = viewData.rewardLayout
        local prorassLabel = viewData.prorassLabel
        local completeConditions = viewData.completeConditions
        local prograssImage = viewData.prograssImage
        local barImage = viewData.barImage
        local underCellImage = viewData.underCellImage
        local alreadyRewardImage = viewData.alreadyRewardImage
        local rewardBtn = viewData.rewardBtn
        --local topCellImage = viewData.topCellImage
        underCellImage:setVisible(false)
        alreadyRewardImage:setVisible(false)
        --topCellImage:setVisible(false)
        rewardLayout:removeAllChildren()
        rewardBtn:setTag(index)
        rewardBtn:setVisible(true)
        for i, v in pairs(rewards) do
            local data = clone(v )
            data.showAmount = true
            local goodNode = require('common.GoodNode').new(data)
            goodNode:setPosition(80 * (i - 0.5 ) , 40 )
            goodNode:setScale(0.7)
            display.commonUIParams(goodNode , {animate = false ,  cb = function(sender)
               uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
            end})
            rewardLayout:addChild(goodNode)
        end
        display.commonLabelParams(prorassLabel , {text = string.format('%d/%d' , checkint(progress) , checkint(targetNum)) })
        if checkint(taskData.showProgress)   == 1 then
            prograssImage:setMaxValue(targetNum)
            prograssImage:setValue(progress)
            prograssImage:setVisible(true)
            prorassLabel:setVisible(true)
            barImage:setVisible(true)
        else
            prograssImage:setVisible(false)
            prorassLabel:setVisible(false)
            barImage:setVisible(false)
        end
        local descr = CommonUtils.GetTaskDescrByTaskData(taskData)
        display.commonLabelParams(completeConditions , {text =  descr ,reqW = 360 })
        if hasDrawn == 1 then
            alreadyRewardImage:setVisible(true)
            underCellImage:setVisible(true)
            rewardBtn:setVisible(false)
        else
            if checkint(progress) >= targetNum then
                underCellImage:setVisible(true)
                --topCellImage:setVisible(true)
                rewardBtn:setVisible(true)
                rewardBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
                rewardBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
                rewardBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
                display.commonLabelParams(rewardBtn , {text = __('领取')})
                display.commonUIParams(viewData.rewardBtn , {cb = handler(self, self.DrawTaskRewards ) , animate = false})
            else

                underCellImage:setVisible(true)
                local taskType = taskData.taskType
                if CommonUtils.GetTaskJumpModuleConfig()[tostring(taskType)]  then
                    rewardBtn:setVisible(true)
                    rewardBtn:setNormalImage(_res('ui/common/common_btn_white_default.png'))
                    rewardBtn:setSelectedImage(_res('ui/common/common_btn_white_default.png'))
                    rewardBtn:setSelectedImage(_res('ui/common/common_btn_white_default.png'))
                    display.commonLabelParams(rewardBtn, {text = __('去完成')})
                    display.commonUIParams(viewData.rewardBtn , {cb = handler(self, self.DrawTaskRewards ) , animate = true})
                else
                    rewardBtn:setNormalImage(_res('ui/common/common_btn_orange_disable'))
                    rewardBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable'))
                    rewardBtn:setDisabledImage(_res('ui/common/common_btn_orange_disable'))
                    display.commonLabelParams(rewardBtn, {text = __('领取')})
                    display.commonUIParams(viewData.rewardBtn , {cb = handler(self, self.DrawTaskRewards ) , animate = true})
                end
            end
        end
    end,__G__TRACKBACK__)
    return cell
end
function ActivityAllRoundTaskMediator:TaskCallBack(sender)
    if self.isGoto then
        return
    end
    local tag = sender:getTag()
    local taskData = self.tasksList[tag]
    -- 跳转
    app:UnRegsitMediator(NAME)
    CommonUtils.JumpModuleByTaskData(taskData)
    sceneWorld:runAction(
        cc.Sequence:create(
            cc.CallFunc:create(function()
                self.isGoto = true
            end),
            cc.DelayTime:create(2) ,
            cc.CallFunc:create(function()
                self.isGoto = false
            end)
        )
)
end
function ActivityAllRoundTaskMediator:DrawTaskRewards(sender)
    local tag = sender:getTag()
    local taskData = self.tasksList[tag]
    local progress = checkint(taskData.progress)
    local targetNum = checkint(taskData.targetNum)
    if progress >= targetNum then
        self:SendSignal(POST.ACTIVITY_ALLROUND_TASK_DRAW.cmdName , {activityId = self.activityId, taskId = taskData.taskId  })
    else
        self:TaskCallBack(sender)
    end
end
function ActivityAllRoundTaskMediator:OnRegist()
    regPost(POST.ACTIVITY_ALLROUND_TASK_DRAW)
end
function ActivityAllRoundTaskMediator:OnUnRegist()
    unregPost(POST.ACTIVITY_ALLROUND_TASK_DRAW)
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return ActivityAllRoundTaskMediator