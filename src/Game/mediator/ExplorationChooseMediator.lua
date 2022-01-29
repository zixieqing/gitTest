--[[
探索选择道路功能Mediator
--]]
local Mediator = mvc.Mediator

local ExplorationChooseMediator = class("ExplorationChooseMediator", Mediator)

local NAME = "ExplorationChooseMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
function ExplorationChooseMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.roomDatas = params.roomDatas -- 当前层数据
	self.floorNum = checkint(params.floorNum or 1)-- 层数
	self.exploreId = checkint(params.exploreId) -- 坐标点
	self.selectedTeam = checkint(params.teamId or 1) -- 选中的编队
	self.selectedGoods = nil -- 选中的恢复品
	self.selectedMap = nil -- 选中的地图
	self.selectedMapId = nil -- 选中的地图Id
	self.isRecovery = false -- 是否处于恢复页面
	self.vigourCost = nil -- 团队新鲜度消耗百分比
end

function ExplorationChooseMediator:InterestSignals()
	local signals = {
		HomeScene_ChangeCenterContainer_TeamFormation,
		SIGNALNAMES.Exploration_DiamondRecover_Callback,
		SIGNALNAMES.Exploration_GetRecord_Callback,
		SIGNALNAMES.Exploration_AddVigour_Callback,
		SIGNALNAMES.Exploration_ChooseExitExplore_Callback,
		"CLOSE_TEAM_FORMATION"
	}
	return signals
end

