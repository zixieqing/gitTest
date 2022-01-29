--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）主界面Scene
--]]
local GameScene = require('Frame.GameScene')
local MurderHomeScene = class('MurderHomeScene', GameScene)
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local RES_DICT = {
	COMMON_TITLE                    = app.murderMgr:GetResPath('ui/common/common_title.png'),
	COMMON_TIPS       		        = app.murderMgr:GetResPath('ui/common/common_btn_tips.png'),
	BG 							    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_bg.jpg'),
	TOP_BTN_BG	 	 	 	 	 	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_bg_up.png'),
	STORY_BTN 	 	 	 	 	 	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_btn_book.png'),
	REWARDS_BTN 	 	 	 	 	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_btn_rewards.png'),
	BTN_TITLE 		 	 	 	 	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_btn_title.png'), 
	COLLECTED_ITEMS_BG	 	 	    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_label_items.png'),
	COLLECTED_ITEMS_NUM_BG 	    	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_label_items_num.png'),
	DRAW_ITEMS_NUM_BG	 	 	    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_label_drawitem.png'),
	POINT_PROGRESS_BG 				= app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_btn_pt.png'),
	POINT_PROGRESS_BAR_BG	 	  	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_pt_bar_grey.png'),
	POINT_PROGRESS_BAR  	 	  	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_pt_bar_active.png'),
	REWARDS_ICON 	 	 	 	 	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_ico_boss_rewards.png'),
	REWARDS_BG 	 	 	 	 	 	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_ico_boss_completed.png'),
	INVESTIGATION_BG   	 	 	    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_main_label_timer.png'),
	MONEY_INFO_BAR       		    = app.murderMgr:GetResPath('ui/home/nmain/main_bg_money.png'),
	REMIND_ICON						= app.murderMgr:GetResPath('ui/common/common_hint_circle_red_ico.png'),
	-- spine --
	CLOCK_SPINE 	 	 	        = app.murderMgr:GetSpinePath('ui/home/activity/murder/effect/murder_main_clock'),
	DRAW_SPINE  	 	 	        = app.murderMgr:GetSpinePath('ui/home/activity/murder/effect/murder_main_draw'),
	MATERIAL_SPINE  	 	 	    = app.murderMgr:GetSpinePath('ui/home/activity/murder/effect/murder_main_material'),
	SHOP_SPINE      	 	 	    = app.murderMgr:GetSpinePath('ui/home/activity/murder/effect/murder_main_shop'),
	BUTTON_SPINE      	 	 	    = app.murderMgr:GetSpinePath('ui/home/activity/murder/effect/murder_main_btn'),
	BOSS_SPINE      	 	 	    = app.murderMgr:GetSpinePath('ui/home/activity/murder/effect/murder_main_boos'),
	CLUE_SPINE 	 	 	 	 	    = app.murderMgr:GetSpinePath('ui/home/activity/murder/effect/murder_main_btn_clue'),
	-- spine --
}
function MurderHomeScene:ctor( ... )
    self.super.ctor(self, 'views.activity.murder.MurderHomeScene')
	local args = unpack({...})
	self:InitUI()
