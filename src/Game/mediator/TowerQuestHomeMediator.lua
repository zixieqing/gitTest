--[[
 * author : kaishiqi
 * descpt : 爬塔 - 主页中介者
]]
local TowerModelFactory      = require('Game.models.TowerQuestModelFactory')
local TowerQuestModel        = TowerModelFactory.getModelType('TowerQuest')
local UnitDefineModel        = TowerModelFactory.getModelType('UnitDefine')
local UnitConfigModel        = TowerModelFactory.getModelType('UnitConfig')
local TowerRootMediator      = require('Game.mediator.TowerQuestRootMediator')
local TowerMapMediator       = require('Game.mediator.TowerQuestMapMediator')
local TowerReadyMediator     = require('Game.mediator.TowerQuestReadyMediator')
local TowerQuestHomeMediator = class('TowerQuestHomeMediator', mvc.Mediator)

function TowerQuestHomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TowerQuestHomeMediator', viewComponent)
    self.towerHomeReceiveData_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function TowerQuestHomeMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    self.contentMdt_     = nil
    self.towerRootMdt_   = self:GetFacade():RetrieveMediator('TowerQuestRootMediator')

    if isGuideOpened('tower') then
        local guideNode = require('common.GuideNode').new({tmodule = 'tower'})
        display.commonUIParams(guideNode, { po = display.center})
        sceneWorld:addChild(guideNode, GameSceneTag.Guide_GameSceneTag)
    end

    -- create view
    local uiManager = self:GetFacade():GetManager('UIManager')
    self.homeScene_ = uiManager:SwitchToTargetScene('Game.views.TowerQuestHomeScene')
    self:SetViewComponent(self.homeScene_)

    -- init view
    local homeViewData = self:getHomeScene():getViewData()
    display.commonUIParams(homeViewData.backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    display.commonUIParams(homeViewData.rankBtn, {cb = handler(self, self.onClickRankButtonHandler_)})
    display.commonUIParams(homeViewData.titleBtn, {cb = handler(self, self.onClickTitleButtonHandler_)})
    display.commonUIParams(homeViewData.guideBtn, {cb = handler(self, self.onClickGuideButtonHandler_)})

    -- update view
    self.isControllable_ = false
    self.homeScene_:showUI(function()
        self.isControllable_ = true
    end)
end


function TowerQuestHomeMediator:CleanupView()
    self:cleanContentMediator_()
end


function TowerQuestHomeMediator:OnRegist()

    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")

    regPost(POST.TOWER_HOME)
    regPost(POST.TOWER_SET_PAST_CARD_LIBRARY)

    if not self.towerRootMdt_ then
        self.towerRootMdt_ = TowerRootMediator.new()
		self:GetFacade():RegistMediator(self.towerRootMdt_)

        if next(self.towerHomeReceiveData_) then
            self:parseTowerHomeReceiveData_()
        else
            self:SendSignal(POST.TOWER_HOME.cmdName)
        end
    else
        self:setFromBattle(self.towerRootMdt_:getBattleResultData() ~= nil)

        -- update unit readied status
        if self:isFromBattle() and not self:getTowerModel():isUnitReadied() then
            self:getTowerModel():setUnitReadied(true)
        end

        self:initContentMediator_()
        self:parseBattleResultData_()
    end
    self:updateHistoryMaxFloor_()
end
function TowerQuestHomeMediator:OnUnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")

    unregPost(POST.TOWER_HOME)
    unregPost(POST.TOWER_SET_PAST_CARD_LIBRARY)
end


function TowerQuestHomeMediator:InterestSignals()
    return {
        POST.TOWER_HOME.sglName,
        SGL.TOWER_QUEST_MODEL_TOWER_ENTERED_CHANGE,
        SGL.TOWER_QUEST_MODEL_HISTORY_MAX_FLOOR_CHANGE,
    }
end
function TowerQuestHomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.TOWER_HOME.sglName then
        AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "31-01"})
        self.towerHomeReceiveData_ = data
        self:parseTowerHomeReceiveData_()


    elseif name == SGL.TOWER_QUEST_MODEL_HISTORY_MAX_FLOOR_CHANGE then
        self:updateHistoryMaxFloor_()


    elseif name == SGL.TOWER_QUEST_MODEL_TOWER_ENTERED_CHANGE then
        self:initContentMediator_()

    end
end


-------------------------------------------------
-- get / set

function TowerQuestHomeMediator:getTowerModel()
    return self.towerRootMdt_:getTowerModel()
end


function TowerQuestHomeMediator:getHomeScene()
    return self.homeScene_
end


function TowerQuestHomeMediator:isFromBattle()
    return self.isFromBattle_ == true
end
function TowerQuestHomeMediator:setFromBattle(isFrom)
    self.isFromBattle_ = isFrom == true