function ExplorationChooseMediator:ProcessSignal( signal )
	local name = signal:GetName()

	if name == "CLOSE_TEAM_FORMATION" then -- 编队跳转回调
		-- 关闭编队界面
		self:GetFacade():DispatchObservers(TeamFormationScene_ChangeCenterContainer)
	elseif name == HomeScene_ChangeCenterContainer_TeamFormation then
		local scene = uiMgr:GetCurrentScene()
		local explorationTeamView = scene:GetDialogByTag(2001)
		local viewData = explorationTeamView.viewData_
		local teamFormationDatas = gameMgr:GetUserInfo().teamFormation
		if table.nums(teamFormationDatas) ~= table.nums(viewData.dotDatas) then
			if viewData.dotLayout then
				viewData.dotLayout:runAction(cc.RemoveSelf:create())
			end
			local dotDatas = {}
			local dotLayout = CLayout:create(cc.size((table.nums(teamFormationDatas)*2-1)*20, 20))
			dotLayout:setPosition(cc.p(viewData.size.width/2, 320))
			viewData.view:addChild(dotLayout, 10)
			for i = 1, table.nums(teamFormationDatas) do
				local dot = display.newImageView(_res('ui/common/maps_fight_ico_round_default.png'), 10+(i-1)*40, 10)
				dotLayout:addChild(dot, 10)
				table.insert(dotDatas, i, dot)
			end
			viewData.dotDatas = dotDatas
			viewData.dotLayout = dotLayout
		end
		self:RefreshTeamSelectedState(self.selectedTeam)
		if explorationTeamView then
			explorationTeamView:setVisible(true)
		end
	elseif name == SIGNALNAMES.Exploration_DiamondRecover_Callback then -- 幻晶石恢复
		local datas = checktable(signal:GetBody())
		-- 更新卡牌活力值
		for id, value in pairs(datas.newVigour) do
			gameMgr:UpdateCardDataById(tonumber(id), {vigour = tonumber(value)})

			local cardData = gameMgr:GetCardDataById(id)
            CommonUtils.PlayCardSoundByCardId(cardData.cardId, SoundType.TYPE_ICEROOM_RANDOM, SoundChannel.CARD_FEED, false)
		end
			gameMgr:GetUserInfo().diamond = datas.diamond
			self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{diamond = datas.diamond})
		--更新UI
		self:RefreshTeamViewFormation( )
		self:RefreshTeamFormation()
	elseif name == SIGNALNAMES.Exploration_GetRecord_Callback then -- 探索记录
		local datas = checktable(signal:GetBody())
		local recordDatas = self:ConvertRecordData(datas)
		local scene = uiMgr:GetCurrentScene()
		local explorationRecordView  = require('Game.views.ExplorationRecordView').new({tag = 5001, mediatorName = "ExplorationChooseMediator", recordDatas = recordDatas, floorNum = table.nums(datas.exploreRecord) - 1})
		display.commonUIParams(explorationRecordView, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
		explorationRecordView:setTag(5001)
		scene:AddDialog(explorationRecordView)
	elseif name == SIGNALNAMES.Exploration_AddVigour_Callback then -- 使用恢复道具
		local datas = checktable(signal:GetBody())
		gameMgr:UpdateCardDataById(tonumber(datas.requestData.playerCardId), {vigour = tonumber(datas.vigour)})
		CommonUtils.DrawRewards({{goodsId = datas.requestData.goodsId, num = -datas.requestData.num}})
		--更新UI
		self:RefreshTeamViewFormation( )
		self:RefreshTeamFormation()

		local cardData = gameMgr:GetCardDataById(datas.requestData.playerCardId)
        CommonUtils.PlayCardSoundByCardId(cardData.cardId, SoundType.TYPE_ICEROOM_RANDOM, SoundChannel.CARD_FEED)

	elseif name == SIGNALNAMES.Exploration_ChooseExitExplore_Callback then -- 退出探索
		local datas = checktable(signal:GetBody())
		-- 更新本地定时器数据
		app.badgeMgr:ClearExploreAreaTimeAndRed(datas.requestData.areaFixedPointId)
		self:AddSettlementView(datas)
		if self.selectedTeam then
			gameMgr:setMutualTakeAwayToTeam( self.selectedTeam, CARDPLACE.PLACE_EXPLORATION,CARDPLACE.PLACE_TEAM)
		end
	end
end


function ExplorationChooseMediator:Initial( key )
	self.super.Initial(self,key)
    -- if isGuideOpened('explore') then
    --     local guideNode = require('common.GuideNode').new({tmodule = 'explore'})
    --     display.commonUIParams(guideNode, { po = display.center})
    --     sceneWorld:addChild(guideNode, GameSceneTag.Guide_GameSceneTag)
    -- end

	local viewComponent  = require( 'Game.views.ExplorationChooseView' ).new({roomDatas = self.roomDatas})
	viewComponent:setTag(999)
	self:SetViewComponent(viewComponent)
	local viewData = viewComponent.viewData_
	-- 更新层数
	viewData.floorNum:setString(self.floorNum)
	for _,mapCard in ipairs(viewData.mapCardDatas) do
		mapCard.cardBtn:setOnClickScriptHandler(handler(self, self.MapCardCallback))
	end
	viewData.recordBtn:setOnClickScriptHandler(handler(self, self.BottomBtnCallback))
	viewData.exploreBtn:setOnClickScriptHandler(handler(self, self.BottomBtnCallback))
	viewData.retreatBtn:setOnClickScriptHandler(handler(self, self.BottomBtnCallback))
	viewData.tipsBtn:setOnClickScriptHandler(handler(self, self.BottomBtnCallback))
	-- 是否添加底部队列
	if self.floorNum ~= 1 then
		self:RefreshTeamFormation()
	end
end
--[[
路线点击回调
--]]
function ExplorationChooseMediator:MapCardCallback( sender )
	GuideUtils.DispatchStepEvent()
	local tag = sender:getTag()
	local userTag = sender:getUserTag()
	local viewData =  self:GetViewComponent().viewData_
	if self.selectedMap == tag then
		if self.floorNum == 1 then
			return
		else
			viewData.mapCardDatas[tag].selectFrame:setVisible(false)
			viewData.mapCardDatas[tag]:runAction(cc.EaseBackOut:create(cc.ScaleTo:create(0.2, 1)))
			viewData.tipsBtn:setVisible(false)
			self.selectedMap = nil
			self.selectedMapId = nil
			self.vigourCost = nil
			return
		end
	end
	-- 添加点击音效
	PlayAudioByClickNormal()
	-- 消耗新鲜度
	self.vigourCost = tonumber(self.roomDatas[tag].consumeVigour)
	-- 是否选择编队
	if self.floorNum == 1 then
		-- 放大选中地图
		viewData.mapCardDatas[tag].selectFrame:setVisible(true)
		viewData.mapCardDatas[tag]:runAction(cc.EaseBackOut:create(cc.ScaleTo:create(0.2, 1.1)))
		-- 添加选中框
		self.selectedMap = tag
		self.selectedMapId = userTag
		self:ChooseTeam()
	else
		if self.selectedMap then
			viewData.mapCardDatas[self.selectedMap].selectFrame:setVisible(false)
			viewData.mapCardDatas[self.selectedMap]:runAction(cc.EaseBackOut:create(cc.ScaleTo:create(0.2, 1)))
		end
		viewData.tipsBtn:setVisible(true)
		viewData.mapCardDatas[tag].selectFrame:setVisible(true)
		viewData.mapCardDatas[tag]:runAction(cc.EaseBackOut:create(cc.ScaleTo:create(0.2, 1.1)))
		self.selectedMap = tag
		self.selectedMapId = userTag
	end
end
--[[
按钮回调
--]]
function ExplorationChooseMediator:BottomBtnCallback( sender )
	-- 添加点击音效
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == 1011 then -- 记录
		self:SendSignal(COMMANDS.COMMAND_Exploration_GetRecord, {areaFixedPointId = self.exploreId})
	elseif tag == 1012 then -- 探索
		-- 判断是否选中地图
		if self.selectedMap then
			-- 判断新鲜度是否足够
			if app.restaurantMgr:HasEnoughVigourToExplore(self.selectedTeam, self.vigourCost) then
				-------------屏蔽按钮点击事件------------
				local viewData = self:GetViewComponent().viewData_
				for i,v in ipairs(viewData.mapCardDatas) do
					v.cardBtn:setEnabled(false)
				end
				sender:setEnabled(false)
				sender:runAction(
					cc.Sequence:create(
						cc.DelayTime:create(3),
						cc.CallFunc:create(function ()
							sender:setEnabled(true)
							for i,v in ipairs(viewData.mapCardDatas) do
								v.cardBtn:setEnabled(true)
							end
						end)
					)
				)
				---------------------------------------
				local scene = uiMgr:GetCurrentScene()
				scene:RemoveDialogByTag(2001)
				local explorationMediator = AppFacade.GetInstance():RetrieveMediator('ExplorationMediator')
				explorationMediator:SendSignal(COMMANDS.COMMAND_Exploration_Continue, {areaFixedPointId = self.exploreId, roomId = self.selectedMapId})
			else
				self:AddVigourRecoveryView()
			end
		else
			uiMgr:ShowInformationTips(__('没有选择路线'))
		end
	elseif tag == 1013 then -- 撤退
		local scene = uiMgr:GetCurrentScene()
		local CommonTip  = require( 'common.NewCommonTip' ).new({
				text = __('确定要退出探索吗？'), isOnlyOK = false, callback = function ()
				self:SendSignal(COMMANDS.COMMAND_Exploration_ChooseExitExplore, {areaFixedPointId = self.exploreId})
			end})
		CommonTip:setPosition(display.center)
		scene:AddDialog(CommonTip)
		
	elseif tag == 1014 then -- 提示
		local scene = uiMgr:GetCurrentScene()
		local pos = cc.p(sender:getPositionX(), sender:getPositionY() + 50)
		local tipsView = require("home.ExplorationVigourTipsView").new({teamId = self.selectedTeam, teamVigourCost = self.vigourCost, pos = pos})
		scene:AddDialog(tipsView)
	end
end
--[[
选择编队
--]]
function ExplorationChooseMediator:ChooseTeam()
	local scene = uiMgr:GetCurrentScene()
	local explorationTeamView  = require('Game.views.ExplorationTeamView').new({tag = 2001, mediatorName = "ExplorationChooseMediator"})
	display.commonUIParams(explorationTeamView, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	explorationTeamView:setTag(2001)
	scene:AddDialog(explorationTeamView)
	local viewData = explorationTeamView.viewData_
	viewData.switchBtnL:setOnClickScriptHandler(handler(self, self.TeamViewBtnCallback))
	viewData.switchBtnR:setOnClickScriptHandler(handler(self, self.TeamViewBtnCallback))
	viewData.changeBtn:setOnClickScriptHandler(handler(self, self.TeamViewBtnCallback))
	viewData.tipsBtn:setOnClickScriptHandler(handler(self, self.TeamViewBtnCallback))
	viewData.explorationBtn:setOnClickScriptHandler(handler(self, self.TeamViewBtnCallback))
	viewData.quickRecoveryBtn:setOnClickScriptHandler(handler(self, self.RecoveryCallback))
	self:RefreshDiamondCost()
	local canClick = true
	explorationTeamView.eaterLayer:setOnClickScriptHandler(function( sender )
		if canClick then
			canClick = false
			if self.isRecovery then
				self.isRecovery = false
			end
			-- 添加点击音效
			PlayAudioByClickClose()
			local viewData = self:GetViewComponent().viewData_
			local view = explorationTeamView.viewData_.view
			viewData.mapCardDatas[self.selectedMap].selectFrame:setVisible(false)
			viewData.mapCardDatas[self.selectedMap]:runAction(cc.EaseBackOut:create(cc.ScaleTo:create(0.2, 1)))
			self.selectedMap = nil
			scene:GetDialogByTag(2001):runAction(
				cc.Sequence:create(
					cc.TargetedAction:create(view, cc.EaseBackIn:create(cc.MoveTo:create(0.3, cc.p(display.cx, 0)))),
					cc.RemoveSelf:create()
				)
			)
		end
	end)
	-- 动作
	self:RefreshTeamSelectedState(self.selectedTeam)
	viewData.view:setPosition(cc.p(display.cx, 0))
	viewData.view:runAction(cc.EaseBackOut:create(cc.MoveTo:create(0.3, cc.p(display.cx, 300))))
end
--[[
刷新选中状态
--]]
function ExplorationChooseMediator:RefreshTeamSelectedState( index )
	local scene = uiMgr:GetCurrentScene()
	local explorationTeamView = scene:GetDialogByTag(2001)
	local viewData = explorationTeamView.viewData_
	-- 刷新选中状态
	local preCircle = viewData.dotDatas[self.selectedTeam]
	if preCircle then
		preCircle:setTexture(_res('ui/common/maps_fight_ico_round_default.png'))
	end
	local curCircle = viewData.dotDatas[index]
	if curCircle then
		curCircle:setTexture(_res('ui/common/maps_fight_ico_round_select.png'))
	end

	if table.nums(gameMgr:GetUserInfo().teamFormation) <= 1 then
		viewData.switchBtnL:setVisible(false)
		viewData.switchBtnR:setVisible(false)
	elseif index == 1 then
		viewData.switchBtnL:setVisible(false)
		viewData.switchBtnR:setVisible(true)
	elseif index == table.nums(gameMgr:GetUserInfo().teamFormation) then
		viewData.switchBtnL:setVisible(true)
		viewData.switchBtnR:setVisible(false)
	else
		viewData.switchBtnL:setVisible(true)
		viewData.switchBtnR:setVisible(true)
	end
	self.selectedTeam = index
	-- 刷新队伍信息
	viewData.teamNameLabel:setString(string.format(__('队伍%d'), self.selectedTeam))
	self:RefreshTeamViewFormation()
end
--[[
刷新弹出界面编队信息
--]]
function ExplorationChooseMediator:RefreshTeamViewFormation( )
	local scene = uiMgr:GetCurrentScene()
	local explorationTeamView = scene:GetDialogByTag(2001)
	local view = explorationTeamView.viewData_.view
	local teamDatas = gameMgr:GetUserInfo().teamFormation[self.selectedTeam]
	for i = 2151, 2155 do
		if view:getChildByTag(i) then
			view:getChildByTag(i):runAction(cc.RemoveSelf:create())
		end
	end
	--添加头像
	local totalBattlePoint = 0
	for i,card in ipairs(teamDatas.cards) do
		if card.id then
			local isShowActionState = false
			if self.floorNum == 1 then
				isShowActionState = true
			end
			local cardHeadNode = require('common.CardHeadNode').new({id = checkint(card.id),
        	    showActionState = isShowActionState})
			cardHeadNode:setPosition(cc.p(display.cx-330+(i-1)*165, 410))
			cardHeadNode:setScale(0.75)
			cardHeadNode:setTag(2150 + i)
			view:addChild(cardHeadNode, 10)
			-- 计算战斗力
			totalBattlePoint = totalBattlePoint + cardMgr.GetCardStaticBattlePointById(checkint(card.id))
		else
			local cardHeadBg = display.newImageView(_res('ui/common/kapai_frame_bg_nocard.png'), display.cx-330+(i-1)*165, 410)
			cardHeadBg:setTag(2150 + i)
			cardHeadBg:setScale(0.75)
			view:addChild(cardHeadBg, 10)
			local cardHeadFrame = display.newImageView(_res('ui/common/kapai_frame_nocard.png'), cardHeadBg:getContentSize().width/2, cardHeadBg:getContentSize().height/2)
			cardHeadBg:addChild(cardHeadFrame)
		end
	end
	-- 刷新战斗力
	explorationTeamView.viewData_.battlePoint:setString(totalBattlePoint)
	-- 更新顶部tips
	self:UpdateTeamViewTopTips()
	-- 刷新新鲜度
	if self.isRecovery then
		self:RefreshCardVigour()
		self:RefreshDiamondCost()
	end
end
--[[
编队页面按钮回调
--]]
function ExplorationChooseMediator:TeamViewBtnCallback( sender )
	-- 添加点击音效
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == 1101 then -- 调整队伍
		local scene = uiMgr:GetCurrentScene()
		local explorationTeamView = scene:GetDialogByTag(2001)
		explorationTeamView:setVisible(false)
		local TeamFormationMediator = require( 'Game.mediator.TeamFormationMediator')
		local mediator = TeamFormationMediator.new({isCommon = true,jumpTeamIndex = self.selectedTeam})
		self:GetFacade():RegistMediator(mediator)
	elseif tag == 1102 then -- 探索
		-- 判断新鲜度是否足够
		local teamFormationData = gameMgr:GetUserInfo().teamFormation[self.selectedTeam]
		local teamCards = 0 -- 队伍卡牌数目

		for i,card in ipairs(teamFormationData.cards) do
			if card.id then
				teamCards = teamCards + 1
				local cardData = gameMgr:GetCardDataById(card.id)
				if self.floorNum  == 1 then -- 只有当层数为1的时候才会进行编队互斥判断
					------------ 互斥判断 ------------
					local ifMutex, placeId = gameMgr:CanSwitchCardStatus(
						{id = card.id},
						CARDPLACE.PLACE_EXPLORATION
					)
					if false == ifMutex and placeId then
						-- 互斥
						local placeName = gameMgr:GetModuleName(placeId)
						uiMgr:ShowInformationTips(string.format(__('您的队伍正在%s, 不能出战'), tostring(placeName)))
						return
					end
					------------ 互斥判断 ------------
				end
			end
		end
		if teamCards == 0 then
			uiMgr:ShowInformationTips(__('队伍不能为空'))
			return
		end
		if app.restaurantMgr:HasEnoughVigourToExplore(self.selectedTeam, self.vigourCost) then
			-------------屏蔽按钮点击事件------------
			local viewData = self:GetViewComponent().viewData_
			for i,v in ipairs(viewData.mapCardDatas) do
				v.cardBtn:setEnabled(false)
			end
			sender:setEnabled(false)
			sender:runAction(
				cc.Sequence:create(
					cc.DelayTime:create(3),
					cc.CallFunc:create(function ()
						sender:setEnabled(true)
						for i,v in ipairs(viewData.mapCardDatas) do
							v.cardBtn:setEnabled(true)
						end
					end)
				)
			)
			---------------------------------------
			local scene = uiMgr:GetCurrentScene()
			scene:RemoveDialogByTag(2001)
			if self.floorNum == 1 then
				local explorationMediator = AppFacade.GetInstance():RetrieveMediator('ExplorationMediator')
				explorationMediator:SendSignal(COMMANDS.COMMAND_Exploration_Explore, {areaFixedPointId = self.exploreId, explorePointId = self.roomDatas[self.selectedMap].explorePointId, teamId = self.selectedTeam})
			else
				local explorationMediator = AppFacade.GetInstance():RetrieveMediator('ExplorationMediator')
				explorationMediator:SendSignal(COMMANDS.COMMAND_Exploration_Continue, {areaFixedPointId = self.exploreId, roomId = self.selectedMapId})
			end
		else
			if self.isRecovery then
				uiMgr:ShowInformationTips(__('队伍新鲜度不足'))
			else
				self:AddVigourRecoveryView()
			end
		end

	elseif tag == 1103 then -- 上翻
		self:RefreshTeamSelectedState(math.max(1, self.selectedTeam - 1))
	elseif tag == 1104 then -- 下翻
		self:RefreshTeamSelectedState(math.min(table.nums(gameMgr:GetUserInfo().teamFormation), self.selectedTeam + 1))
	elseif tag == 1105 then -- 提示
		local scene = uiMgr:GetCurrentScene()
		local explorationTeamView = scene:GetDialogByTag(2001)
		local worldPos = explorationTeamView.viewData_.view:convertToWorldSpace(cc.p(sender:getPositionX(), sender:getPositionY()))
		local pos = cc.p(worldPos.x, worldPos.y + 30)
		local tipsView = require("home.ExplorationVigourTipsView").new({teamId = self.selectedTeam, teamVigourCost = self.vigourCost, pos = pos})
		scene:AddDialog(tipsView)
	end
end
--[[
活力值恢复界面
--]]
function ExplorationChooseMediator:AddVigourRecoveryView()
	local scene = uiMgr:GetCurrentScene()
	if scene:GetDialogByTag(2001) then -- 由编队页面
		local explorationTeamView = scene:GetDialogByTag(2001)
		self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    	self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    	self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    	self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
		cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, explorationTeamView)
		self:RefreshCardVigour()
		explorationTeamView.viewData_.bottomLayout:setVisible(true)
		explorationTeamView.viewData_.view:runAction(cc.MoveTo:create(0.2, cc.p(display.cx, 600)))
		explorationTeamView.viewData_.dotLayout:runAction(cc.MoveTo:create(0.2, cc.p(display.cx, 290)))
		self.isRecovery = true
		self:RefreshDiamondCost()
	else -- 添加活力值恢复界面
		local explorationTeamView  = require('Game.views.ExplorationTeamView').new({tag = 2001, mediatorName = "MarketPurchaseMediator"})
		display.commonUIParams(explorationTeamView, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
		explorationTeamView:setTag(2001)
		scene:AddDialog(explorationTeamView)
		self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    	self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    	self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    	self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
		cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, explorationTeamView)
		local viewData = explorationTeamView.viewData_
		self.isRecovery = true
		viewData.switchBtnL:setVisible(false)
		viewData.switchBtnR:setVisible(false)
		viewData.changeBtn:setVisible(false)
		viewData.bottomLayout:setVisible(true)
		viewData.dotLayout:setVisible(false)
		self:RefreshDiamondCost()
		viewData.explorationBtn:setOnClickScriptHandler(handler(self, self.TeamViewBtnCallback))
		viewData.tipsBtn:setOnClickScriptHandler(handler(self, self.TeamViewBtnCallback))
		viewData.quickRecoveryBtn:setOnClickScriptHandler(handler(self, self.RecoveryCallback))
		local canClick = true
		explorationTeamView.eaterLayer:setOnClickScriptHandler(function( sender )
			if canClick then
				canClick = false
				if self.isRecovery then
					self.isRecovery = false
				end
				self:RefreshTeamFormation() -- 刷新编队界面
				-- 添加点击音效
				PlayAudioByClickClose()
				local viewData = self:GetViewComponent().viewData_
				local view = explorationTeamView.viewData_.view
				scene:GetDialogByTag(2001):runAction(
					cc.Sequence:create(
						cc.TargetedAction:create(view, cc.EaseBackIn:create(cc.MoveTo:create(0.3, cc.p(display.cx, 0)))),
						cc.RemoveSelf:create()
					)
				)
			end
		end)
		-- 动作
		self:RefreshTeamViewFormation()
		viewData.view:setPosition(cc.p(display.cx, 0))
		viewData.view:runAction(cc.EaseBackOut:create(cc.MoveTo:create(0.5, cc.p(display.cx, 600))))
	end
end
--[[
活力值幻晶石恢复
--]]
function ExplorationChooseMediator:RecoveryCallback( sender )
	-- 添加点击音效
	PlayAudioByClickNormal()
	local scene = uiMgr:GetCurrentScene()
	local diamondCost = CommonUtils.GetTeamDiamondRecoverVigourCost(self.selectedTeam)
	if diamondCost == 0 then
		uiMgr:ShowInformationTips(__('新鲜度已满'))
	else
 		if gameMgr:GetUserInfo().diamond >= diamondCost then
			local strs = string.split(string.fmt(__('是否消耗|_num_|幻晶石恢复当前编队飨灵新鲜度？'),{['_num_'] = diamondCost}), '|')
 			local CommonTip  = require( 'common.NewCommonTip' ).new({richtext = {
 				{text = strs[1], fontSize = 22, color = '#4c4c4c'},
 				{text = strs[2], fontSize = 24, color = '#da3c3c'},
 				-- {img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID), scale = 0.2},
 				{text = strs[3], fontSize = 22, color = '#4c4c4c'}},
 				isOnlyOK = false, callback = function ()
    		print('确定')
 			local teamFormationData = gameMgr:GetUserInfo().teamFormation[self.selectedTeam]
 			local cardstr = nil
 			for i,v in ipairs(teamFormationData.cards) do
 				if v.id then
 					if cardstr then
 						cardstr = string.format('%s,%s', cardstr, tostring(v.id))
 					else
 						cardstr = tostring(v.id)
 					end
 				end
 			end
    		self:SendSignal(COMMANDS.COMMAND_Exploration_DiamondRecover, {playerCardId = cardstr})
			end,
			cancelBack = function ()
			print('返回')
			end})
			CommonTip:setPosition(display.center)
			scene:AddDialog(CommonTip)
 		else
			if GAME_MODULE_OPEN.NEW_STORE then
				app.uiMgr:showDiamonTips()
			else
				local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('幻晶石不足是否去商城购买？'),
					isOnlyOK = false, callback = function ()
						app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
					end})
				CommonTip:setPosition(display.center)
				app.uiMgr:GetCurrentScene():AddDialog(CommonTip)
			end
 		end
	end

