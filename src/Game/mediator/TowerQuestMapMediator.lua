--[[
 * author : kaishiqi
 * descpt : 爬塔 - 地图界面中介者
]]
local TowerModelFactory     = require('Game.models.TowerQuestModelFactory')
local TowerQuestModel       = TowerModelFactory.getModelType('TowerQuest')
local UnitConfigModel       = TowerModelFactory.getModelType('UnitConfig')
local UnitDefineModel       = TowerModelFactory.getModelType('UnitDefine')
local UnitContractModel     = TowerModelFactory.getModelType('UnitContract')
local TowerQuestMapUIView   = require('Game.views.TowerQuestMapUIView')
local TowerQuestMapUnitView = require('Game.views.TowerQuestMapUnitView')
local TowerConfigParser     = require('Game.Datas.Parser.TowerConfigParser')
local BossDetailMediator    = require('Game.mediator.BossDetailMediator')
local ContractMediator      = require('Game.mediator.TowerQuestContractMediator')
local EditCardTeamMediator  = require('Game.mediator.TowerQuestEditCardTeamMediator')
local TowerQuestMapMediator = class('TowerQuestMapMediator', mvc.Mediator)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function TowerQuestMapMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TowerQuestMapMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function TowerQuestMapMediator:Initial(key)
    self.super.Initial(self, key)

    local isIgnoreShowView = self.ctorArgs_.isIgnoreShowView == true
    self.isControllable_   = true
    self.towerHomeMdt_     = self:GetFacade():RetrieveMediator('TowerQuestHomeMediator')

    -- create view
    local homeScene = self.towerHomeMdt_:getHomeScene()

    self.nowMapUnitView_ = TowerQuestMapUnitView.new()
	homeScene:AddGameLayer(self.nowMapUnitView_)

    self.nextMapUnitView_ = TowerQuestMapUnitView.new()
    self.nextMapUnitView_:setPositionX(display.width)
	homeScene:AddGameLayer(self.nextMapUnitView_)

    self.roleView_ = display.newLayer(display.cx, display.cy, {ap = display.CENTER})
	homeScene:AddGameLayer(self.roleView_)

    self.mapUIView_ = TowerQuestMapUIView.new()
    homeScene:AddGameLayer(self.mapUIView_)
    
    -- char btn
    if ChatUtils.IsModuleAvailable() then
        self.chatBtn_ = require('common.CommonChatPanel').new({state = 3})
        display.commonUIParams(self.chatBtn_, {po = cc.p(display.SAFE_L + 4, display.cy), ap = display.LEFT_CENTER})
        homeScene:AddGameLayer(self.chatBtn_)
    end

    -- init view
    local nowMapUnitViewData  = self.nowMapUnitView_:getViewData()
    local nextMapUnitViewData = self.nextMapUnitView_:getViewData()
    display.commonUIParams(nowMapUnitViewData.editTeamBtn, {cb = handler(self, self.onClickEditTeamButtonHandler_)})
    display.commonUIParams(nextMapUnitViewData.editTeamBtn, {cb = handler(self, self.onClickEditTeamButtonHandler_)})

    local mapUIViewData = self.mapUIView_:getViewData()
    display.commonUIParams(mapUIViewData.exitBtn, {cb = handler(self, self.onClickExitButtonHandler_)})
    display.commonUIParams(mapUIViewData.fightBtn, {cb = handler(self, self.onClickFightButtonHandler_)})
    display.commonUIParams(mapUIViewData.bossHotspot, {cb = handler(self, self.onClickBossHotspotHandler_), animate = false})

    -- update view
    self.nowMapUnitView_:reloadBackground()
    self:updateMapPathInfo_()
    self:updateFloorInfo_()
    self:updateUnitInfo_()

    -- show ui
    self.isControllable_ = false
    if not isIgnoreShowView then
        self:showUI()
    end
end


function TowerQuestMapMediator:CleanupView()
    if self.nowMapUnitView_ then
        local homeScene = self.towerHomeMdt_:getHomeScene()
        homeScene:RemoveGameLayer(self.nowMapUnitView_)
        self.nowMapUnitView_ = nil
    end
    if self.nextMapUnitView_ then
        local homeScene = self.towerHomeMdt_:getHomeScene()
        homeScene:RemoveGameLayer(self.nextMapUnitView_)
        self.nextMapUnitView_ = nil
    end
    if self.roleView_ then
        local homeScene = self.towerHomeMdt_:getHomeScene()
        homeScene:RemoveGameLayer(self.roleView_)
        self.roleView_ = nil
    end
    if self.mapUIView_ then
        local homeScene = self.towerHomeMdt_:getHomeScene()
        homeScene:RemoveGameLayer(self.mapUIView_)
        self.mapUIView_ = nil
    end
    if self.chatBtn_ then
        local homeScene = self.towerHomeMdt_:getHomeScene()
        homeScene:RemoveGameLayer(self.chatBtn_)
        self.chatBtn_ = nil
    end
end


function TowerQuestMapMediator:OnRegist()
    regPost(POST.TOWER_EXIT)
    regPost(POST.TOWER_UNIT_DRAW_REWARD)
    regPost(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL)
end
function TowerQuestMapMediator:OnUnRegist()
    unregPost(POST.TOWER_EXIT)
    unregPost(POST.TOWER_UNIT_DRAW_REWARD)
    unregPost(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL)
end


function TowerQuestMapMediator:InterestSignals()
    return {
        POST.TOWER_EXIT.sglName,
        POST.TOWER_UNIT_DRAW_REWARD.sglName,
        POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.sglName,
        SGL.TOWER_QUEST_SET_CARD_TEAM,
        SGL.TOWER_QUEST_SET_BATTLE_RESULT,
        SGL.TOWER_QUEST_MODEL_UNIT_CONFIG_CHANGE,
        SGL.TOWER_QUEST_MODEL_UNIT_PASSED_CHANGE,
        SGL.TOWER_QUEST_MODEL_CURRENT_FLOOR_CHANGE,
    }
