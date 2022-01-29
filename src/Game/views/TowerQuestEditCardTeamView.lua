--[[
 * author : kaishiqi
 * descpt : 爬塔 - 编队编辑界面
]]
local TowerModelFactory          = require('Game.models.TowerQuestModelFactory')
local TowerQuestModel            = TowerModelFactory.getModelType('TowerQuest')
local TowerQuestEditCardTeamView = class('TowerQuestEditCardTeamView', function ()
    return display.newLayer(0, 0, {name = 'Game.views.TowerQuestEditCardTeamView'})
end)

local RES_DICT = {
    BTN_BACK      = 'ui/common/common_btn_back.png',
    BTN_CLEAN     = 'ui/common/common_btn_white_default.png',
    BTN_CONFIRM   = 'ui/common/common_btn_orange.png',
    LIBRARY_FRAME = 'ui/tower/library/tower_bg_preteam.png',
    LCARD_CELL_BG = 'ui/common/kapai_frame_bg_nocard.png',
    LCARD_CELL_FA = 'ui/common/kapai_frame_nocard.png',
    LCARD_CELL_SL = 'ui/tower/library/tower_bg_card_slot.png',
    PCARD_CELL_S  = 'ui/common/common_bg_frame_goods_elected.png',
    PCARD_CELL_W  = 'ui/cards/head/kapai_frame_mengban_tired.png',
    PCARD_BAR_W   = 'ui/tower/team/tower_prepare_label_warning.png',
    BOTTOM_FRAME  = 'ui/tower/team/tower_prepare_bg_below.png',
    BTN_TIPS      = 'ui/common/common_btn_tips.png',
    PSKILL_FRAME  = 'ui/battle/battle_bg_skill_default.png',
    ADD_ICON      = 'ui/common/maps_fight_btn_pet_add.png',
    SITE_MEMBER   = 'ui/common/tower_bg_team_base.png',
    SITE_CAPTAIN  = 'ui/common/tower_bg_team_base_cap.png',
    ICON_SITE_C   = 'ui/home/teamformation/team_ico_captain.png',
    SITE_LIGHT    = 'ui/common/tower_prepare_bg_light.png',
    CSKILL_FRAME  = 'ui/home/teamformation/team_ico_skill_circle.png',
}

local LIBRARY_COLS = 5

local CreateView            = nil
local CreateTeamSiteView    = nil
local CreateCardSpineView   = nil
local CreateLibraryCardCell = nil

