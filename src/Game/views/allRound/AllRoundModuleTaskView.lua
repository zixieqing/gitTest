---@class AllRoundModuleTaskView
local AllRoundModuleTaskView = class('AllRoundModuleTaskView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.allRound.AllRoundModuleTaskView'
    node:enableNodeEvents()
    return node
end)
local newImageView = display.newImageView
local newLabel = display.newLabel
local newNSprite = display.newNSprite
local newButton = display.newButton
local newLayer = display.newLayer
local RES_DICT = {
    COMMON_BTN_ORANGE           = _res('ui/common/common_btn_orange.png'),
    ALLROUND_BG_SIDEBAR_LINE    = _res('ui/home/allround/allround_bg_sidebar_line.png'),
    ALLROUND_ICO_BOOK_3         = _res('ui/home/allround/allround_ico_book_3.png'),
    TASK_BG                     = _res('ui/home/story/task_bg.png'),
    ALLROUND_LABEL_PATH_NAME    = _res('ui/home/allround/allround_label_path_name.png'),
    ALLROUND_BG_LIST_LINE       = _res('ui/home/allround/allround_bg_list_line.png'),
    ALLROUND_BG_SIDEBAR         = _res('ui/home/allround/allround_bg_sidebar.png'),
    ALLROUND_ICO_STAR_FULL      = _res('ui/home/allround/allround_ico_star_full.png'),
    ALLROUND_BG_LIST_TOP        = _res('ui/home/allround/allround_bg_list_top.png'),
    ALLROUND_ICO_COMPLETED      = _res('ui/home/allround/allround_ico_completed.png'),
    FUNCTION_16                 = _res('ui/home/levelupgrade/unlockmodule/function_16.png'),
    ALLROUND_BG_LIST_COVER      = _res('ui/home/allround/allround_bg_list_cover.png'),
    ALLROUND_BG_LIST_UNDER      = _res('ui/home/allround/allround_bg_list_under.png'),
    ALLROUND_BG_BAR_2_ACTIVE    = _res('ui/home/allround/allround_bg_bar_2_active.png'),
    ALLROUND_BG_BAR_2_GREY      = _res('ui/home/allround/allround_bg_bar_2_grey.png'),
    ALLROUND_BG_BOOK_COVER_UP   = _res('ui/home/allround/allround_bg_book_cover_up.png'),
    ALLROUND_BG_BOOK_COVER_DOWN = _res('ui/home/allround/allround_bg_book_cover_down.png'),
    CARD_SKILL_BTN_SWITCH       = _res('ui/home/cardslistNew/card_skill_btn_switch.png'),
}

function AllRoundModuleTaskView:ctor( param )
    self:InitUI()