end
function TowerQuestMapMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.TOWER_EXIT.sglName then
        -- hide clippingNode
        local mapUIViewData = self.mapUIView_:getViewData()
        mapUIViewData.bossLayer:setVisible(false)

        -- restart home
        self.towerHomeMdt_:restart()


    elseif name == POST.TOWER_UNIT_DRAW_REWARD.sglName then
        AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "31-02"})
        local uiManager     = self:GetFacade():GetManager('UIManager')
        local towerModel    = self.towerHomeMdt_:getTowerModel()
        local unitDefine    = towerModel:getUnitDefineModel()
        local unitConfig    = towerModel:getUnitConfigModel()
        local currentUnitId = unitDefine and unitDefine:getUnitId() or 0
        local towerUnitConf = checktable(CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.UNIT ,'tower'))[tostring(currentUnitId)] or {}
        local chestLevel    = self:isReallyTeamReadied_() and table.nums(unitConfig:getContractSelectedIdList() or {}) or 0
        local chestId       = checkint(towerUnitConf[string.fmt('chestId%1', chestLevel + 1)])  -- 1 is base, 2 is level 1
        local hasNextUnit   = checkint(data.unitId) > 0

        -- update unitDefine
        local unitDefineModel = UnitDefineModel.new()
        if hasNextUnit then
            unitDefineModel:setUnitId(checkint(data.unitId))
            unitDefineModel:setChestRewardsMap(checktable(data.unitChest))
            unitDefineModel:setContractIdList(checktable(data.unitContracts))
        end
        towerModel:setUnitDefineModel(unitDefineModel)

        -- clean selected contract
        local unitConfigModel = towerModel:getUnitConfigModel()
        unitConfigModel:setContractSelectedIdList({})

        -- show reward popup
        local rewardsData = checktable(data.rewards)
        rewardsData.requestData = {goodsId = chestId}
        uiManager:AddDialog('common.RewardPopup', {
            rewards       = rewardsData,
            closeCallback = hasNextUnit and handler(self, self.switchToNextUnitMap_) or nil
        })

    elseif name == POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.sglName then

        if checkint(data.valid) == 1 then
            self:EnterBattleByPresetTeam(data)
        else
            app.uiMgr:ShowInformationTips(__('当前预设编队已失效'))
        end
    
    elseif name == SGL.TOWER_QUEST_SET_CARD_TEAM then
        local towerModel = self.towerHomeMdt_:getTowerModel()
        towerModel:setUnconfirmedConfig(false)
        
        -- udpate unitConfig
        local unitConfigModel = UnitConfigModel.new()
        unitConfigModel:setCardIdList(checktable(data.selectedCardList))
        unitConfigModel:setSkillIdList(checktable(data.selectedSkillList))
        unitConfigModel:setContractSelectedIdList(checktable(data.selectedContractList))
        towerModel:setUnitConfigModel(unitConfigModel)


    elseif name == SGL.TOWER_QUEST_MODEL_UNIT_CONFIG_CHANGE then
        self:updateUnitConfigInfo_()


    elseif name == SGL.TOWER_QUEST_MODEL_CURRENT_FLOOR_CHANGE then
        self:updateFloorInfo_(true)


    elseif name == SGL.TOWER_QUEST_SET_BATTLE_RESULT then
        local isPassed    = data.isPassed == true
        local reviveTimes = checkint(data.reviveTimes)
        local towerModel  = self.towerHomeMdt_:getTowerModel()

        -- update revive times
        towerModel:setReviveTimes(reviveTimes)
        
        -- check floor passed
        if isPassed then

            -- update history floor
            local currentFloor = towerModel:getCurrentFloor()
            if currentFloor > towerModel:getHistoryMaxFloor() then
                towerModel:setHistoryMaxFloor(currentFloor)
            end

            self:toBattleVictory_()

        else
            self:toBattleFailure_()
        end

    end
end


-------------------------------------------------
-- public method

function TowerQuestMapMediator:showUI(endCB)
    if self.towerHomeMdt_:isFromBattle() then
        self:updateUnitConfigInfo_()
        self:updateUnitPassedStatus_()
    end

    self.mapUIView_:showUI(function()
        if not self.towerHomeMdt_:isFromBattle() then
            self:updateUnitConfigInfo_()
            self:updateUnitPassedStatus_()
            self.isControllable_ = true
        end

        self.nowMapUnitView_:showMapElement()

        if endCB then endCB() end
    end)
end


-------------------------------------------------
-- private method

function TowerQuestMapMediator:isReallyTeamReadied_()
    local towerModel = self.towerHomeMdt_:getTowerModel()
    return not towerModel:isUnconfirmedConfig() or towerModel:isUnitReadied()
end


function TowerQuestMapMediator:updateMapPathInfo_()
    local towerModel          = self.towerHomeMdt_:getTowerModel()
    local currentFloor        = checkint(towerModel:getCurrentFloor())
    local nowMapUnitViewData  = self.nowMapUnitView_:getViewData()
    local nextMapUnitViewData = self.nextMapUnitView_:getViewData()

    local currentFloorLevel = math.ceil(currentFloor / TowerQuestModel.UNIT_PATH_NUM) - 1
    local currentStartFloor = math.max(1, currentFloorLevel * TowerQuestModel.UNIT_PATH_NUM + 1)
    local nextStartFloor    = currentStartFloor + TowerQuestModel.UNIT_PATH_NUM
    for i, unitNode in ipairs(nowMapUnitViewData.unitNodes) do
        local isPassed = currentStartFloor + (i-1) < currentFloor
        unitNode.pointImg:setVisible(not isPassed)
        display.commonLabelParams(unitNode.floorBar, {text = tostring(currentStartFloor + (i-1))})
    end
    for i, unitNode in ipairs(nextMapUnitViewData.unitNodes) do
        display.commonLabelParams(unitNode.floorBar, {text = tostring(nextStartFloor + (i-1))})
    end
    for i, pathNode in ipairs(nowMapUnitViewData.pathNodes) do
        local isPassed = currentStartFloor + (i-1) <= currentFloor
        pathNode:setPathProgress(i == 1 and 100 or (isPassed and 100 or 0))
    end
    for i, pathNode in ipairs(nextMapUnitViewData.pathNodes) do
        pathNode:setPathProgress(0)
    end
end


