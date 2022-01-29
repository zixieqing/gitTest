--[[
    燃战擂台界面
--]]
local GameScene = require( "Frame.GameScene" )
---@class SaiMoePlatformView :GameScene
local SaiMoePlatformView = class("SaiMoePlatformView", GameScene)
local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local uiMgr = shareFacade:GetManager("UIManager")

local RES_DICT          = {
	NAV_BACK                        = _res("ui/common/common_btn_back.png"),
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
	COMMON_BTN_ORANGE_BIG           = _res('ui/common/common_btn_orange_big.png'),
	COMMON_BTN_TIPS                 = _res('ui/common/common_btn_tips.png'),
    MAIN_BTN_RANK                   = _res('ui/home/nmain/main_btn_rank.png'),
    BG_LEFT                         = _resEx('ui/home/activity/saimoe/starplan_vs_left_bg', nil, "remastered1"),
    BG_RIGHT                        = _resEx('ui/home/activity/saimoe/starplan_vs_right_bg', nil, "remastered1"),
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

function SaiMoePlatformView:ctor( ... )
	GameScene.ctor(self, 'Game.views.saimoe.SaiMoePlatformView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function SaiMoePlatformView:InitUI()
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 130))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    
	local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        view:setName('SaiMoePlatformView')
        self:addChild(view)

        local ligthImg = display.newImageView(RES_DICT.STARPLAN_MAIN_ICON_LIGHT, display.SAFE_R - 63, display.height - 64,
                {
                    ap = display.CENTER,
                })
        view:addChild(ligthImg)

        local rankingBG = display.newImageView(RES_DICT.STARPLAN_MAIN_FRAME_BTN_NAME, display.SAFE_R - 61, display.height - 104,
                {
                    ap = display.CENTER,
                })
        view:addChild(rankingBG)

        -----------------rankingBtn start-----------------
        local rankingBtn = display.newButton(display.SAFE_R - 61, display.height - 55,
                {
                    ap = display.CENTER,
                    n = RES_DICT.MAIN_BTN_RANK,
                    enable = true,
                })
        -- display.commonLabelParams(rankingBtn, fontWithColor(14, {text = ''})
        view:addChild(rankingBtn)

        local rankingLabel = display.newLabel(44, -4,
                {
                    text = __('排行榜'),
                    ap = display.CENTER,
                    fontSize = 24,
                    color = '#ffffff',
                    font = TTF_GAME_FONT, ttf = true,
                    outline = '#5b3c25',
                })
        rankingBtn:addChild(rankingLabel)

        ------------------rankingBtn end------------------

        local leftDrawNode = display.newImageView(RES_DICT.BG_LEFT, display.cx - 370, display.cy - 0,
                {
                    ap = display.CENTER,
                })
        view:addChild(leftDrawNode, -1)

        local leftSpoon = sp.SkeletonAnimation:create("ui/guide/guide_ico_hand.json","ui/guide/guide_ico_hand.atlas", 0.75)
        leftSpoon:setPosition(cc.p(display.cx - 370, display.cy - 10))
        leftSpoon:update(0)
        leftSpoon:setAnimation(0, 'idle', true)
        view:addChild(leftSpoon, 10)

        local rightDrawNode = display.newImageView(RES_DICT.BG_RIGHT, display.cx - -372, display.cy - 0,
                {
                    ap = display.CENTER,
                })
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

        --local timeTitleLabel = display.newLabel(display.cx - -12, 69,
        --{
        --    text = __('比赛剩余时间：'),
        --    ap = display.RIGHT_CENTER,
        --    fontSize = 22,
        --    color = '#ffffff',
        --})
        --topView:addChild(timeTitleLabel)

        local timeLabel = display.newRichLabel(display.cx, 70, {
          c = {{
                   text = '',
                   ap = display.LEFT_CENTER,
                   fontSize = 28,
                   color = '#ffd042'
               }}
        })
        topView:addChild(timeLabel)

        -------------------topView end--------------------
        local titleLabel = display.newButton(display.cx - -1, display.height - 182,
        {
            ap = display.CENTER,
            n = RES_DICT.STARPLAN_PK_TITLE,
            scale9 = true ,
            enable = false,
        })
        display.commonLabelParams(titleLabel, fontWithColor(14, {paddingW = 100,  text = __('飨灵明星计划'), fontSize = 48, color = '#fff5ce', outline = '#ff7200', offset = cc.p(-4, -2)}))
        view:addChild(titleLabel)

        local previewBtn = display.newButton(display.cx - -2, display.cy - 120,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,scale9 = true
        })
        display.commonLabelParams(previewBtn, fontWithColor(14, {text = __('获胜奖励'), paddingW = 20 ,  fontSize = 24, color = '#ffffff'}))
        view:addChild(previewBtn)

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

        local barImg = display.newImageView(RES_DICT.STARPLAN_VS_LEFT_TICKET_BG, display.cx - 203, 111,
        {
            ap = display.RIGHT_CENTER,
        })
        leftLayout:addChild(barImg)
        leftLayout.barImg = barImg

        -----------------valueView start------------------
        local valueView = display.newLayer(display.cx - 667, 60,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(400, 100),
            enable = false,
        })
        leftLayout:addChild(valueView)
        leftLayout.valueView = valueView

        local peopleTitleLabel = display.newLabel(47, 22,
        {
            text = __('支持人数：'),
            ap = display.LEFT_CENTER,
            fontSize = 21,
            color = '#5b3c25',
        })
        valueView:addChild(peopleTitleLabel)
        local peopleTitleSize = display.getLabelContentSize(peopleTitleLabel)
        local peopleLabel = display.newLabel(peopleTitleSize.width + 47, 24,
        {
            text = '',
            ap = display.LEFT_CENTER,
            fontSize = 30,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#5b3c25',
        })
        valueView:addChild(peopleLabel)
        leftLayout.peopleLabel = peopleLabel

        local votesTitleLabel = display.newLabel(343, 71,
        {
            text = __('票'),
            ap = display.RIGHT_CENTER,
            fontSize = 28,
            color = '#5b3c25',
        })
        valueView:addChild(votesTitleLabel)

        local votesLabel = display.newLabel(343 - display.getLabelContentSize(votesTitleLabel).width , 72,
        {
            text = '',
            ap = display.RIGHT_CENTER,
            fontSize = 50,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#5b3c25',
        })
        valueView:addChild(votesLabel)
        leftLayout.votesLabel = votesLabel

        ------------------valueView end-------------------

        local interviewBtn = display.newButton(display.cx - 179, 107, {size = cc.size(130, 130), tag = 1})
        leftLayout:addChild(interviewBtn)
        leftLayout.interviewBtn = interviewBtn

        local interviewBtnSpine = sp.SkeletonAnimation:create("effects/activity/saimoe/Button.json","effects/activity/saimoe/Button.atlas", 1)
        interviewBtnSpine:setPosition(cc.p(display.cx - 179, 107))
        interviewBtnSpine:update(0)
        interviewBtnSpine:setAnimation(0, 'idle', true)
        leftLayout:addChild(interviewBtnSpine)
        leftLayout.interviewBtnSpine = interviewBtnSpine

        local interviewBG = display.newButton(display.cx - 179, 52,
        {
            ap = display.CENTER,
            n = RES_DICT.BOOSSTRATEGY_RANKS_NAME_BG,
            enable = false,
        })
        display.commonLabelParams(interviewBG, {text = __('采访回放'), fontSize = 22, color = '#ffffff'})
        leftLayout:addChild(interviewBG)
        leftLayout.interviewBG = interviewBG

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

        local barImg = display.newImageView(RES_DICT.STARPLAN_VS_RIGHT_TICKET_BG, display.cx - -202, 111,
        {
            ap = display.LEFT_CENTER,
        })
        rightLayout:addChild(barImg)
        rightLayout.barImg = barImg

        -----------------valueView start------------------
        local valueView = display.newLayer(display.cx - -667, 60,
        {
            ap = display.RIGHT_BOTTOM,
            size = cc.size(400, 100),
            enable = false,
        })
        rightLayout:addChild(valueView)
        rightLayout.valueView = valueView

        local peopleTitleLabel = display.newLabel(84, 21,
        {
            text = __('支持人数：'),
            ap = display.LEFT_CENTER,
            fontSize = 21,
            color = '#5b3c25',
        })
        valueView:addChild(peopleTitleLabel)

        local peopleLabel = display.newLabel(peopleTitleSize.width + 84, 22,
        {
            text = '',
            ap = display.LEFT_CENTER,
            fontSize = 30,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#5b3c25',
        })
        valueView:addChild(peopleLabel)
        rightLayout.peopleLabel = peopleLabel

        local votesTitleLabel = display.newLabel(378, 69,
        {
            text = __('票'),
            ap = display.RIGHT_CENTER,
            fontSize = 30,
            color = '#5b3c25',
        })
        valueView:addChild(votesTitleLabel)

        local votesLabel = display.newLabel(378 - display.getLabelContentSize(votesTitleLabel).width -20  , 70,
        {
            text = '',
            ap = display.RIGHT_CENTER,
            fontSize = 50,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#5b3c25',
        })
        valueView:addChild(votesLabel)
        rightLayout.votesLabel = votesLabel

        ------------------valueView end-------------------
        local interviewBtn = display.newButton(display.cx - -181, 107, {size = cc.size(130, 130), tag = 2})
        rightLayout:addChild(interviewBtn)
        rightLayout.interviewBtn = interviewBtn

        local interviewBtnSpine = sp.SkeletonAnimation:create("effects/activity/saimoe/Button.json","effects/activity/saimoe/Button.atlas", 1)
        interviewBtnSpine:setPosition(cc.p(display.cx - -181, 107))
        interviewBtnSpine:update(0)
        interviewBtnSpine:setAnimation(0, 'idle', true)
        -- interviewBtnSpine:setAnimation(0, 'attack', false)
        -- interviewBtnSpine:addAnimation(0, 'idle', true)
        rightLayout:addChild(interviewBtnSpine)
        rightLayout.interviewBtnSpine = interviewBtnSpine

        local interviewBG = display.newButton(display.cx - -181, 52,
        {
            ap = display.CENTER,
            n = RES_DICT.BOOSSTRATEGY_RANKS_NAME_BG,
            enable = false,
        })
        display.commonLabelParams(interviewBG, {text = __('采访回放'), fontSize = 22, color = '#ffffff'})
        rightLayout:addChild(interviewBG)
        rightLayout.interviewBG = interviewBG

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
        -----------------rightLayout end------------------

        local vsImg = sp.SkeletonAnimation:create("effects/activity/saimoe/starplan_vs.json","effects/activity/saimoe/starplan_vs.atlas", 1)
        vsImg:setPosition(cc.p(display.cx - -5, display.cy - -32))
        vsImg:update(0)
        view:addChild(vsImg, 10)

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

		local backBtn = display.newButton(0, 0, {n = RES_DICT.NAV_BACK})
		display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
        backBtn:setName('NAV_BACK')
		view:addChild(backBtn, 5)
        backBtn:setOnClickScriptHandler(function(sender)
            PlayAudioByClickNormal()
            shareFacade:UnRegsitMediator("SaiMoePlatformMediator")
        end)


		return {
            view                    = view,
            rankingBtn              = rankingBtn,
            leftDrawNode            = leftDrawNode,
            rightDrawNode           = rightDrawNode,
            vsImg                   = vsImg,
            topView                 = topView,
            timeBG                  = timeBG,
            tipsBtn                 = tipsBtn,
            --timeTitleLabel          = timeTitleLabel,
            timeLabel               = timeLabel,
            titleLabel              = titleLabel,
            previewBtn              = previewBtn,
            leftLayout              = leftLayout,
            rightLayout             = rightLayout,
            leftSpoon               = leftSpoon,
            rightSpoon              = rightSpoon,
            leftSupportBtn          = leftSupportBtn,
            rightSupportBtn         = rightSupportBtn,
            supportTipViewL         = supportTipViewL,
            supportTipViewR         = supportTipViewR,
            backBtn                 = backBtn,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

function SaiMoePlatformView:ShowEnterAni( cb )
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
            cc.FadeIn:create(10 / 30)
        ), {delay = 1})	
        
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

    local vsImg = viewData.vsImg
    vsImg:setAnimation(0, 'play', false)
    vsImg:addAnimation(0, 'idle', true)
    transition.execute(viewData.view, nil, {delay = 21 / 30, complete = function (  )
        vsImg:setLocalZOrder(-1)
    end})

    local barImgMoveDistance = 43
    local barImg = viewData.leftLayout.barImg
    barImg:setPositionX(barImg:getPositionX() - barImgMoveDistance)
    barImg:setOpacity(0)
    transition.execute(barImg, cc.Spawn:create(
        cc.MoveBy:create(8 / 30, cc.p(barImgMoveDistance, 0)),
        cc.FadeIn:create(3 / 30)
    ), {delay = 1})

    local barImg = viewData.rightLayout.barImg
    barImg:setPositionX(barImg:getPositionX() + barImgMoveDistance)
    barImg:setOpacity(0)
    transition.execute(barImg, cc.Spawn:create(
        cc.MoveBy:create(8 / 30, cc.p(-barImgMoveDistance, 0)),
        cc.FadeIn:create(3 / 30)
    ), {delay = 1})

    local interviewBtn = viewData.leftLayout.interviewBtn
    interviewBtn:setOpacity(0)
    transition.execute(interviewBtn, cc.FadeIn:create(8 / 30), {delay = 34 / 30})

    local interviewBtn = viewData.rightLayout.interviewBtn
    interviewBtn:setOpacity(0)
    transition.execute(interviewBtn, cc.FadeIn:create(8 / 30), {delay = 34 / 30})

    local interviewBtnSpine = viewData.leftLayout.interviewBtnSpine
    interviewBtnSpine:setOpacity(0)
    transition.execute(interviewBtnSpine, cc.FadeIn:create(8 / 30), {delay = 34 / 30})

    local interviewBtnSpine = viewData.rightLayout.interviewBtnSpine
    interviewBtnSpine:setOpacity(0)
    transition.execute(interviewBtnSpine, cc.FadeIn:create(8 / 30), {delay = 34 / 30})

    local interviewBG = viewData.leftLayout.interviewBG
    interviewBG:setOpacity(0)
    transition.execute(interviewBG, cc.FadeIn:create(8 / 30), {delay = 38 / 30})

    local interviewBG = viewData.rightLayout.interviewBG
    interviewBG:setOpacity(0)
    transition.execute(interviewBG, cc.FadeIn:create(8 / 30), {delay = 38 / 30})

    local nameLabel = viewData.leftLayout.nameLabel
    nameLabel:setOpacity(0)
    transition.execute(nameLabel, cc.FadeIn:create(10 / 30), {delay = 35 / 30})

    local nameLabel = viewData.rightLayout.nameLabel
    nameLabel:setOpacity(0)
    transition.execute(nameLabel, cc.FadeIn:create(10 / 30), {delay = 35 / 30})

    local valueView = viewData.leftLayout.valueView
    valueView:setOpacity(0)
    transition.execute(valueView, cc.FadeIn:create(8 / 30), {delay = 38 / 30})

    local valueView = viewData.rightLayout.valueView
    valueView:setOpacity(0)
    transition.execute(valueView, cc.FadeIn:create(8 / 30), {delay = 38 / 30, complete = cb})

end

return SaiMoePlatformView