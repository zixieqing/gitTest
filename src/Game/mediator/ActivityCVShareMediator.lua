--[[
CV分享活动mediator
--]]
local Mediator = mvc.Mediator
local ActivityCVShareMediator = class("ActivityCVShareMediator", Mediator)
local NAME = "ActivityCVShareMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local scheduler = require('cocos.framework.scheduler')
local CVShareCell = require('home.CVShareCell')
Card_State = {
	SHARED    = 1, -- 已分享
	CAN_SHARE = 2, -- 可分享
	LOCKED   = 3, -- 卡牌未获得
}
function ActivityCVShareMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	local datas = params or {}
	self.activityhomeDatas = datas
	self.activityId = checkint(datas.activityId) -- 活动Id
	self.activityDatas = {} -- 活动数据
	self.chestDatas = {} -- 宝箱数据
	self.drawCvId = nil -- 抽到的CvId
	self.enterTimeStamp = 0 -- 进入的时间戳
	self.displayType = 1 -- 界面类型（1：竖版，2：横版）

end


function ActivityCVShareMediator:InterestSignals()
	local signals = {
		POST.ACTIVITY_CVSHARE.sglName,
		POST.ACTIVITY_CVSHARE_GAMBLING.sglName,
		POST.ACTIVITY_CVSHARE_SHARE_SUCCESS.sglName,
		POST.ACTIVITY_DRAW_CVSHARE.sglName,
		"ACTIVITY_CVSHARE_CAPSULE",
		"SHARE_REQUEST_RESPONSE",
		"ACTIVITY_CVSHARE_SHARE_FAILED",
		"NEXT_TIME_DATE" -- 恢复免费次数
	}
	return signals
end

function ActivityCVShareMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	local datas = checktable(signal:GetBody())
	if name == POST.ACTIVITY_CVSHARE.sglName then
		self.activityDatas = checktable(datas)
		self.displayType = checkint(self.activityDatas.displayType or 1)
		self:RefreshView()
	elseif name == POST.ACTIVITY_CVSHARE_GAMBLING.sglName then
		self.drawCvId = checkint(datas.cvId)
		if checkint(self.activityDatas.leftFreeGamblingTimes) > 0 then
			self.activityDatas.leftFreeGamblingTimes = checkint(self.activityDatas.leftFreeGamblingTimes) - 1
		elseif checkint(self.activityDatas.leftGamblingTimes) > 0 then
			if checkint(self.activityDatas.leftGamblingTimes) == checkint(self.activityDatas.gamblingTimesMax) then
				self.activityDatas.nextGamblingTimeRecoverySeconds = checkint(self.activityDatas.gamblingTimeCd)
			end
			self.activityDatas.leftGamblingTimes = checkint(self.activityDatas.leftGamblingTimes) - 1
		end
		self:AddCapsuleAction()
	elseif name == POST.ACTIVITY_CVSHARE_SHARE_SUCCESS.sglName then
		self:DrawShareRewards(datas.rewards)
	elseif name == POST.ACTIVITY_DRAW_CVSHARE.sglName then
		self:DrawChestRewards(datas)
	elseif name == "ACTIVITY_CVSHARE_CAPSULE" then
		self:AddCardView()
		-- 更新本地数据
		for i, v in ipairs(self.activityDatas.cvList) do
			if checkint(v.cvId) == self.drawCvId then
				v.collected = 1
				break
			end
		end
		self:RefreshView()
	elseif name == "SHARE_REQUEST_RESPONSE" then
		self:RemoveShareNode()
		-- 判断是否可以领取奖励
		for i, v in ipairs(self.activityDatas.cvList) do
			if checkint(v.cvId) == self.drawCvId then
				if checkint(v.shared) == 0 then
					self:SendSignal(POST.ACTIVITY_CVSHARE_SHARE_SUCCESS.cmdName, {activityId = self.activityId, cvId = self.drawCvId})
				end
				break
			end
		end
	elseif name == "ACTIVITY_CVSHARE_SHARE_FAILED" then
		self:RemoveShareNode()
	elseif name == "NEXT_TIME_DATE" then
		self:SendSignal(POST.ACTIVITY_CVSHARE.cmdName, {activityId = self.activityId})
	end
end

function ActivityCVShareMediator:Initial( key )
	self.super.Initial(self, key)
	-- 创建MailPopup
	local viewComponent = require( 'Game.views.ActivityCVShareView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(viewComponent)
	for i,v in ipairs(viewComponent.viewData_.chestDatas) do
		v.chestBtn:setOnClickScriptHandler(handler(self, self.ChestBtnCallback))
	end

	viewComponent.viewData_.drawBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
	viewComponent.viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.ListDataSource))
