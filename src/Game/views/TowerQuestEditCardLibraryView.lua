--[[
 * author : kaishiqi
 * descpt : 爬塔 - 牌库编辑界面
]]
local TowerModelFactory             = require('Game.models.TowerQuestModelFactory')
local TowerQuestModel               = TowerModelFactory.getModelType('TowerQuest')
local TowerQuestEditCardLibraryView = class('TowerQuestEditCardLibraryView', function ()
    return display.newLayer(0, 0, {name = 'Game.views.TowerQuestEditCardLibraryView'})
end)

local RES_DICT = {
    BTN_BACK      = 'ui/common/common_btn_back.png',
    BTN_CLEAN     = 'ui/common/common_btn_white_default.png',
    BTN_CONFIRM   = 'ui/common/common_btn_orange.png',
    BTN_COMBO_N   = 'ui/tower/library/btn_selection_unused.png',
    BTN_COMBO_S   = 'ui/tower/library/team_btn_selection_choosed.png',
    LIBRARY_FRAME = 'ui/tower/library/tower_bg_preteam.png',
    PRIVATE_FRAME = 'ui/common/pvp_select_bg_allcard.png',
    PRIVATE_BG    = 'ui/common/common_bg_goods.png',
    BTN_FILTER_N  = 'ui/common/tower_select_btn_filter_default.png',
    BTN_FILTER_S  = 'ui/common/tower_select_btn_filter_selected.png',
    NUMBER_BAR    = 'ui/tower/ready/tower_label_title.png',
    PCARD_CELL_S  = 'ui/common/common_bg_frame_goods_elected.png',
    LCARD_CELL_BG = 'ui/common/kapai_frame_bg_nocard.png',
    LCARD_CELL_FA = 'ui/common/kapai_frame_nocard.png',
    LCARD_CELL_SL = 'ui/tower/library/tower_bg_card_slot.png',
    CSKILL_FRAME  = 'ui/home/teamformation/team_ico_skill_circle.png',
}

local LIBRARY_COLS = 5
local FILTER_TYPE  = {
	{type = CARD_FILTER_TYPE_ALL, typeDescr = __('所有')},
	{type = CARD_FILTER_TYPE_DEF},
	{type = CARD_FILTER_TYPE_NEAR_ATK},
	{type = CARD_FILTER_TYPE_REMOTE_ATK},
	{type = CARD_FILTER_TYPE_DOCTOR},
}

local CreateView = nil
local CreatePrivateCardCell = nil
local CreateLibraryCardCell = nil

TowerQuestEditCardLibraryView.FILTER_TYPE  = FILTER_TYPE
TowerQuestEditCardLibraryView.LIBRARY_COLS = LIBRARY_COLS


