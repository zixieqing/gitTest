--[[
探索功能Mediator
--]]
local Mediator = mvc.Mediator

local ExplorationMediator = class("ExplorationMediator", Mediator)

local NAME = "ExplorationMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
function ExplorationMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.exploreId = checkint(params.id or 1)-- 探索点Id
end

function ExplorationMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Exploration_Enter_Callback,
		SIGNALNAMES.Exploration_Home_Callback,
		SIGNALNAMES.Exploration_Explore_Callback,
		SIGNALNAMES.Exploration_EnterNextFloor_Callback,
		SIGNALNAMES.Exploration_Continue_Callback,
		SIGNALNAMES.CACHE_MONEY_UPDATE_UI
	}
	return signals
end

function ExplorationMediator:ProcessSignal( signal )
	local name = signal:GetName()
	-- print(name)
	if name == SIGNALNAMES.Exploration_Home_Callback then
        GuideUtils.DispatchStepEvent()
		local datas = checktable(signal:GetBody())
		-- 更新本地定时器时间
		for k,v in pairs(datas) do
			app.badgeMgr:AddSetExploreTimeInfoRed(k, v.currentFloorInfo.needTime)
		end

		for k,v in pairs(datas) do
			if self.exploreId == tonumber(k) then
				-- 已探索
				if v.currentFloorInfo.roomId then
					-- 探索
					v.currentFloorInfo.isBossQuest = v.currentFloorInfo.floorRooms[tostring(v.currentFloorInfo.roomId)].isBossQuest
					if v.currentFloorInfo.isBossQuest then
						v.currentFloorInfo.bossQuestId = v.currentFloorInfo.floorRooms[tostring(v.currentFloorInfo.roomId)].bossQuestId
						v.currentFloorInfo.bossId = v.currentFloorInfo.floorRooms[tostring(v.currentFloorInfo.roomId)].bossId
					end
					self:EnterExploreView(v)
				else
					-- 选择
					local roomDatas = {}
					local floorDatas = CommonUtils.GetConfigAllMess('exploreFloor', 'explore')
					for explorePointId,roomData in orderedPairs(v.currentFloorInfo.floorRooms) do
						local room = CommonUtils.GetConfig('explore', 'exploreFloorRoom', roomData.roomId)
						room.baseReward = v.currentFloorInfo.baseReward
						room.isBossQuest = roomData.isBossQuest
						if roomData.isBossQuest then
							room.bossQuestId = roomData.bossQuestId
							room.bossId = roomData.bossId
							room.explorePointId = tonumber(explorePointId)
						end
						table.insert(roomDatas, room)
					end
					self:EnterChooseView(roomDatas, v.currentFloorInfo.floor, v.explore.teamId )
				end
				return
			end
		end
		-- 未探索
		self:SendSignal(COMMANDS.COMMAND_Exploration_Enter, {areaFixedPointId = self.exploreId})
	elseif name == SIGNALNAMES.Exploration_Enter_Callback then -- 进入坐标点确定的探索点
		local datas = checktable(signal:GetBody())
		local roomDatas = {}
		local floorDatas = CommonUtils.GetConfig('explore', 'exploreAreaFixedPoint', self.exploreId)
		for explorePointId,v in orderedPairs(floorDatas) do
			local pointData = CommonUtils.GetConfig('explore', 'explorePoint', v)
			local room = CommonUtils.GetConfig('explore', 'exploreFloorRoom', pointData.initRoomId)
			room.isBossQuest = false
			room.baseReward = datas[tostring(v)].baseReward
			room.explorePointId = tonumber(explorePointId)
			table.insert(roomDatas, room)

		end
		-- 进入选择页面
		self:EnterChooseView(roomDatas, 1, 1 )
	elseif name == SIGNALNAMES.Exploration_Explore_Callback then -- 初次探索
		local datas = checktable(signal:GetBody())
		-- 刷新本地定时器数据
		app.badgeMgr:AddSetExploreTimeInfoRed(datas.requestData.areaFixedPointId, datas.currentFloorInfo.needTime)
		-- 扣除活力值
		local mediator = AppFacade.GetInstance():RetrieveMediator('ExplorationChooseMediator')
		self:DeductVigour(datas.requestData.teamId, mediator:GetVigourCost())
		datas.currentFloorInfo.isBossQuest = false
		self:EnterExploreView(datas)
		if datas.explore.teamId then
			local teamData = gameMgr:getTeamCardsInfo(datas.explore.teamId)
			if teamData then
				for i,v in ipairs(teamData) do
					if v.id then
						gameMgr:SetCardPlace({}, {{id = v.id}} , CARDPLACE.PLACE_EXPLORATION)
					end
				end
			end
		end
	elseif name == SIGNALNAMES.Exploration_EnterNextFloor_Callback then -- 进入下层
		local datas = checktable(signal:GetBody())
		local roomDatas = {}
		for explorePointId,v in orderedPairs(datas.newFloorRoom.floorRooms) do
			local room = CommonUtils.GetConfig('explore', 'exploreFloorRoom', tonumber(explorePointId))
			room.baseReward = datas.newFloorRoom.baseReward
			room.isBossQuest = v.isBossQuest
			if room.isBossQuest then
				room.bossQuestId = v.bossQuestId
				room.bossId = v.bossId
				room.explorePointId = tonumber(explorePointId)
			end
			table.insert(roomDatas, room)
		end
		self:EnterChooseView(roomDatas, datas.newFloor, datas.teamId)
	elseif name == SIGNALNAMES.Exploration_Continue_Callback then -- 继续探索
		local datas = checktable(signal:GetBody())
		-- 刷新本地定时器数据
		app.badgeMgr:AddSetExploreTimeInfoRed(datas.requestData.areaFixedPointId, datas.currentFloorInfo.needTime)
		-- 扣除活力值
		local mediator = AppFacade.GetInstance():RetrieveMediator('ExplorationChooseMediator')
		self:DeductVigour(datas.explore.teamId, mediator:GetVigourCost())

		datas.currentFloorInfo.isBossQuest = datas.currentFloorInfo.floorRooms[tostring(datas.currentFloorInfo.roomId)].isBossQuest
		if datas.currentFloorInfo.isBossQuest then
			datas.currentFloorInfo.bossQuestId = datas.currentFloorInfo.floorRooms[tostring(datas.currentFloorInfo.roomId)].bossQuestId
			datas.currentFloorInfo.bossId = datas.currentFloorInfo.floorRooms[tostring(datas.currentFloorInfo.roomId)].bossId
		end
		self:EnterExploreView(datas)
		if datas.explore.teamId then
			local teamData = gameMgr:getTeamCardsInfo(datas.explore.teamId)
			if teamData then
				for i,v in ipairs(teamData) do
					if v.id then
						gameMgr:SetCardPlace({}, {{id = v.id}} , CARDPLACE.PLACE_EXPLORATION)
					end
				end
			end
		end
	elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then -- 刷新顶部状态栏
		self:UpdateCountUI()
	end
