--[[
    燃战BOSSMediator
--]]
local Mediator = mvc.Mediator
---@class SaiMoeBossMediator:Mediator
local SaiMoeBossMediator = class("SaiMoeBossMediator", Mediator)

local NAME = "SaiMoeBossMediator"

local shareFacade = AppFacade.GetInstance()
local uiMgr = app.uiMgr
local gameMgr = shareFacade:GetManager("GameManager")

local MAP_COLLECT_STATE = {
	IMCOMPLETE		= 1,
	COMPOSABLE		= 2,
	BOSS_APPEAR		= 3,
	BOSS_SHOP		= 4,
}

function SaiMoeBossMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.datas = checktable(params) or {}
	-- 缓存的编队数据
	self.teamData = {}
	self.bossName = ""
end

function SaiMoeBossMediator:InterestSignals()
	local signals = { 
		SAIMOE_CHANGE_TEAM_MEMBER_EVENT,
        POST.SAIMOE_BOSS_MAP.sglName ,
        POST.SAIMOE_SET_BOSS_TEAM.sglName ,
		POST.SAIMOE_CLOSE_SHOP.sglName ,
	}

	return signals
end

function SaiMoeBossMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
	if name == SAIMOE_CHANGE_TEAM_MEMBER_EVENT then
		local isEmpty = true
		for i, v in pairs(body.teamData) do
			if next(v) then
				isEmpty = false
				break
			end
		end
		if isEmpty then
			uiMgr:ShowInformationTips(__('队伍不能为空！'))
			return
		end
		self:SendSignal(POST.SAIMOE_SET_BOSS_TEAM.cmdName, {teamCards = self:ConvertTeamData2Str(body.teamData)})
	elseif name == POST.SAIMOE_BOSS_MAP.sglName then
		local supportGroupId = self.datas.supportGroupId
		local playerConf = CommonUtils.GetConfigAllMess('comparisonInfo', 'cardComparison')[tostring(supportGroupId)]
		local consume = {true, true, true, true}
		for i,v in ipairs(playerConf.map) do
			consume[i] = {goodsId = v, num = -1}
		end
		CommonUtils.DrawRewards(consume)
		self.datas.isBossMapOpen = 1
		shareFacade:DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.SAIMOE_COMPOSABLE })

		local viewData = self.viewComponent.viewData
		viewData.accessLabel:setVisible(false)
		viewData.fragmentView:setVisible(false)
		viewData.forkSpine:setVisible(false)
		viewData.shopBtn:setVisible(false)
		viewData.unlockSpine:setVisible(true)
		viewData.bossNode:setVisible(false)
		viewData.bossNode:setScale(0)
		viewData.battleBtn:setVisible(false)
		viewData.showSpine:setVisible(false)
		viewData.unlockSpine:setAnimation(0, 'play', false)
		viewData.unlockSpine:addAnimation(0, 'idle2', true)
		viewData.unlockSpine:registerSpineEventHandler(
				function (event)
					if event.animation == 'play' then
						viewData.showSpine:setVisible(true)
						viewData.completeView:setVisible(true)
						viewData.showSpine:setAnimation(0, 'play', false)
					end
				end,
				sp.EventType.ANIMATION_END
		)
		local function AnimationEnd(  )
			viewData.battleBtn:setVisible(true)
			viewData.forkSpine:setVisible(true)
			viewData.showSpine:setVisible(false)
			viewData.bossStateLabel:setString(__('(已寻得)'))
			viewData.bossStateLabel:setColor(ccc3FromInt('#ffca27'))
			viewData.drawNode:setFilterName()
		end
		viewData.showSpine:registerSpineEventHandler(
				function (event)
					if event.animation == 'play' then
						viewData.bossNode:setVisible(true)
						transition.execute(viewData.bossNode, cc.EaseBackOut:create(
								cc.ScaleTo:create(0.5, -1, 1)
						), {complete = AnimationEnd})
					end
				end,
				sp.EventType.ANIMATION_END
		)
	elseif name == POST.SAIMOE_SET_BOSS_TEAM.sglName then
		self.teamData = self:ConvertStrToTeamTable(body.requestData.teamCards)
		self.datas.bossTeam = body.requestData.teamCards
		-- 关闭阵容界面
		shareFacade:DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')
		self:GetViewComponent():RefreshTeamMember(self.teamData)
	elseif name == POST.SAIMOE_CLOSE_SHOP.sglName then
		self.datas.shopList = {}
		local viewData = self.viewComponent.viewData
		local function AnimationEnd(  )
			self.viewComponent:ShowEnterAni({isScale = true, cb = function ()
				viewData.bossNode:setOpacity(255)
				viewData.bossNode:setVisible(false)
				viewData.bossNode:setPosition(cc.p(858, 60))
				viewData.bossNode:setAnimation(0, 'idle', true)
				self:UpdateMapView()
			end})
		end

		viewData.shopBtn:setVisible(false)
		viewData.bossNode:setAnimation(0, 'run', true)
		transition.execute(viewData.bossNode, cc.Spawn:create(
				cc.FadeOut:create(1),
				cc.MoveBy:create(1, cc.p(-100, 0))
		), {complete = AnimationEnd})

		shareFacade:UnRegsitMediator('SaiMoeShopMediator')
	end