function TowerQuestEditCardLibraryView:ctor(args)
    self.editModelScale_ = 1
    self.teamModelScale_ = 0.8
    self.noneModelScale_ = 0.8
    self.editModelPoint_ = cc.p(0, 0)
    self.teamModelPoint_ = cc.p(-125, -275)
    self.noneModelPoint_ = cc.p(-865, -275)

    xTry(function()
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)

        self.viewData_.blackBg:setVisible(false)
        self.viewData_.conentLayer:setPosition(-display.width, -display.height)
    end, __G__TRACKBACK__)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- black bg
    local blackBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,200), enable = true})
    view:addChild(blackBg)

    -- conent layer
    local conentLayer = display.newLayer()
    view:addChild(conentLayer)

    -------------------------------------------------
    -- library layer

    local libraryLayer = display.newLayer(0, 305)
    conentLayer:addChild(libraryLayer)

    local libraryFrameSize = cc.size(1203 + display.SAFE_L, 469)
    libraryLayer:addChild(display.newImageView(_res(RES_DICT.LIBRARY_FRAME), 0, 0, {ap = display.LEFT_BOTTOM, scale9 = true, size = libraryFrameSize, capInsets = cc.rect(0,0,1,1)}))

    -- title bar
    local titleBar = display.newButton(display.SAFE_L + 110, 462, {n = _res(RES_DICT.NUMBER_BAR), ap = display.LEFT_CENTER, scale9 = true, size = cc.size(240,36), enable = false})
    display.commonLabelParams(titleBar, fontWithColor(4, {offset = cc.p(10,0), text = __('预备队伍'),paddingW = 40 }))
    libraryLayer:addChild(titleBar)
    titleBar:setScale(1 / 0.8)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, 400, {n = _res(RES_DICT.BTN_BACK)})
    libraryLayer:addChild(backBtn)

    -- combo button
    local comboBtn = display.newToggleView(display.SAFE_L + 95, 260, {n = _res(RES_DICT.BTN_COMBO_N), s = _res(RES_DICT.BTN_COMBO_S)})
    display.commonLabelParams(comboBtn, fontWithColor(18, {text = __('查看连携')}))
    libraryLayer:addChild(comboBtn)

    local libraryCardFrameList = {}
    local libraryCardFramePos  = cc.p(display.SAFE_L + 280, 340)
    for i = 1, TowerQuestModel.LIBRARY_CARD_MAX do
        local cardAtRow = math.ceil(i / LIBRARY_COLS)
        local cardAtCol = (i-1) % LIBRARY_COLS + 1
        local cardPoint = cc.p(libraryCardFramePos.x + (cardAtCol-1) * 180, libraryCardFramePos.y - (cardAtRow-1) * 180)
        local cardFrame = display.newImageView(_res(RES_DICT.LCARD_CELL_BG), cardPoint.x, cardPoint.y, {scale = 0.8})
        local frameSize = cardFrame:getContentSize()
        cardFrame:addChild(display.newImageView(_res(RES_DICT.LCARD_CELL_FA), frameSize.width/2, frameSize.height/2))
        libraryLayer:addChild(display.newImageView(_res(RES_DICT.LCARD_CELL_SL), cardPoint.x, cardPoint.y, {scale = 0.83}))
        libraryLayer:addChild(cardFrame)
        libraryCardFrameList[i] = cardFrame
    end


    -------------------------------------------------
    -- private layer
    local privateLayer = display.newLayer()
    conentLayer:addChild(privateLayer)

    privateLayer:addChild(display.newImageView(_res(RES_DICT.PRIVATE_FRAME), 0, 0, {ap = display.LEFT_BOTTOM, scale9 = true, size = cc.size(display.width, 344)}))

    -- clean button
    local cleanBtn = display.newButton(display.SAFE_R - 72, 286, {n = _res(RES_DICT.BTN_CLEAN), scale9 = true })
    display.commonLabelParams(cleanBtn, fontWithColor(14, {text = __('清空选择') }))
    privateLayer:addChild(cleanBtn)
    local cleanBtnLabelSize = display.getLabelContentSize(cleanBtn:getLabel())
    if cleanBtnLabelSize.width > 140 then
        display.commonLabelParams(cleanBtn, fontWithColor(14, {text = __('清空选择') , reqH = 40 , w = 170 ,reqW = 130, hAlign= display.TAC} ))
    else
        display.commonLabelParams(cleanBtn, fontWithColor(14, {text = __('清空选择') , reqW = 110}))
    end



    -- confirm button
    local confirmBtn = display.newButton(cleanBtn:getPositionX(), 42, {n = _res(RES_DICT.BTN_CONFIRM)})
    display.commonLabelParams(confirmBtn, fontWithColor(14, {text = __('确 定')}))
    privateLayer:addChild(confirmBtn)

    -- number bar
    local numberBar = display.newButton(display.SAFE_L + -40, 332, {n = _res(RES_DICT.NUMBER_BAR), ap = display.LEFT_CENTER, scale9 = true, size = cc.size(170,36), enable = false})
    display.commonLabelParams(numberBar, fontWithColor(3, {offset = cc.p(5,0)}))
    privateLayer:addChild(numberBar)

    -- filter button list
    local filterBtnList = {}
    for i, v in ipairs(FILTER_TYPE) do
        local filterBtn  = display.newToggleView(display.SAFE_L + 55, 275 - (i-1)*55, {n = _res(RES_DICT.BTN_FILTER_N), s = _res(RES_DICT.BTN_FILTER_S), tag = i})
        filterBtnList[i] = filterBtn
        privateLayer:addChild(filterBtn)

        if v.type ~= CARD_FILTER_TYPE_ALL then
            local btnSize = filterBtn:getContentSize()
            filterBtn:addChild(display.newImageView(_res(CardUtils.CAREER_ICON_FRAME_PATH_MAP[tostring(v.type)]), btnSize.width/2, btnSize.height/2))
            filterBtn:addChild(display.newImageView(_res(CardUtils.CAREER_ICON_PATH_MAP[tostring(v.type)]), btnSize.width/2, btnSize.height/2))
        else
            display.commonLabelParams(filterBtn, fontWithColor(5, {text = tostring(v.typeDescr)}))
        end
    end

    -- private card gridPageView
    local pageViewMaxW  = display.SAFE_RECT.width - 260
    local pageViewRows  = 2
    local pageViewCols  = math.floor(pageViewMaxW / 144)
    local pageCellSize  = cc.size(math.ceil(pageViewMaxW / pageViewCols), 144)
    local pageViewSize  = cc.size(pageCellSize.width * pageViewCols, pageCellSize.height * pageViewRows)
    local pageFrameSize = cc.size(pageViewSize.width + 8, pageViewSize.height + 8)
    privateLayer:addChild(display.newImageView(_res(RES_DICT.PRIVATE_BG), size.width/2 - 20, 20-4, {ap = display.CENTER_BOTTOM, scale9 = true, size = pageFrameSize}))
    
    local privateCardGridView = CGridView:create(pageViewSize)
    privateCardGridView:setAnchorPoint(display.CENTER_BOTTOM)
    privateCardGridView:setPosition(size.width/2 - 20, 20)
    privateCardGridView:setSizeOfCell(pageCellSize)
    privateCardGridView:setColumns(pageViewCols)
    privateLayer:addChild(privateCardGridView)


    -------------------------------------------------
    -- library card layer
    local libraryLayerPos  = cc.p(libraryLayer:getPosition())
    local libraryCardLayer = display.newLayer(libraryLayerPos.x, libraryLayerPos.y)
    conentLayer:addChild(libraryCardLayer)

    -- edit library button
    local editLibraryBtn = display.newLayer(libraryLayerPos.x + 160, libraryLayerPos.y + 50, {size = cc.size(940, 400), color = cc.c4b(0,0,0,0), enable = true})
    conentLayer:addChild(editLibraryBtn)
    editLibraryBtn:setVisible(false)

    return {
        view                 = view,
        blackBg              = blackBg,
        conentLayer          = conentLayer,
        backBtn              = backBtn,
        comboBtn             = comboBtn,
        cleanBtn             = cleanBtn,
        confirmBtn           = confirmBtn,
        numberBar            = numberBar,
        filterBtnList        = filterBtnList,
        libraryCardLayer     = libraryCardLayer,
        editLibraryBtn       = editLibraryBtn,
        libraryCardFrameList = libraryCardFrameList,
        privateCardGridView  = privateCardGridView,
    }