end

--[[
刷新卡牌新鲜度
--]]
function ExplorationChooseMediator:RefreshCardVigour()
	local teamFormationData = gameMgr:GetUserInfo().teamFormation[self.selectedTeam]
	local scene = uiMgr:GetCurrentScene()
	local viewData = scene:GetDialogByTag(2001).viewData_
	local view = viewData.view
	local bottomLayout = viewData.bottomLayout
	for i,v in ipairs(VIGOUR_RECOVERY_GOODS_ID) do
		local numLabel = bottomLayout:getChildByTag(2700+i)
		local goodsNum = gameMgr:GetAmountByGoodId(v)
		numLabel:setString(tostring(goodsNum))
	end
	for i = 2161, 2165 do
		if view:getChildByTag(i) then
			view:getChildByTag(i):runAction(cc.RemoveSelf:create())
		end
	end
	for i,card in ipairs(teamFormationData.cards) do
		if card.id and checkint(card.id) ~= 0 then
			local cardData = gameMgr:GetCardDataById(card.id)
    		local vigourView = CLayout:create(cc.size(156, 80))
    		vigourView:setTag(2160+i)
    		display.commonUIParams(vigourView, { po = cc.p(display.cx-330+(i-1)*165, 347)})
    		view:addChild(vigourView, 10)
    		local progressBG = display.newImageView(_res('avatar/ui/recovery_bg.png'), vigourView:getContentSize().width/2, 15, {
    		        scale9 = true, size = cc.size(156, 28)
    		    })
    		vigourView:addChild(progressBG, 2)
            local maxVigour = app.restaurantMgr:getCardVigourLimit(card.id)
            local ratio = (checkint(cardData.vigour) / maxVigour)* 100
    		local color = nil
    		if ratio >=0 and ratio <= 29 then
    			color = 'red'
    		elseif ratio >=30 and ratio <= 60 then
    			color = 'yellow'
    		elseif ratio >=60 then
    			color = 'green'
    		else
    			color = 'green'
    		end
    		local operaProgressBar = CProgressBar:create(_res('ui/home/teamformation/newCell/team_img_leaf_' .. color .. '.png'))
    		operaProgressBar:setBackgroundImage(_res('ui/home/teamformation/newCell/team_img_leaf_grey.png'))
    		operaProgressBar:setDirection(eProgressBarDirectionLeftToRight)
    		operaProgressBar:setAnchorPoint(cc.p(0, 0.5))
    		operaProgressBar:setMaxValue(100)
    		operaProgressBar:setValue(ratio)
    		operaProgressBar:setPosition(cc.p(6, 15))
    		vigourView:addChild(operaProgressBar, 5)
    		local vigourProgressBarTop =  display.newImageView(_res('ui/home/teamformation/newCell/team_img_leaf_free.png'),0,0,{as = false})
    		vigourProgressBarTop:setAnchorPoint(cc.p(0,0.5))
    		vigourProgressBarTop:setPosition(cc.p(2, 15))
    		vigourView:addChild(vigourProgressBarTop,6)

    		local vigourLabel = display.newLabel(operaProgressBar:getContentSize().width + 22, operaProgressBar:getPositionY()+1,{
    		    ap = cc.p(0.5, 0.5), fontSize = 18, color = 'ffffff', text = tostring(cardData.vigour)
    		})
    		vigourView:addChild(vigourLabel, 6)
    		-- 新鲜度消耗
    		local vigourCostBg = display.newImageView(_res('ui/home/exploration/discovery_bg_cost_fresh_point.png'), vigourView:getContentSize().width/2, 50)
    		vigourView:addChild(vigourCostBg, 10)
    		-- 判断消耗的点数
    		local cardNums = CommonUtils.GetTeamCardNums(self.selectedTeam)
    		local vigourCostPercent = self.vigourCost/cardNums
    		local MaxVigour = app.restaurantMgr:GetMaxCardVigourById(card.id)
    		local cardVigourCost = math.round(vigourCostPercent*MaxVigour)
    		local vigourCostLabel = display.newLabel(vigourView:getContentSize().width/2, 50, fontWithColor(5, {text = string.fmt(__('消耗_num_点'), {['_num_'] = cardVigourCost})}))
			vigourView:addChild(vigourCostLabel, 10)
		end
	end
