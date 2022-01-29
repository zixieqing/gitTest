
local GameScene = require( 'Frame.GameScene' )
---@type GoodPurchaseNode
local GoodPurchaseNode = require('common.GoodPurchaseNode')
---@class SeasonLiveView :GameScene
local SeasonLiveView = class('SeasonLiveView', GameScene)
local  seasonQuestData = CommonUtils.GetConfigAllMess('quest' , 'seasonActivity')
local RES_DICT = {
   BG_IMAGE_ONE  = _res('ui/home/activity/seasonlive/season_battle_bg'),
   BG_IMAGE_TWO  = _res('battle/map/main_map_bg_12_10.png'),
   BOTTOM_BATTLE_BG = _res('ui/home/activity/seasonlive/season_battle_bg_below'),
   TOP_BATTLE_BG = _res('ui/home/activity/seasonlive/season_battle_bg_up'),
   TOP_RIGHT_IMAGE = _res('ui/home/activity/seasonlive/season_battle_bg_up_right'),
   SEASONIG_LABEL  = _res('ui/home/activity/seasonlive/season_battle_label_num'),
   BATTLE_BG_DECO  = _res('ui/home/activity/seasonlive/season_battle_bg_deco'),

}

function SeasonLiveView:ctor()
    self.super.ctor(self,'home.SeasonLiveView')
    self:InitUI()