end


CreatePrivateCardCell = function(size)
    local view = CGridViewCell:new()
    view:setContentSize(size)

    local headLayer = display.newLayer(0, 0, {size = size})
    view:addChild(headLayer)

    local selectLayer = display.newLayer(0, 0, {size = size})
    view:addChild(selectLayer)

    selectLayer:addChild(display.newLayer(size.width/2, size.height/2, {color = cc.c4b(0,0,0,150), size = cc.size(126,126), ap = display.CENTER}))
    selectLayer:addChild(display.newImageView(_res(RES_DICT.PCARD_CELL_S), size.width/2, size.height/2, {scale9 = true, size = cc.size(138,138)}))

    local clickArea = display.newLayer(0, 0, {size = size, color = cc.c4b(0,0,0,0), enable = true})
    view:addChild(clickArea)

    return {
        view         = view,
        headLayer    = headLayer,
        cardHeadNode = nil,
        selectLayer  = selectLayer,
        clickArea    = clickArea,
    }
end


CreateLibraryCardCell = function()
    local size = cc.size(152, 152)
    local view = display.newLayer(0, 0, {size = size, ap = display.CENTER})

    local headLayer = display.newLayer(0, 0, {size = size})
    view:addChild(headLayer)

    local blackSize = cc.size(size.width + 8, size.height + 8)
    local blackBg   = display.newLayer(size.width/2, size.height/2, {color = cc.c4b(0,0,0,100), size = blackSize, ap = display.CENTER})
    blackBg:setCascadeOpacityEnabled(true)
    view:addChild(blackBg)

    local comboLayer = display.newLayer(size.width/2, size.height/2, {size = size, ap = display.CENTER})
    view:addChild(comboLayer)
    
    local skillFrame = display.newImageView(_res(RES_DICT.CSKILL_FRAME), size.width/2, size.height/2, {scale = 1.6})
    comboLayer:addChild(skillFrame)

    local skillLayer = display.newLayer(size.width/2, size.height/2, {size = size})
    comboLayer:addChild(skillLayer)

    local clickArea = display.newLayer(0, 0, {size = size, color = cc.c4b(0,0,0,0), enable = true})
    view:addChild(clickArea)

    return {
        view              = view,
        headLayer         = headLayer,
        cardHeadNode      = nil,
        blackBg           = blackBg,
        comboLayer        = comboLayer,
        skillLayer        = skillLayer,
        clickArea         = clickArea,
        comboLayerShowPos = cc.p(comboLayer:getPosition()),
        comboLayerHidePos = cc.p(size.width - 20, 20),
    }
end


function TowerQuestEditCardLibraryView:getViewData()
    return self.viewData_
end


function TowerQuestEditCardLibraryView:createPrivateCardCell(size)
    return CreatePrivateCardCell(size)
end


function TowerQuestEditCardLibraryView:createLibraryCardCell()
    return CreateLibraryCardCell()
end


function TowerQuestEditCardLibraryView:showLibraryCardCellCSkill(cellViewData, isFast)
    self:updateLibraryCardCellCSkillStatus_(true, cellViewData, isFast)
