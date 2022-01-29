--[[
常驻累充Mediator
--]]
local Mediator = mvc.Mediator

local CumulativeRechargeMediator = class("CumulativeRechargeMediator", Mediator)

local NAME = "CumulativeRechargeMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
function CumulativeRechargeMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.args = checktable(params) or {}
	self.rewardDatas = {} -- 奖励信息
	self.moneyPoints = 0 -- 充值数目
	self.selectedIndex = 1 -- 档位
	self.selectedReward = 0 -- 选中的奖励
	self.isControllable = true -- 能否点击
end
function CumulativeRechargeMediator:InterestSignals()
	local signals = {
		POST.CUMULATIVE_RECHARGE_DRAW.sglName,
		POST.CUMULATIVE_RECHARGE_HOME.sglName,
		CUMULATIVE_RECHARGE_CHOICE_REWARD,
		EVENT_PAY_MONEY_SUCCESS,
		EVENT_APP_STORE_PRODUCTS,
	}

	return signals
end
function CumulativeRechargeMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local datas = signal:GetBody()
	if name == POST.CUMULATIVE_RECHARGE_DRAW.sglName then
		self:DrawAction(datas)
	elseif name == POST.CUMULATIVE_RECHARGE_HOME.sglName then
		self.rewardDatas = checktable(datas.accumulativeList)
		self.moneyPoints = checkint(datas.moneyPoints)
		self:RefreshView()
	elseif name == CUMULATIVE_RECHARGE_CHOICE_REWARD then
		self:SetSelectedReward(datas.selectedReward)
	elseif name == EVENT_PAY_MONEY_SUCCESS then
		self:SendSignal(POST.CUMULATIVE_RECHARGE_HOME.cmdName)
	elseif name == EVENT_APP_STORE_PRODUCTS then
		self:ShowTipsView()
	end
end
function CumulativeRechargeMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.CumulativeRechargeView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	local viewData = viewComponent.viewData_
	viewData.rechargeBtn:setOnClickScriptHandler(handler(self, self.RechargeButtonCallback))
	viewData.leftSwitchBtn:setOnClickScriptHandler(handler(self, self.SwitchButtonCallback))
	viewData.rightSwitchBtn:setOnClickScriptHandler(handler(self, self.SwitchButtonCallback))
	viewData.drawBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
	viewData.progressTipsBtn:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
	if self.payload then
		self.rewardDatas = checktable(self.payload.accumulativeList)
		self.moneyPoints = checkint(self.payload.moneyPoints)
	end
	self:InitSelectedIndex()
	self:RefreshView()
	self:EnterAction()
end
--[[
初始化档位
--]]
function CumulativeRechargeMediator:InitSelectedIndex()
	for i, v in ipairs(self.rewardDatas) do
		if checkint(v.hasDrawn) == 0 then
			self.selectedIndex = i 
			break
		end
	end
end
--[[
刷新界面
--]]
function CumulativeRechargeMediator:RefreshView()
	local datas = self.rewardDatas[self.selectedIndex]
	local viewData = self:GetViewComponent().viewData_
	self:UpdateProgressBar()
	self:UpdateSwitchBtn()
	self:UpdateRoleImage()
	self:UpdateDrawButton()
	self:UpdateCumulativeRichLabel()
	viewData.rewardLayout:RefreshView(datas)
end
--[[
更新顶部状态条
--]]
function CumulativeRechargeMediator:UpdateProgressBar()
	local datas = self.rewardDatas[self.selectedIndex]
	local moneyPoints = checkint(datas.moneyPoints)
	local viewData = self:GetViewComponent().viewData_
	viewData.progressBar:setMaxValue(moneyPoints)
	viewData.progressBar:setValue(self.moneyPoints)
	viewData.progressLabel:setString(string.format('%d/%d', math.min(self.moneyPoints, moneyPoints), moneyPoints))
	display.reloadRichLabel(viewData.progressTips, {c = {
		{text = __("累计获得"), fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = '#5b3c25'},
		{text = '  ', fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = '#5b3c25'},
		{text = string.fmt(__('_num_积分'), {['_num_'] = tostring(moneyPoints)}), fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = '#d23d3d'},
		{text = '  ', fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = '#5b3c25'},
		{text = __("可获得该档位奖励"), fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = '#5b3c25'},
	}})
	CommonUtils.SetNodeScale(viewData.progressTips , {width = 615})
	local progressTipsWidth =  display.getLabelContentSize(viewData.progressTips).width
	progressTipsWidth = progressTipsWidth > 615 and 615 or progressTipsWidth
	viewData.progressTipsBtn:setPositionX(progressTipsWidth + 20)
	if self.moneyPoints >= moneyPoints then
		viewData.lastRichLabel:setVisible(false)
	else
		viewData.lastRichLabel:setVisible(true)
		display.reloadRichLabel(viewData.lastRichLabel, {c = {
			{color = '#5b3c25', fontSize = 22, text = __('距离奖励还差')},
			{color = '#5b3c25', fontSize = 22, text = ' '},
			{color = '#d23d3d', fontSize = 22, text = string.fmt(__('_num_积分'), {['_num_'] = tostring(moneyPoints - self.moneyPoints)})}
		}})
		CommonUtils.SetNodeScale(viewData.lastRichLabel ,{w = 500 })
	end
