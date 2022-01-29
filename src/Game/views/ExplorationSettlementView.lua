--[[
探索奖励结算界面
--]]
local ExplorationSettlementView = class('ExplorationSettlementView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.ExplorationSettlementView'
	node:enableNodeEvents()
	node:setAnchorPoint(cc.p(0, 0))
	return node
end)
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
function ExplorationSettlementView:ctor( ... )
	self.viewData_ = nil
	self.args = unpack({...})
	self.rewards = self:ConvertRecordData(self.args.rewards) or {}
	self.selectedTeam = checkint(self.args.teamId) or 1
	self.areaFixedPointId = self.args.areaFixedPointId
	local function CreateView()
		local view = CLayout:create(display.size)
		view:setPosition(cc.p(display.cx, display.cy))
		self:addChild(view)
		local bg = display.newImageView(_res('ui/home/exploration/research_result_bg.jpg'), view:getContentSize().width/2, view:getContentSize().height/2, {isFull = true})
		view:addChild(bg)
		local centerBg = display.newImageView(_res('ui/home/exploration/main_bg_banner_up.png'), display.width, display.cy+15, {ap = cc.p(1, 0.5), scale9 = true, size = cc.size(800, 570)})
		view:addChild(centerBg)
        local tabNameLabel = display.newButton(130, display.height + 100,{n = _res('ui/common/common_title_new.png'),enable = false,ap = cc.p(0, 0)})
        local title = CommonUtils.GetConfig('common', 'areaFixedPoint', self.areaFixedPointId).name
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = title, fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel, 10)
		local prizeLayout = CLayout:create(cc.size(800, 620))
		prizeLayout:setPosition(cc.p(display.width, display.cy + 40))
		prizeLayout:setAnchorPoint(cc.p(1, 0.5))
		view:addChild(prizeLayout, 10)
		for i=1, 5 do
			local line = display.newImageView(_res('ui/home/exploration/research_result_bg_line.png'), 450, (i-1)*110, {scale9 = true})
			prizeLayout:addChild(line, 10)
		end
		-- rankLabel = display.newLabel(10, 566, {ap = cc.p(0, 0.5), text = '本次探索奖励超越全服30%的人', fontSize = 22, color = '#f6ef7a'})
		-- prizeLayout:addChild(rankLabel, 10)

		-- floorLabel = display.newLabel(prizeLayout:getContentSize().width - 20, 590, {ap = cc.p(1, 0.5), text = __('本次成功探        层'), fontSize = 28, color = '#ffffff'})
		-- prizeLayout:addChild(floorLabel, 10)
		local strs = string.split(__('本次探索已达到|_num_|层'), "|")
		local posX = prizeLayout:getContentSize().width - 50
		local afterLabel = display.newLabel(posX, 590, {text = strs[3], fontSize = 28, color = '#ffffff', ap = cc.p(1, 0.5)})
    	prizeLayout:addChild(afterLabel, 10)
    	local posX = posX - display.getLabelContentSize(afterLabel).width - 10
    	local floorNum = cc.Label:createWithBMFont('font/levelup.fnt', '')
    	floorNum:setString(tostring(table.nums(self.args.rewards.exploreRecord or {})))
    	floorNum:setAnchorPoint(cc.p(1,0.5))
    	floorNum:setPosition(cc.p(posX, 600))
    	prizeLayout:addChild(floorNum, 10)
    	local posX = posX - floorNum:getContentSize().width - 10
    	local frontLabel = display.newLabel(posX, 590, {text = strs[1], fontSize = 28, color = '#ffffff', ap = cc.p(1, 0.5)})
    	prizeLayout:addChild(frontLabel, 10)
		-- 队长立绘
		local captainId = gameMgr:GetUserInfo().teamFormation[self.selectedTeam].captainId
		if checkint(captainId) == 0 then
			for _, v in ipairs(gameMgr:GetUserInfo().teamFormation[self.selectedTeam].cards) do
				if v.id and v.id ~= '' then
					captainId = v.id
					break
				end

			end
		end
		local cardData = gameMgr:GetCardDataById(captainId)
 		local captain = require('common.CardSkinDrawNode').new({cardId = cardData.cardId, coordinateType = COORDINATE_TYPE_HOME})
		captain:setPosition(cc.p(0, 0))
		captain:setScale(1)
		view:addChild(captain, 5)

		local function CreateCell( text )
			local size = cc.size(800, 110)
			local cell = CLayout:create(size)
			cell:setAnchorPoint(cc.p(1, 0.5))
			local title = display.newButton(190, 55, {ap = cc.p(0.5, 0.5), n = _res('ui/common/common_title_7.png') , ap = display.RIGHT_CENTER , scale9 = true })
			display.commonLabelParams(title, {text = text, fontSize = 20, color = '#efb688' , paddingW = 20 })
			cell:addChild(title, 10)
			return cell
		end
		local roleCell = CreateCell(__('参与角色'))
		roleCell:setPosition(cc.p(800, 500))
		prizeLayout:addChild(roleCell, 10)
		local teamDatas = {}
		for i,v in ipairs(gameMgr:GetUserInfo().teamFormation[self.selectedTeam].cards) do
			if v.id then
				table.insert(teamDatas, v)
			end
		end
		for i,v in ipairs(teamDatas) do
			local cardHeadNode = require('common.CardHeadNode').new({id = checkint(v.id),
    	        showActionState = false})
			cardHeadNode:setPosition(cc.p(260+(i-1)*115, 50))
			cardHeadNode:setScale(0.55)
			cardHeadNode:setTag(2150 + i)
			roleCell:addChild(cardHeadNode, 10)
		end
		local basicRewardCell = CreateCell(__('探索获得'))
		basicRewardCell:setPosition(cc.p(800, 385))
		prizeLayout:addChild(basicRewardCell, 10)
		for i,v in ipairs(self.rewards.baseReward) do
			local goodsIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(v.goodsId)), 350 + (i-1)*180, 55, {ap = cc.p(0, 0.5)})
			goodsIcon:setScale(0.4)
			basicRewardCell:addChild(goodsIcon, 10)
			local num = cc.Label:createWithBMFont('font/small/common_text_num.fnt', v.num)
			num:setPosition(cc.p(340 + (i-1)*180, 55))
			num:setAnchorPoint(cc.p(1, 0.5))
			basicRewardCell:addChild(num, 10)
		end
		local chestCell = CreateCell(__('获得宝箱'))
		chestCell:setPosition(cc.p(800, 275))
		prizeLayout:addChild(chestCell, 10)
		for i,v in ipairs(self.rewards.chestReward) do
			local chestIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(v.goodsId)), 200 + (i-1)*100, 55, {ap = cc.p(0, 0.5)})
			chestIcon:setScale(0.7)
			chestCell:addChild(chestIcon, 10)
			local chestNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', v.num)
			chestNum:setPosition(cc.p(140, 20))
			chestNum:setAnchorPoint(cc.p(1, 0))
			chestIcon:addChild(chestNum, 10)
		end
		local bossCell = CreateCell(__('打败BOSS'))
		bossCell:setPosition(cc.p(800, 165))
		prizeLayout:addChild(bossCell, 10)
		for i,v in ipairs(self.rewards.boss) do
			local drawId = CommonUtils.GetConfig('monster', 'monster', v.bossId).drawId
            local drawPath = AssetsUtils.GetCardHeadPath(drawId)
			bossHeadImage = display.newImageView(drawPath, 200 + (i-1)*100, 55, {ap = cc.p(0, 0.5)})
			bossCell:addChild(bossHeadImage, 10)
			bossHeadImage:setScale(0.5)
			local bossNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', v.num)
			bossNum:setPosition(cc.p(160, 0))
			bossNum:setAnchorPoint(cc.p(1, 0))
			bossHeadImage:addChild(bossNum, 10)
		end
		local goodsCell = CreateCell(__('获得道具'))
		goodsCell:setPosition(cc.p(800, 55))
		prizeLayout:addChild(goodsCell, 10)

		local listSize = cc.size(500, 110)
		local listCellSize = cc.size(100, 110)
		local listView = CListView:create(listSize)
		listView:setDirection(eScrollViewDirectionHorizontal)
		listView:setBounceable(true)
		goodsCell:addChild(listView)
		listView:setAnchorPoint(cc.p(0, 0.5))
		listView:setPosition(cc.p(200, 55))
		for i,v in ipairs(self.rewards.goodsReward) do
			local layout = CLayout:create(cc.size(100, 100))
			goodsNode = require('common.GoodNode').new({
				id = v.goodsId,
				amount = v.num,
				showAmount = true,
				callBack = function (sender)
					local index_ = sender:getParent():getTag()
					uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
				end
			})
			goodsNode:setScale(0.8)
			goodsNode:setPosition(cc.p(50, 55))
			layout:addChild(goodsNode)
			listView:insertNodeAtLast(layout)
		end
		listView:reloadData()
		local closeBtn = display.newButton(display.width - 120, display.cy - 310, {n = _res('ui/common/common_btn_orange.png')})
		view:addChild(closeBtn, 10)
		display.commonLabelParams(closeBtn, fontWithColor(14, {text = __('关闭')}))

		return {
			view          = view,
			closeBtn      = closeBtn,
			tabNameLabel  = tabNameLabel,

		}
	end
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	eaterLayer:setPosition(cc.p(display.cx, display.height))
	self:addChild(eaterLayer, -10)
	xTry(function ( )
		self.viewData_ = CreateView( )
    	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, cc.p(130, display.height - 80)))
    	self.viewData_.tabNameLabel:runAction( action )
	end, __G__TRACKBACK__)
