
---@class Anniversary19AnswerQuesView
local Anniversary19AnswerQuesView = class('Anniversary19AnswerQuesView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.anniversary19.Anniversary19AnswerQuesView'
    node:setName('Anniversary19AnswerQuesView')
    node:enableNodeEvents()
    return node
end)
local newImageView = display.newImageView
local newLabel = display.newLabel
local newButton = display.newButton
local newLayer = display.newLayer
---@type Anniversary2019Manager
local anniversary2019Mgr = app.anniversary2019Mgr
local SECTION = {
    START = 0,  -- 答题开始
    RIGHT  = 1 , --答对
    ERROR  = 2 , --答错
}
local BUTTON_TAG = {
    ANSWER_TAG = 1001 , -- 回答事件
    CONTINUE_TAG = 1002  , -- 回答事件
}
local RES_DICT = {
    COMMON_BTN_WHITE_DEFAULT                   = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_white_default.png'),
    VIP_MENU_BG                                = app.anniversary2019Mgr:GetResPath('ui/home/fishing/vip_menu_bg.png'),
    WONDERLAND_EXPLORE_GO_QUESTION_ICO_WRONG   = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_go_question_ico_wrong.png'),
    COMMCON_BG_TEXT                            = app.anniversary2019Mgr:GetResPath('ui/common/commcon_bg_text.png'),
    WONDERLAND_EXPLORE_GO_QUESTION_BTN_DEFAULT = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_go_question_btn_default.png'),
    WONDERLAND_EXPLORE_GO_QUESTION_LABEL_RIGHT = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_go_question_label_right.png'),
    WONDERLAND_EXPLORE_GO_QUESTION_BTN_RIGHT   = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_go_question_btn_right.png'),
    WONDERLAND_EXPLORE_GO_QUESTION_BTN_WRONG   = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_go_question_btn_wrong.png'),
    WONDERLAND_EXPLORE_GO_QUESTION_BTN_SELECT   = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_go_question_btn_select.png'),
    RAID_ROOM_ICO_READY                        = app.anniversary2019Mgr:GetResPath('ui/common/raid_room_ico_ready.png'),
}
function Anniversary19AnswerQuesView:ctor( ... )
    self:InitUI()
end


