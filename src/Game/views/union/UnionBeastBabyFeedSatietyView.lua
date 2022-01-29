--[[
喂食神兽幼崽层 ------> !!! waring !! can not be common
@params {
	targetNode cc.node 校准的目标节点
	foodsData list 需要显示的菜品数据 {
		id 菜品id
		unlockFoodStyle 解锁了该菜系
		unlockFoodRecipe 解锁了该菜谱
		amount 数量
		gradeId 菜谱等级
		favor 是否是喜欢的菜
	}
}
--]]
local UnionBeastBabyFeedSatietyView = class('UnionBeastBabyFeedSatietyView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.union.UnionBeastBabyFeedSatietyView'
	node:enableNodeEvents()
	return node
end)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
------------ import ------------

------------ define ------------
local FeedRewardInfo = {
	{goodsId = UNION_CONTRIBUTION_POINT_ID, iconTag = 111, labelTag = 112},
	{goodsId = UNION_POINT_ID, iconTag = 113, labelTag = 114}
}
------------ define ------------

--[[
constructor
--]]
function UnionBeastBabyFeedSatietyView:ctor( ... )
	local args = unpack({...})

	self.targetNode = args.targetNode
	self.foodsData = args.foodsData
	self.leftFeedPetNumber = args.leftFeedPetNumber
	self.feedFavoriteFoodBonus = checknumber(args.feedFavoriteFoodBonus)
	self.equipedFoodInfo = {}

	self:InitUI()

	self:RegistHandler()
	self:ShowSelf()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化界面
