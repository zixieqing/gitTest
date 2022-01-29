local Mediator = mvc.Mediator
---@class ReturnWelfareTreasureMediator:Mediator
local ReturnWelfareTreasureMediator = class("ReturnWelfareTreasureMediator", Mediator)

local NAME = "ReturnWelfareTreasureMediator"
local app = app
local uiMgr = app.uiMgr

function ReturnWelfareTreasureMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
    self.datas = checktable(params) or {}
end

function ReturnWelfareTreasureMediator:InterestSignals()
	local signals = { 
		POST.BACK_DRAW_TREASURE.sglName,
	}

	return signals
end

function ReturnWelfareTreasureMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
    -- dump(body, name)
    if name == POST.BACK_DRAW_TREASURE.sglName then
        uiMgr:AddDialog('common.RewardPopup', body)
        CommonUtils.RefreshDiamond(body)
        local type = body.requestData.type
        if 1 == type then
            self.datas.data.treasureFreeRewards.hasDrawn = 1
            app:DispatchObservers('EVENT_HOME_RED_POINT')
        else
            self.datas.data.treasurePayRewards.hasDrawn = 1
        end
        self:RefreshUI()
    end
end

function ReturnWelfareTreasureMediator:Initial( key )
	self.super.Initial(self, key)
	-- local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.returnWelfare.ReturnWelfareTreasureView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
    -- scene:AddDialog(viewComponent)
    self.datas.parent:addChild(viewComponent)
    
    self:InitUI()
    self:RefreshUI()
    local viewData = viewComponent.viewData
    viewData.normalDrawBtn:setOnClickScriptHandler(handler(self, self.DrawBtnClickHandler))
    viewData.shiningDrawBtn:setOnClickScriptHandler(handler(self, self.DrawBtnClickHandler))
end

function ReturnWelfareTreasureMediator:InitUI(  )
    local viewData = self.viewComponent.viewData
    
    local eventLayer = viewData.eventLayer
    local data = self.datas.data
    local i = 1
    table.insert(data.treasureFreeRewards.rewards, {goodsId = EXP_ID, num = data.treasureFreeRewards.exp})
    for k,v in pairs(data.treasureFreeRewards.rewards) do
        local goodsIcon = require('common.GoodNode').new({
            id = v.goodsId,
            amount = v.num,
            showAmount = true,
            callBack = function (sender)
                uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
            end
        })
        goodsIcon:setPosition(i * 140 - 30, 293)
        eventLayer:addChild(goodsIcon)
        i = i + 1
    end

    i = 1
    table.insert(data.treasurePayRewards.rewards, {goodsId = EXP_ID, num = data.treasurePayRewards.exp})
    for k,v in pairs(data.treasurePayRewards.rewards) do
        local goodsIcon = require('common.GoodNode').new({
            id = v.goodsId,
            amount = v.num,
            showAmount = true,
            callBack = function (sender)
                uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
            end
        })
        goodsIcon:setPosition(i * 140 - 30, 93)
        eventLayer:addChild(goodsIcon)
        i = i + 1
    end
end

function ReturnWelfareTreasureMediator:RefreshUI(  )
    local viewData = self.viewComponent.viewData
    
    local data = self.datas.data

    if 0 == checkint(data.treasureFreeRewards.hasDrawn) then
        viewData.redPointImg:setVisible(true)
        display.commonLabelParams(viewData.normalDrawBtn, fontWithColor(14, {text = __('领取')}))
    else
        viewData.redPointImg:setVisible(false)
        viewData.normalDrawBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
        viewData.normalDrawBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
        display.commonLabelParams(viewData.normalDrawBtn, fontWithColor(14, {text = __('已领取')}))
    end
    if 0 == checkint(data.treasurePayRewards.hasDrawn) then
        viewData.costLabel:setVisible(true)
        viewData.costIcon:setVisible(true)
        viewData.costLabel:setString(data.treasurePayRewards.consumeNum)
        display.setNodesToNodeOnCenter(viewData.shiningDrawBtn, {viewData.costLabel, viewData.costIcon})
        display.commonLabelParams(viewData.shiningDrawBtn, fontWithColor(14, {text = ''}))
    else
        viewData.costLabel:setVisible(false)
        viewData.costIcon:setVisible(false)
        viewData.shiningDrawBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
        viewData.shiningDrawBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
        display.commonLabelParams(viewData.shiningDrawBtn, fontWithColor(14, {text = __('已领取')}))
    end
end

function ReturnWelfareTreasureMediator:ResetMdt( data )
    self.datas.data = checktable(data) or {}
    self:RefreshUI()
end

function ReturnWelfareTreasureMediator:DrawBtnClickHandler(sender)
	PlayAudioByClickNormal()
    local tag = sender:getTag()
    local data = self.datas.data
    local hasDrawn = checkint(data.treasureFreeRewards.hasDrawn)
    local available = true
    if 2 == tag then
        hasDrawn = checkint(data.treasurePayRewards.hasDrawn)
        if CommonUtils.GetCacheProductNum(DIAMOND_ID) < checkint(data.treasurePayRewards.consumeNum) then
            available = false
        end
    end
    if 1 == hasDrawn then
        uiMgr:ShowInformationTips(__('不可重复领取'))
    elseif not available then
        uiMgr:ShowInformationTips(__('幻晶石不足'))
    else
        self:SendSignal(POST.BACK_DRAW_TREASURE.cmdName, {type = tag})
    end
end

function ReturnWelfareTreasureMediator:OnRegist(  )
	regPost(POST.BACK_DRAW_TREASURE)
end

function ReturnWelfareTreasureMediator:OnUnRegist(  )
	unregPost(POST.BACK_DRAW_TREASURE)
	-- local scene = uiMgr:GetCurrentScene()
	-- scene:RemoveGameLayer(self.viewComponent)
end

return ReturnWelfareTreasureMediator