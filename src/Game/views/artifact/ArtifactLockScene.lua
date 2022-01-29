--[[
NPC图鉴主页面Scene
--]]
local GameScene = require( "Frame.GameScene" )
---@class ArtifactLockScene
local ArtifactLockScene = class('ArtifactLockScene', GameScene)
local BUTTON_TAG = {
    BACK_BTN       = 1003, -- 返回按钮
    UNLOCK_BTN     = 1004, -- 解锁按钮
    TRAIL_BTN      = 1005, --试炼
    CLICK_ARTIFACT = 1006, -- 点击神器的时候
    TIPS_BUTTON    = 1007, -- tips提示

}
local ARTIFACT_SPINE = {
    UNLOCK_ONE = 'effects/artifact/jiesuo1',
    UNLOCK_TWO = 'effects/artifact/jiesuo2',

}
--
function ArtifactLockScene:ctor(...)
    self.super.ctor(self,'views.ArtifactLockScene')
    self.viewData = nil
    local function CreateView()
        local view = display.newLayer(display.cx , display.cy ,{ ap = display.CENTER})
        self:addChild(view)
        view:setPosition(display.center)

        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height,{n = _res('ui/common/common_title_new.png'),enable = true ,ap = cc.p(0, 1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('神器'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel, 10)
        tabNameLabel:setTag(BUTTON_TAG.TIPS_BUTTON)
        local tipsBtn = display.newButton(tabNameLabel:getContentSize().width - 50, tabNameLabel:getContentSize().height/2 - 10, {n = _res('ui/common/common_btn_tips.png')})
        tabNameLabel:addChild(tipsBtn, 10)

        -- back btn
        local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
        backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
        view:addChild(backBtn, 20)
        backBtn:setTag(BUTTON_TAG.BACK_BTN)

        local bg = display.newImageView(_res('ui/artifact/card_weapon_bg.jpg'))
        bg:setPosition(display.center)
        view:addChild(bg)
        -- 标志
        local markImage  =  display.newImageView(_res('ui/artifact/card_weapon_bg_mask'), display.cx, display.cy )
        view:addChild(markImage)


        -- 能量的image
        local conetntSize = cc.size(1200, 700)
        local contentLayout = display.newLayer(display.cx, display.cy ,{ap = display.CENTER , size = conetntSize , color1  = cc.r4b()})
        view:addChild(contentLayout)

        local energyImage = display.newImageView(_res('ui/artifact/card_weapon_energy_bg.png'))
        local energySize = energyImage:getContentSize()
        energyImage:setPosition(energySize.width/2, energySize.height/2)

        local energyLayout = display.newLayer(conetntSize.width/2 , 0,
                                                    { ap = display.CENTER_BOTTOM , size = energySize , color1 = cc.r4b()})
        energyLayout:addChild(energyImage,2)
        contentLayout:addChild(energyLayout,10)

        local bassLabelTips = display.newButton(conetntSize.width/2 , conetntSize.height/2 , { n =  _res('ui/artifact/card_weapon_label_warning')})
        contentLayout:addChild(bassLabelTips ,20)
        bassLabelTips:setVisible(false)

        local labelUnlock = display.newButton(conetntSize.width/2  ,conetntSize.height/2 , { n =  _res('ui/artifact/card_weapon_label_unlock') })
        contentLayout:addChild(labelUnlock ,20)
        bassLabelTips:setVisible(false)
        labelUnlock:setTag(BUTTON_TAG.UNLOCK_BTN)

        -- 小的武器显示
        local artifactSmallImage = display.newImageView(_res('arts/artifact/small/core_icon_290001'), 130 , energySize.height/2 + 5)
        energyLayout:addChild(artifactSmallImage,2)
        artifactSmallImage:setScale(0.5)


        -- 碎片的进度的进度条
        local progressBarOne = CProgressBar:create(_res('ui/artifact/card_weapon_energy_bar'))
        progressBarOne:setBackgroundImage(_res('ui/artifact/card_weapon_energy_bar_under'))
        progressBarOne:setDirection(eProgressBarDirectionLeftToRight)
        progressBarOne:setAnchorPoint(cc.p(0.5, 0.5))
        progressBarOne:setPosition(cc.p(energySize.width/2 , energySize.height/2))
        energyLayout:addChild(progressBarOne,10)
        progressBarOne:setMaxValue(5000)
        progressBarOne:setValue(0)

        local progressBarOneSize = progressBarOne:getContentSize()
        local progressBarOneLabel =cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
        progressBarOneLabel:setPosition(progressBarOneSize.width/2 , progressBarOneSize.height/2)
        progressBarOne:addChild(progressBarOneLabel,20)

        -- 试练
        local  trainBtn = display.newButton(energySize.width - 120 , energySize.height/2, {n = _res('ui/artifact/card_weapon_btn_train')})
        energyLayout:addChild(trainBtn,2)
        display.commonLabelParams(trainBtn , fontWithColor('14' , {text = __('获取')}))
        trainBtn:setTag(BUTTON_TAG.TRAIL_BTN)

        -- 底座
        local baseImage = display.newImageView(_res('ui/artifact/card_weapon_base_bg'))
        local baseImageSize = baseImage:getContentSize()
        local bassLayout = display.newLayer(conetntSize.width/2 , 0  , {ap = display.CENTER_BOTTOM , color1 = cc.r4b() , size = baseImageSize})
        bassLayout:addChild(baseImage)
        baseImage:setPosition(baseImageSize.width/2 , baseImageSize.height/2)
        contentLayout:addChild(bassLayout,4)
        local bassLabel = display.newButton(baseImageSize.width/2 , 105, {ap = display.CENTER_BOTTOM, n =_res('ui/artifact/card_weapon_base_label_name') })
        bassLayout:addChild(bassLabel,10)
        display.commonLabelParams(bassLabel , fontWithColor('14' ,{text = ""}))


        local spineSzie = cc.size(1008,706)
        local spineLayout = display.newLayer(conetntSize.width /2 , 10, {ap = display.CENTER_BOTTOM , size = spineSzie, color1 = cc.r4b()})
        local artifactBigImage = display.newImageView(_res('arts/artifact/big/core_icon_200001'),spineSzie.width/2 , spineSzie.height/2 ,{enable = true })
        spineLayout:addChild(artifactBigImage,2)
        artifactBigImage:setTag(BUTTON_TAG.CLICK_ARTIFACT)
        contentLayout:addChild(spineLayout,-2)
        local unlockTwo =  SpineCache(SpineCacheName.ARTIFACT):createWithName(ARTIFACT_SPINE.UNLOCK_TWO)
        unlockTwo:setVisible(false)
        unlockTwo:setPosition(spineSzie.width/2 , spineSzie.height/2)
        unlockTwo:setAnchorPoint(display.CENTER)
        spineLayout:addChild(unlockTwo)

        local unlockOne =  SpineCache(SpineCacheName.ARTIFACT):createWithName(ARTIFACT_SPINE.UNLOCK_ONE)
        unlockOne:setVisible(false)
        unlockOne:setPosition(spineSzie.width/2+100 , spineSzie.height/2+10)
        unlockOne:setAnchorPoint(display.CENTER)
        contentLayout:addChild(unlockOne, 3)
        contentLayout:setVisible(false)
        return {
            view               = view,
            tabNameLabel       = tabNameLabel,
            tabNameLabelPos    = cc.p(tabNameLabel:getPosition()),
            trainBtn           = trainBtn,
            backBtn            = backBtn,
            unlockOne          = unlockOne ,
            unlockTwo          = unlockTwo ,
            labelUnlock        = labelUnlock,
            bassLabel          = bassLabel,
            spineLayout        = spineLayout ,

            artifactBigImage   = artifactBigImage,
            artifactSmallImage = artifactSmallImage,
            bassLabelTips      = bassLabelTips ,
            bassLabelTipsPos   = cc.p(bassLabelTips:getPosition()),
            progressBarOneLabel = progressBarOneLabel ,
            progressBarOne = progressBarOne,
            markImage  = markImage ,
            energyLayout = energyLayout ,
            contentLayout = contentLayout ,
            bassLayout = bassLayout
        }
    end
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

function ArtifactLockScene:onCleanup()

end

return ArtifactLockScene