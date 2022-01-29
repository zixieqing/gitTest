---@class SunFlowerBibleView : Node
local SunFlowerBibleView = class('SunFlowerBibleView', function ()
    local node = CLayout:create(display.size)
    node.name = 'SunFlowerBibleView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT           ={
    HANDBOOK_BG                              = _res("ui/home/sunflower/handbook_bg.jpg"),
    COMMON_BTN_BACK                          = _res("ui/common/common_btn_back.png"),
    COMMON_BTN_ORANGE                        = _res("ui/common/common_btn_orange.png"),
    COMMON_TITLE                             = _res("ui/common/common_title.png"),
    COMMON_BTN_TIPS                          = _res("ui/airship/common_btn_tips.png"),
    HANDBOOK_LIST_BG                         = _res("ui/home/sunflower/handbook_list_bg.png"),
    HANDBOOK_LIST_BG_LIGHT                   = _res("ui/home/sunflower/handbook_list_bg_light.png"),
    HANDBOOK_LIST_ICO_1                      = _res("ui/home/sunflower/handbook_list_ico_1.png"),
    HANDBOOK_BOOK_BG                         = _res("ui/home/sunflower/handbook_book_bg.png"),
    HANDBOOK_BOOK_BG_HEAD                    = _res("ui/home/sunflower/handbook_book_bg_head.png"),
    HANDBOOK_BOOK_BG_LIST                    = _res("ui/home/sunflower/handbook_book_bg_list.png"),
    HANDBOOK_BOOK_BG_LIST_HEAD               = _res("ui/home/sunflower/handbook_book_bg_list_head.png"),
    COMMON_BTN_BIG_ORANGE                    = _res("ui/common/common_btn_big_orange.png")
}

--[[
constructor
--]]
function SunFlowerBibleView:ctor(...)
    self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function SunFlowerBibleView:InitUI()
    local swallpwLayer = display.newLayer(display.cx, display.cy ,{ap = display.CENTER,size = display.size,color = cc.c4b(0,0,0,0),enable = true})
    self:addChild(swallpwLayer,0)
    local bgImage = display.newImageView( RES_DICT.HANDBOOK_BG ,display.cx + 0, display.cy  + 0,{ap = display.CENTER})
    self:addChild(bgImage,0)
    local topLayer = display.newLayer(display.cx, display.cy ,{ap = display.CENTER,size = display.size})
    self:addChild(topLayer,12)
    local backBtn = display.newButton(display.SAFE_L + 13, display.cy + 322 , {n = RES_DICT.COMMON_BTN_BACK,ap = display.LEFT_CENTER,scale9 = true,size = cc.size(90,70)})
    topLayer:addChild(backBtn,0)
    display.commonLabelParams(backBtn ,{fontSize = 20,text = '',color = '#ffffff',paddingW  = 20,safeW = 50})
    local tabLabelName = display.newButton(display.SAFE_L + 96.5, display.cy + 333 , {n = RES_DICT.COMMON_TITLE,ap = display.LEFT_CENTER})
    topLayer:addChild(tabLabelName,0)
    display.commonLabelParams(tabLabelName ,fontWithColor(14 , {outline = false ,text = __('我要变强'),color = '#5b3c25', fontSize = 30, offset = cc.p(-0 , -7)}))
    local tipImage = display.newImageView( RES_DICT.COMMON_BTN_TIPS ,252, 26,{ap = display.CENTER})
    tabLabelName:addChild(tipImage,0)
    local leftLayout = display.newLayer(display.cx + -506, display.cy  + -48 ,{ap = display.CENTER,size = cc.size(200,635)})
    self:addChild(leftLayout,0)
    local lScrollView = CListView:create(cc.size(152, 540))
    lScrollView:setAnchorPoint(display.CENTER)
    lScrollView:setPosition(96 , 307.5)
    leftLayout:addChild(lScrollView,10)
    local lefeImage = display.newImageView( RES_DICT.HANDBOOK_LIST_BG ,100, 317.5,{ap = display.CENTER})
    leftLayout:addChild(lefeImage,0)
    local moduleName = display.newLabel(100, 615.5 , {fontSize = 20,text = __('我要变强'),color = '#875139',ap = display.CENTER})
    leftLayout:addChild(moduleName,0)
    local centerLayout = display.newLayer(display.cx + 93, display.cy  + -44 ,{ap = display.CENTER,size = cc.size(1032,665)})
    self:addChild(centerLayout,0)
    local centerImage = display.newImageView( RES_DICT.HANDBOOK_BOOK_BG ,516, 328.5,{ap = display.CENTER})
    centerLayout:addChild(centerImage,0)
    local centerLeftImage = display.newImageView( RES_DICT.HANDBOOK_BOOK_BG_HEAD , 205, 607.5,{ap = display.CENTER  } )
    centerLayout:addChild(centerLeftImage,0)
    local descrLabel = display.newLabel(164.5, 39 , {outline = "#422428",fontSize = 24,ttf = true,font = TTF_GAME_FONT,text = '' , color = '#f1e5c7',ap = display.CENTER})
    centerLeftImage:addChild(descrLabel,10)
    local cScrollView = CGridView:create(cc.size(841, 457))
    cScrollView:setSizeOfCell(cc.size(841 , 147 ))
    cScrollView:setColumns(1)
    cScrollView:setAutoRelocate(true)
    cScrollView:setAnchorPoint(display.CENTER)
    cScrollView:setPosition(516 , 305.5)
    centerLayout:addChild(cScrollView,0)
    self.viewData = {
        swallpwLayer              = swallpwLayer,
        bgImage                   = bgImage,
        topLayer                  = topLayer,
        backBtn                   = backBtn,
        tabLabelName              = tabLabelName,
        tipImage                  = tipImage,
        leftLayout                = leftLayout,
        lScrollView               = lScrollView,
        lefeImage                 = lefeImage,
        moduleName                = moduleName,
        centerLayout              = centerLayout,
        centerImage               = centerImage,
        centerLeftImage           = centerLeftImage,
        descrLabel                = descrLabel,
        cScrollView               = cScrollView
    }
