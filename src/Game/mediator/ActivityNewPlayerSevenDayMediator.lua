local Mediator = mvc.Mediator

local ActivityNewPlayerSevenDayMediator = class("ActivityNewPlayerSevenDayMediator", Mediator)


local NAME = "ActivityNewPlayerSevenDayMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
GET_MONEY_CALLBACK = 'GET_MONEY_CALLBACK'

function ActivityNewPlayerSevenDayMediator:ctor(param, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.taskDatas = param or {}
	-- {['newbieTasks'] = {['1'] = {{hasDrawn = 1,progress = 100,targetNum = 100, descr = '娃儿而已' ,id = 2, name = '耳环柔荑花' ,mainExp = 10000},{hasDrawn = 1,progress = 100,targetNum = 100, descr = '人推介团要' ,id = 2, name = '我楼可以他你' ,mainExp = 10000}},
	-- ['2'] = {{hasDrawn = 0,progress = 1,targetNum = 100, descr = '我是描述' ,id = 2, name = '阿萨德' ,mainExp = 100},{hasDrawn = 0,progress = 100,targetNum = 100, descr = '我让他温柔' ,id = 2, name = '有人头疼' ,mainExp = 1000},{hasDrawn = 0,progress = 1,targetNum = 100, descr = '不让他' ,id = 2, name = '任天野今天还' ,mainExp = 10000}}} } --所有任务数据
	self.clickTag = 0
	self.initIndex = 0
	self.checkTaskFinish = {}--所在天数是否全部领取任务奖励
	if not self.taskDatas.newbieTasks then
		self.taskDatas.newbieTasks = {}
	end
	for k,v in pairs(self.taskDatas.newbieTasks) do
		local temp = {}
		temp.bool = true
		local num  = 0

		for ii,vv in ipairs(v) do
			vv.isFinish = 0
			if vv.hasDrawn == 0 then
				temp.bool = false -- 说明有未领取任务
			else
				num = num  + 1
			end
			if checkint(vv.progress) >=  checkint(vv.targetNum) then
				vv.isFinish = 1
			end
		end

		temp.progress = num
		temp.targetNum = table.nums(v)
		self.checkTaskFinish[k] = temp

		table.sort(v, function(a, b)
	    	local r
			local ah = tonumber(a.hasDrawn)
			local bh = tonumber(b.hasDrawn)
			local af = tonumber(a.isFinish)
			local bf = tonumber(b.isFinish)

			if ah == bh then
				r = af > bf
			else
				r = ah < bh
			end
			return r
	    end)
	end

	for k,v in orderedPairs(self.checkTaskFinish) do
		if v.bool == false then
			self.initIndex = checkint(k)
			break
		end
	end

	if self.initIndex == 0 then
		self.initIndex = 1
	end
	-- dump(self.checkTaskFinish)

	-- dump(self.taskDatas.newbieTasksDoneRewardDrawn)
	dump(self.taskDatas.newbieTasksDoneReward)
	self.gridContentOffset = cc.p(0,0)
	self.TtimeUpdateFunc = nil --任务倒计时计时器
end

function ActivityNewPlayerSevenDayMediator:InterestSignals()
	local signals = {
		POST.ACTIVITY_DRAW_NEWPLAYER_SEVEN_DAY.sglName,
		POST.ACTIVITY_DRAW_FINAL_NEWPLAYER_SEVEN_DAY.sglName,
	}

	return signals
end

function ActivityNewPlayerSevenDayMediator:ProcessSignal(signal )
	local name = signal:GetName()
	-- print(name)
	-- dump(signal:GetBody())
	if name == POST.ACTIVITY_DRAW_NEWPLAYER_SEVEN_DAY.sglName then
		uiMgr:AddDialog('common.RewardPopup', {rewards = signal:GetBody().rewards,mainExp = signal:GetBody().mainExp + gameMgr:GetUserInfo().mainExp })
		self.taskDatas.newbieTasks[tostring(self.clickTag)][self.tag].hasDrawn = 1
		self.checkTaskFinish[tostring(self.clickTag)].progress = self.checkTaskFinish[tostring(self.clickTag)].progress + 1
		for k,v in pairs(self.taskDatas.newbieTasks) do
			table.sort(v, function(a, b)
		    	local r
				local ah = tonumber(a.hasDrawn)
				local bh = tonumber(b.hasDrawn)
				local af = tonumber(a.isFinish)
				local bf = tonumber(b.isFinish)

				if ah == bh then
					r = af > bf
				else
					r = ah < bh
				end
				return r
		    end)
		end

		self.gridView:reloadData()
		self.gridView:setContentOffset(self.gridContentOffset)
		self:updataview( )
    elseif name == POST.ACTIVITY_DRAW_FINAL_NEWPLAYER_SEVEN_DAY.sglName then
    	uiMgr:AddDialog('common.RewardPopup', {rewards = signal:GetBody().rewards})
    	self.viewComponent.viewData.endRewardsBtn:setVisible(false)
    end
end


function ActivityNewPlayerSevenDayMediator:updataview( index )
	local viewData = self.viewComponent.viewData
	for k, v in pairs( viewData.buttons ) do
		local dayLabel 	 = v:getChildByTag(101)
		local prossLabel = v:getChildByTag(102)
		local arrowImg 	 = v:getChildByTag(103)
		local lockImg 	 = v:getChildByTag(104)
		local newImg 	 = v:getChildByTag(789)

		dayLabel:setVisible(false)
		prossLabel:setVisible(false)
		arrowImg:setVisible(false)
		lockImg:setVisible(false)
		newImg:setVisible(false)

		v:setNormalImage(_res("ui/home/activity/newPlayerSevenDay/activity_btn_novice_seven_day_default.png"))

		if not self.taskDatas.newbieTasks[tostring(k)] then
			lockImg:setVisible(true)
			v:setNormalImage(_res("ui/home/activity/newPlayerSevenDay/activity_btn_novice_seven_day_unlock.png"))
		else
			local data = self.checkTaskFinish[tostring(k)]

			if data.bool == true then --全部领取
				arrowImg:setVisible(true)
			else
				dayLabel:setVisible(true)
				prossLabel:setVisible(true)
				prossLabel:setString(string.format('（%d/%d）',data.progress,data.targetNum))
				if not index then
					for i,v in ipairs(self.taskDatas.newbieTasks[tostring(k)]) do
						if v.isFinish == 1 and v.hasDrawn == 0 then
							newImg:setVisible(true)
							break
						end
					end
				else
					for i,v in ipairs(self.taskDatas.newbieTasks[tostring(k)]) do
						if v.isFinish == 1 and v.hasDrawn == 0 and checkint(k) ~= checkint(index) then
							newImg:setVisible(true)
							break
						end
					end
				end
			end
		end
	end
end

function ActivityNewPlayerSevenDayMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.ActivityNewPlayerSevenDayView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	-- scene:AddGameLayer(viewComponent)
	self.viewComponent = viewComponent
	self:updataview( )

	--绑定相关的事件
	local button = nil
	local viewData = viewComponent.viewData
	for k, v in pairs( viewData.buttons ) do
		if v:getTag() == self.initIndex then
			button = v
		end
		v:setOnClickScriptHandler(handler(self,self.ButtonActions))
	end


	self.gridView = viewData.gridView
	self.gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))

	if self.taskDatas.newbieTasksDoneReward then
		local goodsId = self.taskDatas.newbieTasksDoneReward[1].goodsId
		viewData.nameLabel:setString(tostring(checktable(CardUtils.GetCardConfig(goodsId)).name))
		local qualityPath = CardUtils.GetCardQualityTextPathByCardId(goodsId)
		viewData.qualityImg:setScale(0.35)
		viewData.qualityImg:setTexture(qualityPath)

	end

	local showRewardBtn = true
	local num = 0
	for k,v in pairs(self.checkTaskFinish) do
		if v.bool == false then --未领取领取任务
			showRewardBtn = false
		end
		num = num + 1
	end
	if showRewardBtn and num == TOTAL_DAY_NUMS and self.taskDatas.newbieTasksDoneRewardDrawn == 0 then
		viewData.endRewardsBtn:setVisible(showRewardBtn)
		viewData.endRewardsBtn:setOnClickScriptHandler(handler(self,self.EndRewardsButtonActions))
	end

	if button then
        self.isFirst = 1
		self:ButtonActions( button )
        self.isFirst = 0
	end

	self:checkEatFoodTimeSchedule()
