--[[
 * author : liuzhipeng
 * descpt : 活动 周年庆19 主界面Scene
--]]
local GameScene = require('Frame.GameScene')
local Anniversary19HomeScene = class('Anniversary19HomeScene', GameScene)
local anniversary2019Mgr = app.anniversary2019Mgr
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local RES_DICT = {
    COMMON_TITLE                    = anniversary2019Mgr:GetResPath('ui/common/common_title.png'),
    COMMON_TIPS       		        = anniversary2019Mgr:GetResPath('ui/common/common_btn_tips.png'),
	BG                              = anniversary2019Mgr:GetResPath('ui/anniversary19/home/wonderland_main_bg.jpg'),
	MONEY_INFO_BAR       		    = anniversary2019Mgr:GetResPath('ui/home/nmain/main_bg_money.png'),
	BTN_BG                          = anniversary2019Mgr:GetResPath('ui/anniversary19/home/wonderland_main_btn_subtitle.png'),
	POINT_BG                        = anniversary2019Mgr:GetResPath('ui/anniversary19/home/wonderland_main_label_num.png'),
	TOP_BTN_BG   					= anniversary2019Mgr:GetResPath('ui/anniversary19/home/wonderland_main_label_up.png'),
	TOP_BTN_STORY                   = anniversary2019Mgr:GetResPath('ui/anniversary19/home/wonderland_main_btn_story.png'),
	TOP_BTN_CARD                    = anniversary2019Mgr:GetResPath('ui/anniversary19/home/wonderland_main_btn_cardgame.png'),
	TOP_BTN_SHOP                    = anniversary2019Mgr:GetResPath('ui/anniversary19/home/wonderland_main_btn_shop.png'),
	COMMON_BTN_BACK                 = anniversary2019Mgr:GetResPath('ui/common/common_btn_back.png'),
	-- spine --
	RABBIT_SPINE                    = anniversary2019Mgr.spineTable.WONDERLAND_DRAW_RABBIT ,
	SLEEP_SPINE                     = anniversary2019Mgr.spineTable.WONDERLAND_MAIN_ZZZ ,
	TREE_SPINE                      = anniversary2019Mgr.spineTable.WONDERLAND_MAIN_TREE ,
	LOCK_SPINE                      = anniversary2019Mgr.spineTable.WONDERLAND_MAIN_POINT ,
	OPEN_SPINE                      = anniversary2019Mgr.spineTable.WONDERLAND_OPENING_BOOM ,
}

local TOP_BTN_CONFIG = {
	{title = anniversary2019Mgr:GetPoText(__('剧情')), offsetY = 40, image = RES_DICT.TOP_BTN_STORY, isFlipX = false, tag = 1},
	--{title = anniversary2019Mgr:GetPoText(__('战牌')), offsetY = 0,  image = RES_DICT.TOP_BTN_CARD,  isFlipX = false, tag = 2},
	{title = anniversary2019Mgr:GetPoText(__('商店')), offsetY = 40, image = RES_DICT.TOP_BTN_SHOP,  isFlipX = true , tag = 3},
}
function Anniversary19HomeScene:ctor( ... )
    self.super.ctor(self, 'views.anniversary19.Anniversary19HomeScene')
	local args = unpack({...})
	self:InitUI()