function TowerQuestMapMediator:updateUnitInfo_(isNeedAction)
    local mapUIViewData = self.mapUIView_:getViewData()
    local towerModel    = self.towerHomeMdt_:getTowerModel()
    local unitDefine    = towerModel:getUnitDefineModel()
    local currentUnitId = unitDefine and unitDefine:getUnitId() or 0
    local towerUnitConf = checktable(CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.UNIT ,'tower'))[tostring(currentUnitId)] or {}
    local actionTime    = 0.3
    local delayInterval = 0.2

    -------------------------------------------------
    -- update weather info
    for i, weatherIcon in ipairs(mapUIViewData.weatherLayer:getChildren()) do
        weatherIcon:runAction(cc.Sequence:create({
            cc.DelayTime:create((i-1) * delayInterval),
            cc.ScaleTo:create(actionTime, 0),
            cc.RemoveSelf:create()
        }))
    end
    if currentUnitId > 0 then
        -- create weather icon
        local weatherList  = checktable(towerUnitConf.weatherInfo)
        local weatherIdMap = {}
        local weatherIcons = {}
        for _, v in ipairs(weatherList) do
            local weatherId = checkint(v)
            if not weatherIdMap[tostring(weatherId)] then
                local weatherIcon = self.mapUIView_:createWeatherIcon(weatherId)
                mapUIViewData.weatherLayer:addChild(weatherIcon)
                weatherIdMap[tostring(weatherId)] = true
                table.insert(weatherIcons, weatherIcon)

                display.commonUIParams(weatherIcon, {cb = function(sender)
                    local uiManager   = self:GetFacade():GetManager('UIManager')
                    local weatherConf = CommonUtils.GetConfig('quest', 'weather', weatherId)
                    uiManager:ShowInformationTipsBoard({targetNode = sender, title = weatherConf.name, descr = weatherConf.descr, type = 5})
                end})
            end
        end

        -- align weather icon
        local weatherIconGap = 58
        local weatherCenter  = utils.getLocalCenter(mapUIViewData.weatherLayer)
        local iconBasePosX   = weatherCenter.x - (#weatherIcons - 1)/2 * weatherIconGap
        for i, weatherIcon in ipairs(weatherIcons) do
            local iconPoint = cc.p(iconBasePosX + (i-1) * weatherIconGap, weatherCenter.y)
            if isNeedAction then
                weatherIcon:setPosition(cc.p(iconPoint.x, iconPoint.y + 100))
                weatherIcon:runAction(cc.Sequence:create({
                    cc.DelayTime:create(i * delayInterval),
                    cc.MoveTo:create(actionTime, iconPoint)
                }))
            else
                weatherIcon:setPosition(iconPoint)
            end
        end
    end

    -------------------------------------------------
    -- update boss info
    for i, bossIcon in ipairs(mapUIViewData.bossLayer:getChildren()) do
        bossIcon:runAction(cc.Sequence:create({
            cc.DelayTime:create((i-1) * delayInterval),
            cc.ScaleTo:create(actionTime, 0),
            cc.RemoveSelf:create()
        }))
    end
    if currentUnitId > 0 then
        -- create boss icon
        local bossList  = checktable(towerUnitConf.monsterInfo)
        local bossIdMap = {}
        local bossIcons = {}
        for _, v in ipairs(bossList) do
            local bossId = checkint(v)
            if not bossIdMap[tostring(bossId)] then
                local bossIcon = self.mapUIView_:createBossIcon(bossId)
                mapUIViewData.bossLayer:addChild(bossIcon)
                bossIdMap[tostring(bossId)] = true
                table.insert(bossIcons, bossIcon)
            end
        end

        -- align boss icon
        local bossIconGap = 114
        local bossCenter  = utils.getLocalCenter(mapUIViewData.bossLayer)
        local iconBasePosX  = bossCenter.x - (#bossIcons - 1)/2 * bossIconGap
        for i, bossIcon in ipairs(bossIcons) do
            local iconPoint = cc.p(iconBasePosX + (i-1) * bossIconGap, bossCenter.y)
            if isNeedAction then
                bossIcon:setPosition(cc.p(iconPoint.x, iconPoint.y + 100))
                bossIcon:runAction(cc.Sequence:create({
                    cc.DelayTime:create(i * delayInterval),
                    cc.MoveTo:create(actionTime, iconPoint)
                }))
            else
                bossIcon:setPosition(iconPoint)
            end
        end
    end
end


function TowerQuestMapMediator:updateFloorInfo_(isNeedAction)
    local towerModel         = self.towerHomeMdt_:getTowerModel()
    local currentFloor       = checkint(towerModel:getCurrentFloor())
    local mapUIViewData      = self.mapUIView_:getViewData()
    local nowMapUnitViewData = self.nowMapUnitView_:getViewData()
    local labelActionTime    = 0.6

    -------------------------------------------------
    -- udpate floorNum info
    local updateFloorNumFunc = function()
        display.commonLabelParams(mapUIViewData.floorLabel, {reqW = 230 , text = string.fmt(__('当前所在第_num_层'), { _num_ = currentFloor})})
    end
    if isNeedAction then
        mapUIViewData.floorLabel:runAction(cc.Sequence:create({
            cc.FadeTo:create(labelActionTime, 0),
            cc.CallFunc:create(updateFloorNumFunc),
            cc.FadeTo:create(labelActionTime, 255)
        }))
    else
        updateFloorNumFunc()
    end

    -------------------------------------------------
    -- update recommand info
    local updateRecommandFunc = function()
        if currentFloor > 0 then
            local baseRewardConf = checktable(CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.BASE_REWARD ,'tower'))[tostring(currentFloor)] or {}
            display.commonLabelParams(mapUIViewData.recommendLabel, {text = string.fmt(__('推荐等级_num_级'), {_num_ = baseRewardConf.recommendLevel})})
        else
            display.commonLabelParams(mapUIViewData.recommendLabel, {text = ''})
        end
    end
    if isNeedAction then
        mapUIViewData.recommendLabel:runAction(cc.Sequence:create({
            cc.FadeTo:create(labelActionTime, 0),
            cc.CallFunc:create(updateRecommandFunc),
            cc.FadeTo:create(labelActionTime, 255)
        }))
    else
        updateRecommandFunc()
    end

    ------------------------------------------------- 
    -- update role pos
    local unitIndex = currentFloor % TowerQuestModel.UNIT_PATH_NUM
    unitIndex = (currentFloor ~= 0 and unitIndex == 0) and TowerQuestModel.UNIT_PATH_NUM or unitIndex

    local unitNode = nowMapUnitViewData.unitNodes[unitIndex]
    local nodePos  = cc.p(unitNode and unitNode.view:getPositionX() or 0, nowMapUnitViewData.roleNodeY)
    if unitIndex == TowerQuestModel.UNIT_PATH_NUM then
        nodePos.x = nodePos.x - 120
    end
    if isNeedAction then
        if self.roleView_.cardSpine then
            self.roleView_.cardSpine:setToSetupPose()
            self.roleView_.cardSpine:setAnimation(0, 'run', true)
        end
        self.roleView_:runAction(cc.Sequence:create({
            cc.MoveTo:create(0.8, nodePos),
            cc.CallFunc:create(function()
                if self.roleView_ and self.roleView_.cardSpine and not tolua.isnull(self.roleView_.cardSpine) then
                    self.roleView_.cardSpine:setToSetupPose()
                    self.roleView_.cardSpine:setAnimation(0, 'idle', true)
                end
            end)
        }))
    else
        self.roleView_:setPosition(nodePos)
    end
end


function TowerQuestMapMediator:updateUnitConfigInfo_()
    self:updateEditTeamBtnStatus_()
    self:updateFightButtonStatus_()
    self:udpateChestInfo_()
    self:updateRoleView_()
end
function TowerQuestMapMediator:updateFightButtonStatus_()
    local towerModel      = self.towerHomeMdt_:getTowerModel()
    local mapUIViewData   = self.mapUIView_:getViewData()
    local unitConfigModel = towerModel:getUnitConfigModel()
    
    -- not unit passed  &&  config card > 0  &&  team readied
    mapUIViewData.fightBtn:setEnabled(not towerModel:isUnitPassed() and #unitConfigModel:getCardIdList() > 0 and self:isReallyTeamReadied_())
end
function TowerQuestMapMediator:updateEditTeamBtnStatus_()
    local towerModel         = self.towerHomeMdt_:getTowerModel()
    local unitConfigModel    = towerModel:getUnitConfigModel()
    local nowMapUnitViewData = self.nowMapUnitView_:getViewData()
    
    -- update editButton visible
    if towerModel:isUnitReadied() then
        nowMapUnitViewData.editTeamBtn:setVisible(false)
        self.nowMapUnitView_:stopEditTeamAction()

    else
        nowMapUnitViewData.editTeamBtn:setVisible(true)

        -- check setting config
        if #unitConfigModel:getCardIdList() > 0 and self:isReallyTeamReadied_() then
            nowMapUnitViewData.editTeamBtn:setPositionY(nowMapUnitViewData.editTeamBtnExistY)
        else
            nowMapUnitViewData.editTeamBtn:setPositionY(nowMapUnitViewData.editTeamBtnEmptyY)
        end
        
        self.nowMapUnitView_:stopEditTeamAction()
        nowMapUnitViewData.editTeamBtn:setScaleX(0)
        nowMapUnitViewData.editTeamBtn:runAction(cc.Sequence:create({
            cc.DelayTime:create(0.1),
            cc.EaseElasticOut:create(cc.ScaleTo:create(0.6, 1)),
            cc.CallFunc:create(function()
                if self.nowMapUnitView_ and not tolua.isnull(self.nowMapUnitView_) then
                    self.nowMapUnitView_:playEditTeamAction()
                end
            end)
        }))
    end
end
function TowerQuestMapMediator:updateRoleView_()
    local towerModel      = self.towerHomeMdt_:getTowerModel()
    local unitConfigModel = towerModel:getUnitConfigModel()
    local captainCardGuid = 0

    -- check captain card
    if #unitConfigModel:getCardIdList() > 0 then
        for i,v in ipairs(unitConfigModel:getCardIdList()) do
            captainCardGuid = checkint(v)
            if captainCardGuid > 0 then
                break
            end
        end
    end

    -- check same card
    if checkint(self.currentRoleCardGuid_) == captainCardGuid then
        return
    end

    -- clean old spine
    if self.roleView_.spineLayer and self.roleView_.cardSpine then
        self.roleView_.spineLayer:setScaleX(-1)
        self.roleView_.cardSpine:setToSetupPose()
        self.roleView_.cardSpine:setAnimation(0, 'run', true)
        self.roleView_.spineLayer:runAction(cc.Sequence:create({
            cc.MoveBy:create(4, cc.p(-display.width/2, 0)),
            cc.RemoveSelf:create()
        }))
        self.roleView_.spineLayer = nil
        self.roleView_.cardSpine  = nil
    end

    -- create new spine
    if self:isReallyTeamReadied_() and captainCardGuid > 0 then
        local gameMgr    = self:GetFacade():GetManager('GameManager')
        local cardData   = gameMgr:GetCardDataById(captainCardGuid) or {}
        local cardId     = checkint(cardData.cardId)
        local skinId     = cardData.defaultSkinId
        local spineLayer = display.newLayer()
        local cardSpine  = AssetsUtils.GetCardSpineNode({skinId = skinId, cacheName = SpineCacheName.TOWER, spineName = skinId})
        cardSpine:update(0)
        cardSpine:setScale(0.45)
        cardSpine:setAnimation(0, 'idle', true)
        self.roleView_.spineLayer = spineLayer
        self.roleView_.cardSpine  = cardSpine
        self.currentRoleCardGuid_ = captainCardGuid
        self.roleView_:addChild(spineLayer)
        spineLayer:addChild(cardSpine)

        local spinePos = utils.getLocalCenter(self.roleView_)
        if self.towerHomeMdt_:isFromBattle() and towerModel:isUnitReadied() then
            spineLayer:setPosition(spinePos)
        else
            spineLayer:setScaleX(0.5)
            spineLayer:setScaleY(2)
            spineLayer:setOpacity(0)
            spineLayer:setPosition(spinePos.x, spinePos.y + display.height)
            spineLayer:runAction(cc.Sequence:create(
                cc.Sequence:create({
                    cc.FadeIn:create(0.25),
                    cc.MoveTo:create(0.25, spinePos)
                }),
                cc.CallFunc:create(function()
                    PlayAudioClip(AUDIOS.UI.ui_relic_cut.id)
                end),
                cc.ScaleTo:create(0.08, 1.2, 0.6),
                cc.ScaleTo:create(0.08, 0.8, 1.1),
                cc.ScaleTo:create(0.04, 1.1, 0.9),
                cc.ScaleTo:create(0.04, 1)
            ))
        end
    end
end
function TowerQuestMapMediator:udpateChestInfo_()
    local towerModel         = self.towerHomeMdt_:getTowerModel()
    local unitDefine         = towerModel:getUnitDefineModel()
    local unitConfig         = towerModel:getUnitConfigModel()
    local currentUnitId      = unitDefine and unitDefine:getUnitId() or 0
    local towerUnitConf      = checktable(CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.UNIT ,'tower'))[tostring(currentUnitId)] or {}
    local chestLevel         = self:isReallyTeamReadied_() and table.nums(unitConfig:getContractSelectedIdList() or {}) or 0
    local chestId            = checkint(towerUnitConf[string.fmt('chestId%1', chestLevel + 1)])  -- 1 is base, 2 is level 1
    local nowMapUnitViewData = self.nowMapUnitView_:getViewData()

    -- check same chest
    if checkint(self.currentChestId_) == chestId then
        return
    end

    -- check chest effect
    if self.currentChestLevel_ ~= nil then
        nowMapUnitViewData.chestEffectSpine:setToSetupPose()
        if chestLevel > checkint(self.currentChestLevel_) then
            nowMapUnitViewData.chestEffectSpine:setAnimation(0, 'play1', false)  -- upgrade
            PlayAudioClip(AUDIOS.UI.ui_relic_levelup.id)
        else
            nowMapUnitViewData.chestEffectSpine:setAnimation(0, 'play2', false)  -- downgrade
        end
    end

    -- update chest level
    for i = 1, #nowMapUnitViewData.chestLevelHideList do
        local hideIcon = nowMapUnitViewData.chestLevelHideList[i]
        local showIcon = nowMapUnitViewData.chestLevelShowList[i]
        if hideIcon then hideIcon:setVisible(i > chestLevel) end
        if showIcon then showIcon:setVisible(i <= chestLevel) end
    end

    -- clean old spine
    nowMapUnitViewData.chestImageLayer:removeAllChildren()
    
    if chestId > 0 then
        nowMapUnitViewData.chestLayer:setVisible(true)
        nowMapUnitViewData.chestLightParticle:setVisible(true)

        -- create new chest
        local chestImg = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(chestId)), 0, 0, {enable = true, ap = display.CENTER_BOTTOM})
        display.commonUIParams(chestImg, {cb = handler(self, self.onClickChestImgHandler_), animate = false})
        chestImg:setPosition(utils.getLocalCenter(nowMapUnitViewData.chestImageLayer))
        nowMapUnitViewData.chestImageLayer:addChild(chestImg)

        if self.towerHomeMdt_:isFromBattle() and towerModel:isUnitReadied() then
            nowMapUnitViewData.chestInfoLayer:setPosition(nowMapUnitViewData.chestInfoFlyPos)
            self.nowMapUnitView_:playChestLevitateAction()

        else
            -- first create chest
            if not self.currentChestId_ then
                nowMapUnitViewData.chestLight:setScaleY(0)
                nowMapUnitViewData.chestLight:setScaleX(0.1)
                nowMapUnitViewData.chestInfoLayer:setOpacity(0)
                nowMapUnitViewData.chestInfoLayer:setPosition(nowMapUnitViewData.chestInfoDownPos)
                
                local chestShowParticle = cc.ParticleSystemQuad:create('ui/tower/path/particle/chest_show.plist')
                chestShowParticle:setAutoRemoveOnFinish(true)
                chestShowParticle:setPositionX(nowMapUnitViewData.chestInfoDownPos.x)
                chestShowParticle:setPositionY(nowMapUnitViewData.chestInfoDownPos.y + chestImg:getContentSize().height/2)
                nowMapUnitViewData.chestLayer:addChild(chestShowParticle)
                
                if towerModel:isUnitPassed() then
                    nowMapUnitViewData.chestLightParticle:setVisible(false)
                    nowMapUnitViewData.chestLayer:runAction(cc.Sequence:create({
                        cc.DelayTime:create(0.2),
                        cc.TargetedAction:create(nowMapUnitViewData.chestInfoLayer, cc.FadeIn:create(0.1))
                    }))
                else
                    nowMapUnitViewData.chestLayer:runAction(cc.Sequence:create({
                        cc.DelayTime:create(0.2),
                        cc.TargetedAction:create(nowMapUnitViewData.chestInfoLayer, cc.FadeIn:create(0.1)),
                        cc.DelayTime:create(0.2),
                        cc.Spawn:create({
                            cc.TargetedAction:create(nowMapUnitViewData.chestInfoLayer, cc.JumpTo:create(0.5, nowMapUnitViewData.chestInfoFlyPos, 40, 1)),
                            cc.Sequence:create({
                                cc.TargetedAction:create(nowMapUnitViewData.chestLight, cc.ScaleTo:create(0.1, 0.1, 1)),
                                cc.TargetedAction:create(nowMapUnitViewData.chestLight, cc.ScaleTo:create(0.2, 1))
                            }),
                            cc.CallFunc:create(function()
                                PlayAudioClip(AUDIOS.UI.ui_relic_appear.id)
                            end)
                        }),
                        cc.CallFunc:create(function()
                            if self.nowMapUnitView_ then
                                self.nowMapUnitView_:playChestLevitateAction()
                            end
                        end)
                    }))
                end
            end
        end
    end

    -- update chest data
    self.currentChestId_    = chestId
    self.currentChestLevel_ = chestLevel
