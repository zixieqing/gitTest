--[[
带血条显示的选卡界面
@params table {

	-- 其他参数见SelectCardMemberView

	showCardStatus map 是否显示血量蓝量 {
		------------ pattern 1 ------------
		-- 传字段名 自己去读
		hpFieldName string 当前剩余血量的字段
		energyFieldName string 当前剩余能量的字段
		------------ pattern 1 ------------

		------------ pattern 2 ------------
		-- 传信息 直接用
		cardHpData map 血量信息
		cardEnergyData map 能量信息
		------------ pattern 2 ------------
	}
}
--]]
local SelectCardMemberView = require('common.SelectCardMemberView')
local SelectCardMemberViewWithHp = class('SelectCardMemberViewWithHp', SelectCardMemberView)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function SelectCardMemberViewWithHp:ctor( ... )
	SelectCardMemberView.ctor(self, ...)

	self:RegisterSignal()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化数据
--]]
function SelectCardMemberViewWithHp:InitValue(args)
	-- 初始化卡牌的状态信息
	self:InitCardStatus(args)

	SelectCardMemberView.InitValue(self, args)

	-- 重置卡牌状态消耗的道具信息
	self.costGoodsInfo = args.costGoodsInfo

	-- ui信息
	self.uiLocationInfo.gridViewCellSize = cc.size(143, 163)
end
--[[
初始化卡牌的继承状态信息
@params args 外部传参
--]]
function SelectCardMemberViewWithHp:InitCardStatus(args)
	-- 血量信息
	self.cardHpData = args.showCardStatus.cardHpData
	self.cardEnergyData = args.showCardStatus.cardEnergyData

	-- 字段
	self.hpFieldName = args.showCardStatus.hpFieldName
	self.energyFieldName = args.showCardStatus.energyFieldName
end
--[[
@override
初始化ui
--]]
function SelectCardMemberViewWithHp:InitUI()
	SelectCardMemberView.InitUI(self)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
创建cell
@params index cell index(lua)
@return cell CGridViewCell cell
--]]
function SelectCardMemberViewWithHp:CreateCardCell(index)
	local cardData = self:GetCardDataByListIndex(index)
	local id = checkint(cardData.id)
	local cellSize = self.gridView:getSizeOfCell()

	local cell = CGridViewCell:new()
	cell:setContentSize(cellSize)

	-- 卡牌头像
	local cardHeadNode = require('common.CardHeadNode').new({
		id = checkint(cardData.id),
		showBaseState = true, showActionState = false, showVigourState = false
	})
	local scale = (cellSize.width - 10) / cardHeadNode:getContentSize().width
	cardHeadNode:setScale(scale)
	cardHeadNode:setPosition(cc.p(
		cellSize.width * 0.5,
		cellSize.height - cardHeadNode:getContentSize().height * scale * 0.5 - 5
	))
	cell:addChild(cardHeadNode, 1)
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

	if self.isOpenRecommendState then
		local recommendImg = display.newImageView(_res('ui/common/summer_activity_mvpxiangling_icon.png'), cardHeadNode:getContentSize().width * scale - 10 , cardHeadNode:getContentSize().height * scale - 10)
		cell:addChild(recommendImg, 5)
		recommendImg:setTag(8)
		recommendImg:setVisible(false)
	end
	if self.banListMap then
		local banTextLabel = display.newLabel(cardHeadNode:getPositionX(), cardHeadNode:getPositionY(), {text = __('不可出战'), fontSize = 20, color = '#ffffff'})
		cell:addChild(banTextLabel, 10)
		banTextLabel:setTag(9)
	end

	-- 血量能量信息
	local barBg = display.newImageView(_res('ui/lunatower/lunatower_blood_bg.png'), 0, 0)
	local barBgPos = cc.p(
		cellSize.width * 0.5,
		cardHeadNode:getPositionY() - cardHeadNode:getContentSize().height * 0.5 * scale - barBg:getContentSize().height * 0.5
	)
	display.commonUIParams(barBg, {po = barBgPos})
	cell:addChild(barBg)

	local hpBar = CProgressBar:create(_res('ui/lunatower/lunatower_blood.png'))
	hpBar:setDirection(eProgressBarDirectionLeftToRight)
	hpBar:setPosition(barBgPos)
	cell:addChild(hpBar)
	hpBar:setMaxValue(10000)
	hpBar:setValue(0)
	hpBar:setTag(11)

	local energyBar = CProgressBar:create(_res('ui/lunatower/lunatower_energy.png'))
	energyBar:setDirection(eProgressBarDirectionLeftToRight)
	energyBar:setPosition(barBgPos)
	cell:addChild(energyBar)
	energyBar:setMaxValue(10000)
	energyBar:setValue(0)
	energyBar:setTag(13)

	-- 死亡mark
	local dieMark = display.newSprite(_res('ui/battle/battletagmatch/3v3_fighting_head_ico_die.png'), 0, 0)
	display.commonUIParams(dieMark, {po = cc.p(cellSize.width * 0.5, cellSize.height * 0.5 + 10)})
	cell:addChild(dieMark, 10)
	dieMark:setTag(15)

	-- 卡牌头像上的队伍序号
	local cardMark = display.newImageView()
	display.commonUIParams(cardMark, {ap = display.RIGHT_TOP, po = cc.p(
		cardHeadNode:getContentSize().width - 46,
		cardHeadNode:getContentSize().height - 26
	)})
	cardMark:setScale(scale)
	cardMark:setVisible(false)
	cell:addChild(cardMark, 5)
	cardMark:setTag(99)

	return cell