--]]
function UnionBeastBabyFeedSatietyView:InitUI()
	local size = display.size
	self:setContentSize(size)

	local eaterBtn = display.newButton(0, 0, {size = size, animate = false})
	display.commonUIParams(eaterBtn, {ap = cc.p(0.5, 0.5), po = cc.p(
		size.width * 0.5,
		size.height * 0.5
	)})
	self:addChild(eaterBtn, 99)

	local eaterLayer = display.newLayer(0, 0, {size = size, color = cc.c4b(0, 0, 0, 0), animate = false, enable = true, cb = function (sender)
		PlayAudioByClickClose()
		AppFacade.GetInstance():DispatchObservers('HIDE_UNION_FEED_SATIETY')
		-- self:HideSelf()
	end})
	display.commonUIParams(eaterLayer, {ap = cc.p(0.5, 0.5), po = cc.p(size.width * 0.5, size.height * 0.5)})
	self:addChild(eaterLayer)

	-- 顶部食物栏
	local topFoodBg = display.newImageView(_res('ui/union/beastbaby/guild_pet_feed_bg_greens.png'), 0, 0)
	local topFoodLayer = display.newLayer(0, 0, {size = topFoodBg:getContentSize()})
	display.commonUIParams(topFoodLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
		size.width * 0.5,
		size.height * 0.5 + self.targetNode.viewData.innerbgsize.height * 0.5 - topFoodBg:getContentSize().height * 0.5 - 15
	)})
	self:addChild(topFoodLayer)

	local topeaterLayer = display.newLayer(0, 0, {size = topFoodLayer:getContentSize(), color = cc.c4b(0, 0, 0, 0), animate = false, enable = true})
	display.commonUIParams(topeaterLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
		topFoodLayer:getContentSize().width * 0.5,
		topFoodLayer:getContentSize().height * 0.5
	)})
	topFoodLayer:addChild(topeaterLayer)

	display.commonUIParams(topFoodBg, {po = cc.p(
		topFoodLayer:getContentSize().width * 0.5,
		topFoodLayer:getContentSize().height * 0.5
	)})
	topFoodLayer:addChild(topFoodBg)

	local topFoodLabel = display.newLabel(0, 0, fontWithColor('3', {text = __('选择菜品喂食')}))
	display.commonUIParams(topFoodLabel, {po = utils.getLocalCenter(topFoodBg)})
	topFoodBg:addChild(topFoodLabel)

	-- 奖励预览栏
	local rewardAmount = #FeedRewardInfo
	local leftRewardNode = nil
	local topRewardNodes = {}

	for i = rewardAmount, 1, -1 do
		local rinfo_ = FeedRewardInfo[i]
		local rewardBg = display.newButton(0, 0, {n = _res('ui/common/common_btn_huobi_2.png')})
		display.commonUIParams(rewardBg, {po = cc.p(
			topFoodLayer:getContentSize().width - 25 + ((0.5 - i) * (rewardBg:getContentSize().width + 20)),
			-rewardBg:getContentSize().height + 20
		)})
		topFoodLayer:addChild(rewardBg)

		if nil == leftRewardNode then
			leftRewardNode = rewardBg
		end

		local icon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(rinfo_.goodsId)), 0, 0)
		display.commonUIParams(icon, {po = cc.p(
			0,
			rewardBg:getContentSize().height * 0.5
		)})
		icon:setScale(0.3)
		rewardBg:addChild(icon)

		local label = display.newLabel(0, 0, fontWithColor('14', {text = 8888, fontSize = 22}))
		display.commonUIParams(label, {po = cc.p(
			utils.getLocalCenter(rewardBg).x - 15,
			utils.getLocalCenter(rewardBg).y
		)})
		rewardBg:addChild(label)

		topRewardNodes[tostring(rinfo_.goodsId)] = {
			node = rewardBg,
			icon = icon,
			label = label
		}
	end

	local topRewardLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('可获得:'), fontSize = 22}))
	display.commonUIParams(topRewardLabel, {ap = cc.p(1, 0.5), po = cc.p(
		leftRewardNode:getPositionX() - leftRewardNode:getContentSize().width * 0.5 - 25,
		leftRewardNode:getPositionY()
	)})
	topFoodLayer:addChild(topRewardLabel)

	-- 底部菜单栏
	local foodBgSize = cc.size(display.width, display.height * 0.5 - 100)
	local bottomLayer = display.newLayer(0, 0, {size = foodBgSize})
	display.commonUIParams(bottomLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
		size.width * 0.5,
		foodBgSize.height * 0.5
	)})
	self:addChild(bottomLayer)

	local bottomeaterLayer = display.newLayer(0, 0, {size = foodBgSize, color = cc.c4b(0, 0, 0, 0), animate = false, enable = true})
	display.commonUIParams(bottomeaterLayer, {po = cc.p(
		topFoodLayer:getContentSize().width * 0.5,
		topFoodLayer:getContentSize().height * 0.5
	)})
	bottomLayer:addChild(bottomeaterLayer)

	local foodBg = display.newImageView(_res('ui/common/pvp_select_bg_allcard.png'), 0, 0, {scale9 = true, size = foodBgSize})
	display.commonUIParams(foodBg, {po = cc.p(
		foodBgSize.width * 0.5,
		foodBgSize.height * 0.5
	)})
	bottomLayer:addChild(foodBg)

	-- 计算列表大小
	local col = 5
	local gridViewCellSize = cc.size(240, 105)
	local gridViewSize = cc.size(gridViewCellSize.width * col, foodBgSize.height - 82)
	local gridViewBgSize = cc.size(gridViewSize.width + 2, gridViewSize.height + 2)
	local paddingX = math.max(display.SAFE_L, (foodBgSize.width - gridViewBgSize.width) * 0.5)

	-- 养育记录按钮
	local devLogBtn = display.newButton(0, 0,
		{n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'),ap = display.LEFT_CENTER , scal9 = true , cb = handler(self, self.FeedLogBtnClickHandler)})
	display.commonLabelParams(devLogBtn, fontWithColor('9', {text = __('养育记录') , paddingW = 10}))
	display.commonUIParams(devLogBtn, {po = cc.p(
		paddingX  + 10,
		foodBgSize.height - devLogBtn:getContentSize().height * 0.5 - 20
	)})

	bottomLayer:addChild(devLogBtn, 10)

	-- 喜欢的菜品
	local likeStar = display.newNSprite(_res('ui/common/card_love_feed_ico_star.png'), 0, 0)
	display.commonUIParams(likeStar, {po = cc.p(
		devLogBtn:getPositionX() + devLogBtn:getContentSize().width  + 25,
		devLogBtn:getPositionY()
	)})
	bottomLayer:addChild(likeStar, 10)

	local likeLabel = display.newLabel(0, 0, fontWithColor('5', {text = __('今日喜欢的菜品')}))
	display.commonUIParams(likeLabel, {ap = cc.p(0, 0.5), po = cc.p(
		likeStar:getPositionX() + likeStar:getContentSize().width * 0.5 + 5,
		likeStar:getPositionY()
	)})
	bottomLayer:addChild(likeLabel, 10)

	local likeHintBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_tips.png'), cb = handler(self, self.FavorFoodHintBtnClickHandler)})
	display.commonUIParams(likeHintBtn, {po = cc.p(
		likeLabel:getPositionX() + display.getLabelContentSize(likeLabel).width + likeHintBtn:getContentSize().width * 0.5 + 5,
		likeLabel:getPositionY()
	)})
	bottomLayer:addChild(likeHintBtn, 10)

	-- 投食按钮
	local feedBtnBg = display.newNSprite(_res('ui/union/beastbaby/guild_pet_bg_eat_food.png'), 0, 0)
	display.commonUIParams(feedBtnBg, {po = cc.p(
		foodBgSize.width - paddingX - feedBtnBg:getContentSize().width * 0.5 - 15,
		foodBgSize.height - feedBtnBg:getContentSize().height * 0.5 - 12
	)})
	bottomLayer:addChild(feedBtnBg, 10)

	local feedBtn = display.newButton(0, 0, {n = _res('ui/iceroom/refresh_main_ico_eat_food.png'), cb = handler(self, self.FeedBtnClickHandler)})
	display.commonUIParams(feedBtn, {po = cc.p(
		feedBtnBg:getPositionX(),
		feedBtnBg:getPositionY() - feedBtnBg:getContentSize().height * 0.5 + feedBtn:getContentSize().height * 0.5 + 5
	)})
	bottomLayer:addChild(feedBtn, 11)

	local feedBtnLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('投食')}))
	display.commonUIParams(feedBtnLabel, {po = cc.p(
		feedBtn:getContentSize().width * 0.5,
		feedBtn:getContentSize().height * 0.5 - 25
	)})
	feedBtn:addChild(feedBtnLabel)

	-- 剩余数量
	local feedAmountLabel = display.newLabel(0, 0, fontWithColor('14', {text = '88/88'}))
	display.commonUIParams(feedAmountLabel, {ap = cc.p(1, 0.5), po = cc.p(
		feedBtnBg:getPositionX() - feedBtnBg:getContentSize().width * 0.5 - 5,
		feedBtnBg:getPositionY()
	)})
	bottomLayer:addChild(feedAmountLabel, 10)

	local feedLabel = display.newLabel(0, 0, fontWithColor('5', {text = __('今日剩余投食数量:')}))
	display.commonUIParams(feedLabel, {ap = cc.p(1, 0.5), po = cc.p(
		feedAmountLabel:getPositionX() - display.getLabelContentSize(feedAmountLabel).width - 10,
		feedAmountLabel:getPositionY()
	)})
	bottomLayer:addChild(feedLabel, 10)

	-- 菜品gridview
	local gridViewBg = display.newImageView(_res('ui/common/common_bg_goods.png'), 0, 0,
		{size = gridViewBgSize, scale9 = true})
	display.commonUIParams(gridViewBg, {po = cc.p(
		foodBgSize.width * 0.5,
		gridViewBgSize.height * 0.5 + 5
	)})
	bottomLayer:addChild(gridViewBg, 11)

	local gridView = CGridView:create(gridViewSize)
	gridView:setAnchorPoint(cc.p(0.5, 0.5))
	gridView:setPosition(cc.p(
		gridViewBg:getPositionX(),
		gridViewBg:getPositionY()
	))
	bottomLayer:addChild(gridView, 12)
	-- gridView:setBackgroundColor(cc.c4b(178, 63, 88, 100))

	gridView:setCountOfCell(0)
	gridView:setColumns(col)
	gridView:setSizeOfCell(gridViewCellSize)
	gridView:setAutoRelocate(false)
	gridView:setBounceable(false)
	gridView:setDataSourceAdapterScriptHandler(handler(self, self.GridViewDataAdapter))

	self.eaterBtn = eaterBtn
	self.topFoodLayer = topFoodLayer
	self.topFoodBg = topFoodBg
	self.topFoodLabel = topFoodLabel
	self.gridView = gridView
	self.equipedFoodNodes = {}
	self.feedAmountLabel = feedAmountLabel
	self.feedLabel = feedLabel
	self.topRewardLabel = topRewardLabel
	self.topRewardNodes = topRewardNodes
	self.bottomLayer = bottomLayer

	self:RefreshByFoodsData(self.foodsData)
	self:RefreshLeftFeedAmount()
	self:RefreshTopRewardPreview()
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
data adapter
--]]
function UnionBeastBabyFeedSatietyView:GridViewDataAdapter(c, i)
	local cell = c
	local index = i + 1

	local cellSize = self.gridView:getSizeOfCell()
	local foodData = self:GetFoodDataByIndex(index)
	local leftAmount = self:GetLeftFoodAmountByIndex(index)

	local bg = nil
	local splitLine = nil
	local foodIcon = nil
	local amountLabel = nil
	local gradeLabel = nil
	local favorIcon = nil
	local lockCover = nil
	local lockLabel = nil

	if nil == cell then
		cell = CGridViewCell:new()
		cell:setContentSize(cellSize)

		local btn = display.newButton(0, 0, {size = cellSize, cb = handler(self, self.FoodCellClickHandler)})
		display.commonUIParams(btn, {po = cc.p(
			cellSize.width * 0.5,
			cellSize.height * 0.5
		)})
		cell:addChild(btn)

		bg = display.newImageView(_res('ui/union/beastbaby/guild_pet_feed_bg_goods_default.png'), 0, 0)
		display.commonUIParams(bg, {po = cc.p(
			cellSize.width * 0.5,
			cellSize.height * 0.5
		)})
		cell:addChild(bg)
		bg:setTag(3)

		splitLine = display.newNSprite(_res('ui/union/beastbaby/guild_pet_feed_ico_goods_line.png'), 0, 0)
		display.commonUIParams(splitLine, {po = cc.p(
			bg:getPositionX(),
			bg:getPositionY()
		)})
		cell:addChild(splitLine, 1)
		splitLine:setTag(5)

		local foodIconScale = 0.55
		foodIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(checkint(foodData.id))))
		display.commonUIParams(foodIcon, {po = cc.p(
			splitLine:getPositionX() - bg:getContentSize().width * 0.25,
			splitLine:getPositionY() + 5
		)})
		foodIcon:setScale(foodIconScale)
		cell:addChild(foodIcon, 1)
		foodIcon:setTag(7)

		amountLabel = display.newLabel(0, 0, fontWithColor('14', {text = tostring(foodData.amount), fontSize = 22}))
		display.commonUIParams(amountLabel, {ap = cc.p(0.5, 0), po = cc.p(
			foodIcon:getPositionX(),
			bg:getPositionY() - bg:getContentSize().height * 0.5
		)})
		cell:addChild(amountLabel, 2)
		amountLabel:setTag(9)

		gradeLabel = display.newNSprite(_res(string.format('ui/home/kitchen/balance_ico_%d.png', foodData.gradeId)), 0, 0)
		display.commonUIParams(gradeLabel, {po = cc.p(
			20,
			bg:getContentSize().height - 10
		)})
		gradeLabel:setScale(0.5)
		cell:addChild(gradeLabel, 5)
		gradeLabel:setTag(11)

		favorIcon = display.newNSprite(_res('ui/common/card_love_feed_ico_star.png'), 0, 0)
		display.commonUIParams(favorIcon, {po = cc.p(
			bg:getPositionX() + bg:getContentSize().width * 0.5 - 15,
			bg:getPositionY() + bg:getContentSize().height * 0.5 - 15
		)})
		cell:addChild(favorIcon, 5)
		favorIcon:setTag(13)

		local iconScale = 0.25
		for i,v in ipairs(FeedRewardInfo) do
			local icon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(v.goodsId)), 0, 0)
			icon:setScale(iconScale)
			display.commonUIParams(icon, {po = cc.p(
				splitLine:getPositionX() + icon:getContentSize().width * 0.5 * iconScale + 5,
				splitLine:getPositionY() + (i - 0.5 - #FeedRewardInfo * 0.5) * (35)
			)})
			cell:addChild(icon, 2)
			icon:setTag(v.iconTag)

			local label = display.newLabel(0, 0, fontWithColor('14', {text = 8888, fontSize = 22}))
			display.commonUIParams(label, {ap = cc.p(0, 0.5), po = cc.p(
				icon:getPositionX() + icon:getContentSize().width * iconScale * 0.5,
				icon:getPositionY()
			)})
			cell:addChild(label, 2)
			label:setTag(v.labelTag)
		end

		lockCover = display.newImageView(_res('ui/union/beastbaby/guild_pet_feed_bg_goods_tips.png'), 0, 0, {scale9 = true , size = cc.size(222,60)})
		display.commonUIParams(lockCover, {po = cc.p(
			bg:getPositionX(),
			bg:getPositionY()
		)})
		cell:addChild(lockCover, 11)
		lockCover:setTag(15)
		local lockCoverSize  = lockCover:getContentSize()
		lockLabel = display.newLabel(0, 0, fontWithColor('18', {text = '测试文字', ap = display.CENTER , w = 200 , ap = display.CENTER ,hAlign = display.TAC }))
		display.commonUIParams(lockLabel, {po = cc.p(lockCoverSize.width/2 , lockCoverSize.height/2)})
		lockCover:addChild(lockLabel)
		lockLabel:setTag(3)
	else
		bg = cell:getChildByTag(3)
		splitLine = cell:getChildByTag(5)
		foodIcon = cell:getChildByTag(7)
		amountLabel = cell:getChildByTag(9)
		gradeLabel = cell:getChildByTag(11)
		favorIcon = cell:getChildByTag(13)
		lockCover = cell:getChildByTag(15)
		lockLabel = lockCover:getChildByTag(3)
	end

	-- 刷新一些信息
	local bgPath = 'ui/union/beastbaby/guild_pet_feed_bg_goods_default.png'
	local showLock = false
	local lockStr = ''

	if 0 < checkint(foodData.amount) then
		-- 有这道菜
		if foodData.favor then
			bgPath = 'ui/union/beastbaby/guild_pet_feed_bg_goods_like.png'
		end
	else
		-- 没有这道菜
		if not foodData.unlockFoodStyle then
			-- 菜系未解锁
			showLock = true
			lockStr = __('菜系未解锁')
			bgPath = 'ui/union/beastbaby/guild_pet_feed_bg_goods_unlock.png'
		elseif not foodData.unlockFoodRecipe then
			-- 菜谱未解锁
			showLock = true
			lockStr = __('菜谱未解锁')
			bgPath = 'ui/union/beastbaby/guild_pet_feed_bg_goods_unlock.png'
		end
	end

	bg:setTexture(_res(bgPath))
	amountLabel:setString(tostring(leftAmount))
	gradeLabel:setTexture(_res(string.format('ui/home/kitchen/balance_ico_%d.png', checkint(foodData.gradeId))))
	favorIcon:setVisible(foodData.favor)
	foodIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(checkint(foodData.id))))

	lockCover:setVisible(showLock)

	--lockLabel:setString(lockStr)
	display.commonLabelParams(lockLabel ,{text = lockStr  })
	splitLine:setVisible(not showLock)
	amountLabel:setVisible(not showLock)
	gradeLabel:setVisible(not showLock)

	local rewardInfo = cardMgr.GetFeedRewardByFoodInfo(checkint(foodData.id), checkint(foodData.gradeId))

	for i,v in ipairs(FeedRewardInfo) do
		local icon = cell:getChildByTag(v.iconTag)
		local label = cell:getChildByTag(v.labelTag)

		icon:setVisible(not showLock)

		label:setVisible(not showLock)
		local value = checknumber(rewardInfo[v.goodsId])
		if foodData.favor then
			value = value * self.feedFavoriteFoodBonus
		end
		label:setString(tostring(value))
	end

	if showLock then
		foodIcon:setPositionX(splitLine:getPositionX())
	else
		foodIcon:setPositionX(splitLine:getPositionX() - bg:getContentSize().width * 0.25)
	end

	cell:setTag(index)

	return cell
