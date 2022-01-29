--[[
超得抽卡主场景
@params {
	parentNode cc.node 父节点
}
--]]
local GameScene = require( "Frame.GameScene" )
local CapsuleSuperGetView = class("CapsuleSuperGetView", GameScene)

------------ import ------------
------------ import ------------

------------ define ------------
-- 一行三列
local COL_AMOUNT = 3

-- 地图大小
local ButtonBgSize = nil
------------ define ------------

--[[
constructor
--]]
function CapsuleSuperGetView:ctor(...)
	local args = unpack({...})

	self.parentNode = args.parentNode
	self.activityId = args.activityId

	self:InitUI()
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function CapsuleSuperGetView:InitUI()
	local size = self.parentNode:getContentSize()
	self:setContentSize(size)
	display.commonUIParams(self, {ap = cc.p(0.5, 0.5), po = cc.p(size.width * 0.5, size.height * 0.5)})

	local function CreateView()
		local buttonBg = display.newImageView(_res('ui/home/capsuleNew/superGet/summon_activity_bg_.png'), 0, 0, {scale9 = true})
		if nil == ButtonBgSize then
			ButtonBgSize = buttonBg:getContentSize()
		end
		display.commonUIParams(buttonBg, {ap = cc.p(0.5, 0), po = cc.p(size.width * 0.5, size.height * 0.015)})
		self:addChild(buttonBg)

		return {
			buttonBg = buttonBg,
			poolCells = {}
		}
	end

	xTry(function ( )
		self.viewData = CreateView()
	end, __G__TRACKBACK__)
