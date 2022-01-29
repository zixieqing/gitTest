--[[
探索编辑队伍场景
@params params table {
	teamData list 现有阵容
	allCards list 所有卡牌数据
	maxCardsAmount int 最大可以选择的卡牌数量
	avatarTowards int 1 朝右 -1 朝左
	teamChangeSingalName string 阵容变化回调信号
	teamTowards int 队伍朝向 1 朝右 -1 朝左
	battleType int 1 不显示一些pvc专用的ui
	dataTag    int 数据标识
}
--]]
local GameScene = require( "Frame.GameScene" )
local ExploreSystemChangeTeamScene = class("ExploreSystemChangeTeamScene", GameScene)

------------ import ------------
local appFacadeIns     = AppFacade.GetInstance()
local gameMgr          = appFacadeIns:GetManager("GameManager")
local cardMgr          = appFacadeIns:GetManager('CardManager')
local uiMgr            = appFacadeIns:GetManager("UIManager")
local exploreSystemMgr = appFacadeIns:GetManager("ExploreSystemManager")
------------ import ------------

------------ define ------------
-- 关闭此视图
local CLOSE_CHANGE_TEAM_SCENE       = 'CLOSE_CHANGE_TEAM_SCENE'
-- 刷新卡牌列表
local REFRESH_CARD_LIST             = 'REFRESH_CARD_LIST'
-- 装备一个卡牌
local EQUIP_A_CARD                  = 'EQUIP_A_CARD'
-- 卸下一个卡牌
local UNEQUIP_A_CARD                = 'UNEQUIP_A_CARD'
-- 装备所有卡牌
local EQUIP_ALL_CARDS               = 'EQUIP_ALL_CARDS'
-- 卸下一个avatar
local UNEQUIP_A_AVATAR              = 'UNEQUIP_A_AVATAR'
-- 更新达成探索
local UPDATE_QUEST_REACH            = 'UPDATE_QUEST_REACH'
-- 满足团队改变条件
local SATISFY_TEAM_CHANGE_CONDITION = 'SATISFY_TEAM_CHANGE_CONDITION'

local VIEW_CONTROLLABLE             = 'VIEW_CONTROLLABLE'
------------ define ------------

local DIALOG_TAG = {
    REMOND        = 5000,        -- 探索
}

--[[
constructor
--]]
function ExploreSystemChangeTeamScene:ctor(...)
	local args = unpack({...}) or {}
	GameScene.ctor(self, 'Game.views.exploreSystem.ExploreSystemChangeTeamScene')

	self:InitData(args)

	self:InitUI()
	-- 注册信号回调
	self:RegisterSignal()

end
---------------------------------------------------
-- init begin --
---------------------------------------------------

function ExploreSystemChangeTeamScene:InitData(args)
	self.isControllable_      = true
	self.isTimeEnd = false
	-- 过滤类型
	self.filerTypes = {}
	self.teamInfoViewTag = args.teamInfoViewTag

	self.maxCardsAmount = args.maxCardsAmount or MAX_TEAM_MEMBER_AMOUNT
	self.allCards = args.allCards
	
	-- 如果没传数据 初始化一次玩家所有卡牌
	if nil == self.allCards then
		self.allCards = {}
		for k,v in pairs(gameMgr:GetUserInfo().cards) do
			table.insert(self.allCards, v)
		end
	end
	-- logInfo.add(5, tableToString(gameMgr:GetUserInfo().cards))
	self:InitCardSelectData(args)

	self.conditionData = args.conditionData

	self.conditionRewardList = args.conditionRewardList
	self.conditionBaseReward = args.conditionBaseReward

	self.teamChangeSingalName = args.teamChangeSingalName

	self.dataTag = args.dataTag

	self.isCheckCardStatus = args.isCheckCardStatus

end

function ExploreSystemChangeTeamScene:InitCardSelectData(args)
	self.selectedCards = {}
	self.selectedCardIds = {}
	for i = 1, self.maxCardsAmount do
		self.selectedCards[i] = {}
		
		if args.teamData and nil ~= args.teamData[i] and checkint(args.teamData[i].id) > 0 then
			self.selectedCards[i].id = args.teamData[i].id
			self.selectedCardIds[tostring(self.selectedCards[i].id)] = self.selectedCards[i].id
		end
	end