local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function TowerQuestEditCardTeamView:ctor(args)
    xTry(function()
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)

        self.viewData_.blackBg:setOpacity(0)
        self.viewData_.libraryLayer:setScale(0)
        self.viewData_.bottomLayer:setPositionY(-200)
        
        for i, cardSite in ipairs(self.viewData_.teamCardSiteList) do
            cardSite.view:setScaleY(0)
        end        
    end, __G__TRACKBACK__)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- black bg
    local blackBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true})
    view:addChild(blackBg)

    -- back btton
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = _res(RES_DICT.BTN_BACK)})
    view:addChild(backBtn, 2)

    -------------------------------------------------
    -- team layer
    local teamLayer = display.newLayer()
    view:addChild(teamLayer, 1)

    -- team card site
    local teamCardSiteGapW = 160
    local teamCardSiteGapH = 90 + (size.height - 750)/2
    local teamCardSitePos  = cc.p(display.SAFE_L + 755, 400)
    local teamCardSiteList = {}
    for i = 1, TowerQuestModel.BATTLE_CARD_MAX do
        local cardSite = CreateTeamSiteView(i)
        cardSite.view:setPosition(teamCardSitePos.x - (i-1)*teamCardSiteGapW, teamCardSitePos.y + ((i+1)%2) * teamCardSiteGapH)
        teamLayer:addChild(cardSite.view)
        teamCardSiteList[i] = cardSite
    end

    local teamCardLayer = display.newLayer()
    teamLayer:addChild(teamCardLayer)

    -------------------------------------------------
    -- contract layer
    local contractLayer = display.newLayer()
    view:addChild(contractLayer)

    -------------------------------------------------
    -- library layer
    local libraryLayer = display.newLayer()
    view:addChild(libraryLayer)

    local libraryFrameSize = cc.size(1203 + display.SAFE_L/0.75 + 2, 469)
    libraryLayer:addChild(display.newImageView(_res(RES_DICT.LIBRARY_FRAME), -2, 30, {ap = display.LEFT_BOTTOM, scale = 0.75, scale9 = true, capInsets = cc.rect(0,0,1,1), size = libraryFrameSize}))

    -- library card
    local libraryCardFrameGapW = 135
    local libraryCardFrameGapH = 135
    local libraryCardFrameList = {}
    local libraryCardFramePos  = cc.p(display.SAFE_L + 205, 285)
    for i = 1, TowerQuestModel.LIBRARY_CARD_MAX do
        local cardAtRow = math.ceil(i / LIBRARY_COLS)
        local cardAtCol = (i-1) % LIBRARY_COLS + 1
        local cardPoint = cc.p(libraryCardFramePos.x + (cardAtCol-1) * libraryCardFrameGapW, libraryCardFramePos.y - (cardAtRow-1) * libraryCardFrameGapH)
        local cardFrame = display.newImageView(_res(RES_DICT.LCARD_CELL_BG), cardPoint.x, cardPoint.y, {scale = 0.65})
        local cardSize  = cardFrame:getContentSize()
        cardFrame:addChild(display.newImageView(_res(RES_DICT.LCARD_CELL_FA), cardSize.width/2, cardSize.height/2))
        libraryLayer:addChild(display.newImageView(_res(RES_DICT.LCARD_CELL_SL), cardPoint.x, cardPoint.y, {scale = 0.65}))
        libraryLayer:addChild(cardFrame)
        libraryCardFrameList[i] = cardFrame
    end

    -- library card layer
    local libraryCardLayer = display.newLayer()
    libraryLayer:addChild(libraryCardLayer)

    -- pSkill slot
    local pSkillSlotFrameList = {}
    local pSkillSlotFramePos  = cc.p(display.SAFE_L + 65, 295)
    for i = 1, TowerQuestModel.BATTLE_SKILL_MAX do
        local skillPoint = cc.p(pSkillSlotFramePos.x, pSkillSlotFramePos.y - (i-1) * libraryCardFrameGapH)
        local skillFrame = display.newImageView(_res(RES_DICT.PSKILL_FRAME), skillPoint.x, skillPoint.y, {enable = true, tag = i})
        local skillSize  = skillFrame:getContentSize()
        skillFrame:addChild(display.newImageView(_res(RES_DICT.ADD_ICON), skillSize.width/2, skillSize.height/2))
        libraryLayer:addChild(skillFrame)
        pSkillSlotFrameList[i] = skillFrame
    end

    -- pSkill slot layer
    local pSkillIconLayer = display.newLayer()
    libraryLayer:addChild(pSkillIconLayer)

    -------------------------------------------------
    -- bottom layer
    local bottomLayer = display.newLayer()
    view:addChild(bottomLayer)

    local tipsText = __('请选择出战飨灵与料理天赋。（注：签订霸者契约可以获得更多战利品哦~）')
    bottomLayer:addChild(display.newImageView(_res(RES_DICT.BOTTOM_FRAME), size.width/2, 0, {ap = display.CENTER_BOTTOM}))
    bottomLayer:addChild(display.newImageView(_res(RES_DICT.BTN_TIPS), display.SAFE_L + 30, 30))
    bottomLayer:addChild(display.newLabel(display.SAFE_L + 60, 30, fontWithColor(18, {ap = display.LEFT_CENTER, text = tipsText, w = 960 ,reqH = 50}  )))

    -- confirm button
    local confirmBtn = display.newButton(size.width/2 + 420, 50, {n = _res(RES_DICT.BTN_CONFIRM)})
    display.commonLabelParams(confirmBtn, fontWithColor(14, {text = __('确 定')}))
    bottomLayer:addChild(confirmBtn)

    return {
        view                 = view,
        blackBg              = blackBg,
        backBtn              = backBtn,
        teamLayer            = teamLayer,
        teamCardLayer        = teamCardLayer,
        teamCardSiteList     = teamCardSiteList,
        libraryLayer         = libraryLayer,
        libraryCardFrameList = libraryCardFrameList,
        pSkillSlotFrameList  = pSkillSlotFrameList,
        libraryCardLayer     = libraryCardLayer,
        pSkillIconLayer      = pSkillIconLayer,
        contractLayer        = contractLayer,
        contractView         = nil,
        bottomLayer          = bottomLayer,
        confirmBtn           = confirmBtn,
    }
