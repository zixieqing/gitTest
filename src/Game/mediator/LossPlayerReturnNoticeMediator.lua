--[[
    流失玩家公告Mediator
--]]
local Mediator = mvc.Mediator

local LossPlayerReturnNoticeMediator = class("LossPlayerReturnNoticeMediator", Mediator)

local NAME = "LossPlayerReturnNoticeMediator"

local uiMgr = app.uiMgr
local gameMgr = app.gameMgr

function LossPlayerReturnNoticeMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.args = checktable(params) or {}
end

function LossPlayerReturnNoticeMediator:InterestSignals()
	local signals = { 
	}

	return signals
end

function LossPlayerReturnNoticeMediator:ProcessSignal( signal )
	local name = signal:GetName() 
    local body = signal:GetBody()
	-- dump(body, name)
end

function LossPlayerReturnNoticeMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.LossPlayerReturnNoticeView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	local viewData = viewComponent.viewData

    viewData.quitBtn:setOnClickScriptHandler(function(sender)
		PlayAudioByClickClose()
		gameMgr:GetUserInfo().returnRewards = {}
		self:GetFacade():UnRegsitMediator(NAME)
	end)
	
	viewData.desrLabel:setString(string.fmt(gameMgr:GetUserInfo().returnRewards.content, {_number_ = table.nums(gameMgr:GetUserInfo().cards)}))
	local LabelSize = display.getLabelContentSize(viewData.desrLabel)
	if LabelSize.height > 230 then
		viewData.desrScrollView:setContainerSize(LabelSize)
		viewData.desrLabel:setPositionY(LabelSize.height)
	end
	viewData.desrScrollView:setContentOffsetToTop()
	
	self.rewards = gameMgr:GetUserInfo().returnRewards.rewards or {}
	local gridView = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAction))
    gridView:setCountOfCell(#self.rewards)
    gridView:reloadData()
end

function LossPlayerReturnNoticeMediator:OnDataSourceAction(p_convertview, idx)
    local index = idx + 1
    local cell  = p_convertview

    -- init cell
    if cell == nil then
		cell = CTableViewCell:new()
		local size = self:GetViewComponent().viewData.gridView:getSizeOfCell()
		cell:setContentSize(size)
		local goodNode = require('common.GoodNode').new({id = self.rewards[index].goodsId, amount = self.rewards[index].num, showAmount = true })
		goodNode:setScale(0.7)
		goodNode:setPosition(size.width/2, size.height/2)
		display.commonUIParams(goodNode, {animate = false, cb = function (sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
		end})
		cell:addChild(goodNode,5)
		cell.goodNode = goodNode
	else
		cell.goodNode:RefreshSelf({id = self.rewards[index].goodsId, amount = self.rewards[index].num})
	end
    return cell
end

function LossPlayerReturnNoticeMediator:OnRegist(  )
end

function LossPlayerReturnNoticeMediator:OnUnRegist(  )
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return LossPlayerReturnNoticeMediator