end

function SaiMoeBossMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.saimoe.SaiMoeBossView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	local viewData = viewComponent.viewData

	for k,v in pairs(viewData.fragmentButtons) do
		display.commonUIParams(v  , {cb = handler(self, self.FragmentButtonActions)})
	end

	local supportGroupId = self.datas.supportGroupId
	local playerConf = CommonUtils.GetConfigAllMess('comparisonInfo', 'cardComparison')[tostring(supportGroupId)]

	local bossReward = CommonUtils.GetConfigAllMess('quest', 'cardComparison')[tostring(playerConf.bossQuestId)]
	local drawNode = viewData.drawNode
	drawNode:RefreshAvatar({confId = bossReward.showMonster[1]})
	viewData.drawNode.avatar:setAnchorPoint(cc.p(0.5, 0.5))
	viewData.drawNode.avatar:setPosition(cc.p(viewData.BG:getPositionX() + 265,viewData.BG:getPositionY() + 365))
	viewData.drawNode.avatar:setScale(0.75)

	local iconMonsterConf = CardUtils.GetCardConfig(bossReward.showMonster[1])
	local icon = tostring(iconMonsterConf.drawId or bossReward.showMonster[1])
	local bossNode = AssetsUtils.GetCardSpineNode({confId = icon, scale = 0.3})
	bossNode:setScaleX(-1)
	bossNode:setToSetupPose()
	bossNode:setAnimation(0, 'idle', true)
	display.commonUIParams(bossNode, {po = cc.p(858, 60)})
	viewData.completeView:addChild(bossNode)
	viewData.bossNode = bossNode
	local bossData = CommonUtils.GetConfigAllMess('monster','monster')[tostring(bossReward.showMonster[1])]
	--viewData.bossNameLabel:setString(bossData.name)
	self.bossName = bossData.name
	self.rewards = bossReward.rewards
	if 5 >= table.nums(self.rewards) then
		-- local offset = 480 / table.nums(rewards)
		local offset = 96
		for i,v in ipairs(self.rewards) do
			local goodsIcon = require('common.GoodNode').new({id = v.goodsId})
			goodsIcon:setPosition(cc.p(250 - (table.nums(self.rewards)-1)*offset/2+(i-1)*offset, 80))
			goodsIcon:setScale(0.8)
			viewData.desrView:addChild(goodsIcon)
			display.commonUIParams(goodsIcon, {animate = false, cb = function (sender)
				PlayAudioByClickNormal()
				uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
			end})
		end
	else
		local gridView = viewData.gridView
		gridView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSource))
		gridView:setCountOfCell(#self.rewards)
		gridView:reloadData()
	end

	self:UpdateMapView()
	viewData.composedBtn:setOnClickScriptHandler(handler(self, self.ComposedBtnClickHandler))
	viewData.battleBtn:setOnClickScriptHandler(handler(self, self.BattleBtnClickHandler))
	viewData.detailBtn:setOnClickScriptHandler(handler(self, self.BossDetailBtnClickHandler))
	viewData.fightBtn:setOnClickScriptHandler(handler(self, self.FightBtnClickHandler))
	viewData.shopBtn:setOnClickScriptHandler(handler(self, self.ShopBtnClickHandler))
	viewData.tipBtn:setOnClickScriptHandler(function( sender )
		PlayAudioClip(AUDIOS.UI.ui_window_open.id)

		uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.SAIMOE_BOSS})
	end)
	local bottomView = viewData.bottomView
	bottomView:setVisible(false)

	local emptyCardNodes = viewData.emptyCardNodes
	for k, v in pairs(emptyCardNodes) do
		v.btn:setOnClickScriptHandler(handler(self, self.EditTeamMemberClickHandler))
	end
	self.teamData = self:ConvertStrToTeamTable(self.datas.bossTeam)
	viewComponent:RefreshTeamMember(self.teamData)

	local requestData = self.datas.requestData or {}
	local openShop = requestData.openShop or 0
	if 1 == openShop then
		if next(self.datas.shopList or {}) then
			local SaiMoeShopMediator = require('Game.mediator.saimoe.SaiMoeShopMediator')
			local mediator           = SaiMoeShopMediator.new(self.datas)
			self:GetFacade():RegistMediator(mediator)
		else
			viewComponent:ShowEnterAni()
		end
		self.datas.requestData.openShop = 0
	else
		viewComponent:ShowEnterAni()
	end
