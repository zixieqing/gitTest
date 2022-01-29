local GameScene = require( "Frame.GameScene" )
---@class ScratcherPlatformView :GameScene
local ScratcherPlatformView = class("ScratcherPlatformView", GameScene)

local RES_DICT          = {
	NAV_BACK                        = _res("ui/common/common_btn_back.png"),
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
	COMMON_BTN_ORANGE_BIG           = _res('ui/common/common_btn_orange_big.png'),
	COMMON_BTN_TIPS                 = _res('ui/common/common_btn_tips.png'),
    MAIN_BTN_RANK                   = _res('ui/home/nmain/main_btn_rank.png'),
    BOOSSTRATEGY_RANKS_NAME_BG      = _res('ui/home/activity/saimoe/boosstrategy_ranks_name_bg.png'),
    STARPLAN_PK_TITLE               = _res('ui/home/activity/saimoe/starplan_pk_title.png'),
    STARPLAN_TITLE                  = _res('ui/home/activity/saimoe/starplan_title.png'),
    STARPLAN_VS_ICON_VS             = _res('ui/home/activity/saimoe/starplan_vs_icon_vs.png'),
    STARPLAN_VS_LEFT_TICKET_BG      = _res('ui/home/activity/saimoe/starplan_vs_left_ticket_bg.png'),
    STARPLAN_VS_NAME_BG             = _res('ui/home/activity/saimoe/starplan_vs_name_bg.png'),
    STARPLAN_VS_RIGHT_TICKET_BG     = _res('ui/home/activity/saimoe/starplan_vs_right_ticket_bg.png'),
    STARPLAN_MAIN_ICON_LIGHT        = _res('ui/common/starplan_main_icon_light.png'),
    STARPLAN_MAIN_FRAME_BTN_NAME    = _res('ui/common/starplan_main_frame_btn_name.png'),
    MELTING_BG_TIPS                 = _res('ui/pet/smelting/melting_bg_tips.png'),
}

