--[[
餐厅信息信息详情view
--]]
local LobbyDetailedInformationView = class('LobbyDetailedInformationView', function ()
	local node = CLayout:create(cc.size(753, 556))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.LobbyDetailedInformationView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local function CreateView( self )
	local size = cc.size(753, 556)
	local view = CLayout:create(size)
	local bg = display.newImageView(_res('ui/common/commcon_bg_text.png'), 0, 8, {ap = cc.p(0, 0), scale9 = true, size = cc.size(753, 546)})
	view:addChild(bg)
	local listSize = cc.size(753, 546)
	local listView = CListView:create(listSize)
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setBounceable(true)
	view:addChild(listView, 10)
	listView:setAnchorPoint(cc.p(0, 0))
	listView:setPosition(cc.p(0, 8))
	return {
		view 			      = view,
		listView			  = listView,
		size                  = size,
	}
end

function LobbyDetailedInformationView:ctor( ... )
	self.args = unpack({...})
	self.viewData_ = CreateView(  )
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
	self:RefreshUI()
end
function LobbyDetailedInformationView:RefreshUI()
	local userInfo = gameMgr:GetUserInfo()
	local viewData = self.viewData_
	local listView = viewData.listView
	viewData.listView:removeAllNodes()
	local size = viewData.size
	-- 餐厅等级
	local rankLayout = CLayout:create(cc.size(size.width, 56))
	listView:insertNodeAtLast(rankLayout)
	--local tipsIcon = display.newButton(25, 28, {n = _res('ui/common/common_btn_tips.png')})
	--rankLayout:addChild(tipsIcon, 10)
	local nameLabel = display.newLabel(10, 28, fontWithColor(6, {text = __('当前餐厅规模：'), ap = cc.p(0, 0.5)}))
	rankLayout:addChild(nameLabel, 10)
	local rankLabel = display.newLabel(200, 28, fontWithColor(11, {text = string.fmt(__('_num_级'), {['_num_'] = gameMgr:GetUserInfo().restaurantLevel}), ap = cc.p(0, 0.5)}))
	rankLayout:addChild(rankLabel, 10)
	local nameLabelSize = display.getLabelContentSize(nameLabel)
	local rankLabelSize = display.getLabelContentSize(rankLabel)
	if rankLabelSize.width +nameLabelSize.width  > 240   then
		local curentScale =  rankLabel:getScale()
		local scale = curentScale * 240 /(rankLabelSize.width +nameLabelSize.width +20)
		rankLabel:setScale(scale)
		nameLabel:setScale(scale)
		rankLabel:setPosition(cc.p(nameLabelSize.width *240 /(rankLabelSize.width +nameLabelSize.width +20)  + 10  , 28 ))
	end

	local rankBtn = display.newButton(355, 28, {n = _res('ui/cards/petNew/team_btn_selection_unused.png')})
	rankLayout:addChild(rankBtn, 10)
	rankBtn:setOnClickScriptHandler(handler(self, self.RankButtonCallbcak))
	display.commonLabelParams(rankBtn, fontWithColor(18, {text = __('排行榜') , reqW = 110}))
	-- 总收入
	local totalGold = 0
	for _,bill in ipairs(userInfo.avatarCacheData.bill) do
		totalGold = totalGold + bill.gold
	end
	local totalRevenueBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_iccome.png'), 746, 28, {ap = cc.p(1, 0.5)})
	rankLayout:addChild(totalRevenueBg, 5)
	local totalRevenueLabel = display.newLabel(534, 28, {text = __('总收入'), fontSize = 20, color = '#ffffff'})
	if display.getLabelContentSize(totalRevenueLabel).width > 75 then
		totalRevenueLabel:setScale(75/totalRevenueLabel:getContentSize().width)
	end
	rankLayout:addChild(totalRevenueLabel, 7)
	local goldIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), 722, 28)
	rankLayout:addChild(goldIcon, 10)
	goldIcon:setScale(0.2)
	local totalRevenueNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', totalGold)
		display.commonUIParams(totalRevenueNum, {ap = cc.p(1,0.5), po = cc.p(705, 28)})
	totalRevenueNum:setBMFontSize(20)
	rankLayout:addChild(totalRevenueNum, 10)
	-- 基本信息
	local baseInformationLayout = CLayout:create(cc.size(size.width, 161))
	listView:insertNodeAtLast(baseInformationLayout)
	local baseInformationTitleBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_awareness.png'), size.width/2, 0, {scale9 = true, size = cc.size(size.width, 161), ap = cc.p(0.5, 0)})
	baseInformationLayout:addChild(baseInformationTitleBg)
	local baseInformationTitle = display.newButton(size.width/2, 136, {n = _res('ui/common/common_title_5.png'), enable = false , scale9 = true })
	display.commonLabelParams(baseInformationTitle, fontWithColor(4, {text = __('基本信息') , paddingW = 30 }))
	baseInformationLayout:addChild(baseInformationTitle, 10)
	-- 账目明细
	local customerNum = table.nums(checktable(CommonUtils.GetConfigAllMess('customer', 'restaurant')))
	local layoutHeight = 60 + 64 * math.ceil(customerNum/2)
	local billDetailLayout = CLayout:create(cc.size(size.width, layoutHeight))
	listView:insertNodeAtLast(billDetailLayout)
	local billDetailTitleBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_awareness.png'), size.width/2, 0, {scale9 = true, size = cc.size(size.width, layoutHeight), ap = cc.p(0.5, 0)})
	billDetailLayout:addChild(billDetailTitleBg)
	local billDetailTitle = display.newButton(size.width/2, layoutHeight - 21, {n = _res('ui/common/common_title_5.png'), enable = false,scale9 = true})
	display.commonLabelParams(billDetailTitle, fontWithColor(4, {text = __('今日账目'), paddingW = 30}))
	billDetailLayout:addChild(billDetailTitle, 10)
	-- 详细信息
	local detailedInformationLayout = CLayout:create(cc.size(size.width, 42))
	listView:insertNodeAtLast(detailedInformationLayout)
	local detailedInformationTitleBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_awareness.png'), size.width/2, 0, {ap = cc.p(0.5, 0),scale9 = true})
	detailedInformationTitleBg:setScaleY(0.213)
	detailedInformationLayout:addChild(detailedInformationTitleBg)
	local detailedInformationTitle = display.newButton(size.width/2, 21, {n = _res('ui/common/common_title_5.png'), enable = false ,scale9 = true })
	display.commonLabelParams(detailedInformationTitle, fontWithColor(4, {text = __('详细信息'), paddingW  = 30 }))
	detailedInformationLayout:addChild(detailedInformationTitle, 10)

	local recipeNum = 0
	-- local popularityNum = 0
	for _,v in pairs(userInfo.avatarCacheData.bill) do
		recipeNum = recipeNum + checkint(v.sellNum)
		-- popularityNum = popularityNum + checkint(v.popularity)
	end
	local hasSeatNum = 0
	for i,v in pairs(userInfo.avatarCacheData.location) do
		if checkint(v.goodsId) >= 101000 and checkint(v.goodsId) < 102000 then
			local avatarConfig = CommonUtils.GetConfigNoParser("restaurant", 'avatarLocation', v.goodsId)
			if checkint(avatarConfig.hasAddition) == 1 then
				hasSeatNum = hasSeatNum + checkint(avatarConfig.additionNum)
			end

		end
	end
	-- 座位数量限制
	local seatNum = CommonUtils.GetConfigNoParser('restaurant', 'levelUp', userInfo.restaurantLevel).seatNum
	local baseInformationDatas = {
		{name = __('客流量'), num = self:UpdateTraffic()},
		{name =__('知名度'), num = userInfo.avatarCacheData.todayPopularity},
		{name = __('座位数量'), num = hasSeatNum .. '/' .. seatNum},
		{name = __('服务员'), num = self.args.waiterNum},
		{name = __('橱窗菜品'), num = table.nums(userInfo.avatarCacheData.recipe)},
		{name = __('出售菜品数量'), num = recipeNum}
	}
	for i,v in ipairs(baseInformationDatas) do
		if i%2 == 1 then
			if math.ceil(i/2)%2 == 1 then
				local bg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_basic_1.png'), 0, 152 - math.ceil(i/2)*38, {ap = cc.p(0, 1)})
				baseInformationLayout:addChild(bg, 5)
			elseif math.ceil(i/2)%2 == 0 then
				local bg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_basic_2.png'), 0, 152 - math.ceil(i/2)*38, {ap = cc.p(0, 1)})
				baseInformationLayout:addChild(bg, 5)
			end
			local name = display.newLabel(28, 134 - math.ceil(i/2)*38, fontWithColor(5, {text = v.name, ap = cc.p(0, 0.5)}))
			baseInformationLayout:addChild(name, 10)
			if i == 1 then
				local num = display.newLabel(326, 134 - math.ceil(i/2)*38, fontWithColor(5, {text = tostring(v.num) .. __('/小时'), ap = cc.p(1, 0.5)}))
				baseInformationLayout:addChild(num, 10)
				local detailedBtn = display.newButton(350, 134 - math.ceil(i/2)*38, {n = _res('ui/home/market/market_main_ico_research.png')})
				baseInformationLayout:addChild(detailedBtn, 10)
				detailedBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
			else
				local num = display.newLabel(326, 134 - math.ceil(i/2)*38, fontWithColor(5, {text = tostring(v.num), ap = cc.p(1, 0.5)}))
				baseInformationLayout:addChild(num, 10)
			end
		elseif i%2 == 0 then
			if math.ceil(i/2)%2 == 1 then
				local bg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_basic_1.png'), size.width, 152 - math.ceil(i/2)*38, {ap = cc.p(1, 1)})
				baseInformationLayout:addChild(bg, 5)
			elseif math.ceil(i/2)%2 == 0 then
				local bg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_basic_2.png'), size.width, 152 - math.ceil(i/2)*38, {ap = cc.p(1, 1)})
				baseInformationLayout:addChild(bg, 5)
			end
			local name = display.newLabel(398, 134 - math.ceil(i/2)*38, fontWithColor(5, {text = v.name, ap = cc.p(0, 0.5)}))
			baseInformationLayout:addChild(name, 10)
			local num = display.newLabel(size.width - 16, 134 - math.ceil(i/2)*38, fontWithColor(5, {text = tostring(v.num), ap = cc.p(1, 0.5)}))
			baseInformationLayout:addChild(num, 10)
		end
	end
	local billDetailDatas = {}
	local customerDatas = CommonUtils.GetConfigAllMess('customer', 'restaurant')
	for _,v in orderedPairs(customerDatas) do
		local temp = {}
		temp.name = v.name
		temp.id = v.id
		temp.gold = 0
		temp.popularity = 0
		table.insert(billDetailDatas, temp)
	end
	for _,bill in ipairs(userInfo.avatarCacheData.bill) do
		for _, value in ipairs(billDetailDatas) do
			if checkint(bill.customerId) == checkint(value.id) then
				value.gold = bill.gold
				value.popularity = bill.popularity
				break
			end
		end
	end
	for i,v in ipairs(billDetailDatas) do
		local layout = CLayout:create(cc.size(310, 60))
		local name = display.newLabel(5, 45, fontWithColor(5, {text = v.name, ap = cc.p(0, 0.5)}))
		layout:addChild(name, 10)
		local bg = display.newImageView(_res('ui/common/common_bg_goods_2.png'), 155, 0, {scale9 = true, size = cc.size(308, 30), ap = cc.p(0.5, 0)})
		layout:addChild(bg, 5)
		local goldNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', v.gold)
		display.commonUIParams(goldNum, {ap = cc.p(0,0.5), po = cc.p(8, 13)})
		goldNum:setBMFontSize(24)
		layout:addChild(goldNum, 10)
		local goldIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), 10 + goldNum:getContentSize().width, 13, {ap = cc.p(0, 0.5)})
		goldIcon:setScale(0.19)
		layout:addChild(goldIcon, 10)
		local popularityNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', v.popularity)
		display.commonUIParams(popularityNum, {ap = cc.p(1,0.5), po = cc.p(268, 13)})
		popularityNum:setBMFontSize(24)
		layout:addChild(popularityNum, 10)
		local popularityIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(POPULARITY_ID)), 270, 15, {ap = cc.p(0, 0.5)})
		popularityIcon:setScale(0.19)
		layout:addChild(popularityIcon, 10)
		if i%2 == 1 then
			display.commonUIParams(layout,{ap = cc.p(0, 0.5), po = cc.p(30, layoutHeight - math.ceil(i/2)*66)})
		elseif i%2 == 0 then
			display.commonUIParams(layout,{ap = cc.p(1, 0.5), po = cc.p(size.width - 30, layoutHeight - math.ceil(i/2)*66)})
		end
		billDetailLayout:addChild(layout, 10)

	end
	-- 物品的详细信息
	for _,v in orderedPairs(clone(userInfo.avatarCacheData.location)) do
		local avatarData = CommonUtils.GetConfigNoParser('restaurant', 'avatar', v.goodsId)
		-- dump(avatarData)
		if  checkint(avatarData.beautyNum) > 0 then
			local descrLayout = self:CreateDetailedLayout(v.goodsId)
			viewData.listView:insertNodeAtLast(descrLayout)
		end
	end
	viewData.listView:reloadData()