end


function TowerQuestMapMediator:updateUnitPassedStatus_()
    local towerModel         = self.towerHomeMdt_:getTowerModel()
    local nowMapUnitViewData = self.nowMapUnitView_:getViewData()

    if towerModel:isUnitPassed() then
        nowMapUnitViewData.chestOpenImg:setVisible(true)
        
        self.nowMapUnitView_:stopChestOpenAction()
        nowMapUnitViewData.chestOpenImg:setScaleX(0)
        nowMapUnitViewData.chestOpenImg:runAction(cc.Sequence:create({
            cc.DelayTime:create(0.1),
            cc.EaseElasticOut:create(cc.ScaleTo:create(0.6, 1)),
            cc.CallFunc:create(function()
                self.nowMapUnitView_:playChestOpenAction()
            end)
        }))

    else
        nowMapUnitViewData.chestOpenImg:setVisible(false)
        self.nowMapUnitView_:stopChestOpenAction()
    end

    self:updateFightButtonStatus_()
end


function TowerQuestMapMediator:showEditCardTeamLayer_()
    local towerModel       = self.towerHomeMdt_:getTowerModel()
    local unitDefineModel  = towerModel:getUnitDefineModel()
    local unitConfigModel  = towerModel:getUnitConfigModel()
    local editCardTeamArgs = {
        cardLibrary = towerModel:getCardLibrary(),
    }
    if unitDefineModel then
        editCardTeamArgs.towerUnitId     = unitDefineModel:getUnitId()
        editCardTeamArgs.contractIdList  = unitDefineModel:getContractIdList()
        editCardTeamArgs.chestRewardsMap = unitDefineModel:getChestRewardsMap()
    end
    if unitConfigModel then
        editCardTeamArgs.selectedCardList     = clone(unitConfigModel:getCardIdList())
        editCardTeamArgs.selectedSkillList    = clone(unitConfigModel:getSkillIdList())
        editCardTeamArgs.selectedContractList = clone(unitConfigModel:getContractSelectedIdList())
    end
    local editCardTeamMdt = EditCardTeamMediator.new(editCardTeamArgs)
    self:GetFacade():RegistMediator(editCardTeamMdt)
