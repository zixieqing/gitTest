---@class Anniversary19SuppressMediator : Mediator
---@field viewComponent Anniversary19SuppressView
local Anniversary19SuppressMediator = class('Anniversary19SuppressMediator', mvc.Mediator)
local scheduler = require('cocos.framework.scheduler')
local anniversary2019Mgr = app.anniversary2019Mgr

local NAME = "Anniversary19SuppressMediator"

local PAGE_DEFINE = {
	NONPARTICIPANT		= 1,
	PARTICIPANT			= 2,
	SETTLEMENT			= 3
}

local OWNER_DEFINE = {
	GUILD			= 1,
	FRIEND			= 2,
	TOTAL			= 3
}
function Anniversary19SuppressMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
	self.boss = {}
    self.boss[PAGE_DEFINE.NONPARTICIPANT] = checktable(params).boss

	self.currentPage = PAGE_DEFINE.NONPARTICIPANT
	self:SortBossList()
	self.needKeepGameScene = params.requestData.needKeepGameScene
end


function Anniversary19SuppressMediator:Initial(key)
	self.super.Initial(self, key)
	local viewComponent
	if 1 == self.needKeepGameScene then
		viewComponent = app.uiMgr:PushGameScene('Game.views.anniversary19.Anniversary19SuppressView')
	else
		viewComponent = app.uiMgr:SwitchToTargetScene('Game.views.anniversary19.Anniversary19SuppressView')

		-- 非主界面进入时需要同步一下home数据
		regPost(POST.ANNIVERSARY2_HOME)
        self:SendSignal(POST.ANNIVERSARY2_HOME.cmdName)
	end
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	-- scene:AddDialog(viewComponent)
	-- app.uiMgr:SwitchToScene(viewComponent)
	
	local viewData = viewComponent.viewData
	self.toggles = {viewData.nonparticipantBtn, viewData.participantBtn, viewData.settlementBtn}

	viewData.viewNameLabel:setOnClickScriptHandler(handler(self, self.OnTipsBtnClickAction))
	viewData.backBtn:setOnClickScriptHandler(handler(self, self.OnBackBtnClickHandler))
	viewData.inputBtn:setOnClickScriptHandler(handler(self, self.onClickNumAction))
	viewData.clearBtn:setOnClickScriptHandler(handler(self, self.OnClearBtnClickHandler))
	viewData.filterBtn:setOnClickScriptHandler(handler(self, self.OnFilterBtnClickHandler))
	viewData.refreshBtn:setOnClickScriptHandler(handler(self, self.OnRefreshBtnClickHandler))
    for key, value in pairs(self.toggles) do
        value:setOnClickScriptHandler(handler(self, self.OnToggleClickHandler))
    end
	viewData.gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
	if 0 == #self.boss[self.currentPage] then
		viewData.gridView:setVisible(false)
		viewData.emptyPanel:setVisible(true)
		viewData.glowAnimation:setVisible(false)
		viewData.particle:setVisible(false)
	else
		viewData.gridView:setVisible(true)
		viewData.emptyPanel:setVisible(false)
		viewData.glowAnimation:setVisible(true)
		viewData.particle:setVisible(true)
		viewData.gridView:setCountOfCell(#self.boss[self.currentPage])
		viewData.gridView:reloadData()
	end

	self.countdownHandler = scheduler.scheduleGlobal(handler(self, self.SuppressCountDown), 1)
end


function Anniversary19SuppressMediator:OnRegist()
	regPost(POST.ANNIVERSARY2_BOSS)
	regPost(POST.ANNIVERSARY2_BOSS_FOR_HELP)
	regPost(POST.ANNIVERSARY2_BOSS_REWARD_DRAW)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end

function Anniversary19SuppressMediator:OnUnRegist()
	self.battleReadyLayer = nil
	-- 只有在PushGameScene的退出scene时需要手动置空
	if not self.notNeedClearGameScene and 1 == self.needKeepGameScene then
		app.uiMgr.gameScenes['Game.views.anniversary19.Anniversary19SuppressView'] = nil
	end
	unregPost(POST.ANNIVERSARY2_BOSS)
	unregPost(POST.ANNIVERSARY2_BOSS_FOR_HELP)
	unregPost(POST.ANNIVERSARY2_BOSS_REWARD_DRAW)
	if nil ~= self.countdownHandler then
		scheduler.unscheduleGlobal(self.countdownHandler)
		self.countdownHandler = nil
	end
	-- local scene = app.uiMgr:GetCurrentScene()
	-- scene:RemoveGameLayer(self.viewComponent)
end


function Anniversary19SuppressMediator:InterestSignals()
    local signals = {
		POST.ANNIVERSARY2_BOSS.sglName,
		POST.ANNIVERSARY2_BOSS_FOR_HELP.sglName,
		POST.ANNIVERSARY2_BOSS_REWARD_DRAW.sglName,
        POST.ANNIVERSARY2_HOME.sglName,
		"WONDERLAND_SUPPREDD_BOSS_FILTER",
		"REFRESH_NOT_CLOSE_GOODS_EVENT",
		SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
        SGL.NEXT_TIME_DATE,
	}
	return signals
end

function Anniversary19SuppressMediator:ProcessSignal(signal)
    local name = signal:GetName()
	local body = signal:GetBody()
	-- dump(body, name)
	if name == "WONDERLAND_SUPPREDD_BOSS_FILTER" then

		local viewData = self.viewComponent.viewData
		viewData.userIDLabel:setString("")
		viewData.searchImage:setVisible(true)
		viewData.clearBtn:setVisible(false)

		local parameters = {status = PAGE_DEFINE.NONPARTICIPANT}
		if OWNER_DEFINE.FRIEND == body.owner then
			parameters.showFriend = 1
		elseif OWNER_DEFINE.GUILD == body.owner then
			parameters.showUnion = 1
		end

		local bossList = app.anniversary2019Mgr:GetConfigDataByName(app.anniversary2019Mgr:GetConfigParse().TYPE.BOSS)
		local bossIds = {}
		for k, v in pairs(body.boss) do
			if v == true then
				bossIds[#bossIds+1] = k
			end
		end
		if 0 < #bossIds and table.nums(bossList) > #bossIds then
			parameters.bossId = table.concat( bossIds, "," )
		end

		local bossLevels = {}
		for k, v in pairs(body.level) do
			if v == true then
				bossLevels[#bossLevels+1] = k
			end
		end
		if 0 < #bossLevels then
			parameters.bossLevel = table.concat( bossLevels, "," )
		end
		self:SendSignal(POST.ANNIVERSARY2_BOSS.cmdName, parameters)
	elseif name == POST.ANNIVERSARY2_BOSS.sglName then
		local day = self.day
		self.day = body.day
		if day then
			if day ~= body.day then
				if app:RetrieveMediator('EnterBattleMediator') and self.battleReadyLayer then
					self.battleReadyLayer:RefreshRecommendCards(self:GetAdditionCards())
				end
			end
		end
		if 1 == body.requestData.onlyHandleDay then
			return
		end
		self.boss[self.currentPage] = body.boss
		if PAGE_DEFINE.SETTLEMENT == self.currentPage then
			for k, v in pairs(self.boss[self.currentPage]) do
				local rewards = {}
				for _, v2 in ipairs(v.rewards) do
					local isExist = false
					for _, v3 in pairs(rewards) do
						if v3.goodsId == v2.goodsId then
							v3.num = v3.num + v2.num
							isExist = true
							break
						end
					end
					if not isExist then
						rewards[#rewards+1] = v2
					end
				end
				v.rewards = rewards
			end
		end
		self:SortBossList()
		local viewData = self.viewComponent.viewData
		if 0 == #self.boss[self.currentPage] then
			viewData.gridView:setVisible(false)
			viewData.emptyPanel:setVisible(true)
			viewData.glowAnimation:setVisible(false)
			viewData.particle:setVisible(false)
		else
			viewData.gridView:setVisible(true)
			viewData.emptyPanel:setVisible(false)
			viewData.glowAnimation:setVisible(true)
			viewData.particle:setVisible(true)
			viewData.gridView:setCountOfCell(#self.boss[self.currentPage])
			viewData.gridView:reloadData()
		end
	elseif name == POST.ANNIVERSARY2_BOSS_FOR_HELP.sglName then
		if PAGE_DEFINE.PARTICIPANT == self.currentPage then
			local viewData = self.viewComponent.viewData
			local cells = viewData.gridView:getCells()
			for k, v in pairs(cells) do
				local boss = self.boss[self.currentPage][v:getIdx()+1]
				if boss then
					if boss.bossUuid == body.requestData.bossUuid then
						boss.help = 1
						local pviewData = v.viewData
						pviewData.leftCountdownLabel:setPositionY(88)
						pviewData.shareBtn:setVisible(false)
						pviewData.sharedPanel:setVisible(true)
						return
					end
				end
			end
		end
	elseif name == POST.ANNIVERSARY2_BOSS_REWARD_DRAW.sglName then
		app.uiMgr:AddDialog('common.RewardPopup', body)
		if PAGE_DEFINE.SETTLEMENT == self.currentPage then
			local viewData = self.viewComponent.viewData
			local cells = viewData.gridView:getCells()
			for k, v in pairs(cells) do
				local boss = self.boss[self.currentPage][v:getIdx()+1]
				if boss then
					if boss.bossUuid == body.requestData.bossUuid then
						boss.isDrawn = 1
						local pviewData = v.viewData
						pviewData.drawBtn:setEnabled(false)
						display.commonLabelParams(pviewData.drawBtn, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('已领取'))}))
						return
					end
				end
			end
		end
	elseif name == POST.ANNIVERSARY2_HOME.sglName then
		unregPost(POST.ANNIVERSARY2_HOME)
        app.anniversary2019Mgr:InitData(body)
		local viewData = self.viewComponent.viewData
		for k,v in pairs(viewData.moneyNodes) do
			v:updataUi(checkint( k ))
		end
	elseif name == "REFRESH_NOT_CLOSE_GOODS_EVENT" then
		local viewData = self.viewComponent.viewData
		for k,v in pairs(viewData.moneyNodes) do
			v:updataUi(checkint( k ))
		end
	elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
		local viewData = self.viewComponent.viewData
		for k,v in pairs(viewData.moneyNodes) do
			v:updataUi(checkint( k ))
		end
    elseif name == SGL.NEXT_TIME_DATE then
        self:SendSignal(POST.ANNIVERSARY2_BOSS.cmdName, {status = self.currentPage, onlyHandleDay = 1})
	end
end

function Anniversary19SuppressMediator:OnTipsBtnClickAction(sender)
	app.uiMgr:ShowIntroPopup({moduleId = '-41'})
end

function Anniversary19SuppressMediator:OnBackBtnClickHandler( sender )
	PlayAudioByClickNormal()

	self.notNeedClearGameScene = true
	if 1 == self.needKeepGameScene then
		app:UnRegsitMediator(NAME)
		app.uiMgr:PopGameScene()
	else
		app:RetrieveMediator('Router'):Dispatch({name = 'ActivityMediator'}, {name = 'anniversary19.Anniversary19HomeMediator'})
	end
end

function Anniversary19SuppressMediator:OnClearBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
	local viewData = self.viewComponent.viewData
	viewData.userIDLabel:setString("")
	viewData.searchImage:setVisible(true)
	viewData.clearBtn:setVisible(false)

	-- self:SendSignal(POST.ANNIVERSARY2_BOSS.cmdName, {status = PAGE_DEFINE.NONPARTICIPANT})
end

function Anniversary19SuppressMediator:OnFilterBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
	local Anniversary19SuppressFilterMediator = require("Game.mediator.anniversary19.Anniversary19SuppressFilterMediator")
	app:RegistMediator(Anniversary19SuppressFilterMediator.new())
end

function Anniversary19SuppressMediator:OnRefreshBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
	local function DelayRefresh()
		self.waitForRefresh = false
	end

	if not self.waitForRefresh then
		self.waitForRefresh = true

		local viewData = self.viewComponent.viewData
		viewData.userIDLabel:setString("")
		viewData.searchImage:setVisible(true)
		viewData.clearBtn:setVisible(false)
	
		self:SendSignal(POST.ANNIVERSARY2_BOSS.cmdName, {status = PAGE_DEFINE.NONPARTICIPANT})
		self.viewComponent:runAction(cc.Sequence:create(
			cc.DelayTime:create(5), 
			cc.CallFunc:create(DelayRefresh)
		))
	else
		app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('请过5秒后再尝试')))
	end
