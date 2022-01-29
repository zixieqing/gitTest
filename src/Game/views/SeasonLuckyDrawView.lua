
local GameScene           = require( 'Frame.GameScene' )
---@class SeasonLuckyDrawView :GameScene
local SeasonLuckyDrawView = class('SeasonLuckyDrawView', GameScene)
local RES_DICT            = {
    BG_IMAGE          = _res('ui/home/activity/seasonlive/season_loots_bg'),
    BG_POOL_ONE       = _res('ui/home/activity/seasonlive/season_loots_feed_bg_1'),
    BG_POOL_TWO       = _res('ui/home/activity/seasonlive/season_loots_feed_bg_2'),
    LOOK_REWARD_ONE   = _res('ui/home/activity/seasonlive/season_loots_btn_rewards_1'),
    LOOK_REWARD_TWO   = _res('ui/home/activity/seasonlive/season_loots_btn_rewards_2'),
    LOOK_REWARD_THREE = _res('ui/home/activity/seasonlive/season_loots_btn_rewards_3'),
    ONE_BTN           = _res('ui/home/activity/seasonlive/season_loots_btn_default'),
    MULTI_BTN         = _res('ui/home/activity/seasonlive/season_loots_btn_multi'),
    TITLE_ONE         = _res('ui/home/activity/seasonlive/season_loots_bg_title_1'),
    TITLE_TWO         = _res('ui/home/activity/seasonlive/season_loots_bg_title_2'),
    BAR_BGIMAGE       = _res('ui/home/activity/seasonlive/season_loots_bar_bg'),
    BAR_IMAGE         = _res('ui/home/activity/seasonlive/season_loots_bar'),
    TOP_LEFT_IAMGE    = _res('ui/home/activity/seasonlive/season_loots_bg_up_L'),
    TOP_RIGHT_IAMGE   = _res('ui/home/activity/seasonlive/season_loots_bg_up_R'),
    TOP_CENTER_IAMGE  = _res('ui/home/activity/seasonlive/season_point_bg_bar'),
    POINT_IMAGE       = _res('ui/home/activity/seasonlive/season_ico_point')

}

local DRAW_POOL_WAY           = {-- 抽奖池的方式
    ONE = 1, -- 第一种抽奖池
    TWO = 2 -- 第二种抽奖池
}
local SPINE_ANIMATION = {  -- 记录不同NODE 的不同动作
    [tostring(DRAW_POOL_WAY.ONE)] = {
        ['idle'] = 1,
        ['play'] = 2,
        ['end']  = 3,
        ['go']   = 4
    },
    [tostring(DRAW_POOL_WAY.TWO)] = {
        ['idle'] = 5,
        ['play'] = 6,
        ['end']  = 7,
        ['go']   = 8
    }
}
function SeasonLuckyDrawView:ctor()
    self.super.ctor(self, 'home.SeasonLuckyDrawView')
    self:InitUI()
