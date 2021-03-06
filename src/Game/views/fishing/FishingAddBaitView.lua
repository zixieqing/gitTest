---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2018/8/10 4:38 PM
---
--[[
    钓场主界面
--]]
---@class FishingAddBaitView
local FishingAddBaitView = class('FishingAddBaitView', function()
    local node = CLayout:create(display.size)
    node:setAnchorPoint(display.CENTER)
    node.name = 'home.LimitChestGiftView1'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    SIDE_BG       = _res('ui/home/fishing/fishing_add_bait__side_bg.png'),
    BAIT_BG       = _res('ui/home/fishing/fishing_add_bait_bait_bg.png'),
    BG_BARREL     = _res('ui/home/fishing/fishing_add_bait_bg_barrel.png'),
    ADD_BAIT_BG   = _res('ui/home/fishing/fishing_add_bait_bg.png'),
    BTN_REMOVE    = _res('ui/home/fishing/fishing_add_bait_btn_remove.png'),
    TIME_BG_2     = _res('ui/home/fishing/fishing_add_bait_time_bg_2.png'),
    TIME_TITLE    = _res('ui/home/fishing/fishing_add_bait_time_title.png'),
    BAIT_TIME     = _res('ui/home/fishing/fishing_add_bait_time.png'),
    BG_RONG_LIANG = _res('ui/home/fishing/fishing_add_bait_bg_rongliang.png'),
    BARREL_LIGHT  = _res('ui/home/fishing/fishing_add_bait_bg_barrel_light.png'),
    BG_NUMBER     = _res('ui/home/fishing/fishing_add_bait_bait_bg_number.png'),
    BG_TEXT       = _res('ui/common/commcon_bg_text.png'),
    BG_GOODS      = _res('ui/common/common_bg_goods.png'),
    NUM_BG        = _res('ui/home/commonShop/market_sold_bg_goods_info.png'),
    BTN_PLUS      = _res('ui/home/market/market_sold_btn_plus.png'),
    BTN_MAX       = _res('ui/home/market/market_sold_btn_zuida.png'),
    BTN_SUB       = _res('ui/home/market/market_sold_btn_sub.png'),
    BTN_ORANGE    = _res('ui/common/common_btn_orange.png'),
    DELETE_DISH   = _res("ui/home/lobby/cooking/restaurant_kitchen_btn_delete_dish.png"),
}
function FishingAddBaitView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end

function FishingAddBaitView:InitUI()
    local closeLayer = display.newLayer(display.width/2 , display.height/2,
    {ap = display.CENTER , color = cc.c4b(0,0,0,175) , enable = true })
    self:addChild(closeLayer)
    local rightImage = display.newImageView(RES_DICT.ADD_BAIT_BG)
    local rightSize = rightImage:getContentSize()

    local rightLayout = display.newLayer(display.SAFE_R , display.height/2 ,
    {ap = display.RIGHT_CENTER , size =   rightSize })
    rightLayout:addChild(rightImage)
    local rightSize = rightLayout:getContentSize()
    local rightPos = cc.p(display.width + rightSize.width  ,display.height/2)
    rightLayout:setPosition(rightPos )
    rightLayout:setOpacity(0)
    rightLayout:setName("rightLayout")
    rightImage:setPosition(rightSize.width/2 , rightSize.height/2)
    self:addChild(rightLayout,4)

    local swallowOneLayer = display.newLayer(rightSize.width /2 , rightSize.height/2 ,
    {ap = display.CENTER, size = rightSize ,color = cc.c4b(0,0,0,0) , enable = true } )
    rightLayout:addChild(swallowOneLayer)

    local bgGoodsImage = display.newImageView(RES_DICT.BG_GOODS , rightSize.width /2 , rightSize.height - 60
    ,{ap = display.CENTER_TOP , scale9 = true , size = cc.size(346,584)})
    rightLayout:addChild(bgGoodsImage)
    local fishLabel = display.newLabel(rightSize.width/2 , rightSize.height - 35 , fontWithColor(16,{text   = __('选择钓饵') }))
    rightLayout:addChild(fishLabel)
    local listSize =  cc.size(344,580)
    local listCellSize = cc.size(115,115)
    local gridView = CGridView:create(cc.size(listSize.width , listSize.height))
    gridView:setSizeOfCell(listCellSize)
    gridView:setColumns(3)
    rightLayout:addChild(gridView, 10)
    gridView:setAnchorPoint(display.CENTER_TOP)
    gridView:setPosition(rightSize.width /2 , rightSize.height - 65)
    self.viewData = {
        gridView = gridView  ,
        closeLayer = closeLayer
    }
