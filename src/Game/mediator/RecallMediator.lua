--[[
召回Mediator
--]]
local Mediator = mvc.Mediator

local RecallMediator = class("RecallMediator", Mediator)

local NAME = "RecallMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
local dataMgr = AppFacade.GetInstance():GetManager("DataManager")

local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end

function RecallMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.args = checktable(params) or {}
	if not self.args.recallRewards then
		self.args.recallRewards = {}
	end
	if not self.args.recallCode then
		self.args.recallCode = ''
	end
end

function RecallMediator:InterestSignals()
	local signals = { 
		POST.RECALL_REWARD_DRAW.sglName ,
		'SHARE_BUTTON_BACK_EVENT',
		EVENT_REQUEST_RECALLED_H5,
		COUNT_DOWN_ACTION,
		RECALL_MAIN_TIME_UPDATE_EVENT,
	}

	return signals
end

function RecallMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
    if name == POST.RECALL_REWARD_DRAW.sglName then
		uiMgr:AddDialog('common.RewardPopup', body)
        for k,v in pairs(self.args.recallRewards) do
			if v.id == body.requestData.rewardId then
				v.hasDrawn = 1
				local cell = self.viewComponent.viewData_.gridView:cellAtIndex(k - 1)
				if cell then
                    cell.recvBtn:setScale(0.9)
					cell.recvBtn:setEnabled(false)
					cell.recvBtn:setNormalImage(_res('ui/common/activity_mifan_by_ico.png'))
					display.commonLabelParams(cell.recvBtn, fontWithColor('14', {text = __('已领取')}))
				end
				break
			end
		end
		AppFacade.GetInstance():DispatchObservers(RECALL_REWARD_DRAW_UI)
	elseif name == 'SHARE_BUTTON_BACK_EVENT' then
		-- 关闭分享界面
		uiMgr:GetCurrentScene():RemoveDialogByTag(5361)
	elseif name == EVENT_REQUEST_RECALLED_H5 then
		-- dump(body, name)
		if self.webView then
            if body.rule then
                body.rule = crypto.encodeBase64(body.rule)
            end
            if 'recalledWheelWinnerList' == body.requestData.action then
                for k,v in pairs(body.winnerList) do
                    if v.playerName then
                        v.playerName = crypto.encodeBase64(v.playerName)
                    end
                end
            end
			self.webView:evaluateJS('on' .. body.requestData.action .. '(\'' .. json.encode(body) .. '\')')
		end
	elseif name == COUNT_DOWN_ACTION then
		if body.countdown and checkint(body.countdown) == 0 then
			if checkint(body.tag) == RemindTag.RECALLEDMASTER then -- 老玩家成功召回其他人
				local viewData = self.viewComponent.viewData_
				viewData.remindIcon:setVisible(gameMgr:GetUserInfo().showRedPointForMasterRecalled)
			elseif checkint(body.tag) == RemindTag.RECALLH5 then -- 老玩家H5界面可以领奖
				local viewData = self.viewComponent.viewData_
				viewData.h5RemindIcon:setVisible(gameMgr:GetUserInfo().showRedPointForRecallH5)
			end
		end
	elseif name == RECALL_MAIN_TIME_UPDATE_EVENT then
		local leftSeconds = body.leftSeconds
		self:UpdateTimeLabel(leftSeconds)
    end
end

function RecallMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.RecallView').new()
	self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData_
	
	viewData.remindIcon:setVisible(gameMgr:GetUserInfo().showRedPointForMasterRecalled)
	viewData.h5RemindIcon:setVisible(gameMgr:GetUserInfo().showRedPointForRecallH5)

	viewData.recalledMasterBtn:setOnClickScriptHandler(handler(self,self.RecalledMasterActions))
	viewData.gotoh5Btn:setOnClickScriptHandler(handler(self,self.GoToH5Actions))
	viewData.inviteCodeLabel:setString(self.args.recallCode)
	viewData.shareBtn:setOnClickScriptHandler(handler(self, self.ShareButtonCallback))
	viewData.ruleBtn:setOnClickScriptHandler(function(sender)
		PlayAudioByClickNormal()
		local rule = CommonUtils.GetConfigAllMess('rule','recall')
		uiMgr:ShowIntroPopup(rule['1'])
	end)
	self:UpdateTimeLabel(self.args.leftSeconds)

    local gridView = viewData.gridView
    gridView:setCountOfCell(table.nums(self.args.recallRewards))
    gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
    gridView:reloadData()
end