end

function ExploreSystemChangeTeamScene:InitUI()
	local size = self:getContentSize()

	self:addChild(display.newLayer(size.width * 0.5, size.height * 0.5, {ap = display.CENTER, color = cc.c4b(0, 0, 0, 130), size = size, enable = true}))

	-- back btn
	local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png"), cb = handler(self, self.BackBtnClickHandler)})
	backBtn:setName('backBtn')
	display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, size.height - 18 - backBtn:getContentSize().height * 0.5)})
	self:addChild(backBtn, 10)

	-------------------------------------
	-- right
	local explorConditionView = require( "Game.views.exploreSystem.ExploreSystemConditionView" ).new({
		conditionData = self.conditionData, 
		selectedCardIds = self.selectedCardIds, 
		conditionRewardList = self.conditionRewardList,
		conditionBaseReward = self.conditionBaseReward,
		cardsNum = self.maxCardsAmount,
	})
	display.commonUIParams(explorConditionView, {ap = display.LEFT_BOTTOM})
	self:addChild(explorConditionView, 2)
	
	-------------------------------------
	-- left
	local teamInfoView = require('common.TeamInfoView').new({
		tag = self.teamInfoViewTag,
		teamData = self.selectedCards,
		maxCardNum = self.maxCardsAmount,
		disableConnectSkill = true,
		avatarOriPos = cc.p(display.SAFE_L + 155, size.height * 0.48),
		avatarLocationInfo = {
			[1] = {fixedPos = cc.p(620, 0)},
			[2] = {fixedPos = cc.p(465, 0)},
			[3] = {fixedPos = cc.p(310, 0)},
			[4] = {fixedPos = cc.p(155, 0)},
			[5] = {fixedPos = cc.p(0, 0)}
	}})
    display.commonUIParams(teamInfoView,{po = cc.p(display.cx - 20, display.cy), ap = display.CENTER})
    self:addChild(teamInfoView)	

	-- team list info layer
	local teamListInfoLayerSize = cc.size(display.SAFE_RECT.width - 442, size.height / 2)
	local teamListInfoLayer = display.newLayer(display.SAFE_L, 0, {ap = display.LEFT_BOTTOM, size = teamListInfoLayerSize})
	self:addChild(teamListInfoLayer)

	-- team list bg
	local teamListBgSize = cc.size(teamListInfoLayerSize.width, teamListInfoLayerSize.height - 40)
	teamListInfoLayer:addChild(display.newImageView(_res('ui/common/pvp_select_bg_allcard.png'), 0, 0, {scale9 = true, size = teamListBgSize, ap = display.LEFT_BOTTOM}))

	-- list bg
	local listSize = cc.size(teamListBgSize.width - 100, teamListBgSize.height - 87)
	teamListInfoLayer:addChild(display.newImageView(_res('ui/common/common_bg_goods.png'), 20, 5, {ap = display.LEFT_BOTTOM, scale9 = true, size = listSize}))

	-- list
	-- gridView的最大期望宽度
	local paddingX = 10
	local maxGridW = listSize.width - paddingX * 2
	local col = math.floor(maxGridW / 143)
	local gridViewCellSize = cc.size(listSize.width / col, 143)
	local gridView = CGridView:create(listSize)
	gridView:setDataSourceAdapterScriptHandler(handler(self, self.CardsGridViewDataAdapter))
    gridView:setAnchorPoint(display.LEFT_BOTTOM)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setPosition(cc.p(20, 5)) 
	gridView:setColumns(col)
    teamListInfoLayer:addChild(gridView)

	-- team list recommed bg
	local teamListRecommedBgSize = cc.size(teamListInfoLayerSize.width, 73)
	local teamListRecommedBg = display.newLayer(0, teamListBgSize.height - 7, {scale9 = true, size = teamListRecommedBgSize, ap = display.LEFT_TOP})
	teamListInfoLayer:addChild(teamListRecommedBg)

	local recommedBtn = display.newButton(15, teamListRecommedBgSize.height / 2 - 6, {ap = display.LEFT_CENTER, n = _res('ui/common/common_btn_orange.png') , scale9 = true  , size =  cc.size(160,60) })
	display.commonLabelParams(recommedBtn, fontWithColor(14, {text = __('一键编队') , w = 150  ,  hAlign = display.TAC ,reqH = 50 }))

	--recommedBtn:getLabel():setPosition(cc.p(60,30))
	display.commonUIParams(recommedBtn, {cb = handler(self, self.RecommedBtnClickHandler)})
	teamListRecommedBg:addChild(recommedBtn)

	local tipsBtn = display.newButton(167, teamListRecommedBgSize.height / 2 - 6, {ap = display.LEFT_CENTER, animate = false, n = _res('ui/common/common_btn_tips.png')})
	local tipsBtnSize = tipsBtn:getContentSize()
	teamListRecommedBg:addChild(tipsBtn)

	teamListRecommedBg:addChild(display.newLabel(tipsBtn:getPositionX() + tipsBtnSize.width, tipsBtn:getPositionY(), fontWithColor(4, {ap = display.LEFT_CENTER, w= 620 , text = __('提示:选中右侧不同条件可快速检索满足对应条件的飨灵。')})))
	

	local tempCardLayer = display.newLayer()
	self:addChild(tempCardLayer)

	self.gridView = gridView
	self.tempCardLayer = tempCardLayer

	self:RefreshFilterCardsByFilerTypes()
	-- self:RefreshFilterCards()
