--[[
    被召回7天任务Mediator
--]]
local Mediator = mvc.Mediator

local RecallDailyTaskMediator = class("RecallDailyTaskMediator", Mediator)

local NAME = "RecallDailyTaskMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end

function RecallDailyTaskMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.taskDatas = checktable(params) or {}
	self.clickTag = 1 -- 选中的右侧日期tab
	self.rewardSelectedTag = nil -- 选中的UR飨灵
	self.checkTaskFinish = {}--所在天数是否全部领取任务奖励
	self.TtimeUpdateFunc = nil --任务倒计时计时器
	self.rewardCells = {}
	if not self.taskDatas.veteranTasksDoneReward then
		self.taskDatas.veteranTasksDoneReward = {}
	end
	for i=1, math.min(self.taskDatas.veteranDayNum, table.nums(self.taskDatas.veteranTasks)) do
		local temp = {}
		temp.isAllDrawn = true
		local progress  = 0

		local tasks = self.taskDatas.veteranTasks[tostring(i)]
		for _,task in pairs(tasks) do
			if task.hasDrawn == 0 then -- 说明有未领取任务
				temp.isAllDrawn = false 
			else
				progress = progress  + 1
			end
		end

		temp.progress = progress
		temp.targetNum = table.nums(tasks)
		self.checkTaskFinish[tostring(i)] = temp

		table.sort(tasks, function(a, b)
			local function GetTaskIsFinish( task )
				return checkint(task.progress) >= checkint(task.targetNum)
			end
			if a.hasDrawn == b.hasDrawn then
				if GetTaskIsFinish(a) == GetTaskIsFinish(b) then
					return a.id < b.id
				else
					return GetTaskIsFinish(a)
				end
			else
				return 0 == a.hasDrawn -- 未领取
			end
	    end)
	end

	for i=1,table.nums(self.checkTaskFinish) do
		if self.checkTaskFinish[tostring(i)].isAllDrawn == false then
			self.clickTag = i
			break
		end
	end
	for i=1,math.min(self.taskDatas.veteranDayNum, table.nums(self.taskDatas.veteranTasks)) do
		local rewardAvailable = false
		local tasks = self.taskDatas.veteranTasks[tostring(i)]
		for _,task in pairs(tasks) do
			if checkint(task.progress) >= checkint(task.targetNum) and task.hasDrawn == 0 then
				self.clickTag = i
				rewardAvailable = true
				break
			end
		end
		if rewardAvailable then
			break
		end
	end
end

function RecallDailyTaskMediator:InterestSignals()
	local signals = { 
		RECALLED_TASK_TIME_UPDATE_EVENT,
		POST.RECALLED_TASK_DRAW.sglName ,
		POST.RECALLED_FINAL_REWARD_DRAW.sglName ,
	}

	return signals
end

function RecallDailyTaskMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	if name == RECALLED_TASK_TIME_UPDATE_EVENT then
		local leftSeconds = body.leftSeconds
		self:UpdateTimeLabel(leftSeconds)
	elseif name == POST.RECALLED_TASK_DRAW.sglName then
		uiMgr:AddDialog('common.RewardPopup', body)
		self.checkTaskFinish[tostring(self.clickTag)].isAllDrawn = true
		for _,task in pairs(self.taskDatas.veteranTasks[tostring(self.clickTag)]) do
			if task.id == body.requestData.taskId then
				task.hasDrawn = 1
			end
			if task.hasDrawn == 0 then -- 说明有未领取任务
				self.checkTaskFinish[tostring(self.clickTag)].isAllDrawn = false 
			end
		end
		self.checkTaskFinish[tostring(self.clickTag)].progress = self.checkTaskFinish[tostring(self.clickTag)].progress + 1
		for k,v in pairs(self.taskDatas.veteranTasks) do
			table.sort(v, function(a, b)
		    	local function GetTaskIsFinish( task )
					return checkint(task.progress) >= checkint(task.targetNum)
				end
				if a.hasDrawn == b.hasDrawn then
					if GetTaskIsFinish(a) == GetTaskIsFinish(b) then
						return a.id < b.id
					else
						return GetTaskIsFinish(a)
					end
				else
					return 0 == a.hasDrawn -- 未领取
				end
		    end)
		end
		self:updataview( self.clickTag )
		self.gridView:reloadData()

		local viewData = self.viewComponent.viewData_
		viewData.endRewardsBtn:setVisible(self:CheckAllTaskDrawn())

		AppFacade.GetInstance():DispatchObservers(RECALLED_TASK_DRAW_UI)
	elseif name == POST.RECALLED_FINAL_REWARD_DRAW.sglName then
		uiMgr:AddDialog('common.RewardPopup', body)
		self.taskDatas.veteranTasksDoneRewardDrawn = 1
		local viewData = self.viewComponent.viewData_
		viewData.endRewardsBtn:setVisible(true)
		viewData.endRewardsBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
		viewData.endRewardsBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))

		AppFacade.GetInstance():DispatchObservers(RECALLED_TASK_DRAW_UI)
    end
