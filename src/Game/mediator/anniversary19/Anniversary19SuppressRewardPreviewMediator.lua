---@class Anniversary19SuppressRewardPreviewMediator : Mediator
---@field viewComponent Anniversary19SuppressRewardPreviewView
local Anniversary19SuppressRewardPreviewMediator = class('Anniversary19SuppressRewardPreviewMediator', mvc.Mediator)
local anniversary2019Mgr = app.anniversary2019Mgr

local NAME = "Anniversary19SuppressRewardPreviewMediator"

function Anniversary19SuppressRewardPreviewMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)

end


function Anniversary19SuppressRewardPreviewMediator:Initial(key)
    self.super.Initial(self, key)
	local scene = app.uiMgr:GetCurrentScene()
	local viewComponent = require('Game.views.anniversary19.Anniversary19SuppressRewardPreviewView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	local viewData = viewComponent.viewData

	local bossId = self.ctorArgs_.bossId
	local level = self.ctorArgs_.level
	local boss = anniversary2019Mgr:GetConfigDataByName(anniversary2019Mgr:GetConfigParse().TYPE.BOSS)[tostring(bossId)][tostring(level)]

	for i = 1, #boss.attendRewards do
		self:CreateGoodNode(display.cx - -44 - (#boss.attendRewards-1) * 50 + (i-1) * 100, display.cy - -121, boss.attendRewards[i])
	end

	for i = 1, #boss.discoveryRewards do
		self:CreateGoodNode(display.cx - 128 - (#boss.discoveryRewards-1) * 50 + (i-1) * 100, display.cy - 69, boss.discoveryRewards[i])
	end

	for i = 1, #boss.damageRewards do
		self:CreateGoodNode(display.cx - -229 - (#boss.damageRewards-1) * 50 + (i-1) * 100, display.cy - 69, boss.damageRewards[i])
	end
	
	for i = 1, #boss.failureRewards do
		self:CreateGoodNode(display.cx - -44 - (#boss.failureRewards-1) * 50 + (i-1) * 100, display.cy - 241, boss.failureRewards[i])
	end
end

function Anniversary19SuppressRewardPreviewMediator:CreateGoodNode(x, y, rewards)
	local viewData = self.viewComponent.viewData
	local goodsIcon = require('common.GoodNode').new({id = rewards.goodsId, amount = rewards.num, showAmount = true})
	goodsIcon:setScale(0.8)
	goodsIcon:setPosition(x, y)
	goodsIcon:setOnClickScriptHandler(handler(self, self.OnCellRewardBtnClickHandler))
	viewData.view:addChild(goodsIcon)
end

function Anniversary19SuppressRewardPreviewMediator:OnRegist()
end

function Anniversary19SuppressRewardPreviewMediator:OnUnRegist()
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end


function Anniversary19SuppressRewardPreviewMediator:InterestSignals()
    local signals = {
	}
	return signals
end

function Anniversary19SuppressRewardPreviewMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
end

function Anniversary19SuppressRewardPreviewMediator:OnCellRewardBtnClickHandler( sender )
	PlayAudioByClickNormal()
	app.uiMgr:ShowInformationTipsBoard({
		targetNode = sender, iconId = checkint(sender.goodId), type = 1
	})
end

return Anniversary19SuppressRewardPreviewMediator