end

function SaiMoeBossMediator:UpdateMapView()
	local viewData = self.viewComponent.viewData
	local curState = self:CheckMapState()
	if MAP_COLLECT_STATE.IMCOMPLETE == curState then
		viewData.completeView:setVisible(false)
		viewData.fragmentView:setVisible(true)
		viewData.unlockSpine:setVisible(false)
		viewData.composedBtn:setVisible(false)
		self:ShowFragmentsCount()
		viewData.accessLabel:setVisible(true)
		display.reloadRichLabel(viewData.bossNameLabel , {width = 330 , c = {
			{
				color = '#ffffff',
				font = TTF_GAME_FONT, ttf = true,
				outline = '#5b3c25',
				text = self.bossName,
				fontSize = 40
			},
			{
				color = '#d9ba9b',
				text = __('(未寻得)'),
				fontSize = 26
			}
		}})

		viewData.drawNode:setFilterName(filter.TYPES.GRAY)
	elseif MAP_COLLECT_STATE.COMPOSABLE == curState then
		viewData.completeView:setVisible(false)
		viewData.fragmentView:setVisible(true)
		viewData.mapBG:setVisible(false)
		for i,v in ipairs(viewData.fragmentImgs) do
			v:setVisible(false)
		end
		self:ShowFragmentsCount()
		viewData.unlockSpine:setVisible(true)
		viewData.unlockSpine:setAnimation(0, 'idle1', true)
		viewData.composedBtn:setVisible(true)
		viewData.accessLabel:setVisible(true)
		display.reloadRichLabel(viewData.bossNameLabel , { width = 330 , c = {
			{
				color = '#ffffff',
				font = TTF_GAME_FONT, ttf = true,
				text = self.bossName,
				fontSize = 40
			},
			{
				color = '#d9ba9b',
				text = __('(未寻得)'),
				fontSize = 26
			}
		}})
		viewData.drawNode:setFilterName(filter.TYPES.GRAY)
		viewData.bossNode:setVisible(false)
	elseif MAP_COLLECT_STATE.BOSS_APPEAR == curState or MAP_COLLECT_STATE.BOSS_SHOP == curState then
		viewData.completeView:setVisible(true)
		viewData.fragmentView:setVisible(false)
		viewData.unlockSpine:setVisible(true)
		viewData.unlockSpine:setAnimation(0, 'idle2', true)
		viewData.composedBtn:setVisible(false)
		viewData.accessLabel:setVisible(false)
		viewData.showSpine:setVisible(false)
		viewData.bossNode:setVisible(true)
		display.commonUIParams(viewData.bossNode, {po = cc.p(858, 60)})
		viewData.bossNode:setAnimation(0, 'idle', true)
		if MAP_COLLECT_STATE.BOSS_APPEAR == curState then
			viewData.forkSpine:setVisible(true)
			viewData.battleBtn:setVisible(true)
			viewData.shopBtn:setVisible(false)
		else
			viewData.forkSpine:setVisible(false)
			viewData.battleBtn:setVisible(false)
			viewData.shopBtn:setVisible(true)
		end
		display.reloadRichLabel(viewData.bossNameLabel , { width = 330 ,c = {
			{
				color = '#ffffff',
				font = TTF_GAME_FONT, ttf = true,
				text = self.bossName,
				fontSize = 40
			},
			{
				color = '#ffca27',
				text = __('(已寻得)'),
				fontSize = 26
			}
		}})
		viewData.drawNode:setFilterName()
	end
end

