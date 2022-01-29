--[[
 * author : panmeng
 * descpt : 皮肤收集 - 飨灵皮肤展示
]]

local CommonDialog   = require('common.CommonDialog')
local SkinDisplayPopup = class('SkinDisplayPopup', CommonDialog)    

local RES_DICT = {
    COM_BACK_BTN    = _res('ui/common/common_btn_back.png'),
    SKIN_NAME_BG    = _res('ui/collection/skinCollection/draw_card_bg_name.png'),
    CHANGE_BTN      = _res('ui/collection/skinCollection/pokedex_card_btn_story_default.png'),
    STORY_BTN       = _res('ui/collection/skinCollection/allround_ico_book_4.png'),
    CARD_BG         = _res('ui/collection/skinCollection/draw_card_bg.png'),
}


function SkinDisplayPopup:InitialUI()
    self:setPosition(display.center)

    -- create view
    self.viewData = SkinDisplayPopup.CreateView(self.args)
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_), false)
    ui.bindClick(self:getViewData().changeBtn, handler(self, self.onClickChangeSkinBtnHandler_), false)
    ui.bindClick(self:getViewData().spineBlockLayer, handler(self, self.onClickSpineBtnHandler_), false)
    ui.bindClick(self:getViewData().storyBtn, handler(self, self.onClickStoryBtnHandler_), false)
end


function SkinDisplayPopup:getViewData()
    return self.viewData
end