end
--[[
根据菜品信息刷新界面
@params foodsData list 菜品信息
--]]
function UnionBeastBabyFeedSatietyView:RefreshByFoodsData(foodsData)
	self.foodsData = foodsData

	self.gridView:setCountOfCell(#self.foodsData)
	self.gridView:reloadData()
end
--[[
刷新一次所有装备菜品位置
--]]
function UnionBeastBabyFeedSatietyView:RefreshAllEquipedFood()
	local foodNodesAmount = #self.equipedFoodNodes
	self.topFoodLabel:setVisible(0 >= foodNodesAmount)

	for i,v in ipairs(self.equipedFoodNodes) do
		display.commonUIParams(v, {ap = cc.p(0.5, 0.5), po = cc.p(
			self.topFoodLayer:getContentSize().width * 0.5 + (i - 0.5 - foodNodesAmount * 0.5) * (v:getContentSize().width + 10),
			self.topFoodLayer:getContentSize().height * 0.5
		)})
	end
end
--[[
刷新顶部奖励预览
--]]
function UnionBeastBabyFeedSatietyView:RefreshTopRewardPreview()
	if 0 >= #self.equipedFoodNodes then
		-- 没有选择任何菜品
		self.topRewardLabel:setVisible(false)
		for k,v in pairs(self.topRewardNodes) do
			v.node:setVisible(false)
		end
	else
		-- 刷新奖励预览
		self.topRewardLabel:setVisible(true)
		for k,v in pairs(self.topRewardNodes) do
			v.node:setVisible(true)
		end

		local totalUnionPoint = 0
		local totalUnionConPoint = 0
		for i,v in ipairs(self.equipedFoodNodes) do
			local index = v:getTag()
			local foodData = self:GetFoodDataByIndex(index)
			if nil ~= foodData then
				local foodId = checkint(foodData.id)
				local gradeId = checkint(foodData.gradeId)
				local equipedFoodAmount = self:GetEquipedFoodAmount(foodId)
				local rewardInfo = cardMgr.GetFeedRewardByFoodInfo(foodId, gradeId)

				local multi = foodData.favor and self.feedFavoriteFoodBonus or 1

				totalUnionPoint = totalUnionPoint + (rewardInfo[UNION_POINT_ID] * equipedFoodAmount * multi)
				totalUnionConPoint = totalUnionConPoint + (rewardInfo[UNION_CONTRIBUTION_POINT_ID] * equipedFoodAmount * multi)
			end
		end

		self.topRewardNodes[tostring(UNION_POINT_ID)].label:setString(totalUnionPoint)
		self.topRewardNodes[tostring(UNION_CONTRIBUTION_POINT_ID)].label:setString(totalUnionConPoint)
	end
end
--[[
根据剩余菜品数刷新界面
@params leftAmount int 剩余菜品数
@params maxAmount int 最大菜品数
--]]
function UnionBeastBabyFeedSatietyView:RefreshLeftFeedAmountForce(leftAmount, maxAmount)
	self.leftFeedPetNumber = leftAmount
	self.feedAmountLabel:setString(string.format('%d/%d', leftAmount, maxAmount))
	self.feedLabel:setPositionX(self.feedAmountLabel:getPositionX() - display.getLabelContentSize(self.feedAmountLabel).width - 10)
end
--[[
刷新剩余菜品数
--]]
function UnionBeastBabyFeedSatietyView:RefreshLeftFeedAmount()
	local equipedTotalAmount = self:GetCurrentFeedAmount()
	self.feedAmountLabel:setString(string.format('%d/%d', self.leftFeedPetNumber - equipedTotalAmount, CommonUtils.getVipTotalLimitByField('unionFeedNum')))
	self.feedLabel:setPositionX(self.feedAmountLabel:getPositionX() - display.getLabelContentSize(self.feedAmountLabel).width - 10)
end
--[[
喂食行为
@params leftAmount int 剩余数量 
@params maxAmount int 最大数量
@params rewards list 获得的奖励
@params foodsData list 菜品信息
--]]
function UnionBeastBabyFeedSatietyView:DoFeed(leftAmount, maxAmount, rewards, foodsData)
	-- 屏蔽触摸
	self:SetCanTouch(false)

	-- 刷新剩余投食数
	self:RefreshLeftFeedAmountForce(leftAmount, maxAmount)

	-- 刷新缓存的投食信息
	self:ClearEquipedFoodsInfo()

	-- 刷新顶部节点 移动到神兽幼崽身上
	local targetNode = self.targetNode.viewData.avatarShadow
	local targetNodeWorldPos = targetNode:getParent():convertToWorldSpace(cc.p(targetNode:getPositionX(), targetNode:getPositionY() + 25))
	local fixedPos = self.topFoodLayer:convertToNodeSpace(targetNodeWorldPos)

	for i,v in ipairs(self.equipedFoodNodes) do
		v:setEnabled(false)

		local actionSeqTable = {
			cc.DelayTime:create(0.1 * (i - 1)),
			cc.EaseIn:create(cc.Spawn:create(
				cc.MoveTo:create(0.25, cc.p(fixedPos.x, fixedPos.y)),
				cc.ScaleTo:create(0.25, 0)
			), 3),
			cc.RemoveSelf:create()
		}
		if i == #self.equipedFoodNodes then
			table.insert(actionSeqTable, cc.CallFunc:create(function ()
				self:DoFeedOver(rewards)
			end))
		end
		local actionSeq = cc.Sequence:create(actionSeqTable)
		v:runAction(actionSeq)
		
	end
	self.equipedFoodNodes = {}
	-- 刷新一次顶部提示
	self:RefreshAllEquipedFood()
	self:RefreshTopRewardPreview()

	-- 刷新一次列表中道具
	self:RefreshByFoodsData(foodsData)
end
--[[
喂食行为结束
@params rewards list 获得的奖励
--]]
function UnionBeastBabyFeedSatietyView:DoFeedOver(rewards)
	self:SetCanTouch(false)

	-- 延迟2s弹奖励
	local actionSeq = cc.Sequence:create(
		cc.DelayTime:create(2),
		cc.CallFunc:create(function ()
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, addBackpack = false})
			self:SetCanTouch(true)
		end)
	)
	self:runAction(actionSeq)

	-- 播放升级spine
	if self.targetNode.ShowSatietyUp then
		self.targetNode:ShowSatietyUp()
	end