end

function RecallDailyTaskMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.RecallDailyTaskView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
    local viewData = viewComponent.viewData_
	
	self.gridView = viewData.gridView
	self.gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
	
	for i=1,table.nums(self.taskDatas.veteranTasks) do
		viewComponent:CreateTab(i)
	end
	self:updataview()

	for k, v in pairs( viewData.buttons ) do
		v:setOnClickScriptHandler(handler(self,self.ButtonActions))
		if checkint(k) == self.clickTag then
			self:ButtonActions( checkint(k) )
		end
	end

	for i=1,table.nums(self.taskDatas.veteranTasksDoneReward) do
		local pCell = require('home.BackpackCell').new()
        pCell:setPosition(cc.p( 26 + (i - 1) % 3 * 98, 154 - math.floor(i / 4) * 100))
        viewData.view:addChild(pCell, 10)
		pCell:setScale(0.8)
		
		local iconPath = CommonUtils.GetGoodsIconPathById(self.taskDatas.veteranTasksDoneReward[i].goodsId)
		pCell.goodsImg:setTexture(_res(iconPath))
		pCell.goodsImg:setVisible(true)

		pCell.maskImg:setScale(0.95)

		pCell.toggleView:setNormalImage(_res('ui/common/common_frame_goods_5'))
		pCell.toggleView:setSelectedImage(_res('ui/common/common_frame_goods_5'))
		pCell.toggleView:setTag(i)

		pCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))

		pCell.selectImg:setScale(0.95)
		table.insert( self.rewardCells, pCell )
	end
	self:CellButtonAction(1)

	-- 所有回归任务的奖励领取状态
	if 0 == self.taskDatas.veteranTasksDoneRewardDrawn then -- 未领取
		viewData.endRewardsBtn:setVisible(self:CheckAllTaskDrawn())
	else
		viewData.endRewardsBtn:setVisible(true)
		viewData.endRewardsBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
		viewData.endRewardsBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
	end
	viewData.endRewardsBtn:setOnClickScriptHandler(handler(self,self.onClickEndRewardButtonHandler))

	self:UpdateTimeLabel(self.taskDatas.veteranTaskEndLeftSeconds)
end

function RecallDailyTaskMediator:UpdateTimeLabel( leftSeconds )
	local viewData = self.viewComponent.viewData_
	if checkint(leftSeconds) <= 0 then
		viewData.timeLabel:setString('00:00:00')
	else
		if checkint(leftSeconds) <= 86400 then
			viewData.timeLabel:setString(string.formattedTime(checkint(leftSeconds),'%02i:%02i:%02i'))
		else
			local day = math.floor(checkint(leftSeconds)/86400)
			local hour = math.floor((leftSeconds - day * 86400) / 3600)
			viewData.timeLabel:setString(string.fmt(__('_day_天_hour_小时'),{_day_ = day, _hour_ = hour}))
		end
	end
end