function SaiMoeBossMediator:ShowFragmentsCount( ... )
	local viewData = self.viewComponent.viewData
	local fragmentImgs = viewData.fragmentImgs
	local fragmentCountLabels = viewData.fragmentCountLabels
	local size = fragmentCountLabels[1]:getContentSize()
	local str = __('|_name_|:  |_num_|片')
	local supportGroupId = self.datas.supportGroupId
	local playerConf = CommonUtils.GetConfigAllMess('comparisonInfo', 'cardComparison')[tostring(supportGroupId)]
	for i,v in ipairs(playerConf.map) do
		local amount = gameMgr:GetAmountByGoodId(v)
		if 0 < amount then
			fragmentImgs[i]:clearFilter()
		else
			fragmentImgs[i]:setFilter(GrayFilter:create())
		end

		local textRich = {}
		local text = string.split(str, '|')
		for i,s in ipairs(text) do
			if '_num_' == s then
				if 0 < amount then
					table.insert( textRich, fontWithColor(16, {text = amount}) )
				else
					table.insert( textRich, fontWithColor(10, {text = amount}) )
				end
			elseif '_name_' == s then
				local goodData = CommonUtils.GetConfig('goods', 'goods', v) or {}
				table.insert( textRich, fontWithColor(16, {text = goodData.name}) )
			elseif '' ~= s then
				table.insert( textRich, fontWithColor(16, {text = s}) )
			end
		end

		local numLabel = display.newRichLabel(size.width / 2, size.height / 2)
		display.reloadRichLabel(numLabel, { width = 200 , r = true, c = textRich})
		fragmentCountLabels[i]:addChild(numLabel)
	end
end

function SaiMoeBossMediator:CheckMapState( ... )
	if checkint(self.datas.isBossMapOpen) == 1 then
		return MAP_COLLECT_STATE.BOSS_APPEAR
	elseif next(self.datas.shopList or {}) then
		return MAP_COLLECT_STATE.BOSS_SHOP
	end
	local isComposable = true
	local supportGroupId = self.datas.supportGroupId
	local playerConf = CommonUtils.GetConfigAllMess('comparisonInfo', 'cardComparison')[tostring(supportGroupId)]
	for i,v in ipairs(playerConf.map) do
		local amount = gameMgr:GetAmountByGoodId(v)
		if 0 >= amount then
			isComposable = false
			break
		end
	end

	return isComposable and MAP_COLLECT_STATE.COMPOSABLE or MAP_COLLECT_STATE.IMCOMPLETE
end

function SaiMoeBossMediator:onDataSource(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1
	local viewData = self.viewComponent.viewData
	local size = viewData.gridView:getSizeOfCell()

	if pCell == nil then
		pCell = CGridViewCell:new()
		pCell:setContentSize(size)

		local cell = require('common.GoodNode').new({id = self.rewards[index].goodsId})
		cell:setPosition(cc.p(size.width / 2, size.height / 2))
		cell:setScale(0.8)
        pCell:addChild(cell)
        display.commonUIParams(cell, {animate = false, cb = function (sender)
            uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
        end})
	end
	
	xTry(function()
		
	end,__G__TRACKBACK__)

	return pCell
end

function SaiMoeBossMediator:FragmentButtonActions( sender )
	local tag = sender:getTag()
	local supportGroupId = self.datas.supportGroupId
	local playerConf = CommonUtils.GetConfigAllMess('comparisonInfo', 'cardComparison')[tostring(supportGroupId)]
	local amount = gameMgr:GetAmountByGoodId(playerConf.map[tag])
	if 0 >= amount then
		PlayAudioByClickNormal()

		uiMgr:AddDialog("common.GainPopup", {goodId = playerConf.map[tag]})
		-- uiMgr:ShowInformationTips(__('碎片不足，请先前往搜寻碎片'))
	end
end

function SaiMoeBossMediator:ComposedBtnClickHandler( sender )
	PlayAudioByClickNormal()

	local supportGroupId = self.datas.supportGroupId
	local playerConf = CommonUtils.GetConfigAllMess('comparisonInfo', 'cardComparison')[tostring(supportGroupId)]
	for i, v in pairs(playerConf.map) do
		local amount = gameMgr:GetAmountByGoodId(v)
		if 0 >= amount then
			PlayAudioByClickNormal()
			uiMgr:ShowInformationTips(__('碎片不足，请先前往搜寻碎片'))
			return
		end
	end

	self:SendSignal(POST.SAIMOE_BOSS_MAP.cmdName)
end

function SaiMoeBossMediator:BattleBtnClickHandler( sender )
	PlayAudioByClickNormal()

	local viewData = self.viewComponent.viewData
	viewData.bottomView:setVisible(true)
end

function SaiMoeBossMediator:BossDetailBtnClickHandler( sender )
	PlayAudioByClickNormal()
	local supportGroupId = self.datas.supportGroupId
	local playerConf = CommonUtils.GetConfigAllMess('comparisonInfo', 'cardComparison')[tostring(supportGroupId)]

	local BossDetailMediator = require("Game.mediator.BossDetailMediator")
	local mediator = BossDetailMediator.new({questId = tonumber(playerConf.bossQuestId)})
	shareFacade:RegistMediator(mediator)
end

function SaiMoeBossMediator:FightBtnClickHandler( sender )
	PlayAudioByClickNormal()
	if not self.datas.bossTeam or self.datas.bossTeam == '' then
		uiMgr:ShowInformationTips(__('队伍不能为空！'))
		return
	end

	local playerConf = CommonUtils.GetConfigAllMess('comparisonInfo', 'cardComparison')[tostring(self.datas.supportGroupId)]

	-- 服务器参数
	local serverCommand = BattleNetworkCommandStruct.New(
			POST.SAIMOE_BOSS_QUEST_AT.cmdName,
			{questId = checkint(playerConf.bossQuestId), openShop = 1},
			POST.SAIMOE_BOSS_QUEST_AT.sglName,
			POST.SAIMOE_BOSS_QUEST_GRADE.cmdName,
			{questId = checkint(playerConf.bossQuestId)},
			POST.SAIMOE_BOSS_QUEST_GRADE.sglName,
			nil,
			nil,
			nil
	)
	local fromToStruct = BattleMediatorsConnectStruct.New(
			"saimoe.SaiMoeSupportMediator",
			"saimoe.SaiMoeSupportMediator"
	)
	-- 创建战斗构造器
	local battleConstructor = require('battleEntry.BattleConstructor').new()

	battleConstructor:InitStageDataByNormalEvent(
			checkint(playerConf.bossQuestId),
			serverCommand,
			fromToStruct,
			string.split(self.datas.bossTeam, ','),
			{},
			{}
	)

	if not AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator') then
		local enterBattleMediator = require('Game.mediator.EnterBattleMediator').new()
		AppFacade.GetInstance():RegistMediator(enterBattleMediator)
	end

	AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)
