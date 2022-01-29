--[[
 * author : kaishiqi
 * descpt : 世界BOSS历史中介者
]]
local WorldBossConfigParser    = require('Game.Datas.Parser.WorldBossQuestConfigParser')
local WorldBossQuestConfs      = CommonUtils.GetConfigAllMess(WorldBossConfigParser.TYPE.QUEST, 'worldBossQuest') or {}
local WorldBossHistoryMediator = class('WorldBossHistoryMediator', mvc.Mediator)

local RES_DICT = {
    BG_FRAME     = 'ui/common/common_bg_3.png',
    TITLE_FRAME  = 'ui/common/common_bg_title_2.png',
    LIST_FRAME_N = 'ui/common/common_bg_list.png',
    LIST_FRAME_S = 'ui/common/common_bg_list_unselected.png',
    HEAD_FRAME   = 'ui/worldboss/main/common_frame_goods_8.png',
    DAMAGE_BAR   = 'ui/home/rank/restaurant_info_bg_rank_awareness.png',
}

local CreateView     = nil
local CreateBossCell = nil


function WorldBossHistoryMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'WorldBossHistoryMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function WorldBossHistoryMediator:Initial(key)
    self.super.Initial(self, key)

    self.bossCellDict_   = {}
    self.isControllable_ = true
    
    -- create view
    self.viewData_   = CreateView()
    local uiManager  = self:GetFacade():GetManager('UIManager')
    self.ownerScene_ = uiManager:GetCurrentScene()
    self.ownerScene_:AddDialog(self.viewData_.view)

    -- init view
    display.commonUIParams(self.viewData_.blackBg, {cb = handler(self, self.onClickBlackBgHandler_), animate = false})
    self.viewData_.bossGridView:setDataSourceAdapterScriptHandler(handler(self, self.onBossGridDataAdapterHandler_))

    -- show ui
    self:show()
end


function WorldBossHistoryMediator:CleanupView()
    if self.ownerScene_ and self:getViewData().view:getParent() then
        self.ownerScene_:RemoveDialog(self:getViewData().view)
        self.ownerScene_ = nil
    end
end


function WorldBossHistoryMediator:OnRegist()
    regPost(POST.WORLD_BOSS_DAMAGE_HISTORY, true)
    self:SendSignal(POST.WORLD_BOSS_DAMAGE_HISTORY.cmdName)
end
function WorldBossHistoryMediator:OnUnRegist()
    unregPost(POST.WORLD_BOSS_DAMAGE_HISTORY)
end


function WorldBossHistoryMediator:InterestSignals()
    return {
        POST.WORLD_BOSS_DAMAGE_HISTORY.sglName
    }
end
function WorldBossHistoryMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.WORLD_BOSS_DAMAGE_HISTORY.sglName then
        local hasError = checkint(data.errcode) ~= 0
        if hasError then
            self:close()
        else
            local historyData    = {}
            local damageValueMap = checktable(data.damage)
            for bossId, damageValue in pairs(damageValueMap) do
                table.insert(historyData, {bossId = checkint(bossId), damage = checkint(damageValue)})
            end
            self:setBossHistoryData(historyData)
        end
    end
end


-------------------------------------------------
-- view defines

CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    -- black bg
    local blackBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true, coEnable = true})
    blackBg:setOpacity(150)
    view:addChild(blackBg)

    -- list layer
    local listLayer = display.newLayer(size.width/2, size.height/2, {bg = _res(RES_DICT.BG_FRAME), enable = true, ap = display.CENTER})
    local frameSize = listLayer:getContentSize()
    view:addChild(listLayer)
    
    -- titleBar
    local titleBar = display.newButton(frameSize.width/2, frameSize.height - 22, {n = _res(RES_DICT.TITLE_FRAME), scale9 = true, enable = false})
    display.commonLabelParams(titleBar, fontWithColor(3, {text = __('最高伤害'), paddingW = 50}))
    listLayer:addChild(titleBar)
    
    -- boss gridView
    local bossGridSize  = cc.size(frameSize.width - 48, frameSize.height - 56)
    local bossGridPoint = cc.p(frameSize.width/2, frameSize.height/2 - 18)
    local bossGridView  = CGridView:create(bossGridSize)
    bossGridView:setSizeOfCell(cc.size(bossGridSize.width, 100))
    bossGridView:setAnchorPoint(display.CENTER)
    bossGridView:setPosition(bossGridPoint)
    bossGridView:setColumns(1)
    listLayer:addChild(bossGridView)

    -- empty label
    local emptyLabel = display.newLabel(bossGridPoint.x, bossGridPoint.y, fontWithColor(1, {text = __('暂无伤害数据')}))
    listLayer:addChild(emptyLabel)

    return {
        view         = view,
        blackBg      = blackBg,
        listLayer    = listLayer,
        emptyLabel   = emptyLabel,
        bossGridView = bossGridView,
    }
end


CreateBossCell = function(size)
    local view = CGridViewCell:new()
    view:setCascadeOpacityEnabled(true)
    view:setContentSize(size)

    local bgImgSize = cc.size(size.width - 4, size.height - 4)
    local normalImg = display.newImageView(_res(RES_DICT.LIST_FRAME_N), size.width/2, size.height/2, {scale9 = true, size = bgImgSize})
    local selectImg = display.newImageView(_res(RES_DICT.LIST_FRAME_S), size.width/2, size.height/2, {scale9 = true, size = bgImgSize})
    view:addChild(normalImg)
    view:addChild(selectImg)
    
    local headFrame = display.newImageView(_res(RES_DICT.HEAD_FRAME), size.height/2, size.height/2)
    view:addChild(headFrame)
    
    local headLayer = display.newLayer(headFrame:getPositionX(), headFrame:getPositionY())
    headLayer:setScale(0.42)
    view:addChild(headLayer)

    local nameLabel = display.newLabel(headFrame:getPositionX() + headFrame:getContentSize().width/2 + 5, size.height/2, fontWithColor(3, {ap = display.LEFT_CENTER, color = "4c4c4c"}))
    view:addChild(nameLabel)

    local damageBar = display.newButton(size.width - 2, size.height/2, {n = _res(RES_DICT.DAMAGE_BAR), ap = display.RIGHT_CENTER, scale9 = true, capInsets = cc.rect(15,15,120,70)})
    display.commonLabelParams(damageBar, fontWithColor(14))
    view:addChild(damageBar)

    local clickArea = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(clickArea)
    
    return {
        view      = view,
        normalImg = normalImg,
        selectImg = selectImg,
        headLayer = headLayer,
        nameLabel = nameLabel,
        damageBar = damageBar,
        clickArea = clickArea,
    }
end


-------------------------------------------------
-- get / set

function WorldBossHistoryMediator:getViewData()
    return self.viewData_
end


function WorldBossHistoryMediator:getBossHistoryData()
    return self.bossHistoryData_ or {}