end
--==============================--
--desc:初始化界面
--time:2017-08-01 03:13:56
--@return
--==============================--
function SeasonLiveView:InitUI()
    local swallowLayer = display.newLayer(0,0,{ ap = display.CENTER , color = cc.c4b(0,0,0,0) , enable =  true })

    swallowLayer:setPosition(display.center)
    self:addChild(swallowLayer)

    local bgLayout = display.newLayer(display.width/2 , display.height/2, { ap = display.CENTER , color1 = cc.r4b() , size = display.size})
    self:addChild(bgLayout)
    local bgImageWidth = 1334
    local oneBgImage  = display.newImageView(RES_DICT.BG_IMAGE_ONE, display.width/2, display.height/2,{ scale =  display.width/bgImageWidth  })
    bgLayout:addChild(oneBgImage)
    local  leftImage =  display.newImageView(RES_DICT.BATTLE_BG_DECO , display.SAFE_L +15 , display.height , {ap  = display.CENTER_TOP})
    bgLayout:addChild(leftImage)
    local  rightImage =  display.newImageView(RES_DICT.BATTLE_BG_DECO , display.SAFE_R -15 , display.height , {ap  = display.CENTER_TOP})
    bgLayout:addChild(rightImage)
    --local YEARS_WINS_ID = self:GetSpecialGoodId()
    local iconData = { YEARS_WINS_ID ,DOOR_GUN_ID, GOLD_ID, DIAMOND_ID}
    local cellSize = cc.size(190,40)

    local len = #iconData
    local  topSize = cc.size(cellSize.width * len + 20 ,cellSize.height)
    local topLayout = display.newLayer( display.SAFE_R,display.height, { ap = display.RIGHT_TOP , size =  topSize})
    bgLayout:addChild(topLayout)
    local imageImage = display.newImageView(_res('ui/home/nmain/main_bg_money.png'),topSize.width/2,topSize.height/2,{enable = false,
                                      scale9 = true, size = cc.size(topSize.width + 60, 54)})
    topLayout:addChild(imageImage)


    local purchaseNodes = {}
    for k ,v  in pairs(iconData) do
        local isShowHpTips = (v == HP_ID) and 1 or -1

        local purchaseNode = GoodPurchaseNode.new({id = v, isShowHpTips = isShowHpTips})
        purchaseNode:updataUi(checkint(v))
        if checkint(YEARS_WINS_ID) ==  checkint(v) then
            purchaseNode.viewData.bg:setTexture(_res('ui/common/common_btn_huobi_2'))
        end
        purchaseNode:setPosition(cc.p(cellSize.width * (k -0.5) , cellSize.height/2 ))
        topLayout:addChild(purchaseNode,10)
        purchaseNode.viewData.touchBg:setTag(checkint(v))
        purchaseNodes[tostring(v)] = purchaseNode
    end


    local exchangeTable = {}
    local topIcon =  CommonUtils.GetConfigAllMess('topIcon', 'seasonActivity')
    local count =table.nums(topIcon)
    local exchangeGoodsSize  = cc.size(200, 50)
    local countGoodSize  = cc.size(exchangeGoodsSize.width *count,exchangeGoodsSize.height )
    local countGoodLayout = display.newLayer(display.SAFE_R, 0 , { size = countGoodSize , ap = display.RIGHT_BOTTOM , color1 = cc.r4b()})

    for i =1 , count  do
        local exchangeLayout = display.newLayer(exchangeGoodsSize.width *( i -0.5 ) , exchangeGoodsSize.height/2 , { size = exchangeGoodsSize , ap = display.CENTER , color1 = cc.r4b()})
        countGoodLayout:addChild(exchangeLayout)
        exchangeTable[#exchangeTable+1] = exchangeLayout
        -- 图片的背景
        local battleNumImage = display.newImageView(_res('ui/common/common_btn_huobi_2') , exchangeGoodsSize.width/2 , exchangeGoodsSize.height/2)
        exchangeLayout:addChild(battleNumImage)
        -- 道具的图片
        local goodsImage  = display.newImageView(CommonUtils.GetGoodsIconPathById(topIcon[tostring(i)].goodsId or DIAMOND_ID) , -10, exchangeGoodsSize.height/2 , {ap = display.LEFT_CENTER } )
        goodsImage:setScale(0.5)
        exchangeLayout:addChild(goodsImage)
        goodsImage:setName("goodsImage")

        -- 道具的数量
        local goodsNum = display.newLabel( 80 , exchangeGoodsSize.height/2 ,fontWithColor('14' ,{ ap = display.LEFT_CENTER , text = 10000}) )
        exchangeLayout:addChild(goodsNum)
        goodsNum:setName("goodsNum")

    end
    bgLayout:addChild(countGoodLayout , 11)
    -- 下部的图片
    local bottomImage = display.newImageView(RES_DICT.BOTTOM_BATTLE_BG,  display.width/2 , 0 , { ap = display.CENTER_BOTTOM})
    bgLayout:addChild(bottomImage)

    local  gainListSize = cc.size(100, 680)
    local gainListView = CListView:create(gainListSize)
    gainListView:setDirection(eScrollViewDirectionHorizontal)
    gainListView:setBounceable(false)
    bgLayout:addChild(gainListView, 10)
    gainListView:setAnchorPoint(display.CENTER)
    gainListView:setPosition(cc.p(display.cx, display.cy+ 20))
    ---- 返回的按钮
    local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
    backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
    self:addChild(backBtn, 5)
    local tipBtn = display.newButton(0 , 25 ,{ap = display.LEFT_CENTER , n = _res('ui/common/common_btn_tips') , enable = false})
    self:addChild(tipBtn, 5)
    local instructionLabel = display.newLabel(50, 25,{fontSize = 22 , text = __('关卡难度越高掉落道具【岁酒】的概率越高,极难难度必掉【岁酒】' ) , ap = display.LEFT_CENTER} )
    self:addChild(instructionLabel, 5)
    self.viewData = {
        rightLabel = rightLabel ,
        leftLabel = leftLabel ,
        topLayout = topLayout ,
        gainListView = gainListView,
        exchangeTable = exchangeTable ,
        navBack = backBtn ,
        purchaseNodes = purchaseNodes
    }
end

--[[
    刷新顶部的UI
--]]
function SeasonLiveView:UpdateCountUI()
    if self.viewData and  self.viewData.purchaseNodes then
        for k ,v in pairs(self.viewData.purchaseNodes or {})do
            v:updataUi(checkint(k))
        end
    end
end
return SeasonLiveView