end
--[[
初始化ui
--]]
function MurderHomeScene:InitUI()
	local CreateView = function ()
		local size = display.size
		local view = CLayout:create(size)
		view:setPosition(size.width / 2, size.height / 2)
		-- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE,enable = true,ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = app.murderMgr:GetPoText(__('时之镇魂歌')), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
		self:addChild(tabNameLabel, 20)
		-- 提示按钮
		local tabtitleTips = display.newImageView(RES_DICT.COMMON_TIPS, 242, 28)
		tabNameLabel:addChild(tabtitleTips, 1)
		-- 背景
		local bg = display.newImageView(RES_DICT.BG, size.width / 2, size.height / 2)
		view:addChild(bg, 1)
		-- 时钟 
		local clockSpine = sp.SkeletonAnimation:create(
			RES_DICT.CLOCK_SPINE.json,
			RES_DICT.CLOCK_SPINE.atlas,
			1)
		clockSpine:update(0)
		clockSpine:setToSetupPose()
		clockSpine:setAnimation(0, 'idle1', true)
		clockSpine:setPosition(cc.p(size.width / 2 + 30, size.height / 2 - 300))
		app.murderMgr:UpdateSpinePos(clockSpine , "clockSpine")
		view:addChild(clockSpine, 2)
		-- 推进按钮
		local buttonSpine = sp.SkeletonAnimation:create(
			RES_DICT.BUTTON_SPINE.json,
			RES_DICT.BUTTON_SPINE.atlas,
			1)
		buttonSpine:update(0)
		buttonSpine:setToSetupPose()
		buttonSpine:setAnimation(0, 'idle1', true)
		buttonSpine:setPosition(cc.p(size.width / 2 + 30, size.height / 2 - 205))
		view:addChild(buttonSpine, 5)
		local advanceBtn = display.newButton(size.width / 2 + 30, size.height / 2 - 205, {n = 'empty', size = cc.size(245, 80)})
		view:addChild(advanceBtn, 5)
		display.commonLabelParams(advanceBtn, {text = '', fontSize = 28, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#451515', outlineSize = 2})
		-- 顶部按钮背景
		local topBtnBg = display.newImageView(RES_DICT.TOP_BTN_BG, size.width + 60 - display.SAFE_L, size.height - 60, {ap = display.RIGHT_TOP})
		view:addChild(topBtnBg, 2)
		app.murderMgr:UpdateNodeVisible(topBtnBg , "topBtnBg")
		-- 奖励预览
		local rewardsBtn = display.newButton(size.width - 75 - display.SAFE_L, size.height - 100, {n = RES_DICT.REWARDS_BTN})
		view:addChild(rewardsBtn, 5)
		display.commonLabelParams(rewardsBtn, {text = app.murderMgr:GetPoText(__('奖励预览')), fontSize = 20, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#451515', outlineSize = 2, offset = cc.p(0, -60)})
		local rewardsRemindIcon = display.newImageView(RES_DICT.REMIND_ICON, 90, 70)
		rewardsRemindIcon:setVisible(false)
		rewardsBtn:addChild(rewardsRemindIcon, 10)
		-- 剧情收录
		local storyBtn = display.newButton(size.width - 190 - display.SAFE_L, size.height - 100, {n = RES_DICT.STORY_BTN})
		view:addChild(storyBtn, 5)
		display.commonLabelParams(storyBtn, {text = app.murderMgr:GetPoText(__('剧情收录')), fontSize = 20, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#451515', outlineSize = 2, offset = cc.p(0, -60)})
		-- 收集按钮
		local collectedSpine = sp.SkeletonAnimation:create(
			RES_DICT.MATERIAL_SPINE.json,
			RES_DICT.MATERIAL_SPINE.atlas,
			1)
		collectedSpine:update(0)
		collectedSpine:setToSetupPose()
		collectedSpine:setAnimation(0, 'idle', true)
		collectedSpine:setPosition(cc.p(size.width / 2 - 530, size.height / 2 + 40))
		app.murderMgr:UpdateSpinePos(collectedSpine , "collectedSpine")

		collectedSpine:setVisible(false)
		view:addChild(collectedSpine, 5)
		local collectedBtn = display.newButton(size.width / 2 - 490, size.height / 2 + 55, {n = RES_DICT.BTN_TITLE})
		collectedBtn:setVisible(false)
		app.murderMgr:UpdateUIPos(collectedBtn , "collectedBtn")

		view:addChild(collectedBtn, 5)
		display.commonLabelParams(collectedBtn, {text = app.murderMgr:GetPoText(__('时间棋局')), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#451515', outlineSize = 2, offset = cc.p(0, - 60)})
		local collectedItemsBg = display.newImageView(RES_DICT.COLLECTED_ITEMS_BG, size.width / 2 - 490, size.height / 2 - 130)
		app.murderMgr:UpdateUIPos(collectedItemsBg , "collectedItemsBg")

		view:addChild(collectedItemsBg, 2)
		local collectedItemList = {}
		for i = 1, 3 do
			local goodsIcon = display.newImageView('empty', 26, 154 - 40 * i)
			goodsIcon:setScale(0.2)
			collectedItemsBg:addChild(goodsIcon, 1)
			local numberBg = display.newImageView(RES_DICT.COLLECTED_ITEMS_NUM_BG, 120, 154 - 40 * i)
			collectedItemsBg:addChild(numberBg, 1)
			local numLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', 0)
			numLabel:setPosition(cc.p(collectedItemsBg:getContentSize().width - 15, 154 - 40 * i))
			numLabel:setAnchorPoint(cc.p(1, 0.5))
			collectedItemsBg:addChild(numLabel, 2)
			table.insert(collectedItemList, {goodsIcon = goodsIcon, numLabel = numLabel})
		end
		-- 交换按钮
		local exchangeSpine = sp.SkeletonAnimation:create(
			RES_DICT.SHOP_SPINE.json,
			RES_DICT.SHOP_SPINE.atlas,
			1)
		exchangeSpine:update(0)
		exchangeSpine:setToSetupPose()
		exchangeSpine:setAnimation(0, 'lock', true)
		exchangeSpine:setPosition(cc.p(size.width / 2 - 300, size.height / 2 - 320))
		app.murderMgr:UpdateSpinePos(exchangeSpine , "exchangeSpine")
		view:addChild(exchangeSpine, 5)
		
		local exchangeBtn = display.newButton(size.width / 2 - 305, size.height / 2 - 280, {n = RES_DICT.BTN_TITLE})
		exchangeBtn:setVisible(false)
		view:addChild(exchangeBtn, 5)
		app.murderMgr:UpdateUIPos(exchangeBtn , "exchangeBtn")
		display.commonLabelParams(exchangeBtn, {text = app.murderMgr:GetPoText(__('时之馆')), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#451515', outlineSize = 2, offset = cc.p(0, -60)})
		-- 抽奖按钮
		local drawSpine = sp.SkeletonAnimation:create(
			RES_DICT.DRAW_SPINE.json,
			RES_DICT.DRAW_SPINE.atlas,
			1)
		drawSpine:update(0)
		drawSpine:setToSetupPose()
		drawSpine:setAnimation(0, 'lock', true)
		drawSpine:setPosition(cc.p(size.width / 2 + 600, size.height / 2 - 115))
		app.murderMgr:UpdateSpinePos(drawSpine ,"drawSpine")
		view:addChild(drawSpine, 2)
		local drawBtn = display.newButton(size.width / 2 + 520, size.height / 2 - 95, {n = RES_DICT.BTN_TITLE})
		drawBtn:setVisible(false)
		view:addChild(drawBtn, 5)
		app.murderMgr:UpdateUIPos(drawBtn , "drawBtn")
		display.commonLabelParams(drawBtn, {text = app.murderMgr:GetPoText(__('真相之镜')), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#451515', outlineSize = 2, offset = cc.p(0, -60)})
		local drawNumBg = display.newImageView(RES_DICT.DRAW_ITEMS_NUM_BG, size.width / 2 + 520, size.height / 2 - 210)
		view:addChild(drawNumBg, 2)
		drawNumBg:setVisible(false)
		local drawGoodsIcon = display.newImageView('empty', 20, drawNumBg:getContentSize().height / 2)
		drawGoodsIcon:setScale(0.2)
		drawNumBg:addChild(drawGoodsIcon, 2)
		local drawGoodsNumLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', 0)
		display.commonUIParams(drawGoodsNumLabel, {po = cc.p(drawNumBg:getContentSize().width - 10, drawNumBg:getContentSize().height / 2), ap = display.RIGHT_CENTER})
		drawNumBg:addChild(drawGoodsNumLabel, 2)
		app.murderMgr:UpdateUIPos(drawNumBg , "drawNumBg")
		-- 点数进度条
		local pointProgressBtn = display.newButton(size.width + 60 - display.SAFE_L, 0, {n = RES_DICT.POINT_PROGRESS_BG, ap = display.RIGHT_BOTTOM})
		pointProgressBtn:setVisible(false)
		view:addChild(pointProgressBtn, 2)
		local pointTitle = display.newLabel(115, pointProgressBtn:getContentSize().height - 63, {text = app.murderMgr:GetPoText(__('调查点数奖励')), fontSize = 20, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#451515', outlineSize = 2, ap = display.LEFT_CENTER})
		pointProgressBtn:addChild(pointTitle, 1)
		local pointProgressBar = CProgressBar:create(RES_DICT.POINT_PROGRESS_BAR)
		pointProgressBar:setBackgroundImage(RES_DICT.POINT_PROGRESS_BAR_BG)
		pointProgressBar:setPosition(330, 25)
		pointProgressBar:setDirection(eProgressBarDirectionLeftToRight)
		pointProgressBtn:addChild(pointProgressBar, 3)
		local progressBarLabel = display.newLabel(370, 25, {text = '0/0', fontSize = 20, color = '#ffffff'})
		pointProgressBtn:addChild(progressBarLabel, 3)
		local pointRewardsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(app.murderMgr:GetPointGoodsId()), pointProgressBtn:getContentSize().width - 95, 45)
		pointRewardsIcon:setScale(0.5)
		pointProgressBtn:addChild(pointRewardsIcon, 10)
		local pointRemindIcon = display.newImageView(RES_DICT.REMIND_ICON, 90, 70)
		pointRemindIcon:setVisible(false)
		pointProgressBtn:addChild(pointRemindIcon, 10)
		-- 调查
		local investigationLayoutSize = cc.size(340, 350)
		local investigationLayout = CLayout:create(investigationLayoutSize)
		investigationLayout:setVisible(false)
		display.commonUIParams(investigationLayout, {po = cc.p(size.width / 2 + 32, size.height / 2 + 32)})
		view:addChild(investigationLayout, 5)
		local investigationBg = display.newImageView('', investigationLayoutSize.width / 2, investigationLayoutSize.height / 2)
		investigationLayout:addChild(investigationBg, 1) 
		investigationBg:runAction(
			cc.RepeatForever:create(
				cc.Sequence:create(
					cc.DelayTime:create(1),
					cc.FadeTo:create(2, 0.2 * 255),
					cc.DelayTime:create(1),
					cc.FadeTo:create(2, 255)
				)
			)
		)
		local investigationTextBg = display.newImageView(RES_DICT.INVESTIGATION_BG, investigationLayoutSize.width / 2, 16)
		investigationLayout:addChild(investigationTextBg, 2)
		local investigationTimeTitle = display.newLabel(investigationTextBg:getContentSize().width / 2, investigationTextBg:getContentSize().height - 15, {text = app.murderMgr:GetPoText(__('剩余调查时间')), fontSize = 20, color = '#ffffff'})
		investigationTextBg:addChild(investigationTimeTitle, 1) 
		local investigationTimeLabel = display.newLabel(investigationTextBg:getContentSize().width / 2, 18, {text = '', fontSize = 20, color = '#ffbbaa'})
		investigationTextBg:addChild(investigationTimeLabel, 1)
		-- 传送门 
		local bossSpine = sp.SkeletonAnimation:create(
			RES_DICT.BOSS_SPINE.json,
			RES_DICT.BOSS_SPINE.atlas,
			1)
		bossSpine:update(0)
		bossSpine:setToSetupPose()
		bossSpine:setAnimation(0, 'idle1', true)
		bossSpine:setPosition(cc.p(investigationLayoutSize.width / 2,  - 160))
		investigationLayout:addChild(bossSpine, 10)
		-- 领取奖励
		local rewardLayoutSize = cc.size(340, 350)
		local rewardLayout = CLayout:create(rewardLayoutSize)
		rewardLayout:setVisible(false)
		display.commonUIParams(rewardLayout, {po = cc.p(size.width / 2 + 32, size.height / 2 + 32)})
		view:addChild(rewardLayout, 5)
		local rewardBg = display.newImageView(RES_DICT.REWARDS_BG, rewardLayoutSize.width / 2, rewardLayoutSize.height / 2 )
		rewardLayout:addChild(rewardBg, 1)
		local rewardIcon = display.newImageView(RES_DICT.REWARDS_ICON, rewardLayoutSize.width / 2 + 10, rewardLayoutSize.height / 2 - 50)
		rewardLayout:addChild(rewardIcon, 1)
		local rewardLabel = display.newLabel(rewardLayoutSize.width / 2, rewardLayoutSize.height / 2 + 50, {text = app.murderMgr:GetPoText(__('调查完成!')), fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#000000', outlineSize = 2})
		rewardLayout:addChild(rewardLabel, 1)
		-- 线索
		local clueSpine = sp.SkeletonAnimation:create(
			RES_DICT.CLUE_SPINE.json,
			RES_DICT.CLUE_SPINE.atlas,
			1)
		clueSpine:update(0)
		clueSpine:setToSetupPose()
		clueSpine:setAnimation(0, 'idle', true)
		clueSpine:setPosition(cc.p(size.width / 2 + 300, size.height))
		clueSpine:setVisible(false)
		app.murderMgr:UpdateSpinePos(clueSpine , "clueSpine")
		view:addChild(clueSpine, 5)
		local clueBtn = display.newButton(size.width / 2 + 300, size.height, {n = 'empty', size = cc.size(130, 250), ap = cc.p(0.5, 1)})
		clueBtn:setVisible(false)
		view:addChild(clueBtn, 5)			
		-- top ui layer 
		local topUILayer = display.newLayer()
		topUILayer:setPositionY(190)
		view:addChild(topUILayer, 10)
		-- money barBg
		local moneyBarBg = display.newImageView(app.murderMgr:GetResPath(RES_DICT.MONEY_INFO_BAR), display.width, display.height, {ap = display.RIGHT_TOP, scale9 = true, size = cc.size(1, 54)})
		topUILayer:addChild(moneyBarBg)
		-- money layer
		local moneyLayer = display.newLayer()
		topUILayer:addChild(moneyLayer)
		return {
			view 	            = view,
			tabNameLabel        = tabNameLabel,
			clockSpine          = clockSpine,
			bossSpine           = bossSpine,
			buttonSpine 	    = buttonSpine,
			advanceBtn	        = advanceBtn,
			rewardsBtn	        = rewardsBtn,
			rewardLayout        = rewardLayout,
			investigationLayout = investigationLayout, 
			investigationBg     = investigationBg,
			investigationTextBg = investigationTextBg,
			investigationTimeLabel = investigationTimeLabel,
			storyBtn		    = storyBtn,
			collectedBtn	    = collectedBtn,
			collectedItemList   = collectedItemList,
			collectedSpine      = collectedSpine,
			exchangeBtn         = exchangeBtn,
			exchangeSpine       = exchangeSpine,
			drawBtn   	        = drawBtn,
			drawSpine           = drawSpine,
			drawGoodsIcon       = drawGoodsIcon,
			drawGoodsNumLabel   = drawGoodsNumLabel,
			drawNumBg 	 	 	= drawNumBg,
			pointProgressBtn    = pointProgressBtn, 
			pointProgressBar    = pointProgressBar,
			progressBarLabel    = progressBarLabel,
			pointRewardsIcon    = pointRewardsIcon,
			pointRemindIcon     = pointRemindIcon,
			topUILayer		    = topUILayer,
			moneyBarBg          = moneyBarBg,
			moneyLayer          = moneyLayer,
			clueSpine 	 	    = clueSpine,
			clueBtn 	 	    = clueBtn,
			rewardsRemindIcon   = rewardsRemindIcon,
		}
	end

	xTry(function ()
		self.viewData = CreateView()
		self:addChild(self.viewData.view)
		self:EnterAction()
	end, __G__TRACKBACK__)
end
--[[
入场动画
--]]
function MurderHomeScene:EnterAction()
    -- 弹出标题板
	local tabNameLabelPos = cc.p(self.viewData.tabNameLabel:getPosition())
	self.viewData.tabNameLabel:setPositionY(display.height + 100)
	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
	self.viewData.tabNameLabel:runAction( action )
	self.viewData.topUILayer:runAction(cc.MoveTo:create(0.4, cc.p(0, 0)))
end
--[[
重载货币栏
--]]
function MurderHomeScene:ReloadMoneyBar(moneyIdMap, isDisableGain)
    if moneyIdMap then
        moneyIdMap[tostring(GOLD_ID)]         = nil
        moneyIdMap[tostring(DIAMOND_ID)]      = nil
        moneyIdMap[tostring(PAID_DIAMOND_ID)] = nil
        moneyIdMap[tostring(FREE_DIAMOND_ID)] = nil
    end
    
    -- money data
    local moneyIdList = table.keys(moneyIdMap or {})
    table.insert(moneyIdList, GOLD_ID)
    table.insert(moneyIdList, DIAMOND_ID)
    
    -- clean moneyLayer
    local moneyBarBg = self:GetViewData().moneyBarBg
    local moneyLayer = self:GetViewData().moneyLayer
    moneyLayer:removeAllChildren()
    
    -- update moneyLayer
    local MONEY_NODE_GAP = 16
    local moneyLayerSize = moneyLayer:getContentSize()
    local moneryBarSize  = cc.size(20, moneyBarBg:getContentSize().height)
    for i = #moneyIdList, 1, -1 do
		local moneyId = checkint(moneyIdList[i])
		local isShowHpTips = (moneyId == HP_ID or moneyId == app.murderMgr:GetMurderHpId()) and 1 or -1
        local isDisable = moneyId ~= GOLD_ID and moneyId ~= DIAMOND_ID and isDisableGain
        local moneyNode = GoodPurchaseNode.new({id = moneyId, animate = true, disable = isDisable, isEnableGain = not isDisableGain, isShowHpTips = isShowHpTips})
        moneyNode.viewData.touchBg:setTag(checkint(moneyId))
        moneyNode:setPosition(display.SAFE_R - moneryBarSize.width, moneyLayerSize.height - 26)
        moneyNode:setAnchorPoint(display.RIGHT_CENTER)
        moneyNode:setName(moneyId)
        moneyLayer:addChild(moneyNode)

        moneryBarSize.width = moneryBarSize.width + moneyNode:getContentSize().width + MONEY_NODE_GAP
    end

    -- update moneyBarBg
    moneryBarSize.width = 40 + moneryBarSize.width + (display.width - display.SAFE_R)
	moneyBarBg:setContentSize(moneryBarSize)
	self:UpdateGoodsNum()
end
--[[
刷新道具数量
--]]
function MurderHomeScene:UpdateGoodsNum()
	self:UpdateMoneyBar()
	self:UpdateCollectedItem()
	self:UpdateDrawGoods()
end
--[[
刷新材料栏
--]]
function MurderHomeScene:UpdateCollectedItem()
	local viewData = self:GetViewData()
	local collectedItemList = viewData.collectedItemList
	local currencyMap = app.murderMgr:GetStoreCurrency()
	local i = 0
	for k, v in orderedPairs(currencyMap) do
		i = i + 1
		local goodsId = checkint(v)
		local goodsNum = app.gameMgr:GetAmountByIdForce(goodsId)
		collectedItemList[4 - i].goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(goodsId))
		collectedItemList[4 - i].numLabel:setString(tostring(goodsNum))
	end
end
--[[
刷新抽奖道具
--]]
function MurderHomeScene:UpdateDrawGoods()
	local viewData = self:GetViewData()
	local goodsId = app.murderMgr:GetLotteryGoodsId()
	viewData.drawGoodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(goodsId))
	viewData.drawGoodsNumLabel:setString(app.gameMgr:GetAmountByIdForce(goodsId))
end
--[[
刷新货币栏
--]]
function MurderHomeScene:UpdateMoneyBar()
    for _, moneyNode in ipairs(self:GetViewData().moneyLayer:getChildren()) do
        local moneyId = checkint(moneyNode:getName())
        moneyNode:updataUi(moneyId)
	end
end
--[[
更新材料副本锁定状态
@params isLock bool 是否锁定
--]]
function MurderHomeScene:UpdateCollectedLockState( isLock )
	local viewData = self:GetViewData()
	if isLock then
		viewData.collectedBtn:setVisible(false)
		viewData.collectedSpine:setVisible(false)
	else
		viewData.collectedSpine:setToSetupPose()
		viewData.collectedSpine:setAnimation(0, 'idle', true)
		viewData.collectedSpine:setVisible(true)
		viewData.collectedBtn:setVisible(true)
	end
end
--[[
更新商城锁定状态
@params isLock bool 是否锁定
--]]
function MurderHomeScene:UpdateStoreLockState( isLock )
	local viewData = self:GetViewData()
	if isLock then
		viewData.exchangeSpine:setToSetupPose()
		viewData.exchangeSpine:setAnimation(0, 'lock', true)
		viewData.exchangeBtn:setVisible(false)
	else
		viewData.exchangeSpine:setToSetupPose()
		viewData.exchangeSpine:setAnimation(0, 'idle', true)
		viewData.exchangeBtn:setVisible(true)
	end
end
--[[
更新扭蛋机锁定状态
@params isLock bool 是否锁定
--]]
function MurderHomeScene:UpdateCapsuleLockState( isLock )
	local viewData = self:GetViewData()
	if isLock then
		viewData.drawNumBg:setVisible(false)
		viewData.drawSpine:setToSetupPose()
		viewData.drawSpine:setAnimation(0, 'lock', true)
		viewData.drawBtn:setVisible(false)
	else
		viewData.drawNumBg:setVisible(true)
		viewData.drawSpine:setToSetupPose()
		viewData.drawSpine:setAnimation(0, 'idle', true)
		viewData.drawBtn:setVisible(true)
	end
end
--[[
更新线索模块锁定状态
@params isLock bool 是否锁定
--]]
function MurderHomeScene:UpdateClueLockState( isLock )
	local viewData = self:GetViewData()
	if isLock then
		viewData.clueSpine:setVisible(false)
		viewData.clueBtn:setVisible(false)
	else
		viewData.clueSpine:setVisible(true)
		viewData.clueBtn:setVisible(true)
	end
end
--[[
更新积分奖励锁定状态
@params isLock bool 是否锁定
--]]
function MurderHomeScene:UpdatePointRewardsLockState( isLock )
	local viewData = self:GetViewData()
	viewData.pointProgressBtn:setVisible(not isLock)
end
--[[
改变时钟状态
@params 
--]]
function MurderHomeScene:UpdateClockState( state )
	local viewData = self:GetViewData()
	viewData.rewardLayout:setVisible(false)
	viewData.investigationLayout:setVisible(false)
	local clockLevel = app.murderMgr:GetClockLevel() 
	viewData.buttonSpine:setToSetupPose()
	if clockLevel < 6 then
		viewData.clockSpine:setAnimation(0, string.format('idle%d', clockLevel + 1), true)
	else
		viewData.clockSpine:setAnimation(0, 'idle1', true)
	end
	if state == MURDER_CLOCK_STATE.UPGRADE then
		self:RefreshUpgradeLayout()
	elseif state == MURDER_CLOCK_STATE.BOSS then
		self:RefreshBossLayout(false)
	elseif state == MURDER_CLOCK_STATE.REWARD then
		viewData.buttonSpine:setToSetupPose()
		viewData.buttonSpine:setAnimation(0, 'idle3', true)
		viewData.rewardLayout:setVisible(true)
		viewData.advanceBtn:getLabel():setString(app.murderMgr:GetPoText(__('领取奖励')))
	elseif state == MURDER_CLOCK_STATE.FINAL then
		viewData.buttonSpine:setToSetupPose()
		viewData.buttonSpine:setAnimation(0, 'idle3', true)
		viewData.advanceBtn:getLabel():setString(app.murderMgr:GetPoText(__('剧终')))
	end

end
--[[
时钟升级动画
@params clockLevel int 最新时钟等级
--]]
function MurderHomeScene:ClockUpgradeAnimation( newClockLevel )
	local viewData = self:GetViewData()
	local clockSpine = viewData.clockSpine
	local buttonSpine = viewData.buttonSpine
	local unlockBossId = app.murderMgr:GetUnlockBossId()
	local effectBossId = app.murderMgr:GetEffectBossId()
	viewData.rewardLayout:setVisible(false)
	viewData.investigationLayout:setVisible(false)
	clockSpine:setToSetupPose()
	clockSpine:setAnimation(0, string.format('play%d', newClockLevel), false)
	if newClockLevel < 6 then
		clockSpine:addAnimation(0, string.format('idle%d', newClockLevel + 1), true)
	else
		clockSpine:addAnimation(0, 'idle1', true)
	end
	self:runAction(
		cc.Sequence:create(
			cc.DelayTime:create(4),
			cc.CallFunc:create(function()
				if unlockBossId < effectBossId then
					-- 时钟升级
					self:RefreshUpgradeLayout()
				else
					-- 调查
					buttonSpine:setAnimation(0, 'play1', false)
					buttonSpine:addAnimation(0, 'idle2', true)
					self:RefreshBossLayout(true)
				end
			end)
		)
	)
end
--[[
boss奖励领取动画
--]]
function MurderHomeScene:DrawBossRewardsAnimation()
	local viewData = self:GetViewData()
	local buttonSpine = viewData.buttonSpine
	viewData.rewardLayout:setVisible(false)
	viewData.investigationLayout:setVisible(false)
	viewData.buttonSpine:setToSetupPose()
	buttonSpine:setAnimation(0, 'play3', false)
	buttonSpine:addAnimation(0, 'idle1', true)
	self:RefreshUpgradeLayout()
end
--[[
刷新upgradeLayout
--]]
function MurderHomeScene:RefreshUpgradeLayout()
	local viewData = self:GetViewData()
	viewData.buttonSpine:setToSetupPose()
	viewData.buttonSpine:setAnimation(0, 'idle1', true)
	viewData.advanceBtn:getLabel():setString(app.murderMgr:GetPoText(__('推进')))
end
--[[
刷新bossLayout
--]]
function MurderHomeScene:RefreshBossLayout( isAnimate )
	local viewData = self:GetViewData()
	local bossId = app.murderMgr:GetUnlockBossId()
	viewData.buttonSpine:setToSetupPose()
	if not isAnimate then
		viewData.buttonSpine:setAnimation(0, 'idle2', true)
	end
	viewData.investigationLayout:setVisible(true)
	viewData.advanceBtn:getLabel():setString(app.murderMgr:GetPoText(__('调查')))
	viewData.investigationBg:setTexture(app.murderMgr:GetResPath(string.format('ui/home/activity/murder/murder_main_ico_boss_%d.png', bossId)))
	-- 如果boss为当前排期boss，显示倒计时
	viewData.investigationTextBg:setVisible(bossId == app.murderMgr:GetCurrentBossId())
end
--[[
刷新点数进度条
--]]
function MurderHomeScene:UpdatePointProgressBar( value, maxValue )
	local viewData = self:GetViewData()
	viewData.pointProgressBar:setMaxValue(maxValue)
	viewData.pointProgressBar:setValue(value)
	viewData.progressBarLabel:setString(string.format("%d/%d", value, maxValue))
end
--[[
刷新点数进度条红点
--]]
function MurderHomeScene:UpdatePointRemindIcon( isShow )
	local viewData = self:GetViewData()
	viewData.pointRemindIcon:setVisible(isShow)
end
--[[
刷新时钟等级奖励红点
--]]
function MurderHomeScene:UpdateClockRewardsRemindIcon( isShow )
	local viewData = self:GetViewData()
	viewData.rewardsRemindIcon:setVisible(isShow)
end
--[[
播放线索动画
--]]
function MurderHomeScene:RunClueAnimation()
	local viewData = self:GetViewData()
	viewData.clueSpine:setToSetupPose()
	viewData.clueSpine:setAnimation(0, 'play', false)
	viewData.clueSpine:addAnimation(0, 'idle', true)
end
--[[
更新boss倒计时
--]]
function MurderHomeScene:UpdateBossCountdown( seconds )
	local viewData = self:GetViewData()
	local text = CommonUtils.getTimeFormatByType(seconds, 0)
	viewData.investigationTimeLabel:setString(text)
end
--[[
获取viewData
--]]
function MurderHomeScene:GetViewData()
	return self.viewData
end
return MurderHomeScene