function RecallMediator:UpdateTimeLabel( leftSeconds )
	local viewData = self.viewComponent.viewData_
	if checkint(leftSeconds) <= 0 then
		viewData.timeLabel:setString('00:00:00')
	else
		if checkint(leftSeconds) <= 86400 then
			viewData.timeLabel:setString(string.formattedTime(checkint(leftSeconds),'%02i:%02i:%02i'))
		else
			local day = math.floor(checkint(leftSeconds)/86400)
			local hour = math.floor((leftSeconds - day * 86400) / 3600)
			viewData.timeLabel:setString(string.fmt(__('_day_天_hour_小时'),{_day_ = day, _hour_ = hour}))
		end
	end
end

--[[
分享按钮回调
--]]
function RecallMediator:ShareButtonCallback( sender )
	PlayAudioByClickNormal()
	local viewComponent = self:GetViewComponent()
	local shareLayer = require('Game.views.share.RecallShareLayer').new({
		inviteCode = self.args.recallCode
	})
	shareLayer:setAnchorPoint(cc.p(0.5, 0.5))
	shareLayer:setTag(5361)
	shareLayer:setPosition(cc.p(display.cx, display.cy))
	uiMgr:GetCurrentScene():AddDialog(shareLayer)
end

--[[
	查看召回玩家按钮回调
--]]
function RecallMediator:RecalledMasterActions( sender )
	PlayAudioByClickNormal()
	local RecalledMasterMediator = require( 'Game.mediator.RecalledMasterMediator')
	local mediator = RecalledMasterMediator.new(self.args)
	self:GetFacade():RegistMediator(mediator)

	gameMgr:GetUserInfo().showRedPointForMasterRecalled = false
	dataMgr:ClearRedDotNofication(tostring(RemindTag.RECALLEDMASTER),RemindTag.RECALLEDMASTER, "[老玩家召回]RecalledMasterActions")
	AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.RECALLEDMASTER})
end

--[[
	进入召回玩家h5界面
--]]
function RecallMediator:GoToH5Actions( sender )
	PlayAudioByClickNormal()

	local function createH5View( url )
		print("url = " , url)
        local viewData = self.viewComponent.viewData_
		local pos = viewData.view:convertToNodeSpace(cc.p(display.cx, display.cy))
		if not self.webviewLayer then
			local webviewLayer = display.newLayer(pos.x, pos.y, {size = display.size, ap = cc.p(0.5, 0.5), color = cc.c3b(255, 255, 255)})
			viewData.view:addChild(webviewLayer, 10)
			self.webviewLayer = webviewLayer
		end
		if device.platform == 'ios' or device.platform == 'android' then
            local _webView = ccexp.WebView:create()
            _webView:setAnchorPoint(cc.p(0.5, 0.5))
            _webView:setPosition(pos)
            _webView:setContentSize(cc.size(display.width, display.height))
            _webView:setScalesPageToFit(true)
            _webView:setOnShouldStartLoading(handler(self, self.HandleH5Request))
            viewData.view:addChild(_webView)
    
            _webView:loadURL(url)	
            self.webView = _webView
        end
	end
	-- local layer = self:createURLChooseLayer()
	-- layer:setPosition(cc.p(display.cx, display.cy))
    -- uiMgr:GetCurrentScene():AddDialog(layer)
    -- layer.viewData.defaultButton:setOnClickScriptHandler(function ( ... )
	if isElexSdk() and (not isNewUSSdk()) then
		if DEBUG == 0 then
			if PRE_RELEASE_SERVER then
				createH5View(string.format('http://notice-zmfoodimage.17atv.elexapp.com/recall_elex/%s/index.html', i18n.getLang()))
			else
				createH5View(string.format('http://notice-zmfoodapi.17atv.elexapp.com/recall_elex/%s/index.html',  i18n.getLang()))
			end
		else
			createH5View(string.format('http://notice-foodtest.elexapp.com/recall_elex/%s/index.html',i18n.getLang()))
		end
	elseif isNewUSSdk() then
		if DEBUG == 0 then
			if PRE_RELEASE_SERVER then
				createH5View(string.format('http://notice-hw-foodimage.fundollgame.com/recall_hw/%s/index.html', i18n.getLang()))
			else
				createH5View(string.format('http://notice-hwfood.fundollgame.com/recall_hw/%s/index.html',  i18n.getLang()))
			end
		else
			createH5View(string.format('http://notice-hwfoodtestgm.fundollgame.com/recall_hw/%s/index.html',i18n.getLang()))
		end
	else
		createH5View(string.format('http://notice-%s/recall_elex/%s/index.html', Platform.serverHost, i18n.getLang()))
	end

	-- 	createH5View('http://192.168.1.175:3000')
	-- 	layer:removeFromParent()
    -- end)
    -- layer.viewData.confirmButton:setOnClickScriptHandler(function ( ... )
    --     local url = layer.viewData.urlBox:getText()
    --     createH5View(url)
	-- 	layer:removeFromParent()
    -- end)
	-- httpManager:Post("Recall/recalledWheelDraw", EVENT_REQUEST_RECALLED_H5,{})
	gameMgr:GetUserInfo().showRedPointForRecallH5 = false
	dataMgr:ClearRedDotNofication(tostring(RemindTag.RECALLH5),RemindTag.RECALLH5, "[老玩家召回]GoToH5Actions")
	AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.RECALLH5})
