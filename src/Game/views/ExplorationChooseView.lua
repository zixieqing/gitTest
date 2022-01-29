--[[
探索选择道路系统UI
--]]
local ExplorationChooseView = class('ExplorationChooseView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.ExplorationChooseView'
	node:enableNodeEvents()
	node:setAnchorPoint(cc.p(0, 0))
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local function CreateView( self )
	local view = CLayout:create(display.size)
	view:setAnchorPoint(0, 0)
	local mapCardDatas = {}
	for i,v in pairs(self.roomDatas) do
		local mapCard = require('home.ExplorationMapCardCell').new(cc.size(334, 482))
		mapCard:setPosition(cc.p((display.cx-375) + (i-1)*375, display.cy))
		view:addChild(mapCard, 10)
		mapCard.cardBtn:setTag(i)
		mapCard.cardBtn:setUserTag(v.id)
		mapCard.cardName:setString(v.name)
		mapCard.cardBtn:setNormalImage('ui/home/exploration/maps_small/discovery_main_pic_' .. v.photo .. '_' .. tostring(i) .. '.jpg')
		mapCard.cardBtn:setSelectedImage('ui/home/exploration/maps_small/discovery_main_pic_' .. v.photo .. '_' .. tostring(i) .. '.jpg')
		-- 探索时间
		mapCard.timeNum:setString(string.formattedTime(checkint(v.exploreTime),'%02i:%02i:%02i'))
		mapCard.vigourNum:setString(string.format('%d%%', v.consumeVigour*100))
		mapCard.timeIcon:setOnClickScriptHandler(function()
			if mapCard.eventNode:getChildByTag(1234) then
				mapCard.eventNode:getChildByTag(1234):removeFromParent()
			else
				local textLabel = display.newLabel(0, 0, fontWithColor(15, {text = __('探索需要消耗时间')}))
				local bg = display.newImageView(_res('ui/common/common_bg_tips.png'), 175, 185,
					{scale9 = true, size = cc.size(display.getLabelContentSize(textLabel).width + 20, display.getLabelContentSize(textLabel).height + 20), capInsets = cc.rect(10, 10, 345, 174)})
				mapCard.eventNode:addChild(bg, 15)
				bg:addChild(textLabel)
				textLabel:setPosition(bg:getContentSize().width/2, bg:getContentSize().height/2)
				local horn = display.newImageView(_res('ui/common/common_bg_tips_horn.png'), bg:getContentSize().width/2, 2)
				horn:setScaleY(-1)
				bg:addChild(horn)
				bg:setTag(1234)
			end
		end)
		if v.isBossQuest then
			local bossSpine = AssetsUtils.GetCardSpineNode({confId = v.bossId})
			bossSpine:update(0)
			bossSpine:setToSetupPose()
			bossSpine:setPosition(cc.p(mapCard.size.width/2, mapCard.size.height*0.3))
			bossSpine:setAnimation(0, 'idle', true)
			mapCard.eventNode:addChild(bossSpine, 7)
			bossSpine:setScale(0.55)

			-- local bossWarning = sp.SkeletonAnimation:create(
			-- 	'effects/explore/bossWarning.json',
			-- 	'effects/explore/bossWarning.atlas',
			-- 	1)
			-- bossWarning:update(0)
			-- bossWarning:setToSetupPose()
			-- bossWarning:setPosition(cc.p(mapCard.size.width/2, mapCard.size.height*0.8))
			-- bossWarning:setAnimation(0, 'boss', true)
			-- mapCard.eventNode:addChild(bossWarning, 10)
			-- 添加boss奖励
			for i=1,2 do
				local chestId = nil
				local chestNum = nil
				if i == 1 then
					chestId = v.chestRewards[1].goodsId
					chestNum = v.chestRewards[1].num
				elseif i == 2 then
					chestId = v.bossChestReward[1].goodsId
					chestNum = v.bossChestReward[1].num
				end
				local goodsNode = require('common.GoodNode').new({id = chestId, amount = chestNum, showAmount = true,
					callBack = function (sender)
						local index_ = sender:getParent():getTag()
						uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = chestId, type = 1})
					end
				})
				goodsNode:setPosition(cc.p(110+(i-1)*114, 50))
				goodsNode:setScale(0.7)
				mapCard.eventNode:addChild(goodsNode, 10)
			end
		else
			-- 添加非boss奖励
			local pos = cc.p(110, 50)
			local goodsLabel = {}
			for i=1,2 do
				local goodsId = nil
				local goodNum = nil
				if i == 1 then
					if next(v.reward) ~= nil and checkint(v.reward[1].num) ~= 0 then
						goodsId = v.reward[1].goodsId
						goodNum = v.reward[1].num
					end
				elseif i == 2 then
					goodsId = checktable(v.chestRewards[1]).goodsId
					goodNum = checktable(v.chestRewards[1]).num
				end
				if goodsId then
					local goodsNode = require('common.GoodNode').new({id = goodsId, amount = goodNum, showAmount = true,
						callBack = function (sender)
							local index_ = sender:getParent():getTag()
							uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = goodsId, type = 1})
						end
					})
					goodsNode:setPosition(pos)
					goodsNode:setScale(0.7)
					mapCard.eventNode:addChild(goodsNode, 10)
					pos = cc.p(224, 50)
					table.insert(goodsLabel, goodsNode)
				end
			end
			if #goodsLabel == 1 then
				goodsLabel[1]:setPosition(cc.p(mapCard.eventNode:getContentSize().width/2, 50))
			end
		end
		table.insert(mapCardDatas, mapCard)
	end
	-- local tipsBg = display.newImageView(_res('ui/common/common_title_3.png'), display.cx, display.height - TOP_HEIGHT, {scale9 = true, size = cc.size(500, 40)})
	-- view:addChild(tipsBg, 5)
	-- local str = string.split(string.format(__('本层的探索需消耗飨灵队伍|%d|新鲜度'), self.vigourCost), '|')
	-- local tips = display.newRichLabel(display.cx, display.height - TOP_HEIGHT, {r = true, c = {
	-- 	{img = _res('ui/common/common_btn_tips.png'), scale = 0.8},
	-- 	fontWithColor(6, {text = str[1]}),
	-- 	{text = str[2], fontSize = 24, color = '#d23d3d'},
	-- 	fontWithColor(6, {text = str[3]})
	-- }})
	-- view:addChild(tips, 10)
	local floorNumBg = display.newButton(display.width - 110 - display.SAFE_L, display.cy, {n = _res('ui/home/exploration/discovery_ico_floor_num.png'), ap = cc.p(0, 0.5), enable = false})
	view:addChild(floorNumBg, 10)
	display.commonLabelParams(floorNumBg, fontWithColor(16, {text = __('层'), reqW = 55, ap = display.LEFT_CENTER , offset = cc.p(-35, - 7)}))
	local floorNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	floorNum:setPosition(cc.p(30 , floorNumBg:getContentSize().height*0.4))
	floorNum:setScale(2)
	floorNumBg:addChild(floorNum)
	local bottomLayout = CLayout:create(cc.size(display.width, 155))
	bottomLayout:setVisible(false)
	bottomLayout:setAnchorPoint(0.5, 0)
	bottomLayout:setPosition(cc.p(display.cx, 0))
	view:addChild(bottomLayout, 10)
	local bottomBg = display.newImageView(_res('ui/common/discovery_ready_dg.png'), display.cx, 0, {ap = cc.p(0.5, 0), scale9 = true, size = cc.size(display.width, 100), capInsets = cc.rect(10, 10, 1314, 255)})
	bottomLayout:addChild(bottomBg, 5)
	local tipsBtn = display.newButton(display.cx - 292, 80, {tag = 1014, n = _res('ui/common/common_btn_tips.png')})
	tipsBtn:setVisible(false)
	bottomLayout:addChild(tipsBtn, 10)
	local recordBtn = display.newButton(80 + display.SAFE_L, 0, {tag = 1011, ap = cc.p(0.5, 0), n = _res('ui/home/exploration/discovery_btn_record.png')})
	bottomLayout:addChild(recordBtn, 10)
	local exploreBtn = require('common.CommonBattleButton').new({pattern = 3})
	exploreBtn:setPosition(cc.p(display.width -100 - display.SAFE_L, 83))
	exploreBtn:setTag(1012)
	bottomLayout:addChild(exploreBtn, 10)
	local retreatBtn = display.newButton(display.width - 300 - display.SAFE_L, 43, {tag = 1013, n = _res('ui/common/common_btn_orange.png')})
	bottomLayout:addChild(retreatBtn, 10)
	display.commonLabelParams(retreatBtn, fontWithColor(14, {text = __('撤退')}))
	-- -- 指南
	-- local guideBtn = display.newButton(display.width - 60 -  display.SAFE_L, display.cy + 90, {n = _res('guide/guide_ico_book')})
	-- view:addChild(guideBtn, 10)
	-- display.commonLabelParams(guideBtn, fontWithColor(14,{text = __('指南'), fontSize = 28, color = 'ffffff',offset = cc.p(10, -18)}))
	-- guideBtn:setOnClickScriptHandler(function(sender)
	-- 	local guideNode = require('common.GuideNode').new({tmodule = 'explore'})
	-- 	display.commonUIParams(guideNode, { po = display.center})
	-- 	sceneWorld:addChild(guideNode, GameSceneTag.Guide_GameSceneTag)
	-- end)

	return {
		view           		= view,
		bottomLayout        = bottomLayout,
		mapCardDatas        = mapCardDatas,
		recordBtn  			= recordBtn,
		exploreBtn 			= exploreBtn,
		retreatBtn			= retreatBtn,
		floorNum            = floorNum,
		-- tips  	 			= tips,
		tipsBtn 	        = tipsBtn
	}
end

function ExplorationChooseView:ctor( ... )
	self.args = unpack({...}) or {}
	self.roomDatas = self.args.roomDatas
	-- dump(self.roomDatas)
	self.vigourCost = self.args.vigourCost
	self.viewData_ = CreateView(self)
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(cc.p(0, 0))
end

return ExplorationChooseView