end

function FishingAddBaitView:CreateAddBaitLayout()
    local bgBarrelImage = display.newImageView(RES_DICT.BG_BARREL )
    bgBarrelImage:setName("bgBarrelImage")
    local bgBarrelSize = bgBarrelImage:getContentSize()
    local bgBarrelLayout = display.newLayer(display.SAFE_R - 510 , -120 , {ap = display.RIGHT_BOTTOM ,size = bgBarrelSize })
    self:addChild(bgBarrelLayout)
    bgBarrelLayout:setName("bgBarrelLayout")
    local bgBarrelSwallow = display.newLayer(bgBarrelSize.width/2 ,bgBarrelSize.height/2 ,
{size = bgBarrelSize , color = cc.c4b(0,0,0,0),enable = true  })
    bgBarrelLayout:addChild(bgBarrelSwallow)

    bgBarrelImage:setPosition(bgBarrelSize.width/2 , bgBarrelSize.height/2)
    bgBarrelLayout:addChild(bgBarrelImage)
    bgBarrelImage:setOpacity(0)
    bgBarrelImage:setName("bgBarrelImage")
    local swallowTwoLayer = display.newLayer(bgBarrelSize.width /2 , bgBarrelSize.height/2 ,
            {ap = display.CENTER, size = bgBarrelSize ,color = cc.c4b(0,0,0,0) , enable = true } )
    bgBarrelLayout:addChild(swallowTwoLayer)
    local bgRongLianImage  = display.newButton(bgBarrelSize.width/2 , bgBarrelSize.height - 250 ,{n = RES_DICT.BG_RONG_LIANG , padding = 30 , scale9 = true  }     )
    bgBarrelLayout:addChild(bgRongLianImage)
    bgRongLianImage:setName("bgRongLianImage")
    bgRongLianImage:setOpacity(0)
    local baitTimeImage = display.newImageView(RES_DICT.TIME_BG_2 , bgBarrelSize.width /2 , bgBarrelSize.height /2 -  115 ,
            {ap = display.CENTER_BOTTOM})
    bgBarrelLayout:addChild(baitTimeImage)
    baitTimeImage:setName("baitTimeImage")
    local baitTimeImageSize = baitTimeImage:getContentSize()

    local baitTimeDescr = display.newLabel(20 , baitTimeImageSize.height /2 ,
            {ap = display.LEFT_CENTER , fontSize = 24 ,reqW = 200 ,  color = '#5b3c25', text = __('消耗时间')})
    baitTimeImage:addChild(baitTimeDescr)
    baitTimeDescr:setName("baitTimeDescr")
    baitTimeDescr:setOpacity(0)
    local baitTimeLabel = display.newLabel(250-20 , baitTimeImageSize.height /2 ,
           fontWithColor(14,  {ap = display.LEFT_CENTER , fontSize = 24 ,  text = 5000}))
    baitTimeImage:addChild(baitTimeLabel)
    baitTimeLabel:setOpacity(0)
    baitTimeImage:setOpacity(0)
    baitTimeLabel:setName("baitTimeLabel")
    local baitTimeImageTwo = display.newImageView(RES_DICT.TIME_BG_2 , bgBarrelSize.width /2 , bgBarrelSize.height /2 -  60 ,
            {ap = display.CENTER_BOTTOM})
    bgBarrelLayout:addChild(baitTimeImageTwo)
    baitTimeImageTwo:setName("baitTimeImageTwo")
    baitTimeImageTwo:setOpacity(0)
    local freshnessDescr = display.newLabel(20 , baitTimeImageSize.height /2 ,
            {ap = display.LEFT_CENTER , fontSize = 24 ,reqW = 200 ,  color = '#5b3c25', text = __('消耗新鲜度')})
    baitTimeImageTwo:addChild(freshnessDescr)
    freshnessDescr:setName("freshnessDescr") 
    freshnessDescr:setOpacity(0)
    local freshnessLabel = display.newLabel(250 -20, baitTimeImageSize.height /2 ,
            fontWithColor(14, {ap = display.LEFT_CENTER , fontSize = 24 ,  text = 5000}))
    baitTimeImageTwo:addChild(freshnessLabel)
    freshnessLabel:setName("freshnessLabel")
    freshnessLabel:setOpacity(0)
    local bgLightImage = display.newImageView(RES_DICT.BARREL_LIGHT ,bgBarrelSize.width/2 , bgBarrelSize.height + 135  , {ap = display.CENTER_TOP} )
    bgBarrelLayout:addChild(bgLightImage,10)
    bgLightImage:setName("bgLightImage")
    local baitGoodSize = cc.size(600 , 200 )
    local baitGoodLayout = display.newLayer(bgBarrelSize.width/2 , bgBarrelSize.height - 10 ,
    {ap = display.CENTER_TOP , size = baitGoodSize })
    bgBarrelLayout:addChild(baitGoodLayout,10)
    baitGoodLayout:setOpacity(0)
    baitGoodLayout:setName("baitGoodLayout")
    local goodLayoutSize = cc.size(baitGoodSize.width /3 , baitGoodSize.height)
    local path = CommonUtils.GetGoodsIconPathById(DIAMOND_ID)
    for i = 1 , 3 do
        local goodLayout = display.newLayer(goodLayoutSize.width * (i - 0.5 ) , goodLayoutSize.height/2 ,
        {ap = display.CENTER , size = goodLayoutSize  })
        baitGoodLayout:addChild(goodLayout)
        goodLayout:setTag(i)
        local baitBgImage = display.newImageView(RES_DICT.BAIT_BG , goodLayoutSize.width/2 , goodLayoutSize.height/2 )
        goodLayout:addChild(baitBgImage)
        local goodImage = display.newImageView(path ,goodLayoutSize.width/2 , goodLayoutSize.height /2  )
        goodLayout:addChild(goodImage)
        goodImage:setVisible(false)
        goodImage:setScale(0.8)
        goodImage:setName("goodImage")

        local emptyLabel = display.newLabel(goodLayoutSize.width/2 , goodLayoutSize.height/2 ,
        fontWithColor(16,{text = __('空')}))
        goodLayout:addChild(emptyLabel)
        emptyLabel:setName("emptyLabel")
        emptyLabel:setVisible(false)
        local clearBaitButton = display.newButton(goodLayoutSize.width/2 + 60 , goodLayoutSize.height/2 + 60 , {n = RES_DICT.DELETE_DISH} )
        goodLayout:addChild(clearBaitButton)
        clearBaitButton:setVisible(false)
        clearBaitButton:setName("clearBaitButton")
        clearBaitButton:setTag(i)
        local numberBtn = display.newButton(goodLayoutSize.width/2  , goodLayoutSize.height/2 - 80 , {n = RES_DICT.BG_NUMBER} )
        goodLayout:addChild(numberBtn)
        numberBtn:setName("numberBtn")
        display.commonLabelParams(numberBtn  ,fontWithColor('16' , {text = '11' , color = 'ffffff'}))
    end
    return bgBarrelLayout