end
function TowerQuestEditCardLibraryView:hideLibraryCardCellCSkill(cellViewData, isFast)
    self:updateLibraryCardCellCSkillStatus_(false, cellViewData, isFast)
end
function TowerQuestEditCardLibraryView:updateLibraryCardCellCSkillStatus_(isShow, cellViewData, isFast)
    if not cellViewData then return end

    local hideEndCB = function()
        cellViewData.blackBg:setOpacity(0)
        cellViewData.comboLayer:setScale(0.5)
        cellViewData.comboLayer:setPosition(cellViewData.comboLayerHidePos)
    end

    local showEndCB = function()
        cellViewData.blackBg:setOpacity(150)
        cellViewData.comboLayer:setScale(1)
        cellViewData.comboLayer:setPosition(cellViewData.comboLayerShowPos)
    end

    local actionTime = 0.15
    cellViewData.view:stopAllActions()

    if isFast then
        if isShow then
            showEndCB()
        else
            hideEndCB()
        end
    else
        if isShow then
            cellViewData.view:runAction(cc.Spawn:create({
                cc.TargetedAction:create(cellViewData.blackBg, cc.FadeTo:create(actionTime, 150)),
                cc.TargetedAction:create(cellViewData.comboLayer, cc.ScaleTo:create(actionTime, 1)),
                cc.TargetedAction:create(cellViewData.comboLayer, cc.MoveTo:create(actionTime, cellViewData.comboLayerShowPos))
            }))
        else
            cellViewData.view:runAction(cc.Spawn:create({
                cc.TargetedAction:create(cellViewData.blackBg, cc.FadeTo:create(actionTime, 0)),
                cc.TargetedAction:create(cellViewData.comboLayer, cc.ScaleTo:create(actionTime, 0.5)),
                cc.TargetedAction:create(cellViewData.comboLayer, cc.MoveTo:create(actionTime, cellViewData.comboLayerHidePos))
            }))
        end
    end
end


function TowerQuestEditCardLibraryView:showView(hasLibrary, endCb)
    self.viewData_.editLibraryBtn:setVisible(hasLibrary)
    self.viewData_.conentLayer:setScale(self.noneModelScale_)
    self.viewData_.conentLayer:setPosition(cc.p(hasLibrary and self.teamModelPoint_.x or self.noneModelPoint_.x, -display.height))

    local actionTime = 0.5
    self:runAction(cc.Sequence:create({
        cc.TargetedAction:create(self.viewData_.conentLayer, cc.MoveTo:create(actionTime, hasLibrary and self.teamModelPoint_ or self.noneModelPoint_)),
        cc.CallFunc:create(function()
            if endCb then endCb() end
        end)
    }))
end


function TowerQuestEditCardLibraryView:showLibraryHide(endCb)
    self.viewData_.blackBg:setVisible(false)
    self.viewData_.editLibraryBtn:setVisible(false)

    local actionTime = 0.15
    self:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.viewData_.conentLayer, cc.ScaleTo:create(actionTime, self.noneModelScale_)),
            cc.TargetedAction:create(self.viewData_.conentLayer, cc.MoveTo:create(actionTime, self.noneModelPoint_))
        }),
        cc.CallFunc:create(function()
            if endCb then endCb() end
        end)
    }))
end


function TowerQuestEditCardLibraryView:showLibraryCards(endCb)
    local actionTime = 0.15
    self:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.viewData_.blackBg, cc.FadeTo:create(actionTime, 0)),
            cc.TargetedAction:create(self.viewData_.conentLayer, cc.ScaleTo:create(actionTime, self.teamModelScale_)),
            cc.TargetedAction:create(self.viewData_.conentLayer, cc.MoveTo:create(actionTime, self.teamModelPoint_))
        }),
        cc.CallFunc:create(function()
            self.viewData_.blackBg:setVisible(false)
            self.viewData_.editLibraryBtn:setVisible(true)
            if endCb then endCb() end
        end)
    }))
end


function TowerQuestEditCardLibraryView:showLibraryEdit(endCb)
    self.viewData_.blackBg:setOpacity(0)
    self.viewData_.blackBg:setVisible(true)
    self.viewData_.editLibraryBtn:setVisible(false)

    local actionTime = 0.15
    self:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.viewData_.blackBg, cc.FadeTo:create(actionTime, 150)),
            cc.TargetedAction:create(self.viewData_.conentLayer, cc.ScaleTo:create(actionTime, self.editModelScale_)),
            cc.TargetedAction:create(self.viewData_.conentLayer, cc.MoveTo:create(actionTime, self.editModelPoint_))
        }),
        cc.DelayTime:create(0.05),
        cc.CallFunc:create(function()
            if endCb then endCb() end
        end)
    }))
end


return TowerQuestEditCardLibraryView