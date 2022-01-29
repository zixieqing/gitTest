--[[
循环任务活动view
--]]
local CyclicTasksView = class('CyclicTasksView', function ()
	local node = CLayout:create(display.size)
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.CyclicTasksView'
	node:enableNodeEvents()
	return node
end)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local scheduler = require('cocos.framework.scheduler')
local function CreateView( )
	local bgSize = cc.size(1142, 641)
	local view = CLayout:create(bgSize)
	local mask = display.newLayer(bgSize.width/2, bgSize.height/2, {ap = display.CENTER, size = bgSize, enable = true, color = cc.c4b(0,0,0,0)})
	view:addChild(mask, -1)
	local bg = display.newImageView(_res('ui/common/common_bg_13.png'), bgSize.width/2, bgSize.height/2)
	view:addChild(bg)
	local titleBg = display.newButton(bgSize.width/2, bgSize.height - 28, {n = _res('ui/common/common_bg_title_2.png'), enable = false})
	view:addChild(titleBg, 10)
	display.commonLabelParams(titleBg, {text = __('循环任务'), fontSize = 22, color = '#ffffff', offset = cc.p(0, 0)})
	local timeLabel = display.newLabel(bgSize.width/2, bgSize.height - 80, fontWithColor(16, {text = ''}))
	view:addChild(timeLabel, 10)
	-- 进度条
	local progressLayout = CLayout:create(cc.size(bgSize.width, 140))
	progressLayout:setPosition(cc.p(bgSize.width/2, 510))
	view:addChild(progressLayout, 10)
	local progressLabel = display.newLabel(130, 100, {text = __('活动进度'), fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1, ap = cc.p(0, 0.5)})
	progressLayout:addChild(progressLabel, 10)
	local progressBar = CProgressBar:create(_res('ui/home/task/task_bar.png'))
    progressBar:setBackgroundImage(_res('ui/home/task/task_bar_bg.png'))
    progressBar:setDirection(eProgressBarDirectionLeftToRight)
    progressBar:setAnchorPoint(cc.p(0.5, 0.5))
    progressBar:setPosition(cc.p(bgSize.width/2 - 90, 70))
    progressLayout:addChild(progressBar, 5)

	local drawBtn = display.newButton(850, 25, {n = _res('ui/common/common_btn_orange.png'), scale9 = true, size = cc.size(144, 64)})
	progressLayout:addChild(drawBtn, 15)
	display.commonLabelParams(drawBtn, fontWithColor(14, {text = __('领取')}))
	-- 购买按钮
	local buyBtn = display.newButton(980, 70, {n = _res('ui/common/common_btn_green.png'), scale9 = true, size = cc.size(123, 60)})
	local buyBtnLabel = display.newLabel(0, 0, {text = string.fmt(__('购买_num_'), {['_num_'] = 1}), offset = cc.p(5, 0), ap = cc.p(1, 0.5), fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
	buyBtn:addChild(buyBtnLabel, 10)
	local btnTextW = display.getLabelContentSize(buyBtnLabel).width
	buyBtn:setContentSize(cc.size(math.max(123, btnTextW + 60), 60))
	local fire = display.newImageView(_res('ui/home/activity/looptask_ico_fire.png'), buyBtn:getContentSize().width - 25, 30)
	buyBtn:addChild(fire, 10)
	buyBtnLabel:setPosition(cc.p(buyBtn:getContentSize().width - 50, 30))
	progressLayout:addChild(buyBtn, 10)
	local costLabel = display.newRichLabel(980, 25)
	progressLayout:addChild(costLabel, 10)
	-- 任务列表
	local taskListLayout = CLayout:create(cc.size(bgSize.width, 410))
	view:addChild(taskListLayout, 10)
	display.commonUIParams(taskListLayout, {ap = cc.p(0.5, 0), po = cc.p(bgSize.width/2, 20)})
	local listTitleBg = display.newImageView(_res('ui/home/activity/looptask_title.png'), bgSize.width/2, 380)
	taskListLayout:addChild(listTitleBg, 5)
	local todayTimeTitleLabel = display.newLabel(92, 380, fontWithColor(18, {text = __('今日任务剩余时间'), ap = cc.p(0, 0.5)}))
	taskListLayout:addChild(todayTimeTitleLabel, 10)
	local todayTimeLabel = display.newLabel(100 + display.getLabelContentSize(todayTimeTitleLabel).width, 380, {text = '', color = 'ffca14', fontSize = 22, ap = cc.p(0, 0.5)})
	taskListLayout:addChild(todayTimeLabel, 10)
	local tipsLabel = display.newLabel(1005, 380, fontWithColor(18, {text = __('完成今日所有任务获得1个'), ap = cc.p(1, 0.5)}))
	taskListLayout:addChild(tipsLabel, 10)
	local tipsIcon = display.newImageView(_res('ui/home/activity/looptask_ico_fire.png'), 1035, 380)
	taskListLayout:addChild(tipsIcon, 10)
	local listBg = display.newImageView(_res('ui/common/common_bg_goods.png'), bgSize.width/2, 8, {scale9 = true, size = cc.size(981, 350), ap = cc.p(0.5, 0)})
	taskListLayout:addChild(listBg, 3)
	local listSize = cc.size(978, 346)
	local listCellSize = cc.size(978, 124)
	local taskListView = CGridView:create(listSize)
    taskListView:setSizeOfCell(listCellSize)
    taskListView:setColumns(1)
    taskListView:setAutoRelocate(true)
    taskListLayout:addChild(taskListView, 10)
    taskListView:setPosition(cc.p(bgSize.width/2, 181))
    -- taskListView:setDataSourceAdapterScriptHandler(handler(self,self.ListDataSourceAction))
	return {
		view 	       = view,
		timeLabel      = timeLabel,
		progressLayout = progressLayout,
		taskListView   = taskListView,
		todayTimeLabel = todayTimeLabel,
		taskListLayout = taskListLayout,
		progressBar    = progressBar,
		drawBtn        = drawBtn,
		titleBg 	   = titleBg,
		buyBtn 	       = buyBtn,
		costLabel	   = costLabel,


	}
end

function CyclicTasksView:ctor( ... )
	self.activityDatas = unpack({...}) or {}
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	eaterLayer:setOnClickScriptHandler(handler(self, self.RemoveSelf_))
	self.eaterLayer = eaterLayer
	self:addChild(eaterLayer, -1)

	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
	self.viewData_.drawBtn:setOnClickScriptHandler(self.activityDatas.finalDrawCallback)
	self.viewData_.buyBtn:setOnClickScriptHandler(handler(self, self.BuyButtonCallback))
	self.viewData_.taskListView:setDataSourceAdapterScriptHandler(handler(self,self.CyclicTasksDataSource))
	self:InitData()
	self:InitUi()
end

function CyclicTasksView:InitData()
	if nil ~= app.passTicketMgr and nil ~= app.passTicketMgr.GetTaskPointByModuleId then
		local tasks = self.activityDatas.tasks
		for i, task in ipairs(tasks) do
			local point = app.passTicketMgr:GetTaskPointByModuleId(app.passTicketMgr.MODULE_TYPE.CYCLIC_TASK, task.taskId)
			if checkint(point) > 0 then
				table.insert(task.rewards or {}, {goodsId = PASS_TICKET_ID, num = point})
			end
		end
	end
end
--[[
初始化Ui
--]]
function CyclicTasksView:InitUi( newDatas )
	if newDatas then
		self.activityDatas = newDatas
	end
	local activityDatas = self.activityDatas
	activityDatas.taskLeftSeconds = checkint(activityDatas.taskLeftSeconds) + 2
	local viewData = self.viewData_
	self.fireTable = {}
	self.lineTable = {}
	viewData.timeLabel:setString(string.fmt(__('活动剩余时间:_num_'), {_num_ = self:ChangeTimeFormat(checkint(activityDatas.leftSeconds))}))
	viewData.todayTimeLabel:setString(string.formattedTime(activityDatas.taskLeftSeconds,'%02i:%02i:%02i'))
	viewData.titleBg:getLabel():setString(tostring(self.activityDatas.title))
	-- 最终奖励
	if activityDatas.finalRewards then
		local rewardDatas = activityDatas.finalRewards[1]
		local goodsNode = require('common.GoodNode').new({id = rewardDatas.goodsId, showAmount = false, callBack = function(sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = rewardDatas.goodsId, type = 1})
		end})
		viewData.progressLayout:addChild(goodsNode, 10)
		goodsNode:setPosition(850, 60)
		goodsNode:setAnchorPoint(cc.p(0.5, 0))
		goodsNode:setScale(0.75)
		viewData.progressBar:setMaxValue(checkint(activityDatas.finalRewardsTarget))
		viewData.progressBar:setValue(checkint(activityDatas.finalRewardsProgress))
	end
	-- 幻晶石消耗
	display.reloadRichLabel(viewData.costLabel, {c = {
		fontWithColor(16, {text = string.fmt(__('消耗_num_'), {['_num_'] = checkint(activityDatas.doneOnceConsume[1].num)})}),
		{img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID) , scale = 0.18}
	}})
	local sectionW = viewData.progressBar:getContentSize().width / checkint(activityDatas.finalRewardsTarget)
	for i = 1, checkint(activityDatas.finalRewardsTarget) do
		local devY = -10
		if i ~= checkint(activityDatas.finalRewardsTarget) then
			local line = display.newImageView(_res('ui/home/task/task_bar_bg_spot.png'), 116 + sectionW*i, viewData.progressBar:getPositionY())
			viewData.progressLayout:addChild(line, 10)
			table.insert(self.lineTable, line)
		end
		local numLabel = display.newLabel(116 + sectionW*i - 20, 40 + devY, {text = tostring(i), fontSize = 34, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
		viewData.progressLayout:addChild(numLabel, 10)
		local fireIcon = FilteredSpriteWithOne:create(_res('ui/home/activity/looptask_ico_fire.png'))
		fireIcon:setPosition(116 + sectionW*i + 20, 40 + devY)
		fireIcon:setFilter(GrayFilter:create())
		viewData.progressLayout:addChild(fireIcon, 10)
		table.insert(self.fireTable, fireIcon)
	end
	self:RefreshProgressBar()
	self:UpdateTodayLeftTime()
	viewData.taskListView:setCountOfCell(#activityDatas.tasks)
	viewData.taskListView:reloadData()
end
--[[
更新进度条
--]]
function CyclicTasksView:RefreshProgressBar()
	local activityDatas = self.activityDatas
	for i, v in ipairs(self.fireTable) do
		if i <= checkint(activityDatas.finalRewardsProgress) then
			v:clearFilter()
		end
	end
	for i,v in ipairs(self.lineTable) do
		if i <= checkint(activityDatas.finalRewardsProgress) then
			v:setTexture(_res('ui/home/task/task_bar_spot.png'))
		end
	end
	self.viewData_.progressBar:setValue(checkint(activityDatas.finalRewardsProgress))
	if checkint(activityDatas.finalRewardsProgress) >= checkint(activityDatas.finalRewardsTarget) and checkint(activityDatas.finalRewardsHasDrawn) == 0 then
		self.viewData_.drawBtn:setVisible(true)
	else
		self.viewData_.drawBtn:setVisible(false)
	end
	-- 更新购买按钮
	if checkint(activityDatas.nextDay) >= checkint(activityDatas.finalRewardsTarget) and checkint(activityDatas.finalRewardsProgress) < checkint(activityDatas.finalRewardsTarget) then
		self.viewData_.buyBtn:setNormalImage(_res('ui/common/common_btn_green.png'))
		self.viewData_.buyBtn:setSelectedImage(_res('ui/common/common_btn_green.png'))
	else
		self.viewData_.buyBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
		self.viewData_.buyBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
	end
end

--[[
循环任务列表处理
--]]
function CyclicTasksView:CyclicTasksDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(978, 124)

    if pCell == nil then
        pCell = require('home.ActivityCyclicTasksCell').new(cSize)
		pCell.drawBtn:setOnClickScriptHandler(self.activityDatas.cellDrawCallback)
    end
	xTry(function()
		local datas = self.activityDatas.tasks[index]
		pCell.titleLabel:setString(datas.name)
		local descr = datas.descr
		descr = string.gsub(descr, '_target_num_', tostring(datas.target), 1)
		pCell.descLabel:setString(descr)
		pCell.drawBtn:setTag(index)
		for i=1, 4 do
			if datas.rewards and datas.rewards[i] then
				pCell.rewardsTable[i]:setVisible(true)
				pCell.rewardsTable[i]:RefreshSelf({goodsId = datas.rewards[i].goodsId, num = datas.rewards[i].num})
				pCell.rewardsTable[i].callBack = function( sender )
					uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = datas.rewards[i].goodsId, type = 1})
				end
			else
				pCell.rewardsTable[i]:setVisible(false)
			end
		end
		-- 领奖状态
		if datas.hasDrawn then
			pCell.drawBtn:setNormalImage(_res('ui/common/activity_mifan_by_ico.png'))
			pCell.taskProgressLabel:setVisible(false)
			pCell.drawBtn:setEnabled(false)
			display.commonLabelParams(pCell.drawBtn, fontWithColor(14, {text = ''}))
			pCell.completeLabel:setVisible(true)
		else
			pCell.drawBtn:setEnabled(true)
			pCell.drawBtn:setTag(checkint(datas.taskId))
			pCell.taskProgressLabel:setVisible(true)
			pCell.completeLabel:setVisible(false)
			if checkint(datas.progress) >= checkint(datas.target) then
				pCell.drawBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
				pCell.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
				pCell.drawBtn:setEnabled(true)
				display.commonLabelParams(pCell.drawBtn, fontWithColor(14, {text = __('领取')}))
			else
				pCell.drawBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
				pCell.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
				pCell.drawBtn:setEnabled(false)
				display.commonLabelParams(pCell.drawBtn, fontWithColor(14, {text = __('未完成')}))
			end
			pCell.taskProgressLabel:setString(string.format('(%d/%d)', math.min(checkint(datas.progress), checkint(datas.target)), datas.target))
		end
	end,__G__TRACKBACK__)
    return pCell
end
--[[
更新任务剩余时间
--]]
function CyclicTasksView:UpdateTodayLeftTime()
	local startTime = checkint(os.time())
	if  self.todayLeftTimeScheduler then
		scheduler.unscheduleGlobal(self.todayLeftTimeScheduler)
	end

	self.todayLeftTimeScheduler = scheduler.scheduleGlobal(function()
        local curTime =  os.time()
        local distance = curTime - startTime
        local curTaskLeftTime = self.activityDatas.taskLeftSeconds
        startTime = curTime
		if checkint(self.activityDatas.taskLeftSeconds) > 0 then
			self.activityDatas.taskLeftSeconds  =  checkint(self.activityDatas.taskLeftSeconds) - distance
		end
		if checkint(self.activityDatas.taskLeftSeconds) > 0 then
			self.viewData_.todayTimeLabel:setString(string.formattedTime(self.activityDatas.taskLeftSeconds,'%02i:%02i:%02i'))
		else
			local mediator = AppFacade.GetInstance():RetrieveMediator('ActivityMediator')
			if mediator then
				mediator:SendSignal(COMMANDS.COMMAND_Activity_CyclicTasks, {activityId = self.activityDatas.requestData.activityId})
				scheduler.unscheduleGlobal(self.todayLeftTimeScheduler)
			end
		end
	end, 1, false)
end
--[[
完成任务回调
--]]
function CyclicTasksView:CompleteTask( datas )
	if checkint(datas.requestData.type) == 1 then -- 每日任务奖励
		for i,v in ipairs(self.activityDatas.tasks) do
			if checkint(v.taskId) == checkint(datas.requestData.taskId) then
				v.hasDrawn = true
				local cell = self.viewData_.taskListView:cellAtIndex(i-1)
				cell.drawBtn:setNormalImage(_res('ui/common/activity_mifan_by_ico.png'))
				cell.taskProgressLabel:setVisible(false)
				cell.drawBtn:setEnabled(false)
				display.commonLabelParams(cell.drawBtn, fontWithColor(14, {text = ''}))
				cell.completeLabel:setVisible(true)
				
				if nil ~= app.passTicketMgr and nil ~= app.passTicketMgr.UpdateExpByTask then
					app.passTicketMgr:UpdateExpByTask(app.passTicketMgr.MODULE_TYPE.CYCLIC_TASK, v.taskId)
				end
				break
			end
		end
		local isComplete = true
		for i,v in ipairs(self.activityDatas.tasks) do
			if not v.hasDrawn then
				isComplete = false
				break
			end
		end
		if isComplete then
			self.activityDatas.finalRewardsProgress = checkint(self.activityDatas.finalRewardsProgress) + 1
			self:RefreshProgressBar()
		end
	elseif checkint(datas.requestData.type) == 2 then -- 最终奖励
		self.activityDatas.finalRewardsHasDrawn = 1
		self:RefreshProgressBar()
	end
	if datas.rewards then
		uiMgr:AddDialog('common.RewardPopup', {rewards = datas.rewards})
	end
end
--[[
购买任务点按钮回调
--]]
function CyclicTasksView:BuyButtonCallback( sender )
	PlayAudioByClickNormal()
	local activityDatas = self.activityDatas
	if checkint(activityDatas.nextDay) >= checkint(activityDatas.finalRewardsTarget) then
		if checkint(activityDatas.finalRewardsProgress) < checkint(activityDatas.finalRewardsTarget) then
			if checkint(gameMgr:GetUserInfo().diamond) >= checkint(activityDatas.doneOnceConsume[1].num) then
        		local scene = uiMgr:GetCurrentScene()
        		local CommonTip  = require( 'common.NewCommonTip' ).new({text = string.fmt(__('是否花费_num_幻晶石购买？'), {['_num_'] = checkint(activityDatas.doneOnceConsume[1].num)}),
        		    isOnlyOK = false, callback = function ()
						AppFacade.GetInstance():DispatchObservers(CYCLICTASKS_BUY_SUCCESS)
        		    end})
        		CommonTip:setPosition(display.center)
        		scene:AddDialog(CommonTip)
			else
				if GAME_MODULE_OPEN.NEW_STORE then
					app.uiMgr:showDiamonTips()
				else
					uiMgr:ShowInformationTips(__('幻晶石不足'))
				end
			end
		else
			uiMgr:ShowInformationTips(__('该活动奖励你已领取。不可再重复获得'))
		end
	else
		uiMgr:ShowInformationTips(string.fmt(__('该功能在活动开启第_num_天时开启'), {['_num_'] = checkint(activityDatas.finalRewardsTarget)}))
	end
end
--[[
任务点购买完成
--]]
function CyclicTasksView:TaskPointBuyAction( datas )
	-- 扣除道具
	local temp = clone(self.activityDatas.doneOnceConsume)
	for i,v in ipairs(temp) do
		v.num = -v.num
	end
	CommonUtils.DrawRewards(temp)
	self.activityDatas.finalRewardsProgress = checkint(self.activityDatas.finalRewardsProgress) + 1
	self:RefreshProgressBar()
end
--[[
更新剩余时间
--]]
function CyclicTasksView:UpdateTimeLabel( seconds, activityId )
	if checkint(activityId) ~= checkint(self.activityDatas.requestData.activityId) then return end
	if checkint(seconds) > 0 then
		local viewData = self.viewData_
		-- viewData.timeLabel:setString(string.format('活动剩余时间:%s', self:ChangeTimeFormat(checkint(seconds))))
        viewData.timeLabel:setString(string.fmt(__('活动剩余时间:_num_'), {_num_ = self:ChangeTimeFormat(checkint(seconds))}))
	else
		self:RemoveSelf_()
	end
end
--[[
时间转换
--]]
function CyclicTasksView:ChangeTimeFormat( seconds )
	local c = nil
	if checkint(seconds) >= 86400 then
		local day = math.floor(seconds/86400)
		local hour = math.floor((seconds%86400)/3600)
		c = string.fmt(__('_num1_天_num2_小时'), {['_num1_'] = tostring(day),['_num2_'] = tostring(hour)})
	else
		local hour   = math.floor(seconds / 3600)
		local minute = math.floor((seconds - hour*3600) / 60)
		local sec    = (seconds - hour*3600 - minute*60)
		c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
	end
	return c
end
function CyclicTasksView:RemoveSelf_()
	app:UnRegistMediator('activity.cyclicTask.ActivityCyclicTaskMediator')
end
function CyclicTasksView:onCleanup()
    if self.todayLeftTimeScheduler then
        scheduler.unscheduleGlobal(self.todayLeftTimeScheduler)
    end
end
return CyclicTasksView
