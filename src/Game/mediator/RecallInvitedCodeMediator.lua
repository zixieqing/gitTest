--[[
    回归玩家输入召回码Mediator
--]]
local Mediator = mvc.Mediator

local RecallInvitedCodeMediator = class("RecallInvitedCodeMediator", Mediator)

local NAME = "RecallInvitedCodeMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
local dataMgr = AppFacade.GetInstance():GetManager("DataManager")

local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end

function RecallInvitedCodeMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.args = checktable(params) or {}
end

function RecallInvitedCodeMediator:InterestSignals()
	local signals = { 
		POST.RECALLED_COMMIT.sglName ,
		POST.RECALL_CODE_QUERY.sglName ,
	}

	return signals
end

function RecallInvitedCodeMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
	if name == POST.RECALLED_COMMIT.sglName then
		gameMgr:GetUserInfo().recallCode = self.recallCode
		gameMgr:GetUserInfo().recallPlayerName = self.playerName
		gameMgr:GetUserInfo().recallPlayerServerId = self.playerServerId
		local viewData = self.viewComponent.viewData_
		viewData.editBox:setText('')
		self:ShowBindInfo(true)
	elseif name == POST.RECALL_CODE_QUERY.sglName then
		local viewData = self.viewComponent.viewData_
		local isVisible = false
		if body.playerName then
			isVisible = true
			viewData.nameLabel:setString(body.playerName)
			viewData.areaLabel:setString(body.playerServerId)
			self.playerName = body.playerName
			self.playerServerId = body.playerServerId
		end
		viewData.nameTitleLabel:setVisible(isVisible)
		viewData.areaTitleLabel:setVisible(isVisible)
		viewData.nameLabel:setVisible(isVisible)
		viewData.areaLabel:setVisible(isVisible)
	end
end

function RecallInvitedCodeMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.RecallInvitedCodeView').new()
	self:SetViewComponent(viewComponent)
	local viewData = viewComponent.viewData_
	viewData.makeSureBtn:setOnClickScriptHandler(handler(self,self.ButtonAction))
	viewData.editBox:registerScriptEditBoxHandler(function(eventType,sender)
        if eventType == 'began' then  -- 输入开始
        elseif eventType == 'ended' then  -- 输入结束
			local str = viewData.editBox:getText()
			if nil == str or string.len(string.gsub(str, " ", "")) <= 0 then
				return
			end
			self.playerName = nil
			self.playerServerId = nil
			self:ShowBindInfo(false)
			self:SendSignal(POST.RECALL_CODE_QUERY.cmdName, {recallCode = str})
        elseif eventType == 'changed' then  -- 内容变化
        elseif eventType == 'return' then  -- 从输入返回
        end
	end)
	
	self:ShowBindInfo(gameMgr:GetUserInfo().recallCode ~= '')
end

function RecallInvitedCodeMediator:ButtonAction( sender )
	PlayAudioByClickNormal()
	local invitedCode = self.viewComponent.viewData_.editBox:getText()
	if nil == invitedCode or string.len(string.gsub(invitedCode, " ", "")) <= 0 then
        uiMgr:ShowInformationTips(__('请输入召回码'))
		return
	end
	self.recallCode = invitedCode
	self:SendSignal(POST.RECALLED_COMMIT.cmdName, {recallCode = invitedCode})
end

function RecallInvitedCodeMediator:ShowBindInfo( isBind )
    local viewData = self.viewComponent.viewData_
	viewData.nameTitleLabel:setVisible(isBind)
	viewData.nameLabel:setVisible(isBind)
	viewData.areaTitleLabel:setVisible(isBind)
	viewData.areaLabel:setVisible(isBind)
	viewData.editBox:setEnabled(not isBind)
	viewData.inviteCodeLabel:setVisible(isBind)
	
	if isBind then
		viewData.inviteCodeLabel:setString(gameMgr:GetUserInfo().recallCode)
		viewData.nameLabel:setString(gameMgr:GetUserInfo().recallPlayerName)
		for k,v in pairs(gameMgr:GetUserInfo().servers) do
			if checkint(v.id) == checkint(gameMgr:GetUserInfo().recallPlayerServerId) then
				viewData.areaLabel:setString(v.serverName)
				break
			end
		end

		viewData.makeSureBtn:setEnabled(false)
		viewData.makeSureBtn:setNormalImage(_res('ui/common/activity_mifan_by_ico.png'))
		-- viewData.makeSureBtn:setScale(0.9)
		display.commonLabelParams(viewData.makeSureBtn, fontWithColor('7', {fontSize = 22,text = __('已绑定')}))
	end
end

function RecallInvitedCodeMediator:OnRegist(  )
    regPost(POST.RECALLED_COMMIT)
    regPost(POST.RECALL_CODE_QUERY)
end

function RecallInvitedCodeMediator:OnUnRegist(  )
	unregPost(POST.RECALLED_COMMIT)
	unregPost(POST.RECALL_CODE_QUERY)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return RecallInvitedCodeMediator