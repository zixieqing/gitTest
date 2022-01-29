--[[
小红点
@params table {
	type int 小红点类型 1 默认 2 带数字
	parent cc.Node 父节点
	eventTag RemindTag 小红点事件tag
	po(nil) cc.p 位置
}
--]]
local shareFacade = AppFacade.GetInstance()
local RemindIcon = class('RemindIcon', function ()
    local node = cc.Sprite:create()
    node.name = 'common.RemindIcon'
    node:enableNodeEvents()
    return node
end)


local dataMgr = shareFacade:GetManager("DataManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local scheduler = require('cocos.framework.scheduler')


function RemindIcon:ctor( ... )
	self.args = unpack({...})
	if self.args.imgPath then
		if string.byte(self.args.imgPath) == 35 then -- first char is #
			local imgPath = app.plistMgr:checkSpriteFrame(self.args.imgPath)
			if string.byte(imgPath) == 35 then -- first char is #
				self:setSpriteFrame(string.sub(imgPath, 2))
			else
				self:setTexture(_res(imgPath))
			end
		else
			self:setTexture(_res(self.args.imgPath))
		end
	else
		self:setTexture(_res('ui/common/common_hint_circle_red_ico.png'))
	end
	local po = self.args.po or cc.p(self.args.parent:getContentSize().width - 10, self.args.parent:getContentSize().height - 10)
	display.commonUIParams(self, {po = po})
	if self.args.tag then
		self:setRemindTag(self.args.tag)
	end
    -- self:setVisible(false)
    shareFacade:RegistObserver( COUNT_DOWN_ACTION, mvc.Observer.new(handler(self, self.redDotLogical), self))
end

function RemindIcon:getRemindTag()
	return checkint(self:getTag())
end
function RemindIcon:setRemindTag(tagId)
	local tag = checkint(tagId)
	self:setTag(tag)
	--如果是当前节点的逻辑，进行红点逻辑判断
	local num = dataMgr:GetRedDotNofication(tostring(tag), tag)
	if num > 0 then
		self:Animate(true) --显示小红点的逻辑
	else
		dataMgr:ClearRedDotNofication(tostring(tag), tag) --清除提定的提示红点的逻辑
		self:Animate(false)
	end
	if tag == RemindTag.BACKPACK_PLATE then
		--如果是餐盘加与背包相同的小红点
		local num = dataMgr:GetRedDotNofication(tostring(RemindTag.BACKPACK), RemindTag.BACKPACK)
		if num > 0 then
			self:Animate(true) --显示小红点的逻辑
		else
			dataMgr:ClearRedDotNofication(tostring(tag), tag) --清除提定的提示红点的逻辑
			self:Animate(false)
		end
	end
	if tag == RemindTag.ACTIVITY then
		-- 判断活动小红点是否开启
		self.activityScheduler = scheduler.scheduleGlobal(handler(self, self.onTimerScheduler), 1)
	elseif tag == RemindTag.SP_ACTIVITY then
		-- 判断特殊活动小红点是否开启
		self.spActivityScheduler = scheduler.scheduleGlobal(handler(self, self.SpActivityUpdate), 1)
	end
	if tag == RemindTag.SAIMOE_COMPOSABLE then
		self:Animate(false)
	end
end

function RemindIcon:redDotLogical(stage, signal)
	if tolua.isnull(self) then return end
	local body = signal:GetBody()
	if body.countdown and checkint(body.countdown) == 0 then
		local tag = checkint(body.tag)
		local selfTag = checkint(self:getTag())
		if selfTag == RemindTag.RECALL then
			if tag == RemindTag.RECALLEDMASTER or tag == RemindTag.RECALLH5 or tag == RemindTag.RECALL then
				local num = dataMgr:GetRedDotNofication(tostring(RemindTag.RECALLEDMASTER), RemindTag.RECALLEDMASTER)
				if num > 0 then
					self:Animate(true) --显示小红点的逻辑
					return
				end
				local num = dataMgr:GetRedDotNofication(tostring(RemindTag.RECALLH5), RemindTag.RECALLH5)
				if num > 0 then
					self:Animate(true) --显示小红点的逻辑
					return
				end
				local num = dataMgr:GetRedDotNofication(tostring(RemindTag.RECALL), RemindTag.RECALL)
				if num > 0 then
					self:Animate(true) --显示小红点的逻辑
					return
				end
				dataMgr:ClearRedDotNofication(tostring(tag), tag) --清除提定的提示红点的逻辑
				self:Animate(false)
			end
		elseif selfTag == RemindTag.SAIMOE_COMPOSABLE then
			self:Animate(body.isComposable or false)
		elseif checkint(tag) == selfTag then
			--如果是当前节点的逻辑，进行红点逻辑判断
			local num = dataMgr:GetRedDotNofication(tostring(tag), tag)
			if num > 0 then
				self:Animate(true) --显示小红点的逻辑
			else
				dataMgr:ClearRedDotNofication(tostring(tag), tag) --清除提定的提示红点的逻辑
				self:Animate(false)
			end
        elseif selfTag == RemindTag.BACKPACK_PLATE then
            --如果是餐盘加与背包相同的小红点
            local num = dataMgr:GetRedDotNofication(tostring(RemindTag.BACKPACK), RemindTag.BACKPACK)
            if num > 0 then
                self:Animate(true) --显示小红点的逻辑
            else
                dataMgr:ClearRedDotNofication(tostring(selfTag), selfTag) --清除提定的提示红点的逻辑
                self:Animate(false)
			end
        end
	end
end

function RemindIcon:UpdateLocalData()
	local tag = self:getTag()
	local num = dataMgr:GetRedDotNofication(tostring(tag), tag)
    -- print("--------------->>>",num)
	if num > 0 then
        if num > 1 then
            -- 	num = num - 1
            self:Animate(true) --显示小红点的逻辑
        else
            self:Animate(false)
            if tag ~= RemindTag.BACKPACK_PLATE then
                dataMgr:ClearRedDotNofication(tostring(tag), tag) --清除提定的提示红点的逻辑
            end
        end
	end
end
--[[
--开始红点的显示与闪动
--@animate 是否闪动的逻辑
--]]
function RemindIcon:Animate(animate)
    if not animate then
        -- self:stopAllActions()
        self:setVisible(false)
    else
        self:setVisible(true)
		-- self:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.6), cc.FadeOut:create(0.6))))
    end
