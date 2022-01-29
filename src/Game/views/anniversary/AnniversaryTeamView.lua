---@class  AnniversaryTeamView
local AnniversaryTeamView = class('common.AnniversaryTeamView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.anniversary.AnniversaryTeamView'
    node:enableNodeEvents()
    return node
end)
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local newImageView = display.newImageView
local newLabel = display.newLabel
local newNSprite = display.newNSprite
local newButton = display.newButton
local newLayer = display.newLayer
local ANNIVERSAY_SPINE_TABLE   = {
    ANNI_MAIN_CHANGE =  app.anniversaryMgr:GetSpinePath('effects/anniversary/anni_main_change').path
}
local RES_DICT = {
    ANNI_MAIN_LABEL_TITLE         = app.anniversaryMgr:GetResPath('ui/anniversary/main/anni_main_label_title.png'),
    TEMP_ANIME_CHANGE             = app.anniversaryMgr:GetResPath('ui/anniversary/temp_anime_change.png'),
    ANNI_TASK_BG_CARD_SUB         = app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_bg_card_sub.png'),
    ANNI_TASK_LINE_1              = app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_line_1.png'),
    ANNI_TASK_LABEL_GRADE         = app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_label_grade.png'),
    ANNI_TASK_BTN_ARROW_LOCK      = app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_btn_arrow_lock.png'),
    ANNI_MAIN_BTN_SUBTASK         = app.anniversaryMgr:GetResPath('ui/anniversary/main/anni_main_btn_subtask.png'),
    ANNI_TASK_BG_DETAIL           = app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_bg_detail.png'),
    ANNI_MAIN_BTN_MAINTASK_FRAME  = app.anniversaryMgr:GetResPath('ui/anniversary/main/anni_main_btn_maintask_frame.png'),
    ANNI_TASK_BG_CARD_MAIN        = app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_bg_card_main.png'),
    ANNI_MAIN_BTN_MAINTASK_UNDER  = app.anniversaryMgr:GetResPath('ui/anniversary/main/anni_main_btn_maintask_under.png'),
    ANNI_TASK_ICO_STAR            = app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_ico_star.png'),
    COMMON_BTN_BACK               = app.anniversaryMgr:GetResPath('ui/common/common_btn_back.png'),
    ANNI_TASK_LINE_2              = app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_line_2.png'),
    ANNI_TASK_ICO_AREA_5          = app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_ico_area_5.png'),
    ANNI_TASK_BTN_ARROW_ACTIVE    = app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_btn_arrow_active.png'),
    ANNI_TASK_LABEL_CHANGE        = app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_label_change.png'),
    COMMON_BTN_TIPS               = app.anniversaryMgr:GetResPath('ui/common/common_btn_tips.png'),
    COMMON_BTN_GREEN              = app.anniversaryMgr:GetResPath('ui/common/common_btn_green.png'),
}