end

---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
gridview data adapter
--]]
function ExploreSystemChangeTeamScene:CardsGridViewDataAdapter(c, i)
	
	local index = i + 1
	local cell = c
	local cardData = self:GetCardDataByListIndex(index)

	if nil == cell then
		cell = CGridViewCell:new()
		local size = self.gridView:getSizeOfCell()
		cell:setContentSize(size)

		local cardHeadNode = require('common.CardHeadNode').new({
			id = checkint(cardData.id),
			showBaseState = true, showActionState = true, showVigourState = false, ShowExploreState = true
		})
		local scale = (size.width - 20) / cardHeadNode:getContentSize().width
		cardHeadNode:setScale(scale)
		cardHeadNode:setPosition(utils.getLocalCenter(cell))
		cell:addChild(cardHeadNode)
		cardHeadNode:setTag(3)
		display.commonUIParams(cardHeadNode, {cb = handler(self, self.CardHeadClickHandler), animate = false})

		local selectCover = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), size = cc.size(
			cardHeadNode:getContentSize().width * scale - 10,
			cardHeadNode:getContentSize().height * scale - 10
		)})
		display.commonUIParams(selectCover, {ap = cc.p(0.5, 0.5), po = cc.p(
			cardHeadNode:getPositionX(),
			cardHeadNode:getPositionY()
		)})
		cell:addChild(selectCover, 5)
		selectCover:setTag(5)

		selectCover:setVisible(false)

		local selectMark = display.newImageView(_res('ui/common/common_bg_frame_goods_elected.png'), 0, 0)
		display.commonUIParams(selectMark, {po = cc.p(
			cardHeadNode:getPositionX(),
			cardHeadNode:getPositionY()
		)})
		selectMark:setScale((cardHeadNode:getContentSize().width * scale + 10) / selectMark:getContentSize().width)
		cell:addChild(selectMark, 5)
		selectMark:setTag(7)

		selectMark:setVisible(false)

		local cellPos = cc.p(cardHeadNode:getPositionX(), cardHeadNode:getPositionY())
		local gridViewSize = self.gridView:getContentSize()
		cardHeadNode:setPosition(cc.p(0, -gridViewSize.height))
		cardHeadNode:runAction(cc.Sequence:create({
			cc.DelayTime:create(index * 0.02),
			cc.MoveTo:create(0.2, cellPos),
		}))
		
	else
		cell:stopAllActions()
		cell:getChildByTag(3):RefreshUI({
			id = checkint(cardData.id)
		})
		cell:getChildByTag(3):setPosition(utils.getLocalCenter(cell))
	end

	cell:setTag(index)
	local selected = self:IsCardSelectedById(cardData.id)
	cell:getChildByTag(5):setVisible(selected)
	cell:getChildByTag(7):setVisible(selected)

	return cell
