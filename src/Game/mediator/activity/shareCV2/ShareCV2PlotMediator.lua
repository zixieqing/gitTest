---@class ShareCV2PlotMediator : Mediator
local ShareCV2PlotMediator = class('ShareCV2PlotMediator', mvc.Mediator)
local NAME = "ShareCV2PlotMediator"
----@type ShareCVCell
local ShareCVCell = require("Game.views.activity.shareCV2.ShareCVCell")
function ShareCV2PlotMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
	self.shareData = {}
	self.currentIndex = 1
	self.displayType = 2
end

function ShareCV2PlotMediator:InterestSignals()
	local signals = {
		POST.ACTIVITY_NEW_SHARE.sglName ,
		POST.ACTIVITY_DRAW_NEW_SHARE_CV.sglName,
		POST.ACTIVITY_NEW_SHARE_CV_SHARE.sglName,
		"ACTIVITY_CVSHARE_SHARED" ,
		"ACTIVITY_CVSHARE_SHARE_FAILED"
	}
	return signals
end

function ShareCV2PlotMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = signal:GetBody()
	if name == POST.ACTIVITY_NEW_SHARE.sglName  then
		self.shareData  = body
		---@type ShareCV2PlotView
		local viewComponent = self:GetViewComponent()
		local  viewData = viewComponent.viewData
		viewComponent:UpdateCenterUI(self.shareData.cv[self.currentIndex])
		viewComponent:UpdatePlotCellSelect(0, self.currentIndex)
		viewData.grideView:setCountOfCell(table.nums(self.shareData.cv) )
		viewData.grideView:reloadData()
		viewData.pgrideView:setCountOfCell(table.nums(self.shareData.cv) )
		viewData.pgrideView:reloadData()
	elseif name == POST.ACTIVITY_DRAW_NEW_SHARE_CV.sglName  then
		local requestData = body.requestData
		local cvId = checkint(requestData.cvId)
		local index = 1
		for i, v in pairs(self.shareData.cv) do
			if checkint(v.cvId) == cvId  then
				v.hasDrawn = 1
				index = i
				break
			end
		end
		---@type ShareCV2PlotView
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		---@type ShareCVCell
		local cell =  viewData.grideView:cellAtIndex(index - 1)
		cell:UpdateCVCell((self.shareData.cv[index]))
		app.uiMgr:AddDialog('common.RewardPopup' , body)
	elseif name == POST.ACTIVITY_NEW_SHARE_CV_SHARE.sglName  then
		local requestData = body.requestData
		local cvId = checkint(requestData.cvId)
		local index = 1
		for i, v in pairs(self.shareData.cv) do
			if checkint(v.cvId) == cvId then
				v.hasDrawnShareRewards = 1
				v.progress = v.progress + 1
				index = i
				break
			end
		end
		---@type ShareCV2PlotView
		local viewComponent = self:GetViewComponent()
		if self.currentIndex == index then
			viewComponent:UpdateCenterUI(self.shareData.cv[index])
		end
		local cv = self.shareData.cv[index]
		local viewData = viewComponent.viewData
		local cell =  viewData.grideView:cellAtIndex(index-1)
		if cell and(not tolua.isnull(cell)) then
			cell:UpdateCVCell(cv)
		end
		viewComponent:UpdateCenterUI(self.shareData.cv[self.currentIndex])
		if body.rewards and (table.nums(body.rewards) > 0 ) then
			app.uiMgr:AddDialog('common.RewardPopup' , body)
		end
	elseif "ACTIVITY_CVSHARE_SHARED" == name then
		self:RemoveShareNode()
		local cv = self.shareData.cv
		local cvId =cv[self.currentIndex].cvId
		self:SendSignal(POST.ACTIVITY_NEW_SHARE_CV_SHARE.cmdName , { cvId = cvId })
	elseif name == "ACTIVITY_CVSHARE_SHARE_FAILED" then
		self:RemoveShareNode()
	end
end

-------------------------------------------------
------------------ inheritance ------------------
function ShareCV2PlotMediator:Initial( key )
	self.super.Initial(self, key)
	---@type ShareCV2PlotView
	local viewComponent = require("Game.views.activity.shareCV2.ShareCV2PlotView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	local closeBtn = viewData.closeBtn
	local grideView = viewData.grideView
	local shareCVBtn = viewData.shareCVBtn
	local pgrideView = viewData.pgrideView
	viewComponent:EnterAction()
	closeBtn:setOnClickScriptHandler(handler(self, self.CloseClick) )
	shareCVBtn:setOnClickScriptHandler(handler(self, self.ShareBtnClick) )
	grideView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSource))
	pgrideView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourcePlot))
end