end
--[[
更新切换按钮
--]]
function CumulativeRechargeMediator:UpdateSwitchBtn()
	local datas = self.rewardDatas
	local viewData = self:GetViewComponent().viewData_
	if self.selectedIndex == 1 then
		viewData.leftSwitchBtn:setVisible(false)
	else
		viewData.leftSwitchBtn:setVisible(true)
	end
	if self.selectedIndex >= self:GetViewMax() then
		viewData.rightSwitchBtn:setVisible(false)
	else
		viewData.rightSwitchBtn:setVisible(true)
	end
end
--[[
更新累充数目
--]]
function CumulativeRechargeMediator:UpdateCumulativeRichLabel()
	display.reloadRichLabel(self:GetViewComponent().viewData_.cumulativeRichLabel, {c = {
        {fontSize = 22 , color = "#ffffff" , text =  __('当前累计充值'), ttf = true, font = TTF_GAME_FONT} ,
        {fontSize = 22 , color = "#ffffff" , text =  '  ', ttf = true, font = TTF_GAME_FONT} ,
        {fontSize = 22 , color = "#ff942c" , text =  self.moneyPoints, ttf = true, font = TTF_GAME_FONT},
        {fontSize = 22 , color = "#ffffff" , text =  '  ', ttf = true, font = TTF_GAME_FONT} ,
        {fontSize = 22 , color = "#ffffff" , text =  __('积分'), ttf = true, font = TTF_GAME_FONT}
	}})
	CommonUtils.AddRichLabelTraceEffect(self:GetViewComponent().viewData_.cumulativeRichLabel, '#5b3c25' , 1  , {1, 3, 5})
	CommonUtils.SetNodeScale(self:GetViewComponent().viewData_.cumulativeRichLabel, { width  = 480 })
end
--[[
更新领奖按钮
--]]
function CumulativeRechargeMediator:UpdateDrawButton()
	local datas = self.rewardDatas[self.selectedIndex]
	local viewData = self:GetViewComponent().viewData_
	if checkint(datas.hasDrawn) > 0 then
		viewData.drawBtn:setEnabled(false)
		viewData.drawBtn:getLabel():setVisible(false)
		viewData.drawBtn:setScale(0.9)
		viewData.drawLabel:setVisible(true)
	else
		if self.moneyPoints >= checkint(datas.moneyPoints) then
			viewData.drawBtn:setEnabled(true)
			viewData.drawBtn:getLabel():setVisible(true)
			viewData.drawBtn:setScale(1)
			viewData.drawLabel:setVisible(false)
			viewData.drawBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
			viewData.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
		else
			viewData.drawBtn:setEnabled(true)
			viewData.drawBtn:getLabel():setVisible(true)
			viewData.drawBtn:setScale(1)
			viewData.drawLabel:setVisible(false)
			viewData.drawBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
			viewData.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
		end
	end
end
--[[
更新角色
--]]
function CumulativeRechargeMediator:UpdateRoleImage()
	local datas = self.rewardDatas[self.selectedIndex]
	local viewData = self:GetViewComponent().viewData_
	local groupId = checkint(datas.groupId or 1)
	viewData.role:setTexture(_res(string.format('ui/home/recharge/recharge_npc_%d.png', groupId)))
end
--[[
充值按钮点击回调
--]]
function CumulativeRechargeMediator:RechargeButtonCallback( sender )
	PlayAudioByClickNormal()
	if GAME_MODULE_OPEN.NEW_STORE then
		app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.DIAMOND})
    else
        app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
	end
