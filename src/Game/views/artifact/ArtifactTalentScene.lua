--[[
NPC图鉴主页面Scene
--]]
local GameScene = require( "Frame.GameScene" )
---@class ArtifactTalentScene
local ArtifactTalentScene = class('ArtifactTalentScene', GameScene)
local BUTTON_TAG = {
    BACK_BTN      = 1003, -- 返回按钮
    LOOK_DETAIL   = 1004, --查看详情
    TRAIL_BTN     = 1005, --试炼
    RESET_CIRCUIT = 1006, -- 重置回路
    GEM_CALL      = 1007, -- 宝石召唤
    GEM_BACKPACK  = 1008, -- 宝石仓库
    NEXT_ARTIFACT = 1009, -- 下一个神器
    LAST_ARTIFACT = 1010, -- 上一个神器
    TIPS_TAG      = 1011
}
local ARTIFACT_SPINE = {
    MOUSE  = 'effects/artifact/xiaocangshu',
    ROTATE = 'effects/artifact/anime_cage1',
    FIRE   = 'effects/artifact/anime_cage2',
    ARTIFACT_SPINE_B ='effects/artifact/circle1',
    ARTIFACT_SPINE_F ='effects/artifact/circle2'
}
function ArtifactTalentScene:ctor(...)
    self.super.ctor(self,'views.ArtifactTalentScene')
    self.viewData = nil
    local function CreateView()
        local view = display.newLayer(display.cx , display.cy ,{ ap = display.CENTER})
        self:addChild(view)
        view:setPosition(display.center)

        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height,{n = _res('ui/common/common_title_new.png'),enable = true,tag = BUTTON_TAG.TIPS_TAG , ap = cc.p(0, 1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('神器'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel, 10)

        local tipsBtn = display.newButton(tabNameLabel:getContentSize().width - 50, tabNameLabel:getContentSize().height/2 - 10, {n = _res('ui/common/common_btn_tips.png')})
        tabNameLabel:addChild(tipsBtn, 10)

        -- back btn
        local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
        backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
        view:addChild(backBtn, 20)
        backBtn:setTag(BUTTON_TAG.BACK_BTN)

        local bg = display.newImageView(_res('ui/artifact/card_weapon_bg.jpg'))
        local bgSize = cc.size(1624,1006)
        bg:setPosition(bgSize.width/2 , bgSize.height/2)
        local bgLayout = display.newLayer(display.cx  , display.cy , {ap = display.CENTER , color1 = cc.r4b() , size = bgSize})
        view:addChild(bgLayout)
        bgLayout:addChild(bg)


        local giftBg = display.newImageView(_res('ui/artifact/card_weapon_gift_bg_right'))
        local giftBgSize = giftBg:getContentSize()
        giftBg:setPosition(cc.p(giftBgSize.width/2 , giftBgSize.height/2))
        local giftLayout = display.newLayer(display.width/2 + 600,display.height/2, {ap = display.CENTER , size = giftBgSize , color1 = cc.r4b()})
        giftLayout:addChild(giftBg)
        view:addChild(giftLayout , 24)
        -- 宝石召唤按钮
        local gemCallBtn = display.newButton(140,giftBgSize.height/2 - display.height/2 + 70, { n = _res('ui/artifact/card_weapon_btn_under.png') })
        giftLayout:addChild(gemCallBtn)
        local gemCallBtnSize = gemCallBtn:getContentSize()
        local gemCallImage = display.newImageView(_res('ui/artifact/card_weapon_btn_draw.png'),gemCallBtnSize.width/2 , gemCallBtnSize.height/2)
        gemCallBtn:addChild(gemCallImage)

        local skillImage = display.newButton(  gemCallBtnSize.width/2 , 0 ,{ap = display.CENTER_BOTTOM , n = _res('ui/cards/propertyNew/card_bar_bg.png') })
        display.commonLabelParams(skillImage , fontWithColor('14',{text = __('塔可抽取')}))
        gemCallBtn:addChild(skillImage)
        gemCallBtn:setTag(BUTTON_TAG.GEM_CALL)
        -- 查看宝石背包
        local gemBackpackBtn = display.newButton(170,giftBgSize.height/2 - display.height/2 + 180, { n = _res('ui/artifact/card_weapon_btn_under.png') })
        giftLayout:addChild(gemBackpackBtn)

        local gemBackpacImage = display.newImageView(_res('ui/artifact/card_weapon_btn_bag.png'),gemCallBtnSize.width/2 , gemCallBtnSize.height/2)
        gemBackpackBtn:addChild(gemBackpacImage)
        gemBackpackBtn:setTag(BUTTON_TAG.GEM_BACKPACK)
        local skillImage = display.newButton(  gemCallBtnSize.width/2 , 0 ,{ap = display.CENTER_BOTTOM , n = _res('ui/cards/propertyNew/card_bar_bg.png') })
        display.commonLabelParams(skillImage , fontWithColor('14',{text = __('塔可合成')}))
        gemBackpackBtn:addChild(skillImage)

        -- 外部的大圆圈
        local circleOneImage = display.newImageView(_res('ui/artifact/card_weapon_bg_circle_1'))
        circleOneImage:setScale(2)
        local circleOneImageSize = circleOneImage:getContentSize()
        circleOneImageSize = cc.size(circleOneImageSize.width * 2 , circleOneImageSize.height*2)
        circleOneImage:setPosition(circleOneImageSize.width/2 , circleOneImageSize.height/2)
        local circleLayout = display.newLayer(866  , bgSize.height/2 + 20 , {size = circleOneImageSize , color1 = cc.r4b(), ap = display.CENTER})
        circleLayout:addChild(circleOneImage)
        bgLayout:addChild(circleLayout,20)

        -- 里面的小圆圈
        local circleTwoImage = display.newImageView(_res('ui/artifact/card_weapon_bg_circle_2'),circleOneImageSize.width/2 ,circleOneImageSize.height/2)
        circleTwoImage:setScale(2)
        circleLayout:addChild(circleTwoImage)
        local jobImage = display.newImageView(_res('ui/artifact/card_weapon_bg_power') ,circleOneImageSize.width/2 , circleOneImageSize.height/2 )
        circleLayout:addChild(jobImage,-1)

        circleOneImage:runAction(
            cc.RepeatForever:create(
                cc.Spawn:create(
                        cc.TargetedAction:create( circleTwoImage, cc.RotateBy:create(10,-180)),
                        cc.RotateBy:create(10,180)
                )

            )
        )
        -- 左侧的神器界面
        local artifactSize = cc.size(600,750)
        local artifactLayout  = display.newLayer(0,0, {ap = display.LEFT_BOTTOM, size = artifactSize  })
        view:addChild(artifactLayout,10)
        -- 下部基本神器的切换
        local bassImage   = display.newImageView(_res('ui/artifact/card_weapon_base_s_bg'))
        local bassSize = bassImage:getContentSize()
        local bassLayout = display.newLayer(0 + display.SAFE_L - 50 ,-30 , {ap = display.LEFT_BOTTOM , size = bassSize , color1 = cc.r4b()})
        bassImage:setPosition(cc.p(bassSize.width/2 , bassSize.height/2))
        bassLayout:addChild(bassImage)
        artifactLayout:addChild(bassLayout)

        local bassContentSize = cc.size(530 , 120 )
        local bassContent =  display.newLayer( bassSize.width - 35,  bassSize.height - 210 , {ap = display.RIGHT_TOP , size = bassContentSize , color1 = cc.r4b()})
        bassLayout:addChild(bassContent)
        -- 向后切换
        local nextBtn = display.newButton(bassContentSize.width - 45  , 65 , { n = _res('ui/home/cardslistNew/card_skill_btn_switch.png')})
        bassContent:addChild(nextBtn)
        nextBtn:setScale(-1)
        nextBtn:setTag(BUTTON_TAG.NEXT_ARTIFACT)
        -- 向前切换
        local leftBtn = display.newButton(55  , 65 , { n = _res('ui/home/cardslistNew/card_skill_btn_switch.png')})
        bassContent:addChild(leftBtn)
        leftBtn:setTag(BUTTON_TAG.LAST_ARTIFACT)
        -- 装备的名称
        local artifactName = display.newLabel(bassContentSize.width/2 ,70 , fontWithColor('14' , {text = ""}) )
        bassContent:addChild(artifactName)

        local cardName = display.newButton(bassContentSize.width/2 ,  20 ,{n  = _res('ui/artifact/card_weapon_label_name.png') ,enable = false })
        display.commonLabelParams(cardName , fontWithColor('14' , {text = ""}))
        bassContent:addChild(cardName)
        local nameLabelParams = fontWithColor('14', {color = "#f9edcc"})
        local cardNameSize = cardName:getContentSize()

        local attackBgImage = display.newImageView(_res(CardUtils.CAREER_ICON_FRAME_PATH_MAP[tostring(CardUtils.CAREER_TYPE.ATTACK)]) ,20   , cardNameSize.height/2- 5  , {ap = display.LEFT_CENTER} )
        --local attackBgImageSize = attackBgImage:getContentSize()
        local attackImage = display.newImageView(_res(CardUtils.CAREER_ICON_PATH_MAP[tostring(CardUtils.CAREER_TYPE.ATTACK)]),20   , cardNameSize.height/2- 5  , {ap = display.LEFT_CENTER})
        cardName:addChild(attackImage,1)
        cardName:addChild(attackBgImage)
        attackBgImage:setScale(1.5)
        attackImage:setScale(1.5)


        local animeImageSize = cc.size(522,541)
        local animeLayout = display.newLayer(bassSize.width/2 + display.SAFE_L - 50 ,160, {ap = display.CENTER_BOTTOM , size = animeImageSize , color1 = cc.r4b() } )
        artifactLayout:addChild(animeLayout)
        local  artifactBottomSpine  = SpineCache(SpineCacheName.ARTIFACT):createWithName(ARTIFACT_SPINE.ARTIFACT_SPINE_B)
        artifactBottomSpine:setName("artifactBottonSpine")
        artifactBottomSpine:setPosition(cc.p(artifactSize.width/2 - 53  + display.SAFE_L , artifactSize.height/2+30 ))
        artifactLayout:addChild(artifactBottomSpine ,-1)
        artifactBottomSpine:setAnimation(0, 'idle' , true)

        local  artifactForeSpine  = SpineCache(SpineCacheName.ARTIFACT):createWithName(ARTIFACT_SPINE.ARTIFACT_SPINE_F)
        artifactForeSpine:setName("artifactBottonSpine")
        artifactForeSpine:setPosition(cc.p(animeImageSize.width/2+35 , animeImageSize.height/2 -10))
        animeLayout:addChild(artifactForeSpine,21)
        artifactForeSpine:setVisible(false)
        -- 查看堕神的详情按钮
        local lookDetailBtn = display.newButton(animeImageSize.width/2 ,-18, { n =_res('ui/artifact/card_weapon_base_s_label_tips') , ap = display.CENTER_BOTTOM})
        animeLayout:addChild(lookDetailBtn)
        lookDetailBtn:setTag(BUTTON_TAG.LOOK_DETAIL)
        display.commonLabelParams(lookDetailBtn, fontWithColor('10' , {color = "#f9edcc", text = __('点击查看详情')}))
        -- 神器的大照片
        local artifactBigImage = display.newImageView(_res('arts/artifact/big/core_icon_s_200001'),animeImageSize.width/2  , animeImageSize.height/2  ,{enable = true }  )
        animeLayout:addChild(artifactBigImage,20)
        artifactBigImage:setTag(BUTTON_TAG.LOOK_DETAIL)
        artifactBigImage:setVisible(false)
        local artifactBigImagePos =  cc.p( artifactBigImage:getPosition())

        local topImage = display.newImageView(_res('ui/artifact/card_weapon_gift_bg_up'))
        local topImageSize = topImage:getContentSize()
        topImage:setPosition(cc.p(topImageSize.width/2 , topImageSize.height/2))

        local topRightLayout = display.newLayer(display.SAFE_R, display.height , {ap = display.RIGHT_TOP , size =  topImageSize , color1 = cc.r4b() })
        view:addChild(topRightLayout, 25 )

        topRightLayout:addChild(topImage)
        -- 重置按钮
        local resetBtn = display.newButton(topImageSize.width -130 , 68, {n =  _res('ui/home/talent/talent_btn_reset.png')})
        topRightLayout:addChild(resetBtn)
        resetBtn:setTag(BUTTON_TAG.RESET_CIRCUIT)

        display.commonLabelParams(resetBtn , fontWithColor('6', {text = __('重置核心')}))
        local energyImage = display.newImageView(_res('ui/artifact/card_weapon_energy_bg_s.png')  , 200, 142 )
        topRightLayout:addChild(energyImage)

        local energyImageSize = energyImage:getContentSize()
        local artifactNum =  cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
        artifactNum:setAnchorPoint(display.LEFT_CENTER)
        artifactNum:setScale(1.2)
        artifactNum:setPosition(70 ,energyImageSize.height/2)
        energyImage:addChild(artifactNum)

        -- 试炼按钮
        local trailBtn = display.newButton(310, 142 ,{n = _res('ui/artifact/card_weapon_btn_train_r')})
        display.commonLabelParams(trailBtn , fontWithColor('14', {text = __('获取')}))
        topRightLayout:addChild(trailBtn)
        trailBtn:setTag(BUTTON_TAG.TRAIL_BTN)
        -- 武器的小图片
        local artifactSmallImage = display.newImageView(_res('arts/artifact/small/core_icon_290001'),40 , 142, {ap = display.LEFT_CENTER } )
        topRightLayout:addChild(artifactSmallImage,20)
        artifactSmallImage:setScale(0.5)
        -- 未解锁路径层
        local lockPathLayer = display.newLayer(display.cx , display.cy , {ap = display.CENTER, size = cc.size(1624, 1002)})
        view:addChild(lockPathLayer , 22)
        -- 已解锁路径层
        local unlockPathLayer = display.newLayer(display.cx , display.cy , {ap = display.CENTER, size = cc.size(1624, 1002)})
        view:addChild(unlockPathLayer , 22)

        -- icon层
        local  iconLayer = display.newLayer(display.cx , display.cy , {ap = display.CENTER, size = cc.size(1624, 1002)})
        view:addChild(iconLayer , 23)

        return {
            view               = view,
            tabNameLabel       = tabNameLabel,
            tabNameLabelPos    = cc.p(tabNameLabel:getPosition()),
            lookDetailBtn      = lookDetailBtn,
            cardName           = cardName,
            nameLabelParams    = nameLabelParams,
            artifactName       = artifactName,
            artifactBigImage   = artifactBigImage,
            artifactSmallImage = artifactSmallImage,
            artifactBigImagePos= artifactBigImagePos,
            artifactBottomSpine = artifactBottomSpine ,
            artifactForeSpine  = artifactForeSpine ,
            resetBtn           = resetBtn,
            trailBtn           = trailBtn,
            nextBtn            = nextBtn,
            artifactNum        = artifactNum,
            attackBgImage      = attackBgImage,
            attackImage        = attackImage,
            jobImage           = jobImage,
            leftBtn            = leftBtn,
            iconLayer          = iconLayer,
            unlockPathLayer    = unlockPathLayer,
            lockPathLayer      = lockPathLayer,
            gemCallBtn         = gemCallBtn,
            gemBackpackBtn     = gemBackpackBtn,
            circleOneImageSize     = circleOneImageSize,
            backBtn  = backBtn,
            artifactLayout = artifactLayout  ,
        }
    end
    -- colorLayer
    local colorLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    colorLayer:setTouchEnabled(true)
    colorLayer:setContentSize(display.size)
    colorLayer:setAnchorPoint(cc.p(0.5, 0.5))
    colorLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(colorLayer, -10)
    self.viewData = CreateView()
    self.viewData.tabNameLabel:setPositionY(display.height + 100)
    local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData.tabNameLabelPos))
    self.viewData.tabNameLabel:runAction( action )
end

function ArtifactTalentScene:onCleanup()

end

return ArtifactTalentScene