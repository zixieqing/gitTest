local GameScene = require( 'Frame.GameScene' )
---@class  CardEncyclopediaView
local CardEncyclopediaView = class('CardEncyclopediaView', GameScene)
local RES_DICT = {
    KINDS_BTN_NORMAL = _res( 'ui/home/handbook/pokedex_monster_tab_default.png'),
    KINDS_BTN_SELECT = _res( 'ui/home/handbook/pokedex_monster_tab_select.png'),
    BOSS_BG_IMAGE = _res('ui/home/handbook/pokedex_card_bg.jpg'),
    BOSS_LIST_IMAGE =  _res('ui/home/handbook/pokedex_monster_list_bg.png'),
    BOSS_BLOCK_IMAGE =  _res('ui/home/handbook/pokedex_bg_black.png'),
    CG_MAIN_BG_ENTER              = _res('ui/home/cg/CG_main_bg_enter.png'),
    CG_MAIN_BTN_ENTER             = _res('ui/home/cg/CG_main_btn_enter.png')

}
local SELECT_BTNCHECK = {
    LINKAGE = 6,
    CARD_SP = 5,
    CARD_UR = 4,
    CARD_SR = 3 ,
    CARD_R = 2 ,
    CARD_W = 1
}
local CARD_LAYOUT_SIZE= {  -- 记录内容size 的大小
    cc.size(2303 , 625),
    cc.size(3739  , 625),
    cc.size(19764 , 625),
    cc.size(22738 , 625),
    cc.size(1800 , 625),
    cc.size(1834, 625),
}
function CardEncyclopediaView:ctor()
    self.super.ctor(self,'home.CardEncyclopediaView')
    self:InitUI()
