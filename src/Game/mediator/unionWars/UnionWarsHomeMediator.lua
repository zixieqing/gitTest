--[[
 * author : kaishiqi
 * descpt : 工会战 - 主界面中介者
]]
local UnionWarsModelFactory = require('Game.models.UnionWarsModelFactory')
local UnionWarsModel        = UnionWarsModelFactory.UnionWarsModel
local UnionWarsMapModel     = UnionWarsModelFactory.WarsMapModel
local UnionWarsSiteModel    = UnionWarsModelFactory.WarsSiteModel
local UnionWarsHomeMediator = class('UnionWarsHomeMediator', mvc.Mediator)

function UnionWarsHomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'UnionWarsHomeMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- life cycle
function UnionWarsHomeMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.warsHomeScene_ = app.uiMgr:SwitchToTargetScene('Game.views.unionWars.UnionWarsHomeScene')
    self:SetViewComponent(self.lobbyScene_)

    -- add listen
    local uiViewData  = self:getWarsHomeScene():getUIViewData()
    local mapViewData = self:getWarsHomeScene():getMapViewData()
    uiViewData.battleBtn:SetClickCallback(handler(self, self.onClickBattleButtonHandler_), false)
    display.commonUIParams(uiViewData.backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    display.commonUIParams(uiViewData.unionInfoBar, {cb = handler(self, self.onClickUnionInfoBarHandler_)})
    display.commonUIParams(uiViewData.rewardsBtn, {cb = handler(self, self.onClickRewardsButtonHandler_), animate = false})
    display.commonUIParams(uiViewData.reportBtn, {cb = handler(self, self.onClickReportButtonHandler_)})
    display.commonUIParams(uiViewData.applyBtn, {cb = handler(self, self.onClickApplyButtonHandler_)})
    display.commonUIParams(uiViewData.defendBtn, {cb = handler(self, self.onClickDefendButtonHandler_)})
    display.commonUIParams(uiViewData.unionBtn, {cb = handler(self, self.onClickUnionButtonHandler_)})
    display.commonUIParams(uiViewData.shopBtn, {cb = handler(self, self.onClickShopButtonHandler_)})
    display.commonUIParams(mapViewData.nextMapBtn, {cb = handler(self, self.onClickNextMapButtonHandler_)})
    display.commonUIParams(mapViewData.prevMapBtn, {cb = handler(self, self.onClickPrevMapButtonHandler_)})
    self:getWarsHomeScene():getMapLayer():setClickMapSiteCB(handler(self, self.onCLickMapSiteNodeHandler_))
    self:getWarsHomeScene():getMapLayer():setClickMapBossCB(handler(self, self.onCLickMapBossNodeHandler_))

    -- init unionWarsModel
    if not app.unionMgr:getUnionWarsModel() then
        app.unionMgr:setUnionWarsModel(UnionWarsModel.new())
    end
    self:updateUnionWarsModel_(self.ctorArgs_)
    
    -- init map index
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    self:getWarsMapLayer():setMapPageIndex(unionWarsModel:getMapPageIndex(), true)
    
    -- update ui views
    self:updateWarsEnemyInfo_()
    self:updateWatchCampInfo_()
    self:updateWarsHomeLeftTime_()
    self:updateWarsHomeSceneStep_()
    self:updateAllMapNodeStatus_()
    self:checkShowMatchingView_()
end


function UnionWarsHomeMediator:CleanupView()
end


function UnionWarsHomeMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")

    -- reg post
    regPost(POST.UNION_WARS_HOME_SYNC)
    regPost(POST.UNION_WARS_UNION_MAP)
    regPost(POST.UNION_WARS_ENEMY_MAP)
    regPost(POST.UNION_WARS_DEFEND_TEAM)

    -- show ui
    self.isControllable_ = false
    self:getWarsHomeScene():showUI(function()
        self.isControllable_ = true
        self:checkRequestMapModel_()

        -- wars join rewards
        local warsJoinRewards = self.ctorArgs_.joinRewards 
        if warsJoinRewards and #warsJoinRewards > 0 then
            app.uiMgr:AddDialog('common.RewardPopup', {rewards = warsJoinRewards, msg = __('工会竞赛参与奖励'), closeCallback = function()
                self:checkShowWarsResultView_()
            end})
        else
            self:checkShowWarsResultView_()
        end
    end)
end


function UnionWarsHomeMediator:OnUnRegist()
    -- un-reg post
    unregPost(POST.UNION_WARS_HOME_SYNC)
    unregPost(POST.UNION_WARS_UNION_MAP)
    unregPost(POST.UNION_WARS_ENEMY_MAP)
    unregPost(POST.UNION_WARS_DEFEND_TEAM)

    -- stop countdown
    app.unionMgr:stopUnionWarsCountdown()
end


function UnionWarsHomeMediator:InterestSignals()
    return {
        POST.UNION_WARS_HOME_SYNC.sglName,
        POST.UNION_WARS_UNION_MAP.sglName,
        POST.UNION_WARS_ENEMY_MAP.sglName,
        POST.UNION_WARS_DEFEND_TEAM.sglName,
        SGL.UNION_WARS_CLOSE,
        SGL.UNION_WARS_COUNTDOWN_UPDATE,
        SGL.UNION_WARS_TIME_LINE_INDEX_CHANGE,
        SGL.UNION_WARS_WATCH_MAP_CAMP_CHANGE,
        SGL.UNION_WARS_WATCH_MAP_PAGE_CHANGE,
        SGL.UNION_WARS_UNION_MAP_MODEL_CHANGE,
        SGL.UNION_WARS_ENEMY_MAP_MODEL_CHANGE,
        SGL.UNION_WARS_EDIT_DEFEND_TEAM_CHANGE,
        SGL.UNION_WARS_UNION_APPALY_SUCCEED,
        SGL.UNION_WARS_ATTACK_START_NOTICE,
        SGL.UNION_WARS_DEFEND_START_NOTICE,
        SGL.UNION_WARS_ATTACK_ENDED_NOTICE,
        SGL.UNION_WARS_DEFEND_ENDED_NOTICE,
    }
end
function UnionWarsHomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -------------------------------------------------
    -- sync unionWars homeData
    if name == POST.UNION_WARS_HOME_SYNC.sglName then
        self:updateUnionWarsModel_(data)


    -------------------------------------------------
    -- update unionMap data
    elseif name == POST.UNION_WARS_UNION_MAP.sglName then
        local unionWarsModel = app.unionMgr:getUnionWarsModel()
        if unionWarsModel then
            local isJoinWars = false

            -- update unionMapData
            local myUnionData   = app.unionMgr:getUnionData() or {}
            local unionMapModel = UnionWarsMapModel.new()
            unionMapModel:setUnionName(myUnionData.name)
            unionMapModel:setUnionAvatar(myUnionData.avatar)
            unionMapModel:setUnionLevel(myUnionData.level)
            unionMapModel:setWarsBossRQuestId(data.warsBossRQuestId)
            unionMapModel:setWarsBossSRQuestId(data.warsBossSRQuestId)
            unionMapModel:setWarsBossRLevel(data.warsBossRLevel)
            unionMapModel:setWarsBossSRLevel(data.warsBossSRLevel)

            -- update all siteData
            for index, siteData in ipairs(data.warsBuildings or {}) do
                if checkint(siteData.playerId) > 0 then
                    local mapSiteModel = UnionWarsSiteModel.new()
                    mapSiteModel:setBuildingId(siteData.buildingId)
                    mapSiteModel:setPlayerId(siteData.playerId)
                    mapSiteModel:setPlayerLevel(siteData.playerLevel)
                    mapSiteModel:setPlayerName(siteData.playerName)
                    mapSiteModel:setPlayerAvatar(siteData.playerAvatar)
                    mapSiteModel:setPlayerAvatarFrame(siteData.playerAvatarFrame)
                    mapSiteModel:setPlayerCards(siteData.playerCards)
                    mapSiteModel:setPlayerHP(siteData.playerHp)
                    mapSiteModel:setDefendState(siteData.isDefending)
                    mapSiteModel:setDefendDebuff(siteData.defendDebuff)
                    unionMapModel:setMapSiteModel(siteData.buildingId, mapSiteModel)

                    if checkint(mapSiteModel:getPlayerId()) == app.gameMgr:GetUserInfo().playerId then
                        isJoinWars = true
                    end
                end
            end
            unionWarsModel:setUnionMapModel(unionMapModel)
            self:getWarsHomeScene():updateAppliedState(unionWarsModel:isAppliedUnionWars())

            -- request enemyMapData
            local unionWarsStepId = unionWarsModel:getWarsStepId()
            if unionWarsModel:isAppliedUnionWars() and not unionWarsModel:getEnemyMapModel() and unionWarsStepId == UNION_WARS_STEPS.FIGHTING then
                self:SendSignal(POST.UNION_WARS_ENEMY_MAP.cmdName)
            end

            -- record self joinWars status
            unionWarsModel:setJoinMember(isJoinWars)
        end


    -------------------------------------------------
    -- update enemyMap data
    elseif name == POST.UNION_WARS_ENEMY_MAP.sglName then
        local unionWarsModel = app.unionMgr:getUnionWarsModel()
        if unionWarsModel then

            -- update enemyMapData
            local unionMapModel = UnionWarsMapModel.new()
            unionMapModel:setUnionName(data.unionName)
            unionMapModel:setUnionAvatar(data.unionAvatar)
            unionMapModel:setUnionLevel(data.unionLevel)
            unionMapModel:setWarsBossRQuestId(data.warsBossRQuestId)
            unionMapModel:setWarsBossSRQuestId(data.warsBossSRQuestId)
            unionMapModel:setWarsBossRLevel(data.warsBossRLevel)
            unionMapModel:setWarsBossSRLevel(data.warsBossSRLevel)
            -- update all siteData
            for index, siteData in ipairs(data.warsBuildings or {}) do
                if checkint(siteData.playerId) > 0 then
                    local mapSiteModel = UnionWarsSiteModel.new()
                    mapSiteModel:setBuildingId(siteData.buildingId)
                    mapSiteModel:setPlayerId(siteData.playerId)
                    mapSiteModel:setPlayerLevel(siteData.playerLevel)
                    mapSiteModel:setPlayerName(siteData.playerName)
                    mapSiteModel:setPlayerAvatar(siteData.playerAvatar)
                    mapSiteModel:setPlayerAvatarFrame(siteData.playerAvatarFrame)
                    mapSiteModel:setPlayerCards(siteData.playerCards)
                    mapSiteModel:setPlayerHP(siteData.playerHp)
                    mapSiteModel:setDefendState(siteData.isDefending)
                    mapSiteModel:setDefendDebuff(siteData.defendDebuff)
                    unionMapModel:setMapSiteModel(siteData.buildingId, mapSiteModel)
                end
            end
            unionWarsModel:setEnemyMapModel(unionMapModel)

            -- show matched view
            self:checkShowMatchedView_()
        end


    -------------------------------------------------
    -- unionWars set defend team
    elseif name == POST.UNION_WARS_DEFEND_TEAM.sglName then
        app.uiMgr:ShowInformationTips(__('防御编队设置成功'))
        local requestData    = data.requestData or {}
        local unionWarsModel = app.unionMgr:getUnionWarsModel()
        if unionWarsModel then
            unionWarsModel:setDefendCards(requestData.teamCards)
        end


    -------------------------------------------------
    -- unionWars close time
    elseif name == SGL.UNION_WARS_CLOSE then
        self:syncUnionWarsHome_()
        
    
    -------------------------------------------------
    -- countdown update
    elseif name == SGL.UNION_WARS_COUNTDOWN_UPDATE then
        self:updateWarsHomeLeftTime_()


    -------------------------------------------------
    -- timeLine change
    elseif name == SGL.UNION_WARS_TIME_LINE_INDEX_CHANGE then
        local unionWarsModel = app.unionMgr:getUnionWarsModel()
        local isAppliedWars  = unionWarsModel and unionWarsModel:isAppliedUnionWars() or false
        if unionWarsModel then
            if unionWarsModel:isAppliedUnionWars() then
                self:checkShowMatchingView_()
            end
        end

        self:checkRequestMapModel_()
        self:updateWarsHomeLeftTime_()
        self:updateWarsHomeSceneStep_()

        -- check fighting over
        if data.oldValue == UNION_WARS_STEPS.FIGHTING then
            self:showBackToUnionMapTips_(isAppliedWars)

            if unionWarsModel then
                if unionWarsModel:isWatchEnemyMap() then
                    -- fixed to unionMap
                    unionWarsModel:setMapPageIndex(1)
                    unionWarsModel:setWatchEnemyMap(false)
                end
            end
        end


    -------------------------------------------------
    -- watch map camp change
    elseif name == SGL.UNION_WARS_WATCH_MAP_CAMP_CHANGE then
        self:getWarsHomeScene():createSwitchCampMapEffect(function()
            local unionWarsModel = app.unionMgr:getUnionWarsModel()
            local mapPageIndex   = unionWarsModel and unionWarsModel:getMapPageIndex() or 1
            self:getWarsMapLayer():setMapPageIndex(mapPageIndex, true)
            self:updateWatchCampInfo_()
            self:updateAllSiteProgress_()
            self:updateAllMapNodeStatus_()
            self:updateWarsHomeSceneStep_()
        end)
        

    -------------------------------------------------
    -- watch map page change
    elseif name == SGL.UNION_WARS_WATCH_MAP_PAGE_CHANGE then


    -------------------------------------------------
    -- union mapModel change
    elseif name == SGL.UNION_WARS_UNION_MAP_MODEL_CHANGE then
        local unionWarsModel = app.unionMgr:getUnionWarsModel()
        if unionWarsModel then
            if unionWarsModel:isWatchEnemyMap() then
                unionWarsModel:setMapPageIndex(1)
                unionWarsModel:setWatchEnemyMap(false)
            else
                self:updateAllSiteProgress_()
                self:updateAllMapNodeStatus_()
            end
        end
        
       
    -------------------------------------------------
    -- enemy mapModel change
    elseif name == SGL.UNION_WARS_ENEMY_MAP_MODEL_CHANGE then
        self:updateWarsEnemyInfo_()
        
        local unionWarsModel = app.unionMgr:getUnionWarsModel()
        if unionWarsModel and unionWarsModel:isWatchEnemyMap() then
            self:updateWatchCampInfo_()
            self:updateAllSiteProgress_()
            self:updateAllMapNodeStatus_()
            self:updateWarsHomeSceneStep_()
        end


    -------------------------------------------------
    -- edit defend team
    elseif name == SGL.UNION_WARS_EDIT_DEFEND_TEAM_CHANGE then
        
        -- check team is empty
        local teamData = data.teamData or {}
        local errTips  = CommonUtils.ChecTeamIsEmpty(teamData)
        if errTips then
            app.uiMgr:ShowInformationTips(errTips)
        else
            local tipsTitle = __('是否确定使用该阵容参加防守？')
            --local tipsDescr = __('一旦确定防守阵容，无法更改！防守阵容卡牌将不能参加于工会进攻队伍！')
            local tipsDescr = ""
            local commonTip = require( 'common.CommonPopTip' ).new({title = tipsTitle, text = tipsDescr, textW = 330, isOnlyOK = false, callback = function ()
                -- request set defend team
                local teamStr = CommonUtils.ConvertTeamData2Str(teamData)
                self:SendSignal(POST.UNION_WARS_DEFEND_TEAM.cmdName, {teamCards = teamStr})

                -- close edit team view
                app:DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')        
            end})
            commonTip:setPosition(display.center)

            if commonTip.textLabel then
                display.commonLabelParams(commonTip.textLabel, fontWithColor(10, {fontSize = 22}))
            end
            self:getWarsHomeScene():AddDialog(commonTip)
        end


    -------------------------------------------------
    -- socket callback
    elseif name == SGL.UNION_WARS_UNION_APPALY_SUCCEED then
        app.uiMgr:ShowInformationTips(__('成功参与本轮工会竞赛报名'))
        self:SendSignal(POST.UNION_WARS_UNION_MAP.cmdName)

        
    elseif name == SGL.UNION_WARS_ATTACK_START_NOTICE or name == SGL.UNION_WARS_ATTACK_ENDED_NOTICE then
        local enemySiteId    = checkint(data.warsBuildingId)
        local unionWarsModel = app.unionMgr:getUnionWarsModel()
        local enemyMapModel  = unionWarsModel and unionWarsModel:getEnemyMapModel() or nil
        local enemySiteModel = enemyMapModel and enemyMapModel:getMapSiteModel(enemySiteId) or nil
        if unionWarsModel and enemySiteModel then

            -- update siteModel data
            if name == SGL.UNION_WARS_ATTACK_START_NOTICE then
                enemySiteModel:setDefendState(UnionWarsSiteModel.DEFEND_STATE_ON)
            else
                enemySiteModel:setDefendState(UnionWarsSiteModel.DEFEND_STATE_OFF)
                enemySiteModel:setDefendDebuff(data.defendDebuff)
                enemySiteModel:setPlayerHP(checkint(data.playerHp))
            end

            -- update siteNode status
            if unionWarsModel:isWatchEnemyMap() then
                local siteNode = self:getWarsHomeScene():getMapLayer():getMapSiteNode(enemySiteId)
                if siteNode then
                    siteNode:updateSiteStatus(enemySiteId, enemySiteModel, true)
                end
            end

            self:updateAllSiteProgress_()
        end


    elseif name == SGL.UNION_WARS_DEFEND_START_NOTICE or name == SGL.UNION_WARS_DEFEND_ENDED_NOTICE then
        local unionSiteId    = checkint(data.warsBuildingId)
        local unionWarsModel = app.unionMgr:getUnionWarsModel()
        local unionMapModel  = unionWarsModel and unionWarsModel:getUnionMapModel() or nil
        local unionSiteModel = unionMapModel and unionMapModel:getMapSiteModel(unionSiteId) or nil
        if unionWarsModel and unionSiteModel then

            -- update siteModel data
            if name == SGL.UNION_WARS_DEFEND_START_NOTICE then
                unionSiteModel:setDefendState(UnionWarsSiteModel.DEFEND_STATE_ON)
            else
                unionSiteModel:setDefendState(UnionWarsSiteModel.DEFEND_STATE_OFF)
                unionSiteModel:setDefendDebuff(data.defendDebuff)
                unionSiteModel:setPlayerHP(checkint(data.playerHp))
            end

            -- update siteNode status
            if not unionWarsModel:isWatchEnemyMap() then
                local siteNode = self:getWarsHomeScene():getMapLayer():getMapSiteNode(unionSiteId)
                if siteNode then
                    siteNode:updateSiteStatus(unionSiteId, unionSiteModel, false)
                end
            end

            self:updateAllSiteProgress_()
        end

    end
end



-------------------------------------------------
-- get / set

function UnionWarsHomeMediator:getWarsHomeScene()
    return self.warsHomeScene_
end


function UnionWarsHomeMediator:getWarsMapLayer()
    return self:getWarsHomeScene():getMapLayer()
end


function UnionWarsHomeMediator:getCurrentMapSiteModel(siteId)
    local unionSiteModel = nil
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel then
        local mapModel = unionWarsModel:isWatchEnemyMap() and unionWarsModel:getEnemyMapModel() or unionWarsModel:getUnionMapModel()
        unionSiteModel = mapModel and mapModel:getMapSiteModel(siteId) or nil
    end
    return unionSiteModel
end


function UnionWarsHomeMediator:getCurrentMapBossQuestId(pageId)
    local mapBossQuestId = 0
    local warsMapPageId  = checkint(pageId)
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel then
        local mapModel = unionWarsModel:isWatchEnemyMap() and unionWarsModel:getEnemyMapModel() or unionWarsModel:getUnionMapModel()
        if mapModel then
            if warsMapPageId == 1 then
                mapBossQuestId = checkint(mapModel:getWarsBossRQuestId())
            elseif warsMapPageId == 2 then
                mapBossQuestId = checkint(mapModel:getWarsBossSRQuestId())
            end
        end
    end
    return mapBossQuestId
end
function UnionWarsHomeMediator:getCurrentMapBossLevel(pageId)
    local mapBossLevel = 0
    local warsMapPageId  = checkint(pageId)
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel then
        local mapModel = unionWarsModel:isWatchEnemyMap() and unionWarsModel:getEnemyMapModel() or unionWarsModel:getUnionMapModel()
        if mapModel then
            if warsMapPageId == 1 then
                mapBossLevel = checkint(mapModel:getWarsBossRLevel())
            elseif warsMapPageId == 2 then
                mapBossLevel = checkint(mapModel:getWarsBossSRLevel())
            end
        end
    end
    return mapBossLevel
end


-------------------------------------------------
-- public

function UnionWarsHomeMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())

    -- back to unionLobby
    app.router:Dispatch({name = 'unionWars.UnionWarsHomeMediator'}, {name = 'UnionLobbyMediator'})