end


function TowerQuestMapMediator:toBattleVictory_()
    local towerModel         = self.towerHomeMdt_:getTowerModel()
    local currentFloor       = checkint(towerModel:getCurrentFloor())
    local nowMapUnitViewData = self.nowMapUnitView_:getViewData()

    if self.roleView_.cardSpine then
        self.roleView_.cardSpine:setToSetupPose()
        self.roleView_.cardSpine:setAnimation(0, 'win', false)
        self.roleView_.cardSpine:addAnimation(0, 'idle', true)
    end

    -- check unit passed
    if currentFloor % TowerQuestModel.UNIT_PATH_NUM == 0 then
        nowMapUnitViewData.chestLightParticle:setVisible(false)
        self.nowMapUnitView_:stopChestLevitateAction()

        -- unit passed
        towerModel:setUnitPassed(true)
        self:updateFightButtonStatus_()

        -- chest floor action
        self.isControllable_ = false
        self.mapUIView_:runAction(cc.Sequence:create({
            cc.DelayTime:create(0.2),
            cc.TargetedAction:create(nowMapUnitViewData.chestLight, cc.ScaleTo:create(0.2, 0.1, 1)),
            cc.TargetedAction:create(nowMapUnitViewData.chestLight, cc.ScaleTo:create(0.1, 0.1, 0)),
            cc.DelayTime:create(0.2),
            cc.TargetedAction:create(nowMapUnitViewData.chestInfoLayer, cc.EaseCubicActionIn:create(cc.MoveTo:create(0.2, nowMapUnitViewData.chestInfoDownPos))),
            cc.CallFunc:create(function()
                local chestFloorParticle = cc.ParticleSystemQuad:create('ui/tower/path/particle/chest_floor.plist')
                chestFloorParticle:setAutoRemoveOnFinish(true)
                chestFloorParticle:setPositionX(nowMapUnitViewData.chestInfoDownPos.x)
                chestFloorParticle:setPositionY(nowMapUnitViewData.roleNodeY)
                nowMapUnitViewData.chestLayer:addChild(chestFloorParticle)
                PlayAudioClip(AUDIOS.UI.ui_relic_appear.id)
            end),
            cc.CallFunc:create(function()
                self:updateUnitPassedStatus_()
                self.isControllable_ = true
            end)
        }))

    -------------------------------------------------
    -- to next floor
    else
        local unitIndex = currentFloor % TowerQuestModel.UNIT_PATH_NUM
        unitIndex = (currentFloor ~= 0 and unitIndex == 0) and TowerQuestModel.UNIT_PATH_NUM or unitIndex

        -- path action
        local pathNode   = nowMapUnitViewData.pathNodes[unitIndex + 1]
        local pathAction = self.nowMapUnitView_:createPathProgressAction(pathNode)

        -- unit action
        local unitAction = nil
        local unitNode   = nowMapUnitViewData.unitNodes[unitIndex]
        if unitNode then
            unitAction = cc.Sequence:create({
                cc.TargetedAction:create(unitNode.pointImg, cc.FadeOut:create(0.5)),
                cc.TargetedAction:create(unitNode.pointImg, cc.Hide:create())
            })
        end

        -- next floor action
        self.isControllable_ = false
        self.mapUIView_:runAction(cc.Sequence:create({
            pathAction,
            cc.Spawn:create({
                unitAction,
                cc.CallFunc:create(function()
                    self.isControllable_ = true

                    -- update current floor
                    currentFloor = currentFloor + 1
                    towerModel:setCurrentFloor(currentFloor)
                end)
            })
        }))
    end