end
--[[
显示界面
--]]
function UnionBeastBabyFeedSatietyView:ShowSelf()
	self:SetCanTouch(false)

	self.topFoodLayer:setOpacity(0)
	self.bottomLayer:setPositionY(
		self.bottomLayer:getPositionY() - self.bottomLayer:getContentSize().height * 0.5
	)

	local topActionSeq = cc.Sequence:create(
		cc.FadeTo:create(0.1, 255)
	)
	self.topFoodLayer:runAction(topActionSeq)

	local bottomActionSeq = cc.Sequence:create(
		cc.EaseOut:create(cc.MoveTo:create(0.1, cc.p(
			self.bottomLayer:getPositionX(),
			self.bottomLayer:getContentSize().height * 0.5
		)), 2),
		cc.CallFunc:create(function ()
			self:SetCanTouch(true)
		end)
	)
	self.bottomLayer:runAction(bottomActionSeq)
end
--[[
关闭界面
--]]
function UnionBeastBabyFeedSatietyView:HideSelf()
	self:SetCanTouch(false)

	local topActionSeq = cc.Sequence:create(
		cc.FadeTo:create(0, 0)
	)
	self.topFoodLayer:runAction(topActionSeq)

	local bottomActionSeq = cc.Sequence:create(
		cc.FadeTo:create(0, 0),
		cc.CallFunc:create(function ()
			self:removeFromParent()
		end)
	)
	self.bottomLayer:runAction(bottomActionSeq)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
