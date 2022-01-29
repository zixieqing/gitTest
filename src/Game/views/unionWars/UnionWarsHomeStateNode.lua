--[[
 * author : kaishiqi
 * descpt : 工会战 - 主界面场景
]]
local UnionWarsHomeStateNode = class('UnionWarsHomeStateNode', function()
    return display.newLayer(0, 0, {name = 'Game.views.unionWars.UnionWarsHomeStateNode'})
end)

local RES_DICT = {
    STAE_INFO_BAR = _res('ui/union/wars/home/gvg_title_state_bg.png'),
    HP_EMPTY_BAR  = _res('ui/union/wars/home/gvg_hp_line_bottom.png'),
    HP_UNION_BAR  = _res('ui/union/wars/home/gvg_hp_line_yellow.png'),
    HP_ENEMY_BAR  = _res('ui/union/wars/home/gvg_hp_line_red.png'),
}

local CreateView = nil
local TIME_GAP_X = 30


function UnionWarsHomeStateNode:ctor(args)
    local initArgs = checktable(args)
    self:setPositionX(checkint(initArgs.x))
    self:setPositionY(checkint(initArgs.y))
    self:setAnchorPoint(initArgs.ap or display.CENTER)

    -- create views
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)
    
    -- init views
    self:setContentSize(self:getViewData().view:getContentSize())
    self.contentSizeW_ = self:getContentSize().width
    self:setShowHP(false)
    self:setHpProgress(0)
end


CreateView = function()
    local view = display.newLayer(0, 0, {bg = RES_DICT.STAE_INFO_BAR})
    local size = view:getContentSize()

    local stateLabel = display.newLabel(size.width/2, size.height/2 + 16, fontWithColor(1, {fontSize = 24, color = '#91553A', ap = display.LEFT_CENTER}))
    view:addChild(stateLabel)

    local timeLabel = display.newLabel(size.width/2, stateLabel:getPositionY(), fontWithColor(14, {fontSize = 24, color = '#FFCE49', ap = display.LEFT_CENTER}))
    view:addChild(timeLabel)

    -------------------------------------------------
    local hpInfoLayer = display.newLayer()
    view:addChild(hpInfoLayer)

    local unionHpBar = CProgressBar:create(RES_DICT.HP_UNION_BAR)
    unionHpBar:setBackgroundImage(RES_DICT.HP_EMPTY_BAR)
    unionHpBar:setDirection(eProgressBarDirectionLeftToRight)
    unionHpBar:setPositionX(size.width/2)
    unionHpBar:setPositionY(22)
    unionHpBar:setMaxValue(100)
    hpInfoLayer:addChild(unionHpBar)
    
    local enemyHpBar = CProgressBar:create(RES_DICT.HP_ENEMY_BAR)
    enemyHpBar:setBackgroundImage(RES_DICT.HP_EMPTY_BAR)
    enemyHpBar:setDirection(eProgressBarDirectionLeftToRight)
    enemyHpBar:setPositionX(unionHpBar:getPositionX())
    enemyHpBar:setPositionY(unionHpBar:getPositionY())
    enemyHpBar:setMaxValue(100)
    hpInfoLayer:addChild(enemyHpBar)

    local hpNumLable = display.newLabel(unionHpBar:getPositionX(), unionHpBar:getPositionY(), fontWithColor(20, {fontSize = 24}))
    hpInfoLayer:addChild(hpNumLable)

    return {
        view        = view,
        stateLabel  = stateLabel,
        timeLabel   = timeLabel,
        hideHPInfoY = size.height/2,
        showHPInfoY = stateLabel:getPositionY(),
        hpInfoLayer = hpInfoLayer,
        unionHpBar  = unionHpBar,
        enemyHpBar  = enemyHpBar,
        hpNumLable  = hpNumLable,
    }
end


-------------------------------------------------
-- get / set

function UnionWarsHomeStateNode:getViewData()
    return self.viewData_
end


function UnionWarsHomeStateNode:isShowHP()
    return self.isShowHP_
end
function UnionWarsHomeStateNode:setShowHP(isShow, isViewEnemy)
    self.isShowHP_ = isShow == true

    local viewData = self:getViewData()
    viewData.stateLabel:setPositionY(self.isShowHP_ and viewData.showHPInfoY or viewData.hideHPInfoY)
    viewData.timeLabel:setPositionY(self.isShowHP_ and viewData.showHPInfoY or viewData.hideHPInfoY)
    viewData.hpInfoLayer:setVisible(self.isShowHP_)
    viewData.unionHpBar:setVisible(isViewEnemy ~= true)
    viewData.enemyHpBar:setVisible(isViewEnemy == true)
end


function UnionWarsHomeStateNode:setHpProgress(progress, maxValue)
    local maxProgress = checkint(maxValue)
    local curProgress = math.min(maxProgress, checkint(progress))
    local percentNum  = maxProgress > 0 and curProgress / maxProgress * 100 or 0
    local viewData    = self:getViewData()
    viewData.unionHpBar:setValue(math.min(viewData.unionHpBar:getMaxValue(), percentNum))
    viewData.enemyHpBar:setValue(math.min(viewData.enemyHpBar:getMaxValue(), percentNum))
    display.commonLabelParams(viewData.hpNumLable, {text = string.fmt('%1 %', checkint(percentNum))})
end


function UnionWarsHomeStateNode:setStateTitle(title)
    display.commonLabelParams(self:getViewData().stateLabel, {text = tostring(title)})
    self:updateInfoLabelPos_()
end


function UnionWarsHomeStateNode:setStateTime(time)
    local timeStr = checkint(time) > 0 and CommonUtils.getTimeFormatByType(time, 3) or '--:--:--'
    display.commonLabelParams(self:getViewData().timeLabel, {text = timeStr})
    self:updateInfoLabelPos_()
end


-------------------------------------------------
-- private

function UnionWarsHomeStateNode:updateInfoLabelPos_()
    local stateLabelSize = display.getLabelContentSize(self:getViewData().stateLabel)
    local timeLabelSize  = display.getLabelContentSize(self:getViewData().timeLabel)
    local infoLabelWidth = stateLabelSize.width + timeLabelSize.width + TIME_GAP_X
    local infoLabelOffX  = (self.contentSizeW_ - infoLabelWidth) / 2
    self:getViewData().stateLabel:setPositionX(infoLabelOffX)
    self:getViewData().timeLabel:setPositionX(infoLabelOffX + stateLabelSize.width + TIME_GAP_X)
end


return UnionWarsHomeStateNode