end
--[[
刷新编队信息
--]]
function ExplorationChooseMediator:RefreshTeamFormation()
	local viewData = self:GetViewComponent().viewData_
	viewData.bottomLayout:setVisible(true)
	if viewData.bottomLayout:getChildByTag(5555) then
		viewData.bottomLayout:getChildByTag(5555):runAction(cc.RemoveSelf:create())
	end
 	local data = gameMgr:GetUserInfo().teamFormation[self.selectedTeam]
	local layout = CLayout:create(cc.size(600, 100))
	layout:setTag(5555)
	viewData.bottomLayout:addChild(layout, 10)
	layout:setPosition(cc.p(viewData.bottomLayout:getContentSize().width/2, 80))
	for i,card in ipairs(data.cards) do
		if card.id then
			local cardHeadNode = require('common.CardHeadNode').new({id = checkint(card.id),
        	    showActionState = false, })
			cardHeadNode:setScale(0.55)
			cardHeadNode:setPosition(cc.p(80+(i-1)*110, 50))
			layout:addChild(cardHeadNode, 10)
		else
			local cardHeadBg = display.newImageView(_res('ui/common/kapai_frame_bg_nocard.png'), 80+(i-1)*110, 50)
			cardHeadBg:setScale(0.55)
			layout:addChild(cardHeadBg, 10)
			local cardHeadFrame = display.newImageView(_res('ui/common/kapai_frame_nocard.png'), cardHeadBg:getContentSize().width/2, cardHeadBg:getContentSize().height/2)
			cardHeadBg:addChild(cardHeadFrame)
		end
	end
