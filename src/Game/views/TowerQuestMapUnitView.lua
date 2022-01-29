--[[
 * author : kaishiqi
 * descpt : 爬塔 - 地图单元界面
]]
local TowerModelFactory     = require('Game.models.TowerQuestModelFactory')
local TowerQuestModel       = TowerModelFactory.getModelType('TowerQuest')
local TowerQuestMapUnitView = class('TowerQuestMapUnitView', function()
    return display.newLayer(0, 0, {name = 'Game.views.TowerQuestMapUnitView'})
end)

local RES_DICT = {
    BG_IMG       = 'ui/tower/path/tower_bg_2.jpg',
    FG_IMG       = 'ui/tower/path/tower_bg_2_front.png',
    BTN_TEAM     = 'ui/tower/path/tower_btn_team_add.png',
    PATH_UNLOCK  = 'ui/tower/path/tower_bg_path_active.png',
    PATH_LOCK    = 'ui/tower/path/tower_bg_path_locked.png',
    BAR_BOSS     = 'ui/tower/path/tower_label_level_boss.png',
    BAR_NORMAL   = 'ui/tower/path/tower_label_level_s.png',
    BASE_BOSS    = 'ui/tower/path/tower_ico_point_bossbase.png',
    BASE_NORMAL  = 'ui/tower/path/tower_ico_point_finished.png',
    POINT_IMG    = 'ui/tower/path/tower_ico_point_locked.png',
    BOSS_LIGHT   = 'ui/tower/path/tower_ico_point_light.png',
    ICON_TEAM    = 'ui/tower/path/tower_ico_point_editable.png',
    BTN_REAWED   = 'ui/common/common_btn_orange.png',
    CHEST_LV_BAR = 'ui/tower/team/tower_prepare_bg_chest.png',
    CHEST_LV_S   = 'ui/tower/team/tower_ico_mark_active.png',
    CHEST_LV_D   = 'ui/tower/team/tower_ico_mark_unactive.png',
    CHEST_ARROW  = 'ui/common/discovery_ico_open.png',
}

local CreateView     = nil
local CreateUnitNode = nil
local CreatePathNode = nil

local UNIT_PATH_NUM = TowerQuestModel.UNIT_PATH_NUM