end
function WorldBossHistoryMediator:setBossHistoryData(data)
    self.bossHistoryData_ = checktable(data)
    
    local bossGridView = self:getViewData().bossGridView
    bossGridView:setCountOfCell(#self:getBossHistoryData())
    bossGridView:reloadData()

    local isEmptyData = bossGridView:getCountOfCell() == 0
    self:getViewData().emptyLabel:setVisible(isEmptyData)
    bossGridView:setVisible(not isEmptyData)
end


-------------------------------------------------
-- public method

function WorldBossHistoryMediator:show()
    local actionTime     = 0.1
    self.isControllable_ = false
    self.viewData_.blackBg:setOpacity(0)
    self.viewData_.listLayer:setScale(0)
    self.viewData_.listLayer:setOpacity(0)
    
    self.viewData_.view:stopAllActions()
    self.viewData_.view:runAction(cc.Sequence:create({
        cc.Spawn:create(
            cc.TargetedAction:create(self.viewData_.blackBg, cc.FadeTo:create(actionTime, 150)),
            cc.TargetedAction:create(self.viewData_.listLayer, cc.FadeIn:create(actionTime)),
            cc.TargetedAction:create(self.viewData_.listLayer, cc.ScaleTo:create(actionTime, 1))
        ),
        cc.CallFunc:create(function()
            self.isControllable_ = true
        end)
    }))
end
function WorldBossHistoryMediator:hide()
    local actionTime     = 0.1
    self.isControllable_ = false
    self.viewData_.blackBg:setOpacity(150)
    self.viewData_.listLayer:setScale(1)
    self.viewData_.listLayer:setOpacity(255)
    
    self.viewData_.view:stopAllActions()
    self.viewData_.view:runAction(cc.Sequence:create({
        cc.Spawn:create(
            cc.TargetedAction:create(self.viewData_.blackBg, cc.FadeOut:create(actionTime)),
            cc.TargetedAction:create(self.viewData_.listLayer, cc.FadeOut:create(actionTime)),
            cc.TargetedAction:create(self.viewData_.listLayer, cc.ScaleTo:create(actionTime, 0))
        ),
        cc.CallFunc:create(function()
            self:GetFacade():UnRegsitMediator(self:GetMediatorName())
        end)
    }))
end


-------------------------------------------------
-- private method


function WorldBossHistoryMediator:updateBossCell_(index, cellViewData)
    local bossGridView  = self:getViewData().bossGridView
    local cellViewData  = cellViewData or self.bossCellDict_[bossGridView:cellAtIndex(index - 1)]
    local worldBossData = self:getBossHistoryData()[index]

    if cellViewData and worldBossData then
        -- update bgImg
        local isEvenIndex = index % 2 == 0
        cellViewData.selectImg:setVisible(isEvenIndex)
        cellViewData.normalImg:setVisible(not isEvenIndex)

        -- update bossName
        local worldBossQuestConf = WorldBossQuestConfs[tostring(worldBossData.bossId)] or {}
        display.commonLabelParams(cellViewData.nameLabel, {text = tostring(worldBossQuestConf.name)})
        
        -- update bossHead
        cellViewData.headLayer:removeAllChildren()
        local monsterId   = checkint(checktable(worldBossQuestConf.monsterInfo)[1])
        local cardManager = AppFacade.GetInstance():GetManager('CardManager')
        local monsterConf = CardUtils.GetCardConfig(monsterId) or {}
        local bossHeadImg = display.newImageView(AssetsUtils.GetCardHeadPath(monsterConf.drawId))
        cellViewData.headLayer:addChild(bossHeadImg)

        -- update damage
        local damageStr = tostring(worldBossData.damage)
        display.commonLabelParams(cellViewData.damageBar, {paddingW = 20, text = damageStr, safeW = 150})
    end
end



-------------------------------------------------
-- handler

function WorldBossHistoryMediator:onClickBlackBgHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    self:hide()
end


function WorldBossHistoryMediator:onBossGridDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

    local bossGridView = self:getViewData().bossGridView
    local bossCellSize = bossGridView:getSizeOfCell()

    -- create cell
    if pCell == nil then
        local cellViewData = CreateBossCell(bossCellSize)
        display.commonUIParams(cellViewData.clickArea, {cb = handler(self, self.onClickBossCellHandler_)})

        pCell = cellViewData.view
        self.bossCellDict_[pCell] = cellViewData
    end

    -- init cell
    local cellViewData = self.bossCellDict_[pCell]
    cellViewData.clickArea:setTag(index)

    -- update cell
    self:updateBossCell_(index, cellViewData)

    return pCell
end


function WorldBossHistoryMediator:onClickBossCellHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    
    local cellIndex = sender:getTag()
    local bossData  = self:getBossHistoryData()[cellIndex] or {}
    local bossDetailMediator = require('Game.mediator.BossDetailMediator').new({questId = bossData.bossId})
    self:GetFacade():RegistMediator(bossDetailMediator)
end


return WorldBossHistoryMediator