end
--[[
转换结算奖励数据结构
@params record 结算奖励
@return result table 转换后的数据结构
--]]
function ExplorationSettlementView:ConvertRecordData( rewards )
	local result = {
		baseReward = {},
		chestReward = {},
		boss = {},
		goodsReward = {}
	}
	for k, v in pairs(rewards.exploreRecord or {}) do
		if checkint(k) ~= self.floorNum then
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
			if v.floorReward.baseReward then
				if next(result.goodsReward) ~= nil then
					local isFind = false
					for i, reward in ipairs(result.goodsReward) do
						if reward.goodsId == checkint(v.floorReward.baseReward.goodsId) then
							reward.num = reward.num + checkint(v.floorReward.baseReward.num)
							isFind = true
							break
						end
						-- if i == #result.goodsReward then
						-- 	table.insert(result.goodsReward, {goodsId = checkint(v.floorReward.baseReward.goodsId), num = checkint(v.floorReward.baseReward.num)})
						-- end
					end
					if not isFind then
						if checkint(v.floorReward.baseReward.num) ~= 0 then
							table.insert(result.goodsReward, {goodsId = checkint(v.floorReward.baseReward.goodsId), num = checkint(v.floorReward.baseReward.num)})
						end
					end
				else
					if checkint(v.floorReward.baseReward.num) > 0 then
						table.insert(result.goodsReward, {goodsId = checkint(v.floorReward.baseReward.goodsId), num = checkint(v.floorReward.baseReward.num)})
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
										-- if i == #result.t then
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
											print(goodsDatas.num, checkint(reward.num))
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
	end
	-- 排序
	table.sort(result.goodsReward,function(a,b)
		local qualityA = checkint(CommonUtils.GetConfig('goods', 'goods', a.goodsId).quality)
		local qualityB = checkint(CommonUtils.GetConfig('goods', 'goods', b.goodsId).quality)
		return checkint(qualityA) > checkint(qualityB)
	end)
	return result
end
return ExplorationSettlementView