end
--==============================--
--desc:初始化界面
--time:2017-08-01 03:13:56
--@return
--==============================--
function SeasonLuckyDrawView:InitUI()
    local swallowLayer = display.newLayer(0, 0, { ap = display.CENTER, color = cc.c4b(0, 0, 0, 100), enable = true })

    swallowLayer:setPosition(display.center)
    self:addChild(swallowLayer)

    local bottonImage  = display.newImageView(RES_DICT.BG_IMAGE)
    local bottomSize   = bottonImage:getContentSize()

    local bottomLayout = display.newLayer(display.width / 2, (display.height - 80) / 2, { ap = display.CENTER, color1 = cc.r4b(), size = bottomSize })
    self:addChild(bottomLayout)
    bottomLayout:addChild(bottonImage)
    bottonImage:setPosition(cc.p(bottomSize.width / 2, bottomSize.height / 2))

    local poolOneBg     = display.newImageView(RES_DICT.BG_POOL_ONE)
    local poolOneBgSize = poolOneBg:getContentSize()
    poolOneBg:setPosition(cc.p(poolOneBgSize.width / 2, poolOneBgSize.height / 2))
    -- 第一个卡池的内容
    local poolOneLayout = display.newLayer(bottomSize.width/4 + 15, bottomSize.height / 2 - 22, { ap = display.CENTER, size = poolOneBgSize, color1 = cc.r4b() })
    bottomLayout:addChild(poolOneLayout)
    poolOneLayout:addChild(poolOneBg)
    -- 标签
    local titleOneBtn = display.newButton(poolOneBgSize.width / 2, poolOneBgSize.height - 20, { n = RES_DICT.TITLE_ONE, enable = false })
    local titleOneBtnSize =  titleOneBtn:getContentSize()
    local titleOneLayout = display.newLayer(poolOneBgSize.width / 2, poolOneBgSize.height - 20,{ ap = display.CENTER , size = titleOneBtnSize})
    titleOneBtn:setPosition(cc.p(titleOneBtnSize.width/2 ,titleOneBtnSize.height/2))
    titleOneLayout:addChild(titleOneBtn)
    poolOneLayout:addChild(titleOneLayout)

    --第一个点击提示的按钮
    local commonOneTip = display.newButton(titleOneBtnSize.width - 80 , titleOneBtnSize.height/2 -3, {n = _res('ui/common/common_btn_tips')})
    titleOneLayout:addChild(commonOneTip)

    display.commonLabelParams(titleOneBtn, fontWithColor('3', { text = "" }) )
    local consumeSize    = cc.size(390, 108)  -- 消耗的layout
    -- 第一个进度条
    local progressBarOne = CProgressBar:create(RES_DICT.BAR_IMAGE)
    progressBarOne:setBackgroundImage(RES_DICT.BAR_BGIMAGE)
    progressBarOne:setDirection(eProgressBarDirectionLeftToRight)
    progressBarOne:setAnchorPoint(cc.p(0.5, 0.5))
    progressBarOne:setPosition(cc.p(poolOneBgSize.width / 2 -50, poolOneBgSize.height - 70))
    poolOneLayout:addChild(progressBarOne)
    progressBarOne:setMaxValue(100)
    progressBarOne:setValue(0)

    local progressBarOneSize = progressBarOne:getContentSize()
    local prograssOneLabel   = display.newLabel(progressBarOneSize.width / 2, progressBarOneSize.height / 2, fontWithColor('3', { text = "" }) )
    progressBarOne:addChild(prograssOneLabel, 10)
    -- 初始化的label
    local initTimes = display.newLabel(40, poolOneBgSize.height - 103, fontWithColor('4', { fontSize = 20 , ap = display.LEFT_CENTER ,  text = "" }) )
    poolOneLayout:addChild(initTimes)
    -- 查看奖励
    local lookBtnOne = display.newButton(poolOneBgSize.width - 80, poolOneBgSize.height - 70, { n = RES_DICT.LOOK_REWARD_ONE })
    poolOneLayout:addChild(lookBtnOne, 10)
    lookBtnOne:setScale(0.6)
    display.commonLabelParams(lookBtnOne, fontWithColor('14', { fontSize = 35, text = __('查看奖励'), offset = cc.p( 0, -40) }))
    local buttonLayoutSize = cc.size(520, 120)
    -- 按钮的layout
    local buttonLayout     = display.newLayer(poolOneBgSize.width / 2, 0, { ap = display.CENTER_BOTTOM, size = buttonLayoutSize, color1 = cc.r4b() })
    local oneTime          = display.newButton(buttonLayoutSize.width / 4, buttonLayoutSize.height / 2, { n = RES_DICT.ONE_BTN })
    buttonLayout:addChild(oneTime)
    display.commonLabelParams(oneTime, fontWithColor('14', { text = __('吃1份') }) )
    poolOneLayout:addChild(buttonLayout)
    -- 多次
    local mutliTime = display.newButton(buttonLayoutSize.width / 4 * 3, buttonLayoutSize.height / 2, { n = RES_DICT.MULTI_BTN })
    buttonLayout:addChild(mutliTime)
    display.commonLabelParams(mutliTime, fontWithColor('14', { text = "" }) )

    -- 对话框的弹出
    local dialogueOneLayout = display.newLayer(poolOneBgSize.width / 2, 0, { size = buttonLayoutSize, ap = display.CENTER_BOTTOM })
    poolOneLayout:addChild(dialogueOneLayout,10)

    local dialogueOneText  = display.newLabel(40, buttonLayoutSize.height / 2, fontWithColor('6', { ap = display.LEFT_CENTER, text = __('实在吃不下去了.....') }) )
    local dialogueOneImage = display.newImageView(_res('arts/stage/ui/dialogue_bg_5.png'), buttonLayoutSize.width / 2, buttonLayoutSize.height / 2 + 15, { ap = cc.p(0.5, 0.5) })
    dialogueOneLayout:addChild(dialogueOneImage)
    dialogueOneLayout:addChild(dialogueOneText)
    dialogueOneImage:setScale(0.9)
    -- 重置按钮
    local resetOneBtn = display.newButton(buttonLayoutSize.width - 120, buttonLayoutSize.height / 2, { n = _res('ui/common/common_btn_orange'), s = _res('ui/common/common_btn_orange')  ,enable = true } )
    dialogueOneLayout:addChild(resetOneBtn)
    display.commonLabelParams(resetOneBtn, fontWithColor('14', { text = __('抬走') }))
    dialogueOneLayout:setVisible(false)

    -- 卡池二消耗的菜谱
    local consumeOneLayout = display.newLayer(poolOneBgSize.width / 2, buttonLayoutSize.height, { ap = display.CENTER_BOTTOM, size = consumeSize, color1 = cc.r4b() })
    poolOneLayout:addChild(consumeOneLayout,2)

    ---------第二个卡池的UI ------
    local poolTwoBg     = display.newImageView(RES_DICT.BG_POOL_TWO)
    local poolTwoBgSize = poolTwoBg:getContentSize()
    poolTwoBg:setPosition(cc.p(poolTwoBgSize.width / 2, poolTwoBgSize.height / 2))
    -- 第一个卡池的内容
    local poolTwoLayout = display.newLayer(bottomSize.width /4* 3 -15, bottomSize.height / 2 -22, { ap = display.CENTER, size = poolTwoBgSize, color1 = cc.r4b() })
    bottomLayout:addChild(poolTwoLayout)
    poolTwoLayout:addChild(poolTwoBg)
    -- 标签
    local titleTwoBtn = display.newButton(poolTwoBgSize.width / 2, poolTwoBgSize.height + 4, { n = RES_DICT.TITLE_TWO, enable = false })
    local titleTwoBtnSize = titleTwoBtn:getContentSize()
    local titleTwoBtnLayout  = display.newLayer(poolTwoBgSize.width / 2, poolTwoBgSize.height + 4,{ ap = display.CENTER , size =titleTwoBtnSize })
    titleTwoBtn:setPosition(cc.p(titleTwoBtnSize.width/2 ,titleTwoBtnSize.height/2))
    titleTwoBtnLayout:addChild(titleTwoBtn)
    poolTwoLayout:addChild(titleTwoBtnLayout)

    local commonTwoTip = display.newButton(titleTwoBtnSize.width -80, titleTwoBtnSize.height/2 -27,{n = _res('ui/common/common_btn_tips')})
    titleTwoBtnLayout:addChild(commonTwoTip,10)
    display.commonLabelParams(titleTwoBtn, fontWithColor('3', { text ="", offset = cc.p(0, -25) }) )
    -- 第一个进度条
    local progressBarTwo = CProgressBar:create(RES_DICT.BAR_IMAGE)
    progressBarTwo:setBackgroundImage(RES_DICT.BAR_BGIMAGE)
    progressBarTwo:setDirection(eProgressBarDirectionLeftToRight)
    progressBarTwo:setAnchorPoint(cc.p(0.5, 0.5))
    progressBarTwo:setPosition(cc.p(poolTwoBgSize.width / 2 -50, poolTwoBgSize.height - 70))
    poolTwoLayout:addChild(progressBarTwo)
    progressBarTwo:setMaxValue(100)
    progressBarTwo:setValue(0)
    -- 任务进度
    local prograssTwoLabel = display.newLabel(progressBarOneSize.width / 2, progressBarOneSize.height / 2, fontWithColor('3', { text = "" }) )
    progressBarTwo:addChild(prograssTwoLabel, 10)

    -- 查看奖励
    local lookBtnTwo = display.newButton(poolTwoBgSize.width - 90, poolTwoBgSize.height - 70, { n = RES_DICT.LOOK_REWARD_TWO })
    lookBtnTwo:setScale(0.6)
    poolTwoLayout:addChild(lookBtnTwo, 10)
    display.commonLabelParams(lookBtnTwo, fontWithColor('14', { fontSize = 35, text = __('查看奖励'), offset = cc.p( 0, -45) }))
    -- 按钮的layout
    local buttonLayoutTwo = display.newLayer(poolTwoBgSize.width / 2, 0, { ap = display.CENTER_BOTTOM, size = buttonLayoutSize, color2 = cc.r4b() })
    local oneTimeTwo      = display.newButton(buttonLayoutSize.width / 4, buttonLayoutSize.height / 2, { n = RES_DICT.ONE_BTN })
    buttonLayoutTwo:addChild(oneTimeTwo)
    display.commonLabelParams(oneTimeTwo, fontWithColor('14', { text = __('吃一份') }) )
    poolTwoLayout:addChild(buttonLayoutTwo)
    -- 多次
    local mutliTimeTwo = display.newButton(buttonLayoutSize.width / 4 * 3, buttonLayoutSize.height / 2, { n = RES_DICT.MULTI_BTN })
    buttonLayoutTwo:addChild(mutliTimeTwo)
    display.commonLabelParams(mutliTimeTwo, fontWithColor('14', { text = "" }) )
    local backBtn = display.newButton(0, 0, { n = _res("ui/common/common_btn_back") })
    backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
    -- 卡池二消耗的菜谱
    local consumeTwoLayout = display.newLayer(poolTwoBgSize.width / 2, buttonLayoutSize.height, { ap = display.CENTER_BOTTOM, size = consumeSize, color1 = cc.r4b() })
    poolTwoLayout:addChild(consumeTwoLayout,2)



    -- 对话框的弹出
    local dialogueTwoLayout = display.newLayer(poolOneBgSize.width / 2, 0, { size = buttonLayoutSize, ap = display.CENTER_BOTTOM })
    poolTwoLayout:addChild(dialogueTwoLayout,10)
    local dialogueTwoText  = display.newLabel(40, buttonLayoutSize.height / 2, fontWithColor('6', { ap = display.LEFT_CENTER, text = __('实在吃不下去了.....') }) )
    local dialogueTwoImage = display.newImageView(_res('arts/stage/ui/dialogue_bg_5.png'), buttonLayoutSize.width / 2, buttonLayoutSize.height / 2 + 15, { ap = cc.p(0.5, 0.5) })
    dialogueTwoLayout:addChild(dialogueTwoImage)
    dialogueTwoLayout:addChild(dialogueTwoText)
    dialogueTwoLayout:setScale(0.9)

    local resetTwoBtn = display.newButton(buttonLayoutSize.width - 120, buttonLayoutSize.height / 2, { n = _res('ui/common/common_btn_orange'), s = _res('ui/common/common_btn_orange')  ,enable = true } )
    dialogueTwoLayout:addChild(resetTwoBtn)
    display.commonLabelParams(resetTwoBtn, fontWithColor('14', { text = __('抬走') }))
    dialogueTwoLayout:setVisible(false)

    -- 顶部的layout 显示
    local topSize  = cc.size(750, 80)
    local topLayer = display.newLayer(display.width / 2, display.height, { ap = display.CENTER_TOP, size = topSize, color1 = cc.r4b() })
    self:addChild(topLayer)
    self:addChild(backBtn, 5)

    local topCenterImage = display.newImageView(RES_DICT.TOP_CENTER_IAMGE)
    local topCenterSize  = topCenterImage:getContentSize()
    topCenterImage:setPosition(cc.p(topCenterSize.width / 2, topCenterSize.height / 2))
    local topCenterLayer = display.newLayer(topSize.width / 2, topSize.height / 2, { ap = display.CENTER, size = topCenterSize, color1 = cc.r4b() })
    topLayer:addChild(topCenterLayer)
    topCenterLayer:addChild(topCenterImage)
    local progressBarThree = CProgressBar:create(RES_DICT.BAR_IMAGE)
    progressBarThree:setBackgroundImage(RES_DICT.BAR_BGIMAGE)
    progressBarThree:setDirection(eProgressBarDirectionLeftToRight)
    progressBarThree:setAnchorPoint(cc.p(0.5, 0.5))
    progressBarThree:setPosition(cc.p(topCenterSize.width / 2 - 70 , topCenterSize.height / 2))
    topCenterLayer:addChild(progressBarThree)
    progressBarThree:setMaxValue(5000)
    progressBarThree:setValue(0)

    -- 任务进度
    local prograssThreeLabel = display.newLabel(progressBarOneSize.width / 2, progressBarOneSize.height / 2, fontWithColor('3', { text = "" }) )
    progressBarThree:addChild(prograssThreeLabel, 10)
    -- 有奖励可以领取的时候的提示
    local pointImage = display.newImageView(RES_DICT.POINT_IMAGE, topCenterSize.width - 250, topCenterSize.height / 2 + 10 )
    topCenterLayer:addChild(pointImage,10)
    pointImage:setVisible(falses)

    local lookPointReards     = display.newButton(topCenterSize.width  - 160, topCenterSize.height / 2, { n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png') })
    local lookPointReardsSize = lookPointReards:getContentSize()

    local richLabel           = display.newRichLabel(lookPointReardsSize.width / 2 + 25, lookPointReardsSize.height / 2, { r = true, c = {
        {img = _res('ui/common/common_bg_tips_horn'), scale = -1  ,  ap = cc.p(-1 , 1)},
        fontWithColor('14', { text = __('奖励') ,fontSize = 22 })
    } })
    lookPointReards:addChild(richLabel)
    CommonUtils.AddRichLabelTraceEffect(richLabel)
    topCenterLayer:addChild(lookPointReards)
    self.viewData = {
        poolOneLayout      = poolOneLayout,
        titleOneBtn        = titleOneBtn,
        commonOneTip       = commonOneTip,
        lookBtnOne         = lookBtnOne,
        mutliTime          = mutliTime,
        oneTime            = oneTime,
        progressBarOne     = progressBarOne,
        initTimes          = initTimes,
        prograssOneLabel   = prograssOneLabel,
        buttonLayout       = buttonLayout,
        ---------重置卡池的显示-------------
        dialogueOneLayout  = dialogueOneLayout,
        resetOneBtn        = resetOneBtn,
        dialogueOneText    = dialogueOneText,
        dialogueTwoImage   = dialogueTwoImage,
        dialogueTwoLayout  = dialogueTwoLayout,
        dialogueTwoText    = dialogueOneText,
        resetTwoBtn        = resetTwoBtn,
        titleTwoBtn        = titleTwoBtn,
        lookBtnTwo         = lookBtnTwo,
        mutliTimeTwo       = mutliTimeTwo,
        oneTimeTwo         = oneTimeTwo,
        progressBarTwo     = progressBarTwo,
        prograssTwoLabel   = prograssTwoLabel,
        consumeSize        = consumeSize,
        consumeOneLayout   = consumeOneLayout,
        consumeTwoLayout   = consumeTwoLayout,
        buttonLayoutTwo    = buttonLayoutTwo,
        commonTwoTip       = commonTwoTip,
        --- 顶部的内容 -----------
        topLayer           = topLayer,
        lookPointReards    = lookPointReards,
        progressBarThree   = progressBarThree,
        topCenterLayer     = topCenterLayer,
        pointImage         = pointImage,
        prograssThreeLabel = prograssThreeLabel,
        poolTwoLayout = poolTwoLayout ,
        navBack            = backBtn
    }
end

function SeasonLuckyDrawView:CreateSpineAnimation(type)
    type = type or 1
    local str = ""
    local parentNode  = nil
    if type == DRAW_POOL_WAY.ONE then
        str = 'effects/seasonlive/pangdun1'
        parentNode = self.viewData.poolOneLayout
    else
        str = 'effects/seasonlive/pangdun2'
        parentNode = self.viewData.poolTwoLayout
    end
    local spineAnimation = sp.SkeletonAnimation:create(
            string.format('%s.json',str ) ,
            string.format('%s.atlas',str ) ,
            1
    )
    spineAnimation:setAnimation(SPINE_ANIMATION[tostring(type)].idle, 'idle', true)
    local parentSize = parentNode:getContentSize()
    spineAnimation:setPosition(cc.p(parentSize.width/2-25 ,200))
    local clipSize = cc.size(520, 590)
    local clippingNode = cc.ClippingNode:create()
    clippingNode:setContentSize(clipSize)
    clippingNode:setPosition(cc.p(parentSize.width/2 ,parentSize.height/2))
    clippingNode:setAnchorPoint(display.CENTER)
    clippingNode:addChild(spineAnimation,10)
    local  stencilNode  =display.newLayer(parentSize.width/2 ,parentSize.height/2 , { ap = display.CENTER , size = parentSize , color = cc.r4b() })
    clippingNode:setStencil(stencilNode)
    clippingNode:setAlphaThreshold(1)
    clippingNode:setInverted(false)
    stencilNode:setPosition(cc.p(parentSize.width/2,parentSize.height/2))
    stencilNode:setAnchorPoint(display.CENTER)

    parentNode:addChild(clippingNode,1)
    if type == DRAW_POOL_WAY.ONE then
        self.viewData.oneSpineAnimation = spineAnimation
    else
        self.viewData.twoSpineAnimation = spineAnimation
    end
end

return SeasonLuckyDrawView