end
function TowerQuestMapMediator:toBattleFailure_()
    if self.roleView_.cardSpine then
        self.roleView_.cardSpine:setToSetupPose()
        self.roleView_.cardSpine:setAnimation(0, 'die', false)
        self.roleView_.cardSpine:addAnimation(0, 'idle', true)
    end
    self.isControllable_ = true
end


function TowerQuestMapMediator:switchToNextUnitMap_()
    local towerModel = self.towerHomeMdt_:getTowerModel()
    self.nextMapUnitView_:reloadBackground()

    local switchActTime  = 0.8
    local currentRolePos = cc.p(self.roleView_:getPosition())

    local nowMapUnitViewData = self.nowMapUnitView_:getViewData()
    local lastNowPathNode    = nowMapUnitViewData.pathNodes[#nowMapUnitViewData.pathNodes]
    local lastNowPathAction  = self.nowMapUnitView_:createPathProgressAction(lastNowPathNode, switchActTime)

    local nextMapUnitViewData = self.nextMapUnitView_:getViewData()
    local firstNextPathNode   = nextMapUnitViewData.pathNodes[1]
    local firstNextPathAction = self.nextMapUnitView_:createPathProgressAction(firstNextPathNode, 0.5)

    self.isControllable_ = false
    self.mapUIView_:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.nowMapUnitView_, cc.MoveTo:create(switchActTime, cc.p(-display.width, 0))),
            cc.TargetedAction:create(self.nextMapUnitView_, cc.MoveTo:create(switchActTime, cc.p(0, 0))),
            cc.TargetedAction:create(self.roleView_, cc.MoveTo:create(switchActTime, cc.p(currentRolePos.x - display.width, currentRolePos.y))),
            lastNowPathAction,
        }),
        firstNextPathAction,
        cc.CallFunc:create(function()
            -- reset views status
            if self.roleView_.spineLayer and self.roleView_.spineLayer:getParent() then
                self.roleView_.spineLayer:removeFromParent()
                self.roleView_.spineLayer = nil
                self.roleView_.cardSpine  = nil
            end

            -- switch now & next mapUnitView
            local tempMapUnitView = self.nowMapUnitView_
            self.nowMapUnitView_  = self.nextMapUnitView_
            self.nextMapUnitView_ = tempMapUnitView
            self.nowMapUnitView_:setPosition(cc.p(0, 0))
            self.nextMapUnitView_:setPosition(cc.p(display.width, 0))

            -- clean data cache
            self.currentRoleCardGuid_ = nil
            self.currentChestId_      = nil
            self.currentChestLevel_   = nil

            -- reset model status
            towerModel:setUnitPassed(false)
            towerModel:setUnitReadied(false)
            towerModel:setUnconfirmedConfig(true)
            towerModel:setCurrentFloor(towerModel:getCurrentFloor() + 1)

            -- update views status
            self:updateMapPathInfo_()
            self:updateUnitInfo_(true)
            self:updateUnitConfigInfo_()
            self:updateUnitPassedStatus_()

            self.nowMapUnitView_:showMapElement()
            self.isControllable_ = true
        end)
    }))