end
--[[
创建物品详情cell
--]]
function LobbyDetailedInformationView:CreateDetailedLayout( goodsId )
	local height = 10
	local avatarData = CommonUtils.GetConfigNoParser('restaurant', 'avatar', goodsId)
	local descrTable = {}
	if avatarData.beautyNum then
		local buffDescr = string.fmt(__('美观度+_num_'), {['_num_'] = checkint(avatarData.beautyNum)})
		table.insert(descrTable, buffDescr)
		local tempLabel = display.newLabel(0, 0, fontWithColor(6, {w = 560, text = buffDescr}))
		height = height + display.getLabelContentSize(tempLabel).height
	end
	-- for _,buff in ipairs(avatarData.buffType) do
	-- 	local buffDescr = CommonUtils.GetConfigNoParser('restaurant', 'buffType', buff.targetType).descr
	-- 	if buff.targetId and next(buff.targetId) ~= nil then
	-- 		for _, targetId in ipairs(buff.targetId) do
	-- 			buffDescr = string.gsub(buffDescr, '_target_id_', tostring(targetId), 1)
	-- 		end
	-- 	end
	-- 	if buff.targetNum and next(buff.targetNum) ~= nil then
	-- 		for _, targetNum in ipairs(buff.targetNum) do
	-- 			buffDescr = string.gsub(buffDescr, '_target_num_', tostring(targetNum), 1)
	-- 		end
	-- 	end
	-- 	table.insert(descrTable, buffDescr)
	-- 	local tempLabel = display.newLabel(0, 0, fontWithColor(6, {w = 560, text = buffDescr}))
	-- 	height = height + display.getLabelContentSize(tempLabel).height
	-- end
	local size = self.viewData_.size
	local layout = CLayout:create(cc.size(size.width, height))
	local bg = display.newImageView(_res('ui/common/commcon_bg_text.png'), size.width/2, height/2, {scale9 = true, size = cc.size(size.width, height-2), capInsets = cc.rect(10, 10, 414, 121)})
	layout:addChild(bg, 5)
	local nameLabel = display.newLabel(16, height/2, fontWithColor(4, {text = avatarData.name,ap = cc.p(0, 0.5)}))
	layout:addChild(nameLabel, 10)
	local descrHeight = height - 5
	for _,v in ipairs(descrTable) do
		local descrLabel = display.newLabel(372, descrHeight, fontWithColor(6, {text = v, ap = cc.p(0, 1), w = 560}))
		layout:addChild(descrLabel, 10)
		descrHeight = descrHeight - display.getLabelContentSize(descrLabel).height
	end
	return layout