function ScratcherPlatformView:ctor( ... )
	GameScene.ctor(self, 'Game.views.scratcher.ScratcherPlatformView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ScratcherPlatformView:InitUI()
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 130))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    
	local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        view:setName('ScratcherPlatformView')
        self:addChild(view)

        local leftDrawNode = display.newLayer(display.cx - 370, display.cy - 0)
        view:addChild(leftDrawNode, -1)

        local leftSpoon = sp.SkeletonAnimation:create("ui/guide/guide_ico_hand.json","ui/guide/guide_ico_hand.atlas", 0.75)
        leftSpoon:setPosition(cc.p(display.cx - 370, display.cy - 10))
        leftSpoon:update(0)
        leftSpoon:setAnimation(0, 'idle', true)
        view:addChild(leftSpoon, 10)

        local rightDrawNode = display.newLayer(display.cx - -372, display.cy - 0)
        view:addChild(rightDrawNode, -1)

        local rightSpoon = sp.SkeletonAnimation:create("ui/guide/guide_ico_hand.json","ui/guide/guide_ico_hand.atlas", 0.75)
        rightSpoon:setPosition(cc.p(display.cx + 340, display.cy - 10))
        rightSpoon:update(0)
        rightSpoon:setAnimation(0, 'idle', true)
        view:addChild(rightSpoon, 10)

        ------------------topView start-------------------
        local topView = display.newLayer(0, display.height,
        {
            ap = cc.p(0, 1.0),
            size = cc.size(display.width, 100),
            enable = false,
        })
        view:addChild(topView)

        local timeBG = display.newImageView(RES_DICT.STARPLAN_TITLE, display.cx - -18, 100,
        {
            ap = display.CENTER_TOP,
        })
        topView:addChild(timeBG)

        local tipsBtn = display.newButton(display.cx - -220, 68,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_TIPS,
            enable = true,
        })
        -- display.commonLabelParams(tipsBtn, fontWithColor(14, {text = ''})
        topView:addChild(tipsBtn)

        local timeTitleLabel = display.newLabel(display.cx - -12, 69,
        {
            text = __('比赛剩余时间：'),
            ap = display.RIGHT_CENTER,
            fontSize = 22,
            color = '#ffffff',
        })
        topView:addChild(timeTitleLabel)

        local timeLabel = display.newLabel(display.cx - -11, 70,
        {
            text = '',
            ap = display.LEFT_CENTER,
            fontSize = 28,
            color = '#ffd042',
        })
        topView:addChild(timeLabel)

        -------------------topView end--------------------
        local titleLabel = display.newButton(display.cx - -1, display.height - 182,
        {
            ap = display.CENTER,
            n = RES_DICT.STARPLAN_PK_TITLE,
            enable = false,
        })
        display.commonLabelParams(titleLabel, fontWithColor(14, {text = __('飨灵明星计划'), fontSize = 48, color = '#fff5ce', outline = '#ff7200', offset = cc.p(-4, -2)}))
        view:addChild(titleLabel)

        -----------------leftLayout start-----------------
        local leftLayout = display.newLayer(0, 0,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(display.width, 200),
            enable = false,
        })
        view:addChild(leftLayout)

        local nameLabel = display.newButton(display.cx - 339, 205,
        {
            ap = display.CENTER,
            n = RES_DICT.STARPLAN_VS_NAME_BG,
            enable = false,
        })
        display.commonLabelParams(nameLabel, {text = '', fontSize = 26, color = '#960000'})
        leftLayout:addChild(nameLabel)
        leftLayout.nameLabel = nameLabel

        ---------------supportTipView start---------------
        local supportTipViewL = display.newLayer(display.cx - 527, display.cy - 131,
                {
                    ap = display.LEFT_BOTTOM,
                    size = cc.size(400, 50),
                    enable = false,
                })
        leftLayout:addChild(supportTipViewL)

        local tipsBG = display.newImageView(RES_DICT.MELTING_BG_TIPS, 187, 5,
                {
                    ap = display.CENTER,
                })
        tipsBG:setScale(0.7, 0.7)
        supportTipViewL:addChild(tipsBG)

        local tipsLabel = display.newLabel(189, 7,
                {
                    text = __('选择你支持的飨灵'),
                    ap = display.CENTER,
                    fontSize = 26,
                    color = '#ffffff',
                    font = TTF_GAME_FONT, ttf = true,
                    outline = '#5b3c25',
                })
        supportTipViewL:addChild(tipsLabel)

        ----------------supportTipView end----------------
        ------------------leftLayout end------------------
        ----------------rightLayout start-----------------
        local rightLayout = display.newLayer(0, 0,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(display.width, 200),
            enable = false,
        })
        view:addChild(rightLayout)

        local nameLabel = display.newButton(display.cx - -372, 206,
        {
            ap = display.CENTER,
            n = RES_DICT.STARPLAN_VS_NAME_BG,
            enable = false,
        })
        display.commonLabelParams(nameLabel, {text = '', fontSize = 26, color = '#960000'})
        rightLayout:addChild(nameLabel)
        rightLayout.nameLabel = nameLabel

        ---------------supportTipView start---------------
        local supportTipViewR = display.newLayer(display.cx - -180, display.cy - 131,
                {
                    ap = display.LEFT_BOTTOM,
                    size = cc.size(400, 50),
                    enable = false,
                })
        rightLayout:addChild(supportTipViewR)

        local tipsBG = display.newImageView(RES_DICT.MELTING_BG_TIPS, 187, 5,
                {
                    ap = display.CENTER,
                })
        tipsBG:setScale(0.7, 0.7)
        supportTipViewR:addChild(tipsBG)

        local tipsLabel = display.newLabel(189, 7,
                {
                    text = __('选择你支持的飨灵'),
                    ap = display.CENTER,
                    fontSize = 26,
                    color = '#ffffff',
                    font = TTF_GAME_FONT, ttf = true,
                    outline = '#5b3c25',
                })
        supportTipViewR:addChild(tipsLabel)

        ----------------supportTipView end----------------

        local leftSupportBtn = display.newButton(display.cx - 370, display.cy - 10,
        {
            ap = display.CENTER,
            --n = RES_DICT.COMMON_BTN_ORANGE_BIG,
            enable = true,
            tag = 1,
            size = cc.size(200, 200)
        })
        --display.commonLabelParams(leftSupportBtn, fontWithColor(14, {text = __('支持'), fontSize = 30, color = '#ffffff'}))
        view:addChild(leftSupportBtn)

        local rightSupportBtn = display.newButton(display.cx + 340, display.cy - 10,
        {
            ap = display.CENTER,
            --n = RES_DICT.COMMON_BTN_ORANGE_BIG,
            enable = true,
            tag = 2,
            size = cc.size(200, 200)
        })
        --display.commonLabelParams(rightSupportBtn, fontWithColor(14, {text = __('支持'), fontSize = 30, color = '#ffffff'}))
        view:addChild(rightSupportBtn)

        -----------------rightLayout end------------------

		local backBtn = display.newButton(0, 0, {n = RES_DICT.NAV_BACK})
		display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
        backBtn:setName('NAV_BACK')
		view:addChild(backBtn, 5)


		return {
            view                    = view,
            leftDrawNode            = leftDrawNode,
            rightDrawNode           = rightDrawNode,
            topView                 = topView,
            timeBG                  = timeBG,
            tipsBtn                 = tipsBtn,
            timeTitleLabel          = timeTitleLabel,
            timeLabel               = timeLabel,
            titleLabel              = titleLabel,
            leftLayout              = leftLayout,
            rightLayout             = rightLayout,
            leftSpoon               = leftSpoon,
            rightSpoon              = rightSpoon,
            supportTipViewL         = supportTipViewL,
            supportTipViewR         = supportTipViewR,
            leftSupportBtn          = leftSupportBtn,
            rightSupportBtn         = rightSupportBtn,
            backBtn                 = backBtn,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

function ScratcherPlatformView:setLeftBgImg(imgId)
    self.viewData.leftDrawNode:removeAllChildren()
    local imgPath = _res('ui/home/activity/saimoe/starplan_vs_left_bg_' .. imgId)
    self.viewData.leftDrawNode:addChild(display.newImageView(imgPath))
end

function ScratcherPlatformView:setRightBgImg(imgId)
    self.viewData.rightDrawNode:removeAllChildren()
    local imgPath = _res('ui/home/activity/saimoe/starplan_vs_right_bg_' .. imgId)
    self.viewData.rightDrawNode:addChild(display.newImageView(imgPath))
end

function ScratcherPlatformView:ShowEnterAni( cb )
    local viewData = self.viewData

    local drawNodeMoveDistance = 100
    local leftDrawNode = viewData.leftDrawNode
    leftDrawNode:setPositionY(leftDrawNode:getPositionY() - drawNodeMoveDistance)
    transition.execute(leftDrawNode, cc.EaseInOut:create(
        cc.MoveBy:create(4 / 30, cc.p(0, drawNodeMoveDistance)), 2
    ))

    local rightDrawNode = viewData.rightDrawNode
    rightDrawNode:setPositionY(rightDrawNode:getPositionY() + drawNodeMoveDistance)
    transition.execute(rightDrawNode, cc.EaseInOut:create(
        cc.MoveBy:create(4 / 30, cc.p(0, -drawNodeMoveDistance)), 2
    ))
    
    local topViewMoveDistance = 22
    local topView = viewData.topView
    topView:setPositionY(display.height + topViewMoveDistance)
    topView:setOpacity(0)
    transition.execute(topView,cc.Spawn:create(
            cc.MoveBy:create(10 / 30, cc.p(0, -topViewMoveDistance)),
            cc.FadeIn:create(8 / 30)
        ), {delay = 15 / 30})	
        
    local titleLabelMoveDistance = 350
    local titleLabel = viewData.titleLabel
    titleLabel:setPositionY(titleLabel:getPositionY() + titleLabelMoveDistance)
    titleLabel:setOpacity(0)
    transition.execute(titleLabel, cc.Spawn:create(
        cc.EaseBackOut:create(
            cc.MoveBy:create(10 / 30, cc.p(0, -titleLabelMoveDistance))
        ),
        cc.FadeIn:create(5 / 30)
    ), {delay = 5 / 30})

    local nameLabel = viewData.leftLayout.nameLabel
    nameLabel:setOpacity(0)
    transition.execute(nameLabel, cc.FadeIn:create(10 / 30), {delay = 15 / 30})

    local nameLabel = viewData.rightLayout.nameLabel
    nameLabel:setOpacity(0)
    transition.execute(nameLabel, cc.FadeIn:create(10 / 30), {delay = 15 / 30, complete = cb})

end

return ScratcherPlatformView