end


-------------------------------------------------
-- private

-- e.g. request warsHome
function UnionWarsHomeMediator:syncUnionWarsHome_()
    self.isControllable_ = false
    transition.execute(self:getWarsHomeScene(), nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})

    self:SendSignal(POST.UNION_WARS_HOME_SYNC.cmdName)
end


function UnionWarsHomeMediator:showBackToUnionMapTips_(isAppliedWars)
    app:UnRegsitMediator('UnionWarBattleBossMediator')
    app:UnRegsitMediator('UnionWarsEditTeamRivalMediator')
    
    local tipsText = __('本轮工会竞赛已经结束')
    if isAppliedWars == nil or isAppliedWars == true then
        if not self.isShowingCloseTipsView_ then
            local tipsView = require('common.NewCommonTip').new({text = tipsText, isOnlyOK = true, isForced = true, callback = function()
                self.isShowingCloseTipsView_ = false
            end})
            tipsView:setPosition(display.center)
            self:getWarsHomeScene():AddDialog(tipsView)
            self.isShowingCloseTipsView_ = true
        end
    else
        app.uiMgr:ShowInformationTips(tipsText)
    end
end


-- e.g. warsModel update
-- e.g. warsTime countdown
function UnionWarsHomeMediator:updateUnionWarsModel_(homeData)
    local unionWarsData  = checktable(homeData)
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel then
        unionWarsModel:cleanDeadCards()
        unionWarsModel:addDeadCards(checkstr(unionWarsData.deadCards))
        unionWarsModel:setDefendCards(checkstr(unionWarsData.defendCards))
        unionWarsModel:setPastDefendCards(checkstr(unionWarsData.pastDefendCards))
        unionWarsModel:setWarsBaseTime(checkint(unionWarsData.warsBaseTime))
        unionWarsModel:setLeftAttachNum(checkint(unionWarsData.leftAttachNum))
        unionWarsModel:setTotalAttachNum(checkint(unionWarsData.totalAttachNum))
        unionWarsModel:setPassedBuildings(unionWarsData.passedBuildings)
        unionWarsModel:setPastWarsResult(unionWarsData.pastWarsResult)
        unionWarsModel:setUnionMapModel(nil)  -- clean unionMap cache
        unionWarsModel:setEnemyMapModel(nil)  -- clean enemyMap cache

        -- check mapStaus
        local unionWarsStepId = unionWarsModel:getWarsStepId()
        if unionWarsModel:isWatchEnemyMap() and unionWarsStepId ~= UNION_WARS_STEPS.FIGHTING then
            -- fixed to unionMap
            unionWarsModel:setMapPageIndex(1)
            unionWarsModel:setWatchEnemyMap(false)
            self:showBackToUnionMapTips_()
        end

        -- start countdown
        if unionWarsModel:getWarsBaseTime() > 0 then
            app.unionMgr:startUnionWarsCountdown()
        else
            app.unionMgr:stopUnionWarsCountdown()
        end

    else
        app.unionMgr:stopUnionWarsCountdown()
    end