end

function ActivityNewPlayerSevenDayMediator:checkEatFoodTimeSchedule( )

	local newbieTaskRemainTime = gameMgr:GetUserInfo().newbieTaskRemainTime
	print(newbieTaskRemainTime)
	if checkint(newbieTaskRemainTime) > 0 then
		if checkint(newbieTaskRemainTime) <= 86400 then
			display.reloadRichLabel(self.viewComponent.viewData.timeLabel, {
	        c = {
				fontWithColor(10,{text =__('活动剩余时间：'),fontSize = 22, color = 'ffffff'}),
				fontWithColor(10,{text = string.formattedTime(checkint(newbieTaskRemainTime),'%02i:%02i:%02i'),fontSize = 22, color = 'ffc600'})
	        }})
		else
			local day = math.floor(checkint(newbieTaskRemainTime)/86400)
			display.reloadRichLabel(self.viewComponent.viewData.timeLabel, {
	        c = {
				fontWithColor(10,{text =__('活动剩余时间：'),fontSize = 22, color = 'ffffff'}),
				fontWithColor(10,{text = string.fmt(__('_day_天'),{_day_ = day}),fontSize = 22, color = 'ffc600'})
	        }})
		end
		if self.TtimeUpdateFunc then
			scheduler.unscheduleGlobal(self.TtimeUpdateFunc)
		end

		self.TtimeUpdateFunc = scheduler.scheduleGlobal(function(dt)
	        --事件的计时器
	        local newbieTaskRemainTime = gameMgr:GetUserInfo().newbieTaskRemainTime
	        if checkint(newbieTaskRemainTime) <= 0 then
	            scheduler.unscheduleGlobal(self.TtimeUpdateFunc)
	        else
    			if checkint(newbieTaskRemainTime) <= 86400 then
					display.reloadRichLabel(self.viewComponent.viewData.timeLabel, {
			        c = {
						fontWithColor(10,{text =__('活动剩余时间：'),fontSize = 22, color = 'ffffff'}),
						fontWithColor(10,{text = string.formattedTime(checkint(newbieTaskRemainTime),'%02i:%02i:%02i'),fontSize = 22, color = 'ffc600'})
			        }})
				else
					local day = math.floor(checkint(newbieTaskRemainTime)/86400)
					display.reloadRichLabel(self.viewComponent.viewData.timeLabel, {
			        c = {
						fontWithColor(10,{text =__('活动剩余时间：'),fontSize = 22, color = 'ffffff'}),
						fontWithColor(10,{text = string.fmt(__('_day_天'),{_day_ = day}),fontSize = 22, color = 'ffc600'})
			        }})
				end
	        end
	    end,1.0)
	end