end

function TowerQuestMapMediator:EnterBattleByPresetTeam(responseData)
    local towerModel    = self.towerHomeMdt_:getTowerModel()
    local unitDefine    = towerModel:getUnitDefineModel()
    local unitConfig    = towerModel:getUnitConfigModel()

    responseData = responseData or {}
    local presetTeamInfo = responseData.info or {}
    local fixedTeamData = {}
    local cardIdList = unitConfig:getCardIdList()
    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        local playerCardId = checkint(cardIdList[i])
        if playerCardId > 0 then
            for teamIndex, cardInfoList in pairs(presetTeamInfo) do
                for _, cardInfo in pairs(cardInfoList) do
                    if playerCardId == checkint(cardInfo.id) then
                        --- 把最新卡牌数据的 堕神和神器数据 替换为 预设编队中卡牌拥有的堕神和神器数据
                        local cardData = clone(gameMgr:GetCardDataById(playerCardId))
                        cardData.pets = cardInfo.pets or {}
                        cardData.artifactTalent = cardInfo.artifactTalent or {}
                        table.insert(fixedTeamData, cardData)
                        break
                    end
                end
            end
            -- table.insert(fixedTeamData, gameMgr:GetCardDataById(playerCardId))
        else
            table.insert(fixedTeamData, {})
        end
    end
     print("----------------------------------------")
     print(tableToString(fixedTeamData))
     print("----------------------------------------")
    local currentUnitId = unitDefine and unitDefine:getUnitId() or 0
    --AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "31-01"})
    --AppFacade.GetInstance():DispatchObservers("DOT_SET_LOG_EVENT" , {eventId = "31-02"})

    local battleConstructor = require('battleEntry.BattleConstructorEx').new()
    local fromToStruct      = BattleMediatorsConnectStruct.New(nil, nil)
    local teamCustomId      = checkint(towerModel:getTeamCustomId())
    if teamCustomId <= 0 then
        teamCustomId = nil
    end
    local serverCommand     = BattleNetworkCommandStruct.New(
            POST.TOWER_QUEST_AT.cmdName, {floor = towerModel:getCurrentFloor()}, POST.TOWER_QUEST_AT.sglName,
            POST.TOWER_QUEST_GRADE.cmdName, {teamCustomId = teamCustomId, seasonId = towerModel:getSeasonId()}, POST.TOWER_QUEST_GRADE.sglName,
            POST.TOWER_QUEST_BUY_LIVE.cmdName, {}, POST.TOWER_QUEST_BUY_LIVE.sglName
    )

    --- 友方阵容
    local formattedFriendTeamData = battleConstructor:GetFormattedTeamsDataByTeamsCardData({[1] = fixedTeamData})

    --- 敌方阵容
    local currentFloor = towerModel:getCurrentFloor()
    local formattedEnemyTeamData = battleConstructor:ExConvertEnemyFormationData(
            nil, QuestBattleType.TOWER, {
                unitId = currentUnitId, currentFloor = currentFloor
            })

    --- check is disable revive
    local isOpenRevive  = true
    local contractConfs = CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.CONTRACT ,'tower') or {}
    for i, contractId in ipairs(unitConfig:getContractSelectedIdList()) do
        local contractConf = contractConfs[tostring(contractId)] or {}
        local contractId   = checkint(contractConf.id)
        if checkint(contractId) == UnitContractModel.ID_REVIVE_DISABLED then
            isOpenRevive = false
            break
        end
    end

    local config = battleConstructor:ConvertTowerUnit2StageConfig(currentUnitId, currentFloor)
    battleConstructor:InitByCommonDataWithStageConfig(
            config, nil, QuestBattleType.TOWER, nil,                  --- 关卡相关数据
            formattedFriendTeamData, formattedEnemyTeamData,               --- 友方阵容 和 敌方阵容
            unitConfig:getSkillIdList(), unitConfig:getSkillIdList(),          --- 友方技能
            nil, nil,                       --- 敌方技能
            unitConfig:getContractSelectedIdList(), nil, ---  buff 相关
            towerModel:getReviveTimes(), towerModel:getReviveLimit(), isOpenRevive,
            nil, false,
            serverCommand, fromToStruct
    )

    self.isControllable_ = false
    transition.execute(self.mapUIView_, nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})

    ---- call to battle
    if not AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator') then
        local enterBattleMediator = require('Game.mediator.EnterBattleMediator').new()
        AppFacade.GetInstance():RegistMediator(enterBattleMediator)
    end
    AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)
end