end


-- e.g. request union_map
-- e.g. request enemy_map
function UnionWarsHomeMediator:checkRequestMapModel_()
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel then
        local unionWarsStepId = unionWarsModel:getWarsStepId()

        if unionWarsStepId == UNION_WARS_STEPS.APPLY then
            if not unionWarsModel:getUnionMapModel() then
                self:SendSignal(POST.UNION_WARS_UNION_MAP.cmdName)
            end

        elseif unionWarsStepId == UNION_WARS_STEPS.MATCH then
            if not unionWarsModel:getUnionMapModel() then
                self:SendSignal(POST.UNION_WARS_UNION_MAP.cmdName)
            end

        elseif unionWarsStepId == UNION_WARS_STEPS.FIGHTING then
            if unionWarsModel:isWatchEnemyMap() then
                if not unionWarsModel:getEnemyMapModel() then
                    self:SendSignal(POST.UNION_WARS_ENEMY_MAP.cmdName)
                end
            else
                if not unionWarsModel:getUnionMapModel() then
                    self:SendSignal(POST.UNION_WARS_UNION_MAP.cmdName)
                elseif not unionWarsModel:getEnemyMapModel() then
                    if unionWarsModel:isAppliedUnionWars() then
                        self:SendSignal(POST.UNION_WARS_ENEMY_MAP.cmdName)
                    end
                end
            end
            
        else
            unionWarsModel:setEnemyMapModel(nil)
            unionWarsModel:setUnionMapModel(nil)
        end
    end