end
--[[
切换按钮回调
--]]
function CumulativeRechargeMediator:SwitchButtonCallback( sender )
	if not self.isControllable then return end
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == 101 then
		if self.selectedIndex > 1 then
			self.selectedIndex = self.selectedIndex - 1
			self:SetSelectedReward(0)
			self:SwitchAction(true)
		end
	elseif tag == 102 then
		if self.selectedIndex < #self.rewardDatas then
			self.selectedIndex = self.selectedIndex + 1
			self:SetSelectedReward(0)
			self:SwitchAction(false)
		end
	end
	self:UpdateProgressBar()
	self:UpdateSwitchBtn()
	self:UpdateRoleImage()
	self:UpdateDrawButton()
end
--[[
领取按钮回调
--]]
function CumulativeRechargeMediator:DrawButtonCallback( sender )
	PlayAudioByClickNormal()
    local datas = self.rewardDatas[self.selectedIndex]
    if self.moneyPoints >= checkint(datas.moneyPoints) then
    	if datas.rewards and next(datas.rewards) ~= nil then
			if self.selectedReward > 0 then
				local commonTip = require('common.NewCommonTip').new({
					text = __('是否领取这些奖励？'),
					extra = __('tips:奖励领取成功后不可退还'),
					callback = function ()
						self:SendSignal(POST.CUMULATIVE_RECHARGE_DRAW.cmdName, {accumulativeId = checkint(datas.id), rewardId = self.selectedReward - 1})
					end
				})
				commonTip:setPosition(display.center)
				uiMgr:GetCurrentScene():AddDialog(commonTip)

			else
				uiMgr:ShowInformationTips(__('请先选择奖励'))
			end
    	else
    		self:SendSignal(POST.CUMULATIVE_RECHARGE_DRAW.cmdName, {accumulativeId = checkint(datas.id)})
    	end
    else
    	uiMgr:ShowInformationTips(__('积分不足'))
    end
end
--[[
提示按钮点击回调
--]]
function CumulativeRechargeMediator:TipsButtonCallback( sender )
	PlayAudioByClickNormal()
	if isElexSdk() then
		-- 获取当前商店货币类型
		local channelProducts = gameMgr:GetUserInfo().channelProducts
		if channelProducts then
			require('root.AppSDK').GetInstance():QueryProducts({channelProducts[1].channelProductId})
		end
	else
		self:ShowTipsView()
	end
end

--[[
显示tips页面
--]]
function CumulativeRechargeMediator:ShowTipsView()
	local descr = __('        1.此次累计充值永久开放，本次活动的积分根据御侍创建账号后所充值的金额决定，积分为充值金额数量。\n        2.累积的充值积分达到要求积分后，即可领取相应奖励，每个奖励只能领取一次。\n        3.特殊奖励为三个奖励中选择一个作为最终奖励。')
	if isElexSdk() or isKoreanSdk() then
		local currencyConf = CommonUtils.GetConfigAllMess('currency', 'activity')
		local channelProducts = gameMgr:GetUserInfo().channelProducts
		local sdkInstance = require("root.AppSDK").GetInstance()
		local currencySymbol = isKoreanSdk() and '￦' or string.gsub(sdkInstance.loadedProducts[tostring(channelProducts[1].channelProductId)].priceLocale, "%d+(.-)%d*$", ' ')
		local currencyType =  isKoreanSdk() and 'KRW' or cc.UserDefault:getInstance():getStringForKey('EATER_ELEX_CURRENCY_CODE')
		descr = descr .. '\n'
		for k,v in orderedPairs(currencyConf) do
			if checkint(v.moneyPoints) ~= 0 and checkint(v[tostring(currencyType)]) ~= 0 then
				if isKoreanSdk() then
					descr = descr .. currencySymbol .. v[tostring(currencyType)] ..  ' = ' .. v.moneyPoints .. __('积分') .. ' ' .. '\n'
				else
					descr = descr .. currencySymbol .. v[tostring(currencyType)] .. currencyType ..  ' = ' .. v.moneyPoints .. __('积分') .. ' ' .. '\n'
				end
			end
		end
	end
	uiMgr:ShowIntroPopup({title = __('规则说明'), descr = descr ,isTTF = false })