-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function SkinDisplayPopup.CreateView(data)
    local view = ui.layer()

    -- skinBg
    local skinBg = ui.image({img = RES_DICT.CARD_BG, isFull = true})
    view:addList(skinBg):alignTo(nil, ui.cc)

    -- skin png
    local skinDrawNode = require('common.CardSkinDrawNode').new({skinId = data.skinId, coordinateType = COORDINATE_TYPE_CAPSULE})
    view:add(skinDrawNode)

    skinDrawNodeAvator = skinDrawNode:GetAvatar()
    if skinDrawNodeAvator then
        skinDrawNodeAvator:setPosition(cc.rep(cc.p(skinDrawNodeAvator:getPosition()), display.width / 2 - 500, 0))
    end

    skinDrawNodeSpine = skinDrawNode:GetSpine()
    if skinDrawNodeSpine then
        skinDrawNodeSpine:setPosition(cc.rep(cc.p(skinDrawNodeSpine:getPosition()), display.width / 2 - 500, 0))
    end


    -- skin spine
    local spineBlockLayer = ui.layer({size = cc.size(420, 500), color = cc.r4b(0), enable = true})
    view:addList(spineBlockLayer):alignTo(nil, ui.cc, {offsetY = - 50, offsetX = -50})
    spineBlockLayer:setVisible(false)

    local cardSpine = AssetsUtils.GetCardSpineNode({skinId = checkint(data.skinId)})
    cardSpine:setAnimation(0, 'idle', true)
    cardSpine:setTag(1)
    spineBlockLayer:addList(cardSpine):alignTo(nil, ui.cc, {offsetY = 150, offsetX = display.width / 2 - 50})


    -- back button
    local backBtn = ui.button({n = RES_DICT.COM_BACK_BTN})
    view:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 35, offsetY = -15})

    -- change btn
    local changeBtn = ui.button({n = RES_DICT.CHANGE_BTN}):updateLabel({fontSize = 48, text = __("Q版"), offset = cc.p(0, - 50)})
    view:addList(changeBtn):alignTo(nil, ui.lb, {offsetY = 50, offsetX = display.SAFE_L + 35})
    changeBtn:setScale(0.5)

    -- SkinName
    local skinConf = checktable(CardUtils.GetCardSkinConfig(checkint(data.skinId)))
    local skinNameLabel = ui.title({n = RES_DICT.SKIN_NAME_BG, ap = ui.cc}):updateLabel({fnt = FONT.D2, fontSize = 30, color = "#ffe155", text = tostring(skinConf.name), paddingW = 100, offset = cc.p(-50,0)})
    view:addList(skinNameLabel):alignTo(nil, ui.rt, {offsetY = -140, offsetX = -70 - display.SAFE_L})

    -- skinType icon
    local imgType = ui.image({img = CardUtils.GetCardSkinTypeIconPathBySkinType(data.skinType)})
    view:addList(imgType):alignTo(skinNameLabel, ui.lc, {offsetX = 30})

    -- CardName
    local cardConf = checktable(CONF.CARD.CARD_INFO:GetValue(skinConf.cardId))
    local cardNameLabel = ui.label({fnt = FONT.D2, color = "#ffffff", text = tostring(cardConf.name), ap = ui.cc})
    view:addList(cardNameLabel):alignTo(skinNameLabel, ui.cb, {offsetY = -30, offsetX = -25})

    local descr         = skinConf.descr
    local finalStr      = '“'
    local skinNameIndex = string.find(descr, finalStr)

    if checkint(skinNameIndex) > 0 then
        descr = string.sub(descr, (skinNameIndex + #finalStr), string.len(descr) - #finalStr)
    end
    local cardDescrLabel = ui.label({text = tostring(descr), fnt = FONT.D7, fontSize = 22, w = 410, hAlign = cc.TEXT_ALIGNMENT_CENTER})
    cardDescrLabel:setLineSpacing(10)
    view:addList(cardDescrLabel):alignTo(nil, ui.rc, {offsetX = -display.SAFE_L - 30})

    -- time
    local localTimestamp = checkint(data.getTime) - getServerTimezone() + getClientTimezone()
    local dataLabel = ui.label({fnt = FONT.D7, fontSize = 22, text = os.date('%Y.%m.%d', localTimestamp), p = cc.p(cardNameLabel:getPositionX(), 140)})
    view:add(dataLabel)
    dataLabel:setVisible(false)

    -- storyBtn
    local storyBtn = ui.button({n = RES_DICT.STORY_BTN, ap = ui.lc})
    storyBtn:setScale(0.35)
    view:addList(storyBtn):alignTo(dataLabel, ui.rc, {offsetX = 15})

    local storyConfig = CommonUtils.GetConfig('skinCarnival', 'skinStory', checkint(data.skinId))
    local isSkinStoryExist = storyConfig ~= nil
    storyBtn:setVisible(false)

    return {
        view             = view,
        backBtn          = backBtn,
        drawingImg       = skinDrawNode,
        spineBlockLayer  = spineBlockLayer,
        changeBtn        = changeBtn,
        cardSpine        = cardSpine,
        storyBtn         = storyBtn,
        isSkinStoryExist = isSkinStoryExist, 
        dataLabel        = dataLabel,
    }
end

-------------------------------------------------------------------------------
-- handler
-------------------------------------------------------------------------------
function SkinDisplayPopup:onClickBackButtonHandler_(sender)
    PlayAudioByClickNormal()

    self:CloseHandler()
end


function SkinDisplayPopup:onClickChangeSkinBtnHandler_(sender)
    PlayAudioByClickNormal()

    local visible = self:getViewData().spineBlockLayer:isVisible()
    self:getViewData().spineBlockLayer:setVisible(not visible)
    self:getViewData().drawingImg:setVisible(visible)

    self:getViewData().storyBtn:setVisible(not visible and self:getViewData().isSkinStoryExist)
    self:getViewData().dataLabel:setVisible(not visible)

    local btnText = visible and __("Q版") or __("立绘")
    self:getViewData().changeBtn:setText(btnText)
end

function SkinDisplayPopup:onClickSpineBtnHandler_(sender)
    PlayAudioByClickNormal()

    local spineAnimIndex = checkint(self:getViewData().cardSpine:getTag())
    local actionList = {'idle','run','attack','skill1','skill2'}

    spineAnimIndex = spineAnimIndex + 1
    if spineAnimIndex > 5 then
        spineAnimIndex = 1
    end
    self:getViewData().cardSpine:setTag(spineAnimIndex)
    self:getViewData().cardSpine:setToSetupPose()
    --local spineAnimIndex = math.random(1, 5)
    self:getViewData().cardSpine:setAnimation(0, actionList[spineAnimIndex], true)
end

function SkinDisplayPopup:onClickStoryBtnHandler_(sender)
    PlayAudioByClickNormal()

    local storyConfig = CommonUtils.GetConfig('skinCarnival', 'skinStory', checkint(self.args.skinId))
    local skinConf = checktable(CardUtils.GetCardSkinConfig(checkint(self.args.skinId)))
    app.uiMgr:AddDialog("Game.views.activity.skinCarnival.ActivitySkinCarnivalStoryPopup", {title = tostring(skinConf.name), story = storyConfig.descr, skinId = self.args.skinId})
end


return SkinDisplayPopup