菜品点击回调
--]]
function UnionBeastBabyFeedSatietyView:FoodCellClickHandler(sender)
	PlayAudioByClickNormal()
	local index = sender:getParent():getTag()
	self:EquipAFood(index)
end
--[[
已装备的菜品点击回调
--]]
function UnionBeastBabyFeedSatietyView:EquipedFoodClickHandler(sender)
	PlayAudioByClickNormal()
	local index = sender:getTag()
	self:UnequipedAFood(index)
end
--[[
根据序号选择一个菜
@params index int 序号
--]]
function UnionBeastBabyFeedSatietyView:EquipAFood(index)
	local foodData = self:GetFoodDataByIndex(index)
	local foodId = checkint(foodData.id)
	local leftAmount = self:GetLeftFoodAmountByIndex(index)

	------------ 检查可行性 ------------
	if 0 >= leftAmount then
		if 0 <= checkint(foodData.amount) then
			-- 被装备完
			app.uiMgr:AddDialog("common.GainPopup", {goodId = foodId})
			-- uiMgr:ShowInformationTips(__('数量不足!!!'))
			return
		elseif not foodData.unlockFoodStyle then
			-- 菜系未解锁
			uiMgr:ShowInformationTips(__('菜系未解锁!!!'))
			return
		elseif not foodData.unlockFoodRecipe then
			-- 菜谱未解锁
			app.uiMgr:AddDialog("common.GainPopup", {goodId = foodId})
			-- uiMgr:ShowInformationTips(__('菜谱未解锁!!!'))
			return
		end
	end

	-- 一次喂食不能超过10种
	if nil == self:GetEquipedFoodInfoByFoodId(foodId) and 10 <= table.nums(self.equipedFoodInfo) then
		uiMgr:ShowInformationTips(__('单次投食不能超过10种菜品!!!'))
		return
	end

	-- 检查剩余可投食菜品数
	local equipedTotalAmount = self:GetCurrentFeedAmount()
	if equipedTotalAmount >= self.leftFeedPetNumber then
		uiMgr:ShowInformationTips(__('剩余喂食数量不足!!!'))
		return
	end
	------------ 检查可行性 ------------

	local node = nil
	for i,v in ipairs(self.equipedFoodNodes) do
		if index == v:getTag() then
			node = v
			break
		end
	end

	if nil == node then
		-- 节点为空 创建一个
		local goodsNodeScale = 0.8
		local goodsNode = require('common.GoodNode').new({
			goodsId = foodId,
			amount = 1,
			showAmount = true
		})
		goodsNode:setScale(goodsNodeScale)
		local goodsNodeSize = cc.size(goodsNode:getContentSize().width * goodsNodeScale, goodsNode:getContentSize().height * goodsNodeScale)

		node = display.newButton(0, 0, {size = goodsNodeSize, cb = handler(self, self.EquipedFoodClickHandler)})
		node:setTag(index)
		self.topFoodLayer:addChild(node, 10)

		display.commonUIParams(goodsNode, {ap = cc.p(0.5, 0.5), po = cc.p(
			goodsNodeSize.width * 0.5,
			goodsNodeSize.height * 0.5
		)})
		goodsNode:setTag(3)
		node:addChild(goodsNode)

		local unequipMark = display.newNSprite(_res('ui/union/beastbaby/guild_pet_ico_delete_food.png'), 0, 0)
		display.commonUIParams(unequipMark, {po = cc.p(
			goodsNodeSize.width - 5,
			goodsNodeSize.height - 5
		)})
		node:addChild(unequipMark, 5)

		table.insert(self.equipedFoodNodes, node)

		-- 刷新一次位置
		self:RefreshAllEquipedFood()
	end

	self:AddEquipedFoodAmount(foodId, 1)

	-- print('here check fuck food amount<<<<<<<<<<<<<<', self:GetEquipedFoodAmount(foodId), foodId)

	local goodsNode = node:getChildByTag(3)
	goodsNode:RefreshSelf({
		goodsId = foodId,
		amount = self:GetEquipedFoodAmount(foodId),
		showAmount = true
	})

	self:RefreshCellLeftAmountByIndex(index)
	self:RefreshLeftFeedAmount()
	self:RefreshTopRewardPreview()