end

function SaiMoeBossMediator:ShopBtnClickHandler( sender )
	PlayAudioByClickNormal()

	local SaiMoeShopMediator = require('Game.mediator.saimoe.SaiMoeShopMediator')
	local mediator           = SaiMoeShopMediator.new(self.datas)
	self:GetFacade():RegistMediator(mediator)
end

--[[
选卡按钮回调
--]]
function SaiMoeBossMediator:EditTeamMemberClickHandler(sender)
    PlayAudioByClickNormal()

	local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
		teamDatas = {[1] = clone(self.teamData)},
		title = __('编辑队伍'),
		teamTowards = 1,
		avatarTowards = 1,
		teamChangeSingalName = SAIMOE_CHANGE_TEAM_MEMBER_EVENT,
		battleType = 1
	})
	layer:setAnchorPoint(cc.p(0.5, 0.5))
	layer:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(layer)
end

function SaiMoeBossMediator:ConvertStrToTeamTable( str )
	if not str or str == '' then
		return {}
	end
	local ids = string.split(str or '', ',') or {}
	local teamData = {}
	for i,v in ipairs(ids) do
		table.insert( teamData, {id = v} )
	end
	return teamData
end
--[[
获取转换后传给服务器的阵容数据
@params teamData table
@return str string 阵容数据
--]]
function SaiMoeBossMediator:ConvertTeamData2Str(teamData)
	local str = {}
	for i = 1, MAX_TEAM_MEMBER_AMOUNT do
		local cardInfo = teamData[i] or {}
		if nil ~= cardInfo and nil ~= cardInfo.id and 0 ~= checkint(cardInfo.id) then
			table.insert(str, cardInfo.id)
			local nextCardInfo = teamData[i+1] or {}
			if nil ~= nextCardInfo and nil ~= nextCardInfo.id and 0 ~= checkint(nextCardInfo.id) then
				table.insert(str, ',')
			end
		end
	end
	return table.concat( str )
end

function SaiMoeBossMediator:OnRegist(  )
    regPost(POST.SAIMOE_BOSS_MAP)
    regPost(POST.SAIMOE_SET_BOSS_TEAM)
end

function SaiMoeBossMediator:OnUnRegist(  )
	unregPost(POST.SAIMOE_BOSS_MAP)
	unregPost(POST.SAIMOE_SET_BOSS_TEAM)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return SaiMoeBossMediator