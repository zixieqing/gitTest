--[[
    召回公告Mediator
--]]
local Mediator = mvc.Mediator

local RecallNoticeMediator = class("RecallNoticeMediator", Mediator)

local NAME = "RecallNoticeMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
local dataMgr = AppFacade.GetInstance():GetManager("DataManager")

local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end

function RecallNoticeMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.args = checktable(params) or {}
end

function RecallNoticeMediator:InterestSignals()
	local signals = { 
		POST.RECALLED_COMMIT.sglName ,
		POST.RECALL_CODE_QUERY.sglName ,
	}

	return signals
end

function RecallNoticeMediator:ProcessSignal( signal )
	local name = signal:GetName() 
    local body = signal:GetBody()
	-- dump(body, name)
	if name == POST.RECALLED_COMMIT.sglName then
		gameMgr:GetUserInfo().recallCode = self.recallCode
		gameMgr:GetUserInfo().recallPlayerName = self.playerName
		gameMgr:GetUserInfo().recallPlayerServerId = self.playerServerId
		local viewData = self.codeInputLayer.viewData_
		viewData.editBox:setText('')
		self:ShowBindInfo(true)
	elseif name == POST.RECALL_CODE_QUERY.sglName then
		local viewData = self.codeInputLayer.viewData_
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

function RecallNoticeMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.RecallNoticeView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
    local viewData = viewComponent.viewData_

    viewData.quitBtn:setOnClickScriptHandler(function(sender)
		PlayAudioByClickClose()
		if self.args.closeCB then
			self.args.closeCB()
		end
		self:GetFacade():UnRegsitMediator(NAME)
	end)
	
	viewData.gotoBtn:setOnClickScriptHandler(function(sender)
		PlayAudioByClickNormal()
		if self.args.closeCB then
			self.args.closeCB()
		end
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'RecallMainMediator'})
        self:GetFacade():UnRegsitMediator(NAME)
	end)

	viewData.invitedCodeBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	
	local initPosX = viewData.rightImg:getPositionX() - (table.nums(gameMgr:GetUserInfo().recallPresent) - 1) * 88 / 2
	local i = 1
	for k,v in pairs(gameMgr:GetUserInfo().recallPresent) do
		local goodsIcon = require('common.GoodNode').new({
			id = v.goodsId,
			amount = v.num,
			showAmount = true,
			callBack = function (sender)
				uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
			end
		})
		goodsIcon:setScale(0.78)
		goodsIcon:setPosition(cc.p(initPosX + (i - 1)*88, display.cy - 120))
		viewData.view:addChild(goodsIcon)
		i = i + 1
	end

	local day = math.floor(checkint(getServerTime() - gameMgr:GetUserInfo().roleCtime)/86400)
	display.reloadRichLabel(viewData.desrLabel,{c = {
		{text = __('\t\t终于找到您了～您不在缇尔拉大陆的'), fontSize = 20, color = '793002'},
		{text = gameMgr:GetUserInfo().recallLeaveDayNum, fontSize = 20, color = 'd23d23'},
		{text = __('天里，米饭和我们都在翘首期盼您的归来呢！！您的'), fontSize = 20, color = '793002'},
		{text = table.nums(gameMgr:GetUserInfo().cards), fontSize = 20, color = 'd23d23'},
		{text = __('个飨灵现在仍在您的餐厅里为您辛勤劳作～快去与您亲密的飨灵们见面，他们听说您回来了，特地准备了您意想不到的奖励呢～快去看看吧！'), fontSize = 20, color = '793002'},
		}
	})

	local labelSize = display.getLabelContentSize(viewData.desrLabel)
	viewData.desrScrollView:setContainerSize(cc.size(labelSize.width, labelSize.height))
	viewData.desrScrollView:setContentOffsetToTop()
	if viewData.desrSize.height > labelSize.height then
		viewData.desrLabel:setPositionY(viewData.desrSize.height - labelSize.height)
	end
end

function RecallNoticeMediator:ButtonAction( sender )
	PlayAudioByClickNormal()

	local view = require('Game.views.RecallInvitedCodeInputLayer').new()
	view:setAnchorPoint(cc.p(0.5, 0.5))
	view:setPosition(cc.p(display.cx, display.cy))
	uiMgr:GetCurrentScene():AddDialog(view)
	self.codeInputLayer = view
	local viewData = view.viewData_
	viewData.makeSureBtn:setOnClickScriptHandler(function ( sender )
		PlayAudioByClickNormal()
		local invitedCode = viewData.editBox:getText()
		if nil == invitedCode or string.len(string.gsub(invitedCode, " ", "")) <= 0 then
    	    uiMgr:ShowInformationTips(__('请输入召回码'))
			return
		end
		self.recallCode = invitedCode
		self:SendSignal(POST.RECALLED_COMMIT.cmdName, {recallCode = invitedCode})
	end)
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

function RecallNoticeMediator:ShowBindInfo( isBind )
    local viewData = self.codeInputLayer.viewData_
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

function RecallNoticeMediator:OnRegist(  )
    regPost(POST.RECALLED_COMMIT)
    regPost(POST.RECALL_CODE_QUERY)
end

function RecallNoticeMediator:OnUnRegist(  )
	unregPost(POST.RECALLED_COMMIT)
	unregPost(POST.RECALL_CODE_QUERY)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return RecallNoticeMediator