function TowerQuestMapMediator:EnterBattle()
    local towerModel    = self.towerHomeMdt_:getTowerModel()
    local unitDefine    = towerModel:getUnitDefineModel()
    local unitConfig    = towerModel:getUnitConfigModel()

    local currentUnitId = unitDefine and unitDefine:getUnitId() or 0
    if currentUnitId == 0 then
        app.uiMgr:ShowInformationTips(__('不存在的的爬塔单元id'))
        return
    end

    --AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "31-01"})
    --AppFacade.GetInstance():DispatchObservers("DOT_SET_LOG_EVENT" , {eventId = "31-02"})
    ------------ 初始化战斗构造器 ------------
    local battleConstructor = require('battleEntry.BattleConstructor').new()
    local fromToStruct      = BattleMediatorsConnectStruct.New(nil, nil)
    local serverCommand     = BattleNetworkCommandStruct.New(
            POST.TOWER_QUEST_AT.cmdName, {floor = towerModel:getCurrentFloor()}, POST.TOWER_QUEST_AT.sglName,
            POST.TOWER_QUEST_GRADE.cmdName, {seasonId = towerModel:getSeasonId()}, POST.TOWER_QUEST_GRADE.sglName,
            POST.TOWER_QUEST_BUY_LIVE.cmdName, {}, POST.TOWER_QUEST_BUY_LIVE.sglName
    )

    -- 判断是否可以出战
    -- local canBattle, waringText = battleConstructor:CanEnterBattleByCardIds(unitConfig:getCardIdList())
    -- if not canBattle then
    --     if nil ~= waringText then
    --         uiManager:ShowInformationTips(waringText)
    --     end
    --     return
    -- end

    -- check is disable revive
    local isOpenRevive  = true
    local contractConfs = CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.CONTRACT ,'tower') or {}
    for i, contractId in ipairs(unitConfig:getContractSelectedIdList()) do
        local contractConf = contractConfs[tostring(contractId)] or {}
        local contractId   = checkint(contractConf.id)
        if checkint(contractId) == UnitContractModel.ID_REVIVE_DISABLED then
            isOpenRevive = false
            break
        end
    end

    battleConstructor:InitDataByTower(
            currentUnitId,
            towerModel:getCurrentFloor(),
            towerModel:getReviveTimes(),
            towerModel:getReviveLimit(),
            isOpenRevive,
            unitConfig:getCardIdList(),
            unitConfig:getSkillIdList(),
            serverCommand,
            fromToStruct,
            unitConfig:getContractSelectedIdList()
    )

    if self.mapUIView_ ~= nil and not tolua.isnull(self.mapUIView_) then
        self.isControllable_ = false
        transition.execute(self.mapUIView_, nil, {delay = 0.3, complete = function()
            self.isControllable_ = true
        end})
    end

    -- call to battle
    if not AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator') then
        local enterBattleMediator = require('Game.mediator.EnterBattleMediator').new()
        AppFacade.GetInstance():RegistMediator(enterBattleMediator)
    end
    AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)
    ------------ 初始化战斗构造器 ------------
end


-------------------------------------------------
-- handler

function TowerQuestMapMediator:onClickExitButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local gameMgr = self:GetFacade():GetManager('GameManager')
    local tipText = __('是否放弃当前的挑战进度？')
    gameMgr:ShowGameAlertView({text = tipText, callback = function()
        self:SendSignal(POST.TOWER_EXIT.cmdName)

        if self.mapUIView_ ~= nil and not tolua.isnull(self.mapUIView_) then
            self.isControllable_ = false
            transition.execute(self.mapUIView_, nil, {delay = 0.3, complete = function()
                self.isControllable_ = true
            end})
        end
    end})
end


function TowerQuestMapMediator:onClickFightButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local towerModel    = self.towerHomeMdt_:getTowerModel()
    local teamId = checkint(towerModel:getTeamCustomId())
    if teamId > 0 then
        ---获取预设编队阵容卡牌数据
        self:SendSignal(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.cmdName, {teamId = teamId})
        return
    end
    self:EnterBattle()
end


function TowerQuestMapMediator:onClickBossHotspotHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    
    local towerModel    = self.towerHomeMdt_:getTowerModel()
    local unitDefine    = towerModel:getUnitDefineModel()
    local currentUnitId = unitDefine and unitDefine:getUnitId() or 0
    local towerUnitConf = checktable(CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.UNIT ,'tower'))[tostring(currentUnitId)] or {}
    if #checktable(towerUnitConf.monsterInfo) > 0 then
        AppFacade.GetInstance():RegistMediator(BossDetailMediator.new({towerUnitId = currentUnitId}))
    end
end


function TowerQuestMapMediator:onClickEditTeamButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:showEditCardTeamLayer_()
end


function TowerQuestMapMediator:onClickChestImgHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local towerModel         = self.towerHomeMdt_:getTowerModel()
    local nowMapUnitViewData = self.nowMapUnitView_:getViewData()

    -- check unit passed
    if towerModel:isUnitPassed() then
        self.nowMapUnitView_:stopChestOpenAction()
        nowMapUnitViewData.chestOpenImg:runAction(cc.Sequence:create({
            cc.ScaleTo:create(0.2, 0, 1),
            cc.Hide:create()
        }))

        self:SendSignal(POST.TOWER_UNIT_DRAW_REWARD.cmdName)

    else
        if not self.priviewContractViewData_ then
            self.priviewContractViewData_ = self:createPreviewContractViewData_()

            -- show contract
            local homeScene = self.towerHomeMdt_:getHomeScene()
            homeScene:AddDialog(self.priviewContractViewData_.view)
            self.priviewContractViewData_.show()

            display.commonUIParams(self.priviewContractViewData_.blackBg, {cb = function(sender)
                self.priviewContractViewData_.close(function()
                    if self.priviewContractViewData_ then
                        homeScene:RemoveDialog(self.priviewContractViewData_.view)
                    end
                    self.priviewContractViewData_ = nil
                end)
            end})
        end

    end

    self.isControllable_ = false
    transition.execute(self.mapUIView_, nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})
end
function TowerQuestMapMediator:createPreviewContractViewData_()
    local view = display.newLayer()

    local blackBg = display.newLayer(0, 0, {color = cc.r4b(0), enable = true})
    view:addChild(blackBg)

    local contractArgs     = {}
    local towerModel       = self.towerHomeMdt_:getTowerModel()
    local unitDefineModel  = towerModel:getUnitDefineModel()
    local unitConfigModel  = towerModel:getUnitConfigModel()
    if unitDefineModel then
        contractArgs.towerUnitId     = unitDefineModel:getUnitId()
        contractArgs.contractIdList  = unitDefineModel:getContractIdList()
        contractArgs.chestRewardsMap = unitDefineModel:getChestRewardsMap()
    end
    if unitConfigModel and self:isReallyTeamReadied_() then
        contractArgs.selectedContractList = clone(unitConfigModel:getContractSelectedIdList())
    end
    local contractMdt = ContractMediator.new(contractArgs)
    self:GetFacade():RegistMediator(contractMdt)

    local contractView = contractMdt:GetViewComponent()
    contractView:setAnchorPoint(display.RIGHT_CENTER)
    contractView:setPosition(display.width, display.cy)
    view:addChild(contractView)

    contractView:setScaleY(0)
    return {
        view    = view,
        blackBg = blackBg,
        show    = function()
            view:runAction(cc.Sequence:create({
                cc.TargetedAction:create(contractView, cc.ScaleTo:create(0.2, 1)),
            }))
        end,
        close   = function(endCb)
            view:runAction(cc.Sequence:create({
                cc.TargetedAction:create(contractView, cc.ScaleTo:create(0.1, 1, 0)),
                cc.CallFunc:create(function()
                    if contractMdt then
                        contractMdt:close()
                        contractMdt = nil
                    end
                    if endCb then endCb() end
                end)
            }))
        end
    }
end


return TowerQuestMapMediator