end
--[[
刷新cell
@params cell CGridViewCell 卡牌cell
@params index cell index(lua)
--]]
function SelectCardMemberViewWithHp:RefreshCardCell(cell, index)
	SelectCardMemberView.RefreshCardCell(self, cell, index)

	local cardData = self:GetCardDataByListIndex(index)
	local id = checkint(cardData.id)

	-- 刷新血量和能量
	local hpPercent = self:GetHpPercentById(id)
	cell:getChildByTag(11):setValue(math.round(hpPercent * 10000))

	if 0 >= hpPercent then
		-- 显示死亡标志
		cell:getChildByTag(5):setVisible(true)
		if not cell:getChildByTag(9):isVisible() then
			cell:getChildByTag(15):setVisible(true)
		else
			cell:getChildByTag(15):setVisible(false)
		end
	else
		cell:getChildByTag(15):setVisible(false)
	end

	local energyPercent = self:GetEnergyPercentById(id)
	cell:getChildByTag(13):setValue(math.round(energyPercent * 10000))
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------

---------------------------------------------------
-- click handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据卡牌数据库id获取卡牌的剩余血量百分比
@params id int 数据库id
@return _ number 剩余血量百分比
--]]
function SelectCardMemberViewWithHp:GetHpPercentById(id)
	if not string.isEmpty(self.hpFieldName) then

		-- 查找卡牌
		local cardData = app.gameMgr:GetCardDataById(id)
		if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
			-- 查找对应字段
			if nil ~= cardData[tostring(self.hpFieldName)] then
				-- 字段正确
				return checknumber(cardData[tostring(self.hpFieldName)])
			else
				-- 字段不正确
				return 0
			end
		end

	elseif nil ~= self.cardHpData then

		return checknumber(self.cardHpData[tostring(id)])

	end

	return 0
end
--[[
根据卡牌数据库id获取卡牌的剩余能量百分比
@params id int 数据库id
@return _ number 剩余血量百分比
--]]
function SelectCardMemberViewWithHp:GetEnergyPercentById(id)
	if not string.isEmpty(self.energyFieldName) then

		-- 查找卡牌
		local cardData = app.gameMgr:GetCardDataById(id)
		if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
			-- 查找对应字段
			if nil ~= cardData[tostring(self.energyFieldName)] then
				-- 字段正确
				return checknumber(cardData[tostring(self.energyFieldName)])
			else
				-- 字段不正确
				return 0
			end
		end

	elseif nil ~= self.cardEnergyData then

		return checknumber(self.cardEnergyData[tostring(id)])

	end

	return 0
end
--[[
@override
判断卡牌是否可以装载
@params id int 卡牌数据库id
@params cardData table 卡牌信息
@return canEquip, waringText bool, string 是否可以, 警告文字
--]]
function SelectCardMemberViewWithHp:CanEquipCard(id, cardData)
	local cardId = nil
	if nil == cardData or 0 == checkint(cardData.cardId) then
		cardData = app.gameMgr:GetCardDataById(id)
	end

	if 0 == checkint(id) or nil == cardData or 0 == checkint(cardData.cardId) then
		return false, __('卡牌不存在')
	end

	cardId = checkint(cardData.cardId)

	if nil ~= self.banListMap and nil ~= self.banListMap[tostring(cardId)] then
		return false, __('卡牌被禁用')
	end

	if 0 >= self:GetHpPercentById(id) then
		return false, __('卡牌已死亡')
	end

	return true
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- signal handler begin --
---------------------------------------------------
--[[
注册信号回调
--]]
function SelectCardMemberViewWithHp:RegisterSignal()
	------------ 刷新卡牌状态 ------------
	AppFacade.GetInstance():RegistObserver('LT_REFRESH_CARD_STATUS', mvc.Observer.new(function (_, signal)
		-- 原地刷新当前列表中的卡牌状态
		local filterCardsAmount = #self.filterCards
		local cell = nil
		for index = 1, filterCardsAmount do
			cell = self.gridView:cellAtIndex(index - 1)
			if nil ~= cell then
				self:RefreshCardCell(cell, index)
			end
		end
	end, self))
	------------ 刷新卡牌状态 ------------
end
--[[
注销信号
--]]
function SelectCardMemberViewWithHp:UnRegistSignal()
	AppFacade.GetInstance():UnRegistObserver('LT_REFRESH_CARD_STATUS', self)
end
---------------------------------------------------
-- signal handler end --
---------------------------------------------------

function SelectCardMemberViewWithHp:onCleanup()
	-- 注销信号
	self:UnRegistSignal() 
end

return SelectCardMemberViewWithHp
