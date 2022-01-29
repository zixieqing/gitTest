local Mediator = mvc.Mediator
---@class ReturnWelfareMediator:Mediator
local ReturnWelfareMediator = class("ReturnWelfareMediator", Mediator)

local NAME = "ReturnWelfareMediator"
local app = app
local uiMgr = app.uiMgr
local gameMgr = app.gameMgr
local dataMgr = app.dataMgr
local scheduler = require('cocos.framework.scheduler')

function ReturnWelfareMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.datas = checktable(params) or {}
	self.pageDefine = {
		{'ReturnWelfareTreasureMediator', 	_res('ui/home/returnWelfare/diao_bg.png'), 	'treasureLeftSeconds',			'treasure',				'treasureOpened'},
		{'ReturnWelfareDailyMediator', 		_res('ui/home/returnWelfare/day_bg.png'), 	'accumulativeLoginLeftSeconds',	'accumulativeLogin',	'accumulativeLoginOpened'},
		{'ReturnWelfareBingoMediator', 		_res('arts/stage/bg/main_bg_25.png'), 		'bingoLeftSeconds',				'bingo',				'bingoOpened'},
		{'ReturnWelfareWeeklyMediator', 	_res('ui/home/returnWelfare/week_bg.png'), 	'weeklyRewardsLeftSeconds',		'weeklyRewards',		'weeklyRewardsOpened'},
		{'ReturnWelfareDoubleMediator', 	_res('arts/stage/bg/main_bg_30.png'), 		'buffLeftSeconds',				'buff',					'buffOpened'},
	}
	local rule = CommonUtils.GetConfigAllMess('rule', 'back')
	local playerLevel = checkint(gameMgr:GetUserInfo().level)
	for i=table.nums(self.pageDefine),1,-1 do
		if playerLevel < tonumber(rule[self.pageDefine[i][4]].openLevel) or checkint(self.datas[self.pageDefine[i][5]]) == 0 then
			table.remove( self.pageDefine, i )
		end
	end
	self.pages = {}
	self.curPageIndex = 1
	self.zorder = 0
	if 0 >= table.nums(self.pageDefine) then
		uiMgr:ShowInformationTips(__('活动已过期'))
		gameMgr:StopBackCountDown()
		dataMgr:ClearRedDotNofication(tostring(RemindTag.RETURNWELFARE), RemindTag.RETURNWELFARE, "[回归福利]-GameManager:StopBackCountDown")
		app:DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.RETURNWELFARE})
	end
end

function ReturnWelfareMediator:InterestSignals()
	local signals = { 
		POST.BACK_HOME.sglName,
		SGL.NEXT_TIME_DATE, 
		'EVENT_RED_POINT',
		'EVENT_HOME_RED_POINT'
	}

	return signals
end

function ReturnWelfareMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
	if name == POST.BACK_HOME.sglName then
		self.datas = checktable(body) or {}
		self:SafeStopScheduler()
		self.updateHandler = scheduler.scheduleGlobal(handler(self,self.onTimerScheduler), 1)
		for k,v in pairs(self.pages) do
			v:ResetMdt(body)
		end
        app:DispatchObservers('EVENT_RED_POINT')
		self.preTime = os.time()
	elseif name == SGL.NEXT_TIME_DATE then 
		self:SendSignal(POST.BACK_HOME.cmdName)
	elseif name == 'EVENT_RED_POINT' then 
		local viewData = self.viewComponent.viewData
		viewData.redPointImg:setVisible(self:CheckRedPoint(false))
	elseif name == 'EVENT_HOME_RED_POINT' then 
		local redpoint = self:CheckRedPoint(true)
		gameMgr:GetUserInfo().showRedPointForBack = redpoint
		if redpoint then
			dataMgr:AddRedDotNofication(tostring(RemindTag.RETURNWELFARE),RemindTag.RETURNWELFARE, "[回归福利]-ReturnWelfareMediator:EVENT_HOME_RED_POINT[rewelf]")
		else
			dataMgr:ClearRedDotNofication(tostring(RemindTag.RETURNWELFARE), RemindTag.RETURNWELFARE, "[回归福利]-ReturnWelfareMediator:EVENT_HOME_RED_POINT")
		end
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.RETURNWELFARE})
	end
end

function ReturnWelfareMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.returnWelfare.ReturnWelfareView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	uiMgr:SwitchToScene( viewComponent)
	-- scene:AddDialog(viewComponent)
	local viewData = viewComponent.viewData

	viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TipsBtnClickHandler))
	viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackBtnClickHandler))
	if 1 == table.nums(self.pageDefine) then
		viewData.leftBtn:setVisible(false)
		viewData.rightBtn:setVisible(false)
	else
		viewData.leftBtn:setOnClickScriptHandler(handler(self, self.SwitchToNextPage))
		viewData.rightBtn:setOnClickScriptHandler(handler(self, self.SwitchToNextPage))
	end
	self.preTime = os.time()
	self.updateHandler = scheduler.scheduleGlobal(handler(self,self.onTimerScheduler), 1)
	if 1 == checkint(self.datas.treasureFreeRewards.hasDrawn) and 1 == checkint(self.datas.treasurePayRewards.hasDrawn) then
		self.curPageIndex = 2
		local dailyAllClear = true
		for k,v in pairs(self.datas.accumulativeLoginRewards) do
			if 0 == checkint(v.hasDrawn) then
				dailyAllClear = false
				break
			end
		end
		if dailyAllClear then
			self.curPageIndex = 3
		end
	end
	if 0 < table.nums(self.pageDefine) then
		self:SwitchToNextPage()
	end
	local viewData = self.viewComponent.viewData
	viewData.redPointImg:setVisible(self:CheckRedPoint(false))
end

function ReturnWelfareMediator:SafeStopScheduler( ... )
	if self.updateHandler then
		scheduler.unscheduleGlobal(self.updateHandler)
		self.updateHandler = nil
	end
end

function ReturnWelfareMediator:onTimerScheduler( dt )
	local curTime = os.time()
	-- 玩家改时间或长时间切换到后台 重新拉home数据
	if curTime < self.preTime or curTime > (self.preTime + 2 * dt) then
		self:SafeStopScheduler()
		self:SendSignal(POST.BACK_HOME.cmdName)
		return
	end
	self.preTime = curTime
	for k,v in pairs(self.pageDefine) do
		if 0 < checkint(self.datas[v[3]]) then
			self.datas[v[3]] = self.datas[v[3]] - 1
		end
	end
	if 0 < checkint(self.datas.bingoRoundLeftSeconds) then
		self.datas.bingoRoundLeftSeconds = self.datas.bingoRoundLeftSeconds - 1
		app:DispatchObservers('RETURN_WELFARE_BINGO_COUNT_DOWN', self.datas.bingoRoundLeftSeconds)
	end
	local today = checkint(self.datas.weeklyRewardsCurrentId)
	local weeklyRewards = self.datas.weeklyRewards[today]
	if weeklyRewards then
		if 0 < checkint(weeklyRewards.leftSeconds) and 1 ~= checkint(weeklyRewards.hasDrawn)  then
			weeklyRewards.leftSeconds = weeklyRewards.leftSeconds - 1
			app:DispatchObservers('RETURN_WELFARE_WEEK_COUNT_DOWN', weeklyRewards.leftSeconds)
		end
	end
	self:UpdateCountDown()
	if 0 >= checkint(self.datas.bingoRoundLeftSeconds) then
		self:SafeStopScheduler()
		self:SendSignal(POST.BACK_HOME.cmdName, {weeklyRewardId = tag})
	end
end

function ReturnWelfareMediator:SwitchToNextPage( sender )
    local viewData = self.viewComponent.viewData
	if sender then PlayAudioByClickNormal() end
	if self.curPage then
		self.curPage.viewComponent:runAction(cc.Sequence:create(
			cc.Spawn:create(
				cc.FadeOut:create(0.3),
				cc.MoveBy:create(0.3, cc.p(-100 * sender:getTag(), 0))
			),
			cc.Hide:create()
		) )
		self.curPage.viewComponent:setLocalZOrder(self.zorder)
		self.curPageIndex = self.curPageIndex + sender:getTag()
	end
	if self.curPageIndex > table.nums(self.pageDefine) then
		self.curPageIndex = 1
	end
	if self.curPageIndex <= 0 then
		self.curPageIndex = table.nums(self.pageDefine)
	end
	local pageName = self.pageDefine[self.curPageIndex][1]
	self.zorder = self.zorder - 1
	if self.pages[pageName] then
		local page = self.pages[pageName].viewComponent
		page:stopAllActions()
		page:setPositionX(display.cx)
		page:setOpacity(255)
		page:setVisible(true)
		page:setLocalZOrder(self.zorder)
	else
		local welfarePage = require( 'Game.mediator.returnWelfare.' .. pageName).new({parent = viewData.contentView, data = self.datas})
		app:RegistMediator(welfarePage)
		welfarePage.viewComponent:setLocalZOrder(self.zorder)
		self.pages[pageName] = welfarePage
	end
	viewData.BG:setTexture(self.pageDefine[self.curPageIndex][2])
	self:UpdateCountDown()
	fullScreenFixScale(viewData.BG)
	self.curPage = self.pages[pageName]

	app:DispatchObservers('EVENT_RED_POINT')