end
--[[
卸下一个菜品
@params index int cell序号
--]]
function UnionBeastBabyFeedSatietyView:UnequipedAFood(index)
	local foodData = self:GetFoodDataByIndex(index)
	local foodId = checkint(foodData.id)

	local node = nil
	local nodeIdx = nil
	for i,v in ipairs(self.equipedFoodNodes) do
		if index == v:getTag() then
			node = v
			nodeIdx = i
			break
		end
	end

	if nil == node then
		-- 如果节点不存在 表示出现了逻辑错误
		print('\n\n\n*************here find a logic error : can not find the node but you want to unequip it<<<<<<<<<<<<,', index)
		return
	end

	self:AddEquipedFoodAmount(foodId, -1)
	local equipedAmount = self:GetEquipedFoodAmount(foodId)
	if 0 >= equipedAmount then
		-- 需要移除该节点
		node:removeFromParent()
		table.remove(self.equipedFoodNodes, nodeIdx)

		-- 刷新一次节点位置
		self:RefreshAllEquipedFood()
	else
		-- 刷新一次数量
		local goodsNode = node:getChildByTag(3)
		goodsNode:RefreshSelf({
			goodsId = foodId,
			amount = equipedAmount,
			showAmount = true
		})
	end

	self:RefreshCellLeftAmountByIndex(index)
	self:RefreshLeftFeedAmount()
	self:RefreshTopRewardPreview()