function RecallDailyTaskMediator:OnDataSourceAction( p_convertview,idx )
	local pCell = p_convertview
    local index = idx + 1
    local taskNode = nil
    local tempBtn = nil
	local cellSize = self.gridView:getSizeOfCell()
	if nil ==  pCell  then
		pCell = CGridViewCell:new()
		pCell:setContentSize(cellSize)
		taskNode = require('home.TaskCellNode').new({size = cellSize})
		taskNode:setTag(2345)
		taskNode:setPosition(cc.p(cellSize.width * 0.5 - 5 ,cellSize.height * 0.5 - 4 ))
		pCell:addChild(taskNode)

		taskNode.goodsIcon = {}
		taskNode.viewData.button:setOnClickScriptHandler(handler(self,self.cellCallBackActions))
        taskNode:runAction(cc.Sequence:create(
        	cc.Spawn:create(cc.FadeIn:create(0.4), cc.ScaleTo:create(0.4,1))) )
    else
	    taskNode = pCell:getChildByTag(2345)
	    taskNode:setScale(1)
	    taskNode:setOpacity(255)
	end
	xTry(function()
		local item = self.taskDatas.veteranTasks[tostring(self.clickTag)][index]
		taskNode:refreshUI(item)
		taskNode.viewData.button:setUserTag(index)
		for k,v in pairs(taskNode.goodsIcon) do
            v:setVisible(false)
		end
		for i=1,table.nums(item.rewards) do
            if taskNode.goodsIcon[i] then
                taskNode.goodsIcon[i]:setVisible(true)
                taskNode.goodsIcon[i]:RefreshSelf({
                    goodsId = item.rewards[i].goodsId,
                    amount = item.rewards[i].num,
                    showAmount = true,
                })
            else
                local goodsIcon = require('common.GoodNode').new({
                    id = item.rewards[i].goodsId,
                    amount = item.rewards[i].num,
                    showAmount = true,
                    callBack = function (sender)
                        uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
                    end
                })
				goodsIcon:setPosition(cc.p(taskNode.viewData.view:getContentSize().width - 220  - 120*(i-1),taskNode.viewData.view:getContentSize().height/2 ))
                goodsIcon:setScale(0.8)
                taskNode.viewData.view:addChild(goodsIcon)
                taskNode.goodsIcon[i] = goodsIcon
            end
        end
    end,function()
		pCell = CGridViewCell:new()
    end)
    return pCell
end

-- 领取任务奖励事件
function RecallDailyTaskMediator:cellCallBackActions( sender )
	PlayAudioByClickNormal()
	local id = sender:getTag()
	local index = sender:getUserTag()
	local data  = self.taskDatas.veteranTasks[tostring(self.clickTag)][index]
	if data then
		if data.hasDrawn == 0 then
			if checkint(data.progress) < checkint(data.targetNum) then
				uiMgr:ShowInformationTips(__('未达到领取条件'))
			else
				if self.taskDatas.veteranTaskEndLeftSeconds > 0 then
					self:SendSignal(POST.RECALLED_TASK_DRAW.cmdName,{taskId = checkint(id)})
				else
					uiMgr:ShowInformationTips(__('任务时间已经结束'))
				end
			end
		else
			uiMgr:ShowInformationTips(__('已领取该奖励'))
		end
	end
end

-- 选择UR飨灵事件
function RecallDailyTaskMediator:CellButtonAction( sender )
	local tag = 0
	if type(sender) == 'number' then
		tag = sender
	else
		PlayAudioByClickNormal()
		tag = sender:getTag()
		if self.rewardSelectedTag == tag then
			return
		end
	end
	for k,v in pairs(self.rewardCells) do
		v.maskImg:setVisible(true)
		v.selectImg:setVisible(false)
	end
	local pCell = self.rewardCells[tag]
	if pCell then
		pCell.selectImg:setVisible(true)
		pCell.maskImg:setVisible(false)
	end
	self.rewardSelectedTag = tag
	local viewData = self.viewComponent.viewData_
	viewData.imgHero:setTexture(GetFullPath('activity_btn_novice_seven_day_' .. self.taskDatas.veteranTasksDoneReward[tag].goodsId))
end

--[[
主页面tab按钮的事件处理逻辑
@param sender button对象
--]]
function RecallDailyTaskMediator:ButtonActions( sender )
	local tag = 0
	if type(sender) == 'number' then
		tag = sender
	else
		PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
		tag = sender:getTag()
		if self.clickTag == tag then
			sender:setChecked(true)
			return
		end
	end
	local viewData = self.viewComponent.viewData_
	if self.taskDatas.veteranDayNum < tag then
		if viewData.buttons[tostring(tag)] then
			uiMgr:ShowInformationTips(string.fmt(__('第_day_天解锁'),{_day_ = tag}))
			viewData.buttons[tostring(tag)]:setChecked(false)
		end
		return
	end

	-- 更新tab
	if self.clickTag then
		local preTab = viewData.buttons[tostring(self.clickTag)]
		local dayLabel 	 = preTab:getChildByTag(101)
		local prossLabel = preTab:getChildByTag(102)
		preTab:setChecked(false)
		preTab:setLocalZOrder(-1)
		display.commonLabelParams(dayLabel, fontWithColor(14,{fontSize = 22,color = 'ffffff'}))
		display.commonLabelParams(prossLabel,{color = 'ffffff'})
	end
	sender = viewData.buttons[tostring(tag)]
	local dayLabel 	 = sender:getChildByTag(101)
	local prossLabel = sender:getChildByTag(102)
	sender:setChecked(true)
	sender:setLocalZOrder(1)
	display.commonLabelParams(dayLabel, fontWithColor(7,{fontSize = 22, color = '964006'}))
	display.commonLabelParams(prossLabel,{color = '964006'})

	self.clickTag = tag

    self.gridView:setCountOfCell(table.nums(self.taskDatas.veteranTasks[tostring(tag)]))
    self.gridView:reloadData()