end
--[[
转换探索记录数据结构
@params record 探索记录
@return result table 转换后的数据结构
--]]
function ExplorationChooseMediator:ConvertRecordData( rewards )
	local result = {
		baseReward = {},
		chestReward = {},
		boss = {},
		goodsReward = {}
	}
	for k, v in pairs(rewards.exploreRecord) do
		-- if checkint(k) ~= self.floorNum then
			-- 获得道具
			if v.floorReward.baseReward then
				for _, base in ipairs(v.floorReward.baseReward) do
					if next(result.goodsReward) ~= nil then
						local isFind = false
						for i, reward in ipairs(result.goodsReward) do
							if reward.goodsId == checkint(base.goodsId) then
								reward.num = reward.num + checkint(base.num)
								isFind = true
								break
							end
							-- if i == #result.goodsReward then
							-- 	table.insert(result.goodsReward, {goodsId = checkint(base.goodsId), num = checkint(base.num)})
							-- end
						end
						if not isFind then
							if checkint(base.num) ~= 0 then
								table.insert(result.goodsReward, {goodsId = checkint(base.goodsId), num = checkint(base.num)})
							end
						end
					else
						if checkint(base.num) > 0 then
							table.insert(result.goodsReward, {goodsId = checkint(base.goodsId), num = checkint(base.num)})
						end
					end
				end
			end
			if v.floorReward.chestReward then
				for _, chestReward in pairs(v.floorReward.chestReward) do
					if chestReward.chest then
						for _, reward in ipairs(chestReward.chest) do
							local temp = CommonUtils.GetConfig('goods', 'money', reward.goodsId)
							if temp then -- 货币
								if next(result.baseReward) ~= nil then
									local isFind = false
									for i, baseDatas in ipairs(result.baseReward) do
										if baseDatas.goodsId == checkint(reward.goodsId) then
											baseDatas.num = baseDatas.num + checkint(reward.num)
											isFind = true
											break
										end
										-- if i == #result.baseReward then
										-- 	table.insert(result.goodsReward, {goodsId = checkint(reward.goodsId), num = checkint(reward.num)})
										-- end
									end
									if not isFind then
										table.insert(result.baseReward, {goodsId = checkint(reward.goodsId), num = checkint(reward.num)})
									end
								else
									table.insert(result.baseReward, {goodsId = checkint(reward.goodsId), num = checkint(reward.num)})
								end
							else -- 道具
								if next(result.goodsReward) ~= nil then
									local isFind = false
									for i, goodsDatas in ipairs(result.goodsReward) do
										if goodsDatas.goodsId == checkint(reward.goodsId) then
											goodsDatas.num = goodsDatas.num + checkint(reward.num)
											isFind = true
											break
										end
										-- if i == #result.goodsReward then
										-- 	print(checkint(reward.goodsId), checkint(reward.num))
										-- 	table.insert(result.goodsReward, {goodsId = checkint(reward.goodsId), num = checkint(reward.num)})
										-- end
									end
									if not isFind then
										table.insert(result.goodsReward, {goodsId = checkint(reward.goodsId), num = checkint(reward.num)})
									end
								else
									table.insert(result.goodsReward, {goodsId = checkint(reward.goodsId), num = checkint(reward.num)})
								end
							end
						end

					end
				end
			end
			-- 获得宝箱
			if v.floorReward.chestReward then
				for _, chestReward in pairs(v.floorReward.chestReward) do
					if next(result.chestReward) ~= nil then
						local isFind = false
						for i, reward in ipairs(result.chestReward) do
							if reward.goodsId == checkint(chestReward.reward.goodsId) then
								reward.num = reward.num + checkint(chestReward.reward.num)
								isFind = true
								break
							end
							-- if i == #result.chestReward then
							-- 	table.insert(result.chestReward, {goodsId = checkint(chestReward.reward.goodsId), num = checkint(chestReward.reward.num)})
							-- end
						end
						if not isFind then
							table.insert(result.chestReward, {goodsId = checkint(chestReward.reward.goodsId), num = checkint(chestReward.reward.num)})
						end
					else
						table.insert(result.chestReward, {goodsId = checkint(chestReward.reward.goodsId), num = checkint(chestReward.reward.num)})
					end
				end
			end
			-- boss信息
			if v.boss then
				for id, bossNum in pairs(v.boss) do
					if next(result.boss) ~= nil then
						local isFind = false
						for i, reward in ipairs(result.boss) do
							if reward.bossId == checkint(id) then
								reward.num = reward.num + checkint(bossNum)
								isFind = true
								break
							end
							-- if i == #result.boss then
							-- 	table.insert(result.boss, {bossId = checkint(id), num = checkint(bossNum)})
							-- end
						end
						if not isFind then
							table.insert(result.boss, {bossId = checkint(id), num = checkint(bossNum)})
						end
					else
						table.insert(result.boss, {bossId = checkint(id), num = checkint(bossNum)})
					end
				end
			end
		end
	-- end
	-- 排序
	table.sort(result.goodsReward,function(a,b)
		local qualityA = checkint(CommonUtils.GetConfig('goods', 'goods', a.goodsId).quality)
		local qualityB = checkint(CommonUtils.GetConfig('goods', 'goods', b.goodsId).quality)
		return checkint(qualityA) > checkint(qualityB)
	end)
	return result