end

function ActivityNewPlayerSevenDayMediator:EndRewardsButtonActions(sender)
    PlayAudioByClickNormal()
	if next(self.taskDatas.newbieTasks) ~= nil then
		if self.taskDatas.newbieTasksDoneRewardDrawn == 0  then
			if gameMgr:GetUserInfo().newbieTaskRemainTime > 0 then
				self.gridContentOffset = self.gridView:getContentOffset()
				self:SendSignal(POST.ACTIVITY_DRAW_FINAL_NEWPLAYER_SEVEN_DAY.cmdName)
			else
				uiMgr:ShowInformationTips(__('任务时间已经结束'))
			end
		else
			uiMgr:ShowInformationTips(__('奖励已领取'))
		end
	end
end

function ActivityNewPlayerSevenDayMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local index = idx + 1
    local taskNode = nil
    local tempBtn = nil
    local cellSize = self.gridView:getSizeOfCell()
    if nil ==  pCell  then
		pCell = CGridViewCell:new()
		taskNode = require('home.TaskCellNode').new({size = cellSize})

		taskNode:setTag(2345)

		pCell:setContentSize(cellSize)
		taskNode:setPosition(cc.p(cellSize.width * 0.5 - 5 ,cellSize.height * 0.5 - 4 ))
		pCell:addChild(taskNode)

        taskNode:runAction(cc.Sequence:create(
        	cc.Spawn:create(cc.FadeIn:create(0.4), cc.ScaleTo:create(0.4,1))) )
    else
	    taskNode = pCell:getChildByTag(2345)
	    taskNode:setScale(1)
	    taskNode:setOpacity(255)
		-- taskNode:setOnClickScriptHandler(handler(self,self.cellCallBackActions))
    end
    xTry(function()
    	local item = self.taskDatas.newbieTasks[tostring(self.clickTag)][index]
		taskNode:refreshUI(item)
		taskNode.viewData.button:setUserTag(index)
		taskNode.viewData.button:setOnClickScriptHandler(handler(self,self.CellButtonAction))
		for i,v in ipairs(item.rewards) do
			local function callBack(sender)
				AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
			end
			local goodsNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true,callBack = callBack})
			goodsNode:setPosition(cc.p(taskNode.viewData.view:getContentSize().width - 220  - 120*(i-1),taskNode.viewData.view:getContentSize().height/2 ))
			goodsNode:setScale(0.9)
			taskNode.viewData.view:addChild(goodsNode, 5)
		end


    end,function()
		pCell = CGridViewCell:new()
        __G__TRACKBACK__()
    end)
    pCell:setTag(index)
    return pCell
end

--[[
列表的单元格按钮的事件处理逻辑
@param sender button对象
--]]
function ActivityNewPlayerSevenDayMediator:CellButtonAction( sender )
    PlayAudioByClickNormal()
	local tag = sender:getTag()
	local index = sender:getUserTag()
	self.tag = index
	-- dump(index)
	local data  = self.taskDatas.newbieTasks[tostring(self.clickTag)][index]
	-- dump(data)
	if data then
		if data.hasDrawn == 0 then
			if checkint(data.progress) < checkint(data.targetNum) then
				-- uiMgr:ShowInformationTips(__('未达到领取条件'))
				-- dump(data)
				-- AppFacade.GetInstance():DispatchObservers(Event_Story_Missions_Jump,data)
			else
				if gameMgr:GetUserInfo().newbieTaskRemainTime > 0 then
					self.gridContentOffset = self.gridView:getContentOffset()
					self:SendSignal(POST.ACTIVITY_DRAW_NEWPLAYER_SEVEN_DAY.cmdName,{taskId = checkint(tag)})
				else
					uiMgr:ShowInformationTips(__('任务时间已经结束'))
				end
			end
		else
			uiMgr:ShowInformationTips(__('已领取该奖励'))
		end
	end