function AnniversaryTeamView:ctor()

    local view = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size})
    local swallowLayer = newLayer(display.cx , display.cy ,
                                  { ap = display.CENTER, color = cc.c4b(0 , 0,0,175), size = display.size , enable = true })
    --swallowLayer:setPosition(display.cx + 0, display.cy + 0)
    view:addChild(swallowLayer)

    self:addChild(view)
    local rightLayout = newLayer(864, 408,
                                 { ap = display.CENTER, size = cc.size(562, 420), enable = true })
    rightLayout:setPosition(display.cx + 197, display.cy + 33)
    view:addChild(rightLayout)

    local goodNodeLayout = display.newLayer(30 , 70  , {size = cc.size(750  , 120 ) })
    rightLayout:addChild(goodNodeLayout,2 )
    local detailBgImage = newNSprite(RES_DICT.ANNI_TASK_BG_DETAIL, 281, 210,
                                     { ap = display.CENTER, tag = 79 })
    detailBgImage:setScale(1, 1)
    rightLayout:addChild(detailBgImage)

    local descrLabel = newLabel(28, 378,
                                { ap = display.LEFT_CENTER, color = '#ffd3a7', text = app.anniversaryMgr:GetPoText(__('描述')), fontSize = 20, tag = 81 })
    rightLayout:addChild(descrLabel)

    local passLabel = newLabel(28, 205,
                               { ap = display.LEFT_CENTER, color = '#ffd3a7', text = app.anniversaryMgr:GetPoText(__('过关奖励')), fontSize = 20, tag = 88 })
    rightLayout:addChild(passLabel)


    local sweepBtn = display.newButton(  32, 50,{ap = display.LEFT_CENTER , n = RES_DICT.COMMON_BTN_GREEN, scale9 = true  } )
    display.commonLabelParams(sweepBtn , fontWithColor(14 , {text = app.anniversaryMgr:GetPoText(__('快速挑战')) , paddingW =  20 }))
    rightLayout:addChild(sweepBtn)
    sweepBtn:setVisible(false)


    local lineImageOne = newNSprite(RES_DICT.ANNI_TASK_LINE_2, 247, 363,
                                    { ap = display.CENTER, tag = 80 })
    lineImageOne:setScale(1, 1)
    rightLayout:addChild(lineImageOne)

    local lineImageTwo = newNSprite(RES_DICT.ANNI_TASK_LINE_2, 247, 190,
                                    { ap = display.CENTER, tag = 90 })
    lineImageTwo:setScale(1, 1)
    rightLayout:addChild(lineImageTwo)

    local passDescrLabel = newLabel(37, 352,
                                    { ap = display.LEFT_TOP, color = '#ffffff', text = '', fontSize = 20, tag = 92 })
    rightLayout:addChild(passDescrLabel)

    local backBtn = newButton(59, 695, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_BACK, d = RES_DICT.COMMON_BTN_BACK, s = RES_DICT.COMMON_BTN_BACK, scale9 = true, size = cc.size(90, 70), tag = 115 , cb = function()
        self:removeFromParent()
    end })
    display.commonLabelParams(backBtn, {text = "", fontSize = 14, color = '#414146'})
    backBtn:setPosition(display.SAFE_L + 59, display.height + -55)
    view:addChild(backBtn)
    local topLayoutSize = cc.size(display.width, 80)
    local moneyNodeLayout = CLayout:create(topLayoutSize)
    moneyNodeLayout:setName('TOP_LAYOUT')
    display.commonUIParams(moneyNodeLayout, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
    self:addChild(moneyNodeLayout, GameSceneTag.Dialog_GameSceneTag)

    -- top icon
    local imageImage = display.newImageView(app.anniversaryMgr:GetResPath('ui/home/nmain/main_bg_money.png'),0, 0, {enable = false,
                                                                                           scale9 = true, size = cc.size(680 + (display.width - display.SAFE_R), 54)})
    display.commonUIParams(imageImage,{ap = cc.p(1.0,1.0), po = cc.p(display.width,80)})
    moneyNodeLayout:addChild(imageImage)

    local moneyNods = {}
    local iconData = {app.anniversaryMgr:GetIncomeCurrencyID(), app.anniversaryMgr:GetAnniversaryTicketID(),DIAMOND_ID}
    for i,v in ipairs(iconData) do
        local purchaseNode = GoodPurchaseNode.new({id = v})
        purchaseNode:updataUi(checkint(v))
        display.commonUIParams(purchaseNode,
                               {ap = cc.p(1, 0.5), po = cc.p(topLayoutSize.width - 30 - (( 3 - i) * (purchaseNode:getContentSize().width + 16)), imageImage:getPositionY()- 26)})
        moneyNodeLayout:addChild(purchaseNode, 5)
        purchaseNode:setName('purchaseNode' .. i)
        purchaseNode.viewData.touchBg:setTag(checkint(v))
        moneyNods[tostring( v )] = purchaseNode
    end



    self.viewData =  {
        swallowLayer            = swallowLayer,
        rightLayout             = rightLayout,
        detailBgImage           = detailBgImage,
        descrLabel              = descrLabel,
        passLabel               = passLabel,
        lineImageOne            = lineImageOne,
        lineImageTwo            = lineImageTwo,
        passDescrLabel          = passDescrLabel,
        moneyNods               = moneyNods ,
        sweepBtn               = sweepBtn ,
        backBtn                 = backBtn,
        view                    = view ,
        goodNodeLayout         = goodNodeLayout ,
    }
end

function AnniversaryTeamView:CreateMainQuestLayout()
    local view = self.viewData.view
    local mainLineLayout = newLayer(373, 408,
                                    { ap = display.CENTER, size = cc.size(379, 500) })
    mainLineLayout:setPosition(display.cx + -294, display.cy + 33)
    view:addChild(mainLineLayout)
    mainLineLayout:setName("mainLineLayout")
    local areaBgImage = newNSprite(RES_DICT.ANNI_TASK_BG_CARD_MAIN, 189, 250,
                                     { ap = display.CENTER, tag = 98 })
    areaBgImage:setScale(1, 1)
    mainLineLayout:addChild(areaBgImage)

    local headLayout = newLayer(193, 475,
                                { ap = display.CENTER,  size = cc.size(200, 200) })
        mainLineLayout:addChild(headLayout)

    local underImage = newImageView(RES_DICT.ANNI_MAIN_BTN_MAINTASK_UNDER, 97, 104,
                                    { ap = display.CENTER, tag = 119, enable = false })
    headLayout:addChild(underImage)

    local taskFrameImage = newImageView(RES_DICT.ANNI_MAIN_BTN_MAINTASK_FRAME, 97, 98,
                                        { ap = display.CENTER, tag = 118, enable = false })
    headLayout:addChild(taskFrameImage)

    --local headImage = newImageView(RES_DICT.ANNI_MAIN_BTN_SUBTASK, 97, 99,
    --                               { ap = display.CENTER, tag = 120, enable = false })
    --headLayout:addChild(headImage)
    local  clipNodeTable =  self:CreateClipNode()
    clipNodeTable.parentLayout:setPosition( 100, 107 )
    headLayout:addChild(clipNodeTable.parentLayout)

    local lineImage = newNSprite(RES_DICT.ANNI_TASK_LINE_1, 189, 117,
                                   { ap = display.CENTER, tag = 99 })
    lineImage:setScale(1, 1)
    mainLineLayout:addChild(lineImage)

    local areaTitle = newNSprite(RES_DICT.ANNI_MAIN_LABEL_TITLE, 189, 391,
                                   { ap = display.CENTER, tag = 100 })
    areaTitle:setScale(1, 1)
    mainLineLayout:addChild(areaTitle)

    local areaLabel = newLabel(159, 73,
                                 fontWithColor('14', { ap = display.CENTER, outline = '#591f1f' , outlineSize= 2, ttf = true, font = TTF_GAME_FONT, color = '#ffffff', fontSize = 24, text = "", tag = 101 }))
    areaTitle:addChild(areaLabel)

    local areaImage = newNSprite(RES_DICT.ANNI_TASK_ICO_AREA_5, 192, 222,
                                   { ap = display.CENTER, tag = 102 })
    areaImage:setScale(1, 1)
    mainLineLayout:addChild(areaImage)

    local changeLabel = newLabel(188, 87,
                                   { ap = display.CENTER, color = '#926341', text = app.anniversaryMgr:GetPoText(__('主线故事')), fontSize = 24, tag = 106 })
    mainLineLayout:addChild(changeLabel)

    local starLayout = newLayer(160, 332,
                                  { ap = display.LEFT_BOTTOM, color = cc.r4b(0), size = cc.size(52, 24), enable = true })
    mainLineLayout:addChild(starLayout)
    starLayout:setVisible(false)
    local starOne = newImageView(RES_DICT.ANNI_TASK_ICO_STAR, 13, 12,
                                   { ap = display.CENTER, tag = 108, enable = false })
    starLayout:addChild(starOne)

    local starTwo = newImageView(RES_DICT.ANNI_TASK_ICO_STAR, 39, 12,
                                   { ap = display.CENTER, tag = 109, enable = false })
    starLayout:addChild(starTwo)
    local tipBtn = newButton(310, 140, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_TIPS, s = RES_DICT.COMMON_BTN_TIPS })
    display.commonLabelParams(tipBtn, {text = "", fontSize = 14, color = '#414146'})
    mainLineLayout:addChild(tipBtn)

    mainLineLayout.viewData = {
        mainLineLayout = mainLineLayout,
        areaBgImage    = areaBgImage,
        lineImage      = lineImage,
        areaTitle      = areaTitle,
        areaLabel      = areaLabel,
        areaImage      = areaImage,
        changeLabel    = changeLabel,
        starLayout     = starLayout,
        starOne        = starOne,
        starTwo        = starTwo,
        headLayout     = headLayout,
        tipBtn         = tipBtn ,
        taskFrameImage = taskFrameImage,
        headIcon       = clipNodeTable.headIcon ,
    }
    return  mainLineLayout