function TowerQuestMapUnitView:ctor(args)
    xTry(function()
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
    end, __G__TRACKBACK__)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -------------------------------------------------
    -- back ground
    local bgImg  = display.newImageView(_res(RES_DICT.BG_IMG), size.width/2, size.height/2)
    local bgPosY = (size.height - bgImg:getContentSize().height) / 2
    local bgImgW = math.min(bgImg:getContentSize().width, display.width)
    bgImg:setTextureRect(cc.rect(0, 0, bgImgW, bgImg:getContentSize().height))
    view:addChild(bgImg)

    -- mural layer
    local muralLayer = display.newLayer(size.width/2, size.height/2 + 75, {ap = display.CENTER})
    view:addChild(muralLayer)

    -- pillar layer
    local pillarNodeL = display.newLayer(size.width/2 - 425, bgPosY + 345)
    local pillarNodeR = display.newLayer(size.width/2 + 425, pillarNodeL:getPositionY())
    local pillarList  = {pillarNodeL, pillarNodeR}
    view:addChild(pillarNodeL)
    view:addChild(pillarNodeR)

    -------------------------------------------------
    local bgImgDiffW = (display.width - 1334) / 2
    local pathDists  = {bgImgDiffW + 220-66, 220, 220, 220, 300, 220 + bgImgDiffW}
    local pathLayer  = display.newLayer()
    view:addChild(pathLayer)

    -- path nodes
    local pathNodes = {}
    local PATH_Y    = bgPosY + 300
    for i, dist in ipairs(pathDists) do
        local pathNode = CreatePathNode(cc.size(dist, 14))
        local pathPosX = i > 1 and pathNodes[i-1].view:getPositionX() + pathDists[i-1] or 0
        pathNode.view:setPosition(pathPosX, PATH_Y)
        pathNode:setPathProgress(i == 1 and 100 or 0)
        pathLayer:addChild(pathNode.view)
        pathNodes[i] = pathNode
    end

    -- unit nodes
    local unitNodes = {}
    local UNIT_Y    = PATH_Y + 5
    for i = 1, UNIT_PATH_NUM do
        local unitNode = CreateUnitNode(i == UNIT_PATH_NUM)
        local unitPosX = pathNodes[i + 1].view:getPositionX()
        unitNode.view:setPosition(unitPosX, UNIT_Y)
        pathLayer:addChild(unitNode.view)
        unitNodes[i] = unitNode
    end

    -------------------------------------------------
    -- others

    -- editTeam button
    local editTeamBtnExistY = UNIT_Y + 220
    local editTeamBtnEmptyY = UNIT_Y + 30
    local editTeamBtn = display.newButton(unitNodes[1].view:getPositionX(), editTeamBtnEmptyY, {n = _res(RES_DICT.BTN_TEAM), ap = display.CENTER_BOTTOM})
    display.commonLabelParams(editTeamBtn, fontWithColor(7, {text = __('编辑') ,reqW = 90 , offset = cc.p(0,8)}))
    editTeamBtn:setVisible(false)
    view:addChild(editTeamBtn)

    -- chest layer
    local chestPos   = cc.p(unitNodes[UNIT_PATH_NUM].view:getPositionX(), UNIT_Y - 15)
    local chestLayer = display.newLayer()
    view:addChild(chestLayer)
    chestLayer:setVisible(false)
    
    -- chest light
    local chestLight = display.newImageView(_res(RES_DICT.BOSS_LIGHT), chestPos.x, chestPos.y + 5, {ap = display.CENTER_BOTTOM})
    chestLayer:addChild(chestLight)
    chestLight:runAction(cc.RepeatForever:create(cc.Sequence:create({
        cc.FadeTo:create(1, 150),
        cc.FadeTo:create(1, 255),
    })))

    -- chest light particle
    local chestLightParticle = cc.ParticleSystemQuad:create('ui/tower/path/particle/chest_light.plist')
    chestLightParticle:setPosition(cc.p(chestLight:getPositionX(), chestLight:getPositionY() + 20))
    chestLayer:addChild(chestLightParticle)

    -- chest info layer
    local chestInfoLayer = display.newLayer(chestPos.x, chestPos.y, {ap = display.CENTER})
    local chestInfoSize  = chestInfoLayer:getContentSize()
    chestLayer:addChild(chestInfoLayer)

    -- chest image layer
    local chestImageLayer = display.newLayer(chestInfoSize.width/2, chestInfoSize.height/2, {ap = display.CENTER})
    chestInfoLayer:addChild(chestImageLayer)

    -- chest level bar
    local chestLevelHideList = {}
    local chestLevelShowList = {}
    local chestLevelInfoPos  = cc.p(chestInfoSize.width/2, chestInfoSize.height/2)
    chestInfoLayer:addChild(display.newImageView(_res(RES_DICT.CHEST_LV_BAR), chestLevelInfoPos.x + 75, chestLevelInfoPos.y, {ap = display.RIGHT_BOTTOM}))

    for i=1,3 do
        local chestLevelIconPos  = cc.p(chestLevelInfoPos.x - 36 + (i-1)*42, chestLevelInfoPos.y + 25)
        local chestLevelHideIcon = display.newImageView(_res(RES_DICT.CHEST_LV_D), chestLevelIconPos.x, chestLevelIconPos.y)
        local chestLevelShowIcon = display.newImageView(_res(RES_DICT.CHEST_LV_S), chestLevelIconPos.x, chestLevelIconPos.y)
        chestInfoLayer:addChild(chestLevelHideIcon)
        chestInfoLayer:addChild(chestLevelShowIcon)
        chestLevelHideList[i] = chestLevelHideIcon
        chestLevelShowList[i] = chestLevelShowIcon
    end

    -- chest effect spine
    local chestEffectPath  = 'ui/tower/team/spine/shengji'
    if not SpineCache(SpineCacheName.TOWER):hasSpineCacheData(chestEffectPath) then
        SpineCache(SpineCacheName.TOWER):addCacheData(chestEffectPath, chestEffectPath, 1)
    end
    local chestEffectSpine = SpineCache(SpineCacheName.TOWER):createWithName(chestEffectPath)
    chestEffectSpine:setPosition(chestInfoSize.width/2, chestInfoSize.height/2 + 60)
    chestInfoLayer:addChild(chestEffectSpine)

    -- chest open image
    local chestOpenImg = display.newImageView(_res(RES_DICT.CHEST_ARROW), chestPos.x, chestPos.y + 160, {ap = display.CENTER_BOTTOM})
    chestOpenImg:addChild(display.newLabel(18, 75, fontWithColor(20, {text = __('点击打开'), fontSize = 28, outline = '#734441'})))
    chestOpenImg:setVisible(false)
    view:addChild(chestOpenImg)

    -- foreground
    local fgImg = display.newImageView(_res(RES_DICT.FG_IMG), size.width/2, bgPosY, {ap = display.CENTER_BOTTOM})
    fgImg:setTextureRect(cc.rect(0, 0, bgImgW, fgImg:getContentSize().height))
    view:addChild(fgImg)

    return {
        view               = view,
        pillarList         = pillarList,
        muralLayer         = muralLayer,
        muralSpine         = nil,
        unitNodes          = unitNodes,
        pathNodes          = pathNodes,
        roleNodeY          = UNIT_Y + 10,
        chestLayer         = chestLayer,
        chestLight         = chestLight,
        chestInfoLayer     = chestInfoLayer,
        chestInfoDownPos   = cc.p(chestPos.x, chestPos.y),
        chestInfoFlyPos    = cc.p(chestPos.x, chestPos.y + 120),
        chestImageLayer    = chestImageLayer,
        chestImageLayerPos = cc.p(chestImageLayer:getPosition()),
        chestLightParticle = chestLightParticle,
        chestEffectSpine   = chestEffectSpine,
        chestLevelHideList = chestLevelHideList,
        chestLevelShowList = chestLevelShowList,
        editTeamBtn        = editTeamBtn,
        editTeamBtnExistY  = editTeamBtnExistY,
        editTeamBtnEmptyY  = editTeamBtnEmptyY,
        chestOpenImg       = chestOpenImg,
    }