end


CreateLibraryCardCell = function()
    local size = cc.size(122, 122)
    local view = display.newLayer(0, 0, {size = size, ap = display.CENTER})

    local headLayer = display.newLayer(0, 0, {size = size})
    view:addChild(headLayer)

    local selectLayer = display.newLayer(0, 0, {size = size})
    view:addChild(selectLayer)
    selectLayer:addChild(display.newLayer(size.width/2, size.height/2, {color = cc.c4b(0,0,0,150), size = cc.size(size.width-6, size.height-6), ap = display.CENTER}))
    selectLayer:addChild(display.newImageView(_res(RES_DICT.PCARD_CELL_S), size.width/2, size.height/2, {scale9 = true, size = cc.size(130,130)}))

    local warningLayer = display.newLayer(0, 0, {size = size})
    view:addChild(warningLayer)
    warningLayer:addChild(display.newImageView(_res(RES_DICT.PCARD_CELL_W), size.width/2, size.height/2, {scale9 = true, size = cc.size(138,138)}))

    local warningBar = display.newButton(size.width/2, size.height/2 - 35, {n = _res(RES_DICT.PCARD_BAR_W), enable = false})
    display.commonLabelParams(warningBar, fontWithColor(12))
    warningLayer:addChild(warningBar)

    local clickArea = display.newLayer(0, 0, {size = size, color = cc.c4b(0,0,0,0), enable = true})
    view:addChild(clickArea)

    return {
        view              = view,
        headLayer         = headLayer,
        cardHeadNode      = nil,
        selectLayer       = selectLayer,
        warningLayer      = warningLayer,
        warningBar        = warningBar,
        clickArea         = clickArea,
    }
end


CreateTeamSiteView = function(index)
    local size = cc.size(150, 260)
    local view = display.newLayer(0, 0, {size = size, ap = display.CENTER_BOTTOM})

    -- site image
    if index == 1 then
        view:addChild(display.newImageView(_res(RES_DICT.SITE_CAPTAIN), size.width/2, 0, {ap = display.CENTER_BOTTOM}))
        view:addChild(display.newImageView(_res(RES_DICT.ICON_SITE_C), size.width/2 + 88, 10, {ap = display.CENTER}))
    else
        view:addChild(display.newImageView(_res(RES_DICT.SITE_MEMBER), size.width/2, 0, {ap = display.CENTER_BOTTOM}))
    end

    -- site light
    local siteLight = display.newImageView(_res(RES_DICT.SITE_LIGHT), size.width/2, 22, {ap = display.CENTER_BOTTOM})
    view:addChild(siteLight)
    view:runAction(cc.Sequence:create({
        cc.DelayTime:create(index * 0.1 + 0.01),
        cc.CallFunc:create(function()
            siteLight:runAction(cc.RepeatForever:create(cc.Sequence:create({
                cc.FadeTo:create(1, 150),
                cc.FadeTo:create(1, 255),
            })))
        end)
    }))

    local dragAreaSize  = cc.size(size.width - 20, size.height - 40)
    local dragAreaLayer = display.newLayer(size.width/2, size.height/2 - 11, {size = dragAreaSize, ap = display.CENTER})
    view:addChild(dragAreaLayer)

    return {
        view          = view,
        siteLight     = siteLight,
        dragAreaLayer = dragAreaLayer
    }
end


