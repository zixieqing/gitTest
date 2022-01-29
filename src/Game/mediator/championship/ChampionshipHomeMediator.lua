--[[
 * author : kaishiqi
 * descpt : 武道会 - 主页中介者
]]
local ChampionshipHomeMediator = class('ChampionshipHomeMediator', mvc.Mediator)

local MAIN_PROXY_NAME   = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT


function ChampionshipHomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'ChampionshipHomeMediator', viewComponent)
    local initArgs = checktable(params)
    self.ctorArgs_ = initArgs.requestData or {}
    self.homeArgs_ = initArgs
    self.homeArgs_.requestData = nil
end


-------------------------------------------------
-- life cycle
function ChampionshipHomeMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.contentMdtName_ = nil
    self.isControllable_ = true

    -- init model
    self.mainProxy_ = regVoProxy(MAIN_PROXY_NAME, MAIN_PROXY_STRUCT)

    -- create view
    self.ownerScene_ = app.uiMgr:SwitchToTargetScene('Game.views.championship.ChampionshipHomeScene')
    self:SetViewComponent(self.ownerScene_)

    -- add listener
    self.homeRefreshClocker_ = app.timerMgr.CreateClocker(handler(self, self.onHomeRefreshUpdateHandler_))
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(self:getViewData().titleBtn, handler(self, self.onClickTitleButtonHandler_))

    -- update views
    self.isControllable_ = false
    self:getViewNode():showUI(function()
        self:initHomeData_(self.homeArgs_)
        self.isControllable_ = true
    end)

    -- 清除武道会红点
	app.badgeMgr:CleanChampionshipRedPoint()
end


function ChampionshipHomeMediator:CleanupView()
    self.homeRefreshClocker_:stop()
    unregVoProxy(MAIN_PROXY_NAME)
end


function ChampionshipHomeMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'allhide')

    regPost(POST.CHAMPIONSHIP_HOME)
    regPost(POST.CHAMPIONSHIP_CHAMPION_DETAIL)
end


function ChampionshipHomeMediator:OnUnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightShow')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')

    self:GetFacade():UnRegsitMediator(self.contentMdtName_)
    unregPost(POST.CHAMPIONSHIP_CHAMPION_DETAIL)
    unregPost(POST.CHAMPIONSHIP_HOME)
end


function ChampionshipHomeMediator:InterestSignals()
    return {
        POST.CHAMPIONSHIP_HOME.sglName,
        POST.CHAMPIONSHIP_CHAMPION_DETAIL.sglName,
    }
end
function ChampionshipHomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.CHAMPIONSHIP_HOME.sglName then
        self:initHomeData_(data)

    elseif name == POST.CHAMPIONSHIP_CHAMPION_DETAIL.sglName then
        local TAKE_STRUCT = MAIN_PROXY_STRUCT.CHAMPION_PLAYER_TAKE
        self.mainProxy_:set(TAKE_STRUCT, data)
    end
end


-------------------------------------------------
-- get / set

function ChampionshipHomeMediator:getViewNode()
    return self.ownerScene_
end
function ChampionshipHomeMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function ChampionshipHomeMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())

    -- back to homeMdt
    local backMdtName = self.ctorArgs_.backMediatorName or 'HomeMediator'
    app.router:Dispatch({name = 'ChampionshipHomeMediator'}, {name = backMdtName})
end


function ChampionshipHomeMediator:closeAllMdt()
    app:BackMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function ChampionshipHomeMediator:initHomeData_(homeData)
    -- update mainHome takeData
    self.mainProxy_:set(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE, homeData)

    -- update refresh countdown
    local scheduleStep  = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
    local stepCountdown = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.STEP_RTIME)
    local openCountdown = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.OPEN_RTIME)
    if scheduleStep <= FOOD.CHAMPIONSHIP.STEP.UNKNOWN or scheduleStep >= FOOD.CHAMPIONSHIP.STEP.OFF_SEASON then
        self.mainProxy_:set(MAIN_PROXY_STRUCT.REFRESH_COUNTDOWN, openCountdown)
    else
        self.mainProxy_:set(MAIN_PROXY_STRUCT.REFRESH_COUNTDOWN, stepCountdown)
    end
    
    -- update refresh timestamp
    local refreshLeftSeconds = self.mainProxy_:get(MAIN_PROXY_STRUCT.REFRESH_COUNTDOWN)
    self.mainProxy_:set(MAIN_PROXY_STRUCT.REFRESH_TIMESTAMP, os.time() + math.max(refreshLeftSeconds, 1)) -- 防止返回0秒变成无限刷新
    
    -- start homeRefreshClocker
    self.homeRefreshClocker_:start()
    
    -- check season status
    local seasonMdtName = self:checkScheduleStepContentName_()
    if self.contentMdtName_ ~= nil and self.contentMdtName_ ~= seasonMdtName then
        self:getViewNode():closeDoor(function()
            self:checkScheduleStepPopupup_()
            self:updateScheduleStepContent_(seasonMdtName)
            self:getViewNode():openDoor()
        end)
    else
        -- update step content
        self:updateScheduleStepContent_(seasonMdtName)
        -- check step popup
        self:checkScheduleStepPopupup_()
    end
end