end
--[[
扣除活力值
--]]
function ExplorationChooseMediator:DeductVigour()
	app.restaurantMgr:DeductExploreVigour(self.selectedTeam, self.vigourCost)
end
--[[
添加结算页面
--]]
function ExplorationChooseMediator:AddSettlementView( rewards )
	local layer = require('Game.views.ExplorationSettlementView').new({rewards = rewards, teamId = self.selectedTeam, areaFixedPointId = self.exploreId})
	layer:setTag(7000)
	local scene = uiMgr:GetCurrentScene()
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	scene:AddDialog(layer)
	layer.viewData_.closeBtn:setOnClickScriptHandler(function ()
		-- 添加点击音效
		PlayAudioByClickNormal()
		scene:RemoveDialogByTag(7000)
		local explorationMediator = AppFacade.GetInstance():RetrieveMediator('ExplorationMediator')
		explorationMediator:SendSignal(COMMANDS.COMMAND_Exploration_Home)
	end)
end
function ExplorationChooseMediator:onTouchBegan_(touch, event)
	local point = touch:getLocation()
	local scene = uiMgr:GetCurrentScene()
	local explorationTeamView = scene:GetDialogByTag(2001)
	local goodsDatas = explorationTeamView.viewData_.goodsDatas
	for i,icon in pairs(goodsDatas) do
		if cc.rectContainsPoint(icon:getBoundingBox(), point) then
			self.selectedGoods = i
			if gameMgr:GetAmountByGoodId(VIGOUR_RECOVERY_GOODS_ID[i]) > 0 then
				return true
			else
				return false
			end
		end
	end
