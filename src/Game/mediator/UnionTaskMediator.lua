--[[
 * descpt : 工会任务 中介者
]]
---@class UnionTaskMediator :Mediator
local NAME = 'UnionTaskMediator'
local VIEW_TAG = 110127
local UnionTaskMediator = class('UnionTaskMediator', mvc.Mediator)

local uiMgr    = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr  = AppFacade.GetInstance():GetManager("GameManager")
local dataMgr  = AppFacade.GetInstance():GetManager('DataManager')
local unionMgr =  AppFacade.GetInstance():GetManager("UnionManager")

local UNION_TASK_TYPE_CONFS = CommonUtils.GetConfigAllMess('taskType', 'union')

local sortfunction = nil

function UnionTaskMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)

    self.datas                 = {}
    self.canReceiveRewardCount = 0  -- 用于更新红点

    self.isTimeEnd = false
end


-------------------------------------------------
-- inheritance method

function UnionTaskMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true

    -- create view

    local data = {tag = VIEW_TAG, mediatorName = NAME, viewConfData = {tag = VIEW_TAG, title = __('工会任务'), isShowListTitle = false}}
    -- dump(data)
	local viewComponent = require('Game.views.ActivityPropExchangeListView').new(data)
	viewComponent:setTag(VIEW_TAG)
	display.commonUIParams(viewComponent, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	self:SetViewComponent(viewComponent)

    self.viewData_ = viewComponent:getViewData()

    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(viewComponent)

    self:initUi()
end

function UnionTaskMediator:initUi()
    local viewData = self:getViewData()

    local gridView = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSource))
end

function UnionTaskMediator:CleanupView()
end


function UnionTaskMediator:OnRegist()
    regPost(POST.UNION_TASK)
    regPost(POST.UNION_DRAWTASK)

    self:enterLayer()
end
function UnionTaskMediator:OnUnRegist()
    unregPost(POST.UNION_TASK)
    unregPost(POST.UNION_DRAWTASK)

    self:updateRedPoint()

    local scene = uiMgr:GetCurrentScene()
    if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then
        scene:RemoveDialog(self:GetViewComponent())
    end
end


function UnionTaskMediator:InterestSignals()
    return {
        POST.UNION_TASK.sglName,
        POST.UNION_DRAWTASK.sglName,

        UNION_TASK_FINISH_EVENT,   -- 工会任务完成
        UNION_TASK_REFRESH_EVENT,  -- 刷新工会任务
    }
end
function UnionTaskMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()

    if name == POST.UNION_TASK.sglName then
        self.isControllable_ = false

        self.datas = body.tasks or {}
        -- dump(self.datas, 'datasdatasdatasdatasdatasdatas')
        table.sort( self.datas, sortfunction )

        for i,v in ipairs(self.datas) do
            local taskTypeData = UNION_TASK_TYPE_CONFS[tostring(v.taskType)]
            if taskTypeData then
                local taskDesc = string.fmt(taskTypeData.descr, {_target_num_ = v.targetNum})
                v.taskName = string.format( "%s%s", v.taskName, taskDesc)
            end
            if checkint(v.hasDrawn) == 0 and checkint(v.progress) >= checkint(v.targetNum) then
                self.canReceiveRewardCount = self.canReceiveRewardCount + 1
            end
        end

        -- 更新红点
        self:updateRedPoint()
        -- 更新描述
        self:updateDescLabel(body)
        -- 更新列表状态
        self:GetViewComponent():initUiState()

        local gridView = self:getViewData().gridView
        local listLen = #self.datas
        if listLen <= 3 then
            gridView:setBounceable(false)
        end
        gridView:setCountOfCell(listLen)
        gridView:reloadData()

        self.isControllable_ = true
        self.isTimeEnd = false
    elseif name == POST.UNION_DRAWTASK.sglName then
        local rewards = body.rewards or {}
        if #rewards > 0 then
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
        end

        local requestData = checktable(body.requestData)
        local taskId = requestData.taskId

        -- 检查一下 现有数据中有没有 此任务ID
        local index = nil
        local data  = nil
        for i,v in ipairs(self.datas) do
            if v.taskId == taskId then
                index = i
                v.hasDrawn = 1
                data = v
                break
            end
        end

        -- 现有数据中没有此 taskid  则不处理 下面
        if index == nil then return end

        -- 更新红点
        self.canReceiveRewardCount = self.canReceiveRewardCount - 1

        self:updateCellByIndex(index, data)

    elseif name == UNION_TASK_FINISH_EVENT then
        self:enterLayer()
    elseif name == UNION_TASK_REFRESH_EVENT then
        self.canReceiveRewardCount = 0
        self.isTimeEnd = true
        self:enterLayer()
    end