end
--[[
排行榜点击回调
--]]
function LobbyDetailedInformationView:RankButtonCallbcak( sender )
	-- 添加点击音效
	PlayAudioByClickNormal()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "AvatarMediator"},
		{name = "RankingListMediator"})

end
function LobbyDetailedInformationView:ButtonCallback( sender )
	-- 添加点击音效
	PlayAudioByClickNormal()
	local viewData = self.viewData_
	local layout = CLayout:create(viewData.size)
	layout:setPosition(cc.p(viewData.size.width/2, viewData.size.height/2))
	viewData.view:addChild(layout, 20)
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(viewData.size)
	eaterLayer:setPosition(utils.getLocalCenter(layout))
	layout:addChild(eaterLayer, -1)
	eaterLayer:setOnClickScriptHandler(function(sender)
		-- 添加点击音效
		PlayAudioByClickClose()
		layout:runAction(cc.RemoveSelf:create())
	end)

	local yPos = sender:getPositionY() - 15
	local baseInformationLayout = sender:getParent()
	local worldPos = baseInformationLayout:convertToWorldSpace(cc.p(350, yPos))
	local nodePos = layout:convertToNodeSpace(worldPos)
	local tipsSize = cc.size(650, 268)
	local tipsLayout = CLayout:create(tipsSize)
	tipsLayout:setAnchorPoint(cc.p(0.5, 1))
	tipsLayout:setPosition(cc.p(nodePos))
	layout:addChild(tipsLayout)
	local colorView = CColorView:create(cc.c4b(0, 0, 0, 0))
	colorView:setContentSize(tipsSize)
	colorView:setTouchEnabled(true)
	colorView:setPosition(utils.getLocalCenter(tipsLayout))
	tipsLayout:addChild(colorView, -1)
	local bg = display.newImageView(_res('ui/common/common_bg_tips'), tipsSize.width/2, 0, {ap = cc.p(0.5, 0), scale9 = true, size = cc.size(650, 258)})
	tipsLayout:addChild(bg, 5)
	local horn = display.newImageView(_res('ui/common/common_bg_tips_horn.png'), tipsSize.width/2, tipsSize.height, {ap = cc.p(0.5, 1)})
	tipsLayout:addChild(horn, 5)
	local title = display.newButton(tipsSize.width/2, tipsSize.height - 35, {n = _res('ui/common/common_title_5.png'), enable = false})
	display.commonLabelParams(title, fontWithColor(4, {text = __('客流详情')}))
	tipsLayout:addChild(title, 10)
	local nameBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bar_title.png'), 8, 195, {ap = cc.p(0, 0.5), scale9 = true, size = cc.size(200, 34)})
	tipsLayout:addChild(nameBg, 7)
	local nameLabel = display.newLabel(110, 195, fontWithColor(18, {text = __('名称')}))
	tipsLayout:addChild(nameLabel, 10)
	local effectBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bar_title.png'), tipsSize.width - 8, 195, {ap = cc.p(1, 0.5), scale9 = true, size = cc.size(432, 34)})
	tipsLayout:addChild(effectBg, 7)
	local effectLabel = display.newLabel(tipsSize.width - 224, 195, fontWithColor(18, {text = __('效果')}))
	tipsLayout:addChild(effectLabel, 7)
	local listSize = cc.size(640, 170)
	local listView = CListView:create(listSize)
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setBounceable(true)
	tipsLayout:addChild(listView, 10)
	listView:setAnchorPoint(cc.p(0.5, 0))
	listView:setPosition(cc.p(tipsSize.width/2+1, 6))
	local effectTable = {}
	local userInfo = gameMgr:GetUserInfo()
	-- 露比
	local bugNums = table.nums(checktable(self.args.bug))
	if bugNums > 0 then
		local debuff = CommonUtils.GetConfigAllMess('restaurantBugDebuff', 'friend')
		local percentage = 0
		if debuff[tostring(bugNums)] then
			percentage = tonumber(debuff[tostring(bugNums)]['1']) * 100
		else
			percentage = 20
		end
        table.insert(effectTable, {descr = string.fmt(__('客流量降低_num_%'), {['_num_'] = percentage}), name = __('捣蛋露比')})
	end

	-- 雇员技能
    for k, v in pairs(gameMgr:GetUserInfo().supervisor) do
    	local x = app.restaurantMgr:GetCardBusinessBuff(v, LOBBY_SUPERVISOR, 2)
        if next(x) ~= nil then
        	for _, skill in ipairs(x) do
        		if skill.allEffectNum.targetType == '41' then
        			local cardDatas = gameMgr:GetCardDataById(v)
					local cardName = CommonUtils.GetConfig('cards', 'card', cardDatas.cardId).name
        			table.insert(effectTable, {descr = skill.descr, name = cardName})
        		end
        	end
        end
    end

    for k, v in pairs(gameMgr:GetUserInfo().chef) do
        local x = app.restaurantMgr:GetCardBusinessBuff(v, LOBBY_CHEF, 2)
        if next(x) ~= nil then
        	for _, skill in ipairs(x) do
        		if skill.allEffectNum.targetType == '41' then
        			local cardDatas = gameMgr:GetCardDataById(v)
					local cardName = CommonUtils.GetConfig('cards', 'card', cardDatas.cardId).name
        			table.insert(effectTable, {descr = skill.descr, name = cardName})
        		end
        	end
        end
    end

    for k, v in pairs(gameMgr:GetUserInfo().waiter) do
        local x = app.restaurantMgr:GetCardBusinessBuff(v, LOBBY_WAITER, 2)
        if next(x) ~= nil then
        	for _, skill in ipairs(x) do
        		if skill.allEffectNum.targetType == '41' then
        			local cardDatas = gameMgr:GetCardDataById(v)
					local cardName = CommonUtils.GetConfig('cards', 'card', cardDatas.cardId).name
        			table.insert(effectTable, {descr = skill.descr, name = cardName})
        		end
        	end
        end
    end
	-- for _,v in pairs(userInfo.supervisor) do
	-- 		-- 主管技能

	-- 	-- dump(app.restaurantMgr:GetCardBusinessBuff(v, 1, 1))
	-- 	local cardDatas = gameMgr:GetCardDataById(v)
	-- 	for skillId, levelData in pairs(cardDatas.businessSkill) do
	-- 		local skillDatas = CommonUtils.GetConfig('business', 'assistantSkill', skillId)
	-- 		if checkint(skillDatas.consumeType) == 1 then -- 是否为主管技能
	-- 			if checkint(skillDatas.type[1].targetType) == 1 then
	-- 				local descr = skillDatas.descr
	-- 				if skillDatas.type[1].targetId and next(skillDatas.type[1].targetId) ~= nil then
	-- 					for _, targetId in ipairs(skillDatas.type[1].targetId) do
	-- 						local customerDatas = CommonUtils.GetConfigNoParser('restaurant', 'customer', targetId)
	-- 						descr = string.gsub(descr, '_target_id_', tostring(customerDatas.name), 1)
	-- 					end
	-- 				end

	-- 				if skillDatas.type[1].targetNum and next(skillDatas.type[1].targetNum) ~= nil then
	-- 					for _, targetNum in ipairs(skillDatas.type[1].targetNum) do
	-- 						descr = string.gsub(descr, '_target_num_', tostring(tonumber(targetNum) * tonumber(levelData.level)), 1)
	-- 					end
	-- 				end
	-- 				local cardName = CommonUtils.GetConfig('cards', 'card', cardDatas.cardId).name
	-- 				table.insert(effectTable, {descr = descr, name = cardName})
	-- 			end
	-- 		end
	-- 	end
	-- end
	-- 香味属性
	local fragrance = 0
	for recipeId,_ in pairs(userInfo.avatarCacheData.recipe) do
		local recipeDatas = CommonUtils.GetConfigNoParser('cooking', 'recipe', recipeId)
		for _, recipe in ipairs(userInfo.cookingStyles[recipeDatas.cookingStyleId]) do
			if checkint(recipe.recipeId) == checkint(recipeId) then
				fragrance = fragrance + checkint(recipe.fragrance)
				break
			end
		end
	end
	local addCustomerNum = checkint(fragrance/20) * math.sqrt(table.nums(userInfo.avatarCacheData.recipe))
	table.insert(effectTable, {descr = string.fmt(__('每小时增加_num_个客人'), {['_num_'] = checkint(addCustomerNum)}), name = __('香味属性')})
	-- avatarbuff
	for _,v in pairs(userInfo.avatarCacheData.location) do
		local avatarDatas = CommonUtils.GetConfigNoParser('restaurant', 'avatar', v.goodsId)
		for _, buff in ipairs(avatarDatas.buffType) do
			if checkint(buff.targetType) == 1 then
				local buffTypeDatas = CommonUtils.GetConfigNoParser('restaurant', 'buffType', 1)
				local descr = buffTypeDatas.descr
				if buff.targetId and next(buff.targetId) ~= nil then
					for _, targetId in ipairs(buff.targetId) do
						descr = string.gsub(descr, '_target_id_', tostring(targetId), 1)
					end
				end
				if buff.targetNum and next(buff.targetNum) ~= nil then
					for _, targetNum in ipairs(buff.targetNum) do
						descr = string.gsub(descr, '_target_num_', tostring(targetNum), 1)
					end
				end
				table.insert(effectTable, {name = avatarDatas.name, descr = descr})
			end
		end
	end
	-- 特殊事件
	for _, event in ipairs(userInfo.avatarCacheData.events) do
		if event.status == 2 then
			if checkint(event.eventId) >= 5 and checkint(event.eventId) <= 10 then
				local eventDatas = CommonUtils.GetConfigNoParser('restaurant', 'event', event.eventId)
				table.insert(effectTable, {name = eventDatas.name, descr = eventDatas.descr})
			end
		end
	end
	-- 餐厅等级
	local restaurantDatas = CommonUtils.GetConfigNoParser('restaurant', 'levelUp', userInfo.restaurantLevel)
	table.insert(effectTable, {name = string.fmt(__('_num_级餐厅'), {['_num_'] = tostring(userInfo.restaurantLevel)}), descr = string.fmt(__('每小时增加_num_个客人'), {['_num_'] = tostring(restaurantDatas.traffic)})})
	-- 创建cell
	for i,v in ipairs(effectTable) do
		local layout = CLayout:create(cc.size(listSize.width, 34))
		local bgRes = nil
		if i%2 == 1 then
			local bg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_name.png'), layout:getContentSize().width/2, layout:getContentSize().height/2, {scale9 = true, size = cc.size(listSize.width, 34)})
			layout:addChild(bg)
		end
		local nameLabel = display.newLabel(104, 17, fontWithColor(6, {text = v.name}))
		layout:addChild(nameLabel, 10)
		local descrLabel = display.newLabel(222, 17, fontWithColor(6, {text = v.descr, ap = cc.p(0, 0.5)}))
		layout:addChild(descrLabel, 10)
		listView:insertNodeAtLast(layout)
	end
	listView:reloadData()