end

--[[
根据筛选的类型刷新可选择的卡牌
@params ftype int 筛选类型
--]]
function ExploreSystemChangeTeamScene:RefreshFilterCardsByFilerTypes()
	local cardDatas = {}
	if next(self.filerTypes) == nil then
		cardDatas = self.allCards
	end

	CommonUtils.sortCard(cardDatas)
	self:RefreshFilterCards(cardDatas)
end

function ExploreSystemChangeTeamScene:RefreshFilterCards(cardDatas)
	------------ data ------------
	self.filterCards = cardDatas
	------------ data ------------

	------------ view ------------
	self.gridView:setCountOfCell(#self.filterCards)
	self.gridView:reloadData()
	------------ view ------------
end

--[[
根据列表序号获取卡牌数据
@params listIndex int 列表序号
@return _ table cardData
--]]
function ExploreSystemChangeTeamScene:GetCardDataByListIndex(listIndex)
	return self.filterCards[listIndex]
end
--[[
根据卡牌id获取列表序号
@params id int 卡牌id
@return listIndex int 列表序号
--]]
function ExploreSystemChangeTeamScene:GetListIndexById(id)
	local listIndex = nil
	id = checkint(id)
	if id <= 0 then return listIndex end

	for i,v in ipairs(self.filterCards) do
		if id == checkint(v.id) then
			listIndex = i
		end
	end
	return listIndex
end

--[[
装备卡牌
@params id int 卡牌数据库id
@params listIndex int 列表序号
--]]
function ExploreSystemChangeTeamScene:EquipACardById(id, listIndex)
	local slotIndex = self:GetAEmptyCardSlot()

	-- 判断是否可以上卡
	if nil == slotIndex then
		uiMgr:ShowInformationTips(__('没有多余位置了!!!'))
		return
	end
	if not self:GetIsControllable() then return end
	self:SetIsControllable(false)

	local callback = function ()
		------------ data ------------
		
		self.selectedCards[slotIndex] = {id = id}
		self.selectedCardIds[tostring(id)] = id
		
		appFacadeIns:DispatchObservers(EQUIP_A_CARD, {id = id, position = slotIndex, listIndex = listIndex, callback = handler(self, self.ShowCardAction), tag = self.teamInfoViewTag})
		appFacadeIns:DispatchObservers(UPDATE_QUEST_REACH, {selectedCardIds = self.selectedCardIds})
		------------ data ------------

		------------ view ------------
		self:UpdateCellShowState(listIndex, true)
		------------ view ------------
	end

	if self.isCheckCardStatus then
		self:CheckCardStatus(id, CARDPLACE.PLACE_EXPLORE_SYSTEM, callback) 
	else
		callback()
	end
	
end
--[[
卸下卡牌
@params id int 卡牌数据库id
@params listIndex int 列表序号
--]]
function ExploreSystemChangeTeamScene:UnequipACardById(id, listIndex)
	local position = nil
	if self:IsCardSelectedById(id) then
		------------ data ------------
		self.selectedCardIds[tostring(id)] = nil
		for i,v in ipairs(self.selectedCards) do
			if nil ~= v.id and checkint(id) == checkint(v.id) then
				position = i
				self.selectedCards[i] = {}
				break
			end
		end
		------------ data ------------

		------------ view ------------
		self:UpdateCellShowState(listIndex, false)
		------------ view ------------
	end

	if nil ~= position then
		appFacadeIns:DispatchObservers(UNEQUIP_A_CARD, {id = id, position = position, tag = self.teamInfoViewTag})
	end
	appFacadeIns:DispatchObservers(UPDATE_QUEST_REACH, {selectedCardIds = self.selectedCardIds})

end

--[[
卸下卡牌
@params teamIndex int 队伍序号
--]]
function ExploreSystemChangeTeamScene:UnequipACardByTeamIndex(teamIndex)
	------------ data ------------
	
	local id = nil
	if nil ~= self.selectedCards[teamIndex] then
		id = self.selectedCards[teamIndex].id
		self.selectedCards[teamIndex] = {}
	end

	if nil ~= id then
		self.selectedCardIds[tostring(id)] = nil
		local listIndex = self:GetListIndexById(id)
		if nil ~= listIndex then
			------------ view ------------
			self:UpdateCellShowState(listIndex, false)
			------------ view ------------
		end
	end

	------------ data ------------
	appFacadeIns:DispatchObservers(UPDATE_QUEST_REACH, {selectedCardIds = self.selectedCardIds})
end

function ExploreSystemChangeTeamScene:UpdateCellShowState(listIndex, isShow)
	local cell = self.gridView:cellAtIndex(listIndex - 1)
	if nil ~= cell then
		cell:getChildByTag(5):setVisible(isShow)
		cell:getChildByTag(7):setVisible(isShow)
	end
end

---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------

--[[
获取一个空槽
@return index int 空槽id
--]]
function ExploreSystemChangeTeamScene:GetAEmptyCardSlot()
	local index = nil
	for i = 1, self.maxCardsAmount do
		if nil == self.selectedCards[i].id then
			return i
		end
	end
	return index
end

function ExploreSystemChangeTeamScene:GetDisableTip()
	return self.disableTip
end
function ExploreSystemChangeTeamScene:SetDisableTip(disableTip)
	self.disableTip = disableTip
end

function ExploreSystemChangeTeamScene:GetDataTag()
	return self.dataTag
end

--[[
根据卡牌数据库id判断卡牌是否被选中
@params id int 卡牌数据库id
@return _ bool 是否被选中
--]]
function ExploreSystemChangeTeamScene:IsCardSelectedById(id)
	return nil ~= self.selectedCardIds[tostring(id)]
end

--[[
添加filerType
@params id int 卡牌数据库id
@return _ bool 是否被选中
--]]
function ExploreSystemChangeTeamScene:AddFilerType(filerType)
	self.filerTypes[tostring(filerType)] = filerType
	self:RefreshFilterCardsByFilerTypes()
end

--[[
移除filerType
@params id int 卡牌数据库id
@return _ bool 是否被选中
--]]
function ExploreSystemChangeTeamScene:RemoveFilerType(filerType)
	self.filerTypes[tostring(filerType)] = nil
end

function ExploreSystemChangeTeamScene:CheckCardStatus(id, placeId, callback)
	local isCan = false
	local places = gameMgr:GetCardPlace({id = id})
	
	if gameMgr:CanSwitchCardStatus({id = id}, placeId) then
		isCan = true
		if places and next(places) ~= nil then
			
			local descr     = nil
			-- if places[tostring(CARDPLACE.PLACE_TEAM)] then
			-- 	descr = __('该飨灵已经在编队中，是否派遣该飨灵进行探索。')
			-- elseif places[tostring(CARDPLACE.PLACE_ICE_ROOM)] then
			-- 	descr = __('该飨灵已经在冰场中，是否派遣该飨灵进行探索。')
			-- else
				if callback then
					callback()
				end
			-- end

			if descr ~= nil then
				local scene = uiMgr:GetCurrentScene()
				local temp_str = __('确定派遣该飨灵进行探索？')
				local CommonTip  = require( 'common.NewCommonTip' ).new({extra = descr, text = temp_str, isOnlyOK = false, callback = function ()
					if callback then
						callback()
					end
				end, cancelBack = function ()
					self:SetIsControllable(true)
				end, closeBgCB = function ()
					self:SetIsControllable(true)
				end})
				CommonTip:setPosition(display.center)
				scene:AddDialog(CommonTip)
			end

		else
			if callback then
				callback()
			end
		end
	else
		if places[tostring(CARDPLACE.PLACE_TAKEAWAY)] then
			uiMgr:ShowInformationTips(__('该飨灵正在配送外卖中。'))
		elseif places[tostring(CARDPLACE.PLACE_EXPLORATION)] or places[tostring(CARDPLACE.PLACE_EXPLORE_SYSTEM)] then
			uiMgr:ShowInformationTips(__('该飨灵正在探索中。'))
		elseif places[tostring(CARDPLACE.PLACE_ASSISTANT)] then
			uiMgr:ShowInformationTips(__('该飨灵已经在大堂工作。'))
		elseif places[tostring(CARDPLACE.PLACE_FISH_PLACE)]  then
			uiMgr:ShowInformationTips(__('该飨灵已经在好友钓场工作。'))
		elseif places[tostring(CARDPLACE.PLACE_FISH_PLACE)]  then
			uiMgr:ShowInformationTips(__('该飨灵已经在钓场工作。'))
		end
		self:SetIsControllable(true)
	end

	return isCan
end

---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
function ExploreSystemChangeTeamScene:BackBtnClickHandler()
	if not self:GetIsControllable() then return end
	-- 弹提示
	local commonTip = require('common.NewCommonTip').new({
		text = __('返回将无法保存编队 是否继续?'),
		callback = function ()
			appFacadeIns:DispatchObservers(CLOSE_CHANGE_TEAM_SCENE)
		end
	})
	commonTip:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(commonTip)
	-- appFacadeIns:DispatchObservers(CLOSE_CHANGE_TEAM_SCENE)
end

function ExploreSystemChangeTeamScene:RecommedBtnClickHandler()
	if not self:GetIsControllable() then return end
	self:SetIsControllable(false)
	local recommedCards = exploreSystemMgr:getRecommedCards(self.allCards, self.conditionData, self.maxCardsAmount, self.dataTag)
	self:InitCardSelectData({teamData = recommedCards})
	self:RefreshFilterCardsByFilerTypes()
	
	appFacadeIns:DispatchObservers(UPDATE_QUEST_REACH, {selectedCardIds = self.selectedCardIds})
	appFacadeIns:DispatchObservers(EQUIP_ALL_CARDS, {selectedCards = self.selectedCards, tag = self.teamInfoViewTag})
end

function ExploreSystemChangeTeamScene:CardHeadClickHandler(sender)
	PlayAudioByClickNormal()
	
	local cell = sender:getParent()
	local listIndex = cell:getTag()
	local cardData = self:GetCardDataByListIndex(listIndex)
	local id = checkint(cardData.id)
	if self:IsCardSelectedById(id) then
		if not self:GetIsControllable() then return end
		self:SetIsControllable(false)

		-- 卸下卡牌
		self:UnequipACardById(id, listIndex)
	else
		-- 装备卡牌
		self:EquipACardById(id, listIndex)
	end	
end

--[[
注册信号回调
--]]
function ExploreSystemChangeTeamScene:RegisterSignal()

	------------ 关闭本界面 ------------
	appFacadeIns:RegistObserver(CLOSE_CHANGE_TEAM_SCENE, mvc.Observer.new(function (_, signal)
		if not self:GetIsControllable() then return end
		self:setVisible(false)
		self:runAction(cc.RemoveSelf:create())
	end, self))
	------------ 关闭本界面 ------------

	------------ 刷新卡牌列表 ------------
	appFacadeIns:RegistObserver(REFRESH_CARD_LIST, mvc.Observer.new(function (_, signal)
		local data = signal:GetBody() or {}
		self:RefreshFilterCards(data.cardDatas or self.allCards)
	end, self))
	------------ 刷新卡牌列表 ------------

	------------ 卸下一个avatar ------------
	appFacadeIns:RegistObserver(UNEQUIP_A_AVATAR, mvc.Observer.new(function (_, signal)
		local data = signal:GetBody() or {}
		if data.tag ~= self.teamInfoViewTag then return end
		self:UnequipACardByTeamIndex(data.position)
	end, self))
	------------ 卸下一个avatar ------------

	------------ 满足阵容改变条件 ------------
	appFacadeIns:RegistObserver(SATISFY_TEAM_CHANGE_CONDITION, mvc.Observer.new(function (_, signal)
		if not self:GetIsControllable() then return end
		local data = signal:GetBody()
		-- todo 如果这个探索任务刷新时间到了的话 直接退界面
		if self:GetDisableTip() then
			uiMgr:ShowInformationTips(__('您的任务已经过期，请重新选择新的任务进行探索'))
		else
			-- 转发一下信号
			if self.teamChangeSingalName then
				appFacadeIns:DispatchObservers(self.teamChangeSingalName, {teamData = self.selectedCards, curRewardIndex = data.curRewardIndex, dataTag = self.dataTag})
			end
		end
		appFacadeIns:DispatchObservers(CLOSE_CHANGE_TEAM_SCENE)
	end, self))
	------------ 满足阵容改变条件 ------------

	appFacadeIns:RegistObserver(VIEW_CONTROLLABLE, mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		if data.tag ~= self.teamInfoViewTag then return end
		local isControllable = data.isControllable
		self:SetIsControllable(isControllable)
	end, self))
	