end


-- e.g. update campState
-- e.g. update stepState
function UnionWarsHomeMediator:updateWarsHomeSceneStep_()
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel then
        self:getWarsHomeScene():updateAppliedState(unionWarsModel:isAppliedUnionWars())
        self:getWarsHomeScene():updateWatchCampState(unionWarsModel:isWatchEnemyMap())
        self:getWarsHomeScene():updateWarsStepState(unionWarsModel:getWarsStepId())
    end
end


-- e.g. stateNode time
-- e.g. attack enemy time
function UnionWarsHomeMediator:updateWarsHomeLeftTime_()
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel then

        local countdownTime = unionWarsModel:getTimeLineLeftTime()
        if not unionWarsModel:isAppliedUnionWars() then
            local wardStepId  = unionWarsModel:getWarsStepId()
            local finishIndex = 0
            if UNION_WARS_STEPS.MATCH == wardStepId then
                finishIndex = 2
            elseif UNION_WARS_STEPS.FIGHTING == wardStepId then
                finishIndex = 1
            end
            for i = 1, finishIndex do
                local nextStepTimeModel = unionWarsModel:getWarsTimeModel(unionWarsModel:getTimeLineIndex() + i)
                countdownTime = countdownTime + nextStepTimeModel:getDuration()
            end
        end
        self:getWarsHomeScene():updateStateNodeTime(countdownTime)
        
        if self:getWarsHomeScene():isVisibleEnemyLayer() then
            self:getWarsHomeScene():updateBattleTime(countdownTime)
        end
    end
