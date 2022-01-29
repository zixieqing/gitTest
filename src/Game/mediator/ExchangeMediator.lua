---
--- Created by xingweihao.
--- DateTime: 25/10/2017 3:25 PM
---

local Mediator = mvc.Mediator
---@class ExchangeMediator :Mediator
local ExchangeMediator = class("ExchangeMediator", Mediator)
local NAME = "ExchangeMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local BUTTON_CLICK = {
    INPUT_EXCHANGE = 100011 ,
    MAKE_SURE = 100022,
}
function ExchangeMediator:ctor( layer, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.preIndex = nil  -- 上一次点击
    self.exchangeNum = ""
end

function ExchangeMediator:InterestSignals()
    local signals = {
        POST.PRESENT_CODE.sglName,
        POST.GIFT_ADDRESS.sglName
    }
    return signals
end
function ExchangeMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type ExchangeView
    self.viewComponent = require('Game.views.ExchangeView').new()
    self:SetViewComponent(self.viewComponent)
    self.viewComponent.viewData.makeSureBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    self.viewComponent.viewData.editBox:registerScriptEditBoxHandler(function(eventType,sender)
        if eventType == 'began' then  -- 输入开始
        elseif eventType == 'ended' then  -- 输入结束
            self:ButtonAction(sender)
        elseif eventType == 'changed' then  -- 内容变化
        elseif eventType == 'return' then  -- 从输入返回
            self:ButtonAction(sender)
        end
    end)
end

function ExchangeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.PRESENT_CODE.sglName then -- 兑换码的回调
        if 3 == checkint(data.type) then
            self:ShowRecordInfoLayer()
        else
            uiMgr:ShowInformationTips(data.msg)
        end
    elseif name == POST.GIFT_ADDRESS.sglName then 
        local layer = uiMgr:GetCurrentScene():GetDialogByTag(1010)
        if layer then
            layer:removeFromParent()
        end
        uiMgr:ShowInformationTips(__('兑换成功，详见邮箱说明'))
        self.viewComponent.viewData.editBox:setEnabled(true)
    end
end

--[[
登记个人信息界面
--]]
function ExchangeMediator:ShowRecordInfoLayer()
    self.viewComponent.viewData.editBox:setEnabled(false)
	local layer = require('Game.views.RecordInfoLayer').new({cb = function (  )
        self.viewComponent.viewData.editBox:setEnabled(true)
    end})
	display.commonUIParams(layer, {ap = cc.p(0, 0), po = cc.p(0, 0)})
	uiMgr:GetCurrentScene():AddDialog(layer)
	layer:setTag(1010)
	for k,btn in pairs(layer.viewData.actionButtons) do
		display.commonUIParams(btn, {cb = handler(self, self.ButtonAction)})
	end
end

function ExchangeMediator:ButtonAction(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag == BUTTON_CLICK.INPUT_EXCHANGE then  -- 输入事件
        self.exchangeNum = sender:getText()
    elseif tag == BUTTON_CLICK.MAKE_SURE then
        if self.exchangeNum ~= "" then
            self.presentCode = self.exchangeNum
            self:SendSignal(POST.PRESENT_CODE.cmdName, { code = self.exchangeNum })
        else
            uiMgr:ShowInformationTips(__('请输入兑换码'))
        end
    elseif tag == 1004 then
        local layer = uiMgr:GetCurrentScene():GetDialogByTag(1010)
        if layer then
			local playerName = layer.viewData.nameBox:getText()
			-- 查错
			if nil == playerName or string.len(string.gsub(playerName, " ", "")) <= 0 then
                uiMgr:ShowInformationTips(__('姓名不能为空'))
				return
			end
			local phone = layer.viewData.phoneBox:getText()
			if nil == phone or string.len(string.gsub(phone, " ", "")) <= 0 then
                uiMgr:ShowInformationTips(__('电话号码不能为空'))
				return
			end
			local address = layer.viewData.addressBox:getText()
			if nil == address or string.len(string.gsub(address, " ", "")) <= 0 then
                uiMgr:ShowInformationTips(__('地址不能为空'))
				return
			end
			self:SendSignal(POST.GIFT_ADDRESS.cmdName, {code = self.presentCode, name = playerName, telephone = phone, address = address})
		end
    end
end
function ExchangeMediator:OnRegist()
    regPost(POST.PRESENT_CODE)
    regPost(POST.GIFT_ADDRESS)
end

function ExchangeMediator:OnUnRegist()
    unregPost(POST.PRESENT_CODE)
    unregPost(POST.GIFT_ADDRESS)
end

return ExchangeMediator