end


CreateUnitNode = function(isBoss)
    local view = display.newLayer(0, 0, {ap = display.CENTER})
    local size = view:getContentSize()

    if isBoss then
        view:addChild(display.newImageView(_res(RES_DICT.BASE_BOSS), size.width/2, size.height/2))
    end

    local baseImg = display.newImageView(_res(RES_DICT.BASE_NORMAL), size.width/2, size.height/2)
    view:addChild(baseImg)

    local pointImg = display.newImageView(_res(RES_DICT.POINT_IMG), size.width/2, size.height/2)
    view:addChild(pointImg)

    local floorBar = display.newButton(size.width/2, size.height/2 - 30, {n = isBoss and _res(RES_DICT.BAR_BOSS) or _res(RES_DICT.BAR_NORMAL), enable = false})
    display.commonLabelParams(floorBar, fontWithColor(14))
    view:addChild(floorBar)

    return {
        view     = view,
        baseImg  = baseImg,
        pointImg = pointImg,
        floorBar = floorBar,
    }
end


CreatePathNode = function(size)
    local view = display.newLayer(0, 0, {size = size, ap = display.LEFT_CENTER})

    local pathLockImg = display.newImageView(_res(RES_DICT.PATH_LOCK), 0, size.height/2, {scale9 = true, size = size, ap = display.LEFT_CENTER, capInsets = cc.rect(5,0,290,14)})
    view:addChild(pathLockImg)

    local pathUnlockImg = display.newImageView(_res(RES_DICT.PATH_UNLOCK), 0, size.height/2, {ap = display.LEFT_CENTER})
    view:addChild(pathUnlockImg)

    local pathProgress = 0
    return {
        view          = view,
        pathLockImg   = pathLockImg,
        pathUnlockImg = pathUnlockImg,
        getPathProgress = function()
            return pathProgress
        end,
        setPathProgress = function(_, progress)
            pathProgress = math.max(0, math.min(checkint(progress), 100))
            pathUnlockImg:setTextureRect(cc.rect(0, 0, size.width * pathProgress/100, size.height))
        end
    }
end


function TowerQuestMapUnitView:getViewData()
    return self.viewData_
end


function TowerQuestMapUnitView:playEditTeamAction()
    self.viewData_.editTeamBtn:runAction(cc.RepeatForever:create(cc.Sequence:create({
        cc.DelayTime:create(0.8),
        cc.ScaleTo:create(0.1, 1.1, 0.8),
        cc.ScaleTo:create(0.1, 1),
        cc.JumpBy:create(0.4, cc.p(0,0), 60, 1),
        cc.ScaleTo:create(0.1, 1.1, 0.8),
        cc.ScaleTo:create(0.1, 1)
    })))
end
function TowerQuestMapUnitView:stopEditTeamAction()
    self.viewData_.editTeamBtn:stopAllActions()
    self.viewData_.editTeamBtn:setScale(1)
end