end


-------------------------------------------------
-- public method

function TowerQuestHomeMediator:restart()
    self.isControllable_ = false
    transition.execute(self.homeScene_, nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})

    self:setFromBattle(false)
    self:SendSignal(POST.TOWER_HOME.cmdName)
end


-------------------------------------------------
-- private method

function TowerQuestHomeMediator:parseTowerHomeReceiveData_()
    local towerData  = self.towerHomeReceiveData_
    local towerModel = self:getTowerModel()
    local teamCards  = checkstr(towerData.teamCards)
    if string.len(teamCards) == 0 then
        local cardsList = {}
        local isEmptied = true
        local cacheTeam = towerModel:getCacheCardLibrary() or ''
        for _, cardUuid in ipairs(string.split2(cacheTeam, ',')) do
            if next(app.gameMgr:GetCardDataById(cardUuid)) ~= nil then
                isEmptied = false
                table.insert(cardsList, cardUuid)
            end
        end
        if #cardsList > 0 and not isEmptied then
            teamCards = table.concat(cardsList, ',')
            self:SendSignal(POST.TOWER_SET_PAST_CARD_LIBRARY.cmdName, {teamCards = teamCards})
        end
    end
    towerModel:setCacheCardLibrary(teamCards)
    towerModel:setSweepFloor(checkint(towerData.sweepFloor))
    towerModel:setHistoryMaxFloor(checkint(towerData.maxFloor))
    towerModel:setCurrentFloor(checkint(towerData.currentFloor))
    towerModel:setCardLibrary(string.split2(teamCards, ','))
    towerModel:setReviveTimes(checkint(towerData.buyLiveNum))
    towerModel:setReviveLimit(checkint(towerData.buyLiveLimitNum))
    towerModel:setEnterLeftTimes(checkint(towerData.enterLeftNum))
    towerModel:setUnitReadied(checkint(towerData.isReady) == 1)
    towerModel:setUnitPassed(checkint(towerData.isUnitPassed) == 1)
    towerModel:setSeasonId(checkint(towerData.seasonId))
    towerModel:setTeamCustomId(checkint(towerData.teamCustomId))

    -- unit define
    local unitDefineData  = checktable(towerData.unitDefine)
    local unitDefineModel = UnitDefineModel.new()
    if next(unitDefineData) then
        unitDefineModel:setUnitId(checkint(unitDefineData.unitId))
        unitDefineModel:setChestRewardsMap(checktable(unitDefineData.unitChest))
        unitDefineModel:setContractIdList(checktable(unitDefineData.unitContracts))
    end
    towerModel:setUnitDefineModel(unitDefineModel)

    -- unit config
    local unitConfigData  = checktable(towerData.unitConfig)
    local unitConfigModel = UnitConfigModel.new()
    if next(unitConfigData) then
        unitConfigModel:setCardIdList(string.split2(checkstr(unitConfigData.cards), ','))
        unitConfigModel:setSkillIdList(string.split2(checkstr(unitConfigData.skill), ','))
        unitConfigModel:setContractSelectedIdList(checktable(unitConfigData.contract))
    end
    towerModel:setUnitConfigModel(unitConfigModel)

    -- init center mediator
    towerModel:setTowerEntered(checkint(towerData.isEnter) == 1)
end


function TowerQuestHomeMediator:initContentMediator_()
    local prevContentSnapshot = self.contentMdt_ and self:createSnapshot_(sceneWorld) or nil
    self:cleanContentMediator_()
    self.prevContentSnapshot_ = prevContentSnapshot

    local isEntered  = self:getTowerModel():isTowerEntered()
    local mdtInitArg = {isIgnoreShowView = self.prevContentSnapshot_ ~= nil}
    self.contentMdt_ = isEntered and TowerMapMediator.new(mdtInitArg) or TowerReadyMediator.new(mdtInitArg)
    self:GetFacade():RegistMediator(self.contentMdt_)

    if self.prevContentSnapshot_ then
        self.homeScene_:AddDialog(self.prevContentSnapshot_)
        
        local homeViewData = self:getHomeScene():getViewData()
        homeViewData.backBtn:setEnabled(false)

        if isEntered then
            self.prevContentSnapshot_:setReverseDirection(true)
            self.prevContentSnapshot_:setPercentage(0.01)
            self.homeScene_:runAction(cc.Sequence:create({
                cc.TargetedAction:create(self.prevContentSnapshot_, cc.EaseCubicActionIn:create(cc.ProgressTo:create(0.6, 100))),
                cc.CallFunc:create(function()
                    if self.prevContentSnapshot_ then
                        self.homeScene_:RemoveDialog(self.prevContentSnapshot_)
                        self.prevContentSnapshot_ = nil
                    end
                    self.contentMdt_:showUI(function()
                        homeViewData.backBtn:setEnabled(true)
                    end)
                end)
            }))
        else
            self.prevContentSnapshot_:setPercentage(100)
            self.homeScene_:runAction(cc.Sequence:create({
                cc.TargetedAction:create(self.prevContentSnapshot_, cc.EaseCubicActionIn:create(cc.ProgressTo:create(0.6, 0.01))),
                cc.CallFunc:create(function()
                    if self.prevContentSnapshot_ then
                        self.homeScene_:RemoveDialog(self.prevContentSnapshot_)
                        self.prevContentSnapshot_ = nil
                    end
                    self.contentMdt_:showUI(function()
                        homeViewData.backBtn:setEnabled(true)
                    end)
                end)
            }))
        end
    end
