---@class ArtifactTalentUpgradeView
local ArtifactTalentUpgradeView = class('home.ArtifactTalentUpgradeView',function ()
    local node = display.newLayer(0, 0, { ap = display.CENTER , size = display.size})
    node.name = 'Game.views.ArtifactTalentUpgradeView'
    node:enableNodeEvents()
    return node
end)
function ArtifactTalentUpgradeView:ctor(param)
    self.isAction = false
    self:initUI(param.isFull)
end

function ArtifactTalentUpgradeView:initUI(isFull)
    local isFull = isFull
    local closeLayer = display.newButton(display.cx, display.cy ,{ap =display.CENTER , color = cc.c4b(0,0,0,0) , enable = true , size = display.size })
    self:addChild(closeLayer)
    if isFull then
        local bgSize = cc.size(460 ,130)
        local bgLayout = display.newLayer(display.cx,display.cy,{ap = display.CENTER , size = bgSize })
        local swallowLayer = display.newButton(bgSize.width/2 , bgSize.height/2 , {ap = display.CENTER ,size = bgSize})
        bgLayout:addChild(swallowLayer)
        local bgImage = display.newImageView(_res('ui/common/common_bg_tips'),bgSize.width/2 , bgSize.height/2,
        {ap = display.CENTER , scale9 = true , size = bgSize })
        bgLayout:addChild(bgImage)
        local effectImage  = display.newImageView(_res('ui/artifact/core_point_ifo_bg_effect') , bgSize.width/2 , bgSize.height/2)
        bgLayout:addChild(effectImage)
        local effectName = display.newLabel(25, bgSize.height -30  , fontWithColor('10',   {color = "#ffffff", ap = display.LEFT_CENTER , text = "" }))
        bgLayout:addChild(effectName)
        local effectLabel = display.newLabel(25 , bgSize.height-50,fontWithColor('10',  {ap =display.LEFT_TOP ,w = 420 , color = "#ff9edcc" , text = "" ,hAlign = display.TAL }))
        bgLayout:addChild(effectLabel)
        local effectBgImage = display.newImageView(_res('ui/artifact/core_point_ifo_bg_effect_number')  ,bgSize.width - 60 , bgSize.height -30  )
        local effectBgImageSize = effectBgImage:getContentSize()
        bgLayout:addChild(effectBgImage)
        local effectNumber = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
        effectNumber:setPosition(effectBgImageSize.width/2 , effectBgImageSize.height/2)
        effectBgImage:addChild(effectNumber)
        self:addChild(bgLayout)
        self.viewData = {
            bgLayout = bgLayout ,
            effectName = effectName ,
            effectNumber = effectNumber ,
            closeLayer = closeLayer ,
            effectLabel = effectLabel
        }
    else
        local bgSize =  cc.size(460, 385)
        local bgLayout = display.newLayer(display.cx,display.cy,{ap = display.CENTER , size = bgSize })
        local swallowLayer = display.newButton(bgSize.width/2 , bgSize.height/2 , {ap = display.CENTER , enable = true ,  size = bgSize})
        bgLayout:addChild(swallowLayer)
        local bgImage = display.newImageView(_res('ui/common/common_bg_tips'),bgSize.width/2 , bgSize.height /2,
        {ap = display.CENTER , scale9 = true , size = bgSize })
        bgLayout:addChild(bgImage)
        self:addChild(bgLayout)
        local effectImage  = display.newImageView(_res('ui/artifact/core_point_ifo_bg_effect') , bgSize.width/2 , bgSize.height - 65)
        bgLayout:addChild(effectImage)
        local effectName = display.newLabel(25, bgSize.height -30  , fontWithColor('10',   {color = "#ffffff", ap = display.LEFT_CENTER , text = "" }))
        bgLayout:addChild(effectName)

        local effectBgImage = display.newImageView(_res('ui/artifact/core_point_ifo_bg_effect_number')  ,bgSize.width - 60 , bgSize.height -30  )
        local effectBgImageSize = effectBgImage:getContentSize()
        bgLayout:addChild(effectBgImage)
        local effectNumber = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
        effectNumber:setPosition(effectBgImageSize.width/2 , effectBgImageSize.height/2)
        effectBgImage:addChild(effectNumber)

        local effectLabel = display.newLabel(25 , bgSize.height-50,fontWithColor('10',  {ap =display.LEFT_TOP , w = 420 , color = "#f9edcc" , text = "" ,hAlign = display.TAL }))
        bgLayout:addChild(effectLabel)

        local titleImage = display.newButton(bgSize.width/2 , bgSize.height - 133 , {n = _res('ui/common/common_title_3'), ap =display.CENTER_TOP ,enable = false })
        display.commonLabelParams(titleImage , fontWithColor('6' , {text = __('升级材料')}))
        bgLayout:addChild(titleImage)

        local goodNode = require("common.GoodNode").new({goodsId = DIAMOND_ID})
        bgLayout:addChild(goodNode)
        goodNode:setAnchorPoint(display.CENTER_TOP)
        goodNode:setPosition(bgSize.width/2 , bgSize.height - 170)
        goodNode:setScale(0.8)

        local goodsLabel  = display.newRichLabel(bgSize.width/2 , bgSize.height -275 , { r = true ,  c = {
            fontWithColor('14' ,{text ="1/1" , fontSize = 26})
        }})
        bgLayout:addChild(goodsLabel)
        CommonUtils.AddRichLabelTraceEffect(goodsLabel , nil , nil ,{1})

        local  upgradeBtn = display.newButton(bgSize.width/2 , 10 ,{ap = display.CENTER_BOTTOM ,animate = false , scale9 = true ,   n = _res('ui/common/common_btn_orange') })
        display.commonLabelParams(upgradeBtn, fontWithColor('14' ,{text = __('升级')}))
        bgLayout:addChild(upgradeBtn)
        self.viewData = {
            bgLayout = bgLayout,
            effectLabel  = effectLabel,
            swallowLayer  = swallowLayer,
            closeLayer   = closeLayer ,
            effectNumber = effectNumber,
            goodsLabel   = goodsLabel,
            upgradeBtn   = upgradeBtn,
            effectName   = effectName ,
            goodNode     = goodNode
        }
    end
end






return ArtifactTalentUpgradeView