end
function FishingAddBaitView:CreateBaitInfor()
    local swallowOneLayer = display.newLayer(display.width/2 ,display.height/2,
            {ap =display.CENTER , color = cc.r4b(0,0,0,0), enable = true , size = display.size })
    swallowOneLayer:setVisible(false)
    self:addChild(swallowOneLayer,1)
    swallowOneLayer:setName("swallowOneLayer")
    local sideBg = display.newImageView(RES_DICT.SIDE_BG )
    local sideBgSize = sideBg:getContentSize()
    sideBg:setPosition(sideBgSize.width/2 , sideBgSize.height/2)
    local sideLayout =  display.newLayer(0,0, {size = sideBgSize , ap = display.LEFT_CENTER } )
    sideLayout:addChild(sideBg)
    local sideLayoutSwallow = display.newLayer(sideBgSize.width/2 , sideBgSize.height/2 , {ap = display.CENTER ,size = sideBgSize ,enable = true , color = cc.c4b(0,0,0,0)})
    sideLayout:addChild(sideLayoutSwallow)
    sideLayout:setName("sideLayout")
    local rightLayout = self:getChildByName("rightLayout")
    local rightSize = rightLayout:getContentSize()
    local sidePos = cc.p(display.SAFE_R - rightSize.width  ,display.height/2)
    sideLayout:setPosition(sidePos)
    sideLayout:setOpacity(0)

    local goodNode = require("common.GoodNode").new({goodsId = DIAMOND_ID , showAmount = false})
    sideLayout:addChild(goodNode)
    goodNode:setAnchorPoint(display.CENTER_TOP)
    goodNode:setPosition(84 , sideBgSize.height - 34)
    goodNode:setName("goodNode")

    local goodsName = display.newLabel(84 , sideBgSize.height - 170,
    fontWithColor('16', {text = "xxxx" , w = 150 , hAlign = display.TAC}))
    sideLayout:addChild(goodsName)
    goodsName:setName("goodsName")

    local commonTextImage = display.newImageView(RES_DICT.BG_TEXT,160, sideBgSize.height - 30 ,
{scale9 = true , size = cc.size(270,164) , ap = display.LEFT_TOP})
    sideLayout:addChild(commonTextImage)
    commonTextImage:setCascadeOpacityEnabled(true)
    commonTextImage:setName("commonTextImage")
    local commonTextSize = commonTextImage:getContentSize()

    local goodsEffect = display.newLabel(commonTextSize.width /2 , commonTextSize.height - 10 ,
    fontWithColor('5' , { fontSize = 19 ,  ap = display.CENTER_TOP ,  w = 260 , hAlign = display.TAL ,text = "xxxxxxx"}) )
    commonTextImage:addChild(goodsEffect)
    goodsEffect:setName("goodsEffect")

    local baitTime  = display.newImageView(RES_DICT.BAIT_TIME , sideBgSize.width /2- 15 , sideBgSize.height - 220 ,
{ap = display.CENTER_TOP })
    sideLayout:addChild(baitTime)
    baitTime:setName("baitTime")
    local baitTimeSize = baitTime:getContentSize()

    local timeTitleOne  = display.newImageView(RES_DICT.TIME_TITLE , baitTimeSize.width/2 , baitTimeSize.height , {ap = display.CENTER_TOP})
    baitTime:addChild(timeTitleOne)
    baitTime:setCascadeOpacityEnabled(true )

    local baitTimeLabel  = display.newLabel( baitTimeSize.width/2 ,  baitTimeSize.height * 3/4,
    fontWithColor(16, {text = __('消耗时间')}) )
    baitTime:addChild(baitTimeLabel)
    baitTimeLabel:setName("baitTimeLabel")
    
    local baitTimeNums  = display.newRichLabel( baitTimeSize.width/2 ,  baitTimeSize.height * 1/4, {c= {
                fontWithColor(16, {text = ""}) } } )
    baitTime:addChild(baitTimeNums)
    baitTimeNums:setName("baitTimeNums")

    local baitNum  = display.newImageView(RES_DICT.BAIT_TIME , sideBgSize.width /2 -15, sideBgSize.height - 320 ,
            {ap = display.CENTER_TOP })
    sideLayout:addChild(baitNum)
    baitNum:setName("baitNum")

    baitNum:setCascadeOpacityEnabled(true )
    local timeTitleTwo  = display.newImageView(RES_DICT.TIME_TITLE , baitTimeSize.width/2 , baitTimeSize.height , {ap = display.CENTER_TOP})
    baitNum:addChild(timeTitleTwo)
    
    local baitNumLabel  = display.newLabel( baitTimeSize.width/2 ,  baitTimeSize.height * 3/4,
            fontWithColor(16, {text = __('消耗新鲜度')}) )
    baitNum:addChild(baitNumLabel)
    baitNumLabel:setName("baitNumLabel")
    

    local baitNumNums  = display.newRichLabel( baitTimeSize.width/2 ,  baitTimeSize.height * 1/4, {r= true ,  c= {
        fontWithColor(16, {text = ''}) } } )
    baitNum:addChild(baitNumNums)
    baitNumNums:setName("baitNumNums")


    local addFriendLabel = display.newLabel(sideBgSize.width/2 ,  40 ,
    fontWithColor(6, {hAlign = display.TAC , w =  350  , text = __('去好友的钓场进行垂钓，双方都可以获得奖励哦！')}) )
    sideLayout:addChild(addFriendLabel)
    local baitSize = cc.size(sideBgSize.width , 60 )
    local baitLayout = display.newLayer(sideBgSize.width /2 -15  ,150 , {ap = display.CENTER_BOTTOM ,size = baitSize} )
    sideLayout:addChild(baitLayout)
    baitLayout:setName("baitLayout")

    local  goodsInfo = display.newButton(baitSize.width /2    , baitSize.height/2 ,
    {ap = display.CENTER , n = RES_DICT.NUM_BG , s = RES_DICT.NUM_BG , scale9 = true , size = cc.size(133,45) } )
    display.commonLabelParams(goodsInfo , fontWithColor(6,{text = 0 }))
    baitLayout:addChild(goodsInfo)
    goodsInfo:setName("goodsInfo")
    local reduceBtn = display.newButton(baitSize.width/2 - 90 , baitSize.height/2 , {n = RES_DICT.BTN_SUB })
    baitLayout:addChild(reduceBtn,3)
    reduceBtn:setName("reduceBtn")

    local addBtn = display.newButton(baitSize.width/2 +  90 , baitSize.height/2 , {n = RES_DICT.BTN_PLUS })
    baitLayout:addChild(addBtn,3)
    addBtn:setName("addBtn")

    local maxBtn = display.newButton(baitSize.width/2 +  160,baitSize.height/2 ,{n = RES_DICT.BTN_MAX }  )
    baitLayout:addChild(maxBtn)
    display.commonLabelParams(maxBtn , fontWithColor(14 , {text = __('最大')}))
    maxBtn:setName("maxBtn")


    local numLabel = display.newLabel(baitSize.width/2 - 130 , baitSize.height/2 ,
    fontWithColor(6,{ap = display.RIGHT_CENTER ,text = __('数量') }))
    baitLayout:addChild(numLabel)

    local addBaitBtn = display.newButton(sideBgSize.width /2-15 , 100 ,{n = RES_DICT.BTN_ORANGE})
    display.commonLabelParams(addBaitBtn , fontWithColor(14,{ text = __('添加钓饵')}))
    sideLayout:addChild(addBaitBtn)
    addBaitBtn:setName("addBaitBtn")


    return sideLayout
end

return FishingAddBaitView