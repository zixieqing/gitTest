--[[
    礼包保存收货信息Mediator
--]]
local Mediator = mvc.Mediator
---@class RecordInfoMediator:Mediator
local RecordInfoMediator = class("RecordInfoMediator", Mediator)

local NAME = "RecordInfoMediator"

local shareFacade = AppFacade.GetInstance()
local uiMgr = shareFacade:GetManager("UIManager")

function RecordInfoMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.goodsId = params or 890002
end

function RecordInfoMediator:InterestSignals()
	local signals = { 
        POST.GOODS_ADDRESS.sglName
	}

	return signals
end

function RecordInfoMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
    if name == POST.GOODS_ADDRESS.sglName then 
		CommonUtils.DrawRewards({{goodsId = self.goodsId, num = -1}})
		shareFacade:DispatchObservers(SIGNALNAMES.Updata_BackPack_Callback)
        uiMgr:ShowInformationTips(__('兑换成功，奖励会在10个工作日内发货哦！'))
        shareFacade:UnRegsitMediator(NAME)
    end
end

function RecordInfoMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.RecordInfoLayer').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
    local viewData = viewComponent.viewData
    for k,btn in pairs(viewData.actionButtons) do
		display.commonUIParams(btn, {cb = handler(self, self.ButtonAction)})
	end
end

function RecordInfoMediator:ButtonAction(sender)
    PlayAudioByClickNormal()
    
	local viewData = self.viewComponent.viewData
    local playerName = viewData.nameBox:getText()
	-- 查错
	if nil == playerName or string.len(string.gsub(playerName, " ", "")) <= 0 then
        uiMgr:ShowInformationTips(__('姓名不能为空'))
		return
	end
	local phone = viewData.phoneBox:getText()
	if nil == phone or string.len(string.gsub(phone, " ", "")) <= 0 then
        uiMgr:ShowInformationTips(__('电话号码不能为空'))
		return
	end
	local address = viewData.addressBox:getText()
	if nil == address or string.len(string.gsub(address, " ", "")) <= 0 then
        uiMgr:ShowInformationTips(__('地址不能为空'))
		return
	end
	self:SendSignal(POST.GOODS_ADDRESS.cmdName, {goodsId = self.goodsId, name = playerName, telephone = phone, address = address})
end

function RecordInfoMediator:OnRegist(  )
    regPost(POST.GOODS_ADDRESS)
end

function RecordInfoMediator:OnUnRegist(  )
    unregPost(POST.GOODS_ADDRESS)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return RecordInfoMediator