end
function AllRoundModuleTaskView:InitUI()
    local view = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size})
    self:addChild(view)
    local closeLayout = display.newLayer(display.cx , display.cy ,{ap = display.CENTER, color = cc.c4b(0,0,0,175) , enable = true , size = display.size  })
    view:addChild(closeLayout)
    local leftLayout = newLayer(78, 359,
                                { ap = display.CENTER, size = cc.size(167, 637), enable = true })
    leftLayout:setPosition(display.cx + -550, display.cy + -16)
    view:addChild(leftLayout)

    local bgImage = newImageView(RES_DICT.ALLROUND_BG_SIDEBAR, 167/2, 637/2,
                                 { ap = display.CENTER, tag = 886, enable = false })
    leftLayout:addChild(bgImage)

    local lineImage = newImageView(RES_DICT.ALLROUND_BG_SIDEBAR_LINE, 79, 590,
                                   { ap = display.CENTER, tag = 885, enable = false })
    leftLayout:addChild(lineImage)

    local wantGoLabel = newLabel(87, 593,
                                 { ap = display.CENTER_BOTTOM, color = '#ffddb4', text = __('猜你想去：'), w = 160,hAlign = display.TAC, fontSize = 20, tag = 880 })
    wantGoLabel:setPosition(87, 593)
    leftLayout:addChild(wantGoLabel)
    local centerSize = cc.size(980, 630)
    local centerLayout = newLayer(723, 362,
                                  { ap = display.CENTER, size = cc.size(980, 630), enable = true })
    centerLayout:setPosition(display.cx + 56, display.cy + -13)
    view:addChild(centerLayout)

    local  underImage = display.newImageView(RES_DICT.ALLROUND_BG_BOOK_COVER_DOWN , centerSize.width /2-2 ,-5, {
        ap = display.CENTER_BOTTOM
    } )
    centerLayout:addChild(underImage,10 )



    local bgImage_1 = newImageView(RES_DICT.TASK_BG, 488, 313,
                                   { ap = display.CENTER, tag = 910, enable = false })
    centerLayout:addChild(bgImage_1)
    local topListImage = display.newImageView(RES_DICT.ALLROUND_BG_BOOK_COVER_UP ,centerSize.width/2 , centerSize.height, {
        ap = display.CENTER_TOP
    })
    centerLayout:addChild(topListImage,2)
    local topLayout = newLayer(-30, 568,
                               { ap = display.LEFT_BOTTOM, size = cc.size(100, 100) })
    centerLayout:addChild(topLayout,2)

    local moduleTitle = newImageView(RES_DICT.ALLROUND_LABEL_PATH_NAME, 180, 58,
                                     { ap = display.CENTER, tag = 890, enable = false })
    topLayout:addChild(moduleTitle)

    local moduleImage = newImageView(RES_DICT.ALLROUND_ICO_BOOK_3, 46, 55,
                                     { ap = display.CENTER, tag = 889, scale = 0.63, enable = false })
    topLayout:addChild(moduleImage)

    local moduleName = newLabel(99, 59,
                                fontWithColor('14', { ap = display.LEFT_CENTER, outline = false, ttf = true, font = TTF_GAME_FONT, color = '#ffffff', fontSize = 24, text = "", tag = 891 }))
    topLayout:addChild(moduleName)
    local tableView = CTableView:create(cc.size(883,562) )
    tableView:setName('gridView')
    tableView:setSizeOfCell(cc.size(870, 140))
    tableView:setAutoRelocate(true)
    tableView:setDirection(eScrollViewDirectionVertical)
    centerLayout:addChild(tableView,1)
    tableView:setAnchorPoint(display.LEFT_BOTTOM)
    tableView:setPosition(53, 32 )
    self.viewData =  {
        leftLayout              = leftLayout,
        bgImage                 = bgImage,
        lineImage               = lineImage,
        wantGoLabel             = wantGoLabel,
        centerLayout            = centerLayout,
        bgImage_1               = bgImage_1,
        topLayout               = topLayout,
        moduleTitle             = moduleTitle,
        moduleImage             = moduleImage,
        moduleName              = moduleName,
        tableView               = tableView,
        closeLayout             = closeLayout ,
    }
