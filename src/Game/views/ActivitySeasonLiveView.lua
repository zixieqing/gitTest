---
--- Created by xingweihao.
--- DateTime: 16/10/2017 5:39 PM
---
---@class ActivitySeasonLiveView
local ActivitySeasonLiveView = class('ActivitySeasonLiveView', function()
    local node = CLayout:create(cc.size(1035, 637))
    node:setAnchorPoint(cc.p(0, 0))
    node.name = 'home.ActivitySeasonLiveView'
    node:enableNodeEvents()
    return node
end)
local BUTTON_TAG             = {
    THEME_PREVIEW_BTN        = 1101, --显示主题
    BATTLE_BTN               = 1102, -- 进入季活的战斗按钮
    EXCHANGE_BTN             = 1103, -- 抽奖兑换积分按钮
    RECEIVE_NEWYEASPOINT_BTN = 1104, -- 兑换积分奖励的tag
    GUN_REWARD_BTN           = 1105, -- 领取开门炮
}
local function CreateView( )
    local bgSize = cc.size(1035, 637)
    local view   = CLayout:create(bgSize)
    -- 背景
    local bg     = display.newImageView(_res('ui/home/activity/seasonlive/season_home_bg_1.png'), bgSize.width / 2, bgSize.height / 2)
    view:addChild(bg, 1)
    -- 活动规则
    local heightDistance = 20
    local acivityButton = display.newButton(5, 125 + heightDistance, { n = _res('ui/home/activity/seasonlive/season_home_label_rule.png'), ap = display.LEFT_CENTER, enable = false } )
    display.commonLabelParams(acivityButton, fontWithColor('14', { text = __('活动规则'), offset = cc.p( -15, 0) }) )
    view:addChild(acivityButton, 9 )

    local timeBg = display.newImageView(_res('ui/home/activity/activity_time_bg.png'), 1030, 600, {ap = display.RIGHT_CENTER,scale9 = true , size = isKoreanSdk() and cc.size(268 ,47) or cc.size(400 ,47)})
    local timeBgSize = timeBg:getContentSize()
    view:addChild(timeBg, 20)
    local timeLabel = display.newRichLabel(timeBgSize.width - 25, timeBgSize.height/2, { ap = display.RIGHT_CENTER , c = {
        {text = __('剩余时间:'), fontSize = 22, color = '#ffffff', outline = '#5b3c25', outlineSize = 1},
        {text = '8天', fontSize = 24, color = '#fed23b', ttf = true, font = TTF_GAME_FONT, outline = '#5b3c25', outlineSize = 1}
    }})
    timeBg:addChild(timeLabel, 20)

    -- 规则图片
    local ruleImage     = display.newImageView(_res('ui/home/activity/seasonlive/season_home_bg_below.png'))
    --
    local ruleImageSize = ruleImage:getContentSize()
    local ruleLayout    = display.newLayer(bgSize.width / 2 + 0.5, 5, { ap = display.CENTER_BOTTOM, size = ruleImageSize })
    ruleLayout:addChild(ruleImage)
    ruleImage:setPosition(cc.p(ruleImageSize.width / 2, ruleImageSize.height / 2))
    view:addChild(ruleLayout, 9 )
    -- 战斗的按钮
    local battleBtn = display.newButton(ruleImageSize.width - 150, ruleImageSize.height / 2 + 25, { n = _res('ui/home/activity/seasonlive/season_home_ico_battle.png'), ap = display.RIGHT_CENTER })
    ruleLayout:addChild(battleBtn)
    local battleBtnSize = battleBtn:getContentSize()
    local battleLabel   = display.newButton(ruleImageSize.width - 224, ruleImageSize.height / 2 -50, { n = _res('ui/home/activity/seasonlive/season_home_label_subtitle.png'), ap = display.CENTER_BOTTOM })
    battleBtn:addChild(battleLabel)
    battleBtn:setTag(BUTTON_TAG.BATTLE_BTN)
    display.commonLabelParams( battleLabel, fontWithColor('14', { text = __('夺回年夜饭') }))
    battleLabel:setPosition(cc.p(battleBtnSize.width / 2, -23))
    -- 兑换按钮
    local exchangeBtn = display.newButton(ruleImageSize.width, ruleImageSize.height / 2 + 30, { n = _res('ui/home/activity/seasonlive/season_home_ico_loots.png'), ap = display.RIGHT_CENTER })
    ruleLayout:addChild(exchangeBtn)
    local exchangeBtnSize = exchangeBtn:getContentSize()
    local exchangeLabel   = display.newButton(ruleImageSize.width - 224, ruleImageSize.height / 2 -60, { n = _res('ui/home/activity/seasonlive/season_home_label_subtitle.png'), ap = display.CENTER_BOTTOM })
    exchangeBtn:addChild(exchangeLabel)
    exchangeBtn:setTag(BUTTON_TAG.EXCHANGE_BTN)
    display.commonLabelParams( exchangeLabel, fontWithColor('14', { text = __('交还年夜饭') }))
    exchangeLabel:setPosition(cc.p(exchangeBtnSize.width / 2, -24))




    -- 领取开门炮
    local rewardGunBtn = display.newButton(ruleImageSize.width - 300, ruleImageSize.height / 2+15 , { n = _res('ui/home/activity/seasonlive/season_home_ico_ticket.png'), ap = display.RIGHT_CENTER })
    ruleLayout:addChild(rewardGunBtn)
    local rewardGunBtnSize = rewardGunBtn:getContentSize()
    local rewardGunLabel   = display.newButton(ruleImageSize.width - 224, ruleImageSize.height / 2 -60, { n = _res('ui/home/activity/seasonlive/season_home_label_subtitle.png'), ap = display.CENTER_BOTTOM })
    rewardGunBtn:addChild(rewardGunLabel)
    rewardGunBtn:setTag(BUTTON_TAG.GUN_REWARD_BTN)
    display.commonLabelParams( rewardGunLabel, fontWithColor('14', { text = __('领取开门炮') }))
    rewardGunLabel:setPosition(cc.p(rewardGunBtnSize.width / 2, -23))
    local redTwoImage = display.newImageView(_res('ui/home/activity/seasonlive/season_ico_point'))
    redTwoImage:setPosition(cc.p(rewardGunBtnSize.width + 20, rewardGunBtnSize.height / 2 + 40))
    redTwoImage:setVisible(true )
    redTwoImage:setAnchorPoint(display.RIGHT_CENTER)
    redTwoImage:setName("redTwoImage")
    rewardGunBtn:addChild(redTwoImage)
    redTwoImage:setVisible(false)



    local intergalBgImage     = display.newImageView(_res('ui/home/activity/seasonlive/season_home_label_point.png'))
    local intergalBgImageSize = intergalBgImage:getContentSize()
    -- 背景图片
    local intergalLayout      = display.newLayer(ruleImageSize.width - 450, 130 +heightDistance, { ap = display.RIGHT_CENTER, size = intergalBgImageSize, color = cc.c4b(0,0,0,0), enable = true  })
    intergalBgImage:setPosition(cc.p(intergalBgImageSize.width / 2, intergalBgImageSize.height / 2))
    intergalLayout:addChild(intergalBgImage)
    intergalLayout:setPosition(cc.p(590,160))
    view:addChild(intergalLayout, 20)
    --ruleLayout:addChild(intergalLayout,10)

    -- 满意度
    local intergalLabel = display.newRichLabel(50, intergalBgImageSize.height / 2  , { ap = display.LEFT_CENTER,c = { fontWithColor('14', { text = "" } ) } })
    intergalLayout:addChild(intergalLabel)

    local rewardLabel = display.newLabel(intergalBgImageSize.width -115 , intergalBgImageSize.height/2 ,
         fontWithColor('14' ,{ap  = display.CENTER ,  text = __('领取奖励')} ) )
    intergalLayout:addChild(rewardLabel)
    -- 红点的显示
    local redImage = display.newImageView(_res('ui/home/activity/seasonlive/season_ico_point'))
    redImage:setPosition(cc.p(intergalBgImageSize.width + 15, intergalBgImageSize.height / 2 + 10))
    redImage:setVisible(true )
    redImage:setAnchorPoint(display.RIGHT_CENTER)
    intergalLayout:addChild(redImage)
    intergalLayout:setTag(BUTTON_TAG.RECEIVE_NEWYEASPOINT_BTN)

    local themePreViewBtn = display.newButton(bgSize.width - 21, bgSize.height - 2, { n = _res('ui/home/activity/seasonlive/season_home_bg_avt_preview.png'), ap = display.RIGHT_TOP }  )
    view:addChild(themePreViewBtn, 10)
    local themePreViewBtnSize = themePreViewBtn:getContentSize()
    local avatorImage  =display.newImageView(CommonUtils.GetGoodsIconPathById('107032'),themePreViewBtnSize.width/2 ,themePreViewBtnSize.height/2)
    themePreViewBtn:addChild(avatorImage)
    avatorImage:setScale(0.8)
    themePreViewBtn:setTag(BUTTON_TAG.THEME_PREVIEW_BTN)
    display.commonLabelParams(themePreViewBtn, fontWithColor('14', { text = __('主题预览'), offset = cc.p( 0, -60) }))
    local ruleLabel = display.newLabel(20, 90 +heightDistance + 5, fontWithColor('18', { fontSize = 22, ap = display.LEFT_TOP, w = 570, hAlign = display.TAL, text = '' } )  )
    ruleImage:addChild(ruleLabel)
    return {
        view            = view,
        themePreViewBtn = themePreViewBtn,
        intergalLabel   = intergalLabel,
        battleBtn       = battleBtn,
        intergalLayout  = intergalLayout,
        exchangeBtn     = exchangeBtn,
        redImage        = redImage,
        avatorImage     = avatorImage,
        timeLabel       = timeLabel,
        rewardGunBtn    = rewardGunBtn,
        ruleLabel       = ruleLabel
    }
end

function ActivitySeasonLiveView:ctor( ... )
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view, 1)
    self.viewData_.view:setPosition(utils.getLocalCenter(self))

end

return ActivitySeasonLiveView