end


function ExplorationMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent  = require( 'Game.views.ExplorationView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = uiMgr:GetCurrentScene()
	scene:AddGameLayer(viewComponent)
	-- backBtn
	viewComponent.viewData_.backBtn:setOnClickScriptHandler(function( sender )
		self:GetFacade():UnRegsitMediator('ExplorationMediator')
		local mediator = self:GetFacade():RetrieveMediator("CardEncyclopediaMediator")
		if mediator then
			self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "GONE")
		end
	end)
	self:UpdateCountUI()
	-- local viewComponent = uiMgr:SwitchToTargetScene('Game.views.ExplorationView')
	-- self:SetViewComponent(viewComponent)

	-- local mediator = require( 'Game.mediator.ExplorationChooseMediator').new()
	-- self:GetFacade():RegistMediator(mediator)
	-- local viewData = viewComponent.viewData_
	-- viewData.view:addChild(mediator:GetViewComponent())
	-- local mediator = require( 'Game.mediator.ExplorationBattleMediator').new()
	-- self:GetFacade():RegistMediator(mediator)
	-- local viewData = viewComponent.viewData_
	-- viewData.view:addChild(mediator:GetViewComponent())
end
--[[
进入选择页面
--]]
function ExplorationMediator:EnterChooseView( roomDatas, floorNum, teamId )
	-- dump(roomDatas)
	local viewData = self:GetViewComponent().viewData_
	if viewData.view:getChildByTag(999) then
		self:GetFacade():UnRegsitMediator("ExplorationBattleMediator")
		self:GetFacade():UnRegsitMediator("ExplorationChooseMediator")
		viewData.view:getChildByTag(999):runAction(cc.RemoveSelf:create())
	end
	local mediator = require( 'Game.mediator.ExplorationChooseMediator').new({roomDatas = roomDatas, floorNum = floorNum, exploreId = self.exploreId, teamId = teamId})
	self:GetFacade():RegistMediator(mediator)

	viewData.view:addChild(mediator:GetViewComponent())