end
--[[
根据序号刷新cell道具数量
@params index int 序号
--]]
function UnionBeastBabyFeedSatietyView:RefreshCellLeftAmountByIndex(index)
	local cell = self.gridView:cellAtIndex(index - 1)
	if nil ~= cell then
		local amountLabel = cell:getChildByTag(9)
		amountLabel:setString(self:GetLeftFoodAmountByIndex(index))
	end
end
--[[
投食按钮回调
--]]
function UnionBeastBabyFeedSatietyView:FeedBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local data = {}
	for k,v in pairs(self.equipedFoodInfo) do
		data[tostring(v.foodId)] = checkint(v.equipedAmount)
	end

	AppFacade.GetInstance():DispatchObservers('FEED_BEAST_BABY', data)
end
--[[
清空选中的菜
--]]
function UnionBeastBabyFeedSatietyView:ClearEquipedFoods()
	------------ data ------------
	self:ClearEquipedFoodsInfo()
	------------ data ------------

	------------ view ------------
	for i,v in ipairs(self.equipedFoodNodes) do
		-- 刷新一次cell中的数量
		local index = v:getTag()
		self:RefreshCellLeftAmountByIndex(index)
		v:removeFromParent()
	end
	self.equipedFoodNodes = {}

	-- 刷新一次剩余投食数量
	self:RefreshLeftFeedAmount()
	-- 刷新一次顶部提示
	self:RefreshAllEquipedFood()
	self:RefreshTopRewardPreview()
	------------ view ------------