end
function TowerQuestHomeMediator:cleanContentMediator_()
    if self.prevContentSnapshot_ and self.prevContentSnapshot_:getParent() then
        self.homeScene_:RemoveDialog(self.prevContentSnapshot_)
        self.prevContentSnapshot_ = nil
    end
    if self.contentMdt_ then
        local contentMdtName = self.contentMdt_:GetMediatorName()
        self:GetFacade():UnRegsitMediator(contentMdtName)
        self.contentMdt_ = nil
    end
end
function TowerQuestHomeMediator:createSnapshot_(viewObj)
	-- create the second render texture for outScene
    local texture = cc.RenderTexture:create(display.width, display.height)
    texture:setPosition(display.cx, display.cy)
    texture:setAnchorPoint(display.CENTER)

    -- render outScene to its texturebuffer
    texture:clear(0, 0, 0, 0)
    texture:begin()
    viewObj:visit()
    texture:endToLua()

    local middle = cc.ProgressTimer:create(texture:getSprite())
    middle:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    -- Setup for a bar starting from the bottom since the midpoint is 0 for the y
    middle:setMidpoint(cc.p((display.SAFE_R-135) / display.width, (display.height-130) / display.height))
    -- middle:setMidpoint(display.CENTER)
    -- Setup for a vertical bar since the bar change rate is 0 for x meaning no horizontal change
    middle:setBarChangeRate(cc.p(1, 1))
    middle:setPosition(display.cx, display.cy)
    return middle
end


function TowerQuestHomeMediator:updateHistoryMaxFloor_()
    local historyFloor = self:getTowerModel():getHistoryMaxFloor()
    local homeViewData = self:getHomeScene():getViewData()
    local myScoreText  = historyFloor <= 0 and '----' or string.fmt(__('_level_层'), {_level_ = historyFloor})
    homeViewData.maxFloorLabel:setString(myScoreText)
end


function TowerQuestHomeMediator:parseBattleResultData_()
    local battleResultData = self.towerRootMdt_:getBattleResultData()
    if not battleResultData then return end

    -- dispatch battle result
    local isPassed    = checkint(battleResultData.isPassed) == 1
    local reviveTimes = checkint(battleResultData.buyLiveNum)
    self:GetFacade():DispatchObservers(SGL.TOWER_QUEST_SET_BATTLE_RESULT, {
        isPassed    = isPassed,
        reviveTimes = reviveTimes
    })

    -- clean battle result data
    self.towerRootMdt_:setBattleResultData(nil)
end


function TowerQuestHomeMediator:getBackToMediatorName()
    local name = 'HomeMediator'
    if nil ~= self.towerHomeReceiveData_.requestData and nil ~= self.towerHomeReceiveData_.requestData.backMediatorName then
        name = self.towerHomeReceiveData_.requestData.backMediatorName
    end
    return name
end


-------------------------------------------------
-- handler method

function TowerQuestHomeMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    if self.prevContentSnapshot_ then return end

    self:GetFacade():UnRegsitMediator('TowerQuestRootMediator')

    local routeMediator = self:GetFacade():RetrieveMediator('Router')
    routeMediator:Dispatch({name = 'TowerQuestHomeMediator'}, {name = self:getBackToMediatorName()})
end


function TowerQuestHomeMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local uiMgr = self:GetFacade():GetManager('UIManager')
    uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.TOWER)]})
end


function TowerQuestHomeMediator:onClickRankButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local RankingListMediator = require( 'Game.mediator.RankingListMediator' )
    local mediator = RankingListMediator.new({rankTypes = RankTypes.TOWER})
    self:GetFacade():RegistMediator(mediator)
end


function TowerQuestHomeMediator:onClickGuideButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local guideNode = require('common.GuideNode').new({tmodule = 'tower'})
    sceneWorld:addChild(guideNode, GameSceneTag.Guide_GameSceneTag)
end


return TowerQuestHomeMediator