function ShareCV2PlotMediator:OnDataSource(cell , idx  )
	if  not cell then
		---@type ShareCVCell
		cell = ShareCVCell.new()
	end
	xTry(function()
		local index = idx + 1
		local cv = self.shareData.cv
		local data = cv[index]
		cell:UpdateCVCell((data))
		local viewData = cell.viewData
		display.commonUIParams(viewData.cellLayout , { cb = handler( self , self.CellClick)})
		viewData.cellLayout:setTag(index)
	end,__G__TRACKBACK__)
	return cell
end
function ShareCV2PlotMediator:OnDataSourcePlot(cell , idx  )
	---@type ShareCV2PlotView
	local viewComponent = self:GetViewComponent()
	if  not cell then
		---@type ShareCVCell
		cell = viewComponent:CreatePlotCell()
	end
	xTry(function()
		local index = idx + 1
		local cv = self.shareData.cv
		local data = cv[index]
		viewComponent:UpdateCell(cell ,data )
		local viewData = cell.viewData
		display.commonUIParams(viewData.plotLayout , { cb = handler( self , self.CellPlotClick)})
		local isVisible = false
		if index ~= 1 then
			isVisible = self:IsVisibleRedByIndex(index)
		end
		viewData.redImage:setVisible(isVisible)
		

		if index == self.currentIndex then
			viewData.plotSelectImage:setVisible(true)
		else
			viewData.plotSelectImage:setVisible(false)
		end
		viewData.plotLayout:setTag(index)
	end,__G__TRACKBACK__)
	return cell
end
-- 关闭界面
function ShareCV2PlotMediator:CloseClick(sender)
	self:GetFacade():UnRegsitMediator(NAME)
end
-- cell 的点击事件
function ShareCV2PlotMediator:CellClick(sender)
	local index = sender:getTag()
	local cv = self.shareData.cv[index] or {}
	if checkint(cv.hasDrawn) == 1 then
		app.uiMgr:ShowInformationTips(__('已经领取任务奖励'))
		return
	else
		if checkint(cv.progress) >= checkint(cv.targetNum) then
			-- 可以领取奖励
			self:SendSignal(POST.ACTIVITY_DRAW_NEW_SHARE_CV.cmdName , {cvId =  checkint(cv.cvId)  })
		else
			-- 不可以领取奖励 直接显示获得的奖励内容
			app.uiMgr:ShowInformationTipsBoard({ targetNode = sender , iconIds = cv.rewards , type = 4 })
		end
	end
end
-- CellPlotClick 的点击事件
function ShareCV2PlotMediator:CellPlotClick(sender)
	local index = sender:getTag()
	local cv = self.shareData.cv[index] or {}
	-- 判断剧情是否开启
	if checkint(cv.isOpened) == 0   then
		app.uiMgr:ShowInformationTips(__('该cv剧情暂未开启'))
	else
		if self.currentIndex == index then
			return
		end
		---@type ShareCV2PlotView
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateCenterUI(self.shareData.cv[index] )
		viewComponent:UpdatePlotCellSelect(self.currentIndex , index)
		viewComponent:SetCellRedIsVisible(index , false)
		cc.UserDefault:getInstance():setIntegerForKey("SHARE_CV2_EVENT_"  .. index, 0  )
		self.currentIndex = index
	end
end
function ShareCV2PlotMediator:IsVisibleRedByIndex(index)
	local cv =  self.shareData.cv or {}
	local isOpened = cv[index] and checkint(cv[index].isOpened) or 0
	if isOpened == 0  then
		return false
	end
	local isVisible =  cc.UserDefault:getInstance():getIntegerForKey("SHARE_CV2_EVENT_"  .. index, 1  )
	isVisible = isVisible ==1 and true or false
	return isVisible
end
function ShareCV2PlotMediator:ShareBtnClick()
	self:AddCardView()