end
--[[
刷新活动页面
--]]
function ActivityCVShareMediator:RefreshView()
	local viewData = self:GetViewComponent().viewData_
	if not self.recoverScheduler then
		self.recoverScheduler = scheduler.scheduleGlobal(handler(self, self.UpdateRecoverTimeLabel), 1)
		self.enterTimeStamp = os.time()
		self.activityDatas.nextGamblingTimeRecoverySeconds = checkint(self.activityDatas.nextGamblingTimeRecoverySeconds) + 3
	end
	self:UpdateCardListState()
	-- 添加奖励宝箱
	self:RefreshChestLayout()
	self:RefreshDrawBtn()
	viewData.gridView:setCountOfCell(#checktable(self.activityDatas.cvList))
    viewData.gridView:reloadData()
end
--[[
列表数据处理
--]]
function ActivityCVShareMediator:ListDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = self:GetViewComponent().viewData_.gridlistCellSize
    if pCell == nil then
        pCell = CVShareCell.new(cSize)
		pCell.bgBtn:setOnClickScriptHandler(handler(self, self.HeadIconCallback))
    end
	xTry(function()
		local datas = self.activityDatas.cvList[index]
		local imagePath = string.format('ui/home/activity/cvShare/head/activity_cv_cvsharecards_%s.png', tostring(datas.cvId))
		pCell.headIcon:setTexture(imagePath or 'ui/home/activity/cvShare/head/activity_cv_cvsharecards_1.png')
		pCell.bgBtn:setTag(index)
		if checkint(datas.state) == Card_State.SHARED then -- 已分享
			pCell.headIcon:clearFilter()
			pCell.shareLabel:setVisible(false)
		elseif checkint(datas.state) == Card_State.CAN_SHARE then -- 可分享
			pCell.headIcon:clearFilter()
			pCell.shareLabel:setVisible(true)
		elseif checkint(datas.state) == Card_State.LOCKED then -- 未获取
			pCell.headIcon:setFilter(filter.newFilter('GRAY'))
			pCell.shareLabel:setVisible(false)
		end
	end,__G__TRACKBACK__)
    return pCell
end
--[[
头像点击回调
--]]
function ActivityCVShareMediator:HeadIconCallback( sender )

	local index = sender:getTag()
	local cvDatas = self.activityDatas.cvList[index]
	self.drawCvId = checkint(cvDatas.cvId)
	if checkint(cvDatas.state) == Card_State.SHARED then
		PlayAudioByClickNormal()
		self:AddCardView()
	elseif checkint(cvDatas.state) == Card_State.CAN_SHARE then
		PlayAudioByClickNormal()
		self:AddCardView()
	elseif checkint(cvDatas.state) == Card_State.LOCKED then
		uiMgr:ShowInformationTips(__('当前未获得此插图'))
	end
end
--[[
更新卡牌状态
--]]
function ActivityCVShareMediator:UpdateCardListState()
	for i, v in ipairs(self.activityDatas.cvList) do
		if checkint(v.collected) == 1 then
			if checkint(v.shared) == 1 then
				v.state = Card_State.SHARED
			else
				v.state = Card_State.CAN_SHARE
			end
		else
			v.state = Card_State.LOCKED
		end
	end
end
--[[
抽奖按钮点击回调
--]]
function ActivityCVShareMediator:DrawButtonCallback( sender )
	PlayAudioByClickNormal()
	if checkint(self.activityDatas.leftFreeGamblingTimes) > 0 or checkint(self.activityDatas.leftGamblingTimes) > 0 then
		self:SendSignal(POST.ACTIVITY_CVSHARE_GAMBLING.cmdName, {activityId = self.activityId})
	else
		uiMgr:ShowInformationTips(__('次数不足'))
	end
end
--[[
添加抽奖动画
--]]
function ActivityCVShareMediator:AddCapsuleAction()
	local activityCVShareCapsuleView = require( 'Game.views.ActivityCVShareCapsuleView' ).new()
	local scene = uiMgr:GetCurrentScene()
	scene:AddViewForNoTouch()
	scene:AddDialog(activityCVShareCapsuleView)
end
--[[
宝箱点击回调
--]]
function ActivityCVShareMediator:ChestBtnCallback( sender )
	local tag = sender:getTag()
	local rewardDatas = self.activityDatas.collectRewards[tag]
	local sharedNum = checkint(self:GetSharedNum())
	local targetNum = checkint(rewardDatas.target)
	if sharedNum >= targetNum then
		if checkint(rewardDatas.hasDrawn) == 0 then
			PlayAudioByClickNormal()
			self:SendSignal(POST.ACTIVITY_DRAW_CVSHARE.cmdName, {activityId = self.activityId, collectId = checkint(rewardDatas.collectId)})
		end
	else
		PlayAudioByClickNormal()
		uiMgr:ShowInformationTipsBoard({targetNode = sender, iconIds = rewardDatas.rewards, type = 4})
	end
end
--[[
添加分享奖励宝箱
--]]
function ActivityCVShareMediator:RefreshChestLayout()
	local viewData = self:GetViewComponent().viewData_
	local activityDatas = checktable(self.activityDatas)
	local maxTarget = checkint(activityDatas.collectRewards[#activityDatas.collectRewards].target) -- 最大目标数
	local sharedNum = checkint(self:GetSharedNum()) -- 分享次数
	for i=1, 3 do -- 修改宝箱位置
		local chest = viewData.chestDatas[i] -- 宝箱
		if activityDatas.collectRewards[i] then
			local datas = activityDatas.collectRewards[i] -- 奖励数据
			local sharedNum = checkint(self:GetSharedNum()) --分享次数
			local targetNum = checkint(datas.target) -- 目标次数
			chest.chestLayout:setPositionX(65 + viewData.progressBarWidth / maxTarget * targetNum)
			chest.collectNum:setString(string.format('(%d/%d)', math.min(sharedNum, targetNum), targetNum))
			if sharedNum >= targetNum then
				if checkint(datas.hasDrawn) == 0 then
           			chest.chestSpine:update(0)
            		chest.chestSpine:setToSetupPose()
		            chest.chestSpine:setAnimation(0, 'idle', true)
				else
            		chest.chestSpine:update(0)
            		chest.chestSpine:setToSetupPose()
					chest.chestSpine:setAnimation(0, 'play', true)
				end
				chest.chestIcon:setVisible(false)
				chest.chestSpine:setVisible(true)
			else
				chest.chestIcon:setVisible(true)
				chest.chestSpine:setVisible(false)
			end
			chest.chestLayout:setVisible(true)
		else
			chest.chestLayout:setVisible(false)
		end
	end
	-- 刷新进度
    viewData.progressBar:setMaxValue(maxTarget)
   	viewData.progressBar:setValue(sharedNum)
   	viewData.progressNums:setString(string.format('(%d/%d)', math.min(sharedNum, maxTarget), maxTarget))
end
--[[
刷新抽卡按钮
--]]
function ActivityCVShareMediator:RefreshDrawBtn()
	local viewData = self:GetViewComponent().viewData_
	local activityDatas = self.activityDatas
	-- 刷新剩余抽卡次数
	if checkint(activityDatas.leftFreeGamblingTimes) > 0 then
		-- 存在免费次数
		viewData.numLabel:setString(__('每日首次免费'))
	else
		viewData.numLabel:setString(string.format('(%s/%s)', tostring(activityDatas.leftGamblingTimes),tostring(activityDatas.gamblingTimesMax)))
	end
	-- 更新剩余时间
	self:UpdateRecoverTimes()
	if checkint(activityDatas.leftGamblingTimes) == checkint(activityDatas.gamblingTimesMax) then
		viewData.recoverRichLabel:setVisible(false)
	else
		viewData.recoverRichLabel:setVisible(true)
	end
end
--[[
抽卡整卡页面
--]]
function ActivityCVShareMediator:AddCardView()
	local cvDatas = nil
	for i, v in ipairs(self.activityDatas.cvList) do
		if checkint(v.cvId) == self.drawCvId then
			cvDatas = clone(v)
			break
		end
	end
	local shareView = nil 
	if self.displayType == 1 then
		shareView = require( 'Game.views.ActivityCVShareCardView' ).new({cvDatas = cvDatas, shareRewards = self.activityDatas.shareRewards})
	elseif self.displayType == 2 then
		shareView = require( 'Game.views.ActivityCVShareCGView' ).new({cvDatas = cvDatas, shareRewards = self.activityDatas.shareRewards})
	end
	
	shareView:setName('ActivityCVShareShowView')
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(shareView)	
	scene:RemoveViewForNoTouch()

end
--[[
更新抽卡恢复时间
--]]
function ActivityCVShareMediator:UpdateRecoverTimes(  )
	local recoverRichLabel = self:GetViewComponent().viewData_.recoverRichLabel
	display.reloadRichLabel(recoverRichLabel, {c =
		{
			fontWithColor(10, {text = string.formattedTime(checkint(self.activityDatas.nextGamblingTimeRecoverySeconds),'%02i:%02i:%02i')}),
			fontWithColor(16, {text = __('后增加1次')})
		}
	})
	CommonUtils.SetNodeScale(recoverRichLabel ,{ width = 240})
end
--[[
获取已经分享的次数
--]]
function ActivityCVShareMediator:GetSharedNum()
	local nums = 0
	for i,v in ipairs(checktable(self.activityDatas.cvList)) do
		if checkint(v.shared) == 1 then
			nums = nums + 1
		end
	end
	return nums
end
--[[
领取分享奖励
--]]
function ActivityCVShareMediator:DrawShareRewards( rewards )
	uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
	local scene = uiMgr:GetCurrentScene()
	local activityCVShareCardView = scene:GetDialogByName('ActivityCVShareShowView')
	if activityCVShareCardView then
		activityCVShareCardView.viewData_.rewardLabel:setVisible(false)
		for i, v in ipairs(self.activityDatas.cvList) do
			if checkint(v.cvId) == self.drawCvId then
				v.shared = 1
				break
			end
		end
		self:RefreshView()
	end
end
--[[
移除分享界面
--]]
function ActivityCVShareMediator:RemoveShareNode()
	-- 移除分享界面
	local scene = uiMgr:GetCurrentScene()
	local activityCVShareCardView = scene:GetDialogByName('ActivityCVShareShowView')
	if activityCVShareCardView:getChildByName('ShareNode') then
		activityCVShareCardView:getChildByName('ShareNode'):runAction(cc.RemoveSelf:create())
	end
	if sceneWorld:getChildByName('btn_backButton') then
		sceneWorld:getChildByName('btn_backButton'):runAction(cc.RemoveSelf:create())
	end
	activityCVShareCardView.viewData_.shareImg:setVisible(false)
end
--[[
领取宝箱奖励
--]]
function ActivityCVShareMediator:DrawChestRewards( datas )
	uiMgr:AddDialog('common.RewardPopup', {rewards = datas.rewards})
	for i,v in ipairs(self.activityDatas.collectRewards) do
		if checkint(v.collectId) == checkint(datas.requestData.collectId) then
			v.hasDrawn = 1
			break
		end
	end
	self:RefreshView()
end
--[[
定时器回调
--]]
function ActivityCVShareMediator:UpdateRecoverTimeLabel()
	local curTime = os.time()
	local deltaTime = math.abs(curTime - self.enterTimeStamp)
	self.enterTimeStamp = curTime
	if checkint(self.activityDatas.leftGamblingTimes) < checkint(self.activityDatas.gamblingTimesMax) and checkint(self.activityDatas.nextGamblingTimeRecoverySeconds) > 0 then
		self.activityDatas.nextGamblingTimeRecoverySeconds = self.activityDatas.nextGamblingTimeRecoverySeconds - deltaTime
		while self.activityDatas.nextGamblingTimeRecoverySeconds <= 0 do
			self.activityDatas.nextGamblingTimeRecoverySeconds = self.activityDatas.nextGamblingTimeRecoverySeconds + checkint(self.activityDatas.gamblingTimeCd)
			self.activityDatas.leftGamblingTimes = checkint(self.activityDatas.leftGamblingTimes) + 1
			if checkint(self.activityDatas.leftGamblingTimes) == checkint(self.activityDatas.gamblingTimesMax) then
				self.activityDatas.nextGamblingTimeRecoverySeconds = 0
				break
			end
		end
		self:RefreshDrawBtn()
	end
end
function ActivityCVShareMediator:EnterLayer()
	self:SendSignal(POST.ACTIVITY_CVSHARE.cmdName, {activityId = self.activityId})
end
function ActivityCVShareMediator:OnRegist(  )
	regPost(POST.ACTIVITY_CVSHARE)
	regPost(POST.ACTIVITY_CVSHARE_GAMBLING)
	regPost(POST.ACTIVITY_CVSHARE_SHARE_SUCCESS)
	regPost(POST.ACTIVITY_DRAW_CVSHARE)
	-- 添加活动分享标识
	cc.UserDefault:getInstance():setBoolForKey(CV_SHARE_ACTIVITY_KEY, true)
	self:EnterLayer()
end

function ActivityCVShareMediator:OnUnRegist(  )
	unregPost(POST.ACTIVITY_CVSHARE)
	unregPost(POST.ACTIVITY_CVSHARE_GAMBLING)
	unregPost(POST.ACTIVITY_CVSHARE_SHARE_SUCCESS)
	unregPost(POST.ACTIVITY_DRAW_CVSHARE)
	-- 移除活动分享标识
	cc.UserDefault:getInstance():setBoolForKey(CV_SHARE_ACTIVITY_KEY, false)
	-- 移除定时器
	if self.recoverScheduler then
		scheduler.unscheduleGlobal(self.recoverScheduler)
	end
	-- 移除界面
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveViewForNoTouch()
	scene:RemoveDialog(self:GetViewComponent())

end
return ActivityCVShareMediator