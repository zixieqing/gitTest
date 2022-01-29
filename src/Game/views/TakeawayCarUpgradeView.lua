---
--- Created by xingweihao.
--- DateTime: 30/09/2017 5:40 PM

---
---@class TakeawayCarUpgradeView
local TakeawayCarUpgradeView = class('TakeawayCarUpgradeView', function()
    local node = display.newLayer(0,0, {  size =cc.size(467,735) , ap = display.CENTER })
    --CLayout:create(cc.size(467,735))
    node.name = 'TakeawayCarUpgradeView'
    return node
end)

local  RES_DICT ={
    BG_IMAGE  = _res('ui/home/carexplore/order__info_bg_layer_middle.png') , -- 背景图片
    EFFECT_IMAGE = _res('ui/home/carexplore/raid_mode_bg_active.png') , -- 效果的图片
    COMMON_BG = _res('ui/common/common_bg_goods.png') ,
    COMMON_TITLE = _res('ui/common/common_title_5.png') ,   -- 标题
    COMMON_DISABLE = _res('ui/common/common_btn_orange_disable.png') ,   -- 条件不符合点击的按钮
    COMMON_ENABLE = _res('ui/common/common_btn_orange.png') ,    -- 条件符合点击的按钮

}
function TakeawayCarUpgradeView:ctor()
    self:InitUI()
end
--- 初始化UI
function TakeawayCarUpgradeView:InitUI()
    local offsetW = -30
    local bgImage = display.newImageView(RES_DICT.BG_IMAGE )
    local bgSize = bgImage:getContentSize()
    local bgLayer = display.newLayer(465 , bgSize.height/2 , {size = bgSize , ap = display.RIGHT_CENTER })
    self:addChild(bgLayer)
    bgImage:setPosition(cc.p(bgSize.width/2 , bgSize.height/2))
    bgLayer:addChild(bgImage)
    -- 吞噬层
    local swalowLayer =display.newLayer(bgSize.width /2 , bgSize.height/2 , {size = bgSize ,color = cc.c4b(0,0,0,0) , ap = display.CENTER , enable = true })
    bgLayer:addChild(swalowLayer)
    -- 背景图片
    local effectImage = display.newImageView(RES_DICT.EFFECT_IMAGE ,bgSize.width/2 +offsetW, bgSize.height - 45, { ap = display.CENTER_TOP})
    bgLayer:addChild(effectImage)
    local effectImageSize = effectImage:getContentSize()
    -- 车辆的属性
    local carProperty = display.newLabel(effectImageSize.width/2 , effectImageSize.height - 90 , fontWithColor('14', { text = __('车辆当前属性') , reqW = 250,  color = "#a1673c", outline = false}))
    effectImage:addChild(carProperty)
    -- 具体的属性值
    local carereteProperty = display.newLabel(effectImageSize.width/2 , effectImageSize.height - 170 ,
            fontWithColor('6', {text = ""}))
    effectImage:addChild(carereteProperty)
    local needSize = cc.size(350, 185)
    -- 需要的商品
    local needLayout = display.newLayer(bgSize.width/2+offsetW , bgSize.height - 530 , { size = needSize , ap = display.CENTER  })
    bgLayer:addChild(needLayout)
    -- 背景图片
    local bgGoodsImage = display.newImageView( RES_DICT.COMMON_BG,needSize.width/2 , needSize.height/2 , { scale9 = true , size = needSize })
    needLayout:addChild(bgGoodsImage)
    -- 标题的名字
    local titleImage = display.newButton(  needSize.width/2 , needSize.height - 5 , { ap = display.CENTER_TOP , n = RES_DICT.COMMON_TITLE , s = RES_DICT.COMMON_TITLE , scale9 = true  } )
    needLayout:addChild(titleImage)
    display.commonLabelParams(titleImage, fontWithColor('5', { text =  __('升级材料' ) , paddingW = 30}))
    -- 升级所要消耗的物品
    local consumeGoodsLayout = display.newLayer(needSize.width/2 , 12 , { size = cc.size(350, 140 ) , ap = display.CENTER_BOTTOM  })
    needLayout:addChild(consumeGoodsLayout)
    -- 升级按钮
    local upgradeBtn = display.newButton(  bgSize.width/2 +offsetW, 100 , { ap = display.CENTER_TOP , n = RES_DICT.COMMON_ENABLE , s = RES_DICT.COMMON_ENABLE  } )
    bgLayer:addChild(upgradeBtn)
    local upgradeBtnSize = upgradeBtn:getContentSize()
    display.commonLabelParams(upgradeBtn , fontWithColor('14', {fontSize = 22, text = __('升级') , offset = cc.p(0, -3), ap = display.CENTER_BOTTOM}))
    --需要消耗的金币的数量
    local consumeGoldLabel = display.newLabel(upgradeBtnSize.width/2 , upgradeBtnSize.height / 2 + 3, fontWithColor('14' ,{fontSize = 22, text = '30000', ap = display.CENTER_TOP }) )
    upgradeBtn:addChild(consumeGoldLabel)
    -- 外卖车升级的经验label 
    local upgradeLevelExp = display.newRichLabel(bgSize.width/2+offsetW , 20+8, { r =true , c = {fontWithColor('14' , {  text = ""}) } }  )
    bgLayer:addChild(upgradeLevelExp)

    -- 外卖车等级满级
    local fullLevel = display.newLabel( bgSize.width/2 + offsetW , bgSize.height  - 550 , fontWithColor('14' , { text = __('该外卖车已升至最高等级')}))
    bgLayer:addChild(fullLevel)
    fullLevel:setVisible(false)
    self.viewData = {
        bgImage = bgImage ,
        needLayout = needLayout ,
        upgradeBtn = upgradeBtn ,
        upgradeLevelExp = upgradeLevelExp ,
        consumeGoldLabel = consumeGoldLabel ,
        carereteProperty = carereteProperty ,
        fullLevel = fullLevel ,
        carProperty = carProperty,
        consumeGoodsLayout = consumeGoodsLayout
    }
end
return TakeawayCarUpgradeView 