end

-- 更新右侧每日Tab
function RecallDailyTaskMediator:updataview( index )
	local viewData = self.viewComponent.viewData_
	local function UpdateTabButton( idx, btn )
		local dayLabel 	 = btn:getChildByTag(101)
		local prossLabel = btn:getChildByTag(102)
		local arrowImg 	 = btn:getChildByTag(103)
		local lockImg 	 = btn:getChildByTag(104)
		local newImg 	 = btn:getChildByTag(789)

		dayLabel:setVisible(false)
		prossLabel:setVisible(false)
		arrowImg:setVisible(false)
		lockImg:setVisible(false)
		newImg:setVisible(false)

		btn:setNormalImage(_res("ui/home/activity/newPlayerSevenDay/activity_btn_novice_seven_day_default.png"))

		if self.taskDatas.veteranDayNum < checkint(idx) then
			lockImg:setVisible(true)
			btn:setNormalImage(_res("ui/home/activity/newPlayerSevenDay/activity_btn_novice_seven_day_unlock.png"))
		else
			local data = self.checkTaskFinish[tostring(idx)]

			if data.isAllDrawn == true then --全部领取
				arrowImg:setVisible(true)
			else
				dayLabel:setVisible(true)
				prossLabel:setVisible(true)
				prossLabel:setString(string.format('（%d/%d）',data.progress,data.targetNum))
				for _,task in pairs(self.taskDatas.veteranTasks[tostring(idx)]) do
					if checkint(task.progress) >= checkint(task.targetNum) and task.hasDrawn == 0 then
						newImg:setVisible(true)
						break
					end
				end
			end
		end
	end
	for k, v in pairs( viewData.buttons ) do
		if index then
			if tostring(index) == tostring(k) then
				UpdateTabButton(k, v)
				break
			end
		else
			UpdateTabButton(k, v)
		end
	end
end

function RecallDailyTaskMediator:onClickEndRewardButtonHandler(sender)
	PlayAudioByClickNormal()
	
	if 0 == self.taskDatas.veteranTasksDoneRewardDrawn then
		if not self:CheckAllTaskDrawn() then
			uiMgr:ShowInformationTips(__('未达到领取条件'))
		else
			if self.taskDatas.veteranTaskEndLeftSeconds > 0 then
				if self.taskDatas.veteranTasksDoneReward[self.rewardSelectedTag] then
					self:SendSignal(POST.RECALLED_FINAL_REWARD_DRAW.cmdName,{rewardId = checkint(self.taskDatas.veteranTasksDoneReward[self.rewardSelectedTag].id)})
				end
			else
				uiMgr:ShowInformationTips(__('任务时间已经结束'))
			end
		end
	else
		uiMgr:ShowInformationTips(__('已领取该奖励'))
	end
end

-- 检查是否所有的任务都完成了
function RecallDailyTaskMediator:CheckAllTaskDrawn(  )
	local isAllDrawn = true
	if checkint(self.taskDatas.veteranDayNum) < table.nums(self.taskDatas.veteranTasks) then
		return false
	end
	for k,v in pairs(self.checkTaskFinish) do
		if not v.isAllDrawn then
			isAllDrawn = false
			break
		end
	end
	return isAllDrawn
end

function RecallDailyTaskMediator:OnRegist(  )
    regPost(POST.RECALLED_TASK_DRAW)
    regPost(POST.RECALLED_FINAL_REWARD_DRAW)
end

function RecallDailyTaskMediator:OnUnRegist(  )
	unregPost(POST.RECALLED_TASK_DRAW)
	unregPost(POST.RECALLED_FINAL_REWARD_DRAW)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return RecallDailyTaskMediator