end
--[[
获取一个卡池按钮
@params poolData map {
	poolId: int 卡池ID.
	icon: list 图标.
}
@params poolConsumeData map 消耗信息
--]]
function CapsuleSuperGetView:GetAPoolCell(poolData, poolConsumeData)
	-- 卡池按钮
	local poolButton = display.newButton(0, 0, {
		n = _res('ui/common/common_btn_big_orange_2.png'),
		cb = function (sender)
			PlayAudioByClickNormal()
			AppFacade.GetInstance():DispatchObservers('SUPER_GET_DRAW', self:GetSignalParams({poolId = checkint(poolData.poolId)}))
		end
	})

	local buttonSize = poolButton:getContentSize()

	-- 卡池底层
	local poolCellLayer = display.newLayer(0, 0, {size = buttonSize})
	display.commonUIParams(poolButton, {po = utils.getLocalCenter(poolCellLayer)})
	poolCellLayer:addChild(poolButton)

	-- 卡池上文字
	local drawLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('召唤')}))
	display.commonUIParams(drawLabel, {ap = cc.p(0.5, 0), po = cc.p(
		poolButton:getContentSize().width * 0.5,
		poolButton:getContentSize().height * 0.5
	)})
	poolButton:addChild(drawLabel)

	local drawTime = checkint(poolData.time or 1)
	local drawTimeLabel = display.newLabel(0, 0, fontWithColor('14', {text = string.format(__('x%d'), drawTime)}))
	display.commonUIParams(drawTimeLabel, {ap = cc.p(0.5, 1), po = cc.p(
		poolButton:getContentSize().width * 0.5,
		poolButton:getContentSize().height * 0.5
	)})
	poolButton:addChild(drawTimeLabel)

	if isJapanSdk() then
		drawLabel:setVisible(false)
		display.commonLabelParams(drawTimeLabel, fontWithColor('14', {ap = cc.p(0.5, 0.5), po = cc.p(
			poolButton:getContentSize().width * 0.5,
			poolButton:getContentSize().height * 0.5
		), fontSize = 26, hAlign = display.TAC, text = string.fmt(__('召唤\n_num_次'), {_num_ = drawTime})}))
	end

	-- 广告牌信息
	local saleInfoBg = display.newImageView(_res('ui/home/capsuleNew/superGet/summon_bg_tips_special.png'), 0, 0, {scale9 = true})
	local saleInfoBgOriSize = saleInfoBg:getContentSize()
	display.commonUIParams(saleInfoBg, {po = cc.p(
		buttonSize.width * 0.5,
		buttonSize.height + saleInfoBg:getContentSize().height * 0.5 - 5
	)})
	poolCellLayer:addChild(saleInfoBg, 30)

	local arrow = display.newImageView(_res('ui/common/common_bg_tips_horn.png'), 0, 0)
	arrow:setScaleY(-1)
	display.commonUIParams(arrow, {po = cc.p(saleInfoBg:getContentSize().width * 0.5, 7)})
	saleInfoBg:addChild(arrow)

	-- 闪光
	local leftShine = display.newNSprite(_res('ui/home/capsuleNew/superGet/summon_ico_star.png'), 0, 0)
	leftShine:setFlippedX(true)
	saleInfoBg:addChild(leftShine, 20)
	leftShine:setVisible(false)

	local rightShine = display.newNSprite(_res('ui/home/capsuleNew/superGet/summon_ico_star.png'), 0, 0)
	saleInfoBg:addChild(rightShine, 20)
	rightShine:setVisible(false)

	local cellData = {
		poolCellLayer 				= poolCellLayer,
		poolButton 					= poolButton,
		drawLabel 					= drawLabel,
		drawTimeLabel 				= drawTimeLabel,
		saleInfoBg 					= saleInfoBg,
		saleInfoBgOriSize 			= saleInfoBgOriSize,
		arrow 						= arrow,
		leftShine 					= leftShine,
		rightShine 					= rightShine,

		costLabel 					= nil,
		costGoodsIcon 				= nil,
		costGoodsLabel 				= nil,
		saleIcons 					= {},

		RefreshCostInfo 			= function (self, costGoodsId, costGoodsAmount)

			if nil == self.costGoodsIcon then
				local costLabel = display.newLabel(0, 0, fontWithColor('18', {text = __('消耗')}))
				self.poolCellLayer:addChild(costLabel, 5)

				local costGoodsLabel = display.newLabel(0, 0, fontWithColor('14', {text = costGoodsAmount}))
				self.poolCellLayer:addChild(costGoodsLabel, 5)

				local costGoodsIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(costGoodsId)), 0, 0)
				costGoodsIcon:setScale(0.2)
				self.poolCellLayer:addChild(costGoodsIcon, 5)

				-- display.setNodesToNodeOnCenter(self.poolButton, {costGoodsLabel, costGoodsIcon})

				self.costLabel = costLabel
				self.costGoodsLabel = costGoodsLabel
				self.costGoodsIcon = costGoodsIcon
			end

			-- 刷新
			if nil ~= costGoodsId then
				self.costGoodsLabel:setString(tostring(costGoodsAmount))
				self.costGoodsIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(costGoodsId)))
				display.setNodesToNodeOnCenter(self.poolButton, {self.costLabel, self.costGoodsLabel, self.costGoodsIcon}, {spaceW = 2, y = -20})

				self.costLabel:setVisible(true)
				self.costGoodsLabel:setVisible(true)
				self.costGoodsIcon:setVisible(true)

				if isJapanSdk() then
					self.costLabel:setVisible(false)
					display.setNodesToNodeOnCenter(self.poolButton, {self.costGoodsIcon, self.costGoodsLabel}, {y = -20})
				end
			else
				self.costGoodsLabel:setString(tostring(__('无消耗')))
				display.setNodesToNodeOnCenter(self.poolButton, {self.costGoodsLabel}, {y = -20})

				self.costLabel:setVisible(false)
				self.costGoodsLabel:setVisible(true)
				self.costGoodsIcon:setVisible(false)
			end

		end,
		--[[
		@params iconList list {
			iconId: int 图标编号.
			iconTitle: int 图标编号文字.
		}
		--]]
		RefreshSaleInfo 			= function (self, iconList)
			-- 移除老的图标
			for i,v in ipairs(self.saleIcons) do
				v:setVisible(false)
				v:removeFromParent()
			end
			self.saleIcons = {}

			-- 重置广告牌大小
			self.saleInfoBg:setContentSize(self.saleInfoBgOriSize)
			local iconScale = 0.65
			local splitScale = 1
			local x = 0
			local iconAmount = #iconList

			for i, iconInfo in ipairs(iconList) do
				local iconId = checkint(iconInfo.iconId)
				local iconStr = iconInfo.iconTitle
				local iconPath = CardUtils.QUALITY_ICON_PATH_MAP[tostring(iconId)]

				local icon = display.newNSprite(_res(iconPath), 0, 0)
				icon:setScale(iconScale)
				self.saleInfoBg:addChild(icon)
				icon:setTag(3)
				table.insert(self.saleIcons, icon)

				x = x + icon:getContentSize().width * iconScale

				local iconLabel = display.newLabel(0, 0, fontWithColor('14', {text = iconStr}))
				self.saleInfoBg:addChild(iconLabel)
				iconLabel:setTag(5)
				table.insert(self.saleIcons, iconLabel)

				x = x + display.getLabelContentSize(iconLabel).width

				if i < #iconList then
					local iconSplit = display.newNSprite(_res('ui/home/capsuleNew/superGet/summon_ico_line_split.png'))
					iconSplit:setScale(splitScale)
					self.saleInfoBg:addChild(iconSplit)
					iconSplit:setTag(7)
					table.insert(self.saleIcons, iconSplit)

					x = x + iconSplit:getContentSize().width * splitScale
				end

			end

			-- 修正广告牌大小
			local paddingX = 10
			if x >= self.saleInfoBg:getContentSize().width + paddingX * 2 then
				self.saleInfoBg:setContentSize(cc.size(
					x + paddingX * 2,
					self.saleInfoBgOriSize.height
				))
			end

			-- 修正箭头位置
			arrow:setPositionX(self.saleInfoBg:getContentSize().width * 0.5)

			-- 修正广告牌内部图标位置
			if 1 == iconAmount then
				-- 只有一个 直接居中
				display.setNodesToNodeOnCenter(self.saleInfoBg, self.saleIcons)

				-- 显示闪光
				self.leftShine:stopAllActions()
				self.rightShine:stopAllActions()

				self.leftShine:setOpacity(255)
				self.rightShine:setOpacity(255)

				display.commonUIParams(self.leftShine, {ap = cc.p(0, 0.5), po = cc.p(
					-10,
					self.saleInfoBg:getContentSize().height * 0.5
				)})
				self.leftShine:setVisible(true)
				display.commonUIParams(self.rightShine, {ap = cc.p(1, 0.5), po = cc.p(
					self.saleInfoBg:getContentSize().width + 10,
					self.saleInfoBg:getContentSize().height * 0.5
				)})
				self.rightShine:setVisible(true)

				local actionSeq = cc.RepeatForever:create(cc.Sequence:create(
					cc.FadeTo:create(1, 78),
					cc.FadeTo:create(1, 255),
					cc.DelayTime:create(2)
				))

				self.leftShine:runAction(actionSeq:clone())
				self.rightShine:runAction(actionSeq:clone())
			else
				-- 隐藏闪光
				self.leftShine:setVisible(false)
				self.rightShine:setVisible(false)

				self.leftShine:stopAllActions()
				self.rightShine:stopAllActions()

				local fixedX = (self.saleInfoBg:getContentSize().width - x) * 0.5
				local fixedY = self.saleInfoBg:getContentSize().height * 0.5
				for i, icon in ipairs(self.saleIcons) do

					if 3 == icon:getTag() then
						display.commonUIParams(icon, {ap = cc.p(0, 0.5), po = cc.p(
							fixedX,
							fixedY
						)})

						fixedX = fixedX + icon:getContentSize().width * iconScale
					elseif 5 == icon:getTag() then
						display.commonUIParams(icon, {ap = cc.p(0, 0.5), po = cc.p(
							fixedX,
							fixedY
						)})

						fixedX = fixedX + display.getLabelContentSize(icon).width
					elseif 7 == icon:getTag() then
						display.commonUIParams(icon, {ap = cc.p(0, 0.5), po = cc.p(
							fixedX,
							fixedY
						)})

						fixedX = fixedX + icon:getContentSize().width * splitScale
					end

				end
			end


		end

	}

	return cellData
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
刷新界面
@params pool 卡池信息 list
@params poolConsume 卡池消耗 map
--]]
function CapsuleSuperGetView:RefreshUI(pool, poolConsume)
	-- 刷新地图大小
	self:RefreshPoolBg(#pool)
	-- 刷新卡池按钮
	self:RefreshPool(pool, poolConsume)
end
--[[
刷新底图大小
@params poolAmount 卡池数量
--]]
function CapsuleSuperGetView:RefreshPoolBg(poolAmount)
	local row = math.ceil(poolAmount / COL_AMOUNT)

	self.viewData.buttonBg:setContentSize(cc.size(ButtonBgSize.width, (ButtonBgSize.height + 20) * row))
end
--[[
刷新卡池按钮
@params pool 卡池信息 list
@params poolConsume 卡池消耗 map
--]]
function CapsuleSuperGetView:RefreshPool(pool, poolConsume)
	local poolId = nil
	local poolCell = nil
	local poolAmount = #pool

	local bgPos = cc.p(
		self.viewData.buttonBg:getPositionX(),
		self.viewData.buttonBg:getPositionY()
	)
	local bgLTPos = cc.p(
		bgPos.x - self.viewData.buttonBg:getContentSize().width * 0.5,
		bgPos.y + self.viewData.buttonBg:getContentSize().height
	)
	local cellWidth = (ButtonBgSize.width - 50 * 2) / COL_AMOUNT
	local cellHeight = ButtonBgSize.height + 20

	for poolIndex, poolData in ipairs(pool) do
		poolId = checkint(poolData.poolId)
		poolCell = self:GetPoolCellByPoolIndex(poolIndex)
		local consumeInfo = poolConsume[tostring(poolId)]

		if nil == poolCell then
			-- 获取一个卡池按钮
			poolCell = self:GetAPoolCell(poolData, consumeInfo)
			self:addChild(poolCell.poolCellLayer, 10)
			self:SetPoolCellByPoolIndex(poolIndex, poolCell)
		end

		-- 刷新消耗信息
		poolCell:RefreshCostInfo(consumeInfo.goodsId, consumeInfo.goodsAmount)
		-- 刷新广告牌信息
		poolCell:RefreshSaleInfo(poolData.icon)

		if poolAmount < COL_AMOUNT then

			-- 不足三个一行 居中版式
			local x = bgPos.x + cellWidth * ((poolIndex - 0.5) - poolAmount * 0.5)
			local y = bgLTPos.y - 20 - cellHeight * (1 - 0.5)

			display.commonUIParams(poolCell.poolCellLayer, {ap = cc.p(0.5, 0.5), po = cc.p(x, y)})

		else

			-- 超过三个
			local row = math.ceil(poolIndex / COL_AMOUNT)
			local col = (poolIndex - 1) % COL_AMOUNT + 1
			local x = bgPos.x + cellWidth * ((col - 0.5) - COL_AMOUNT * 0.5)
			local y = bgLTPos.y - 20 - cellHeight * (row - 0.5)

			display.commonUIParams(poolCell.poolCellLayer, {ap = cc.p(0.5, 0.5), po = cc.p(x, y)})

		end

	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取当前活动id
--]]
function CapsuleSuperGetView:GetActivityId()
	return self.activityId
end
function CapsuleSuperGetView:SetActivityId(activityId)
	self.activityId = activityId
end
--[[
封装一次传参
@params params table 参数
--]]
function CapsuleSuperGetView:GetSignalParams(params)
	if nil == params then
		params = {}
	end
	params.activityId = self:GetActivityId()
	return params
end
--[[
根据序号获取卡池cell
@params poolIndex 卡池序号
--]]
function CapsuleSuperGetView:GetPoolCellByPoolIndex(poolIndex)
	return self.viewData.poolCells[poolIndex]
end
function CapsuleSuperGetView:SetPoolCellByPoolIndex(poolIndex, poolCell)
	self.viewData.poolCells[poolIndex] = poolCell
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return CapsuleSuperGetView