end
--[[
切换动画
@params reverse bool 是否翻转
--]]
function CumulativeRechargeMediator:SwitchAction( reverse )
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData_
	viewData.nextRewardLayout:RefreshView(self.rewardDatas[self.selectedIndex])
	viewData.nextRewardLayout:setOpacity(0)
	viewData.nextRewardLayout:setVisible(true)
	local actTime = 0.2
	self.isControllable = false
	if reverse then -- 是否翻转
		viewData.nextRewardLayout:setLocalZOrder(3)
		viewData.rewardLayout:setLocalZOrder(4)
		viewData.nextRewardLayout:setPositionX(880)
		viewComponent:runAction(
			cc.Sequence:create(
				cc.Spawn:create(
					cc.TargetedAction:create(viewData.nextRewardLayout, cc.Spawn:create(
						cc.MoveTo:create(actTime, cc.p(1020, 12)),
						cc.FadeIn:create(actTime)
					)),
					cc.TargetedAction:create(viewData.rewardLayout, cc.Spawn:create(
						cc.MoveTo:create(actTime, cc.p(1160, 12)),
						cc.FadeOut:create(actTime)
					))
				),
				cc.CallFunc:create(function ()
					local temp = viewData.nextRewardLayout
					viewData.nextRewardLayout = viewData.rewardLayout
					viewData.rewardLayout = temp
					viewData.nextRewardLayout:setVisible(false)
					self.isControllable = true
				end)
			)
		)
	else
		viewData.nextRewardLayout:setLocalZOrder(4)
		viewData.rewardLayout:setLocalZOrder(3)
		viewData.nextRewardLayout:setPositionX(1160)
		viewComponent:runAction(
			cc.Sequence:create(
				cc.Spawn:create(
					cc.TargetedAction:create(viewData.nextRewardLayout, cc.Spawn:create(
						cc.MoveTo:create(actTime, cc.p(1020, 12)),
						cc.FadeIn:create(actTime)
					)),
					cc.TargetedAction:create(viewData.rewardLayout, cc.Spawn:create(
						cc.MoveTo:create(actTime, cc.p(880, 12)),
						cc.FadeOut:create(actTime)
					))
				),
				cc.CallFunc:create(function ()
					local temp = viewData.nextRewardLayout
					viewData.nextRewardLayout = viewData.rewardLayout
					viewData.rewardLayout = temp
					viewData.nextRewardLayout:setVisible(false)
					self.isControllable = true
				end)
			)
		)
	end
end
--[[
设置选择的奖励
--]]
function CumulativeRechargeMediator:SetSelectedReward( selectedReward )
	self.selectedReward = checkint(selectedReward)
end
--[[
领奖
--]]
function CumulativeRechargeMediator:DrawAction( datas )
	local index = self.selectedIndex
	uiMgr:AddDialog('common.RewardPopup', {rewards = datas.rewards})
	self:SetSelectedReward(0)
	self.rewardDatas[index].hasDrawn = 1
	if datas.requestData.rewardId then
		self.rewardDatas[index].rewards[checkint(datas.requestData.rewardId) + 1].hasDrawn = 1
	end
	self:RefreshView()
end
--[[
获取当先能显示的最大页数
--]]
function CumulativeRechargeMediator:GetViewMax()
	local datas = self.rewardDatas
	local group = 1
	local hasDrawn = true
	for i, v in ipairs(datas) do
		if checkint(v.hasDrawn) < 1 then
			hasDrawn = false
		end
		if checkint(v.groupId) > group then
			group = checkint(v.groupId)
		end
		if not hasDrawn then break end
	end
	for i, v in ipairs(datas) do
		if checkint(v.groupId) > group then
			return i - 1
		end
	end
	return #datas
end
function CumulativeRechargeMediator:EnterAction()
	local viewComponent = self:GetViewComponent()
	viewComponent:setOpacity(0)
	viewComponent:runAction(cc.FadeIn:create(0.15))
end
function CumulativeRechargeMediator:OnRegist(  )
	regPost(POST.CUMULATIVE_RECHARGE_HOME)
	regPost(POST.CUMULATIVE_RECHARGE_DRAW)
end

function CumulativeRechargeMediator:OnUnRegist(  )
	unregPost(POST.CUMULATIVE_RECHARGE_HOME)
	unregPost(POST.CUMULATIVE_RECHARGE_DRAW)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end

return CumulativeRechargeMediator