end
--==============================--
--desc:初始化界面
--time:2017-08-01 03:13:56
--@return
--==============================--
function CardEncyclopediaView:InitUI()
    local swallowLayer = display.newLayer(0,0,{ ap = display.CENTER , color = cc.c4b(0,0,0,0) ,enable =  true })
    swallowLayer:setPosition(display.center)
    self:addChild(swallowLayer)

    local bottomSize = cc.size(display.width , display.height/2  - 353)
    local middleSize = cc.size(display.SAFE_RECT.width,625)
    local middleLayout = CLayout:create(middleSize)
    middleLayout:setAnchorPoint(display.CENTER_BOTTOM)
    middleLayout:setPosition(cc.p(display.cx, bottomSize.height))
    self:addChild(middleLayout,2)

    -- title bar
    local tabNameLabel = display.newButton(display.SAFE_L + 130, display.size.height,{n = _res('ui/common/common_title.png'),enable = false,ap = cc.p(0, 1.0)})
    display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('飨灵百科'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
    self:addChild(tabNameLabel,10)

    -- back button
    local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
    backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
    self:addChild(backBtn, 5)

    --
    local touchMiddleLayout = display.newLayer(0,0,{color  = cc.c4b(0,0,0,0) ,enable = true ,size = middleSize, ap = display.CENTER})
    touchMiddleLayout:setPosition(cc.p(display.cx, bottomSize.height))
    touchMiddleLayout:setAnchorPoint(display.CENTER_BOTTOM)
    self:addChild(touchMiddleLayout,1000)
    -- 左右黑色的描边
    local blockImgSize = cc.size(173 + display.SAFE_L, 632)
    local leftBlock = display.newImageView(RES_DICT.BOSS_BLOCK_IMAGE, blockImgSize.width/2 - display.SAFE_L, middleSize.height/2  , {scale9 = true, size = blockImgSize})
    leftBlock:setScaleX(-1)
    touchMiddleLayout:addChild(leftBlock,100)

    local rightBlock = display.newImageView(RES_DICT.BOSS_BLOCK_IMAGE, middleSize.width - blockImgSize.width/2 + display.SAFE_L, middleSize.height/2 ,{scale9 = true, size = blockImgSize})
    touchMiddleLayout:addChild(rightBlock,100)
    -------------------------------------------------
    -- 顶部的范围
    local topSize = cc.size(display.SAFE_RECT.width, display.height/2 - 272)
    local topLayout = CLayout:create(topSize)
    topLayout:setAnchorPoint(display.CENTER_BOTTOM)
    topLayout:setPosition(cc.p(display.cx, bottomSize.height + middleSize.height))
    self:addChild(topLayout,2)

    -- 加载中部的layout
    local bgImageList = display.newImageView(RES_DICT.BOSS_LIST_IMAGE, middleSize.width/2,middleSize.height/2, {scale9 = true, size = cc.size(display.width, 632)})
    middleLayout:addChild(bgImageList)

    -------------------------------------------------
    -- 下面的范围
    local bottomLayout = CLayout:create(bottomSize)
    bottomLayout:setPosition(cc.p(display.width/2,0))
    bottomLayout:setAnchorPoint(display.CENTER_BOTTOM)
    self:addChild(bottomLayout,2)

    -------------------------------------------------
    -- 创建bottonLayout 的部分
    local bottonSize = cc.size(145,92)


    local cardQuality = CommonUtils.GetConfigAllMess('quality','card')
    local kindsBoss =  {
        --{ __('联动'),"0/10", SELECT_BTNCHECK.LINKAGE  },
        { cardQuality[tostring(SELECT_BTNCHECK.CARD_W)].quality ,"0/10" ,SELECT_BTNCHECK.CARD_W},
        { cardQuality[tostring(SELECT_BTNCHECK.CARD_R)].quality ,"0/10",SELECT_BTNCHECK.CARD_R},
        { cardQuality[tostring(SELECT_BTNCHECK.CARD_SR)].quality ,"0/10", SELECT_BTNCHECK.CARD_SR},
        { cardQuality[tostring(SELECT_BTNCHECK.CARD_UR)].quality ,"0/10",SELECT_BTNCHECK.CARD_UR} ,
        { cardQuality[tostring(SELECT_BTNCHECK.CARD_SP)].quality ,"0/10",SELECT_BTNCHECK.CARD_SP}

    }

    local bottonLayoutSize = cc.size(bottonSize.width * (#kindsBoss) ,bottonSize.height)
    local bottonLayout = CLayout:create(bottonLayoutSize)
    bottonLayout:setAnchorPoint(display.RIGHT_BOTTOM)
    bottonLayout:setPosition(cc.p(display.SAFE_R -20 , -3) )
    -- 裁剪图片
    -- local clippingNode = cc.ClippingNode:create()
    local noticeImage = display.newImageView(RES_DICT.BOSS_BG_IMAGE, {isFull = true})
    self:addChild(noticeImage)
    noticeImage:setPosition(cc.p(display.cx, display.cy))
    local checkButtons = {}
    -- local checkedBtnTable = {}
    for i =1 ,  #kindsBoss do
        local checkBtned = display.newButton((i -0.5) *bottonSize.width,bottonLayoutSize.height/2,{n = RES_DICT.KINDS_BTN_NORMAL , s = RES_DICT.KINDS_BTN_SELECT,enable = true})
        -- 这个是选中的btn按钮
        local bossKindsName = display.newLabel(bottonSize.width/2+5,bottonSize.height /2 + 13,fontWithColor('14',{ fontSize = 24 , color = '#ffc52a' ,text = kindsBoss[i][1] , outline ="#4f2212"}) )
        -- 选中的boss 名称
        local prograssName =  display.newLabel(bottonSize.width/2, bottonSize.height/2 -20, {text = "" , fontSize = 22 , color = "#ffffff" , ap = display.CENTER})
        checkBtned:addChild(prograssName)
        --local collectLabel = display.newLabel( , {text =  __('收集') .. "  " , fontSize = 22 , color = "#f4d8a7" , ap = display.LEFT_CENTER})
        --local prograssNameLayout = display.newLayer(bottonSize.width/2, bottonSize.height/2 ,{size = cc.size( 20, 100) ,ap = display.CENTER_BOTTOM})
        --CLayout:create(cc.size( 20, 100))
        --display.newLayer(bottonSize.width/2, 0 {size = cc.size( 20, 100) ,ap = display.CENTER_BOTTOM})
        --prograssNameLayout:addChild(collectLabel)
        --prograssNameLayout:addChild(prograssName)
        -- 收集boss 的进度
        checkBtned:addChild(bossKindsName)
        --checkBtned:addChild(prograssNameLayout)
        checkBtned.bossKindsName = bossKindsName
        checkBtned.prograssName = prograssName
        --checkBtned.collectLabel = collectLabel
        --checkBtned.prograssNameLayout = prograssNameLayout
        checkBtned:setTag(kindsBoss[i][3])
        bottonLayout:addChild(checkBtned)
        checkButtons[tostring(kindsBoss[i][3])] = checkBtned
    end
    topLayout:addChild(bottonLayout)

    -------------------------------------------------
    local tabNameLabelPos = cc.p(tabNameLabel:getPosition())
    tabNameLabel:setPositionY(display.height + 100)
    local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
    tabNameLabel:runAction( action )
    self.viewData = {
        middleLayout = middleLayout,
        touchMiddleLayout = touchMiddleLayout,
        topLayout = topLayout,
        bottomLayout = bottomLayout,
        bottonLayout = bottonLayout,
        navBack = backBtn,
        checkButtons = checkButtons
    }
end
--==============================--
--desc:更新Button 的显示
-- data 格式 { "1" = { owner = num , count = num }}
--time:2017-08-03 05:02:36
--@return
--==============================--
function CardEncyclopediaView:UpdateButton(data)
    local contentSize = nil
    --local prograssNameSize = nil
    --local collectLabelSize = nil
    for k , v in pairs (self.viewData.checkButtons) do
        v.prograssName:setString(string.format( "%s/%s",data[k].owner , data[k].count))
        --prograssNameSize = display.getLabelContentSize(v.prograssName)
        --collectLabelSize = display.getLabelContentSize(v.collectLabel)
        --contentSize = cc.size(prograssNameSize.width + collectLabelSize.width , collectLabelSize.height)
        --v.prograssNameLayout:setContentSize(contentSize)
        --v.collectLabel:setPosition(0,contentSize.height/2)
        --v.prograssName:setPosition(cc.p(collectLabelSize.width , contentSize.height/2 ))
    end
end

function CardEncyclopediaView:CreateCollectLayout()
    local collectLayout = display.newLayer(1492, -2,
            { ap = display.RIGHT_BOTTOM,  size = cc.size(555, 146) ,color = cc.c4b(0,0,0,0) ,enable = true  })
    collectLayout:setPosition(display.SAFE_R + 158, -2)
    self:addChild(collectLayout ,1000)

    local bottomImage = display.newImageView(RES_DICT.CG_MAIN_BG_ENTER, -1, 0,
            { ap = display.LEFT_BOTTOM, tag = 1369, enable = false })
    collectLayout:addChild(bottomImage)


    local superPluzzBtn = display.newButton(278, 30, { ap = display.CENTER ,  n = RES_DICT.CG_MAIN_BTN_ENTER, s = RES_DICT.CG_MAIN_BTN_ENTER, tag = 1366 })
    display.commonLabelParams(superPluzzBtn, fontWithColor(14, { text =__('飨灵回忆'), fontSize = 24, w = 300 , hAlign = display.TAC,  color = '#ffffff' }))
    collectLayout:addChild(superPluzzBtn,2)

    local progressLabel = display.newLabel(272, 80,
            { ap = display.RIGHT_CENTER, text = __('已收集:'), color = '#f4d8a7',  fontSize = 24, tag = 1368 })
    collectLayout:addChild(progressLabel)

    local progressNum = display.newLabel(286, 80,
            { ap = display.LEFT_CENTER, color = '#ffffff', text = "", fontSize = 24, tag = 1369 })
    collectLayout:addChild(progressNum)
    self.viewData.collectLayout = collectLayout
    self.viewData.progressLabel = progressLabel
    self.viewData.progressNum = progressNum
    self.viewData.superPluzzBtn = superPluzzBtn
end
--==============================--
--desc:创建不同的页面
--time:2017-08-02 05:33:50
--@type:
--@return
--==============================--
function CardEncyclopediaView:CreateCardLayout(type )
    -- local cardLayout = display.newLayer(0,0,{color =cc.c4b(100,200,100,100) , size = CARD_LAYOUT_SIZE[type] ,ap = display.LEFT_BOTTOM})
    local containerW = self.viewData.middleLayout:getContentSize().width
    local cardLayout = CLayout:create(cc.size(math.max(containerW, CARD_LAYOUT_SIZE[type].width), CARD_LAYOUT_SIZE[type].height))
    cardLayout:setPosition(cc.p(0,0))
    cardLayout:setAnchorPoint(display.LEFT_BOTTOM)
    self.viewData.middleLayout:addChild(cardLayout)
    return cardLayout
end
return CardEncyclopediaView