end

function RecallMediator:createURLChooseLayer( ... )
    local node = CLayout:create(display.size)

    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 122))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(node:getContentSize())
    eaterLayer:setPosition(utils.getLocalCenter(node))
    node:addChild(eaterLayer)
    eaterLayer:setOnClickScriptHandler(function()
        PlayAudioByClickClose()
        node:removeFromParent()
    end)

    local bg = display.newLayer(utils.getLocalCenter(node).x, utils.getLocalCenter(node).y, {enable = true, bg = _res('ui/common/common_bg_9.png'), ap = cc.p(0.5, 0.5)})
	node:addChild(bg)
	local bgSize = bg:getContentSize()

	-- title
	local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
	display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5 -3)})
	display.commonLabelParams(titleBg,
		{text = __('选择URL'),
		fontSize = fontWithColor('3').fontSize, color = fontWithColor('3').color,
		offset = cc.p(0, -2)})
    bg:addChild(titleBg)

	local urlBox = ccui.EditBox:create(cc.size(300, 44), _res('ui/common/common_bg_input_default.png'))
	display.commonUIParams(urlBox, {po = cc.p(utils.getLocalCenter(bg).x, bgSize.height * 0.8)})
	bg:addChild(urlBox)
	urlBox:setFontSize(fontWithColor('M2PX').fontSize)
	urlBox:setFontColor(ccc3FromInt('#9f9f9f'))
	urlBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	urlBox:setPlaceHolder(__('请输入URL'))
	urlBox:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
	urlBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
    urlBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    
    local defaultButton = display.newButton(bgSize.width * 0.5, bgSize.height * 0.4, {ap = cc.p(0.5, 1), n = _res('ui/common/common_btn_orange.png')})
    display.commonLabelParams(defaultButton, fontWithColor(14,{text = __('默认')}))
    bg:addChild(defaultButton)

    local confirmButton = display.newButton(bgSize.width * 0.5, bgSize.height * 0.6, {ap = cc.p(0.5, 1), n = _res('ui/common/common_btn_orange.png')})
    display.commonLabelParams(confirmButton, fontWithColor(14,{text = __('确认')}))
    bg:addChild(confirmButton)

    node.viewData = {
        urlBox          = urlBox,
        defaultButton   = defaultButton,
        confirmButton   = confirmButton,
    }

    return node
end

--[[
	与召回玩家h5界面交互
--]]
function RecallMediator:HandleH5Request( webview, url )
	local scheme = 'liuzhipeng'
	local urlInfo = string.split(url, '://')
	if 2 == table.nums(urlInfo) then
		if urlInfo[1] == scheme then
			local urlParams = string.split(urlInfo[2], '&')
			local params = {}
			for k,v in pairs(urlParams) do
				local param = string.split(v, '=')
				-- 构造表单做get请求 所以结尾多一个？
				-- params[param[1]] = string.split(param[2], '?')[1]
				-- 构造表单做get请求（win上面的ie浏览器结尾多一个/，其他浏览器或其他平台尾多一个？，所以不能用上面的）
				local lastChar = string.sub(param[2], string.len(param[2]))
                if lastChar == '/' or lastChar == '?' then
                    params[param[1]] = string.sub(param[2], 0, string.len(param[2]) - 1)
                else
                    params[param[1]] = param[2]
                end
			end
			if params.action then
				if 'getId' == params.action then
					webview:evaluateJS('onGetIdAction(' .. gameMgr:GetUserInfo().playerId .. ')')
				elseif 'close' == params.action then
					webview:runAction(cc.RemoveSelf:create())
					self.webView = nil
					if self.webviewLayer then
						self.webviewLayer:runAction(cc.RemoveSelf:create())
						self.webviewLayer = nil
					end
				elseif 'reload' == params.action then
					webview:reload()
				elseif 'recalledAction' == params.action then
					httpManager:Post("Recall/recalledAction", EVENT_REQUEST_RECALLED_H5,params)
				elseif 'loginClosePointDraw' == params.action then
					httpManager:Post("Recall/loginClosePointDraw", EVENT_REQUEST_RECALLED_H5,params)
				elseif 'paymentClosePointDraw' == params.action then
					httpManager:Post("Recall/paymentClosePointDraw", EVENT_REQUEST_RECALLED_H5,params)
				elseif 'recalledWheelDraw' == params.action then
					httpManager:Post("Recall/recalledWheelDraw", EVENT_REQUEST_RECALLED_H5,params)
				elseif 'recalledWheelWinnerList' == params.action then
					httpManager:Post("Recall/recalledWheelWinnerList", EVENT_REQUEST_RECALLED_H5,params)
				else
					return true
				end
			end
			return false
		end
	end
	return true