end

--------------------------------------

function RemindIcon.addRemindIcon(params)
	local remindIcon = RemindIcon.new(params)
	remindIcon.args.parent:addChild(remindIcon, 100)
	return remindIcon
end
--[[
活动小红点判断定时器回调
--]]
function RemindIcon:onTimerScheduler( )

	-- 全服活动 tips
	-- local fullServerTip = false
	-- for i,v in pairs(gameMgr:GetUserInfo().serverTask) do
	-- 	if v == 1 then
	-- 		fullServerTip = true
	-- 		break
	-- 	end
	-- end
	-- local accumulativePayTip = false
	-- for i,v in pairs(gameMgr:GetUserInfo().accumulativePay) do
	-- 	if checkint(v) == 1 then
	-- 		accumulativePayTip = true
	-- 		break
	-- 	end
	-- end
	-- local binggoTaskTip = false
	-- for activityId, state in pairs(gameMgr:GetUserInfo().binggoTask) do
	-- 	if state == 1 then
	-- 		binggoTaskTip = true
	-- 		break
	-- 	end
	-- end
	-- local loginTip = false
	-- for activityId, state in pairs(gameMgr:GetUserInfo().login) do
	-- 	if checkint(state) == 1 then
	-- 		loginTip = true
	-- 		break
	-- 	end
	-- end
	-- local cvShareTip = false
	-- for activityId, state in pairs(gameMgr:GetUserInfo().cvShare) do
	-- 	if checkint(state) == 1 then
	-- 		cvShareTip = true
	-- 		break
	-- 	end
	-- end
	local tips = gameMgr:GetUserInfo().tips
	local isShowRed = false
	if (checkint(tips.monthlyLogin) == 1 or
		checkint(tips.newbie15Day) == 1 or 
		checkint(tips.seasonActivity)  == 1 or 
		checkint(tips.permanentSinglePay) == 1 or 
		checkint(tips.levelAdvanceChest) == 1 or 
		checkint(tips.levelReward) >= 1 or 
		checkint(tips.continuousActive) == 1 or 
		checkint(tips.newbieAccumulatePay) == 1 or 
		app.activityMgr:JudageSeasonFoodIsReward() == 1 or 
		app.badgeMgr:checkSpActivityRedPoint()) or
		self:HoneyBentoIsShowRemind()  or
		app.badgeMgr:CheckCrBoxActivityRedPoint() then
		isShowRed = true
	end
	self:Animate(isShowRed)
