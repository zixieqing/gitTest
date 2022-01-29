--[[
活动弹出页 等级礼包 mediator    
--]]
local Mediator = mvc.Mediator
local ActivityLevelGiftPopupMediator = class("ActivityLevelGiftPopupMediator", Mediator)
local NAME = "ActivityLevelGiftPopupMediator"
function ActivityLevelGiftPopupMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.showSpine = false
end

function ActivityLevelGiftPopupMediator:InterestSignals()
	local signals = {
        POST.LEVEL_GIFT_CHEST.sglName,
        SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback,
	}
	return signals
end

function ActivityLevelGiftPopupMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    print(name)
    if name == POST.LEVEL_GIFT_CHEST.sglName then
        self:RefreshLevelChest()
    elseif name == SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback then
		if signal:GetBody().requestData.name ~= 'levelChest' then return end
		if body.orderNo then
			if device.platform == 'android' or device.platform == 'ios' then
				local AppSDK = require('root.AppSDK')
				local price =  checkint( self.curLevelData.price)
				if checkint(self.curLevelData.discountLeftSeconds) > 0 then
					price = checkint( self.curLevelData.discountPrice)
				end
				AppSDK.GetInstance():InvokePay({amount =  price  , property = body.orderNo, goodsId = tostring(self.curLevelData.channelProductId), goodsName = __('幻晶石'), quantifier = __('个'),price = 0.1, count = 1})
			end
		end
    end
end

function ActivityLevelGiftPopupMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require( 'Game.views.activity.popup.ActivityLevelGiftPopupView' ).new()
    viewComponent:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
end

---------------------------------------------
----------------- method --------------------
--[[
刷新等级礼包
--]]
function ActivityLevelGiftPopupMediator:RefreshLevelChest()
    app.activityMgr:SortChestData()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
	viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceChestLevel))
	viewData.gridView:setCountOfCell(table.nums(app.activityMgr:GetLevelChestData()))
	viewData.gridView:reloadData()
end
--[[
等级礼包数据处理
--]]
function ActivityLevelGiftPopupMediator:OnDataSourceChestLevel(cell , idx)
	local pcell = cell
	local index = idx +1
	local levelChestData = app.activityMgr:GetLevelChestData()
    ---@type ActivityLevelGiftView
    local viewComponent = self:GetViewComponent()
	xTry(function ( )
		if index > 0 and index <= table.nums(levelChestData) then
			if not  pcell then
				pcell = viewComponent:CreateGridCell()
				pcell.buyBtn:setOnClickScriptHandler(function (sender)
					PlayAudioByClickNormal()
					local index = sender:getTag()
					local levelChestData =  app.activityMgr:GetLevelChestData()
					if levelChestData[index] and checkint(levelChestData[index].hasPurchased) == 0 and app.gameMgr:GetUserInfo().level >= checkint(levelChestData[index].openLevel)  then
						self.curLevelData = levelChestData[index]
						self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = levelChestData[index].productId , name = 'levelChest'})
					elseif  app.gameMgr:GetUserInfo().level <  checkint(levelChestData[index].openLevel) then
						app.uiMgr:ShowInformationTips(__('等级不足不能购买该礼包'))
					else
						app.uiMgr:ShowInformationTips(__('已经购买该礼包'))
					end
				end)
			end
			pcell.buyBtn:setTag(index)
			viewComponent:UpdateCell(pcell, levelChestData[index])
		end
	end, __G__TRACKBACK__)
	return pcell
end
----------------- method --------------------
---------------------------------------------

---------------------------------------------
---------------- callback -------------------
--[[
返回按钮回调
--]]
function ActivityLevelGiftPopupMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    AppFacade.GetInstance():UnRegsitMediator("ActivityLevelGiftPopupMediator")
end
---------------- callback -------------------
---------------------------------------------

---------------------------------------------
---------------- get / set ------------------

---------------- get / set ------------------
---------------------------------------------
function ActivityLevelGiftPopupMediator:enterLayer()
    if app.activityMgr:GetLevelChestData() then
        self:RefreshLevelChest()
    else
        self:SendSignal(POST.LEVEL_GIFT_CHEST.cmdName,{})
    end
end

function ActivityLevelGiftPopupMediator:OnRegist(  )
    regPost(POST.LEVEL_GIFT_CHEST)
    self:enterLayer()
end

function ActivityLevelGiftPopupMediator:OnUnRegist(  )
    unregPost(POST.LEVEL_GIFT_CHEST)
    app.uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
end
return ActivityLevelGiftPopupMediator