end

function ReturnWelfareMediator:UpdateCountDown()
	local countdown = self.datas[self.pageDefine[self.curPageIndex][3]]
    local viewData = self.viewComponent.viewData
    if countdown <= 0 then
        viewData.timeLabel:setString(__('已结束'))
    else
        if checkint(countdown) <= 86400 then
            viewData.timeLabel:setString(string.formattedTime(checkint(countdown), '%02i:%02i:%02i'))
        else
            local day  = math.floor(checkint(countdown) / 86400)
            local hour = math.floor((countdown - day * 86400) / 3600)
            viewData.timeLabel:setString(string.fmt(__('_day_天_hour_小时'), { _day_ = day, _hour_ = hour }))
        end
    end
end

function ReturnWelfareMediator:BackBtnClickHandler(sender)
	PlayAudioByClickNormal()
	app:BackHomeMediator()
	-- app:UnRegsitMediator("ReturnWelfareMediator")
end

function ReturnWelfareMediator:TipsBtnClickHandler(sender)
	PlayAudioByClickNormal()
	uiMgr:ShowIntroPopup({moduleId = '86'})
end

function ReturnWelfareMediator:CheckRedPoint( isTotal )
	local data = self.datas
	for i,v in ipairs(self.pageDefine) do
		if i ~= self.curPageIndex or isTotal then
			if v[1] == 'ReturnWelfareTreasureMediator' then
				if checkint(data.treasureFreeRewards.hasDrawn) ~= 1 then
					return true
				end
			elseif v[1] == 'ReturnWelfareDailyMediator' then
				local today = checkint(data.accumulativeLoginDayNum)
				for i,v in ipairs(data.accumulativeLoginRewards) do
					if today >= i and 0 == checkint(v.hasDrawn) then
						return true
					end
				end
			elseif v[1] == 'ReturnWelfareBingoMediator' then
				local lines = self:CheckBoxComplete()
				for i,v in ipairs(data.bingoRewards) do
					if 0 == checkint(v.hasDrawn) and i <= table.nums(lines) then
						return true
					end
				end
				for i,v in ipairs(data.bingoTasks) do
					if 0 == checkint(v.hasDrawn) and checkint(v.progress) >= checkint(v.targetNum) then
						return true
					end
				end
			elseif v[1] == 'ReturnWelfareWeeklyMediator' then
				local today = checkint(data.weeklyRewardsCurrentId)
				for i,v in ipairs(data.weeklyRewards) do
					if today == i and 0 == checkint(v.hasDrawn) then
						return true
					end
				end
			end
		end
	end
    return false
end

local line = {
	['1'] = {1, 4, 5},
	['2'] = {4},
	['3'] = {4},
	['4'] = {3, 4},
	['5'] = {1},
	['9'] = {1},
	['13'] = {1}
}
function ReturnWelfareMediator:CheckBoxComplete(  )
	local lines = {}
	local data = self.datas
	local position = {}
	for k,v in pairs(data.bingoPositions) do
		position[tostring(v)] = true
	end
	for k,v in pairs(line) do
		if position[tostring(k)] then
			for _,child in pairs(v) do
				if position[tostring(k + child)] and position[tostring(k + child * 2)] and position[tostring(k + child * 3)] then
					table.insert( lines, {k, child} )
				end
			end
		end
	end
	return lines
end

function ReturnWelfareMediator:OnRegist(  )
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
	regPost(POST.BACK_HOME)
end

function ReturnWelfareMediator:OnUnRegist(  )
	unregPost(POST.BACK_HOME)
	self:SafeStopScheduler()
	for k,v in pairs(self.pages) do
		app:UnRegsitMediator(k)
	end

	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return ReturnWelfareMediator