end

-------------------------------------------------
-- get / set

function UnionTaskMediator:getViewData()
    return self.viewData_
end

-------------------------------------------------
-- public method


-------------------------------------------------
-- private method
function UnionTaskMediator:enterLayer()
    self:SendSignal(POST.UNION_TASK.cmdName)
end

function UnionTaskMediator:updateCellByIndex(index, data)
    local gridView = self:getViewData().gridView
    local cell = gridView:cellAtIndex(index - 1)
    if cell then
        local viewData       = cell.viewData

        local targetNum      = data.targetNum
        local progress       = data.progress
        local isSatisfy      = progress >= targetNum     -- 是否满足条件
        local isDrawn        = data.hasDrawn == 1        -- 是否领取过
        self:updateButtonState(viewData, isDrawn, isSatisfy)
    end
end

function UnionTaskMediator:updateRedPoint()
    if self.canReceiveRewardCount > 0 then
        unionMgr.unionTaskRed = 1
        dataMgr:AddRedDotNofication(tostring(RemindTag.UNION_TASK), RemindTag.UNION_TASK, "[工会]-UnionTaskMediator:updateRedPoint")
    else
        unionMgr.unionTaskRed = 0
        dataMgr:ClearRedDotNofication(tostring(RemindTag.UNION_TASK), RemindTag.UNION_TASK, "[工会]-UnionTaskMediator:updateRedPoint")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.UNION_TASK})
end

function UnionTaskMediator:updateDescLabel(body)
    local refreshTime       = body.refreshTime
    local contributionPoint = body.contributionPoint
    local refreshTimeData   = string.split(refreshTime, ':')
    local refreshTimeText   = l10nHours(refreshTimeData[1], refreshTimeData[2]):fmt('%H:%M')
    local descLabel         = self:getViewData().descLabel
    display.commonLabelParams(descLabel, {text = string.fmt(__('工会任务每天%1刷新进度，每完成一个工会任务可帮助工会增加%2点贡献值。'), refreshTimeText, contributionPoint)})
end