end


-- e.g. title info
function UnionWarsHomeMediator:updateWatchCampInfo_()
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel then
        if unionWarsModel:isWatchEnemyMap() then
            local enemyMapModel = unionWarsModel:getEnemyMapModel()
            if enemyMapModel then
                -- enemy union data
                self:getWarsHomeScene():updateTitleInfo({
                    unionName   = enemyMapModel:getUnionName(),
                    unionAvatar = enemyMapModel:getUnionAvatar(),
                    unionLevel  = enemyMapModel:getUnionLevel(),
                })
            else
                -- empty title
                self:getWarsHomeScene():updateTitleInfo()
            end
        else
            -- mine union data
            local mineUnionData = app.unionMgr:getUnionData() or {}
            self:getWarsHomeScene():updateTitleInfo({
                unionName   = mineUnionData.name,
                unionAvatar = mineUnionData.avatar,
                unionLevel  = mineUnionData.level,
            })
        end
    else
        -- empty title
        self:getWarsHomeScene():updateTitleInfo()
    end
end


-- e.g. attack enemy name
function UnionWarsHomeMediator:updateWarsEnemyInfo_()
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    local enemyMapModel = unionWarsModel and unionWarsModel:getEnemyMapModel() or nil
    if enemyMapModel then
        self:getWarsHomeScene():updateEnemyInfo({enemyName = enemyMapModel:getUnionName()})
    else
        self:getWarsHomeScene():updateEnemyInfo()
    end