end
--[[
进入探索页面
--]]
function ExplorationMediator:EnterExploreView( exploreDatas )
	local viewData = self:GetViewComponent().viewData_
	if viewData.view:getChildByTag(999) then
		self:GetFacade():UnRegsitMediator("ExplorationChooseMediator")
		viewData.view:getChildByTag(999):runAction(cc.RemoveSelf:create())
	end
	local mediator = require( 'Game.mediator.ExplorationBattleMediator').new({exploreDatas = exploreDatas})
	self:GetFacade():RegistMediator(mediator)


	viewData.view:addChild(mediator:GetViewComponent())
end
--[[
扣除活力值
--]]
function ExplorationMediator:DeductVigour( teamId, vigourCost )
	app.restaurantMgr:DeductExploreVigour(teamId, vigourCost)
	-- local teamFormationData = gameMgr:GetUserInfo().teamFormation[teamId]
	-- for i,card in ipairs(teamFormationData.cards) do
	-- 	if card.id then
	-- 		local cardData = gameMgr:GetCardDataById(card.id)
	-- 		gameMgr:UpdateCardDataById(tonumber(card.id), {vigour = tonumber(cardData.vigour - vigourCost)})
	-- 	end
	-- end
end
--更新数量ui值
function ExplorationMediator:UpdateCountUI()
	local viewData = self:GetViewComponent().viewData_
	if viewData.moneyNods then
		for id,v in pairs(viewData.moneyNods) do
			v:updataUi(checkint(id)) --刷新每一个金币数量
		end
	end
end
function ExplorationMediator:EnterLayer(  )
	self:SendSignal(COMMANDS.COMMAND_Exploration_Home)
end
function ExplorationMediator:OnRegist(  )
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "shopAllhide")
	self:GetFacade():DispatchObservers(AvatarScene_ChangeCenterContainer, "hide")
	uiMgr:UpdatePurchageNodeState(false)
	local ExplorationCommand = require('Game.command.ExplorationCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Exploration_Enter, ExplorationCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Exploration_Home, ExplorationCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Exploration_Explore, ExplorationCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Exploration_EnterNextFloor, ExplorationCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Exploration_Continue, ExplorationCommand)
	self:EnterLayer()
end


function ExplorationMediator:OnUnRegist(  )
	uiMgr:UpdatePurchageNodeState(true)
	self:GetFacade():DispatchObservers(AvatarScene_ChangeCenterContainer, "show")
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
	app.badgeMgr:CheckOrderRed()
	-- if gameMgr:GetUserInfo().topUIShowType then
	-- 	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer,gameMgr:GetUserInfo().topUIShowType)
	-- end
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Exploration_Enter)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Exploration_Home)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Exploration_Explore)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Exploration_EnterNextFloor)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Exploration_Continue)
	self:GetFacade():UnRegsitMediator("ExplorationBattleMediator")
    self:GetFacade():UnRegsitMediator("ExplorationChooseMediator")

	AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
end
return ExplorationMediator