end



--[[
主页面tab按钮的事件处理逻辑
@param sender button对象
--]]
function ActivityNewPlayerSevenDayMediator:ButtonActions( sender )
    if checkint(self.isFirst) == 0 then
        PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
    end
	local tag = 0
	if type(sender) == 'number' then
		tag = sender
	else
		tag = sender:getTag()
		if self.clickTag == tag then
			return
		end
	end
	local viewData = self.viewComponent.viewData
	if not self.taskDatas.newbieTasks[tostring(tag)] then
		uiMgr:ShowInformationTips(string.fmt(__('第_day_天解锁'),{_day_ = tag}))
		viewData.buttons[tostring(tag)]:setChecked(false)
		viewData.buttons[tostring(tag)]:setEnabled(true)
		viewData.buttons[tostring(tag)]:setLocalZOrder(-1)
		return
	end

	for k, v in pairs( viewData.buttons ) do
		local dayLabel 	 = v:getChildByTag(101)
		local prossLabel = v:getChildByTag(102)
		local curTag = v:getTag()
		if tag == curTag then
			v:setChecked(true)
			v:setEnabled(false)
			v:setLocalZOrder(1)
			display.commonLabelParams(dayLabel, fontWithColor(7,{fontSize = 22, color = '964006'}))
			display.commonLabelParams(prossLabel,{color = '964006'})
		else
			v:setChecked(false)
			v:setEnabled(true)
			v:setLocalZOrder(-1)
			display.commonLabelParams(dayLabel, fontWithColor(14,{fontSize = 22,color = 'ffffff'}))
			display.commonLabelParams(prossLabel,{color = 'ffffff'})
		end
	end

	self.clickTag = tag

	local num = table.nums(self.taskDatas.newbieTasks[tostring(tag)])


    self.gridView:setCountOfCell(num)
    self.gridView:reloadData()
	--切页面滑动层滑到最上
	self.gridView:setContentOffsetToTop()
	self.gridContentOffset = self.gridView:getContentOffset()

	local newImg  = sender:getChildByTag(789)
	newImg:setVisible(false)
	self:updataview( tag )
end

function ActivityNewPlayerSevenDayMediator:OnRegist(  )
	regPost(POST.ACTIVITY_DRAW_NEWPLAYER_SEVEN_DAY)
	regPost(POST.ACTIVITY_DRAW_FINAL_NEWPLAYER_SEVEN_DAY)
end

function ActivityNewPlayerSevenDayMediator:OnUnRegist(  )
	--称出命令
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	unregPost(POST.ACTIVITY_DRAW_NEWPLAYER_SEVEN_DAY)
	unregPost(POST.ACTIVITY_DRAW_FINAL_NEWPLAYER_SEVEN_DAY)


	gameMgr:GetUserInfo().showRedPointForNewbieTask = false
	for k,v in pairs(self.taskDatas.newbieTasks) do
		local bool = false
		for i,vv in ipairs(v) do
			if vv.isFinish == 1 and vv.hasDrawn == 0 then
				gameMgr:GetUserInfo().showRedPointForNewbieTask = true
				bool = true
				break
			end
		end
		if bool then
			break
		end
	end

	if gameMgr:GetUserInfo().newbieTaskRemainTime > 0 then
		if gameMgr:GetUserInfo().showRedPointForNewbieTask == true then--
			AppFacade.GetInstance():GetManager("DataManager"):AddRedDotNofication(tostring(RemindTag.SEVENDAY), RemindTag.SEVENDAY, "[新手七天]ActivityNewPlayerSevenDayMediator")
		else
			AppFacade.GetInstance():GetManager("DataManager"):ClearRedDotNofication(tostring(RemindTag.SEVENDAY), RemindTag.SEVENDAY, "[新手七天]ActivityNewPlayerSevenDayMediator")
		end
	else
		AppFacade.GetInstance():GetManager("DataManager"):ClearRedDotNofication(tostring(RemindTag.SEVENDAY), RemindTag.SEVENDAY)
	end
	AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.SEVENDAY})


	if self.TtimeUpdateFunc then
		scheduler.unscheduleGlobal(self.TtimeUpdateFunc)
	end
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)

end

return ActivityNewPlayerSevenDayMediator