function Anniversary19AnswerQuesView:InitUI()
    -- 吞噬层
    local swallowLayer = display.newLayer(display.cx , display.cy , {
        ap = display.CENTER, size = display.size , color = cc.c4b(0,0,0,175),
        enable = true
    })
    self:addChild(swallowLayer)

    local view = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size})
    self:addChild(view)

    local answerQuestSkinId = anniversary2019Mgr:GetChangeSkinData().answerQuestSkinId or 251293
    local cardSkinDrawNode = require('common.CardSkinDrawNode').new({skinId  = answerQuestSkinId , coordinateType = COORDINATE_TYPE_HOME})
    cardSkinDrawNode:setPosition(cc.p(0, 0))
    cardSkinDrawNode:setScale(1)
    view:addChild(cardSkinDrawNode)

    local leftLayout = newLayer(1302, 342,
    { ap = display.RIGHT_CENTER, size = cc.size(514, 710), enable = true })
    leftLayout:setPosition(display.SAFE_R + -32, display.cy + -33)
    view:addChild(leftLayout)

    local bgImage = newImageView(RES_DICT.VIP_MENU_BG, 0, 0,
    { ap = display.LEFT_BOTTOM, tag = 39, enable = false })
    leftLayout:addChild(bgImage)

    local answerLabel = newLabel(258, 640,
    fontWithColor(14, { outline = false ,  ap = display.CENTER, color = '#a97b4c', text = app.anniversary2019Mgr:GetPoText(__('提交答案')), fontSize = 26, tag = 43 }))
    leftLayout:addChild(answerLabel)

    local answerResultLabel = newLabel(258, 406,
    fontWithColor(14 , { outline = false ,  ap = display.CENTER, color = '#a97b4c', text = "", fontSize = 26, tag = 45 }))
    leftLayout:addChild(answerResultLabel)

    local questionLayout = newLayer(257, 519,
    { ap = display.CENTER, color = cc.r4b(0), size = cc.size(390, 174), enable = true })
    leftLayout:addChild(questionLayout)

    local textBgImage = newImageView(RES_DICT.COMMCON_BG_TEXT, 195, 87,
    { ap = display.CENTER, tag = 41, enable = false, scale9 = true, size = cc.size(390, 174) })
    questionLayout:addChild(textBgImage)

    local questionLabel = newLabel(30, 150,
    { ap = display.LEFT_TOP, color = '#88604e', w = 300, hAlign = display.TAC ,  text = "", fontSize = 24, tag = 42 })
    questionLayout:addChild(questionLabel)

    local answerBtn = newButton(258, 103, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_WHITE_DEFAULT, d = RES_DICT.COMMON_BTN_WHITE_DEFAULT, s = RES_DICT.COMMON_BTN_WHITE_DEFAULT, scale9 = true, size = cc.size(122, 62), tag = 46 })
    display.commonLabelParams(answerBtn, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('提交答案')), fontSize = 24, color = '#ffffff'}))
    leftLayout:addChild(answerBtn)
    local posStart = cc.p(258, 346)
    local optionsTable = {}
    for i = 1 , 3 do
        local viewData = self:CreateOptionsCell()
        optionsTable[#optionsTable+1] = viewData
        viewData.oneOptionsLayout:setTag(i)
        leftLayout:addChild(viewData.oneOptionsLayout, 2 )
        viewData.oneOptionsLayout:setPosition(posStart.x ,( 1- i ) * 72 +  posStart.y  )
    end
    self.viewData =  {
    leftLayout              = leftLayout,
    bgImage                 = bgImage,
    answerLabel             = answerLabel,
    answerResultLabel       = answerResultLabel,
    questionLayout          = questionLayout,
    textBgImage             = textBgImage,
    questionLabel           = questionLabel,
    optionsTable           = optionsTable,
    answerBtn               = answerBtn
    }
end

function Anniversary19AnswerQuesView:CreateOptionsCell()
    local oneOptionsLayout = newButton(258, 346,
            { ap = display.CENTER, size = cc.size(400, 72) })
    local optionsImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_GO_QUESTION_BTN_DEFAULT, 200, 36,
            { ap = display.CENTER })
    oneOptionsLayout:addChild(optionsImage)

    local optionsText = newLabel(200, 36,
            { ap = display.CENTER, color = '#ffffff', text = "ccc", fontSize = 26, tag = 49 })
    oneOptionsLayout:addChild(optionsText)

    local rightOptionsImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_GO_QUESTION_LABEL_RIGHT, 200, 36,
            { ap = display.CENTER })
    oneOptionsLayout:addChild(rightOptionsImage)
    rightOptionsImage:setVisible(false)

    local resultImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_GO_QUESTION_ICO_WRONG, 20, 33,
            { ap = display.LEFT_CENTER})
    resultImage:setVisible(false)
    oneOptionsLayout:addChild(resultImage)
    local viewData = {
        oneOptionsLayout  = oneOptionsLayout,
        optionsImage      = optionsImage,
        optionsText       = optionsText,
        rightOptionsImage = rightOptionsImage,
        resultImage       = resultImage
    }
    return viewData
end

function Anniversary19AnswerQuesView:UpdateUI( exploreModuleId ,  exploreId , section , answerTable )
    section = checkint(section)
    if section == SECTION.START then
        self:UpdateStartUI(exploreModuleId , exploreId , answerTable )
    elseif  section == SECTION.RIGHT then
        self:UpdateRightUI()
    elseif  section == SECTION.ERROR then
        self:UpdateErrorUI()
    end
end

function Anniversary19AnswerQuesView:UpdateStartUI(exploreModuleId , exploreId , answerTable)
    local viewData = self.viewData
    local optionName = anniversary2019Mgr:GetDreamQuestTypeNameByDreamQuestType(anniversary2019Mgr.dreamQuestType.ANSWER_SHUT)
    local optionsConfig = anniversary2019Mgr:GetConfigDataByName(optionName)
    local optionsOneConfig = optionsConfig[tostring(exploreModuleId)][tostring(exploreId )]
    local question = optionsOneConfig.question
    local options = optionsOneConfig.options
    display.commonLabelParams(viewData.questionLabel , {text = question })
    display.commonLabelParams(viewData.answerBtn ,{text = app.anniversary2019Mgr:GetPoText(__('提交答案'))} )
    viewData.answerBtn:setNormalImage(app.anniversary2019Mgr:GetResPath('ui/common/common_btn_orange_disable'))
    viewData.answerBtn:setSelectedImage(app.anniversary2019Mgr:GetResPath('ui/common/common_btn_orange_disable'))
    viewData.answerBtn:setTag(BUTTON_TAG.ANSWER_TAG)
    for i = 1 ,#viewData.optionsTable do
        local optionsData = viewData.optionsTable[i]
        display.commonLabelParams(optionsData.optionsText , {color = "#591010" ,  text = options[tostring(answerTable[i])] })
    end
end

