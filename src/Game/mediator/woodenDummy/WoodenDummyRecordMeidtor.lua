local Mediator = mvc.Mediator
---@class WoodenDummyRecordMeidtor :Mediator
local WoodenDummyRecordMeidtor = class("WoodenDummyRecordMeidtor", Mediator)
local NAME = "WoodenDummyRecordMeidtor"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
function WoodenDummyRecordMeidtor:ctor( param, viewComponent )
	self.super:ctor(NAME,viewComponent)
	local param = param or {}
	self.dummyRecordsList =param.dummyRecordsList  -- 所有类型的记录
	self.questType = 1 -- 战斗类型
	self.dummyRecordList = {} -- 一个战斗一类型的记录
end
function WoodenDummyRecordMeidtor:InterestSignals()
	local signals = {
		"DUMMY_CLICK_INDEX_EVENT"
	}
	return signals
end

function WoodenDummyRecordMeidtor:Initial( key )
	self.super.Initial(self,key)

	---@type WoodenDummyRecordView
	local  viewComponent = require('Game.views.woodenDummy.WoodenDummyRecordView').new()
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	self:SetViewComponent(viewComponent)

	local viewData  = viewComponent.viewData
	viewData.closeLayer:setOnClickScriptHandler(handler(self , self.CloseView))
	for i = 1, #viewData.buttons do
		local button = viewData.buttons[i]
		button:setOnClickScriptHandler(handler(self, self.QuestTypeRecordClick))
	end
	viewComponent:SelectType(1)
	self:ReloadGride(1)
end



function WoodenDummyRecordMeidtor:ProcessSignal(signal)
	local name = signal:GetName()
	local data = signal:GetBody()
	if name == "DUMMY_CLICK_INDEX_EVENT" then
		local pos = data.pos
		local cellIndex = data.cellIndex
		local team = self.dummyRecordList[cellIndex].team
		local cardData = team[pos]
		local playerCardDetailData = {
			cardData = {
				breakLevel = cardData.breakLevel,
				cardId     = cardData.cardId,
				favorLevel = cardData.favorabilityLevel,
				level      = cardData.level,
				skinId     = cardData.defaultSkinId,
				artifactTalent = cardData.artifactTalent,
				isArtifactUnlock = cardData.isArtifactUnlock,
				bookLevel = cardData.bookLevel,
				equippedHouseCatGene = cardData.equippedHouseCatGene,
			},
			petsData = cardData.pets,
			playerData = {
				playerAvatar      = app.gameMgr:GetUserInfo().avatar,
				playerAvatarFrame = app.gameMgr:GetUserInfo().avatarFrame,
				playerId          = app.gameMgr:GetUserInfo().playerId,
				playerLevel       = app.gameMgr:GetUserInfo().level,
				playerName        = app.gameMgr:GetUserInfo().playerName,
			},
			viewType = 1,
		}
		local playerCardDetailView = require('Game.views.raid.PlayerCardDetailView').new(playerCardDetailData)
		playerCardDetailView:setTag(2222)
		display.commonUIParams(playerCardDetailView, {ap = cc.p(0.5, 0.5), po = cc.p(
				display.cx, display.cy
		)})

		uiMgr:GetCurrentScene():AddDialog(playerCardDetailView)


	end
end

function WoodenDummyRecordMeidtor:ReloadGride(index)
	self.questType = index
	self.dummyRecordList = self.dummyRecordsList[tostring(index)] or {}

	---@type WoodenDummyRecordView
	local viewComponent = self:GetViewComponent()
	local viewData =  viewComponent.viewData
	viewData.gridView:setCountOfCell(#self.dummyRecordList)
	viewData.gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSource))
	viewData.gridView:reloadData()
	if #self.dummyRecordList > 0  then
		viewData.richLabel:setVisible(false)
	else
		viewData.richLabel:setVisible(true)
	end
end


--[[
   副本刷新操作
--]]
function WoodenDummyRecordMeidtor:OnDataSource(p_convertview, idx)
	local index = idx +1
	---@type WoodenDummyRecordCell
	local pcell = p_convertview
	if not  pcell then
		pcell = require("Game.views.woodenDummy.WoodenDummyRecordCell").new()
	end
	xTry(function()
		local data = self.dummyRecordList[index]
		pcell:UpdateCell(data , self.questType , index )

	end,__G__TRACKBACK__)
	return pcell
end
--[[
	关卡类型的点击事件
--]]
function WoodenDummyRecordMeidtor:QuestTypeRecordClick(sender)
	local index = sender:getTag()

	local viewComponent = self:GetViewComponent()
	viewComponent:SelectType(index)
	self:ReloadGride(index)

end
function WoodenDummyRecordMeidtor:CloseView()
	app:UnRegsitMediator(NAME)
end

function WoodenDummyRecordMeidtor:OnRegist()

end

function WoodenDummyRecordMeidtor:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:runAction(cc.RemoveSelf:create())
	end
end

return WoodenDummyRecordMeidtor