function TowerQuestMapUnitView:playChestOpenAction()
    self:stopChestOpenAction()
    self.viewData_.chestOpenImg:runAction(cc.RepeatForever:create(cc.Sequence:create({
        cc.DelayTime:create(0.8),
        cc.ScaleTo:create(0.1, 1.1, 0.8),
        cc.ScaleTo:create(0.1, 1),
        cc.JumpBy:create(0.4, cc.p(0,0), 60, 1),
        cc.ScaleTo:create(0.1, 1.1, 0.8),
        cc.ScaleTo:create(0.1, 1)
    })))

    local shakeActList   = {}
    local shakeWaveNum   = 3
    local chestOriginPos = self.viewData_.chestImageLayerPos
    for i=1,10 do
        local targetPos = cc.p(
            chestOriginPos.x + math.random(-shakeWaveNum, shakeWaveNum), 
            chestOriginPos.y + math.random(-shakeWaveNum, shakeWaveNum)
        )
        table.insert(shakeActList, cc.MoveTo:create(0.02, targetPos))
    end
    table.insert(shakeActList, cc.MoveTo:create(0.02, chestOriginPos))
    self.viewData_.chestImageLayer:runAction(cc.RepeatForever:create(cc.Sequence:create({
        cc.DelayTime:create(0.8),
        cc.Sequence:create(shakeActList),
    })))
end
function TowerQuestMapUnitView:stopChestOpenAction()
    self.viewData_.chestOpenImg:stopAllActions()
    self.viewData_.chestOpenImg:setScale(1)
    self.viewData_.chestImageLayer:stopAllActions()
    self.viewData_.chestImageLayer:setPosition(self.viewData_.chestImageLayerPos)
end


function TowerQuestMapUnitView:playChestLevitateAction()
    self:stopChestLevitateAction()
    self.viewData_.chestInfoLayer:runAction(cc.RepeatForever:create(cc.Sequence:create({
        cc.JumpTo:create(1.6, self.viewData_.chestInfoFlyPos, -15, 1),
        cc.JumpTo:create(1.6, self.viewData_.chestInfoFlyPos, 15, 1),
    })))
end
function TowerQuestMapUnitView:stopChestLevitateAction()
    self.viewData_.chestInfoLayer:stopAllActions()
end


function TowerQuestMapUnitView:reloadBackground()
    -- reload mural
    self.viewData_.muralLayer:removeAllChildren()

    local muralNum   = math.random(1, 3)
    local muralPath  = string.fmt('ui/tower/path/spine/changjing%1', muralNum)
    if not SpineCache(SpineCacheName.TOWER):hasSpineCacheData(muralPath) then
        SpineCache(SpineCacheName.TOWER):addCacheData(muralPath, muralPath, 1)
    end
    local muralSpine = SpineCache(SpineCacheName.TOWER):createWithName(muralPath)
    local layerSize  = self.viewData_.muralLayer:getContentSize()
    muralSpine:setPosition(cc.p(layerSize.width/2, layerSize.height/2 + (muralNum == 3 and 1 or 0)))
    muralSpine:setAnimation(0, 'idle', true)
    muralSpine:setOpacity(0)
    self.viewData_.muralLayer:addChild(muralSpine)
    self.viewData_.muralSpine = muralSpine

    -- reload pillar
    for _, pillarNode in ipairs(self.viewData_.pillarList) do
        pillarNode:removeAllChildren()

        local pillarNum  = math.random(1, 4)
        local pillarPath = string.fmt('ui/tower/path/tower_bg_2_pillar_%1.png', pillarNum)
        pillarNode:addChild(display.newImageView(_res(pillarPath), 0, 0, {ap = display.CENTER_BOTTOM}))
    end
end


function TowerQuestMapUnitView:showMapElement()
    if self.viewData_.muralSpine then
        self.viewData_.muralSpine:runAction(cc.FadeTo:create(0.8, 255))
    end
end


function TowerQuestMapUnitView:createPathProgressAction(pathNode, actTime)
    local pathAction   = nil
    local pathActTime  = actTime or 1.5
    local pathActDelay = 0.02
    if pathNode then
        local pathActList = {}
        local actCount    = pathActTime / pathActDelay
        local percent     = 100 / actCount
        for i = 1, actCount do
            table.insert(pathActList, cc.CallFunc:create(function()
                pathNode:setPathProgress(pathNode:getPathProgress() + percent)
            end))
            table.insert(pathActList, cc.DelayTime:create(pathActDelay))
        end
        table.insert(pathActList, cc.CallFunc:create(function()
            pathNode:setPathProgress(100)
        end))
        pathAction = cc.Sequence:create(pathActList)
    end
    return pathAction
end


return TowerQuestMapUnitView
