---@class ShareCV2TaskMediator : Mediator
local ShareCV2TaskMediator = class('ShareCV2TaskMediator', mvc.Mediator)
local NAME = "ShareCV2TaskMediator"
----@type ShareCVCell
local ShareCVCell = require("Game.views.activity.shareCV2.ShareCVCell")
function ShareCV2TaskMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
	params = params or {}
	self.detail = params.detail or ""
	self.title =  params.title or ""
	self.shareData = {}
end

function ShareCV2TaskMediator:InterestSignals()
	local signals = {
		POST.ACTIVITY_NEW_SHARE.sglName ,
		POST.ACTIVITY_NEW_SHARE_COMPOUND.sglName ,
		POST.ACTIVITY_DRAW_NEW_SHARE_COLLECT.sglName ,
		POST.ACTIVITY_NEW_SHARE_COLLECT_SHARE.sglName ,
		"ACTIVITY_CVSHARE_SHARED" ,
		"ACTIVITY_CVSHARE2_SHARED_BTN_EVENT",
		"ACTIVITY_CVSHARE_SHARE_FAILED",
		"COMPOUND_PHOTO_EVENT"
	}
	return signals
end
function ShareCV2TaskMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = signal:GetBody()
	if name == POST.ACTIVITY_NEW_SHARE.sglName  then
		local collect = body.collect
		self.shareData  = body
		---@type ShareCV2TaskView
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdatePhotoLayout(collect)
		viewComponent:UpdateUI(
			checkint(self.shareData.compound) ,
			checkint(self.shareData.collectShareRewardsHasDrawn) ,
			checktable(self.shareData.collectShareRewards)  ,
			checkint(self.shareData.collectedNum) ,
			table.nums(self.shareData.collect)
		)
		local  viewData = viewComponent.viewData
		viewData.grideView:setCountOfCell(table.nums(self.shareData.collect) )
		viewData.grideView:reloadData()
	elseif name == POST.ACTIVITY_DRAW_NEW_SHARE_COLLECT.sglName then
		local requestData = body.requestData
		local collectId = checkint(requestData.collectId)
		local index = 1
		for i, v in pairs(self.shareData.collect) do
			if checkint(v.collectId) == collectId  then
				v.hasDrawn = 1
				index = i
				break
			end
		end
		self.shareData.collectedNum = self.shareData.collectedNum +1
		---@type ShareCV2TaskView
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		---@type ShareCVCell
		local cell =  viewData.grideView:cellAtIndex(index - 1)
		cell:UpdateTaskCell(self.shareData.collect[index])
		viewComponent:UpdatePrograssLayout(self.shareData.collectedNum ,  table.nums(self.shareData.collect) )
		app.uiMgr:AddDialog('common.RewardPopup' , body)
	elseif name == POST.ACTIVITY_NEW_SHARE_COLLECT_SHARE.sglName then
		if self.shareData.collectShareRewardsHasDrawn == 1 then
			return
		end
		self.shareData.collectShareRewardsHasDrawn = 1
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateUI(checkint(self.shareData.compound) ,
				checkint(self.shareData.collectShareRewardsHasDrawn) ,
				checktable(self.shareData.collectShareRewards)  ,
				checkint(self.shareData.collectedNum) ,
				table.nums(self.shareData.collect)
		)
		if body.rewards and (table.nums(body.rewards) > 0 ) then
			app.uiMgr:AddDialog('common.RewardPopup' , body)
		end
	elseif name == POST.ACTIVITY_NEW_SHARE_COMPOUND.sglName then
		self.shareData.compound = 1
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateUI(checkint(self.shareData.compound) ,
			checkint(self.shareData.collectShareRewardsHasDrawn) ,
			checktable(self.shareData.collectShareRewards)  ,
			checkint(self.shareData.collectedNum) ,
			checkint(self.shareData.totalNum)
		)
	elseif name == "ACTIVITY_CVSHARE_SHARED" then
		self:RemoveShareNode()
		self:SendSignal(POST.ACTIVITY_NEW_SHARE_COLLECT_SHARE.cmdName , {})
	elseif name == "ACTIVITY_CVSHARE2_SHARED_BTN_EVENT" then
	 	self:AddCardView()
	elseif name == "ACTIVITY_CVSHARE_SHARE_FAILED" then
		self:RemoveShareNode()
	elseif name == "COMPOUND_PHOTO_EVENT" then
		local compound = checkint(self.shareData.compound)
		local collectedNum = checkint(self.shareData.collectedNum)
		if compound == 1 then
			app.uiMgr:ShowInformationTips(__('已经合成拼图'))
		else
			if collectedNum >= #self.shareData.collect  then
				self:SendSignal(POST.ACTIVITY_NEW_SHARE_COMPOUND.cmdName , {})
			else
				app.uiMgr:ShowInformationTips(__('拼图未全部收集'))
			end
		end
	end
end