end
--[[
    创建左侧的leftCell

--]]
function SunFlowerBibleView:CreateLeftCellLayout()
    local leftCellLayout = display.newLayer(96, 513.5, { ap = display.CENTER, size = cc.size(152, 125), color = cc.c4b(0, 0, 0, 0), enable = true })
    local selectImage = display.newImageView(RES_DICT.HANDBOOK_LIST_BG_LIGHT, 76, 62.5, { ap = display.CENTER })
    leftCellLayout:addChild(selectImage, 0)
    selectImage:setVisible(false)
    local iconImage = display.newImageView(RES_DICT.HANDBOOK_LIST_ICO_1, 76, 75, { ap = display.CENTER })
    leftCellLayout:addChild(iconImage, 0)
    local iconName = display.newLabel(76, 26.5, fontWithColor(14, {fontSize = 22, text = "", ap = display.CENTER  , w = 115 , hAlign = display.TAC}))
    leftCellLayout:addChild(iconName, 0)
    leftCellLayout.viewData = {
        leftCellLayout  = leftCellLayout,
        selectImage = selectImage,
        iconImage   = iconImage,
        iconName    = iconName,
    }
    return leftCellLayout
end
--[[
    创建中部的cell
--]]
function SunFlowerBibleView:CreateCenterCellLayout()
    local gridSize = cc.size(841,147)
    local gridCell = CGridViewCell:new()
    gridCell:setContentSize(gridSize)
    local cellLayout = display.newLayer(gridSize.width/2, gridSize.height/2,{ap = display.CENTER,size = gridSize , enable = true})
    gridCell:addChild(cellLayout)
    local cellBgImage = display.newImageView( RES_DICT.HANDBOOK_BOOK_BG_LIST ,415.5, 73.5,{ap = display.CENTER})

    cellLayout:addChild(cellBgImage,0)
    local descrLabel = display.newLabel(34, 60.5 , {fontSize = 20,w = 380,  text = "",color = '#875139',ap = display.LEFT_CENTER})
    cellLayout:addChild(descrLabel,0)
    local goodNode = require("common.GoodNode").new({goodsId = DIAMOND_ID})
    goodNode:setPosition(490.5, 73.5)

    cellLayout:addChild(goodNode )
    local goodsName = display.newButton(13.5, 118.5 , {n = RES_DICT.HANDBOOK_BOOK_BG_LIST_HEAD,ap = display.LEFT_CENTER,scale9 = true,size = cc.size(200,41)})
    cellLayout:addChild(goodsName,0)
    display.commonLabelParams(goodsName ,{offset = cc.p(-85, 0 ),  outline ="#39230",fontSize = 24,ttf = true,font = TTF_GAME_FONT,outlineSize = 1,text = '',color = '#FFF1BB'})
    goodsName:getLabel():setAnchorPoint(display.LEFT_CENTER)
    local rewardBtn = display.newButton(635, 72.5 , {n = RES_DICT.COMMON_BTN_BIG_ORANGE,ap = display.LEFT_CENTER,scale9 = true,size = cc.size(148,71)})
    cellLayout:addChild(rewardBtn,0)
    display.commonLabelParams(rewardBtn ,fontWithColor(14 , {fontSize = 24,ttf = true,font = TTF_GAME_FONT,outlineSize = 1,text = __('获取'),color = '#ffffff',paddingW  = 20,safeW = 108}))
    gridCell.viewData = {
        cellLayout  = cellLayout,
        cellBgImage = cellBgImage,
        descrLabel = descrLabel,
        goodsName   = goodsName,
        goodNode    = goodNode ,
        rewardBtn   = rewardBtn,
    }
    return gridCell