function Anniversary19AnswerQuesView:UpdateRightUI()
    local viewData = self.viewData
    display.commonLabelParams(viewData.answerResultLabel , {text = app.anniversary2019Mgr:GetPoText(__('回答正确')) , color  = "#5da52d"})
    viewData.answerBtn:setNormalImage(app.anniversary2019Mgr:GetResPath('ui/common/common_btn_white_default'))
    viewData.answerBtn:setSelectedImage(app.anniversary2019Mgr:GetResPath('ui/common/common_btn_white_default'))
    display.commonLabelParams(viewData.answerBtn , {text = app.anniversary2019Mgr:GetPoText(__('继续'))})
    viewData.answerBtn:setTag(BUTTON_TAG.CONTINUE_TAG)
end

function Anniversary19AnswerQuesView:UpdateErrorUI()
    local viewData = self.viewData
    display.commonLabelParams(viewData.answerResultLabel , {text = app.anniversary2019Mgr:GetPoText(__('回答错误')) , color  = "#db3a33"})
    viewData.answerBtn:setNormalImage(app.anniversary2019Mgr:GetResPath('ui/common/common_btn_white_default'))
    viewData.answerBtn:setSelectedImage(app.anniversary2019Mgr:GetResPath('ui/common/common_btn_white_default'))
    display.commonLabelParams(viewData.answerBtn , {text = app.anniversary2019Mgr:GetPoText(__('继续'))})
    viewData.answerBtn:setTag(BUTTON_TAG.CONTINUE_TAG)
end

function Anniversary19AnswerQuesView:ClickOptionsCell(index)
    local optionsTable = self.viewData.optionsTable
    for i = 1, #optionsTable do
        local viewData = optionsTable[i]
        if index == i  then
            viewData.optionsImage:setTexture(RES_DICT.WONDERLAND_EXPLORE_GO_QUESTION_BTN_SELECT)
            viewData.optionsText:setColor(ccc3FromInt("##ffffff"))
        else
            viewData.optionsImage:setTexture(RES_DICT.WONDERLAND_EXPLORE_GO_QUESTION_BTN_DEFAULT)
            viewData.optionsText:setColor(ccc3FromInt("#591010"))
        end
    end
end


---UpdateOptionsCell
---@param viewData table 当前容器
---@param currentOptionId number 当前选项
---@param selectOptionId number 选中的选项
function Anniversary19AnswerQuesView:UpdateOptionsCell( viewData , currentOptionId  ,  selectOptionId)
    currentOptionId = checkint(currentOptionId)
    selectOptionId = checkint(selectOptionId)
    if  checkint(selectOptionId) == 1 then
        -- 答案正确
        if currentOptionId == selectOptionId then
            viewData.optionsImage:setTexture(RES_DICT.WONDERLAND_EXPLORE_GO_QUESTION_BTN_RIGHT)
            viewData.rightOptionsImage:setVisible(false)
            viewData.resultImage:setVisible(false)
            viewData.resultImage:setScale(1.1)
            viewData.optionsImage:runAction(
                    cc.EaseSineInOut:create(
                            cc.Sequence:create(
                                    cc.ScaleTo:create(0.5,0.95) ,
                                    cc.ScaleTo:create(0.5,1.05) ,
                                    cc.ScaleTo:create(0.5,1)
                            )
                    )
            )
        end

    else
        -- 答案错误
        if currentOptionId == 1 then
            -- 正确选项
            viewData.rightOptionsImage:setVisible(true)

            viewData.resultImage:setVisible(true)
            viewData.resultImage:setTexture(RES_DICT.RAID_ROOM_ICO_READY)
        elseif currentOptionId == selectOptionId then
            -- 选中选项错误
            viewData.resultImage:setScale(1.5)
            viewData.resultImage:setOpacity(125)
            viewData.resultImage:runAction(
                cc.EaseSineInOut:create(
                    cc.Sequence:create(
                         cc.Spawn:create(
                                 cc.ScaleTo:create(0.5,0.9) ,
                                 cc.FadeIn:create(0.5)
                         ),
                        cc.ScaleTo:create(0.5,1.3) ,
                        cc.ScaleTo:create(0.5,1)
                    )
                )
            )
            viewData.rightOptionsImage:setVisible(false)
            viewData.resultImage:setVisible(true)
            viewData.optionsImage:setTexture(RES_DICT.WONDERLAND_EXPLORE_GO_QUESTION_BTN_WRONG)
            viewData.resultImage:setTexture(RES_DICT.WONDERLAND_EXPLORE_GO_QUESTION_ICO_WRONG)
        end
    end
end

return Anniversary19AnswerQuesView