end
--[[
初始化ui
--]]
function Anniversary19HomeScene:InitUI()
	local CreateView = function ()
		local size = display.size
		local view = CLayout:create(size)
		view:setPosition(size.width / 2, size.height / 2)



		-- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE, enable = true,ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = app.anniversary2019Mgr:GetPoText(__('仙境梦游')),  reqW = 204, fontSize = 30, color = '#473227',offset = cc.p(-20,-10)})
		self:addChild(tabNameLabel, 20)
		-- 提示按钮
		local tabtitleTips = display.newImageView(RES_DICT.COMMON_TIPS, 260, 29)
		tabNameLabel:addChild(tabtitleTips, 1)
		-- 背景
		local bg = display.newImageView(RES_DICT.BG, size.width / 2, size.height / 2)
		view:addChild(bg, 1)
		local wonderland_main_house = anniversary2019Mgr.spineTable.WONDERLAND_MAIN_HOUSE
		if wonderland_main_house then
			anniversary2019Mgr:AddSpineCacheByPath(wonderland_main_house)
			local  houseSpine = SpineCache(SpineCacheName.ANNIVERSARY_2019):createWithName(wonderland_main_house)
			houseSpine:setAnimation(0, 'idle', true)
			houseSpine:setPosition(size.width / 2, size.height / 2)
			view:addChild(houseSpine, 3)
			anniversary2019Mgr:SetSpineChangeData("houseSpine" , houseSpine)
		end

		local changeData = anniversary2019Mgr:GetChangeSkinData()
		if changeData.frontImage then
			local frontImage = display.newImageView(anniversary2019Mgr:GetResPath(changeData.frontImage) , display.cx , display.cy)
			view:addChild(frontImage , 3)
		end

		local backBtn = display.newButton(display.SAFE_L + 15, display.height - 55,
				{
					ap = display.LEFT_CENTER,
					n = RES_DICT.COMMON_BTN_BACK,
					scale9 = true, size = cc.size(90, 70),
					enable = true,
				})
		view:addChild(backBtn, 10)

		----------------------
		-------- spine -------
		-- 锁
		anniversary2019Mgr:AddSpineCacheByPath(RES_DICT.LOCK_SPINE)
		local  lockSpine = SpineCache(SpineCacheName.ANNIVERSARY_2019):createWithName(RES_DICT.LOCK_SPINE)
		lockSpine:setAnimation(0, 'idle', true)
		lockSpine:setPosition(size.width / 2, size.height / 2)
		view:addChild(lockSpine, 3)
		-- 树
		anniversary2019Mgr:AddSpineCacheByPath(RES_DICT.TREE_SPINE)
		local treeSpine = SpineCache(SpineCacheName.ANNIVERSARY_2019):createWithName(RES_DICT.TREE_SPINE)
		treeSpine:setAnimation(0, 'idle', false)
		treeSpine:setPosition(size.width / 2, size.height / 2 + 40)
		view:addChild(treeSpine, 3)



		-- 睡眠
		anniversary2019Mgr:AddSpineCacheByPath(RES_DICT.SLEEP_SPINE)
		local  sleepSpine = SpineCache(SpineCacheName.ANNIVERSARY_2019):createWithName(RES_DICT.SLEEP_SPINE)
		sleepSpine:setAnimation(0, 'idle', true)
		sleepSpine:setPosition(size.width / 2, size.height / 2)
		view:addChild(sleepSpine, 3)

		anniversary2019Mgr:SetSpineChangeData("sleepSpine" , sleepSpine)
		anniversary2019Mgr:SetSpineChangeData("lockSpine" , lockSpine)
		anniversary2019Mgr:SetSpineChangeData("treeSpine" , treeSpine)


		-------- spine -------
		----------------------

		----------------------
		---- buttonLayout ----
		local buttonLayout = CLayout:create(size)
		buttonLayout:setPosition(size.width / 2, size.height / 2)
		view:addChild(buttonLayout, 5)
		-- 普通按钮创建
		local function createBtn(pos, title)
			local btn = display.newButton(pos.x, pos.y, {n = RES_DICT.BTN_BG, useS = false , scale9 = true , size = cc.size(380,300) })
			buttonLayout:addChild(btn, 1)
			display.commonLabelParams(btn, {text = title or '',  fontSize = 24, color = '#ffffff', ttf = true, font = TTF_GAME_FONT,  outline = '#250c0c', outlineSize = 2, offset = cc.p(4, - 78)})
			return btn
		end
		-- 奖励
		local changeSkinData = anniversary2019Mgr:GetChangeSkinData()
		local rewardPos = cc.p(size.width / 2 - 510, size.height / 2 + 40)
		local mainPos = changeSkinData.mainPos
		if mainPos then
			rewardPos = mainPos.rewardBtnPos
		end
		local rewardBtn = createBtn(rewardPos, anniversary2019Mgr:GetPoText(__('梦中的宝物')))
		local rewardPointBg = display.newImageView(RES_DICT.POINT_BG, rewardPos.x , size.height / 2 + 40)
		rewardPointBg:setCascadeOpacityEnabled(true)
		rewardPointBg:setPosition(rewardPos.x, size.height / 2 - 85)
		buttonLayout:addChild(rewardPointBg, 1)
		local pointIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID), 20, rewardPointBg:getContentSize().height / 2)
		pointIcon:setScale(0.18)
		rewardPointBg:addChild(pointIcon, 1)
		local pointNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '0')
		pointNum:setAnchorPoint(display.RIGHT_CENTER)
		pointNum:setPosition(rewardPointBg:getContentSize().width - 8, rewardPointBg:getContentSize().height / 2)
		rewardPointBg:addChild(pointNum, 1)
		local exploreBtnPos = changeSkinData.mainPos
		if mainPos then
			exploreBtnPos = mainPos.exploreBtnPos
		end
		exploreBtnPos = exploreBtnPos ~= nil and exploreBtnPos or cc.p(size.width / 2 + 8, size.height / 2 + 85)
		-- 探索
		local exploreBtn = createBtn(exploreBtnPos, anniversary2019Mgr:GetPoText(__('仙境之旅')))
		-- 仙境
		local wonderlandBtn = createBtn(cc.p(size.width / 2 - 166, size.height / 2 - 240), anniversary2019Mgr:GetPoText(__('柴郡猫的帮助')))
		-- 抽奖
		local lotteryBtn = createBtn(cc.p(size.width / 2 + 490, size.height / 2 - 120), anniversary2019Mgr:GetPoText(__('许愿树洞')))
		
		-- 顶部按钮创建	
		local topBtnComponentList = {}
		for i, v in ipairs(TOP_BTN_CONFIG) do
			local bg = display.newImageView(RES_DICT.TOP_BTN_BG, 0, 0)
			local bgSize = bg:getContentSize()
			local layout = CLayout:create(bgSize)
			display.commonUIParams(layout, {ap = display.CENTER_TOP, po = cc.p(size.width - display.SAFE_L - (125 * i), size.height + v.offsetY)})
			buttonLayout:addChild(layout, 1)
			bg:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))
			bg:setFlippedX(v.isFlipX)
			layout:addChild(bg, 1)
			local btn = display.newButton(bgSize.width / 2, 70, {n = v.image})
			layout:addChild(btn , 1)
			btn:setTag(v.tag)
			local titleLabel = display.newLabel(bgSize.width / 2, 25, {text = v.title, fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#250c0c', outlineSize = 2})
			layout:addChild(titleLabel, 1)
			table.insert(topBtnComponentList, {
				layout     = layout,
				btn        = btn, 
				titleLabel = titleLabel,
			})
		end
		---- buttonLayout ----
		----------------------

		-- top ui layer 
		local topUILayer = display.newLayer()
		topUILayer:setPositionY(190)
		view:addChild(topUILayer, 10)
		-- money barBg
		local moneyBarBg = display.newImageView(anniversary2019Mgr:GetResPath(RES_DICT.MONEY_INFO_BAR), display.width, display.height, {ap = display.RIGHT_TOP, scale9 = true, size = cc.size(1, 54)})
		topUILayer:addChild(moneyBarBg)
		-- money layer
		local moneyLayer = display.newLayer()
		topUILayer:addChild(moneyLayer)
		return {
			view 	            = view,
			tabNameLabel        = tabNameLabel,
			topUILayer		    = topUILayer,
			moneyBarBg          = moneyBarBg,
			moneyLayer          = moneyLayer,
			treeSpine           = treeSpine,
			sleepSpine	        = sleepSpine,
			rewardBtn           = rewardBtn, 	
			rewardPointBg       = rewardPointBg,
			pointIcon           = pointIcon,
			pointNum            = pointNum,
			exploreBtn          = exploreBtn, 	
			wonderlandBtn       = wonderlandBtn, 	
			lotteryBtn          = lotteryBtn, 	
			topBtnComponentList = topBtnComponentList,
			buttonLayout        = buttonLayout,
			backBtn             = backBtn,
		}
	end
	xTry(function ()
		self.viewData = CreateView()
		self:addChild(self.viewData.view)
	end, __G__TRACKBACK__)
end
--[[
入场动画
@params animation string openSpine播放的动画名称
--]]
function Anniversary19HomeScene:EnterAction( animation )
	-- 添加点击屏蔽层
	app.uiMgr:GetCurrentScene():AddViewForNoTouch()
	local viewData = self:GetViewData()
	local tabNameLabelPos = cc.p(viewData.tabNameLabel:getPosition())
	viewData.tabNameLabel:setPositionY(display.height + 100)
	viewData.buttonLayout:setOpacity(0)

	anniversary2019Mgr:AddSpineCacheByPath(RES_DICT.OPEN_SPINE)
	local  openSpine = SpineCache(SpineCacheName.ANNIVERSARY_2019):createWithName(RES_DICT.OPEN_SPINE)
	openSpine:setAnimation(0, animation, false)
	openSpine:setPosition(display.center)
	sceneWorld:addChild(openSpine, GameSceneTag.Dialog_GameSceneTag)
	openSpine:registerSpineEventHandler(function ()
    	-- 弹出标题板
		local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
		viewData.tabNameLabel:runAction( action )
		viewData.topUILayer:runAction(cc.MoveTo:create(0.4, cc.p(0, 0)))
		viewData.buttonLayout:runAction(cc.FadeIn:create(0.4))
		-- 移除spine自身
		openSpine:runAction(cc.RemoveSelf:create())
		-- 移除点击屏蔽层
		app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
	end, sp.EventType.ANIMATION_END)
end
--[[
刷新道具数量
--]]
function Anniversary19HomeScene:UpdateGoodsNum()
	self:UpdateMoneyBar()
	self:RefreshRewardPointNum()
end
--[[
重载货币栏
--]]
function Anniversary19HomeScene:ReloadMoneyBar(moneyIdMap, isDisableGain)
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
		local isShowHpTips = (moneyId == HP_ID or moneyId == anniversary2019Mgr:GetHPGoodsId()) and 1 or -1
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
	self:UpdateMoneyBar()
end
--[[
刷新货币栏
--]]
function Anniversary19HomeScene:UpdateMoneyBar()
    for _, moneyNode in ipairs(self:GetViewData().moneyLayer:getChildren()) do
        local moneyId = checkint(moneyNode:getName())
        moneyNode:updataUi(moneyId)
	end
end
--[[
随机treeSpine动画
--]]
function Anniversary19HomeScene:RandomTreeSpineAnimation()
	local viewData = self:GetViewData()
	local config = {
		{animation = 'idle',  weight = 2},
		{animation = 'play1', weight = 1},
		{animation = 'play2', weight = 1},
		{animation = 'play3', weight = 1},
	}
	-- 随机动画
	local total = 0
	for i, v in ipairs(config) do
		total = total + v.weight
	end
	local rand = math.random(1, total)
	local animation = 'idle'
	local tmp = 0
	for i, v in ipairs(config) do
		tmp = tmp + v.weight
		if tmp >= rand then
			animation = v.animation
			break
		end
	end
    self:performWithDelay(
        function ()
        	viewData.treeSpine:update(0)
         	viewData.treeSpine:setToSetupPose()
    		viewData.treeSpine:addAnimation(0, animation, false)
        end,
        (1 * cc.Director:getInstance():getAnimationInterval())
    )
end
--[[
刷新奖励点数
--]]
function Anniversary19HomeScene:RefreshRewardPointNum()
	local viewData = self:GetViewData()
	local paramConfig = CommonUtils.GetConfigAllMess('parameter', 'anniversary2')
	viewData.pointIcon:setTexture(CommonUtils.GetGoodsIconPathById(paramConfig.crusadePoint))
	viewData.pointNum:setString(app.gameMgr:GetAmountByIdForce(paramConfig.crusadePoint))
end
--[[
隐藏sleepSpine
--]]
function Anniversary19HomeScene:HideSleepSpine()
	local viewData = self:GetViewData()
	viewData.sleepSpine:setVisible(false)
end
--[[
显示sleepSpine
--]]
function Anniversary19HomeScene:ShowSleepSpine()
	local viewData = self:GetViewData()
	viewData.sleepSpine:setVisible(true)
end
--[[
获取viewData
--]]
function Anniversary19HomeScene:GetViewData()
	return self.viewData
end
return Anniversary19HomeScene