end
--[[
更新客流量信息
--]]
function LobbyDetailedInformationView:UpdateTraffic()
	local traffic = 0
	local userInfo = gameMgr:GetUserInfo()
	-- 雇员效果
    for k, v in pairs(gameMgr:GetUserInfo().supervisor) do
    	local x = app.restaurantMgr:GetCardBusinessBuff(v, LOBBY_SUPERVISOR, 2)
        if next(x) ~= nil then
        	for _, skill in ipairs(x) do
        		if skill.allEffectNum.targetType == '41' then
        			traffic = traffic + checkint(skill.allEffectNum.effectNum[1])
        		end
        	end
        end
    end

    for k, v in pairs(gameMgr:GetUserInfo().chef) do
        local x = app.restaurantMgr:GetCardBusinessBuff(v, LOBBY_CHEF, 2)
        if next(x) ~= nil then
        	for _, skill in ipairs(x) do
        		if skill.allEffectNum.targetType == '41' then
        			traffic = traffic + checkint(skill.allEffectNum.effectNum[1])
        		end
        	end
        end
    end
    for k, v in pairs(gameMgr:GetUserInfo().waiter) do
        local x = app.restaurantMgr:GetCardBusinessBuff(v, LOBBY_WAITER, 2)
        if next(x) ~= nil then
        	for _, skill in ipairs(x) do
        		if skill.allEffectNum.targetType == '41' then
        			traffic = traffic + checkint(skill.allEffectNum.effectNum[1])
        		end
        	end
        end
    end
    -- 香味
	local fragrance = 0
	for recipeId,_ in pairs(userInfo.avatarCacheData.recipe) do
		local recipeDatas = CommonUtils.GetConfigNoParser('cooking', 'recipe', recipeId)
		for _, recipe in ipairs(userInfo.cookingStyles[recipeDatas.cookingStyleId]) do
			if checkint(recipe.recipeId) == checkint(recipeId) then
				fragrance = fragrance + checkint(recipe.fragrance)
				break
			end
		end
	end
	local addCustomerNum = checkint(fragrance/20) * math.sqrt(table.nums(userInfo.avatarCacheData.recipe))
	traffic = traffic + checkint(addCustomerNum)
	-- avatarbuff
	for _,v in pairs(userInfo.avatarCacheData.location) do
		local avatarDatas = CommonUtils.GetConfigNoParser('restaurant', 'avatar', v.goodsId)
		for _, buff in ipairs(avatarDatas.buffType) do
			if buff.targetNum and next(buff.targetNum) ~= nil then
				traffic = traffic + checkint(buff.targetNum)
			end
		end
	end
	-- 餐厅等级
	local restaurantDatas = CommonUtils.GetConfigNoParser('restaurant', 'levelUp', userInfo.restaurantLevel)
	traffic = traffic + checkint(restaurantDatas.traffic)
	-- 露比
	local bugNums = table.nums(checktable(self.args.bug))
	if bugNums > 0 then
		local debuff = CommonUtils.GetConfigAllMess('restaurantBugDebuff', 'friend')
		local percentage = 0
		if debuff[tostring(bugNums)] then
			percentage = tonumber(debuff[tostring(bugNums)]['1'])
		else
			percentage = 0.2
		end
		traffic = checkint(traffic*(1-tonumber(percentage)))
	end
	return traffic
end
return LobbyDetailedInformationView