end
--[[
抽卡整卡页面
--]]
function ShareCV2PlotMediator:AddCardView()
	local cv = self.shareData.cv[self.currentIndex] or {}
	local shareRewards = cv.shareRewards
	local shareLang = {
		ANNIVERSARY19 = {
			title = "食之契约两周年庆！！！超多福利，全新童话副本来临，一起挑战超级BOSS，唯美外观，超高品阶飨灵等待御侍大人的光临",
			text = "食之契约两周年庆！！！超多福利，全新童话副本来临，一起挑战超级BOSS，唯美外观，超高品阶飨灵等待御侍大人的光临" ,
		} ,
		SPRIFES ={
			title = "超强飨灵上线，SP米饭重回缇尔菈大陆，还有飨灵们换上新衣与御侍大人共度鼠年#食之契约#。快来一起喜气洋洋迎新年，领取超多福利，美好永藏心间！",
			text = "超强飨灵上线，SP米饭重回缇尔菈大陆，还有飨灵们换上新衣与御侍大人共度鼠年#食之契约#。快来一起喜气洋洋迎新年，领取超多福利，美好永藏心间！" ,
		},
		ANNIVERSARY20 ={
			title = "《食之契约》三岁啦！周年庆典限时狂欢！「梦中迷途」周年大版本绚丽开启！全新SP飨灵-B-52鸡尾酒限时降临提尔菈大陆！UR飨灵-史多伦面包、伯爵茶和戚风蛋糕限时登场与您一起欢度庆典！参与「童谣绮梦」主题活动，还可获取超多豪华外观！",
			text = "《食之契约》三岁啦！周年庆典限时狂欢！「梦中迷途」周年大版本绚丽开启！全新SP飨灵-B-52鸡尾酒限时降临提尔菈大陆！UR飨灵-史多伦面包、伯爵茶和戚风蛋糕限时登场与您一起欢度庆典！参与「童谣绮梦」主题活动，还可获取超多豪华外观！" ,
		},
		NEW_YEAR_2021 = {
			title = "新春庆典限时狂欢！签到即送免费二十连召唤！新春主题版本【盛华年】将于2月5日华丽开启！全新SP飨灵-啤酒限时降临提尔菈大陆！SP飨灵限时狂欢全部返场！UR飨灵辣子鸡、烧仙草、菖蒲酒限时登场与您一同欢度新春佳节！参与【新春闲趣】外观卡池还可获取更多超稀有新春主题外观！",
			text = "新春庆典限时狂欢！签到即送免费二十连召唤！新春主题版本【盛华年】将于2月5日华丽开启！全新SP飨灵-啤酒限时降临提尔菈大陆！SP飨灵限时狂欢全部返场！UR飨灵辣子鸡、烧仙草、菖蒲酒限时登场与您一同欢度新春佳节！参与【新春闲趣】外观卡池还可获取更多超稀有新春主题外观！" ,
		}
	}
	local shareView = require( 'common.ActivityShareCommonView' ).new({
		shareRewards = shareRewards ,
		shared = cv.hasDrawnShareRewards ,
		bgPath     = _res(string.format("ui/home/activity/cv2/shareBg/%s", cv.taskGoods)),
		qrCodePath = _res(string.format("ui/home/activity/cv2/shareQr/%s", cv.taskGoods)),
		sglNameEvent = "ACTIVITY_CVSHARE_SHARED" ,
		title = shareLang.SPRIFES.title ,
		text = shareLang.SPRIFES.text ,
		myurl = nil, -- TODO 一个卡一个地址，伟浩加油！奥力给！！
		--namePath   = _res(string.format("ui/home/activity/cv2/shareName/%s", cv.taskGoods))
	})
	shareView:setName('ActivityCVShareShowView')
	local scene = app.uiMgr:GetCurrentScene()
	scene:AddDialog(shareView)
	scene:RemoveViewForNoTouch()
end
function ShareCV2PlotMediator:EnterLayer()
	self:SendSignal(POST.ACTIVITY_NEW_SHARE.cmdName , {} )
end
--[[
移除分享界面
--]]
function ShareCV2PlotMediator:RemoveShareNode()
	-- 移除分享界面
	local scene = app.uiMgr:GetCurrentScene()
	local activityCVShareCardView = scene:GetDialogByName('ActivityCVShareShowView')
	if activityCVShareCardView:getChildByName('ShareNode') then
		activityCVShareCardView:getChildByName('ShareNode'):runAction(cc.RemoveSelf:create())
	end
	if sceneWorld:getChildByName('btn_backButton') then
		sceneWorld:getChildByName('btn_backButton'):runAction(cc.RemoveSelf:create())
	end
	activityCVShareCardView.viewData_.shareCVLayout:setVisible(false)
end
function ShareCV2PlotMediator:OnRegist()
	regPost(POST.ACTIVITY_NEW_SHARE)
	regPost(POST.ACTIVITY_DRAW_NEW_SHARE_CV)
	regPost(POST.ACTIVITY_NEW_SHARE_CV_SHARE)
	self:EnterLayer()
	cc.UserDefault:getInstance():setBoolForKey(CV_SHARE_ACTIVITY_KEY, true)
end

function ShareCV2PlotMediator:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	viewData.closeBtn:setLocalZOrder(100)
	viewData.closeBtn:setEnabled(false)
	viewComponent:runAction(
		cc.Sequence:create(
			cc.Spawn:create(
				cc.FadeOut:create(0.2),
				cc.TargetedAction:create(
						viewData.colorLayer  ,
						cc.FadeOut:create(0.2)
				)
			),
			cc.RemoveSelf:create()
		)
	)
	unregPost(POST.ACTIVITY_NEW_SHARE)
	unregPost(POST.ACTIVITY_DRAW_NEW_SHARE_CV)
	unregPost(POST.ACTIVITY_NEW_SHARE_CV_SHARE)
	cc.UserDefault:getInstance():setBoolForKey(CV_SHARE_ACTIVITY_KEY, false)
end


return ShareCV2PlotMediator
