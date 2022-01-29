--[[
游乐园（夏活）扭蛋view
--]]
-- local CarnieCapsuleView = class('CarnieCapsuleView', function ()
--     local node = CLayout:create(display.size)
--     node.name = 'home.CarnieCapsuleView'
--     node:enableNodeEvents()
--     return node
-- end)
local GameScene = require('Frame.GameScene')
local CarnieCapsuleView = class('CarnieCapsuleView', GameScene)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local summerActMgr = app.summerActMgr
local GoodPurchaseNode = require('common.GoodPurchaseNode')

local RES_DICT_ = {
    COMMON_TITLE_NEW           = _res('ui/common/common_title_new.png'),
    COMMON_BTN_TIPS            = _res('ui/common/common_btn_tips.png'),
    COMMON_HINT_CIRCLE_RED_ICO = _res('ui/common/common_hint_circle_red_ico.png'),
    MAIN_BG_MONEY              = _res('ui/home/nmain/main_bg_money.png'),

    SUMMER_ACTIVITY_EGG_BG_TIME = _res('ui/home/activity/carnieTheme/base/summer_activity_egg_bg_time.png'),
    SUMMER_ACTIVITY_EGG_LINE_NUM = _res('ui/home/activity/carnieTheme/base/summer_activity_egg_line_num.png'),

    SUMMER_ACTIVITY_EGG_BG = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_bg.jpg'),
    SUMMER_ACTIVITY_EGG_BG_BELOW = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_bg_below.png'),
    SUMMER_ACTIVITY_EGG_BG_DRAW = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_bg_draw.png'),
    SUMMER_ACTIVITY_EGG_BTN_TEN = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_btn_ten.png'),
    SUMMER_ACTIVITY_EGG_LABEL_DRAW = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_label_draw.png'),
    SUMMER_ACTIVITY_EGG_LABEL_LIMITED = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_label_limited.png'),
    SUMMER_ACTIVITY_EGG_BTN_ONE = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_btn_one.png'),
    SUMMER_ACTIVITY_EGG_BG_NUM = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_bg_num.png'),
    SUMMER_ACTIVITY_EGG_BTN_REWARDS = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_btn_rewards.png'),
    SUMMER_ACTIVITY_EGG_BG_EXTRA = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_bg_extra.png'),
    SUMMER_ACTIVITY_EGG_BG_EXTRA_LIGHT = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_bg_extra_light.png'),
    SUMMER_ACTIVITY_EGG_BG_EXTRA_SHADOW = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_bg_extra_shadow.png'),
    SUMMER_ACTIVITY_EGG_EXTRA_BAR_ACTIVE = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_extra_bar_active.png'),
    SUMMER_ACTIVITY_EGG_EXTRA_BAR_GREY = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_extra_bar_grey.png'),
    SUMMER_ACTIVITY_EGG_LABEL_EXTRA = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_label_extra.png'),
    SUMMER_ACTIVITY_EGG_BTN_LIMITED = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_btn_limited.png'),

    SPINE_ACTIVITY_NIUDANJI_PATH        = 'ui/home/activity/summerActivity/carnie/effects/summer_activity_niudanji'
}

local RES_DICT = {}