end

function ExploreSystemChangeTeamScene:ShowCardAction(id, listIndex, toWorldPos, callback)
	local cell = self.gridView:cellAtIndex(listIndex - 1)
	local cellSize = cell:getContentSize()
	local fromWorldPos = cell:convertToWorldSpace(cc.p(cellSize.width/2, cellSize.height/2))
	local fromNodePos = self.tempCardLayer:convertToNodeSpace(fromWorldPos)
	local toNodePos = self.tempCardLayer:convertToNodeSpace(toWorldPos)

	local cardHeadNode = require('common.CardHeadNode').new({id = id, showActionState = false})
	cardHeadNode:setAnchorPoint(display.CENTER)
	cardHeadNode:setPosition(fromNodePos)
	cardHeadNode:setEnabled(false)
	cardHeadNode:setScale(0.65)
	self.tempCardLayer:addChild(cardHeadNode)

	local actionTime = 0.2
	self.tempCardLayer:runAction(cc.Sequence:create({
		cc.Spawn:create({
			cc.TargetedAction:create(cardHeadNode, cc.MoveTo:create(actionTime, cc.p(toNodePos.x, toNodePos.y + 120))),
		}),
		cc.DelayTime:create(0.1),
		cc.TargetedAction:create(cardHeadNode, cc.ScaleTo:create(0.2, 0, 1)),
		cc.TargetedAction:create(cardHeadNode, cc.RemoveSelf:create()),
		cc.DelayTime:create(0.2),
		cc.CallFunc:create(function()
			-- PlayAudioClip(AUDIOS.UI.ui_relic_cut.id)
			if callback then
				callback(function ()
					self:SetIsControllable(true)
				end)
			end
		end)
	}))
	-- self.tempCardLayer:addChild(display.newLayer(toNodePos.x, toNodePos.y, {ap = display.CENTER, color = cc.c4b(), size = cellSize}))
end

function ExploreSystemChangeTeamScene:GetIsControllable()
	return self.isControllable_
end
function ExploreSystemChangeTeamScene:SetIsControllable(isControllable)
	self.isControllable_ = checkbool(isControllable)
	self.gridView:setDragable(self.isControllable_)
end


--[[
注销信号
--]]
function ExploreSystemChangeTeamScene:UnRegistSignal()
	
	appFacadeIns:UnRegistObserver(CLOSE_CHANGE_TEAM_SCENE, self)
	appFacadeIns:UnRegistObserver(REFRESH_CARD_LIST, self)
	appFacadeIns:UnRegistObserver(UNEQUIP_A_AVATAR, self)
	appFacadeIns:UnRegistObserver(SATISFY_TEAM_CHANGE_CONDITION, self)
	appFacadeIns:UnRegistObserver(VIEW_CONTROLLABLE, self)
	
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

function ExploreSystemChangeTeamScene:onCleanup()
	-- 注销信号
	self:UnRegistSignal()
	exploreSystemMgr:setRecommedCacheCards()
end
return ExploreSystemChangeTeamScene