end
--[[
特殊活动小红点判断定时器回调
--]]
function RemindIcon:SpActivityUpdate()
	self:Animate(app.badgeMgr:checkSpActivityRedPoint())
end
--[[
判断爱心便当活动是否可领取
--]]
function RemindIcon:HoneyBentoIsOpenTime( startTime, endTime )
	if isElexSdk() then
		local serverTimeSecond = getServerTime()
		local startTimeText    = checkstr(startTime)
		local endedTimeText    = checkstr(endTime)
		local timezone         = getElexBentoTimezone() -- 首次登陆绑定的时区
		local startTimeData    = string.split(string.len(startTimeText) > 0 and startTimeText or '00:00', ':')
		local endedTimeData    = string.split(string.len(endedTimeText) > 0 and endedTimeText or '00:00', ':')
		local serverTimestamp  = os.date('!%Y-%m-%d _H_:_M_:00', serverTimeSecond + timezone + getServerTimezone())
		local startTimestamp   = string.fmt(serverTimestamp, {_H_ = startTimeData[1], _M_ = startTimeData[2]})
		local endedTimestamp   = string.fmt(serverTimestamp, {_H_ = endedTimeData[1], _M_ = endedTimeData[2]})
		local startTimeSecond  = timestampToSecond(startTimestamp) - timezone - getServerTimezone()
		local endedTimeSecond  = timestampToSecond(endedTimestamp) - timezone - getServerTimezone()
		return serverTimeSecond >= startTimeSecond and serverTimeSecond < endedTimeSecond
	else
		local serverTimeSecond = getServerTime()
		local startTimeText    = checkstr(startTime)
		local endedTimeText    = checkstr(endTime)
		local startTimeData    = string.split(string.len(startTimeText) > 0 and startTimeText or '00:00', ':')
		local endedTimeData    = string.split(string.len(endedTimeText) > 0 and endedTimeText or '00:00', ':')
		local serverTimestamp  = os.date('!%Y-%m-%d _H_:_M_:00', serverTimeSecond + getServerTimezone())
		local startTimestamp   = string.fmt(serverTimestamp, {_H_ = startTimeData[1], _M_ = startTimeData[2]})
		local endedTimestamp   = string.fmt(serverTimestamp, {_H_ = endedTimeData[1], _M_ = endedTimeData[2]})
		local startTimeSecond  = timestampToSecond(startTimestamp) - getServerTimezone()
		local endedTimeSecond  = timestampToSecond(endedTimestamp) - getServerTimezone()
		return serverTimeSecond >= startTimeSecond and serverTimeSecond < endedTimeSecond
	end
end
--[[
判断爱心便当活动小红点是否展示
--]]
function RemindIcon:HoneyBentoIsShowRemind()
	local isShow = false
	local loveBentoData = checktable(gameMgr:GetUserInfo().loveBentoData)
	for _, bentoData in pairs(loveBentoData) do
		if self:HoneyBentoIsOpenTime(bentoData.startTime, bentoData.endTime) then
			if checkint(bentoData.isReceived) == 0 then
				isShow = true
			end
		end
	end
	return isShow
end
function RemindIcon:onCleanup()
	--清理逻辑
    shareFacade:UnRegistObserver(COUNT_DOWN_ACTION,self)
	if self.activityScheduler then
		scheduler.unscheduleGlobal(self.activityScheduler)
	end
	if self.spActivityScheduler then
		scheduler.unscheduleGlobal(self.spActivityScheduler)
	end
end

return RemindIcon