end

function Anniversary19SuppressMediator:OnToggleClickHandler( sender )
	local tag = sender:getTag()
	if self.currentPage == tag then
		self.toggles[tag]:setChecked(true)
		return
	end

	local viewData = self.viewComponent.viewData
	for index, value in ipairs(self.toggles) do
		if index == tag then
			value:setChecked(true)
			value:getLabel():setColor(ccc3FromInt('#7e3b23'))
		elseif index == self.currentPage then
			value:setChecked(false)
			value:getLabel():setColor(ccc3FromInt('#deaa83'))
		end
	end
	self.currentPage = tag
	viewData.searchPanel:setVisible(PAGE_DEFINE.NONPARTICIPANT == tag)
	if not self.boss[self.currentPage] then
		viewData.gridView:setVisible(false)
		viewData.emptyPanel:setVisible(true)
		viewData.glowAnimation:setVisible(false)
		viewData.particle:setVisible(false)
		self:SendSignal(POST.ANNIVERSARY2_BOSS.cmdName, {status = tag})
	else
		if 0 == #self.boss[self.currentPage] then
			viewData.gridView:setVisible(false)
			viewData.emptyPanel:setVisible(true)
			viewData.glowAnimation:setVisible(false)
			viewData.particle:setVisible(false)
		else
			viewData.gridView:setVisible(true)
			viewData.emptyPanel:setVisible(false)
			viewData.glowAnimation:setVisible(true)
			viewData.particle:setVisible(true)
			viewData.gridView:setCountOfCell(#self.boss[self.currentPage])
			viewData.gridView:reloadData()
		end
	end
end

function Anniversary19SuppressMediator:onClickNumAction(sender)
	PlayAudioByClickNormal()
	
	local tempData = {}
	tempData.callback = handler(self, self.numkeyboardCallBack)
	tempData.titleText = app.anniversary2019Mgr:GetPoText(__('请输入信息者ID'))
	tempData.nums = 10
	tempData.model = NumboardModel.freeModel

	local NumKeyboardMediator = require( 'Game.mediator.NumKeyboardMediator' )
	local mediator = NumKeyboardMediator.new(tempData)
	app:RegistMediator(mediator)
end

function Anniversary19SuppressMediator:numkeyboardCallBack(data)
	if data then
		local viewData = self.viewComponent.viewData
		viewData.userIDLabel:setString(data)
		viewData.searchImage:setVisible("" == data)
		viewData.clearBtn:setVisible("" ~= data)

		if "" ~= data then
			self:SendSignal(POST.ANNIVERSARY2_BOSS.cmdName, {status = PAGE_DEFINE.NONPARTICIPANT, discoveryPlayerId = data})
		else
			self:SendSignal(POST.ANNIVERSARY2_BOSS.cmdName, {status = PAGE_DEFINE.NONPARTICIPANT})
		end
	end
end

function Anniversary19SuppressMediator:OnDataSourceAction(p_convertview,idx)
	---@type Anniversary19SuppressCell
    local pCell = p_convertview
    if pCell == nil then
		pCell = require('Game.views.anniversary19.Anniversary19SuppressCell').new()
		local viewData = pCell.viewData
		viewData.bossPreviewBtn:setOnClickScriptHandler(handler(self,self.OnBOSSPreviewBtnClickHandler))
		viewData.rewardPreviewBtn:setOnClickScriptHandler(handler(self,self.OnRewardPreviewBtnClickHandler))
		viewData.shareBtn:setOnClickScriptHandler(handler(self,self.OnShareBtnClickHandler))
		viewData.suppressBtn:setOnClickScriptHandler(handler(self,self.OnSuppressBtnClickHandler))
		viewData.drawBtn:setOnClickScriptHandler(handler(self,self.OnDrawBtnClickHandler))
		viewData.recordBtn:setOnClickScriptHandler(handler(self,self.OnRecordBtnClickHandler))
		for key, value in pairs(viewData.goodsIcons) do
			value:setOnClickScriptHandler(handler(self, self.OnCellRewardBtnClickHandler))
		end
	end
	xTry(function()
		self:ReloadGridViewCell(pCell, idx)
	end, __G__TRACKBACK__)
	return pCell
end

function Anniversary19SuppressMediator:ReloadGridViewCell( pCell, idx )
	local index = idx + 1
	local viewData = pCell.viewData
	viewData.bossPreviewBtn:setTag(index)
	local boss = checktable(checktable(self.boss)[self.currentPage])[index]
	if not boss then return end

	local isSelf = app.gameMgr:GetUserInfo().playerId == tonumber(boss.discoveryPlayerId)
	local isShared = boss.help == 1

	viewData.settlementPanel:setVisible(PAGE_DEFINE.SETTLEMENT == self.currentPage)
	viewData.participantPanel:setVisible(PAGE_DEFINE.SETTLEMENT ~= self.currentPage)
	if PAGE_DEFINE.SETTLEMENT ~= self.currentPage then
		viewData.rewardPreviewBtn:setTag(index)

		viewData.suppressPanel:setVisible(PAGE_DEFINE.NONPARTICIPANT == self.currentPage)
		viewData.sharePanel:setVisible(PAGE_DEFINE.PARTICIPANT == self.currentPage)

		if PAGE_DEFINE.PARTICIPANT == self.currentPage then
			viewData.shareBtn:setTag(index)
			if isSelf then
				viewData.shareBtn:setVisible(not isShared)
				viewData.sharedPanel:setVisible(isShared)
			else
				viewData.shareBtn:setVisible(false)
				viewData.sharedPanel:setVisible(false)
			end
			if isShared then
				viewData.leftCountdownLabel:setPositionY(88)
			else
				viewData.leftCountdownLabel:setPositionY(115)
			end
			viewData.leftCountdownLabel:setString(self:ChangeTimeFormat(boss.leftSeconds))
		else
			viewData.suppressBtn:setTag(index)
			viewData.suppressCostPanel:setVisible(not isSelf)
			viewData.countdownLabel:setString(self:ChangeTimeFormat(boss.leftSeconds))
		end
		viewData.bossBloodBar:setMaxValue(self:CalculateBossBlood(boss.bossId, boss.level))
		viewData.bossBloodBar:setValue(boss.leftHp)
		viewData.bossImage:clearFilter()
	else
		if 1 == boss.isDrawn then
			viewData.drawBtn:setEnabled(false)
			display.commonLabelParams(viewData.drawBtn, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('已领取'))}))
		else
			viewData.drawBtn:setEnabled(true)
			display.commonLabelParams(viewData.drawBtn, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('领取'))}))
		end
		viewData.drawBtn:setTag(index)
		viewData.recordBtn:setTag(index)
		if 1 == boss.result then
			viewData.bossImage:setFilter(GrayFilter:create())
			display.commonLabelParams(viewData.resultLabel, {fontSize = 30, color = '#249bff', font = TTF_GAME_FONT, ttf = true, text = app.anniversary2019Mgr:GetPoText(__("讨伐成功"))})
		else
			viewData.bossImage:clearFilter()
			display.commonLabelParams(viewData.resultLabel, {fontSize = 30, color = '#ce351c', font = TTF_GAME_FONT, ttf = true, text = app.anniversary2019Mgr:GetPoText(__("讨伐失败"))})
		end

		local goodsIcons = viewData.goodsIcons
		local rewards = boss.rewards
		for i = 1, #goodsIcons do
			if i <= #rewards then
				goodsIcons[i]:RefreshSelf(rewards[i])
			end
		end
		for i = #rewards + 1, #goodsIcons do
			goodsIcons[i]:setVisible(false)
		end
		for i = #goodsIcons + 1, #rewards do
		    local goodsIcon = require('common.GoodNode').new({id = rewards[i].goodsId, amount = rewards[i].num, showAmount = true})
		    goodsIcon:setScale(0.8)
		    goodsIcon:setPosition(583, 58)
            viewData.settlementPanel:addChild(goodsIcon)
            goodsIcons[i] = goodsIcon
		end
		for i = 1, #rewards do
            goodsIcons[i]:setPositionX(783 - (#rewards-1) * 50 + (i-1)*100)
		end
		viewData.settlementBloodBar:setMaxValue(self:CalculateBossBlood(boss.bossId, boss.level))
		viewData.settlementBloodBar:setValue(boss.leftHp)
	end

	viewData.myPanel:setVisible(isSelf)
	viewData.otherPanel:setVisible(not isSelf)
	if not isSelf then
		local richLabel = {{text = boss.discoveryPlayerName, fontSize = 22, color = "#595755"}}
		if 1 == boss.isFriend then
			richLabel[#richLabel+1] = {text = app.anniversary2019Mgr:GetPoText(__("好友")), fontSize = 22, color = '#b24d29'}
		elseif 1 == boss.isUnion then
			richLabel[#richLabel+1] = {text = app.anniversary2019Mgr:GetPoText(__("工会")), fontSize = 22, color = '#b24d29'}
		end
        display.reloadRichLabel(viewData.ownerNameLabel, {c = richLabel})
	end
	viewData.bossImage:setTexture(self:GetBossImage(boss.bossId))

	local bossNameRichLabel = {}
	local bossName = string.split(__("等级：|_level_| |_name_|"), "|")
	for i, v in ipairs(bossName) do
		if "_level_" == v then
			bossNameRichLabel[#bossNameRichLabel+1] = {text = boss.level, fontSize = 24, color = '#6c5353'}
		elseif "_name_" == v then
			bossNameRichLabel[#bossNameRichLabel+1] = {text = self:GetBossName(boss.bossId), fontSize = 22, color = '#b24d29'}
		elseif "" ~= v then
			bossNameRichLabel[#bossNameRichLabel+1] = {text = v, fontSize = 24, color = '#6c5353'}
		end
	end
	display.reloadRichLabel(viewData.bossNameLabel, {c = bossNameRichLabel})
end

function Anniversary19SuppressMediator:OnBOSSPreviewBtnClickHandler( sender )
	PlayAudioByClickNormal()

	local boss = self.boss[self.currentPage][sender:getTag()]
	local questId = anniversary2019Mgr:GetConfigDataByName(anniversary2019Mgr:GetConfigParse().TYPE.BOSS)[tostring(boss.bossId)][tostring(boss.level)].questId

    local bossDetailMediator = require('Game.mediator.BossDetailMediator').new({questId = questId})
    app:RegistMediator(bossDetailMediator)
end

function Anniversary19SuppressMediator:OnRewardPreviewBtnClickHandler( sender )
	PlayAudioByClickNormal()

	local boss = self.boss[self.currentPage][sender:getTag()]
	local Anniversary19SuppressRewardPreviewMediator = require('Game.mediator.anniversary19.Anniversary19SuppressRewardPreviewMediator').new(boss)
	app:RegistMediator(Anniversary19SuppressRewardPreviewMediator)
end

function Anniversary19SuppressMediator:OnShareBtnClickHandler( sender )
	PlayAudioByClickNormal()

	local boss = self.boss[self.currentPage][sender:getTag()]

	if boss.leftSeconds > 0 then
		self:SendSignal(POST.ANNIVERSARY2_BOSS_FOR_HELP.cmdName, {bossUuid = boss.bossUuid})
	else
		app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('boss已过期')))
	end
end

function Anniversary19SuppressMediator:OnSuppressBtnClickHandler( sender )
	PlayAudioByClickNormal()

	local boss = self.boss[self.currentPage][sender:getTag()]
	if boss.leftSeconds > 0 then

		if app.gameMgr:GetUserInfo().playerId == tonumber(boss.discoveryPlayerId) then
			self:showBattleReady(boss.bossUuid, boss.bossId, boss.level, true, boss.leftHp)
			return
		end

		if app.activityHpMgr:GetHpAmountByHpGoodsId(anniversary2019Mgr:GetSuppressHPId()) < tonumber(anniversary2019Mgr:GetSuppressHPConsume()) then
			local goodsConfig = CommonUtils.GetConfig('goods', 'goods', anniversary2019Mgr:GetSuppressHPId())
			app.uiMgr:ShowInformationTips(string.format(app.anniversary2019Mgr:GetPoText(__('%s不足')), goodsConfig.name))
		else
			self:showBattleReady(boss.bossUuid, boss.bossId, boss.level, false, boss.leftHp)
		end
	else
		app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('boss已过期')))
	end
end

function Anniversary19SuppressMediator:OnDrawBtnClickHandler( sender )
	PlayAudioByClickNormal()

	local boss = self.boss[self.currentPage][sender:getTag()]
	self:SendSignal(POST.ANNIVERSARY2_BOSS_REWARD_DRAW.cmdName, {bossUuid = boss.bossUuid})
end

function Anniversary19SuppressMediator:OnRecordBtnClickHandler( sender )
	PlayAudioByClickNormal()

	local boss = self.boss[self.currentPage][sender:getTag()]
    app.uiMgr:AddDialog("Game.views.anniversary19.Anniversary19SuppressRecordPopup", boss.damage)
end

function Anniversary19SuppressMediator:SuppressCountDown( dt )
	local needReload = false
	for kb, vb in pairs(self.boss) do
		if kb ~= PAGE_DEFINE.SETTLEMENT then
			for k, v in pairs(vb) do
				if v.leftSeconds > 0 then
					v.leftSeconds = v.leftSeconds - 1
				else
					if PAGE_DEFINE.SETTLEMENT ~= self.currentPage then
						self.boss[PAGE_DEFINE.SETTLEMENT] = nil
					end
					needReload = true
				end
			end
		end
	end
	
	if needReload then
		self:SendSignal(POST.ANNIVERSARY2_BOSS.cmdName, {status = self.currentPage})
		return
	end
	local viewData = self.viewComponent.viewData
	local cells = viewData.gridView:getCells()
	for k, v in pairs(cells) do
		if self.boss[self.currentPage] then
			local boss = self.boss[self.currentPage][v:getIdx()+1]
			if boss then
				if boss.leftSeconds >= 0 then
					if PAGE_DEFINE.NONPARTICIPANT == self.currentPage then
						v.viewData.countdownLabel:setString(self:ChangeTimeFormat(boss.leftSeconds))
					elseif PAGE_DEFINE.PARTICIPANT == self.currentPage then
						v.viewData.leftCountdownLabel:setString(self:ChangeTimeFormat(boss.leftSeconds))
					end
				end
			end
		end
	end
end

function Anniversary19SuppressMediator:OnCellRewardBtnClickHandler( sender )
	PlayAudioByClickNormal()
	app.uiMgr:ShowInformationTipsBoard({
		targetNode = sender, iconId = checkint(sender.goodId), type = 1
	})
end

--==============================--
--desc: 显示战斗预览界面
--@params questId 关卡id
--@return
--==============================--
function Anniversary19SuppressMediator:showBattleReady(bossUuid, bossId, level, isSelf, leftHp)
	local questId = anniversary2019Mgr:GetConfigDataByName(anniversary2019Mgr:GetConfigParse().TYPE.BOSS)[tostring(bossId)][tostring(level)].questId
    -- 显示编队界面
    local battleReadyData = BattleReadyConstructorStruct.New(
            2,
            app.gameMgr:GetUserInfo().localCurrentBattleTeamId,
            nil,
            questId,
            CommonUtils.GetQuestBattleByQuestId(questId),
            nil,
            POST.ANNIVERSARY2_BOSS_QUEST_AT.cmdName,
            { bossUuid = bossUuid },
            POST.ANNIVERSARY2_BOSS_QUEST_AT.sglName,
            POST.ANNIVERSARY2_BOSS_QUEST_GRADE.cmdName,
            { bossUuid = bossUuid },
            POST.ANNIVERSARY2_BOSS_QUEST_GRADE.sglName,
            "anniversary19.Anniversary19SuppressMediator",
            "anniversary19.Anniversary19SuppressMediator"
	)
	battleReadyData.disableUpdateBackButton = true
    --------------- 初始化战斗传参 ---------------
    local layer = require('Game.views.anniversary19.Anniversary19BattleReadyView').new(battleReadyData)
    layer:setPosition(cc.p(display.cx,display.cy))
	app.uiMgr:GetCurrentScene():AddDialog(layer)
	
	if not isSelf then
		layer:AddTopCurrency({ anniversary2019Mgr:GetSuppressHPId() }, {consumeGoods = anniversary2019Mgr:GetSuppressHPId(), consumeGoodsNum = anniversary2019Mgr:GetSuppressHPConsume()})
	end

	layer:RefreshRecommendCards(self:GetAdditionCards())
	self.battleReadyLayer = layer
end

function Anniversary19SuppressMediator:GetAdditionCards()
	local day = self.day or 1
	local cardAddition = anniversary2019Mgr:GetConfigDataByName(anniversary2019Mgr:GetConfigParse().TYPE.CARD_ADDITION)
	local addition = {}
	for k, v in orderedPairs(cardAddition) do
		if tonumber(v.from) <= day and tonumber(v.to) >= day then
			addition[#addition+1] = v
		end
	end
	return addition
end

function Anniversary19SuppressMediator:SortBossList()
	local playerId = app.gameMgr:GetUserInfo().playerId
	local function SortBoss(a, b)
		local aIsMe = tonumber(a.discoveryPlayerId) == playerId
		local bIsMe = tonumber(b.discoveryPlayerId) == playerId
		if aIsMe == bIsMe then
			return a.leftSeconds < b.leftSeconds
		else
			if aIsMe then
				return true
			else
				return false
			end
		end
	end
	table.sort(self.boss[self.currentPage], SortBoss)
end

function Anniversary19SuppressMediator:CalculateBossBlood(bossId, level)
	local questId = anniversary2019Mgr:GetConfigDataByName(anniversary2019Mgr:GetConfigParse().TYPE.BOSS)[tostring(bossId)][tostring(level)].questId
	local enemy = CommonUtils.GetConfig("quest", "enemy", tostring(questId))["1"]["npc"][1]
	local monster = CommonUtils.GetConfig("monster", "monster", enemy.npcId)
	return monster.hp * enemy.attrGrow
end

function Anniversary19SuppressMediator:GetBossName(bossId)
	if not self.bossName then
		self.bossName = {}
		local chapter = anniversary2019Mgr:GetConfigDataByName(anniversary2019Mgr:GetConfigParse().TYPE.CHAPTER)
		for k, v in pairs(chapter) do
			self.bossName[v.bossId] = v.bossName
		end
	end
	return self.bossName[tostring(bossId)]
end

function Anniversary19SuppressMediator:GetBossImage(bossId)
	if not self.bossImage then
		self.bossImage = {}
		local chapter = anniversary2019Mgr:GetConfigDataByName(anniversary2019Mgr:GetConfigParse().TYPE.CHAPTER)
		for k, v in pairs(chapter) do
			self.bossImage[v.bossId] = app.anniversary2019Mgr:GetResPath("ui/anniversary19/wonderland/wonderland_battle_boss" .. k)
		end
	end
	return self.bossImage[tostring(bossId)]
end

--[[
时间转换
--]]
function Anniversary19SuppressMediator:ChangeTimeFormat( seconds )
	local c = nil
	if checkint(seconds) >= 86400 then
		local day = math.floor(seconds/86400)
		local hour = math.floor((seconds%86400)/3600)
		c = string.fmt(app.anniversary2019Mgr:GetPoText(__('_num1_天_num2_小时')), {['_num1_'] = tostring(day),['_num2_'] = tostring(hour)})
	else
		local hour   = math.floor(seconds / 3600)
		local minute = math.floor((seconds - hour*3600) / 60)
		local sec    = (seconds - hour*3600 - minute*60)
		c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
	end
	return c
end

return Anniversary19SuppressMediator