end
function ExplorationChooseMediator:onTouchMoved_(touch, event)
	local scene = uiMgr:GetCurrentScene()
	local explorationTeamView = scene:GetDialogByTag(2001)
	local view = explorationTeamView.viewData_.view
	if view:getChildByTag(2222) then
		view:getChildByTag(2222):setPosition(touch:getLocation())
	else
		local icon = display.newImageView(_res('arts/goods/goods_icon_' .. tostring(VIGOUR_RECOVERY_GOODS_ID[self.selectedGoods]) .. '.png'), touch:getLocation().x, touch:getLocation().y, {tag = 2222})
		view:addChild(icon, 15)
	end
end
function ExplorationChooseMediator:onTouchEnded_(touch, event)
	local scene = uiMgr:GetCurrentScene()
	local explorationTeamView = scene:GetDialogByTag(2001)
	local view = explorationTeamView.viewData_.view

	local point = touch:getLocation()
	for i = 2150, 2155 do
		if view:getChildByTag(i) then
			if cc.rectContainsPoint(view:getChildByTag(i):getBoundingBox(), point) then
				local cardId = gameMgr:GetUserInfo().teamFormation[self.selectedTeam].cards[i- 2150].id
				if cardId and cardId ~= '' then
					local cardData = gameMgr:GetCardDataById(cardId)
                    local maxVigour = app.restaurantMgr:getCardVigourLimit(cardData.id)
					if checkint(cardData.vigour) >= checkint(maxVigour) then
						uiMgr:ShowInformationTips(__("此飨灵活力值已满"))
					else
						httpManager:Post("backpack/cardVigourMagicFoodRecover",SIGNALNAMES.Exploration_AddVigour_Callback,{ playerCardId = cardId, goodsId = VIGOUR_RECOVERY_GOODS_ID[self.selectedGoods],num = 1})
					end
				end
			end
		end
	end

	if view:getChildByTag(2222) then
		view:getChildByTag(2222):runAction(cc.RemoveSelf:create())
	end
	self.selectedGoods = nil
