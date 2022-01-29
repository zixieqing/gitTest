--[[
 * author : kaishiqi
 * descpt : 工会派对 - boss挑战视图
]]
local UnionPartyBossQuestView = class('UnionPartyBossQuestView', function()
    return display.newLayer(0, 0, {name = 'Game.views.union.UnionPartyBossQuestView'})
end)

local RES_DICT = {
    NAME_BAR       = 'ui/union/party/party/common_bg_title_4.png',
    TIME_BAR       = 'ui/union/party/party/guild_party_bg_battle_time.png',
    FRAME_RESULT   = 'ui/union/party/party/guild_party_bg_battle_wait_result.png',
    FRAME_BATTLE   = 'ui/union/party/party/guild_party_bg_battle.png',
    PROGRESS_BAR_D = 'ui/union/party/party/guild_hunt_bg_blood.png',
    PROGRESS_BAR_S = 'ui/union/party/party/guild_hunt_bg_loading_blood.png',
}

local CreateView     = nil


function UnionPartyBossQuestView:ctor(args)
    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -------------------------------------------------
    -- quest layer
    local questLayer = display.newLayer()
    view:addChild(questLayer)
    questLayer:addChild(display.newImageView(_res(RES_DICT.FRAME_BATTLE), display.SAFE_R + 60, -3, {ap = display.RIGHT_BOTTOM, enable = true}))

    local questFightBtn = require('common.CommonBattleButton').new()
    questFightBtn:setPosition(display.SAFE_R - 96, 135)
    questLayer:addChild(questFightBtn)

    local questTimeBrand = display.newLabel(questFightBtn:getPositionX(), 40, fontWithColor(16, {fontSize = 18, text = __('驱赶剩余时间')}))
    questLayer:addChild(questTimeBrand)

    local questTimeLabel = display.newButton(questTimeBrand:getPositionX(), questTimeBrand:getPositionY() - 25, {n = _res(RES_DICT.TIME_BAR), enable = false})
    display.commonLabelParams(questTimeLabel, fontWithColor(14))
    questLayer:addChild(questTimeLabel)

    
    -------------------------------------------------
    -- result layer
    local resultLayer = display.newLayer()
    view:addChild(resultLayer)
    resultLayer:addChild(display.newImageView(_res(RES_DICT.FRAME_RESULT), display.SAFE_R + 60, -3, {ap = display.RIGHT_BOTTOM, enable = true}))

    local resultTextBrand = display.newLabel(display.SAFE_R - 90, 75, fontWithColor(7, {fontSize = 30, text = __('结算中...')}))
    resultLayer:addChild(resultTextBrand)

    local resultTimeBrand = display.newLabel(display.SAFE_R - 170, 20, fontWithColor(16, {fontSize = 20, text = __('结算剩余时间')}))
    resultLayer:addChild(resultTimeBrand)

    local resultTimeLabel = display.newLabel(resultTimeBrand:getPositionX() + 110, resultTimeBrand:getPositionY(), fontWithColor(14))
    resultLayer:addChild(resultTimeLabel)


    -------------------------------------------------
    -- fail layer
    local failLayer = display.newLayer()
    view:addChild(failLayer)
    failLayer:addChild(display.newImageView(_res(RES_DICT.FRAME_RESULT), display.SAFE_R + 60, -3, {ap = display.RIGHT_BOTTOM, enable = true}))

    local failTextBrand = display.newLabel(resultTextBrand:getPositionX(), resultTextBrand:getPositionY(), fontWithColor(7, {fontSize = 30, text = __('驱赶失败')}))
    failLayer:addChild(failTextBrand)

    local failTimeBrand = display.newLabel(resultTimeBrand:getPositionX(), resultTimeBrand:getPositionY(), fontWithColor(16, {fontSize = 20, text = __('回合剩余时间')}))
    failLayer:addChild(failTimeBrand)

    local failTimeLabel = display.newLabel(resultTimeLabel:getPositionX(), resultTimeLabel:getPositionY(), fontWithColor(14))
    failLayer:addChild(failTimeLabel)


    -------------------------------------------------
    -- common layer
    local commonLayer = display.newLayer()
    view:addChild(commonLayer)

    local questTargetPos = cc.p(display.SAFE_R - 450, 105)
    local questTargetBar = display.newButton(questTargetPos.x, questTargetPos.y, {n = _res(RES_DICT.NAME_BAR), enable = false})
    display.commonLabelParams(questTargetBar, fontWithColor(18, {text = __('任务目标'), paddingW = 50}))
    commonLayer:addChild(questTargetBar)

    local questTargetLabel = display.newLabel(questTargetPos.x, questTargetPos.y - 32, fontWithColor(16))
    commonLayer:addChild(questTargetLabel)

    local questTargetBrand = display.newLabel(display.SAFE_R - 575, 40, {fontSize = 22, color = '#775F52', text = __('目标进度'), ap = display.RIGHT_CENTER})
    commonLayer:addChild(questTargetBrand)

    local questProgressPos = cc.p(questTargetBrand:getPositionX() + 10, questTargetBrand:getPositionY())
    local questProgressBar = CProgressBar:create(_res(RES_DICT.PROGRESS_BAR_S))
    questProgressBar:setBackgroundImage(_res(RES_DICT.PROGRESS_BAR_D))
    questProgressBar:setDirection(eProgressBarDirectionLeftToRight)
    questProgressBar:setAnchorPoint(display.LEFT_CENTER)
    questProgressBar:setPosition(questProgressPos)
    questProgressBar:setMaxValue(100)
    questProgressBar:setValue(0)
    commonLayer:addChild(questProgressBar)

    local questProgressLabel = display.newLabel(questProgressPos.x + questProgressBar:getContentSize().width/2, questProgressPos.y, fontWithColor(14))
    commonLayer:addChild(questProgressLabel)
    
    return {
        view               = view,
        questLayer         = questLayer,
        questFightBtn      = questFightBtn,
        questTimeLabel     = questTimeLabel,
        resultLayer        = resultLayer,
        resultTimeLabel    = resultTimeLabel,
        failLayer          = failLayer,
        failTimeLabel      = failTimeLabel,
        commonLayer        = commonLayer,
        questTargetLabel   = questTargetLabel,
        questProgressBar   = questProgressBar,
        questProgressLabel = questProgressLabel,
    }