end
function AnniversaryTeamView:CreateBranchLayout()
    local view = self.viewData.view
    local branchPanel = newLayer(369, 408,
                                 { ap = display.CENTER, size = cc.size(379, 500) })
    branchPanel:setPosition(display.cx + -298, display.cy + 33)
    view:addChild(branchPanel)
    branchPanel:setName("branchPanel")
    local areaBgImage = newNSprite(RES_DICT.ANNI_TASK_BG_CARD_SUB, 189, 250,
                                   { ap = display.CENTER, tag = 76 })
    areaBgImage:setScale(1, 1)
    branchPanel:addChild(areaBgImage)

    local lineImage = newNSprite(RES_DICT.ANNI_TASK_LINE_1, 189, 117,
                                 { ap = display.CENTER, tag = 67 })
    lineImage:setScale(1, 1)
    branchPanel:addChild(lineImage)

    local areaTitle = newNSprite(RES_DICT.ANNI_MAIN_LABEL_TITLE, 189, 391,
                                 { ap = display.CENTER, tag = 68 })
    areaTitle:setScale(1, 1)
    branchPanel:addChild(areaTitle)

    local areaLabel = newLabel(159, 73,
                               fontWithColor('14',  { outline = "#591f1f" ,outlineSize = 2,  ap = display.CENTER,  ttf = true, font = TTF_GAME_FONT, color = '#ffffff', fontSize = 24, text = "", tag = 69 }))
    areaTitle:addChild(areaLabel)

    local starLayout = newLayer(170, 322,
                                { ap = display.LEFT_BOTTOM, color = cc.r4b(0), size = cc.size(52, 24), enable = true })
    branchPanel:addChild(starLayout)
    starLayout:setVisible(false)
    local starOne = newImageView(RES_DICT.ANNI_TASK_ICO_STAR, 13, 12,
                                 { ap = display.CENTER, tag = 112, enable = false })
    starLayout:addChild(starOne)

    local starTwo = newImageView(RES_DICT.ANNI_TASK_ICO_STAR, 39, 12,
                                 { ap = display.CENTER, tag = 113, enable = false })
    starLayout:addChild(starTwo)

    local areaImage = newNSprite(RES_DICT.ANNI_TASK_ICO_AREA_5, 192, 222,
                                 { ap = display.CENTER, tag = 70 })
    areaImage:setScale(1, 1)
    branchPanel:addChild(areaImage)

    local diffcultBtn = newButton(189, 69, { ap = display.CENTER ,  n = RES_DICT.ANNI_TASK_LABEL_GRADE, d = RES_DICT.ANNI_TASK_LABEL_GRADE, s = RES_DICT.ANNI_TASK_LABEL_GRADE, scale9 = true, size = cc.size(202, 44), tag = 72 })
    display.commonLabelParams(diffcultBtn, fontWithColor(14, { text = app.anniversaryMgr:GetPoText(__('难度')), fontSize = 24, color = '#6f4229' , outline = false }))
    branchPanel:addChild(diffcultBtn)

    local leftBtn = newButton(60, 69, { ap = display.CENTER ,  n = RES_DICT.ANNI_TASK_BTN_ARROW_ACTIVE, d = RES_DICT.ANNI_TASK_BTN_ARROW_LOCK, s = RES_DICT.ANNI_TASK_BTN_ARROW_ACTIVE, scale9 = true, size = cc.size(80, 80), tag = 74 })
    display.commonLabelParams(leftBtn, {text = "", fontSize = 24, color = '#414146'})
    branchPanel:addChild(leftBtn)

    local rightBtn = newButton(318, 69, { ap = display.CENTER ,  n = RES_DICT.ANNI_TASK_BTN_ARROW_ACTIVE, d = RES_DICT.ANNI_TASK_BTN_ARROW_LOCK, s = RES_DICT.ANNI_TASK_BTN_ARROW_ACTIVE, scale9 = true, size = cc.size(80, 80), tag = 75 })
    display.commonLabelParams(rightBtn, {text = "", fontSize = 24, color = '#414146'})
    branchPanel:addChild(rightBtn)
    rightBtn:setScaleX(-1)

    local changeLabel = newLabel(189, 104,
                                 { ap = display.CENTER, color = '#926341', text = app.anniversaryMgr:GetPoText(__('更改难度')), fontSize = 20, tag = 77 })
    branchPanel:addChild(changeLabel)

    local branchrefreshLayout = newLayer(1169, 446,
                                         { ap = display.CENTER, size = cc.size(200, 200) , color = cc.c4b(0,0,0,0) ,enable = true  } )
    branchrefreshLayout:setPosition(display.cx + 502, display.cy + 71)
    view:addChild(branchrefreshLayout)
    local shareSpineCache = SpineCache(SpineCacheName.ANNIVERSARY)
    local refreshCardSpine =  shareSpineCache:createWithName(app.anniversaryMgr.spineTable.ANNI_MAIN_CHANGE)
    branchrefreshLayout:addChild(refreshCardSpine,2)
    refreshCardSpine:setPosition(100,15)
    refreshCardSpine:setVisible(false)
    refreshCardSpine:setAnimation(0,'anni_main_change_4',true )
    local changeNextLabel = newLabel(100, -15,
                                     fontWithColor(14, { ap = display.CENTER, color = '#ffffff', text = app.anniversaryMgr:GetPoText(__('换一个')), fontSize = 24, tag = 96 }))
    branchrefreshLayout:addChild(changeNextLabel,2)

    local labelChange = newImageView(RES_DICT.ANNI_TASK_LABEL_CHANGE ,100 , -50  )
    branchrefreshLayout:addChild(labelChange)

    local comsumeRichLabel = display.newRichLabel(100 , -50  , { r = true ,
        c = {
            fontWithColor(10 ,{ color = "ffffff" ,fontSize = 24 ,   text = string.format(app.anniversaryMgr:GetPoText(__('消耗%d')) , 10) }),
            {img = CommonUtils.GetGoodsIconPathById(GOLD_ID)  , scale = 0.2}
        }
    })
    branchrefreshLayout:addChild(comsumeRichLabel)
    local tipBtn = newButton(310, 140, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_TIPS, s = RES_DICT.COMMON_BTN_TIPS })
    display.commonLabelParams(tipBtn, {text = "", fontSize = 14, color = '#414146'})
    branchPanel:addChild(tipBtn)
    branchPanel.viewData = {
        branchPanel             = branchPanel,
        areaBgImage             = areaBgImage,
        lineImage               = lineImage,
        areaTitle               = areaTitle,
        areaLabel               = areaLabel,
        starLayout              = starLayout,
        starOne                 = starOne,
        starTwo                 = starTwo,
        areaImage               = areaImage,
        diffcultBtn             = diffcultBtn,
        leftBtn                 = leftBtn,
        tipBtn                  = tipBtn ,
        rightBtn                = rightBtn,
        changeLabel             = changeLabel,
        comsumeRichLabel        = comsumeRichLabel ,
        branchrefreshLayout     = branchrefreshLayout,
        refreshCardSpine             = refreshCardSpine,
        changeNextLabel         = changeNextLabel,
    }
    return branchPanel