end
function ExplorationChooseMediator:GetVigourCost()
	return self.vigourCost or 0
end
--[[
获取编队页面顶部tips
--]]
function ExplorationChooseMediator:GetTeamViewTopTips()
    local cardNums = CommonUtils.GetTeamCardNums(self.selectedTeam)
    local descr = ''
    if cardNums ~= 0 then
    	descr = string.fmt(__('队伍中现有_num2_个飨灵，每个飨灵消耗_num3_%的新鲜度'), {['_num2_'] = tostring(cardNums), ['_num3_'] = tonumber(string.format('%.2f', tonumber(self.vigourCost)/cardNums*100))})
   	else
   		descr = __('队伍为空')
   	end
    return descr
end
--[[
更新编队页面顶部tips
--]]
function ExplorationChooseMediator:UpdateTeamViewTopTips()
	local scene = uiMgr:GetCurrentScene()
	local explorationTeamView = scene:GetDialogByTag(2001)
	if explorationTeamView then
		explorationTeamView.viewData_.topTipsLabel:setString(self:GetTeamViewTopTips())
	end
end
function ExplorationChooseMediator:OnRegist(  )

	local ExplorationChooseCommand = require('Game.command.ExplorationChooseCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Exploration_DiamondRecover, ExplorationChooseCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Exploration_GetRecord, ExplorationChooseCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Exploration_ChooseExitExplore, ExplorationChooseCommand)
end
--[[
更新恢复新鲜度幻晶石消耗
--]]
function ExplorationChooseMediator:RefreshDiamondCost(  )
	local scene = uiMgr:GetCurrentScene()
	local explorationTeamView = scene:GetDialogByTag(2001)
	if explorationTeamView then
		local diamondCost = CommonUtils.GetTeamDiamondRecoverVigourCost(self.selectedTeam)
		explorationTeamView.viewData_.diamondNum:setString(tostring(diamondCost))
	end
end
function ExplorationChooseMediator:AutoHiddenState(  )
	return false
end
function ExplorationChooseMediator:OnUnRegist(  )
	print( "OnUnRegist" )
	if self.touchListener_ then
		local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
		eventDispatcher:removeEventListener(self.touchListener_)
	end
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Exploration_DiamondRecover)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Exploration_GetRecord)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Exploration_ChooseExitExplore)

end
return ExplorationChooseMediator