function ChampionshipHomeMediator:checkScheduleStepContentName_()
    local seasonMdtName = ''
    local scheduleStep  = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
    if scheduleStep <= FOOD.CHAMPIONSHIP.STEP.UNKNOWN or scheduleStep >= FOOD.CHAMPIONSHIP.STEP.OFF_SEASON then
        seasonMdtName = 'ChampionshipOffSeasonMediator'  -- 休赛期
    elseif scheduleStep <= FOOD.CHAMPIONSHIP.STEP.AUDITIONS then
        seasonMdtName = 'ChampionshipAuditionsMediator'  -- 海选赛
    else
        local isPromotion = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_QUALIFIED) == 1
        if isPromotion then
            seasonMdtName = 'ChampionshipPromotionMediator'  -- 晋级赛
        else
            seasonMdtName = 'ChampionshipVoteGuessMediator'  -- 投票竞猜
        end
    end
    return seasonMdtName
end
function ChampionshipHomeMediator:updateScheduleStepContent_(seasonMdtName)
    -- un-regist old contentMdt
    if self.contentMdtName_ ~= nil and self.contentMdtName_ ~= seasonMdtName then
        self:GetFacade():UnRegsitMediator(self.contentMdtName_)
        self.contentMdtName_ = nil
        self:closeAllMdt()
    end

    if string.len(seasonMdtName) > 0 and self.contentMdtName_ ~= seasonMdtName then

        -- regist new contentMdt
        xTry(function()
            local contentMdtClass  = require(string.fmt('Game.mediator.championship.%1', seasonMdtName))
            local contentMdtObject = contentMdtClass.new({ownerNode = self:getViewData().contentLayer})
            self:GetFacade():RegistMediator(contentMdtObject)
            
            -- update contentMdtName
            self.contentMdtName_ = contentMdtObject:GetMediatorName()
        end, __G__TRACKBACK__)
    end
end


function ChampionshipHomeMediator:checkScheduleStepPopupup_()
    local popupViewName = ''
    local popupViewType = 0
    local seasonId      = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SEASON_ID)
    local scheduleStep  = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
    
    -------------------------------------------------
    -- 赛季结束
    if scheduleStep == FOOD.CHAMPIONSHIP.STEP.OFF_SEASON then
        local finalMatchId    = FOOD.CHAMPIONSHIP.STEP.RESULT_1_1
        local SCHEDULE_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE
        local matchProxy      = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(finalMatchId))
        local championId      = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.WINNER_ID)
        local SEND_STRUCT     = MAIN_PROXY_STRUCT.CHAMPION_PLAYER_SEND
        if championId > 0 then
            -- 请求冠军队伍详情
            self.mainProxy_:set(SEND_STRUCT.PLAYER_ID, championId)
            self:SendSignal(POST.CHAMPIONSHIP_CHAMPION_DETAIL.cmdName, self.mainProxy_:get(SEND_STRUCT):getData())
            
            -- 本届冠军
            popupViewName = 'ChampionshipFinalWinnerPopup'
        end
        
    -------------------------------------------------
    -- 公布冠军
    elseif scheduleStep == FOOD.CHAMPIONSHIP.STEP.RESULT_1_1 then
        local topMatchId      = FOOD.CHAMPIONSHIP.STEP.RESULT_1_1
        local SCHEDULE_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE
        local matchProxy      = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(topMatchId))
        local winnerId        = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.WINNER_ID)
        if winnerId > 0 and winnerId == app.gameMgr:GetPlayerId() then
            -- 恭喜夺冠
            popupViewName = 'ChampionshipScheduleStepPopup'
            popupViewType = 3
        else
            -- 比赛结束
            popupViewName = 'ChampionshipScheduleStepPopup'
            popupViewType = 4
        end
        
    -------------------------------------------------
    -- 晋级赛内
    elseif scheduleStep > FOOD.CHAMPIONSHIP.STEP.AUDITIONS and scheduleStep < FOOD.CHAMPIONSHIP.STEP.RESULT_1_1 then
        -- 参与了海选
        local auditionTeamSize = self.mainProxy_:size(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_TEAM)
        if auditionTeamSize > 0 then
            local isPromotion = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_QUALIFIED) == 1
            if isPromotion then
                -- 恭喜入选
                popupViewName = 'ChampionshipScheduleStepPopup'
                popupViewType = 1
            else
                -- 遗憾落选
                popupViewName = 'ChampionshipScheduleStepPopup'
                popupViewType = 2
            end
        end

    -------------------------------------------------
    -- 海选赛开始
    elseif scheduleStep == FOOD.CHAMPIONSHIP.STEP.AUDITIONS then
        -- 海选赛开塞
        popupViewName = 'ChampionshipScheduleStepPopup'
        popupViewType = 5
    end
    
    -- 检测本地记录 是否有弹过相同的
    local loaclValue  = string.fmt('%1_%2', popupViewName, popupViewType)
    local localDefine = LOCAL.CHAMPIONSHIP.SCHEDULE_POPUP_NAME({seasonId = seasonId})
    local isNeedPopup = localDefine:Load() ~= loaclValue
    if string.len(popupViewName) > 0 and isNeedPopup then
        app.uiMgr:AddDialog(string.fmt('Game.views.championship.%1', popupViewName), {type = popupViewType})
        localDefine:Save(loaclValue)
    end
end


-------------------------------------------------
-- handler

function ChampionshipHomeMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function ChampionshipHomeMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.CHAMPIONSHIP)]})
end


function ChampionshipHomeMediator:onHomeRefreshUpdateHandler_()
    local currentTime = os.time()
    local refreshTime = self.mainProxy_:get(MAIN_PROXY_STRUCT.REFRESH_TIMESTAMP)
    local leftSeconds = refreshTime - currentTime

    if leftSeconds >= 0 then
        self.mainProxy_:set(MAIN_PROXY_STRUCT.REFRESH_COUNTDOWN, leftSeconds)
    else
        self.homeRefreshClocker_:stop()
        self:SendSignal(POST.CHAMPIONSHIP_HOME.cmdName)
    end
end


return ChampionshipHomeMediator
