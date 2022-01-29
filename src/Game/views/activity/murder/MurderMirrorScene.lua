--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）抽奖scene
--]]
local GameScene = require('Frame.GameScene')
local MurderMirrorScene = class('MurderMirrorScene', GameScene)
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local RES_DICT = {
    BG                              = app.murderMgr:GetResPath('ui/home/activity/murder/murder_draw_bg.png'),
    COMMON_TITLE                    = app.murderMgr:GetResPath('ui/common/common_title.png'),
	COMMON_TIPS       		        = app.murderMgr:GetResPath('ui/common/common_btn_tips.png'),
    MONEY_INFO_BAR       		    = app.murderMgr:GetResPath('ui/home/nmain/main_bg_money.png'),
    BOTTOM_BG                       = app.murderMgr:GetResPath('ui/home/activity/murder/murder_draw_bg_below.png'),
    DRAW_BTN                        = app.murderMgr:GetResPath('ui/home/activity/murder/murder_draw_bg_draw.png'),
    DRAW_ONE_ICON                   = app.murderMgr:GetResPath('ui/home/activity/murder/murder_draw_btn_one.png'),
    DRAW_TEN_ICON                   = app.murderMgr:GetResPath('ui/home/activity/murder/murder_draw_egg_btn_ten.png'),
    DRAW_COST_LABEL_BG              = app.murderMgr:GetResPath('ui/home/activity/murder/murder_draw_label_draw.png'),
    DRAW_TITLE_SHADOW               = app.murderMgr:GetResPath('ui/home/activity/murder/murder_draw_bg_shadow.png'),
    DRAW_LEFT_NUM_BG                = app.murderMgr:GetResPath('ui/home/activity/murder/murder_draw_bg_num.png'),
    LIMITED_BTN                     = app.murderMgr:GetResPath('ui/home/activity/murder/murder_draw_btn_limited.png'),
    LIMITED_LABEL_BG                = app.murderMgr:GetResPath('ui/home/activity/murder/murder_draw_label_limited.png'),
    REWARDS_BTN                     = app.murderMgr:GetResPath('ui/home/activity/murder/murder_draw_btn_rewards.png'),
    -- spine -- 
    MIRROR_SPINE                    = app.murderMgr:GetSpinePath('ui/home/activity/murder/effect/murder_draw_mirror'),
    WATCH_SPINE                     = app.murderMgr:GetSpinePath('ui/home/activity/murder/effect/murder_draw_watch'),
    -- spine -- 
}
function MurderMirrorScene:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function MurderMirrorScene:InitUI()
    local function CreateView()
        local size = display.size
        local view = CLayout:create(size)
        -- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE,enable = true,ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = app.murderMgr:GetPoText(__('真相之镜')), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
		self:addChild(tabNameLabel, 20)
		-- 提示按钮
		local tabtitleTips = display.newImageView(RES_DICT.COMMON_TIPS, 242, 28)
        tabNameLabel:addChild(tabtitleTips, 1)
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, size.width / 2, size.height / 2)
        view:addChild(bg, 1)
        -- 镜子
        local mirrorSpine = sp.SkeletonAnimation:create(
			RES_DICT.MIRROR_SPINE.json,
			RES_DICT.MIRROR_SPINE.atlas,
			1)
		mirrorSpine:update(0)
		mirrorSpine:setToSetupPose()
		mirrorSpine:setAnimation(0, 'idle', true)
		mirrorSpine:setPosition(cc.p(size.width / 2, size.height / 2 - 50))
		view:addChild(mirrorSpine, 2)

        -- 底部ui
        local bottomLayoutSize = cc.size(size.width, 250)
        local bottomLayout = CLayout:create(bottomLayoutSize)
        bottomLayout:setAnchorPoint(cc.p(0.5, 0))
        bottomLayout:setPosition(cc.p(display.cx, 0))
        view:addChild(bottomLayout, 5)
        local bottomBarBg = display.newImageView(RES_DICT.BOTTOM_BG, size.width/2, 0, {ap = cc.p(0.5, 0)})
        bottomLayout:addChild(bottomBarBg, 1)

        -- 抽10次 -- 
        local drawTenBg =  display.newImageView(RES_DICT.DRAW_TEN_ICON, size.width/2 - 550, 0, {ap = cc.p(0.5, 0)})
        bottomLayout:addChild(drawTenBg, 5)
        drawTenBg:setFlippedX(true)
        local drawTenBtn = display.newButton(size.width/2 - 550, 120, {n = RES_DICT.DRAW_BTN})
        bottomLayout:addChild(drawTenBtn, 3)
        local drawTenCostBg = display.newButton(size.width/2 - 550, 30, {n = RES_DICT.DRAW_COST_LABEL_BG, enable = false})
        bottomLayout:addChild(drawTenCostBg, 10)
        local drawTenNumLabel = display.newLabel(98, 33, {text = '10', fontSize = 30, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c1c19', outlineSize = 2}) 
        drawTenCostBg:addChild(drawTenNumLabel, 1)
        local drawTenCostIcon = display.newImageView(app.murderMgr:GetResPath(CommonUtils.GetGoodsIconPathById(GOLD_ID)), 152, 33)
        drawTenCostIcon:setScale(0.25)
        drawTenCostBg:addChild(drawTenCostIcon, 1)
        local drawTenTitle = display.newButton(size.width/2 - 550, 60, {n = RES_DICT.DRAW_TITLE_SHADOW, enable = false})
        bottomLayout:addChild(drawTenTitle, 8)
        display.commonLabelParams(drawTenTitle, {fontSize = 28, text = (app.murderMgr:GetPoText(__("调查10次"))), color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c1c19', outlineSize = 2, offset = cc.p(0, 10)})
        -- 抽10次 -- 

        -- 抽一次 -- 
        local drawOneBg =  display.newImageView(RES_DICT.DRAW_ONE_ICON, size.width/2 + 550, 0, {ap = cc.p(0.5, 0)})
        bottomLayout:addChild(drawOneBg, 5)
        local drawOneBtn = display.newButton(size.width/2 + 550, 110, {n = RES_DICT.DRAW_BTN})
        bottomLayout:addChild(drawOneBtn, 3)
        
        local drawOneCostBg = display.newButton(size.width/2 + 550, 30, {n = RES_DICT.DRAW_COST_LABEL_BG, enable = false})
        bottomLayout:addChild(drawOneCostBg, 10)
        local drawOneNumLabel = display.newLabel(100, 33, {text = '1', fontSize = 30, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c1c19', outlineSize = 2}) 
        drawOneCostBg:addChild(drawOneNumLabel, 1)
        local drawOneCostIcon = display.newImageView(app.murderMgr:GetResPath(CommonUtils.GetGoodsIconPathById(GOLD_ID)), 140, 33)
        drawOneCostIcon:setScale(0.25)
        drawOneCostBg:addChild(drawOneCostIcon, 1)
        local drawOneTitle = display.newButton(size.width/2 + 550, 60, {n = RES_DICT.DRAW_TITLE_SHADOW, enable = false})
        bottomLayout:addChild(drawOneTitle, 8)        
        display.commonLabelParams(drawOneTitle, {fontSize = 28, text = (app.murderMgr:GetPoText(__("调查1次"))), color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c1c19', outlineSize = 2, offset = cc.p(0, 10)})
        -- 抽一次 --

        -- 扭蛋剩余次数
        local leftNumBg = display.newImageView(RES_DICT.DRAW_LEFT_NUM_BG, size.width/2 - 155, 60)
        bottomLayout:addChild(leftNumBg, 3)
        local numComponent = require('Game.views.summerActivity.carnie.JumpingNumberTextComponent').new()
        numComponent:setPosition(cc.p(leftNumBg:getContentSize().width , leftNumBg:getContentSize().height/2))
        numComponent:setAnchorPoint(display.RIGHT_CENTER)
        numComponent:setScale(0.5)
        leftNumBg:addChild(numComponent, 1)
        local turnLabel = display.newLabel(bottomLayoutSize.width/2 - 160, 100, {text = '', fontSize = 20, color = '#f5ba5c'})
        bottomLayout:addChild(turnLabel, 5)
        local leftNumTitle = display.newLabel(bottomLayoutSize.width/2 - 290, 75, {text = (app.murderMgr:GetPoText(__('本轮剩余'))), fontSize = 18, color = '#ffffff', ap = cc.p(0, 0.5)})
        bottomLayout:addChild(leftNumTitle, 5)

        -- 奖励预览
        local capsulePoolBtn = display.newButton(size.width/2 + 165, 58, {n = RES_DICT.REWARDS_BTN})
        bottomLayout:addChild(capsulePoolBtn, 5)
        display.commonLabelParams(capsulePoolBtn, {text = app.murderMgr:GetPoText(__('奖励预览')), color = '#ffffff', fontSize = 24, font = TTF_GAME_FONT, ttf = true, outline = '#5c1c19', outlineSize = 2})

        -- 稀有奖励 --
        local exCapsuleLayoutSize = cc.size(472, 440)
        local exCapsuleLayout = CLayout:create(exCapsuleLayoutSize)
        display.commonUIParams(exCapsuleLayout, {ap = cc.p(1, 0.5), po = cc.p(30 + display.width - display.SAFE_L, display.cy + 200)})
        view:addChild(exCapsuleLayout, 5)
        -- 背景
        local exCapsuleLayoutBg = display.newButton(exCapsuleLayoutSize.width/2, exCapsuleLayoutSize.height/2 + 10, {n = RES_DICT.LIMITED_BTN})
        exCapsuleLayout:addChild(exCapsuleLayoutBg, 1) 
        local exCapsuleTitle = display.newButton(exCapsuleLayoutSize.width/2 + 5, 43, {enable = false, n = RES_DICT.LIMITED_LABEL_BG})
        display.commonLabelParams(exCapsuleTitle, {text = app.murderMgr:GetPoText(__('本轮稀有')), fontSize = 22, color = '#ffffff'})
        exCapsuleLayout:addChild(exCapsuleTitle, 3)
        local exCapsuleView = CLayout:create(exCapsuleLayoutSize)
        exCapsuleView:setPosition(cc.p(exCapsuleLayoutSize.width/2, exCapsuleLayoutSize.height/2))
        exCapsuleLayout:addChild(exCapsuleView, 5)
        -- 稀有奖励 --
        
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
            view              = view,
            tabNameLabel      = tabNameLabel,
            bottomLayoutSize  = bottomLayoutSize,
            bottomLayout      = bottomLayout,
            drawTenBtn        = drawTenBtn,
            drawOneBtn        = drawOneBtn,
            capsulePoolBtn    = capsulePoolBtn,
            topUILayer		  = topUILayer,
            moneyBarBg        = moneyBarBg,
            moneyLayer        = moneyLayer,
            exCapsuleLayoutSize = exCapsuleLayoutSize,
            exCapsuleLayout   = exCapsuleLayout,
            exCapsuleLayoutBg = exCapsuleLayoutBg,
            exCapsuleView     = exCapsuleView,
            numComponent      = numComponent,
            turnLabel         = turnLabel,
            drawOneCostIcon   = drawOneCostIcon,
            drawTenCostIcon   = drawTenCostIcon,
            mirrorSpine       = mirrorSpine,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
入场动画
--]]
function MurderMirrorScene:EnterAction()
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
function MurderMirrorScene:ReloadMoneyBar(moneyIdMap, isDisableGain)
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
        local isDisable = moneyId ~= GOLD_ID and moneyId ~= DIAMOND_ID and isDisableGain
        local moneyNode = GoodPurchaseNode.new({id = moneyId, animate = true, disable = isDisable, isEnableGain = not isDisableGain})
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

    -- update money value
    self:UpdateMoneyBar()
end
--[[
更新货币栏
--]]
function MurderMirrorScene:UpdateMoneyBar()
    for _, moneyNode in ipairs(self:GetViewData().moneyLayer:getChildren()) do
        local moneyId = checkint(moneyNode:getName())
        moneyNode:updataUi(moneyId)
    end
end
--[[
获取viewData
--]]
function MurderMirrorScene:GetViewData()
    return self.viewData
end
return MurderMirrorScene