function CarnieCapsuleView:ctor( ... )
    RES_DICT = summerActMgr:resetResPath(RES_DICT_)
    RES_DICT.SPINE_ACTIVITY_NIUDANJI = _spn(RES_DICT.SPINE_ACTIVITY_NIUDANJI_PATH)
    

    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function CarnieCapsuleView:InitUI()
    local function CreateView()
        local bgSize = display.size
        local view = CLayout:create(bgSize)
		-- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE_NEW, enable = true, ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = summerActMgr:getThemeTextByText(__('扭蛋机')), fontSize = 30, color = '473227',offset = cc.p(0,-8), reqW = 220})
		self:addChild(tabNameLabel, 20)
		local tabtitleTips = display.newImageView(RES_DICT.COMMON_BTN_TIPS, 270, 28)
        tabNameLabel:addChild(tabtitleTips, 1)
        -- 背景
        local bg = display.newImageView(RES_DICT.SUMMER_ACTIVITY_EGG_BG, display.cx, display.cy)
        view:addChild(bg, 1)
        -- 小丑
        local jokerSpine = sp.SkeletonAnimation:create(
            RES_DICT.SPINE_ACTIVITY_NIUDANJI.json,
            RES_DICT.SPINE_ACTIVITY_NIUDANJI.atlas,
        1)
        jokerSpine:update(0)
        jokerSpine:setToSetupPose()
        jokerSpine:setAnimation(0, 'idle', true)
        jokerSpine:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        jokerSpine:setScale(0.85)
        view:addChild(jokerSpine, 2)

        -- 底部ui
        local bottomLayoutSize = cc.size(bgSize.width, 250)
        local bottomLayout = CLayout:create(bottomLayoutSize)
        bottomLayout:setAnchorPoint(cc.p(0.5, 0))
        bottomLayout:setPosition(cc.p(display.cx, 0))
        view:addChild(bottomLayout, 5)
        local bottomBarBg = display.newImageView(RES_DICT.SUMMER_ACTIVITY_EGG_BG_BELOW, bgSize.width/2, 0, {ap = cc.p(0.5, 0)})
        bottomLayout:addChild(bottomBarBg, 1)
        -- 抽10次 -- 
        local drawTenBg =  display.newImageView(RES_DICT.SUMMER_ACTIVITY_EGG_BG_DRAW, bgSize.width/2 - 550, 0, {ap = cc.p(0.5, 0)})
        bottomLayout:addChild(drawTenBg, 3)
        drawTenBg:setFlippedX(true)
        local drawTenBtn = display.newButton(bgSize.width/2 - 550, 120, {n = RES_DICT.SUMMER_ACTIVITY_EGG_BTN_TEN})
        bottomLayout:addChild(drawTenBtn, 5)
        local drawTenCostBg = display.newButton(bgSize.width/2 - 550, 30, {n = RES_DICT.SUMMER_ACTIVITY_EGG_LABEL_DRAW, enable = false})
        bottomLayout:addChild(drawTenCostBg, 10)
        local drawTenNumLabel = display.newLabel(98, 33, {text = '10', fontSize = 30, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c1c19', outlineSize = 2}) 
        drawTenCostBg:addChild(drawTenNumLabel, 1)
        local drawTenCostIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(app.summerActMgr:getCurCarnieCoin())), 152, 33)
        drawTenCostIcon:setScale(0.25)
        drawTenCostBg:addChild(drawTenCostIcon, 1)
        local drawTenTitle = display.newButton(bgSize.width/2 - 550, 60, {n = RES_DICT.SUMMER_ACTIVITY_EGG_LABEL_LIMITED, enable = false})
        bottomLayout:addChild(drawTenTitle, 8)
        display.commonLabelParams(drawTenTitle, {fontSize = 28, text = summerActMgr:getThemeTextByText(__("扭10次")), color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c1c19', outlineSize = 2, offset = cc.p(0, 10)})
        -- 抽10次 -- 
        -- 抽一次 -- 
        local drawOneBg =  display.newImageView(RES_DICT.SUMMER_ACTIVITY_EGG_BG_DRAW, bgSize.width/2 + 550, 0, {ap = cc.p(0.5, 0)})
        bottomLayout:addChild(drawOneBg, 3)
        local drawOneBtn = display.newButton(bgSize.width/2 + 550, 110, {n = RES_DICT.SUMMER_ACTIVITY_EGG_BTN_ONE})
        bottomLayout:addChild(drawOneBtn, 5)
        
        local drawOneCostBg = display.newButton(bgSize.width/2 + 550, 30, {n = RES_DICT.SUMMER_ACTIVITY_EGG_LABEL_DRAW, enable = false})
        bottomLayout:addChild(drawOneCostBg, 10)
        local drawOneNumLabel = display.newLabel(100, 33, {text = '1', fontSize = 30, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c1c19', outlineSize = 2}) 
        drawOneCostBg:addChild(drawOneNumLabel, 1)
        local drawOneCostIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(app.summerActMgr:getCurCarnieCoin())), 140, 33)
        drawOneCostIcon:setScale(0.25)
        drawOneCostBg:addChild(drawOneCostIcon, 1)
        local drawOneTitle = display.newButton(bgSize.width/2 + 550, 60, {n = RES_DICT.SUMMER_ACTIVITY_EGG_LABEL_LIMITED, enable = false})
        bottomLayout:addChild(drawOneTitle, 8)        
        display.commonLabelParams(drawOneTitle, {fontSize = 28, text = summerActMgr:getThemeTextByText(__("扭1次")), color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c1c19', outlineSize = 2, offset = cc.p(0, 10)})
        -- 抽一次 --

        -- 扭蛋剩余次数
        local leftNumBg = display.newImageView(RES_DICT.SUMMER_ACTIVITY_EGG_BG_NUM, bgSize.width/2 - 270, 60)
        bottomLayout:addChild(leftNumBg, 3)
        local numComponent = require('Game.views.summerActivity.carnie.JumpingNumberTextComponent').new()
        numComponent:setPosition(cc.p(leftNumBg:getContentSize().width/2 - 5, leftNumBg:getContentSize().height/2 + 15))
        leftNumBg:addChild(numComponent, 1)
        local leftNumLine = display.newNSprite(RES_DICT.SUMMER_ACTIVITY_EGG_LINE_NUM, leftNumBg:getPositionX(), 42)
        bottomLayout:addChild(leftNumLine, 5)
        local leftNumTitle = display.newLabel(bgSize.width/2 - 270, 27, {text = summerActMgr:getThemeTextByText(__('剩余扭蛋')), fontSize = 20, color = '#ffbf6c'})
        bottomLayout:addChild(leftNumTitle, 5)

        -- 今日蛋池
        local capsulePoolBtn = display.newButton(bgSize.width/2 + 30, 58, {n = RES_DICT.SUMMER_ACTIVITY_EGG_BTN_REWARDS})
        bottomLayout:addChild(capsulePoolBtn, 5)
        display.commonLabelParams(capsulePoolBtn, {text = summerActMgr:getThemeTextByText(__('今日蛋池')), color = '#ffffff', fontSize = 28, font = TTF_GAME_FONT, ttf = true, outline = '#5c1c19', outlineSize = 2, reqW = 250})

        -- 刷新时间
        local refreshTimeBg = display.newNSprite(RES_DICT.SUMMER_ACTIVITY_EGG_BG_TIME, bgSize.width/2 + 300, 55 , {ap = display.CENTER , size = cc.size(180,100) , scale9 = true  })
        bottomLayout:addChild(refreshTimeBg, 5 )

        local refreshTimeTitle = display.newLabel(bgSize.width/2 + 295, 75, {text = summerActMgr:getThemeTextByText(__('扭蛋上新')), color = '#ffa32d', fontSize = 20, w = 180, hAlign = cc.TEXT_ALIGNMENT_CENTER})
        bottomLayout:addChild(refreshTimeTitle, 5)
        local refreshTimeLabel = display.newLabel(bgSize.width/2 + 295, 40, {text = '00:00:00', color = '#ffffff', fontSize = 24})
        bottomLayout:addChild(refreshTimeLabel, 5)

        -- 累计扭蛋奖励 --
        local accRewardLayoutSize = cc.size(280, 240)
        local accRewardLayout = CLayout:create(accRewardLayoutSize)
        display.commonUIParams(accRewardLayout, {ap = cc.p(0, 0.5), po = cc.p(display.SAFE_L, display.cy + 100)})
        view:addChild(accRewardLayout, 5)
        -- 背景
        local accRewardBg = display.newButton(accRewardLayoutSize.width/2, 15, {ap = cc.p(0.5, 0), n = RES_DICT.SUMMER_ACTIVITY_EGG_BG_EXTRA})
        accRewardLayout:addChild(accRewardBg, 3)
        local accRewardBgLight = display.newImageView(RES_DICT.SUMMER_ACTIVITY_EGG_BG_EXTRA_LIGHT, accRewardLayoutSize.width/2, 15, {ap = cc.p(0.5, 0)})
        accRewardLayout:addChild(accRewardBgLight, 1)
        -- 小红点
        local accRemindIcon = display.newImageView(RES_DICT.COMMON_HINT_CIRCLE_RED_ICO, accRewardLayoutSize.width - 40, 154)
        accRewardLayout:addChild(accRemindIcon, 5)
        -- 进度条
        local accProgressBarBg = display.newImageView(RES_DICT.SUMMER_ACTIVITY_EGG_BG_EXTRA_SHADOW, accRewardLayoutSize.width/2, 48)
        accRewardLayout:addChild(accProgressBarBg, 3)
        local accProgressBar = CProgressBar:create(RES_DICT.SUMMER_ACTIVITY_EGG_EXTRA_BAR_ACTIVE)
        accProgressBar:setBackgroundImage(RES_DICT.SUMMER_ACTIVITY_EGG_EXTRA_BAR_GREY)
        accProgressBar:setDirection(eProgressBarDirectionLeftToRight)
        accProgressBar:setPosition(cc.p(accRewardLayoutSize.width/2, 48))
        accRewardLayout:addChild(accProgressBar, 5)
        local accProgressLabel = display.newLabel(accRewardLayoutSize.width/2, 48, {text = '', fontSize = 20, color = '#ffffff'})
        accRewardLayout:addChild(accProgressLabel, 10)
        local accRewardTitle = display.newButton(accRewardLayoutSize.width/2, 18, {n = RES_DICT.SUMMER_ACTIVITY_EGG_LABEL_EXTRA})
        display.commonLabelParams(accRewardTitle, {fontSize = 20, text = summerActMgr:getThemeTextByText(__("累计扭蛋奖励")), color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c1c19', outlineSize = 2})
        accRewardLayout:addChild(accRewardTitle, 5)
        -- 累计扭蛋奖励 --
        -- 特典扭蛋 --
        local exCapsuleLayoutSize = cc.size(472, 440)
        local exCapsuleLayout = CLayout:create(exCapsuleLayoutSize)
        display.commonUIParams(exCapsuleLayout, {ap = cc.p(1, 0.5), po = cc.p(70 + display.width - display.SAFE_L, display.cy + 210)})
        view:addChild(exCapsuleLayout, 5)
        -- 背景
        local exCapsuleLayoutBg = display.newButton(exCapsuleLayoutSize.width/2, exCapsuleLayoutSize.height/2 + 10, {n = RES_DICT.SUMMER_ACTIVITY_EGG_BTN_LIMITED})
        exCapsuleLayout:addChild(exCapsuleLayoutBg, 1) 
        local exCapsuleTitle = display.newButton(exCapsuleLayoutSize.width/2 + 5, 43, {enable = false, n = RES_DICT.SUMMER_ACTIVITY_EGG_LABEL_LIMITED})
        display.commonLabelParams(exCapsuleTitle, {text = summerActMgr:getThemeTextByText(__('今日特典扭蛋')), fontSize = 22, color = '#ffffff'})
        exCapsuleLayout:addChild(exCapsuleTitle, 3)
        local exCapsuleView = CLayout:create(exCapsuleLayoutSize)
        exCapsuleView:setPosition(cc.p(exCapsuleLayoutSize.width/2, exCapsuleLayoutSize.height/2))
        exCapsuleLayout:addChild(exCapsuleView, 5)
        -- 特典扭蛋 --
	    -- 重写顶部状态条 -- 
        local topLayoutSize = cc.size(display.width, 80)
        local moneyNode = CLayout:create(topLayoutSize)
        moneyNode:setName('TOP_LAYOUT')
        display.commonUIParams(moneyNode, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
        view:addChild(moneyNode,100)

        -- local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
        -- display.commonUIParams(backBtn, {po = cc.p(backBtn:getContentSize().width * 0.5 + 30, topLayoutSize.height - 18 - backBtn:getContentSize().height * 0.5)})
        -- backBtn:setName('btn_backButton')
        -- moneyNode:addChild(backBtn, 5)
        -- top icon
        local imageImage = display.newImageView(RES_DICT.MAIN_BG_MONEY,0,0,{enable = false,
        scale9 = true, size = cc.size(680 + (display.width - display.SAFE_R),54)})
        display.commonUIParams(imageImage,{ap = cc.p(1.0,1.0), po = cc.p(display.width,80)})
        moneyNode:addChild(imageImage)
        local moneyNods = {}
        local iconData = {app.summerActMgr:getCurCarnieCoin(), GOLD_ID, DIAMOND_ID}
        for i,v in ipairs(iconData) do
	    	local isShowHpTips = (v == HP_ID) and 1 or -1
            local purchaseNode = GoodPurchaseNode.new({id = v, isShowHpTips = isShowHpTips})
            display.commonUIParams(purchaseNode,
            {ap = cc.p(1, 0.5), po = cc.p(topLayoutSize.width - 30 - display.SAFE_L - (( #iconData - i) * (purchaseNode:getContentSize().width + 16)), imageImage:getPositionY()- 26)})
            moneyNode:addChild(purchaseNode, 5)
            purchaseNode:setName('purchaseNode' .. i)
            purchaseNode.viewData.touchBg:setTag(checkint(v))
            moneyNods[tostring( v )] = purchaseNode
        end
        -- 重写顶部状态条 -- 
        return {
            view             = view,
            tabNameLabel     = tabNameLabel, 
            tabNameLabelPos  = cc.p(tabNameLabel:getPosition()),
            bottomLayoutSize = bottomLayoutSize,
            bottomLayout     = bottomLayout,
            drawTenBtn       = drawTenBtn,
            drawOneBtn       = drawOneBtn,
            capsulePoolBtn   = capsulePoolBtn,
            refreshTimeLabel = refreshTimeLabel,
            accRewardLayoutSize = accRewardLayoutSize,
            accRewardLayout  = accRewardLayout,
            accRewardBg      = accRewardBg,
            accRemindIcon    = accRemindIcon,
            accProgressBar   = accProgressBar,
            accProgressLabel = accProgressLabel,
            exCapsuleLayoutSize = exCapsuleLayoutSize,
            exCapsuleLayout  = exCapsuleLayout,
            exCapsuleLayoutBg = exCapsuleLayoutBg,
            exCapsuleView    = exCapsuleView,
            moneyNods        = moneyNods,
            jokerSpine       = jokerSpine,
            numComponent     = numComponent,
            accRewardTitle   = accRewardTitle, 
            accRewardBgLight = accRewardBgLight,
        }

    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
    end, __G__TRACKBACK__)
	-- 弹出标题板
	self.viewData.tabNameLabel:setPositionY(display.height + 100)
	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData.tabNameLabelPos))
	self.viewData.tabNameLabel:runAction( action )
end
return CarnieCapsuleView