end


-- e.g. site left/count
-- e.g. site hp progress
function UnionWarsHomeMediator:updateAllSiteProgress_()
    local siteProgressData = {
        memberNum   = 0, -- 参与成员数
        detroyNum   = 0, -- 死亡成员数
        allTotalHP  = 0, -- 全成员 总共血量
        allMemberHP = 0, -- 全成员 当前血量
    }

    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel then
        local marsMapModel = unionWarsModel:isWatchEnemyMap() and unionWarsModel:getEnemyMapModel() or unionWarsModel:getUnionMapModel()
        for siteId, warsSiteModel in pairs(marsMapModel and marsMapModel:getMapSiteModelMap() or {}) do
            local sitePlayerHP = checkint(warsSiteModel:getPlayerHP())
            siteProgressData.memberNum   = siteProgressData.memberNum + 1
            siteProgressData.detroyNum   = siteProgressData.detroyNum + (sitePlayerHP <= 0 and 1 or 0)
            siteProgressData.allTotalHP  = siteProgressData.allTotalHP + UnionWarsModel.SITE_HP_MAX
            siteProgressData.allMemberHP = siteProgressData.allMemberHP + sitePlayerHP
        end
    end
    self:getWarsHomeScene():updateSiteProgress(siteProgressData)
end


-- e.g. update site node
-- e.g. update boss node
function UnionWarsHomeMediator:updateAllMapNodeStatus_()
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    local isWatchEnemy   = unionWarsModel and unionWarsModel:isWatchEnemyMap() or false

    -- update all site node
    for siteId, siteNode in pairs(self:getWarsHomeScene():getMapLayer():getMapSiteMap()) do
        siteNode:updateSiteStatus(siteId, self:getCurrentMapSiteModel(siteId), isWatchEnemy)
    end
    
    -- update all boss node
    for pageId, siteNode in pairs(self:getWarsHomeScene():getMapLayer():getMapBossMap()) do
        siteNode:updateBossStatus(pageId, self:getCurrentMapBossQuestId(pageId))
    end
end


