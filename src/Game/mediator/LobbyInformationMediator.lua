--[[
餐厅信息页面Mediator
--]]
local Mediator = mvc.Mediator

local LobbyInformationMediator = class("LobbyInformationMediator", Mediator)

local NAME = "LobbyInformationMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local scheduler = require('cocos.framework.scheduler')
local LobbyInformationCell = require('home.LobbyInformationCell')
local LobbyPopularityRankingCell = require('home.LobbyPopularityRankingCell')
local LobbyLastRankingCell = require('home.LobbyLastRankingCell')
local LobbyRewardListCell = require('home.LobbyRewardListCell')
function LobbyInformationMediator:ctor( params, viewComponent )
	self.popularityRank     	   = params.popularityRank or {}
	self.lastPopularityRank        = params.lastPopularityRank or {}
	self.popularityRankLeftSeconds = params.popularityRankLeftSeconds or 0
    self.myPopularityRank          = params.myPopularityRank or 0
    self.lastPopularityRankRewards = params.lastPopularityRankRewards or {}
    self.myLastPopularitRank       = params.myLastPopularitRank or 0
    self.myPopularityScore         = params.myPopularityScore or 0
    self.myLastPopularityScore     = params.myLastPopularityScore or 0
    self.traffic				   = params.traffic or 0
    self.bill 	   				   = params.bill or {}
    self.waiterNum	    	 	   = params.waiterNum or 0
    self.bug 					   = params.bug or {}
	self.super:ctor(NAME,viewComponent)
	self.selectedTab = 1 -- 选择的页签
	self.showLayer = {}
end
local BTNDATA = {
	{name = __('餐厅升级'), tag = 1002},
	{name = __('餐厅信息'), tag = 1001},
	-- {name = __('知名度排行'), tag = 1003},
	-- {name = __('事件详情	'), tag = 1004}
}

function LobbyInformationMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Restaurant_LevelUp_Callback,
		SIGNALNAMES.MaterialCompose_Callback,
		SGL.REFRESH_NOT_CLOSE_GOODS_EVENT
	}

	return signals
end

function LobbyInformationMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	if name == SIGNALNAMES.Restaurant_LevelUp_Callback then
		local datas = signal:GetBody()
		-- 扣除道具
		local upgradeDatas = CommonUtils.GetConfigNoParser('restaurant', 'levelUp', datas.newLevel)
		-- 领奖
		CommonUtils.DrawRewards(checktable(upgradeDatas.avatarRewards))
		for i,v in ipairs(upgradeDatas.consumeGoods) do
			CommonUtils.DrawRewards({{goodsId = v.goodsId, num = - checkint(v.num)}})
		end
		gameMgr:GetUserInfo().restaurantLevel = checkint(datas.newLevel)
		app.fishingMgr:UpdateFishLevel()
		gameMgr:GetUserInfo().popularity = checkint(datas.newPopularity)
		self.showLayer['1002']:UpdateUI()
		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
		self:GetViewComponent().viewData.gridView:reloadData()
		uiMgr:AddDialog("home.LobbyUpgradeView")
		AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_AVATAR_SHOP_UPDATE_REMIND, {restaurantLevel = gameMgr:GetUserInfo().restaurantLevel})
		AppFacade.GetInstance():DispatchObservers(SGL.CAT_HOUSE_CHECK_UNLOCKED, {restaurantLevel = gameMgr:GetUserInfo().restaurantLevel})
	elseif name == SIGNALNAMES.MaterialCompose_Callback then -- 材料合成
		if self.showLayer['1002'] then
			self.showLayer['1002']:UpdateUI()
		end
	elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
		if self.showLayer['1002'] then
			self.showLayer['1002']:UpdateUI()
		end
	end
end


function LobbyInformationMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.LobbyInformationView' ).new({tag = 5000, mediatorName = "LobbyInformationMediator"})
	viewComponent:setTag(5000)
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddGameLayer(viewComponent)
	local viewData = viewComponent.viewData
	viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.ButtonDataSource))
	viewData.gridView:setCountOfCell(table.nums(BTNDATA))
	viewData.gridView:reloadData()
	self:TabButtonCallback(self.selectedTab)
	-- 开启定时器
	self.scheduler = scheduler.scheduleGlobal(handler(self, self.ScheduleCallback), 1)