end


function UnionPartyBossQuestView:getViewData()
    return self.viewData_
end


function UnionPartyBossQuestView:updateQuestTime(time)
    local questTimeLabel = self:getViewData().questTimeLabel
    local questTimeTable = string.formattedTime(checkint(time))
    local questTimeText  = string.format('%02d:%02d', questTimeTable.m, questTimeTable.s)
    display.commonLabelParams(questTimeLabel, {text = questTimeText})
end


function UnionPartyBossQuestView:updateResultTime(time)
    local resultTimeLabel = self:getViewData().resultTimeLabel
    local resultTimeTable = string.formattedTime(checkint(time))
    local resultTimeText  = string.format('%02d:%02d', resultTimeTable.m, resultTimeTable.s)
    display.commonLabelParams(resultTimeLabel, {text = resultTimeText})
end


function UnionPartyBossQuestView:updateEndedTime(time)
    local failTimeLabel = self:getViewData().failTimeLabel
    local failTimeTable = string.formattedTime(checkint(time))
    local failTimeText  = string.format('%02d:%02d', failTimeTable.m, failTimeTable.s)
    display.commonLabelParams(failTimeLabel, {text = failTimeText})
end


function UnionPartyBossQuestView:updateQuestTargetDescr(descr)
    local viewData = self:getViewData()
    display.commonLabelParams(viewData.questTargetLabel, {text = tostring(descr)})
end


function UnionPartyBossQuestView:updateQuestProgressMax(max)
    local progressNum = self:getViewData().questProgressBar:getValue()
    self:getViewData().questProgressBar:setMaxValue(math.max(1, checkint(max)))
    self:getViewData().questProgressBar:setName(tostring(max))
    self:updateQuestProgressLabel_(progressNum, value)
end
function UnionPartyBossQuestView:updateQuestProgressNum(value)
    local progressMax = checkint(self:getViewData().questProgressBar:getName())
    self:getViewData().questProgressBar:setValue(math.min(progressMax, checkint(value)))
    self:updateQuestProgressLabel_(value, progressMax)
end
function UnionPartyBossQuestView:updateQuestProgressLabel_(num, max)
    display.commonLabelParams(self:getViewData().questProgressLabel, {text = string.fmt('%1 / %2', num, max)})
end


return UnionPartyBossQuestView