function UnionWarsHomeMediator:checkShowMatchingView_()
    local mineUnionData   = app.unionMgr:getUnionData() or {}
    local unionWarsModel  = app.unionMgr:getUnionWarsModel()
    local unionWarsStepId = unionWarsModel and unionWarsModel:getWarsStepId() or UNION_WARS_STEPS.UNOPEN
    if unionWarsStepId == UNION_WARS_STEPS.MATCH then
        self:getWarsHomeScene():showMatchView({
            unionName   = mineUnionData.name,
            unionAvatar = mineUnionData.avatar,
        })
    elseif unionWarsStepId == UNION_WARS_STEPS.FIGHTING then
        -- wait to matched view
    else
        self:getWarsHomeScene():hideMatchView()
    end
end
function UnionWarsHomeMediator:checkShowMatchedView_()
    local unionWarsModel   = app.unionMgr:getUnionWarsModel()
    local nowStepTimeModel = unionWarsModel and unionWarsModel:getWarsTimeModel(unionWarsModel:getTimeLineIndex()) or nil
    local nowStepStartTime = nowStepTimeModel and checkint(nowStepTimeModel:getStartTime()) or 0
    local MATCHED_TIME_KEY = 'UNION_WARS_MATCHED_TIMESTAMP'
    local matchedTimestamp = checkint(cc.UserDefault:getInstance():getStringForKey(MATCHED_TIME_KEY, ''))
    
    if self:getWarsHomeScene():isShowingMatchView() or matchedTimestamp ~= nowStepStartTime then
        local mineUnionData = app.unionMgr:getUnionData() or {}
        local enemyMapModel = unionWarsModel and unionWarsModel:getEnemyMapModel() or nil
        self:getWarsHomeScene():showMatchView({
            unionName   = mineUnionData.name,
            unionAvatar = mineUnionData.avatar,
        }, {
            unionName   = enemyMapModel and enemyMapModel:getUnionName() or '----',
            unionAvatar = enemyMapModel and enemyMapModel:getUnionAvatar() or 0,
        })

        -- update local cache
        cc.UserDefault:getInstance():setStringForKey(MATCHED_TIME_KEY, nowStepStartTime)
        cc.UserDefault:getInstance():flush()
    end
end


function UnionWarsHomeMediator:checkShowWarsResultView_()
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    local pastResultData = unionWarsModel and unionWarsModel:getPastWarsResult() or nil
    if unionWarsModel and pastResultData and next(pastResultData) ~= nil then

        local SHOW_RESULT_KEY = 'UNION_WARS_RESULT_VIEW_KEY'
        local oldResultValue  = checkstr(cc.UserDefault:getInstance():getStringForKey(SHOW_RESULT_KEY, ''))
        local newResultValue  = json.encode(pastResultData)
        if oldResultValue ~= newResultValue then
            
            local unionWarsResultView = require('Game.views.unionWars.UnionWarsResultView').new({warsResultData = pastResultData})
            unionWarsResultView:setPosition(display.center)
            self:getWarsHomeScene():AddDialog(unionWarsResultView)

            -- update local cache
            cc.UserDefault:getInstance():setStringForKey(SHOW_RESULT_KEY, newResultValue)
            cc.UserDefault:getInstance():flush()
        end
    end
end


-------------------------------------------------
-- handler

function UnionWarsHomeMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- clean unionWarsModel cache
    app.unionMgr:setUnionWarsModel(nil)

    -- close
    self:close()
end


function UnionWarsHomeMediator:onClickUnionInfoBarHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.UNION_WARS)]})
end


function UnionWarsHomeMediator:onClickRewardsButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local mediatorClass  = require( 'Game.mediator.unionWars.UnionWarsRewardPreviewMeditaor' )
	local mediatorObject = mediatorClass.new()
	app:RegistMediator(mediatorObject)
end


function UnionWarsHomeMediator:onClickReportButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local mediatorClass  = require( 'Game.mediator.unionWars.UnionBattlefileReportMediator' )
	local mediatorObject = mediatorClass.new()
	app:RegistMediator(mediatorObject)
end


function UnionWarsHomeMediator:onClickApplyButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel then
        local isApplyStep = unionWarsModel:getWarsStepId() == UNION_WARS_STEPS.APPLY
        local isNotApply  = unionWarsModel:isAppliedUnionWars() == false
        local isOpenEdit  = isApplyStep and isNotApply

        -- show union apply
        local setApplySucceedCB = function()
            self:SendSignal(POST.UNION_WARS_UNION_MAP.cmdName)
        end
        local mediatorClass  = require( 'Game.mediator.unionWars.UnionWarsApplyMembersMediator' )
        local mediatorObject = mediatorClass.new({isEditMode = isOpenEdit, setApplySucceedCB = setApplySucceedCB})
        app:RegistMediator(mediatorObject)
    end
end


function UnionWarsHomeMediator:onClickDefendButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel then
        if unionWarsModel:hasDefendCards() == false then

            -- show edit defend team
            local editTeamLayer = require('Game.views.pvc.PVCChangeTeamScene').new({
                teamDatas             = {[1] = CommonUtils.ConvertTeamDataByStr(unionWarsModel:getPastDefendCards())},
                title                 = __('编辑防守队伍'),
                teamTowards           = -1,
                avatarTowards         = 1,
                teamChangeSingalName  = SGL.UNION_WARS_EDIT_DEFEND_TEAM_CHANGE,
                isDisableHomeTopSignal = true,
                -- tipsText              = app.unionMgr:getUnionWarsDefendTip(),
            }) 
            editTeamLayer:setAnchorPoint(display.CENTER)
            editTeamLayer:setPosition(display.center)
            editTeamLayer:setTag(4001)
            self:getWarsHomeScene():AddDialog(editTeamLayer)
            
        else
            -- alert to only edit once
            app.uiMgr:ShowInformationTips(__('防御编队只能设置一次'))
        end
    end