end
--[[
喂食记录按钮回调
--]]
function UnionBeastBabyFeedSatietyView:FeedLogBtnClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('SHOW_UNION_FEED_LOG')
end
--[[
今日喜欢菜品按钮回调
--]]
function UnionBeastBabyFeedSatietyView:FavorFoodHintBtnClickHandler(sender)
	PlayAudioByClickNormal()
	uiMgr:ShowInformationTipsBoard({targetNode = sender, title = __('喂养规则'), descr = cardMgr.GetBeastBabyFavorFoodDescr(), type = 5})
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- signal begin --
---------------------------------------------------
--[[
信号
--]]
function UnionBeastBabyFeedSatietyView:RegistHandler()
	------------ 喂食行为 ------------
	AppFacade.GetInstance():RegistObserver('UNION_BEASTBABY_DO_FEED', mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		self:DoFeed(checkint(data.leftFeedAmount), checkint(data.maxFeedAmount))
	end, self))
	------------ 喂食行为 ------------
end
function UnionBeastBabyFeedSatietyView:UnregistHandler()

end
---------------------------------------------------
-- signal end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据序号获取菜品信息
@params index int 序号
--]]
function UnionBeastBabyFeedSatietyView:GetFoodDataByIndex(index)
	return self.foodsData[index]
end
--[[
根据菜品id获取装备了的菜品信息
@params foodId int 菜品id
@return equipedFoodInfo table 装备了的菜品信息 {
	foodId int 菜品id
	equipedAmount int 装备了的数量
}
--]]
function UnionBeastBabyFeedSatietyView:GetEquipedFoodInfoByFoodId(foodId)
	return self.equipedFoodInfo[tostring(foodId)]
end
function UnionBeastBabyFeedSatietyView:SetEquipedFoodInfoByFoodId(foodId, info)
	self.equipedFoodInfo[tostring(foodId)] = info
end
function UnionBeastBabyFeedSatietyView:AddEquipedFoodAmount(foodId, delta)
	if nil == self:GetEquipedFoodInfoByFoodId(foodId) and 0 <= delta then
		local foodInfo = {
			foodId = foodId,
			equipedAmount = 1
		}
		self:SetEquipedFoodInfoByFoodId(foodId, foodInfo)
	else
		local amount_ = math.max(0, self:GetEquipedFoodInfoByFoodId(foodId).equipedAmount + delta)
		if 0 < amount_ then
			self.equipedFoodInfo[tostring(foodId)].equipedAmount = amount_
		else
			self.equipedFoodInfo[tostring(foodId)] = nil
		end
	end
end
function UnionBeastBabyFeedSatietyView:GetEquipedFoodAmount(foodId)
	if nil ~= self:GetEquipedFoodInfoByFoodId(foodId) then
		return self:GetEquipedFoodInfoByFoodId(foodId).equipedAmount
	end
	return 0
end
--[[
清空选中的菜的数据
--]]
function UnionBeastBabyFeedSatietyView:ClearEquipedFoodsInfo()
	self.equipedFoodInfo = {}
end
--[[
根据菜品id获取菜品信息
@params id int 菜品id
--]]
function UnionBeastBabyFeedSatietyView:GetFoodDataById(id)
	for i,v in ipairs(self.foodsData) do
		if checkint(id) == checkint(v.id) then
			return v
		end
	end
	return nil
end
--[[
根据序号获取当前剩余的菜品数量
@params index int 序号
@return amount int 数量
--]]
function UnionBeastBabyFeedSatietyView:GetLeftFoodAmountByIndex(index)
	local foodData = self:GetFoodDataByIndex(index)
	local foodId = checkint(foodData.id)
	if nil == foodData then
		return 0
	end
	-- 原始数量
	local oriAmount = checkint(foodData.amount)
	-- 装备的数量
	local equipedAmount = 0
	if nil ~= self:GetEquipedFoodInfoByFoodId(foodId) then
		-- 如果装备了 减去装备的数量
		equipedAmount = checkint(self:GetEquipedFoodInfoByFoodId(foodId).equipedAmount)
	end

	return math.max(0, oriAmount - equipedAmount)
end
--[[
获取当前已选择的投食数量
--]]
function UnionBeastBabyFeedSatietyView:GetCurrentFeedAmount()
	local amount = 0
	for k,v in pairs(self.equipedFoodInfo) do
		amount = amount + checkint(v.equipedAmount)
	end
	return amount
end
--[[
是否可以点击
--]]
function UnionBeastBabyFeedSatietyView:CanTouch()
	return not self.eaterBtn:isVisible()
end
function UnionBeastBabyFeedSatietyView:SetCanTouch(can)
	self.eaterBtn:setVisible(not can)
end
---------------------------------------------------
-- get set end --
---------------------------------------------------
function UnionBeastBabyFeedSatietyView:onCleanup()
	print('here >>>UnionBeastBabyFeedSatietyView<<< onCleanup')
	self:UnregistHandler()
end

return UnionBeastBabyFeedSatietyView
