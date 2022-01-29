---
--- Created by xingweihao.
--- DateTime: 11/12/2017 3:32 PM
---
---@class SeasonLiveCell
local SeasonLiveCell = class('home.SeasonLiveCell', function()
    local pageviewcell = CTableViewCell:new()
    pageviewcell.name  = 'home.SeasonLiveCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)
local DESC_DICT      = {
    CARD_BG                 = _res('ui/home/activity/seasonlive/material_card_bg_back'),
    CARD_BG_CHOSEN          = _res('ui/home/activity/seasonlive/season_battle_card_bg_chosen_s'),
    CARD_BG_CHOSEN_TWO      = _res('ui/home/activity/seasonlive/season_battle_card_bg_chosen_l'),
    CARD_BG_MAIN            = _res('ui/home/activity/seasonlive/season_battle_bg_card_s'),
    CARD_BG_MAIN_TWO        = _res('ui/home/activity/seasonlive/season_battle_bg_card_l'),
    CARD_BG_SUB             = _res('ui/home/activity/seasonlive/season_battle_card_bg_sub_s'),
    CARD_BG_SUB_TWO         = _res('ui/home/activity/seasonlive/season_battle_card_bg_sub_l'),
    CARD_BTN_SELECT_DEFAULT = _res('ui/home/activity/seasonlive/season_battle_card_btn_selectlist_default'),
    CARD_BTN_SELECT_DOWN    = _res('ui/home/activity/seasonlive/season_battle_card_btn_selectlist_down'),
    CARD_LABEL_RELEASE_TIME = _res('ui/home/activity/seasonlive/season_battle_label_cost'),
    TITLE_BTN_ONE           = _res('ui/home/activity/seasonlive/season_battle_card_bg_title_s'),
    TITLE_BTN_TWO           = _res('ui/home/activity/seasonlive/season_battle_card_bg_title_l'),
    SCRIPT_TYPE_IMAGE       = _res('ui/home/activity/seasonlive/season_battle_ico_1'),
    SCRIPT_TYPE_IMAGE_TWO   = _res('ui/home/activity/seasonlive/season_battle_ico_3'),
    CARD_LINE_TWO           = _res('ui/home/activity/seasonlive/season_battle_card_line_1'),
    CARD_BG_TITLE           = _res('ui/home/activity/seasonlive/season_battle_card_bg_detial'),
}
function SeasonLiveCell:ctor(param)
    param            = param or {}
    local scriptType = param.type or 2
    if scriptType == 1 then
        local cellSize = cc.size(404, 680)
        self:setContentSize(cellSize)

        local cellContentSzie = cc.size(400, 600)
        local cellLayout      = display.newLayer(cellSize.width / 2, 50, { ap = display.CENTER_BOTTOM, size = cellContentSzie, color1 = cc.r4b() })
        self:addChild(cellLayout)
        cellLayout:setName("cellLayout")
        -- 点击的layer
        local clickLayer = display.newLayer(cellContentSzie.width / 2, cellContentSzie.height / 2,
                                            { ap = display.CENTER, size = cellContentSzie, color = cc.c4b(0, 0, 0, 0), enable = true })
        cellLayout:addChild(clickLayer)
        -- 选中的光圈
        local bgImageChosen = display.newImageView(DESC_DICT.CARD_BG_CHOSEN, cellContentSzie.width / 2, cellContentSzie.height / 2)
        cellLayout:addChild(bgImageChosen)
        bgImageChosen:setVisible(false)


        -- 季活的type的Image
        local scriptTypeImage = display.newImageView(DESC_DICT.SCRIPT_TYPE_IMAGE, cellContentSzie.width / 2, cellContentSzie.height - 115)
        scriptTypeImage:setAnchorPoint(display.CENTER_TOP)
        cellLayout:addChild(scriptTypeImage, 2)

        -- 前面的背景
        local card_bg_main = display.newImageView(DESC_DICT.CARD_BG_MAIN)
        card_bg_main:setPosition(cc.p(  cellContentSzie.width / 2, cellContentSzie.height / 2))
        cellLayout:addChild(card_bg_main)

        -- 顶部的Btn 图片
        local titleBtn = display.newButton(cellSize.width / 2, cellSize.height - 150, { n = DESC_DICT.TITLE_BTN_ONE, enable = false })
        cellLayout:addChild(titleBtn, 3)
        display.commonLabelParams(titleBtn, fontWithColor('14', { text = '好好学习', offset = cc.p(0, 5) }  ) )
        local desrLabel = display.newButton(cellSize.width /2 , cellSize.height -187 , {n = DESC_DICT.CARD_BG_TITLE , enable = false  })
        cellLayout:addChild(desrLabel, 3)
        -- 中间区域的背景
        local card_bg_sub      = display.newImageView(DESC_DICT.CARD_BG_SUB)
        local card_bg_sub_Size = card_bg_sub:getContentSize()
        card_bg_sub:setPosition(cc.p(card_bg_sub_Size.width / 2, card_bg_sub_Size.height / 2))
        -- 中部区域的主要内容
        local subcontentLayout = display.newLayer(cellContentSzie.width / 2, cellContentSzie.height - 265,
                                                  { ap = display.CENTER_TOP, size = card_bg_sub_Size, color1 = cc.r4b(), enable = true })
        cellLayout:addChild(subcontentLayout,12)
        subcontentLayout:addChild(card_bg_sub)

        -- 选择难度
        local chosenDifficultyLabel = display.newLabel(15, card_bg_sub_Size.height - 20,
                                                       fontWithColor('8', { fontSize = 20, color = "#926341", text = __("选择难度:"), ap = display.LEFT_CENTER }))
        subcontentLayout:addChild(chosenDifficultyLabel)
        -- 选择难度的按钮
        local chooseDifficultyBtn = display.newCheckBox(card_bg_sub_Size.width / 2, card_bg_sub_Size.height - 35,
                                                        { n = DESC_DICT.CARD_BTN_SELECT_DEFAULT, s = DESC_DICT.CARD_BTN_SELECT_DOWN })
        chooseDifficultyBtn:setName("chooseDifficultyBtn")
        local chooseDifficultyBtnSize = chooseDifficultyBtn:getContentSize()
        chooseDifficultyBtn:setPosition(cc.p(chooseDifficultyBtnSize.width / 2, chooseDifficultyBtnSize.height / 2))
        local chooseDifficultyLayout = display.newLayer(card_bg_sub_Size.width / 2, card_bg_sub_Size.height - 35,
                                                        { ap = display.CENTER_TOP, size = chooseDifficultyBtnSize, color = cc.c4b(0, 0, 0, 0), enable = true })
        subcontentLayout:addChild( chooseDifficultyLayout)

        chooseDifficultyLayout:addChild(chooseDifficultyBtn)
        -- 选择的难度
        local difficultyLabel = display.newRichLabel(chooseDifficultyBtnSize.width / 2 - 30, chooseDifficultyBtnSize.height / 2, { r = true,
                                                                                                                                   c = { fontWithColor('8', { text = "好好学习" }) }
        })
        difficultyLabel:setName("difficultyLabel")
        chooseDifficultyLayout:addChild(difficultyLabel)

        -- 第二条线
        local lineTwo = display.newImageView(DESC_DICT.CARD_LINE_TWO, card_bg_sub_Size.width / 2, card_bg_sub_Size.height - 104, { ap = display.CENTER_TOP } )
        subcontentLayout:addChild(lineTwo)

        local titleGoodBtn = display.newButton(card_bg_sub_Size.width / 2, card_bg_sub_Size.height - 105, { ap = display.CENTER_TOP, n = _res('ui/common/common_title_5'), enable = false })
        display.commonLabelParams(titleGoodBtn, fontWithColor('8', { text = __('可能掉落') }))
        subcontentLayout:addChild(titleGoodBtn)

        -- 副本的图鉴等级
        local recommendLevel = display.newLabel(card_bg_sub_Size.width / 2, -15, fontWithColor('8', { fontSize = 20, text = "推荐等级:", color = "#926341", ap = display.CENTER }))
        subcontentLayout:addChild(recommendLevel)
        recommendLevel:setName("recommendLevel")

        local costGoodImage     = display.newImageView(DESC_DICT.CARD_LABEL_RELEASE_TIME)
        local costGoodImageSize = costGoodImage:getContentSize()
        local challengeLayout   = display.newLayer(cellContentSzie.width / 2, 0, { size = costGoodImageSize, ap = display.CENTER, color1 = cc.r4b()
        })
        costGoodImage:setPosition(cc.p(costGoodImageSize.width / 2, costGoodImageSize.height / 2))
        challengeLayout:addChild(costGoodImage)
        challengeLayout:setName("challengeLayout")
        -- 剩余的次数
        local costLabel = display.newRichLabel(costGoodImageSize.width / 2, costGoodImageSize.height / 2, { c = { fontWithColor('8', { fontSize = 20, text = "推荐等级:" }) } } )
        challengeLayout:addChild(costLabel)
        costLabel:setName("costLabel")
        cellLayout:addChild(challengeLayout)
        self.viewData = {
            clickLayer             = clickLayer,
            titleGoodBtn           = titleGoodBtn,
            card_bg_main           = card_bg_main,
            chooseDifficultyBtn    = chooseDifficultyBtn,
            difficultyLabel        = difficultyLabel,
            costGoodImageSize      = costGoodImageSize,
            challengeLayout        = challengeLayout,
            recommendLevel         = recommendLevel,
            subcontentLayout       = subcontentLayout,
            costLabel              = costLabel,
            card_bg_sub            = card_bg_sub,
            cellLayout             = cellLayout,
            chooseDifficultyLayout = chooseDifficultyLayout,
            bgImageChosen          = bgImageChosen,
            titleBtn               = titleBtn,
            desrLabel              = desrLabel ,
            scriptTypeImage        = scriptTypeImage
        }
    elseif scriptType == 2 then
        local cellSize = cc.size(460, 680)
        self:setContentSize(cellSize)
        cellSize = cc.size(400, 600)
        local cellContentSzie = cc.size(400, 600)
        local cellLayout      = display.newLayer(cellSize.width / 2, 50, { ap = display.CENTER_BOTTOM, size = cellContentSzie, color1 = cc.r4b() })
        self:addChild(cellLayout)
        cellLayout:setName("cellLayout")
        -- 点击的layer
        local clickLayer = display.newLayer(cellContentSzie.width / 2, cellContentSzie.height / 2,
                                            { ap = display.CENTER, size = cellContentSzie, color = cc.c4b(0, 0, 0, 0), enable = true })
        cellLayout:addChild(clickLayer)
        -- 选中的光圈
        local bgImageChosen = display.newImageView(DESC_DICT.CARD_BG_CHOSEN_TWO, cellContentSzie.width / 2, cellContentSzie.height / 2)
        cellLayout:addChild(bgImageChosen)
        bgImageChosen:setVisible(false)

        -- 季活的type的Image
        local scriptTypeImage = display.newImageView(DESC_DICT.SCRIPT_TYPE_IMAGE_TWO, cellContentSzie.width / 2, cellContentSzie.height / 2 + 75)
        scriptTypeImage:setAnchorPoint(display.CENTER)
        cellLayout:addChild(scriptTypeImage, 2)

        -- 前面的背景
        local card_bg_main = display.newImageView(DESC_DICT.CARD_BG_MAIN_TWO)
        card_bg_main:setPosition(cc.p(  cellContentSzie.width / 2, cellContentSzie.height / 2))
        cellLayout:addChild(card_bg_main)


        -- 顶部的Btn 图片
        local titleBtn = display.newButton(cellSize.width / 2, cellSize.height -65 , { n = DESC_DICT.TITLE_BTN_TWO, enable = false })
        cellLayout:addChild(titleBtn, 3)
        display.commonLabelParams(titleBtn, fontWithColor('14', { text = '好好学习', offset = cc.p(0, 0) }  ) )
        local monsterImage = AssetsUtils.GetCartoonNode(300006, cellSize.width/2 , cellSize.height , { ap  = display.CENTER_TOP })
        cellLayout:addChild(monsterImage)
        monsterImage:setScale(0.65)
        -- 中间区域的背景
        local card_bg_sub      = display.newImageView(DESC_DICT.CARD_BG_SUB_TWO)
        local card_bg_sub_Size = card_bg_sub:getContentSize()
        card_bg_sub:setPosition(cc.p(card_bg_sub_Size.width / 2, card_bg_sub_Size.height / 2))
        -- 中部区域的主要内容
        local subcontentLayout = display.newLayer(cellContentSzie.width / 2, cellContentSzie.height - 265,
                                                  { ap = display.CENTER_TOP, size = card_bg_sub_Size, color1 = cc.r4b(), enable = true })
        cellLayout:addChild(subcontentLayout)
        subcontentLayout:addChild(card_bg_sub)


        local desrLabel = display.newButton(cellSize.width /2 , cellSize.height -105 , {n = DESC_DICT.CARD_BG_TITLE , enable = false ,"#ffc697"  })
        cellLayout:addChild(desrLabel, 3)

        -- 选择难度
        local chosenDifficultyLabel = display.newLabel(15, card_bg_sub_Size.height - 20,
                                                       fontWithColor('8', { fontSize = 20, color = "#ffffff", text = __("选择难度:"), ap = display.LEFT_CENTER }))
        subcontentLayout:addChild(chosenDifficultyLabel)
        -- 选择难度的按钮
        local chooseDifficultyBtn = display.newCheckBox(card_bg_sub_Size.width / 2, card_bg_sub_Size.height - 35,
                                                        { n = DESC_DICT.CARD_BTN_SELECT_DEFAULT, s = DESC_DICT.CARD_BTN_SELECT_DOWN })
        chooseDifficultyBtn:setName("chooseDifficultyBtn")
        local chooseDifficultyBtnSize = chooseDifficultyBtn:getContentSize()
        chooseDifficultyBtn:setPosition(cc.p(chooseDifficultyBtnSize.width / 2, chooseDifficultyBtnSize.height / 2))
        local chooseDifficultyLayout = display.newLayer(card_bg_sub_Size.width / 2, card_bg_sub_Size.height - 35, { ap = display.CENTER_TOP, size = chooseDifficultyBtnSize, color = cc.c4b(0, 0, 0, 0), enable = true })
        subcontentLayout:addChild( chooseDifficultyLayout)

        chooseDifficultyLayout:addChild(chooseDifficultyBtn)
        -- 选择的难度
        local difficultyLabel = display.newRichLabel(chooseDifficultyBtnSize.width / 2 - 30, chooseDifficultyBtnSize.height / 2,
                                                     { r = true, c = { fontWithColor('8', { text = "好好学习" }) }
                                                     })
        difficultyLabel:setName("difficultyLabel")
        chooseDifficultyLayout:addChild(difficultyLabel)

        -- 第二条线
        local lineTwo = display.newImageView(DESC_DICT.CARD_LINE_TWO, card_bg_sub_Size.width / 2, card_bg_sub_Size.height - 104, { ap = display.CENTER_TOP } )
        subcontentLayout:addChild(lineTwo)

        local titleGoodBtn = display.newButton(card_bg_sub_Size.width / 2, card_bg_sub_Size.height - 105, { ap = display.CENTER_TOP, n = _res('ui/common/common_title_5'), enable = false })
        display.commonLabelParams(titleGoodBtn, fontWithColor('8', { text = __('可能掉落') }))
        subcontentLayout:addChild(titleGoodBtn)

        -- 副本的图鉴等级
        local recommendLevel = display.newLabel(card_bg_sub_Size.width / 2, -15, fontWithColor('8', { fontSize = 20, text = "推荐等级:", color = "#ffc697", ap = display.CENTER }))
        subcontentLayout:addChild(recommendLevel)
        recommendLevel:setName("recommendLevel")

        local costGoodImage     = display.newImageView(DESC_DICT.CARD_LABEL_RELEASE_TIME)
        local costGoodImageSize = costGoodImage:getContentSize()
        local challengeLayout   = display.newLayer(cellContentSzie.width / 2, 0, { size = costGoodImageSize, ap = display.CENTER, color1 = cc.r4b()
        })
        costGoodImage:setPosition(cc.p(costGoodImageSize.width / 2, costGoodImageSize.height / 2))
        challengeLayout:addChild(costGoodImage)
        challengeLayout:setName("challengeLayout")
        -- 应该扣除的道具
        local costLabel = display.newRichLabel(costGoodImageSize.width / 2, costGoodImageSize.height / 2, { c = { fontWithColor('8', { fontSize = 20, text = "推荐等级:" }) } } )
        challengeLayout:addChild(costLabel)
        costLabel:setName("costLabel")
        cellLayout:addChild(challengeLayout)
        self.viewData = {
            clickLayer             = clickLayer,
            titleGoodBtn           = titleGoodBtn,
            card_bg_main           = card_bg_main,
            chooseDifficultyBtn    = chooseDifficultyBtn,
            difficultyLabel        = difficultyLabel,
            costGoodImageSize      = costGoodImageSize,
            challengeLayout        = challengeLayout,
            recommendLevel         = recommendLevel,
            subcontentLayout       = subcontentLayout,
            costLabel              = costLabel,
            scriptTypeImage        = scriptTypeImage,
            card_bg_sub            = card_bg_sub,
            cellLayout             = cellLayout,
            desrLabel              = desrLabel ,
            chooseDifficultyLayout = chooseDifficultyLayout,
            bgImageChosen          = bgImageChosen,
            titleBtn               = titleBtn,
        }
    end


end
return SeasonLiveCell