--[[
奖励mediator
--]]
local Mediator = mvc.Mediator
---@class ActivityChestSmallMediator :Mediator
local ActivityChestSmallMediator = class("ActivityChestSmallMediator", Mediator)
local NAME = "Game.mediator.activity.chest.ActivityChestSmallMediator"
ActivityChestSmallMediator.NAME = NAME
local CHEST_STATUS = {
	NOT_OPEN     = 1,  --未打开
	DO_OPENING   = 2,  --打开中
	ALREADY_OPEN = 3,  --已打开
}

--[[{
		chestId  , 宝箱id
		status  , 宝箱状态
		openLeftSeconds  ， 倒计时
		refreshSgl  ， 刷新倒计时
	}
--]]
function ActivityChestSmallMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
	self.chestId = params.chestId
	self.status = params.status
	self.openLeftSeconds = params.openLeftSeconds
	self.refreshSgl = params.refreshSgl
	self.placeId = params.placeId
	self.activityId = params.activityId
	self.canUnlock = params.canUnlock
end
function ActivityChestSmallMediator:InterestSignals()
	return {
		self.refreshSgl,
		POST.ACTIVITY2_CR_BOX_OPEN_BOX.sglName,
		POST.ACTIVITY2_CR_BOX_DRAW_BOX.sglName
	}
end

function ActivityChestSmallMediator:ProcessSignal(signal)
	local name = signal:GetName()
	if name == self.refreshSgl then
		local body = signal:GetBody()
		local viewComponent = self:GetViewComponent()
		self.openLeftSeconds = body.countdown
		if self.openLeftSeconds == 0 then
			viewComponent:UpdateChestStatus(self.chestId , self.status   , self.openLeftSeconds)
		else
			viewComponent:UpdateChestTimeDiamond(self.chestId , self.openLeftSeconds)
			viewComponent:UpdateOpenTimeLabel( self.openLeftSeconds)
		end
	elseif name == POST.ACTIVITY2_CR_BOX_DRAW_BOX.sglName then
		self:GetFacade():UnRegistMediator(NAME)
	elseif name == POST.ACTIVITY2_CR_BOX_OPEN_BOX.sglName then
		local body = signal:GetBody()
		local viewComponent = self:GetViewComponent()
		self.status = CHEST_STATUS.DO_OPENING
		self.openLeftSeconds = body.leftSeconds
		viewComponent:UpdateChestStatus(self.chestId , self.status   , self.openLeftSeconds)
	end
end

-- inheritance method
function ActivityChestSmallMediator:Initial(key)
	self.super.Initial(self, key)
	---@type ActivityChestSmallView
	local viewComponent =  require("Game.views.activity.chest.ActivityChestSmallView").new()
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	self:SetViewComponent(viewComponent)
	local viewData = viewComponent.viewData
	display.commonUIParams(viewData.closeLayer , {cb = handler(self, self.CloseClick) ,animate = false})
	display.commonUIParams(viewData.leftBtn , {cb = handler(self, self.UnLockClick) })
	display.commonUIParams(viewData.rightBtn , {cb = handler(self, self.QuickOpenChestClick) })
	viewComponent:UpdateView(self.chestId)
	viewComponent:UpdateChestStatus(self.chestId, self.status , self.openLeftSeconds)
end

function ActivityChestSmallMediator:CloseClick()
	self:GetFacade():UnRegistMediator(NAME)
end

function ActivityChestSmallMediator:UnLockClick(sender)
	if self.status == CHEST_STATUS.NOT_OPEN then
		if not self.canUnlock then
			app.uiMgr:ShowInformationTips(__('解锁已达上限'))
			return
		end
		self:SendSignal(POST.ACTIVITY2_CR_BOX_OPEN_BOX.cmdName,{
			activityId = self.activityId ,
			placeId = self.placeId
		})
	elseif self.status == CHEST_STATUS.DO_OPENING then
		if self.openLeftSeconds == 0  then
			self:SendSignal(POST.ACTIVITY2_CR_BOX_DRAW_BOX.cmdName , {
				activityId = self.activityId ,
				placeId = self.placeId , type = 1
			})
		else
			app.uiMgr:ShowInformationTips(__('正在解锁中'))
			return
		end
	end
end

function ActivityChestSmallMediator:QuickOpenChestClick(sender)
	local crBoxConf = CONF.GOODS.CR_BOX:GetValue(self.chestId)
	local openConsume = crBoxConf.openConsume
	local openTime = crBoxConf.openTime
	if openConsume[1] then
		local needNum = nil
		if self.status == CHEST_STATUS.NOT_OPEN then
			needNum = openConsume[1].num
		elseif self.status == CHEST_STATUS.DO_OPENING then
			needNum = math.ceil(self.openLeftSeconds/openTime * openConsume[1].num )
		end
		local ownNum = CommonUtils.GetCacheProductNum(openConsume[1].goodsId)
		if needNum > ownNum then
			local goodName = CommonUtils.GetCacheProductName(openConsume[1].goodsId)
			app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足') , {_name_ = goodName}))
			return
		end
		app.uiMgr:AddNewCommonTipDialog({
			text = __('确定消耗幻晶石解锁伴手礼'),
			callback = function()
				self:SendSignal(POST.ACTIVITY2_CR_BOX_DRAW_BOX.cmdName , {
					activityId = self.activityId ,
					placeId = self.placeId ,
					type = 2 , num = needNum
				})
			end
		})

	end
end

function ActivityChestSmallMediator:OnRegist()
	regPost(POST.ACTIVITY2_CR_BOX_OPEN_BOX)
end

function ActivityChestSmallMediator:OnUnRegist()
	unregPost(POST.ACTIVITY2_CR_BOX_OPEN_BOX)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:runAction(cc.RemoveSelf:create())
	end
end

return ActivityChestSmallMediator