end

function RecallMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local sizee = cc.size(296 * 2, 150)
    local tempData = self.args.recallRewards[index]
   	if pCell == nil then
        pCell = CGridViewCell:new()
        pCell:setContentSize(sizee)

        local cellBg = display.newImageView(GetFullPath('recall_bg_task'), 296, 75)
        pCell:addChild(cellBg)

		local desrLabel = display.newLabel(18, 130, fontWithColor('16', {ap = display.LEFT_CENTER}))
        pCell:addChild(desrLabel)
        pCell.desrLabel = desrLabel
		
		local recvBtn = display.newButton(500, 58, {n = _res('ui/common/common_btn_orange.png')})
		pCell:addChild(recvBtn)
		display.commonLabelParams(recvBtn, fontWithColor('14', {text = __('领取')}))
		recvBtn:setOnClickScriptHandler(handler(self,self.CellButtonAction))
		pCell.recvBtn = recvBtn

        pCell.goodsIcon = {}
    end
	xTry(function()
        pCell.desrLabel:setString(tempData.name .. string.format('（%d/%d）',tempData.progress,checkint(tempData.targetNum)))
        for k,v in pairs(pCell.goodsIcon) do
            v:setVisible(false)
		end
		pCell.recvBtn:setTag(index)
		pCell.recvBtn:setScale(1)
		if 1 == checkint(tempData.hasDrawn) then	-- 已领取
			pCell.recvBtn:setEnabled(false)
			pCell.recvBtn:setNormalImage(_res('ui/common/activity_mifan_by_ico.png'))
			pCell.recvBtn:setScale(0.9)
			display.commonLabelParams(pCell.recvBtn, fontWithColor('7', {fontSize = 22,text = __('已领取')}))
		elseif checkint(tempData.progress) < checkint(tempData.targetNum) then
			pCell.recvBtn:setEnabled(true)
			pCell.recvBtn:setNormalImage(_res('ui/common/common_btn_blue_default.png'))
			pCell.recvBtn:setSelectedImage(_res('ui/common/common_btn_blue_default.png'))
			display.commonLabelParams(pCell.recvBtn, fontWithColor('14', {text = __('去邀请')}))
		else
			pCell.recvBtn:setEnabled(true)
			pCell.recvBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
			pCell.recvBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
			display.commonLabelParams(pCell.recvBtn, fontWithColor('14', {text = __('领取')}))
		end
        for i=1,table.nums(tempData.rewards) do
            if pCell.goodsIcon[i] then
                pCell.goodsIcon[i]:setVisible(true)
                pCell.goodsIcon[i]:RefreshSelf({
                    goodsId = tempData.rewards[i].goodsId,
                    amount = tempData.rewards[i].num,
                    showAmount = true,
                })
            else
                local goodsIcon = require('common.GoodNode').new({
                    id = tempData.rewards[i].goodsId,
                    amount = tempData.rewards[i].num,
                    showAmount = true,
                    callBack = function (sender)
                        uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
					end
                })
                goodsIcon:setPosition(cc.p(62 + (i - 1)*93, 58))
                goodsIcon:setScale(0.8)
                pCell:addChild(goodsIcon)
                pCell.goodsIcon[i] = goodsIcon
            end
        end
	end,__G__TRACKBACK__)
    return pCell
end

--[[
列表的单元格按钮的事件处理逻辑
@param sender button对象
--]]
function RecallMediator:CellButtonAction( sender )
    PlayAudioByClickNormal()
	local index = sender:getTag()
	self.tag = index
	local data  = self.args.recallRewards[index]
	if data then
		if data.hasDrawn == 0 then
			if checkint(data.progress) < checkint(data.targetNum) then
				-- uiMgr:ShowInformationTips(__('未达到领取条件'))
				self:ShareButtonCallback()
			else
				if self.args.leftSeconds > 0 then
					self:SendSignal(POST.RECALL_REWARD_DRAW.cmdName,{rewardId = checkint(data.id)})
				else
					uiMgr:ShowInformationTips(__('任务时间已经结束'))
				end
			end
		else
			uiMgr:ShowInformationTips(__('已领取该奖励'))
		end
	end
end

function RecallMediator:OnRegist(  )
    regPost(POST.RECALL_REWARD_DRAW)
end

function RecallMediator:OnUnRegist(  )
	unregPost(POST.RECALL_REWARD_DRAW)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return RecallMediator