end
function AnniversaryTeamView:CreateClipNode()
    local size = cc.size(120,120)
    local parentLayout =  CLayout:create(size)
    --parentLayout:setPosition(size.width/2 , size.height/2)
    local eventNode = CLayout:create(size)
    eventNode:setCascadeOpacityEnabled(true)
    eventNode:setPosition(utils.getLocalCenter(parentLayout))
    parentLayout:addChild(eventNode)
    -- 裁剪节点
    local sceneClipNode = cc.ClippingNode:create()
    sceneClipNode:setCascadeOpacityEnabled(true)
    sceneClipNode:setContentSize(size)
    sceneClipNode:setAnchorPoint(cc.p(0.5, 0.5))
    sceneClipNode:setPosition(utils.getLocalCenter(eventNode))
    eventNode:addChild(sceneClipNode, 3)
    local stencilLayer = display.newLayer(0, 0, {  size = size})
    stencilLayer:setCascadeOpacityEnabled(true)
    sceneClipNode:setInverted(false)
    sceneClipNode:setAlphaThreshold(0.1)
    sceneClipNode:setStencil(stencilLayer)
    local mask = display.newImageView(app.anniversaryMgr:GetResPath('ui/home/handbook/pokedex_card_bg_skin_head_unlock.png'), size.width/2, size.height/2 - 8)
    stencilLayer:addChild(mask)
    -- 头像
    local headIcon = display.newImageView( AssetsUtils.GetCardHeadPath(200002), size.width/2, size.height/2 -8)
    headIcon:setScale(0.6)
    sceneClipNode:addChild(headIcon, 10)
    return {
        eventNode = eventNode ,
        headIcon = headIcon ,
        parentLayout = parentLayout ,
    }
end
--[[
    刷新顶部的UI
--]]
function AnniversaryTeamView:UpdateCountUI()
    if self.viewData and  self.viewData.moneyNods then
        for k ,v in pairs(self.viewData.moneyNods or {})do
            v:updataUi(checkint(k))
        end
    end
end
return  AnniversaryTeamView