--[[
抽卡整卡页面
--]]
function ShareCV2TaskMediator:AddCardView()
	local shareRewards = self.shareData.collectShareRewards
	local collectShareRewardsHasDrawn = self.shareData.collectShareRewardsHasDrawn or {}
	local collectedNum  = checkint(self.shareData.collectedNum)
	local picture = self.shareData.collect[collectedNum].picture
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
		shared = collectShareRewardsHasDrawn  ,
		sglNameEvent = "ACTIVITY_CVSHARE_SHARED" ,
		title = shareLang.SPRIFES.title ,
		text = shareLang.SPRIFES.text ,
		bgPath     = _res(string.format("ui/home/activity/cv2/photoSe/%s", picture))
	})
	shareView:setName('ActivityCVShareShowView')
	local scene = app.uiMgr:GetCurrentScene()
	scene:AddDialog(shareView)
	scene:RemoveViewForNoTouch()
end
-------------------------------------------------
------------------ inheritance ------------------
function ShareCV2TaskMediator:Initial( key )
	self.super.Initial(self, key)
	---@type ShareCV2TaskView
	local viewComponent = require("Game.views.activity.shareCV2.ShareCV2TaskView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	local closeBtn = viewData.closeBtn
	local completeBtn = viewData.completeBtn
	local grideView = viewData.grideView
	local tipBtn = viewData.tipBtn
	viewComponent:EnterAction()
	closeBtn:setOnClickScriptHandler(handler(self, self.CloseClick) )
	completeBtn:setOnClickScriptHandler(handler(self,self.GoToTaskMediator) )
	tipBtn:setOnClickScriptHandler(handler(self,self.TipClick) )
	grideView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSource))
end

function ShareCV2TaskMediator:OnDataSource(cell , idx  )
	if  not cell then
		---@type ShareCVCell
		cell = ShareCVCell.new()
	end
	xTry(function()
		local index = idx + 1
		local collect = self.shareData.collect
		local data = collect[index]
		cell:UpdateTaskCell(data)
		local viewData = cell.viewData
		display.commonUIParams(viewData.cellLayout , { cb = handler( self , self.CellClick)})
		viewData.cellLayout:setTag(index)
	end,__G__TRACKBACK__)
	return cell
end
-- 关闭界面
function ShareCV2TaskMediator:CloseClick(sender)
	self:GetFacade():UnRegsitMediator(NAME)
end
-- 规则显示
function ShareCV2TaskMediator:TipClick(sender)
	app.uiMgr:ShowIntroPopup({ descr = self.detail , title = self.title })
end
-- cell 的点击事件
function ShareCV2TaskMediator:CellClick(sender)
	local index = sender:getTag()
	local collect = self.shareData.collect[index] or {}
	if checkint(collect.hasDrawn) == 1 then
		app.uiMgr:ShowInformationTips(__('已经领取任务奖励'))
		return
	else
		if checkint(collect.progress) >= checkint(collect.targetNum) then
			-- 可以领取奖励
			self:SendSignal(POST.ACTIVITY_DRAW_NEW_SHARE_COLLECT.cmdName , {collectId =  checkint(collect.collectId)  })
		else
			-- 不可以领取奖励 直接显示获得的奖励内容
			app.uiMgr:ShowInformationTipsBoard({ targetNode = sender , iconIds = collect.rewards , type = 4 })
		end
	end
end
-- 前往任务界面
function ShareCV2TaskMediator:GoToTaskMediator(sender)
	self:GetFacade():BackHomeMediator()
	---@type Router
	local router = self:GetFacade():RetrieveMediator("Router")
	router:Dispatch({}  , { name = 'task.TaskHomeMediator' })
end
--[[
移除分享界面
--]]
function ShareCV2TaskMediator:RemoveShareNode()
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
function ShareCV2TaskMediator:EnterLayer()
	self:SendSignal(POST.ACTIVITY_NEW_SHARE.cmdName , {} )
end

function ShareCV2TaskMediator:OnRegist()
	regPost(POST.ACTIVITY_NEW_SHARE)
	regPost(POST.ACTIVITY_DRAW_NEW_SHARE_COLLECT)
	regPost(POST.ACTIVITY_NEW_SHARE_COMPOUND)
	regPost(POST.ACTIVITY_NEW_SHARE_COLLECT_SHARE)
	self:EnterLayer()
	cc.UserDefault:getInstance():setBoolForKey(CV_SHARE_ACTIVITY_KEY, true)
end


function ShareCV2TaskMediator:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	viewData.closeBtn:setLocalZOrder(100)
	viewData.closeBtn:setEnabled(false)
	viewComponent:runAction(
		cc.Sequence:create(
			cc.Spawn:create(
				--cc.TargetedAction:create(viewData.grideView ,cc.FadeOut:create(0.2)) ,
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
	unregPost(POST.ACTIVITY_DRAW_NEW_SHARE_COLLECT)
	unregPost(POST.ACTIVITY_NEW_SHARE_COLLECT_SHARE)
	unregPost(POST.ACTIVITY_NEW_SHARE_COMPOUND)
	cc.UserDefault:getInstance():setBoolForKey(CV_SHARE_ACTIVITY_KEY, false)
end


return ShareCV2TaskMediator