end


function UnionWarsHomeMediator:onClickUnionButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel then
        if unionWarsModel:getUnionMapModel() then
            unionWarsModel:setMapPageIndex(1)
            unionWarsModel:setWatchEnemyMap(false)
        else
            self:SendSignal(POST.UNION_WARS_UNION_MAP.cmdName)
        end
    end
end


function UnionWarsHomeMediator:onClickBattleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel then
        if unionWarsModel:getEnemyMapModel() then
            unionWarsModel:setMapPageIndex(1)
            unionWarsModel:setWatchEnemyMap(true)
        else
            self:SendSignal(POST.UNION_WARS_ENEMY_MAP.cmdName)
        end
    end
end


function UnionWarsHomeMediator:onClickShopButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local mediator = require("Game.mediator.unionWars.UnionWarsShopMediator").new()
    self:GetFacade():RegistMediator(mediator)
end


function UnionWarsHomeMediator:onClickNextMapButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local mapPageIndex = self:getWarsMapLayer():getMapPageIndex()
    local mapPageCount = self:getWarsMapLayer():getMapPageCount()
    if mapPageIndex < mapPageCount then
        self.isControllable_ = false
        local nextMapPageIdx = mapPageIndex + 1
        self:getWarsMapLayer():setMapPageIndex(nextMapPageIdx, false, function()
            local unionWarsModel = app.unionMgr:getUnionWarsModel()
            if unionWarsModel then
                unionWarsModel:setMapPageIndex(nextMapPageIdx)
            end
            self.isControllable_ = true
        end)
    end
end


function UnionWarsHomeMediator:onClickPrevMapButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local mapPageIndex = self:getWarsMapLayer():getMapPageIndex()
    local mapPageCount = self:getWarsMapLayer():getMapPageCount()
    if mapPageIndex > 1 then
        self.isControllable_ = false
        local prevMapPageIdx = mapPageIndex - 1
        self:getWarsMapLayer():setMapPageIndex(prevMapPageIdx, false, function()
            local unionWarsModel = app.unionMgr:getUnionWarsModel()
            if unionWarsModel then
                unionWarsModel:setMapPageIndex(prevMapPageIdx)
            end
            self.isControllable_ = true
        end)
    end
end


function UnionWarsHomeMediator:onCLickMapSiteNodeHandler_(siteId)
    -- PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local mapSiteModel   = self:getCurrentMapSiteModel(siteId)
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel and mapSiteModel then
        PlayAudioByClickNormal()

        if unionWarsModel:isWatchEnemyMap() then
            -- check player is dead
            if mapSiteModel:isDead() then
                app.uiMgr:ShowInformationTips(__('该玩家已被击破，请尝试攻打其他玩家'))
                
            elseif mapSiteModel:isDefending() then
                app.uiMgr:ShowInformationTips(__('该玩家正在被攻击，请稍后再尝试挑战'))

            elseif not unionWarsModel:isJoinMember() then
                app.uiMgr:ShowInformationTips(__('您不属于报名成员，只能进攻竞赛神兽'))

            elseif unionWarsModel:isPassedBuilding(siteId) then
                app.uiMgr:ShowInformationTips(__('您已击败过该玩家，请尝试挑战其他玩家'))

            else
                -- battle to enemy
                local battleToPlayerClass = require('Game.mediator.unionWars.UnionWarsBattleMemberMediator')
                local battleToPlayerObj   = battleToPlayerClass.new({buildingId = siteId })
                app:RegistMediator(battleToPlayerObj)
            end

        else
            -- view union player
            local cardShowClass = require('Game.views.worldboss.WorldBossManualPlayerCardShowView')
            local cardShowView  = cardShowClass.new({playerInfo = mapSiteModel:dumpPlayerData(), title = __('他（她）的防守阵容')})
            display.commonUIParams(cardShowView, {po = display.center, ap = display.CENTER})
            self:getWarsHomeScene():AddDialog(cardShowView)
        end

    end
end

function UnionWarsHomeMediator:onCLickMapBossNodeHandler_(pageId)
    -- PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    if unionWarsModel then
        PlayAudioByClickNormal()

        if unionWarsModel:isWatchEnemyMap() then
            -- battle to enemy
             local warsBeastQuestId = self:getCurrentMapBossQuestId(pageId)
             local warsBeastLevel = self:getCurrentMapBossLevel(pageId)
             local battleToBossClass = require('Game.mediator.unionWars.UnionWarBattleBossMediator')
             local battleToBossObj   = battleToBossClass.new({
                 warsBeastQuestId = warsBeastQuestId  ,
                 warsBeastLevel = warsBeastLevel
             })
             app:RegistMediator(battleToBossObj)
        end
    end
end


return UnionWarsHomeMediator