CreateCardSpineView = function()
    local size = cc.size(150, 260)
    local view = display.newLayer(0, 0, {size = size, ap = display.CENTER_BOTTOM})

    -- spine layer
    local spineLayer = display.newLayer(size.width/2, 25)
    spineLayer:setCascadeOpacityEnabled(true)
    view:addChild(spineLayer)

    -- skill frame
    local skillFrame = display.newImageView(_res(RES_DICT.CSKILL_FRAME), size.width/2, 18, {scale = 0.65})
    view:addChild(skillFrame)

    -- skill layer
    local skillLayer = display.newLayer(skillFrame:getPositionX(), skillFrame:getPositionY())
    view:addChild(skillLayer)

    -- warning bar
    local warningBar = display.newButton(size.width/2, size.height/2 - 35, {n = _res(RES_DICT.PCARD_BAR_W), enable = false})
    display.commonLabelParams(warningBar, fontWithColor(12))
    view:addChild(warningBar)

    return {
        view       = view,
        spineLayer = spineLayer,
        cardSpine  = nil,
        skillFrame = skillFrame,
        skillLayer = skillLayer,
        warningBar = warningBar,
    }
end


function TowerQuestEditCardTeamView:getViewData()
    return self.viewData_
end


function TowerQuestEditCardTeamView:createLibraryCardCell()
    return CreateLibraryCardCell()
end


function TowerQuestEditCardTeamView:createCardSpineView(cardId)
    local cardSpineView = CreateCardSpineView()
    if checkint(cardId) > 0 then
		local cardInfo  = gameMgr:GetCardDataByCardId(cardId)
        local skinId    = cardInfo.defaultSkinId
        local cardSpine = AssetsUtils.GetCardSpineNode({skinId = skinId, cacheName = SpineCacheName.TOWER, spineName = skinId})
        cardSpine:update(0)
        cardSpine:setScale(0.45)
        cardSpine:setAnimation(0, 'idle', true)
        cardSpineView.cardSpine = cardSpine
        cardSpineView.spineLayer:addChild(cardSpine)
    end
    return cardSpineView
end


function TowerQuestEditCardTeamView:showView(endCb1, endCb2)
    if self.viewData_.contractView then
        self.viewData_.contractView:setScaleY(0)
    end

    local actionTime = 0.3

    local cardSiteActList = {}
    for i = 1, TowerQuestModel.BATTLE_CARD_MAX do
        local cardSite = self.viewData_.teamCardSiteList[i]
        if cardSite then
            table.insert(cardSiteActList, cc.TargetedAction:create(cardSite.view, cc.Sequence:create({
                cc.DelayTime:create(0.1 + i*0.05),
                cc.ScaleTo:create(0.1, 1)
            })))
        end
    end

    self:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.viewData_.blackBg, cc.FadeTo:create(actionTime, 150)),
            cc.TargetedAction:create(self.viewData_.bottomLayer, cc.MoveTo:create(actionTime, cc.p(0, 0))),
            cc.TargetedAction:create(self.viewData_.libraryLayer, cc.EaseCubicActionOut:create(cc.ScaleTo:create(actionTime, 1))),
            self.viewData_.contractView and cc.TargetedAction:create(self.viewData_.contractView, cc.EaseCubicActionOut:create(cc.ScaleTo:create(actionTime, 1))) or nil,
        }),
        cc.CallFunc:create(function()
            if endCb1 then endCb1() end
        end),
        cc.Spawn:create(cardSiteActList),
        cc.DelayTime:create(0.05),
        cc.CallFunc:create(function()
            if endCb2 then endCb2() end
        end),
    }))
end


function TowerQuestEditCardTeamView:hideView(endCb)
    local actionTime = 0.2
    self:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.viewData_.blackBg, cc.FadeTo:create(actionTime, 0)),
            cc.TargetedAction:create(self.viewData_.teamLayer, cc.FadeTo:create(actionTime, 0)),
            cc.TargetedAction:create(self.viewData_.bottomLayer, cc.MoveTo:create(actionTime, cc.p(0, -200))),
            cc.TargetedAction:create(self.viewData_.libraryLayer, cc.EaseCubicActionOut:create(cc.ScaleTo:create(actionTime, 0))),
            self.viewData_.contractView and cc.TargetedAction:create(self.viewData_.contractView, cc.EaseCubicActionOut:create(cc.ScaleTo:create(actionTime, 1, 0))) or nil,
        }),
        cc.CallFunc:create(function()
            if endCb then endCb() end
        end)
    }))
end


return TowerQuestEditCardTeamView