-------------------------------------------------
-- handler
function UnionTaskMediator:onDataSource(p_convertview, idx)
	local pCell = p_convertview
	local index = idx + 1

    if pCell == nil then
		pCell = self:GetViewComponent():CreateTaskCell(VIEW_TAG)

		local button = pCell.viewData.button
		display.commonUIParams(button, {cb = handler(self, self.onReceivedRewardAction)})
	end

	xTry(function()

        local data           = self.datas[index]
        local taskId         = data.taskId
        local taskName       = data.taskName or ''
        local targetNum      = checkint(data.targetNum)
        local progress       = checkint(data.progress)
        local hasDrawn       = data.hasDrawn
        local rewards        = data.rewards or {}

        local isSatisfy      = progress >= targetNum -- 是否满足条件
        local isDrawn        = hasDrawn == 1         -- 是否领取过

        local viewData           = pCell.viewData
		local descLabel          = viewData.descLabel
        local progressLabel      = viewData.progressLabel
        local propLayer          = viewData.propLayer
        local button             = viewData.button
        local alreadyReceived    = viewData.alreadyReceived

        -- 防止进度 远远大于 目标数
        progress = progress > targetNum and targetNum or progress

		display.commonLabelParams(descLabel,     {text = tostring(taskName)})
		display.commonLabelParams(progressLabel, {text = string.format('(%s/%s)', progress, targetNum)})
        local standerWidth= 630
		local descLabelSize = display.getLabelContentSize(descLabel)
        local progressLabelSize = display.getLabelContentSize(progressLabel)
        local countWidth = ( progressLabelSize.width +  descLabelSize.width)
        if countWidth > standerWidth  then
            local currentScale = descLabel:getScale()
            local  scale = currentScale  * standerWidth / countWidth
            progressLabel:setScale(scale)
            descLabel:setScale(scale)
            display.commonUIParams(progressLabel, {po = cc.p(descLabel:getPositionX() + descLabelSize.width * (standerWidth / countWidth) + 10, descLabel:getPositionY())})
        else
            display.commonUIParams(progressLabel, {po = cc.p(descLabel:getPositionX() + descLabelSize.width + 10, descLabel:getPositionY())})
        end


		propLayer:removeAllChildren()
		local callBack = function (sender)
			local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
		end

		local startX = descLabel:getPositionX()
		local goodNodeSize = nil
		local scale = 0.8
		for i,reward in ipairs(rewards) do
			local goodNode = require('common.GoodNode').new({id = reward.goodsId, amount = reward.num, showAmount = true, callBack = callBack})
			goodNode:setScale(scale)
			if goodNodeSize == nil then goodNodeSize = goodNode:getContentSize() end

			display.commonUIParams(goodNode, {ap = display.LEFT_CENTER, po = cc.p(startX + (i - 1) * (goodNodeSize.width * scale + 10), button:getPositionY())})
			propLayer:addChild(goodNode)
		end

        self:updateButtonState(viewData, isDrawn, isSatisfy)

		button:setTag(index)
	end,__G__TRACKBACK__)

	return pCell
 end


 function UnionTaskMediator:onReceivedRewardAction(sender)
    PlayAudioByClickNormal()
    if self.isTimeEnd then
        uiMgr:ShowInformationTips(__('任务正在刷新中'))
        return
    end
    if not self.isControllable_ then return end

    local index = sender:getTag()

    local data         = self.datas[index]
	local progress     = checkint(data.progress)
	local targetNum    = checkint(data.targetNum)

	if progress >= targetNum then
        local taskId       = data.taskId
        self:SendSignal(POST.UNION_DRAWTASK.cmdName, {taskId = taskId})
	else
		uiMgr:ShowInformationTips(__('未满足领取条件'))
	end

 end

 function UnionTaskMediator:updateButtonState(viewData, isDrawn, isSatisfy )
	local button             = viewData.button
	local alreadyReceived    = viewData.alreadyReceived

	button:setVisible(not isDrawn)
	alreadyReceived:setVisible(isDrawn)

	if not isDrawn then
		if isSatisfy then
			button:setNormalImage(_res('ui/common/common_btn_orange.png'))
			button:setSelectedImage(_res('ui/common/common_btn_orange.png'))
		else
			button:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
			button:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
		end
	end


end

sortfunction = function ( a, b )
    if a == nil then
        return true
    end
    if b == nil then
        return false
    end
    local aProgress = checkint(a.progress)
    local bProgress = checkint(b.progress)
    local aTargetNum = checkint(a.targetNum)
    local bTargetNum = checkint(b.targetNum)
    local aTaskId = checkint(a.taskId)
    local bTaskId = checkint(b.taskId)
    local aHasDrawn = checkint(a.hasDrawn)
    local bHasDrawn = checkint(b.hasDrawn)

    local aState = aProgress >= aTargetNum and 1 or 0
    local bState = bProgress >= bTargetNum and 1 or 0

    if aHasDrawn == bHasDrawn then
        if aState == bState then
            return aTaskId < bTaskId
        end
        return aState > bState
    end

    return checkint(a.hasDrawn) < checkint(b.hasDrawn)
end


return UnionTaskMediator