end
--[[
知名度页面按钮回调
--]]
function LobbyInformationMediator:PopularityViewBtnCallback( sender )
	-- 添加点击音效
	PlayAudioByClickNormal()
    if CommonUtils.UnLockModule(RemindTag.BTN_AVATAR_UPGRADE, true) then
        if self.showLayer['1002'].canUpgrade then
            self:SendSignal(COMMANDS.COMMAND_Restaurant_LevelUp)
        else
        	if not self.showLayer['1002'].goldEnough then
        		uiMgr:ShowInformationTips(__('金币不足'))
        	elseif not self.showLayer['1002'].materialEnough then
        		uiMgr:ShowInformationTips(__('材料不足'))
        	elseif not self.showLayer['1002'].popularityEnough then
        		uiMgr:ShowInformationTips(__('知名度不足'))
        	end
        end
    end
end
--[[
知名度排行页面按钮回调
--]]
function LobbyInformationMediator:RankingViewBtnCallback( sender )
	-- 添加点击音效
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == 3001 then
		local scene = uiMgr:GetCurrentScene()
		local LobbyLastRankingView  = require( 'Game.views.LobbyLastRankingView' ).new({tag = 3100, mediatorName = "LobbyInformationMediator"})
		LobbyLastRankingView:setTag(3100)
		LobbyLastRankingView:setPosition(display.center)
		scene:AddDialog(LobbyLastRankingView)
		local gridView = LobbyLastRankingView.viewData.gridView
		gridView:setDataSourceAdapterScriptHandler(handler(self, self.LastRankingDataSource))
		gridView:setCountOfCell(table.nums(self.lastPopularityRank))
		gridView:reloadData()


	elseif tag == 3002 then
		local scene = uiMgr:GetCurrentScene()
		local LobbyRewardListView  = require( 'Game.views.LobbyRewardListView' ).new({tag = 3200, mediatorName = "LobbyInformationMediator"})
		LobbyRewardListView:setTag(3200)
		LobbyRewardListView:setPosition(display.center)
		scene:AddDialog(LobbyRewardListView)
		local gridView = LobbyRewardListView.viewData.gridView
		gridView:setDataSourceAdapterScriptHandler(handler(self, self.RewardListDataSource))
		local rewardDatas = CommonUtils.GetConfigAllMess('popularityRankReward', 'restaurant')
		gridView:setCountOfCell(table.nums(rewardDatas))
		gridView:reloadData()
	end