end
function AllRoundModuleTaskView:CreateListCell()
    local listCell = newLayer(103, 336,
                              { ap = display.CENTER , size = cc.size(870, 140) })
    local underCellImage = newImageView(RES_DICT.ALLROUND_BG_LIST_UNDER, 439, 70,
                                        { ap = display.CENTER, tag = 893, enable = false })
    listCell:addChild(underCellImage)


    local gotoImage = display.newImageView(RES_DICT.CARD_SKILL_BTN_SWITCH , 820, 68)
    gotoImage:setScale(-0.8)

    local lineImage_1 = newImageView(RES_DICT.ALLROUND_BG_LIST_LINE, 241, 100,
                                     { ap = display.CENTER, tag = 896, enable = false })
    listCell:addChild(lineImage_1)
    local starWidth = 30
    local starPos = {
        cc.p(78, 113) ,
        cc.p(78 + starWidth * 1, 113) ,
        cc.p(78 + starWidth * 2, 113) ,
        cc.p(78 + starWidth * 3, 113) ,
        cc.p(78 + starWidth * 4, 113)
    }
    local starTable = {
    }
    for i, v in ipairs(starPos) do
        local star =  newImageView(RES_DICT.ALLROUND_ICO_STAR_FULL, starPos[i].x , starPos[i].y ,
                                   { ap = display.CENTER, tag = 897, enable = false })
        listCell:addChild(star)
        starTable[#starTable+1] = star
    end
    local completeConditions = newLabel(68, 95,
                                        { ap = display.LEFT_TOP, color = '#906866', text = "", fontSize = 20, tag = 902 })
    listCell:addChild(completeConditions)

    local rewardLabel = newLabel(446, 111,
                                 { ap = display.LEFT_CENTER, color = '#9b4848', text = __('奖励：'), fontSize = 20, tag = 903 })
    rewardLabel:setPosition(446, 111)
    listCell:addChild(rewardLabel)

    local rewardLayout = newLayer(441, 18,
                                  { ap = display.LEFT_BOTTOM,  size = cc.size(260, 80), enable = true })
    listCell:addChild(rewardLayout)

    local rewardBtn = newButton(780, 68, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_ORANGE, d = RES_DICT.COMMON_BTN_ORANGE, s = RES_DICT.COMMON_BTN_ORANGE, tag = 905 ,enable = true  })
    display.commonLabelParams(rewardBtn, fontWithColor(14, { text = __('领取'), fontSize = 20, color = '#ffffff' }))
    rewardBtn:setPosition(780, 68)
    listCell:addChild(rewardBtn)

    local barImage = newNSprite(RES_DICT.ALLROUND_BG_BAR_2_GREY, 200, 29,
                                { ap = display.CENTER, tag = 912 })
    barImage:setScale(1, 1)
    listCell:addChild(barImage)

    local prograssImage = CProgressBar:create(RES_DICT.ALLROUND_BG_BAR_2_ACTIVE)
    prograssImage:setAnchorPoint(cc.p(0.5, 0.5))
    prograssImage:setMaxValue(100)
    prograssImage:setValue(0)
    prograssImage:setScale(1, 1)
    prograssImage:setPosition(200, 29)
    prograssImage:setDirection(eProgressBarDirectionLeftToRight)
    listCell:addChild(prograssImage)

    local prorassLabel = newLabel(170, 29,
                                  { ap = display.LEFT_CENTER, color = '#ffffff', text = "", fontSize = 20, tag = 914 })
    listCell:addChild(prorassLabel)

    local alreadyRewardImage = newImageView(RES_DICT.ALLROUND_BG_LIST_COVER, 439, 70,
                                            { ap = display.CENTER, tag = 906, enable = false })
    listCell:addChild(alreadyRewardImage)
    local alreadyLayout = newLayer(735, 23,
                                   { ap = display.LEFT_BOTTOM, color = cc.r4b(0), size = cc.size(100, 100), enable = true })
    alreadyLayout:setPosition(735, 23)
    alreadyRewardImage:addChild(alreadyLayout)

    local completeImage = newImageView(RES_DICT.ALLROUND_ICO_COMPLETED, 49, 49,
                                       { ap = display.CENTER, tag = 908, enable = false })
    alreadyLayout:addChild(completeImage)

    local completeLabel = newLabel(52, 6,
                                   fontWithColor('14', { ap = display.CENTER,ttf = true, font = TTF_GAME_FONT, color = '#ffffff', fontSize = 22, text = __('已完成'), tag = 909 }))
    alreadyLayout:addChild(completeLabel)
    listCell.viewData = {
        listCell                = listCell,
        underCellImage          = underCellImage,
        lineImage_1             = lineImage_1,
        completeConditions      = completeConditions,
        rewardLabel             = rewardLabel,
        rewardLayout            = rewardLayout,
        rewardBtn               = rewardBtn,
        barImage                = barImage,
        prograssImage           = prograssImage,
        prorassLabel            = prorassLabel,
        alreadyRewardImage      = alreadyRewardImage,
        alreadyLayout           = alreadyLayout,
        completeImage           = completeImage,
        completeLabel           = completeLabel,
        starTable               = starTable ,
    }
    return listCell
end
function AllRoundModuleTaskView:CreateFunctionLayout()
    local functionLayout = newLayer(4, 198,
                                    { ap = display.CENTER , size = cc.size(160, 140)})
    local functionImage = newImageView(RES_DICT.FUNCTION_16, 76, 74,
                                     { ap = display.CENTER, tag = 882 , enable = true  })
    functionImage:setScale(1, 1)
    functionLayout:addChild(functionImage)

    local functionLabel = newLabel(70, 18,
                                   fontWithColor('14', { ap = display.CENTER, outline = '#222323', ttf = true, font = TTF_GAME_FONT, color = '#ffffff', fontSize = 24, text = "", tag = 883 }))
    functionLayout:addChild(functionLabel)
    functionLayout.viewData = {
        functionLayout = functionLayout,
        functionImage  = functionImage,
        functionLabel  = functionLabel
    }
    return functionLayout
end

return AllRoundModuleTaskView