end

function SunFlowerBibleView:UpdateCenterCellLayout(cell)
    local viewData = cell.viewData
    local rewardBtn = viewData.rewardBtn
    local id = rewardBtn:getTag()
    local strongerOneConf = CONF.SUN_FLOWR.STRONGER:GetValue(id)
    local goodsId = strongerOneConf.goodsId
    if checkint(goodsId) == 0 then return end

    local goodOneConf = CommonUtils.GetConfig('goods' , 'goods', goodsId)
    local name = goodOneConf.name
    local descr = goodOneConf.descr
    display.commonLabelParams(viewData.goodsName , { text = name ,hAligh = display.TAC})
    display.commonLabelParams(viewData.descrLabel , {text = descr})
    viewData.goodNode:RefreshSelf({goodsId = goodsId })
end
function SunFlowerBibleView:UpdateLeftCell(cell , type)
    local strongerTypeConf = CONF.SUN_FLOWR.STRONGER_TYPE:GetValue(type)
    local name = strongerTypeConf.name
    local texturePath = _res(string.format("ui/home/sunflower/handbook_list_ico_%d", checkint(type)) )
    local viewData = cell.viewData
    viewData.iconImage:setTexture(texturePath)
    display.commonLabelParams(viewData.iconName , {text = name })
end

function SunFlowerBibleView:UpdateView(type)
    local strongerTypeConf = CONF.SUN_FLOWR.STRONGER_TYPE:GetValue(type)
    local descrText = strongerTypeConf.descr
    local viewData = self.viewData
    display.commonLabelParams(viewData.descrLabel , {text = descrText})
    viewData.cScrollView:reloadData()
    local listNodes = viewData.lScrollView:getNodes()
    local nodeType = checkint(type)
    for i = 1,#listNodes do
        local node = listNodes[i]
        local viewData = node.viewData
        viewData.selectImage:setVisible(node:getTag() == nodeType)
    end
end

function SunFlowerBibleView:onCleanup()

end

return SunFlowerBibleView