end
function LobbyInformationMediator:LastRankingDataSource( p_convertview,idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(458, 52)
    if pCell == nil then
        pCell = LobbyLastRankingCell.new(cSize)
    else

    end
	xTry(function()
		pCell.nameLabel:setString(self.lastPopularityRank[index].playerName)
		pCell.rankNum:setString(self.lastPopularityRank[index].rank)
		if self.lastPopularityRank[index].rank >= 1 and self.lastPopularityRank[index].rank <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/lobby/information/restaurant_info_bg_rank_num' .. tostring(self.lastPopularityRank[index].rank) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
		end
		pCell.scoreNum:setString(self.lastPopularityRank[index].popularity)
	end,__G__TRACKBACK__)
    return pCell
end
function LobbyInformationMediator:RewardListDataSource( p_convertview,idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(458, 94)
    if pCell == nil then
        pCell = LobbyRewardListCell.new(cSize)
    else

    end
	xTry(function()
		local rewardDatas = CommonUtils.GetConfigNoParser('restaurant', 'popularityRankReward', index)
		if checkint(rewardDatas.lowerLimit) == checkint(rewardDatas.upperLimit) then
			pCell.numLabel:setString(string.fmt(__('第_num_名'), {['_num_'] = rewardDatas.upperLimit}))
		else
			pCell.numLabel:setString(tostring(rewardDatas.upperLimit) .. '~' .. tostring(rewardDatas.lowerLimit))
		end
		if pCell.eventNode:getChildByTag(4545) then
			pCell.eventNode:getChildByTag(4545):removeFromParent()
		end
		local layout = CLayout:create(cc.size(458, 94))
		layout:setTag(4545)
		layout:setPosition(utils.getLocalCenter(pCell.eventNode))
		pCell.eventNode:addChild(layout, 10)
		for i,v in ipairs(rewardDatas.rewards) do

			local function callBack(sender)
				AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
			end
			local goodsNode = require('common.GoodNode').new({id = v.goodsId, showAmount = true, callBack = callBack, num = v.num})
			goodsNode:setPosition(cc.p(160 + (i-1)*82, 47))
			goodsNode:setScale(0.7)
			layout:addChild(goodsNode, 10)
		end
	end,__G__TRACKBACK__)
    return pCell
end
function LobbyInformationMediator:ButtonDataSource( p_convertview,idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(226, 90)

    if pCell == nil then
        pCell = LobbyInformationCell.new(cSize)
    else

    end
	xTry(function()
		display.commonLabelParams(pCell.nameLabel,{text = BTNDATA[index].name , reqW = 205 , w = 200 , hAlign = display.TAC})
		pCell.bgBtn:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
		pCell.bgBtn:setTag(index)
		if BTNDATA[index].tag == 1002 then
    		local canUpgrade = true
            local nextLevel = checkint(gameMgr:GetUserInfo().restaurantLevel)
            local levelConfigs = CommonUtils.GetConfigAllMess('levelUp', 'restaurant')
            if (nextLevel + 1) > table.nums(levelConfigs) then
                nextLevel = nextLevel
            else
                nextLevel = nextLevel + 1
            end
            local upgradeDatas = CommonUtils.GetConfigNoParser('restaurant', 'levelUp', nextLevel)
    		if checkint(gameMgr:GetUserInfo().popularity) < checkint(upgradeDatas.popularity) then
    		    canUpgrade = false
    		end
    		for i,v in ipairs(upgradeDatas.consumeGoods) do
    		    if v.goodsId == GOLD_ID then
    		        if gameMgr:GetUserInfo().gold < v.num then
    		            canUpgrade = false
    		        end
    		    else
    		        local hasNum = gameMgr:GetAmountByGoodId(v.goodsId)
    		        if hasNum < v.num then
    		            canUpgrade = false
    		        end
    		    end
    		end
    		if canUpgrade then
    			pCell.remindIcon:setVisible(true)
    		else
    			pCell.remindIcon:setVisible(false)
    		end
		else
			pCell.remindIcon:setVisible(false)
		end
	end,__G__TRACKBACK__)
    return pCell
end
function LobbyInformationMediator:RankingDataSource( p_convertview,idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(753, 50)

    if pCell == nil then
        pCell = LobbyPopularityRankingCell.new(cSize)
    else

    end
	xTry(function()
		pCell.rankNum:setString(self.popularityRank[index].rank)
		pCell.nameLabel:setString(self.popularityRank[index].playerName)
		pCell.scoreNum:setString(self.popularityRank[index].popularity)
		if self.popularityRank[index].rank >= 1 and self.popularityRank[index].rank <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/lobby/information/restaurant_info_bg_rank_num' .. tostring(self.popularityRank[index].rank) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
		end

	end,__G__TRACKBACK__)
    return pCell
end
function LobbyInformationMediator:TabButtonCallback( sender )
    PlayAudioByClickNormal()
	local tag = 0
	local viewData = self:GetViewComponent().viewData
	local gridView = viewData.gridView
	if type(sender) == 'number' then
		tag = sender
	else
		tag = sender:getTag()
		if self.selectedTab == tag then
			return
		else
			-- 添加点击音效
			gridView:cellAtIndex(self.selectedTab - 1).bgBtn:setChecked(false)
			gridView:cellAtIndex(self.selectedTab - 1).bgBtn:setEnabled(true)
			gridView:cellAtIndex(self.selectedTab - 1).nameLabel:setColor(cc.c3b(118, 85, 59))
			if self.showLayer[tostring(BTNDATA[self.selectedTab].tag)] then
				self.showLayer[tostring(BTNDATA[self.selectedTab].tag)]:setVisible(false)
			end
			self.selectedTab = tag
		end
	end
	gridView:cellAtIndex(self.selectedTab - 1).bgBtn:setChecked(true)
	gridView:cellAtIndex(self.selectedTab - 1).bgBtn:setEnabled(false)
	gridView:cellAtIndex(self.selectedTab - 1).nameLabel:setColor(cc.c3b(255, 255, 255))
	if self.showLayer[tostring(BTNDATA[self.selectedTab].tag)] then
		self.showLayer[tostring(BTNDATA[self.selectedTab].tag)]:setVisible(true)
		if BTNDATA[self.selectedTab].tag == 1001 then
			self.showLayer[tostring(BTNDATA[self.selectedTab].tag)]:RefreshUI()
		end
	else
		self:SwitchView(BTNDATA[self.selectedTab].tag)
		-- self:SwitchView(self.selectedTab)
	end
end
--[[
切换页面
@params tag int 选择的页面
--]]
function LobbyInformationMediator:SwitchView( tag )
	local viewData = self:GetViewComponent().viewData
	local function CreateView( viewName, datas )
		local view = require( 'Game.views.' .. viewName).new(datas)
	    viewData.showLayout:addChild(view, 10)
	    view:setAnchorPoint(cc.p(0,0))
		view:setPosition(cc.p(0,0))
		self.showLayer[tostring(tag)] = view
		return view
	end
	if tag == 1001 then
		local LobbyDetailedInformationView = CreateView('LobbyDetailedInformationView', {bill = self.bill, traffic = self.traffic, waiterNum = self.waiterNum, bug = self.bug})

	elseif tag == 1002 then
		local lobbyPopularityView = CreateView('LobbyPopularityView')
		local viewData = lobbyPopularityView.viewData_
		viewData.upgradeBtn:setOnClickScriptHandler(handler(self, self.PopularityViewBtnCallback))
	elseif tag == 1003 then
		local lobbyPopularityRankingView = CreateView('LobbyPopularityRankingView')
		local viewData = lobbyPopularityRankingView.viewData_
		viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.RankingDataSource))
		viewData.gridView:setCountOfCell(table.nums(self.popularityRank))
		viewData.gridView:reloadData()
		viewData.lastWeekRankBtn:setOnClickScriptHandler(handler(self, self.RankingViewBtnCallback))
		viewData.rewardBtn:setOnClickScriptHandler(handler(self, self.RankingViewBtnCallback))
		display.reloadRichLabel(viewData.timeLabel, { c = self:ChangeTimeFormat(self.popularityRankLeftSeconds)})
		if self.myPopularityRank == 0 then
			viewData.playerRankNum:setVisible(false)
			viewData.playerRankNumBg:setVisible(false)
			viewData.playerRankLabel:setVisible(true)
		else
			if self.myPopularityRank >= 1 and self.myPopularityRank <= 3 then
				viewData.playerRankNumBg:setVisible(true)
				if v then
					viewData.playerRankNumBg:setTexture(_res('ui/home/lobby/information/restaurant_info_bg_rank_num' .. tostring(v.rank) .. '.png'))
				end
			else
				viewData.playerRankNumBg:setVisible(false)
			end
			viewData.playerRankLabel:setVisible(false)
			viewData.playerRankNum:setVisible(true)
			viewData.playerRankNum:setString(tostring(self.myPopularityRank))
		end
		viewData.playerName:setString(gameMgr:GetUserInfo().playerName)
		viewData.scoreNum:setString(tostring(self.myPopularityScore))
	elseif tag == 1004 then
		print('事件详情')
	end
end
--[[
改变时间格式
@params seconds int 剩余秒数
--]]
function LobbyInformationMediator:ChangeTimeFormat( seconds )
	local c = {}
	if seconds >= 86400 then
		local num = math.floor(seconds/86400)
		table.insert(c, {text = tostring(num), fontSize = 32, color = '#e76415'})
		table.insert(c, {text = __('天'), fontSize = 32, color = '#5c5c5c'})
	else
		local hour   = math.floor(seconds / 3600)
		local minute = math.floor((seconds - hour*3600) / 60)
		local sec    = (seconds - hour*3600 - minute*60)
		table.insert(c, {text = string.format("%.2d:%.2d:%.2d", hour, minute, sec), fontSize = 32, color = '#e76415'})
	end
	return c
end
function LobbyInformationMediator:ScheduleCallback()
	if self.popularityRankLeftSeconds >= 0 then
		self.popularityRankLeftSeconds = self.popularityRankLeftSeconds - 1
		if self.showLayer['1003'] then
			display.reloadRichLabel(self.showLayer['1003'].viewData_.timeLabel, { c = self:ChangeTimeFormat(self.popularityRankLeftSeconds)})
		end
	end
end
function LobbyInformationMediator:OnRegist(  )
	local LobbyInformationCommand = require( 'Game.command.LobbyInformationCommand' )
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Restaurant_LevelUp, LobbyInformationCommand)
	self:GetFacade():DispatchObservers(FRIEND_UPDATE_LOBBY_FRIEND_BTN_STATE, {showBtn = false})
end

function LobbyInformationMediator:OnUnRegist(  )
    scheduler.unscheduleGlobal(self.scheduler)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Restaurant_LevelUp)
    local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self.viewComponent)
	self:GetFacade():DispatchObservers(FRIEND_UPDATE_LOBBY_FRIEND_BTN_STATE)
end

return LobbyInformationMediator
